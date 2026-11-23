import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

class RbcWebViewPage extends StatefulWidget {
  const RbcWebViewPage({super.key});

  @override
  State<RbcWebViewPage> createState() => _RbcWebViewPageState();
}

class _RbcWebViewPageState extends State<RbcWebViewPage> {
  static const _rbcDirectSignInUrl =
      'https://royalbank.com';
  static const _rbcHomeUrl = 'https://rbcroyalbank.com';

  final List<String> _capturedCsvContents = [];
  InAppWebViewController? _controller;
  double _progress = 0;
  bool _isCapturingCsv = false;
  String? _loadError;

  Future<void> _handleDownload(DownloadStartRequest request) async {
    if (_isCapturingCsv) return;
    setState(() => _isCapturingCsv = true);

    try {
      final url = request.url;
      String? csvContent;

      if (url.scheme == 'data') {
        final uriData = UriData.fromUri(url);
        csvContent = utf8.decode(uriData.contentAsBytes(), allowMalformed: true);
      } else if (url.scheme == 'blob') {
        csvContent = await _readBlobUrl(url.toString());
      } else {
        csvContent = await _downloadWithSessionCookies(url);
      }

      if (!mounted) return;
      if (csvContent != null && csvContent.trim().isNotEmpty) {
        setState(() => _capturedCsvContents.add(csvContent!));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Captured ${_capturedCsvContents.length} file(s). '
              'Download another account (e.g. Visa) or click "Done & Import".',
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the downloaded CSV file.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download capture failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturingCsv = false);
    }
  }

  Future<String?> _readBlobUrl(String blobUrl) async {
    if (_controller == null) return null;
    final res = await _controller!.callAsyncJavaScript(
      functionBody: '''
        const response = await fetch(blobUrl);
        return await response.text();
      ''',
      arguments: {'blobUrl': blobUrl},
    );
    return res?.value?.toString();
  }

  Future<String?> _downloadWithSessionCookies(WebUri url) async {
    final cookieManager = CookieManager.instance();
    final cookies = await cookieManager.getCookies(url: url);
    final cookieHeader = cookies.map((c) => '${c.name}=${c.value}').join('; ');

    final response = await http.get(
      Uri.parse(url.toString()),
      headers: {
        if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    );

    if (response.statusCode == 200) {
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final count = _capturedCsvContents.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RBC Online Banking Sync'),
        actions: [
          if (count > 0) ...[
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_capturedCsvContents),
              icon: const Icon(Icons.check, size: 18),
              label: Text('Done & Import ($count)'),
            ),
            const SizedBox(width: 8),
          ],
          TextButton.icon(
            onPressed: () {
              setState(() => _loadError = null);
              _controller?.loadUrl(
                urlRequest: URLRequest(url: WebUri(_rbcHomeUrl)),
              );
            },
            icon: const Icon(Icons.home_outlined, size: 18),
            label: const Text('RBC Home'),
          ),
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _controller?.goBack(),
          ),
          IconButton(
            tooltip: 'Reload page',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loadError = null);
              _controller?.reload();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildGuideBanner(context),
          if (_loadError != null)
            MaterialBanner(
              content: Text('Connection issue: $_loadError'),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() => _loadError = null);
                    _controller?.loadUrl(
                      urlRequest: URLRequest(url: WebUri(_rbcHomeUrl)),
                    );
                  },
                  child: const Text('Try RBC Main Site'),
                ),
              ],
            ),
          if (_progress < 1.0 || _isCapturingCsv)
            LinearProgressIndicator(value: _isCapturingCsv ? null : _progress),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_rbcDirectSignInUrl)),
              initialSettings: InAppWebViewSettings(
                useOnDownloadStart: true,
                javaScriptEnabled: true,
                domStorageEnabled: true,
              ),
              onWebViewCreated: (controller) => _controller = controller,
              onProgressChanged: (_, p) => setState(() => _progress = p / 100),
              onReceivedError: (_, request, error) {
                if (request.isForMainFrame ?? false) {
                  setState(() => _loadError = error.description);
                }
              },
              onDownloadStartRequest: (_, req) => _handleDownload(req),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: Colors.blue.withValues(alpha: 0.1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.blue.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '1. Sign in to RBC (complete 2FA if prompted).\n'
              '2. Open your Chequing account → Download Transactions → Select CSV (Excel) & date range → Download.\n'
              '3. Go back, open your Credit Card (Visa) → Download Transactions → CSV (Excel) → Download.\n'
              '4. Click "Done & Import" in the top bar once all accounts are downloaded.',
              style: TextStyle(fontSize: 12.5, color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
