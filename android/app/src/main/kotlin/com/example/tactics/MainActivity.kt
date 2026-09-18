package com.example.tactics

import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.tactics/engine"
    private val STOCKFISH_VERSION = "Stockfish 19 (sf_19 / edb0d9d)"
    private val TAG = "StockfishNative"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "prepareStockfishBinary") {
                val libDir = applicationInfo.nativeLibraryDir
                try {
                    val bundled = File(libDir, "libstockfish.so")
                    if (!bundled.isFile || bundled.length() == 0L) {
                        result.error("STOCKFISH_MISSING", "Stockfish is not bundled for this device ABI ($libDir)", null)
                        return@setMethodCallHandler
                    }

                    // Execute from nativeLibraryDir. Android's app data files
                    // directory may be mounted noexec, so copying an engine
                    // to files/engine causes EACCES even after chmod 755.
                    // Gradle extracts this ABI-specific jniLibs entry here.
                    bundled.setExecutable(true, false)
                    Log.d(TAG, "Using $STOCKFISH_VERSION: ${bundled.absolutePath}, size=${bundled.length()}")
                    result.success(bundled.absolutePath)
                } catch (e: Exception) {
                    Log.e(TAG, "Error listing native libraries: ${e.message}")
                    result.error("STOCKFISH_COPY_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
