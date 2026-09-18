import 'package:flutter/material.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/atlas_ui.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

/// Lets a signed-in player open a support ticket.
///
/// Writes into the same Supabase tables the website uses — `support_tickets`
/// plus the opening `support_messages` row — so a ticket raised here shows up
/// in the admin dashboard next to the ones raised on the web. See
/// [SupportService] for the exact row shape.
class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  /// Null until the player picks one; submission is blocked while null.
  SupportTicketType? _type;

  bool _submitting = false;
  bool _submitted = false;

  /// Set when the player submits without choosing a type.
  bool _typeMissing = false;

  /// Set when the service rejected the ticket.
  SupportTicketError? _serviceError;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// A ticket can only be written by an authenticated user: `support_tickets`
  /// RLS requires the row to carry the caller's own `user_id`, and guests
  /// never get a Supabase session (they just jump straight to /home).
  bool get _hasAccount {
    final userId = AuthService.userId;
    final email = AuthService.userEmail;
    return userId != null && email != null && email.trim().isNotEmpty;
  }

  /// Resolved on every build rather than stored, so the banner re-translates
  /// if the player switches language while it is on screen.
  String? _errorText(AppLocalizations l10n) {
    if (_typeMissing) return l10n.supportErrTypeRequired;
    switch (_serviceError) {
      case SupportTicketError.subjectRequired:
        return l10n.supportErrSubjectRequired;
      case SupportTicketError.messageRequired:
        return l10n.supportErrMessageRequired;
      case SupportTicketError.subjectTooLong:
        return l10n.supportErrSubjectTooLong;
      case SupportTicketError.messageTooLong:
        return l10n.supportErrMessageTooLong;
      case SupportTicketError.signInRequired:
      case SupportTicketError.submissionFailed:
        return l10n.supportErrGeneric;
      case null:
        return null;
    }
  }

  Future<void> _submit() async {
    if (_type == null) {
      setState(() {
        _typeMissing = true;
        _serviceError = null;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _typeMissing = false;
      _serviceError = null;
    });

    final result = await SupportService.createTicket(
      type: _type!,
      subject: _subjectController.text,
      message: _messageController.text,
    );

    if (!mounted) return;

    setState(() {
      _submitting = false;
      if (result.isSuccess) {
        _submitted = true;
      } else {
        _serviceError = result.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.contactSupportTitle,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: _submitted
          ? _buildSuccess(context, l10n)
          : !_hasAccount
              ? _buildSignInRequired(context, l10n)
              : _buildForm(context, l10n),
    );
  }

  // ---------------------------------------------------------------------------
  // Form
  // ---------------------------------------------------------------------------

  Widget _buildForm(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final errorText = _errorText(l10n);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, l10n.supportTypeLabel),
          const SizedBox(height: 6),
          Text(
            l10n.supportTypeHint,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          _buildTypeTile(
            context,
            type: SupportTicketType.ui,
            icon: Icons.palette_outlined,
            label: l10n.supportTypeUi,
          ),
          _buildTypeTile(
            context,
            type: SupportTicketType.error,
            icon: Icons.bug_report_outlined,
            label: l10n.supportTypeError,
          ),
          _buildTypeTile(
            context,
            type: SupportTicketType.other,
            icon: Icons.more_horiz_rounded,
            label: l10n.supportTypeOther,
          ),
          const SizedBox(height: 26),
          AtlasTextField(
            controller: _subjectController,
            label: l10n.supportSubjectLabel,
            hint: l10n.supportSubjectHint,
            maxLength: SupportService.subjectMaxLength,
            // The stored subject gets a "[Error] " style prefix, so a counter
            // here would not match what actually lands in Supabase. The cap is
            // still enforced, just not advertised.
            counterText: '',
            onChanged: (_) {
              if (_serviceError == SupportTicketError.subjectRequired ||
                  _serviceError == SupportTicketError.subjectTooLong) {
                setState(() => _serviceError = null);
              }
            },
          ),
          const SizedBox(height: 22),
          AtlasTextField(
            controller: _messageController,
            label: l10n.supportMessageLabel,
            hint: l10n.supportMessageHint,
            keyboardType: TextInputType.multiline,
            minLines: 5,
            maxLines: 8,
            maxLength: SupportService.messageMaxLength,
            counterText: '',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              l10n.supportMessageCounter(
                _messageController.text.length,
                SupportService.messageMaxLength,
              ),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildOfflineNotice(context, l10n),
          if (errorText != null) ...[
            _buildErrorBanner(context, errorText),
            const SizedBox(height: 18),
          ],
          AtlasButton(
            label: l10n.supportSubmitButton,
            useGradient: true,
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        letterSpacing: 1.2,
      ),
    );
  }

  /// One selectable "type of problem" row. Built by hand rather than with
  /// [AtlasCard] so the selected state can tint both the fill and the border.
  Widget _buildTypeTile(
    BuildContext context, {
    required SupportTicketType type,
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isSelected = _type == type;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _submitting
              ? null
              : () => setState(() {
                    _type = type;
                    _typeMissing = false;
                  }),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderOf(context),
                width: isSelected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : AppColors.surfaceSubtleOf(context),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? AppColors.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: isSelected
                      ? AppColors.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.25),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Warns before the player taps submit. The service call would fail anyway
  /// (the write never leaves the device), but saying so up front beats a
  /// generic error after the fact.
  Widget _buildOfflineNotice(BuildContext context, AppLocalizations l10n) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.isOnline,
      builder: (context, isOnline, _) {
        if (isOnline) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 18,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.supportOfflineNotice,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Terminal states
  // ---------------------------------------------------------------------------

  Widget _buildSuccess(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 52,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.supportSuccessTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.supportSuccessBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            AtlasButton(
              label: l10n.supportSuccessDone,
              useGradient: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInRequired(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.supportSignInTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.supportSignInBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            AtlasButton(
              label: l10n.signInTab,
              useGradient: true,
              // AuthForm replaces the whole stack once sign-in succeeds, so
              // this does not leave a settings screen behind the auth flow.
              onPressed: () => Navigator.pushNamed(context, '/auth'),
            ),
          ],
        ),
      ),
    );
  }
}
