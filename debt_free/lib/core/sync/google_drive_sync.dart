import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/app_database.dart';
import 'cloud_sync_provider.dart';

class GoogleDriveSync implements CloudSyncProvider {
  static const _scope = drive.DriveApi.driveAppdataScope;
  static const _remoteFileName = 'debt_free.sqlite';

  final String clientId;
  final String? clientSecret;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;

  GoogleDriveSync({required this.clientId, this.clientSecret});

  @override
  String get providerName => 'Google Drive';

  Future<File> _tokenFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'gdrive_token.json'));
  }

  Future<bool> _loadSavedTokens() async {
    final file = await _tokenFile();
    if (!await file.exists()) return false;
    final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    _accessToken = data['access_token'] as String?;
    _refreshToken = data['refresh_token'] as String?;
    final exp = data['expires_at'] as String?;
    _expiresAt = exp != null ? DateTime.tryParse(exp) : null;
    return _refreshToken != null || _accessToken != null;
  }

  Future<void> _saveTokens() async {
    final file = await _tokenFile();
    await file.writeAsString(jsonEncode({
      'access_token': _accessToken,
      'refresh_token': _refreshToken,
      'expires_at': _expiresAt?.toIso8601String(),
    }));
  }

  Future<String?> _getValidAccessToken() async {
    if (_accessToken == null && _refreshToken == null) await _loadSavedTokens();
    if (_accessToken != null && _expiresAt != null && DateTime.now().isBefore(_expiresAt!.subtract(const Duration(minutes: 1)))) {
      return _accessToken;
    }
    if (_refreshToken == null) return null;

    final res = await http.post(Uri.parse('https://googleapis.com'), body: {
      'client_id': clientId,
      if (clientSecret != null) 'client_secret': clientSecret!,
      'refresh_token': _refreshToken!,
      'grant_type': 'refresh_token',
    });
    if (res.statusCode != 200) return null;

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    _accessToken = json['access_token'] as String;
    _expiresAt = DateTime.now().add(Duration(seconds: (json['expires_in'] as int?) ?? 3500));
    await _saveTokens();
    return _accessToken;
  }

  @override
  Future<bool> connect() async {
    if (await _getValidAccessToken() != null) return true;

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirectUri = 'http://127.0.0.1:${server.port}';
    final verifier = base64UrlEncode(List<int>.generate(32, (_) => Random.secure().nextInt(256))).replaceAll('=', '');
    final challenge = base64UrlEncode(sha256.convert(utf8.encode(verifier)).bytes).replaceAll('=', '');

    final authUri = Uri.https('://google.com', '/o/oauth2/v2/auth', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': _scope,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'access_type': 'offline',
      'prompt': 'consent',
    });

    await launchUrl(authUri, mode: LaunchMode.externalApplication);
    final req = await server.first;
    final code = req.uri.queryParameters['code'];
    req.response
      ..statusCode = 200
      ..headers.contentType = ContentType.html
      ..write('<html><body><h2>DebtFree connected! You can close this tab.</h2></body></html>');
    await req.response.close();
    await server.close();

    if (code == null) return false;
    final tokenRes = await http.post(Uri.parse('https://googleapis.com'), body: {
      'client_id': clientId,
      if (clientSecret != null) 'client_secret': clientSecret!,
      'code': code,
      'code_verifier': verifier,
      'grant_type': 'authorization_code',
      'redirect_uri': redirectUri,
    });
    if (tokenRes.statusCode != 200) return false;

    final json = jsonDecode(tokenRes.body) as Map<String, dynamic>;
    _accessToken = json['access_token'] as String;
    _refreshToken = (json['refresh_token'] as String?) ?? _refreshToken;
    _expiresAt = DateTime.now().add(Duration(seconds: (json['expires_in'] as int?) ?? 3500));
    await _saveTokens();
    return true;
  }

  Future<drive.DriveApi?> _driveApi() async {
    final token = await _getValidAccessToken();
    if (token == null) return null;
    return drive.DriveApi(_BearerClient(token));
  }

  Future<drive.File?> _findRemoteFile(drive.DriveApi api) async {
    final list = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_remoteFileName' and trashed = false",
      $fields: 'files(id, name, modifiedTime)',
    );
    return (list.files != null && list.files!.isNotEmpty) ? list.files!.first : null;
  }

  @override
  Future<DateTime?> getRemoteLastModified() async {
    if (AppDatabase.currentProfile != DatabaseProfile.real) return null;
    final api = await _driveApi();
    if (api == null) return null;
    return (await _findRemoteFile(api))?.modifiedTime;
  }

  @override
  Future<void> pullDatabase(File localDbFile) async {
    if (AppDatabase.currentProfile != DatabaseProfile.real) return;
    final api = await _driveApi();
    if (api == null) return;
    final remote = await _findRemoteFile(api);
    if (remote?.id == null) return;

    final media = await api.files.get(remote!.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final sink = localDbFile.openWrite();
    await media.stream.pipe(sink);
    await sink.close();
  }

  @override
  Future<void> pushDatabase(File localDbFile) async {
    if (AppDatabase.currentProfile != DatabaseProfile.real || !await localDbFile.exists()) return;
    final api = await _driveApi();
    if (api == null) return;

    final media = drive.Media(localDbFile.openRead(), await localDbFile.length());
    final existing = await _findRemoteFile(api);
    if (existing?.id != null) {
      await api.files.update(drive.File(), existing!.id!, uploadMedia: media);
    } else {
      await api.files.create(drive.File()..name = _remoteFileName..parents = ['appDataFolder'], uploadMedia: media);
    }
  }
}

class _BearerClient extends http.BaseClient {
  final String _token;
  final http.Client _inner = http.Client();
  _BearerClient(this._token);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }
}
