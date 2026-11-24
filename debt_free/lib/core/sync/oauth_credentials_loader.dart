import 'dart:convert';
import 'package:flutter/services.dart';
import 'cloud_sync_provider.dart';
import 'google_drive_sync.dart';
import 'local_only_sync.dart';

class OAuthCredentialsLoader {
  static Future<CloudSyncProvider> loadGoogleDriveProvider() async {
    try {
      final raw = await rootBundle.loadString('resources/google_oauth_client.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final section = (decoded['installed'] ?? decoded['web'] ?? decoded) as Map<String, dynamic>;
      final clientId = section['client_id'] as String?;
      final clientSecret = section['client_secret'] as String?;

      if (clientId != null && clientId.isNotEmpty) {
        return GoogleDriveSync(clientId: clientId, clientSecret: clientSecret);
      }
    } catch (_) {
      // Fallback to local-only sync if JSON asset is missing or unreadable
    }
    return LocalOnlySync();
  }
}
