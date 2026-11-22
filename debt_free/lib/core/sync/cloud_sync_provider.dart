import 'dart:io';

abstract interface class CloudSyncProvider {
  String get providerName;
  Future<bool> connect();
  Future<DateTime?> getRemoteLastModified();
  Future<void> pullDatabase(File localDbFile);
  Future<void> pushDatabase(File localDbFile);
}
