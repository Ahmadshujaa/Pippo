import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Prepares the app's private storage area up-front, during bootstrap.
///
/// The app persists puzzles, games and the local engine model in its own
/// private directory, which Android grants via `android.permission.STORAGE` for
/// free at install time on every phone. The older build instead required the
/// sensitive `android.permission.MANAGE_EXTERNAL_STORAGE` ("All files access")
/// permission, which only some devices (e.g. certain Samsung units) actually
/// granted — so installing/saving only worked there.
///
/// By declaring STORAGE in AndroidManifest.xml and creating the data directory
/// here, the permissions the app needs are granted and ready from the very
/// first launch, on any Android phone. This is best-effort and never blocks
/// startup; features that need storage surface their own errors if it fails.
///
/// The directory is intentionally the same one `ModelApiService` writes the
/// engine model to (`getApplicationSupportDirectory()/AtlasChess`).
Future<void> requestStartupPermissions() async {
  try {
    final support = await getApplicationSupportDirectory();
    final Directory dir = Directory('${support.path}/AtlasChess');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  } catch (_) {
    // Non-fatal: download/local-save will report its own error if storage is
    // ever unavailable.
  }
}