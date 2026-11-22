# DebtFree — Architecture & Developer Guide

Personal finance management application built with **Flutter / Dart** targeting **Windows Desktop** and **Android** (no React/web wrapper).

---

## 1. Architectural Principles

- **Clean Layered Architecture** inside `lib/`:
  - `domain/` — Pure Dart immutable entities and repository contracts. **Zero external or Flutter dependencies.**
  - `core/` — Cross-cutting infrastructure (SQLite v3 database management and cloud sync contracts).
  - `data/` — Data source parsers (CSV) and concrete repository implementations.
  - `presentation/` — Flutter UI pages and modular, single-responsibility widgets.
- **Language Rule**: All code, comments, UI labels, and documentation must be written strictly in **English**.
- **Sync-Ready SQLite**: Configured with `PRAGMA journal_mode = DELETE;` so the single `debt_free.sqlite` file can be safely backed up and synced across devices without WAL sidecar conflicts.

---

## 2. Directory Structure

```text
lib/
├── main.dart                                  # App entry point, NavigationRail shell (collapsible LeftMenu)
├── core/
│   ├── database/
│   │   └── app_database.dart                  # SQLite v3 singleton (transactions, categories, category_rules)
│   └── sync/
│       ├── cloud_sync_provider.dart           # Abstract sync contract (pushDatabase / pullDatabase)
│       └── local_only_sync.dart               # No-op local implementation (placeholder for GoogleDriveSync)
├── domain/
│   ├── entities/
│   │   ├── account_type.dart                  # Enum: rbcChequing, rbcVisa, unknown
│   │   ├── transaction.dart                   # Immutable Transaction model (SHA-256 id, amount, type, category)
│   │   └── transaction_type.dart              # Enum: expense, income, transfer
│   └── repositories/
│       └── transaction_repository.dart        # Repository contract (CRUD, bulk edits, rules, category colors)
├── data/
│   ├── repositories/
│   │   └── sqlite_transaction_repository.dart # SQLite implementation + auto-rule matching + sync trigger
│   └── sources/
│       ├── transaction_source.dart            # Abstract CSV/data source interface
│       └── rbc_csv_source.dart                # RBC Chequing & Visa CSV parser + internal transfer detection
└── presentation/
    ├── pages/
    │   ├── dashboard_page.dart                # Responsive 2-column widget grid + interactive Category PieChart
    │   ├── expenses_page.dart                 # "All Transactions" view, filters, Refresh (Append/Replace), Bulk Edit
    │   └── categories_page.dart               # Category management (with HSL hue slider) & merchant auto-rules
    └── widgets/
        ├── global_summary_card.dart           # Top summary card
        ├── monthly_cashflow_section.dart      # Monthly container (header + breakdown + 2-column cashflow)
        ├── month_breakdown_bar.dart           # Expandable Debit vs Credit vs Transfers summary bar
        ├── transaction_category_group.dart    # Reusable section header + transaction list (Expenses/Income/Transfers)
        ├── transaction_row_card.dart          # Interactive row with hover state, badges, tooltip, inline dropdown
        ├── transaction_edit_dialog.dart       # Modal dialog for category assignment, rule memory, and type switch
        └── gradient_color_slider.dart         # Continuous HSL hue slider widget for custom category colors
```

---

## 3. Database Schema (`debt_free.sqlite` — v3)

- **`transactions`**
  - `id TEXT PRIMARY KEY` (SHA-256 hash for deterministic deduplication)
  - `account TEXT NOT NULL`
  - `date TEXT NOT NULL` (`YYYY-MM-DD`)
  - `amount REAL NOT NULL`
  - `merchant TEXT NOT NULL`
  - `type TEXT NOT NULL DEFAULT 'expense'` (`expense` | `income` | `transfer`)
  - `category TEXT NOT NULL DEFAULT 'Uncategorized'`
- **`categories`**
  - `name TEXT PRIMARY KEY` (seeded with 16 default categories + user-defined categories like `Gifts`)
  - `color INTEGER NOT NULL DEFAULT 4286091420` (ARGB32 integer for consistent chart & UI theming)
- **`category_rules`**
  - `merchant_pattern TEXT PRIMARY KEY`
  - `category_name TEXT NOT NULL`

---

## 4. Implemented Features

- **Navigation Shell**: Collapsible `NavigationRail` (`Dashboard`, `All Transactions`, `Categories`) toggled manually via header menu button.
- **CSV Import & Deduplication**: RBC Chequing & Visa parsing, automatic internal transfer tagging (`TransactionType.transfer`), SHA-256 deduplication, and `Append` vs `Replace all` refresh modes.
- **All Transactions (`ExpensesPage`)**:
  - Grouped by month (rolling 12+ months) with side-by-side **Expenses** (red, left) and **Income** (green, right), plus **Transfers** (blue, bottom, excluded from totals).
  - Expandable `Show more / Show less` breakdown (`Debit` vs `Credit` vs `Transfers`).
  - Interactive `TransactionRowCard` with desktop hover states, `DEBIT`/`CREDIT` badges, merchant tooltips, `Uncategorized only (X)` filter, and multi-row **Bulk Edit** with `Save All`.
- **Categories & Rules (`CategoriesPage`)**:
  - Add/delete custom categories with a continuous HSL `GradientColorSlider` persisted in SQLite.
  - Memorized merchant auto-rules (`category_rules`) applied automatically on import and bulk updates.
- **Dashboard (`DashboardPage`)**:
  - Responsive `Wrap` grid (max 2 cards per row on Desktop `>= 800px`, 1 column on mobile).
  - Interactive `PieChart` (`fl_chart`) with period selector (`Current Month`, `Last 6 Months`, `Last Year`, `All Time`), dynamic period total, fixed category colors, and hover badges.

---

## 5. Roadmap

1. **Dashboard Expansion**: Add secondary analytics cards to the 2-column grid (monthly category averages, month-over-month comparison, year-end projection).
2. **Wealthsimple Integration**: Implement `WealthsimpleCsvSource` in `data/sources/` conforming to `TransactionSource`.
3. **Cross-Device Sync**: Replace `LocalOnlySync` with `GoogleDriveSync` to sync `debt_free.sqlite` between Windows Desktop and Android.
