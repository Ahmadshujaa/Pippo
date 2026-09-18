import 'package:flutter/material.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/atlas_ui.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key});

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  // Placeholder until [_loadProfile] answers; the header is not shown before
  // then, so no user ever sees this value.
  String _displayName = '';
  String? _email;
  PlanStatus _planStatus = PlanStatus.guest;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final email = AuthService.userEmail;
    final results = await Future.wait([
      AuthApiService.fetchDisplayName(),
      AuthApiService.getPlanStatus(),
    ]);
    if (!mounted) return;
    final profile = results[0] as DisplayNameResult;
    setState(() {
      _email = email;
      _displayName =
          profile.displayName ?? AppLocalizations.of(context).defaultPlayerName;
      _planStatus = results[1] as PlanStatus;
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.settingsTitle,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context, l10n),
            const SizedBox(height: 32),
            _buildSectionHeader(context, l10n.appSettingsSection),
            const SizedBox(height: 16),
            _buildSettingsItem(
              context,
              icon: Icons.palette_outlined,
              title: l10n.appearanceTitle,
              subtitle: l10n.appearanceSubtitle,
              onTap: () => _showThemeSelector(context),
            ),
            _buildSettingsItem(
              context,
              icon: Icons.payments_outlined,
              title: l10n.subscriptionTitle,
              subtitle: l10n.subscriptionSubtitle,
              onTap: () {},
            ),
            _buildSettingsItem(
              context,
              icon: Icons.language_rounded,
              title: l10n.languageTitle,
              subtitle: _languageSubtitle(l10n),
              onTap: () => _showLanguageSelector(context),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader(context, l10n.supportSection),
            const SizedBox(height: 16),
            _buildSettingsItem(
              context,
              icon: Icons.support_agent_rounded,
              title: l10n.contactSupportTitle,
              subtitle: l10n.contactSupportSubtitle,
              onTap: () => Navigator.pushNamed(context, '/contact-support'),
            ),
            const SizedBox(height: 40),
            _buildLogoutButton(context, l10n),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  /// Native language name for the subtitle; "System Default" is localized.
  String _languageSubtitle(AppLocalizations l10n) {
    final current = LocaleService.locale.value;
    if (current == null) return l10n.systemLanguage;
    return LocaleService.supportedLanguages
        .firstWhere(
          (l) => l.locale.languageCode == current.languageCode,
          orElse: () => LocaleService.supportedLanguages.first,
        )
        .nativeName;
  }

  Widget _buildProfileHeader(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isPremium = _planStatus.isAdmin || _planStatus.isPro;
    return AtlasCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email ?? l10n.notSignedIn,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPremium
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _planLabel(l10n),
                    style: TextStyle(
                      color: isPremium
                          ? AppColors.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEditDisplayNameSheet(context),
            icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
          ),
        ],
      ),
    );
  }

  String _planLabel(AppLocalizations l10n) {
    switch (_planStatus.plan) {
      case 'admin':
        return l10n.planAdmin;
      case 'pro':
      case 'referral':
      case 'lifetime':
        return l10n.planPro;
      default:
        return l10n.planFree;
    }
  }

  /// Renames the account: writes `profiles.name` in Supabase and mirrors the
  /// new value into the on-device cache (see UserProfileStore) so the home
  /// screen greets the user with it on the very next launch.
  ///
  /// Previously this only changed the label on this screen and the change was
  /// silently lost — the sheet closed as if it had saved.
  Future<void> _showEditDisplayNameSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: _displayName);

    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _EditDisplayNameSheet(
        l10n: l10n,
        controller: controller,
        initialName: _displayName,
      ),
    );

    controller.dispose();
    if (!mounted || saved == null) return;

    // The header itself is the confirmation: it now shows the persisted name.
    setState(() => _displayName = saved);
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AtlasCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? AppColors.surfaceSubtleDark
                    : AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.onSurface, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AppLocalizations l10n) {
    return InkWell(
      onTap: () async {
        await AuthService.clearSession();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            l10n.logout,
            style: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.chooseTheme,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildThemeOption(sheetContext, l10n, ThemeMode.light, l10n.lightMode, Icons.light_mode_rounded),
              _buildThemeOption(sheetContext, l10n, ThemeMode.dark, l10n.darkMode, Icons.dark_mode_rounded),
              _buildThemeOption(sheetContext, l10n, ThemeMode.system, l10n.systemDefault, Icons.settings_brightness_rounded),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(BuildContext context, AppLocalizations l10n, ThemeMode mode, String title, IconData icon) {
    final isSelected = ThemeService.themeMode.value == mode;
    return ListTile(
      onTap: () {
        ThemeService.setTheme(mode);
        Navigator.pop(context);
      },
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isSelected ? AppColors.primary : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      // The options list is taller than the default sheet height now that the
      // app ships six languages, so the sheet must be allowed to size itself
      // and scroll rather than overflow off the bottom of the screen.
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final current = LocaleService.locale.value?.languageCode;
        return SafeArea(
          child: ConstrainedBox(
            // Capped at three quarters of the screen: the heading stays put
            // while the list scrolls, so the sheet never grows past the
            // viewport however many languages we ship.
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Text(
                    l10n.languageSheetTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    children: [
                      ListTile(
                        onTap: () => _pickLanguage(sheetContext, null),
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.settings_brightness_rounded,
                          color: current == null ? AppColors.primary : null,
                        ),
                        title: Text(
                          l10n.systemLanguage,
                          style: TextStyle(
                            fontWeight: current == null
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: current == null ? AppColors.primary : null,
                          ),
                        ),
                        trailing: current == null
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary)
                            : null,
                      ),
                      // Language names stay native on purpose (an Arabic user
                      // can still find "Español" and vice versa).
                      for (final lang in LocaleService.supportedLanguages)
                        ListTile(
                          onTap: () => _pickLanguage(sheetContext, lang.locale),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            lang.nativeName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: current == lang.code
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: current == lang.code
                                  ? AppColors.primary
                                  : null,
                            ),
                          ),
                          trailing: current == lang.code
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary)
                              : null,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickLanguage(BuildContext sheetContext, Locale? newLocale) {
    LocaleService.setLocale(newLocale);
    Navigator.pop(sheetContext);
    // MaterialApp rebuilds via LocaleService.locale listener; this screen's
    // header refreshes through the inherited Localizations widget.
    setState(() {});
  }
}

/// Bottom sheet that performs the actual rename. Kept as its own stateful
/// widget so the sheet can show its own spinner/error without rebuilding the
/// settings screen behind it.
///
/// Pops with the saved name on success, or null when dismissed.
class _EditDisplayNameSheet extends StatefulWidget {
  const _EditDisplayNameSheet({
    required this.l10n,
    required this.controller,
    required this.initialName,
  });

  final AppLocalizations l10n;
  final TextEditingController controller;
  final String initialName;

  @override
  State<_EditDisplayNameSheet> createState() => _EditDisplayNameSheetState();
}

class _EditDisplayNameSheetState extends State<_EditDisplayNameSheet> {
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final newName = widget.controller.text.trim();
    if (newName.isEmpty) {
      setState(() => _error = 'Enter a name.');
      return;
    }
    if (newName == widget.initialName) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await AuthApiService.updateDisplayName(newName);

    if (!mounted) return;

    if (result.success) {
      Navigator.pop(context, newName);
      return;
    }

    setState(() {
      _saving = false;
      _error = result.error ?? 'Could not save your name.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.editDisplayName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.displayNameRule(10),
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: widget.controller,
            autofocus: true,
            maxLength: 10,
            enabled: !_saving,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _saving ? null : _save(),
            decoration: InputDecoration(
              labelText: l10n.displayNameLabel,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.save,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
