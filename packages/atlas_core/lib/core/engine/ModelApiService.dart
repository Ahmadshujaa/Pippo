import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ModelApiService {
  static const String _repoId = 'AShuja/NewBaseModel';
  static const String _fileName = 'BaseModel.onnx';
  static const String _token = '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';
  static const int _timeoutSeconds = 120;

  static Future<String> getModelFilePath() async {
    if (Platform.isAndroid) {
      // App-private storage (android.permission.STORAGE). Android grants this
      // to every app at install time on every phone — no sensitive "All files
      // access" prompt. The old code wrote to the public Downloads folder,
      // which required the Android 14+ sensitive MANAGE_EXTERNAL_STORAGE
      // permission, and that is exactly what only some phones (e.g. Samsung)
      // actually granted.
      final supportDir = await getApplicationSupportDirectory();
      return '${supportDir.path}/AtlasChess/$_fileName';
    }
    final docsDir = await getApplicationDocumentsDirectory();
    return '${docsDir.path}/$_fileName';
  }

  /// Paths under which the model was stored by older app versions (public
  /// Downloads / external storage). Kept only for a one-time migration.
  static Future<List<String>> _legacyModelFiles() async {
    final paths = <String>[];
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      paths.add('${docsDir.path}/$_fileName');
    } catch (_) {}
    if (Platform.isAndroid) {
      paths.add('/storage/emulated/0/Download/AtlasChess/$_fileName');
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) paths.add('${extDir.path}/$_fileName');
      } catch (_) {}
    }
    return paths;
  }

  /// Returns the path of an available model in app-private storage. If the
  /// model was previously downloaded to a legacy location, it is migrated
  /// (copied) into private storage so it keeps working on any phone.
  static Future<String> ensureModelFile() async {
    final target = await getModelFilePath();
    if (await File(target).exists()) return target;

    for (final legacy in await _legacyModelFiles()) {
      if (await File(legacy).exists()) {
        final directory = Directory(File(target).parent.path);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final sink = File(target).openWrite();
        sink.add(await File(legacy).readAsBytes());
        await sink.flush();
        await sink.close();
        return target;
      }
    }

    // Not present anywhere yet — the caller decides whether to download.
    return target;
  }

  static Future<bool> isModelDownloaded() async {
    return await File(await ensureModelFile()).exists();
  }

  static Future<void> downloadModel({void Function(int receivedBytes, int totalBytes)? onProgress}) async {
    // Reuse or migrate an existing model (if any) instead of re-downloading.
    final modelPath = await ensureModelFile();
    final file = File(modelPath);
    if (await file.exists()) return;

    // Ensure directory exists
    final directory = Directory(file.parent.path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final url = Uri.parse('https://huggingface.co/$_repoId/resolve/main/$_fileName');

    final client = http.Client();
    try {
      final request = http.Request('GET', url);
      request.headers['Authorization'] = 'Bearer $_token';

      final streamedResponse = await client.send(request).timeout(
        const Duration(seconds: _timeoutSeconds),
      );

      final statusCode = streamedResponse.statusCode;

      if (statusCode == 404) {
        throw Exception('$_fileName not found in repo $_repoId');
      }

      if (statusCode != 200) {
        throw Exception('Download failed (HTTP $statusCode)');
      }

      final contentLength = streamedResponse.contentLength;
      final sink = file.openWrite();

      var received = 0;
      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength != null && contentLength > 0) {
          onProgress?.call(received, contentLength);
        }
      }

      await sink.flush();
      await sink.close();

      if (contentLength != null && contentLength > 0) {
        onProgress?.call(contentLength, contentLength);
      }
    } on TimeoutException {
      throw Exception('Download timed out after $_timeoutSeconds seconds. Check your internet connection.');
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    } finally {
      client.close();
    }
  }
}