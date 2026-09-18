import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:atlas_core/core/auth/AuthService.dart';
import 'package:atlas_core/core/logging/AppLogger.dart';

class MongoService {
  static Db? _db;
  static bool _isConnected = false;
  static Future<void>? _connectionAttempt;

  static const int _maxOperationAttempts = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  static Db get db {
    if (_db == null) {
      throw Exception('MongoService not initialized. Call init() first.');
    }
    return _db!;
  }

  static Future<void> init() async {
    // The local flag can remain true after a socket/network interruption.
    if (_isConnected && (_db?.isConnected ?? false)) return;

    // Prevent competing Db instances when multiple screens retry together.
    final activeAttempt = _connectionAttempt;
    if (activeAttempt != null) {
      await activeAttempt;
      return;
    }

    final attempt = _connect();
    _connectionAttempt = attempt;
    try {
      await attempt;
    } finally {
      if (identical(_connectionAttempt, attempt)) {
        _connectionAttempt = null;
      }
    }
  }

  static Future<void> _connect() async {
    _isConnected = false;

    final uri = dotenv.env['MONGODB_URI'];
    final dbName = dotenv.env['MONGODB_DB'];

    if (uri == null || dbName == null) {
      AppLogger.error('[MongoService] Error: MONGODB_URI or MONGODB_DB not found in .env');
      AppLogger.debug('[MongoService] Available env keys: ${dotenv.env.keys}');
      return;
    }

    final previousDb = _db;
    _db = null;
    if (previousDb != null) {
      try {
        await previousDb.close();
      } catch (e) {
        AppLogger.warn('[MongoService] Error closing stale connection: $e');
      }
    }

    Db? newDb;
    try {
      final maskedUri = uri.replaceFirst(RegExp(r':.*@'), ':****@');
      AppLogger.debug('[MongoService] Connecting with direct node list: $maskedUri');
      final createdDb = await Db.create(uri);
      newDb = createdDb;
      await createdDb.open();
      _db = createdDb;
      _isConnected = true;
      AppLogger.info('[MongoService] Successfully connected to MongoDB database: $dbName');
    } catch (e) {
      AppLogger.error('[MongoService] Connection error: $e');
      try {
        await newDb?.close();
      } catch (_) {
        // The connection may already have failed closed.
      }
      _db = null;
      _isConnected = false;
    }
  }

  static Future<void> close() async {
    final dbToClose = _db;
    _db = null;
    _isConnected = false;
    if (dbToClose != null) {
      try {
        await dbToClose.close();
      } catch (e) {
        AppLogger.warn('[MongoService] Error closing connection: $e');
      }
    }
  }

  static Future<T> withRetry<T>(Future<T> Function() operation) async {
    Object? lastError;

    for (var attempt = 1; attempt <= _maxOperationAttempts; attempt++) {
      try {
        await init();
        return await operation();
      } catch (e) {
        lastError = e;
        AppLogger.warn('[MongoService] Operation attempt $attempt failed: $e');

        if (attempt == _maxOperationAttempts) break;

        // Rebuild the Db instance for both explicit "No master connection"
        // errors and sockets that went stale underneath mongo_dart.
        await close();
        await Future<void>.delayed(_retryDelay * attempt);
      }
    }

    throw lastError ?? Exception('MongoDB operation failed');
  }

  static Future<DbCollection> collection(String name) async {
    if (!_isConnected || !(_db?.isConnected ?? false)) await init();
    return db.collection(name);
  }

  // ---------------------------------------------------------------------------
  // Write authorization
  // ---------------------------------------------------------------------------
  // Everything in MongoDB is shared: courses, themes, the daily puzzle record
  // and the per-account counters. A device without an account may read all of
  // it, but it may never change any of it. [canWrite] / [withSignedInRetry] are
  // the choke point every write goes through, so a signed-out user cannot
  // mutate the database even if a screen forgets to check.

  /// Whether this device holds a Supabase session, and may therefore write.
  ///
  /// Fail-closed on purpose: if the session cannot even be read (Supabase not
  /// initialized yet, storage error) this reports `false`, because a write that
  /// cannot be attributed to a signed-in account must not happen at all.
  static bool get canWrite {
    try {
      return AuthService.isLoggedIn;
    } catch (e) {
      AppLogger.warn('[MongoService] Session check failed, treating as signed out: $e');
      return false;
    }
  }

  /// [withRetry] for WRITE operations, restricted to signed-in devices.
  ///
  /// Returns null — without opening a connection or touching the database —
  /// when nobody is signed in, so callers can read the null as "skipped".
  static Future<T?> withSignedInRetry<T>(
    Future<T> Function() operation, {
    String? label,
  }) async {
    if (!canWrite) {
      AppLogger.debug('[MongoService] Write skipped (${label ?? 'operation'}): '
          'no signed-in user.');
      return null;
    }
    return withRetry(operation);
  }
}
