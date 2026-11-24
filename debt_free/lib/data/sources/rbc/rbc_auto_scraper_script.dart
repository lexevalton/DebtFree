import 'dart:convert';
import '../../../domain/entities/bank_account_profile.dart';

class RbcAutoScraperScript {
  static String buildStepScript({
    required BankAccountProfile targetAccount,
    required bool isFirstSyncEver,
  }) {
    final now = DateTime.now();
    // Use 360 days instead of 365 so RBC Visa never rejects timezone/boundary checks
    final safeOneYearAgo = now.subtract(const Duration(days: 360));
    final fromDateIso = safeOneYearAgo.toIso8601String().split('T').first;
    final toDateIso = now.toIso8601String().split('T').first;

    final targetJson = jsonEncode({
      'name': targetAccount.accountName.toLowerCase(),
      'digits': targetAccount.lastFourDigits.trim(),
      'isVisa': targetAccount.accountType.name == 'rbcVisa',
      'isFirstSync': isFirstSyncEver,
      'fromDateIso': fromDateIso,
      'toDateIso': toDateIso,
    });

    return '''
      (function() {
        const target = $targetJson;

        function setAngularInput(input, val) {
          if (!input) return;
          input.focus();
          const setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;
          setter.call(input, val);
          input.dispatchEvent(new Event('input', { bubbles: true }));
          input.dispatchEvent(new Event('change', { bubbles: true }));
          input.blur();
        }

        // 1. Inside an account details page: look for <bwc-download-transactions-selector>
        const dlWidgets = Array.from(document.querySelectorAll('bwc-download-transactions-selector'));
        for (const dlWidget of dlWidgets) {
          const trigger = Array.from(dlWidget.querySelectorAll('button'))
            .find(b => /télécharger|download/i.test(b.textContent || ''));
          if (!trigger || trigger.offsetParent === null) continue;

          // Allow automatic retry if previous download attempt stalled > 8 seconds
          const triggeredAt = Number(dlWidget.dataset.debtfreeTriggeredAt || '0');
          if (triggeredAt > 0 && (Date.now() - triggeredAt) < 8000) {
            return 'WAITING_FOR_CSV_FILE';
          }

          // On first sync only: fill BOTH "From" (-360 days) and "To" (today) inputs
          if (target.isFirstSync && dlWidget.dataset.debtfreeFiltered !== '1') {
            const fromInput = document.querySelector('#filterFromDatepicker');
            if (!fromInput || fromInput.offsetParent === null) {
              const filterBtn = Array.from(document.querySelectorAll('button, a'))
                .find(b => /^filtrer\$|^filter\$/i.test((b.textContent || '').trim()) && b.offsetParent !== null);
              if (filterBtn) {
                filterBtn.click();
                return 'OPENING_12M_FILTER';
              }
            } else {
              dlWidget.dataset.debtfreeFiltered = '1';
              const dateInputs = Array.from(document.querySelectorAll('form.filter__form rbc-date-picker input.rbc-input'));
              const toInput = document.querySelector('#filterToDatepicker') || dateInputs[1];

              setAngularInput(fromInput, target.fromDateIso);
              setAngularInput(toInput, target.toDateIso);

              setTimeout(() => {
                const applyBtn = Array.from(document.querySelectorAll('form.filter__form button'))
                  .find(b => /appliquer|apply|rechercher|search|ok/i.test((b.textContent || '').trim()));
                if (applyBtn) applyBtn.click();
              }, 350);
              return 'APPLYING_12M_FILTER';
            }
          }

          const csvOption = Array.from(dlWidget.querySelectorAll('li[role="option"], .rbc-dropdown-list--li'))
            .find(li => /csv/i.test(li.textContent || ''));

          if (csvOption) {
            dlWidget.dataset.debtfreeTriggeredAt = String(Date.now());
            trigger.click();
            setTimeout(() => {
              csvOption.click();
            }, 400);
            return 'CLICKING_CSV_OPTION';
          }
        }

        // 2. Accounts Summary table: match on <li class="accounts-table__row">
        const rows = Array.from(document.querySelectorAll('li.accounts-table__row, [rbc-account-list-item-widget]'));
        for (const row of rows) {
          const rowText = (row.innerText || row.textContent || '').toLowerCase();
          const link = row.querySelector('a[data-dig-id], .accounts-table__account-link a, a');
          if (!link) continue;

          const matchesDigits = target.digits && rowText.includes(target.digits);
          const matchesName = target.name && rowText.includes(target.name);
          const matchesType = target.isVisa
            ? /visa|mastercard|crédit|credit/i.test(rowText)
            : /chèques|chequing|forfait bancaire/i.test(rowText);

          if (matchesDigits || matchesName || matchesType) {
            const openedAt = Number(link.dataset.debtfreeOpenedAt || '0');
            if (openedAt > 0 && (Date.now() - openedAt) < 6000) {
              return 'WAITING_FOR_ACCOUNT_PAGE';
            }
            link.dataset.debtfreeOpenedAt = String(Date.now());
            link.click();
            return 'OPENING_ACCOUNT';
          }
        }

        return 'WAITING_FOR_USER';
      })();
    ''';
  }
}
