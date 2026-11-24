import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/sources/rbc/rbc_auto_scraper_script.dart';
import '../../domain/entities/bank_account_profile.dart';
import '../../theme/app_theme.dart';

class RbcWebViewPage extends StatefulWidget {
  final List<BankAccountProfile> activeProfiles;

  const RbcWebViewPage({super.key, this.activeProfiles = const []});

  @override
  State<RbcWebViewPage> createState() => _RbcWebViewPageState();
}

class _RbcWebViewPageState extends State<RbcWebViewPage> {
  static const _rbcMainUrl = 'https://rbcroyalbank.com';
  static const _rbcDirectSignInUrl =
      'https://royalbank.com';

  final List<String> _capturedCsvContents = [];
  final Set<String> _processedFilePaths = {};
  late final DateTime _sessionStartedAt;
  Timer? _poller;
  InAppWebViewController? _controller;
  double _progress = 0;
  bool _autoModeEnabled = true;
  int _currentAccountIndex = 0;
  String? _loadError;
  String _statusStep = 'Sign in to RBC (complete 2FA) — auto-sync watches the page automatically.';

  @override
  void initState() {
    super.initState();
    _sessionStartedAt = DateTime.now().subtract(const Duration(seconds: 2));
    _poller = Timer.periodic(const Duration(milliseconds: 1500), (_) => _onTick());
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  BankAccountProfile? get _currentTarget {
    if (widget.activeProfiles.isEmpty || _currentAccountIndex >= widget.activeProfiles.length) {
      return null;
    }
    return widget.activeProfiles[_currentAccountIndex];
  }

  Future<void> _onTick() async {
    await _scanNewCsvDownloads();
    if (!_autoModeEnabled || _controller == null || _currentTarget == null) return;

    final currentUrl = (await _controller!.getUrl())?.toString().toLowerCase() ?? '';
    if (!currentUrl.contains('royalbank.com') ||
        currentUrl.contains('signin') ||
        currentUrl.contains('login')) {
      return;
    }

    final target = _currentTarget!;
    final script = RbcAutoScraperScript.buildStepScript(
      targetAccount: target,
      isFirstSyncEver: target.lastSyncedAt == null,
    );
    final res = await _controller!.evaluateJavascript(source: script);
    if (!mounted) return;
    setState(() {
      _statusStep = 'Auto (${_currentAccountIndex + 1}/${widget.activeProfiles.length}) "${target.accountName}": ${res ?? 'SCANNING'}';
    });
  }

  Future<void> _scanNewCsvDownloads() async {
    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir == null || !await downloadsDir.exists()) return;

    for (final file in downloadsDir.listSync().whereType<File>()) {
      if (!file.path.toLowerCase().endsWith('.csv') || _processedFilePaths.contains(file.path)) continue;
      final stat = await file.stat();
      if (stat.modified.isBefore(_sessionStartedAt) || stat.size == 0) continue;

      try {
        final content = await file.readAsString();
        if (content.trim().isEmpty) continue;
        _processedFilePaths.add(file.path);
        if (!mounted) return;

        setState(() {
          _capturedCsvContents.add(content);
          _currentAccountIndex++;
        });

        final totalTargets = widget.activeProfiles.length;
        if (totalTargets > 0 && _currentAccountIndex >= totalTargets) {
          Navigator.of(context).pop(_capturedCsvContents);
          return;
        }

        if (_autoModeEnabled && _currentTarget != null) {
          await _controller?.evaluateJavascript(
            source: "const home = Array.from(document.querySelectorAll('a, button')).find(a => /^(comptes|accounts|sommaire des comptes|accounts summary)\$/i.test((a.textContent || '').trim())); if (home) home.click(); else window.history.back();",
          );
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _capturedCsvContents.length;
    final expected = widget.activeProfiles.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(_capturedCsvContents),
        ),
        title: const Text('RBC Online Banking Sync'),
        actions: [
          Row(
            children: [
              const Text('Auto', style: TextStyle(fontSize: 13, color: Colors.white)),
              Switch(
                value: _autoModeEnabled,
                activeThumbColor: Colors.white,
                onChanged: (v) => setState(() => _autoModeEnabled = v),
              ),
            ],
          ),
          if (count > 0) ...[
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_capturedCsvContents),
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryDark),
              icon: const Icon(Icons.check, size: 18),
              label: Text('Import ($count${expected > 0 ? '/$expected' : ''})'),
            ),
            const SizedBox(width: 8),
          ],
          TextButton.icon(
            onPressed: () {
              setState(() => _loadError = null);
              _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(_rbcDirectSignInUrl)));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Sign In'),
          ),
          IconButton(tooltip: 'Reload', icon: const Icon(Icons.refresh), onPressed: () => _controller?.reload()),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppColors.menuSelected,
            child: Text(
              _statusStep,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
          if (_loadError != null)
            MaterialBanner(
              content: Text('Connection issue: $_loadError'),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() => _loadError = null);
                    _controller?.reload();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          if (_progress < 1.0) LinearProgressIndicator(value: _progress),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_rbcMainUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                isInspectable: true,
              ),
              onWebViewCreated: (c) => _controller = c,
              onProgressChanged: (_, p) => setState(() => _progress = p / 100),
              onPermissionRequest: (_, request) async {
                return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT,
                );
              },
              onReceivedError: (_, request, error) {
                if (request.isForMainFrame ?? false) {
                  setState(() => _loadError = error.description);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
