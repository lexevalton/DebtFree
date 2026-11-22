import 'dart:io';
import 'cloud_sync_provider.dart';

class LocalOnlySync implements CloudSyncProvider {
  @override
  String get providerName => 'Local Storage Only';

  @override
  Future<bool> connect() async => true;

  @override
  Future<DateTime?> getRemoteLastModified() async => null;

  @override
  Future<void> pullDatabase(File localDbFile) async {}

  @override
  Future<void> pushDatabase(File localDbFile) async {}
}
