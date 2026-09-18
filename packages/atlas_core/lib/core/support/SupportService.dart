import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:atlas_core/core/auth/AuthService.dart';
import 'package:atlas_core/core/integrations/SupabaseService.dart';
import 'package:atlas_core/core/logging/AppLogger.dart';

/// The kind of problem a support ticket is about.
///
/// `support_tickets` has no dedicated column for this — the website has only
/// ever written email/subject/message into it — so the label is carried as a
/// `[UI]` / `[Error]` / `[Other]` prefix on the subject. That keeps the row
/// shape identical to the website's inserts (same table, same columns, same
/// values) while still making the category visible at a glance in the admin
/// ticket list at /dashboard/support.
enum SupportTicketType {
  ui('UI'),
  error('Error'),
  other('Other');

  const SupportTicketType(this.label);

  /// English tag written into the subject prefix. Deliberately not localized:
  /// the admins reading the ticket list all work in English, and a translated
  /// tag would make the same category show up under several different strings.
  final String label;

  /// Subject as the website's admin dashboard should see it, e.g.
  /// `[Error] App crashes on puzzle screen`.
  String prefixedSubject(String subject) => '[$label] ${subject.trim()}';
}

/// Why a ticket could not be submitted. The screen maps these to localized
/// copy, so the service itself never builds user-facing text.
enum SupportTicketError {
  /// No Supabase session — guests cannot write to `support_tickets` because
  /// RLS requires an authenticated owner.
  signInRequired,

  /// The subject was empty after trimming.
  subjectRequired,

  /// The message was empty after trimming.
  messageRequired,

  /// The composed subject exceeded [SupportService.subjectMaxLength].
  subjectTooLong,

  /// The message exceeded [SupportService.messageMaxLength].
  messageTooLong,

  /// The device is offline or Supabase rejected the write.
  submissionFailed,
}

/// Result of [SupportService.createTicket].
class SupportTicketResult {
  const SupportTicketResult._({this.ticketId, this.error});

  const SupportTicketResult.success(String ticketId) : this._(ticketId: ticketId);

  const SupportTicketResult.failure(SupportTicketError error) : this._(error: error);

  /// Row id of the created `support_tickets` row, null on failure.
  final String? ticketId;

  /// Why the submission failed, null on success.
  final SupportTicketError? error;

  bool get isSuccess => ticketId != null;
}

/// Creates support tickets in the same Supabase tables the website uses.
///
/// Mirrors `POST /api/support` from the web app, with one structural
/// difference: the website writes through a service-role key that bypasses
/// RLS, whereas the app only holds the anon key and therefore writes as the
/// signed-in user. `support_tickets` allows that (the row must carry the
/// caller's own `user_id`), which is why a session is required.
class SupportService {
  SupportService._();

  static SupabaseClient get _client => SupabaseService.client;

  /// Mirrors the website's `subject.trim().slice(0, 200)`.
  static const int subjectMaxLength = 200;

  /// Mirrors the website's "Message too long (max 5000 characters)" check.
  static const int messageMaxLength = 5000;

  /// Submits a ticket and returns the new ticket id.
  ///
  /// Writes two rows, exactly like the website does:
  /// 1. `support_tickets` — the ticket itself, `status: 'open'`.
  /// 2. `support_messages` — the opening message, so the ticket has a thread
  ///    the admin can reply into from /dashboard/support/[ticketId].
  static Future<SupportTicketResult> createTicket({
    required SupportTicketType type,
    required String subject,
    required String message,
  }) async {
    final userId = AuthService.userId;
    final email = AuthService.userEmail;

    if (userId == null || email == null || email.trim().isEmpty) {
      return const SupportTicketResult.failure(
        SupportTicketError.signInRequired,
      );
    }

    final trimmedSubject = subject.trim();
    if (trimmedSubject.isEmpty) {
      return const SupportTicketResult.failure(SupportTicketError.subjectRequired);
    }

    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      return const SupportTicketResult.failure(SupportTicketError.messageRequired);
    }

    if (trimmedMessage.length > messageMaxLength) {
      return const SupportTicketResult.failure(SupportTicketError.messageTooLong);
    }

    // The type prefix eats into the website's 200-character budget, so the
    // subject is clipped on the composed value rather than on the raw input.
    var composedSubject = type.prefixedSubject(trimmedSubject);
    if (composedSubject.length > subjectMaxLength) {
      final room = subjectMaxLength - composedSubject.length + trimmedSubject.length;
      if (room <= 0) {
        return const SupportTicketResult.failure(
          SupportTicketError.subjectTooLong,
        );
      }
      composedSubject = type.prefixedSubject(
        trimmedSubject.substring(0, room),
      );
    }

    try {
      final ticket = await _client
          .from('support_tickets')
          .insert({
            'email': email.trim().toLowerCase(),
            'subject': composedSubject,
            'message': trimmedMessage,
            // Required by RLS: the row must belong to the caller.
            'user_id': userId,
            'status': 'open',
          })
          .select('id')
          .single();

      final ticketId = ticket['id'] as String;

      // The ticket is already created at this point; a failure to seed the
      // thread must not lose it, so the message insert is best-effort and
      // only logged. The admin dashboard reads the ticket's own `message`
      // column for the opening post regardless.
      try {
        await _client.from('support_messages').insert({
          'ticket_id': ticketId,
          'sender_role': 'user',
          'message': trimmedMessage,
          'read': false,
        });
      } catch (e) {
        AppLogger.error('[SupportService] opening message insert failed: $e');
      }

      AppLogger.info('[SupportService] ticket created: $ticketId');
      return SupportTicketResult.success(ticketId);
    } catch (e) {
      AppLogger.error('[SupportService] createTicket error: $e');
      return const SupportTicketResult.failure(
        SupportTicketError.submissionFailed,
      );
    }
  }
}
