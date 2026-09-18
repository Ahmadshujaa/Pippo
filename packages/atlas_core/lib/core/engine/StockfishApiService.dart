import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/services.dart';

class StockfishApiService {
  static const _channel = MethodChannel('com.example.tactics/engine');

  static Future<String> getInternalBinaryPath() async {
    try {
      // Android installs the ABI-appropriate engine in its extracted native
      // library directory. That directory is executable; app files
      // directories may be mounted noexec on some Android versions.
      final String? path = await _channel.invokeMethod<String>(
        'prepareStockfishBinary',
      );
      if (path == null || path.isEmpty) {
        throw Exception('Failed to prepare Stockfish binary');
      }
      dev.log('Resolved Stockfish path: $path');
      return path;
    } catch (e) {
      dev.log('Error getting native library path: $e');
      rethrow;
    }
  }

  static Future<bool> isStockfishDownloaded() async {
    try {
      final path = await getInternalBinaryPath();
      final exists = await File(path).exists();
      dev.log('Checking Stockfish binary: $path (exists: $exists)');
      return exists;
    } catch (_) {
      return false;
    }
  }

  static Future<void> prepareBinary() async {
    final path = await getInternalBinaryPath();
    if (!await File(path).exists()) {
      throw Exception(
        'Stockfish binary not found in the native library directory. Please ensure it was bundled for this device ABI.',
      );
    }

    if (Platform.isAndroid &&
        !(await File(path).stat()).modeString().contains('x')) {
      await Process.run('chmod', ['755', path]);
    }
  }
}
