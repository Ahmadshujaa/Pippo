import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/shared/widgets/AtlasButton.dart';
import 'package:atlas_ui/shared/widgets/AtlasTextField.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({super.key});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sign In
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  // Sign Up
  final _signUpFirstNameController = TextEditingController();
  final _signUpLastNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();

  bool _isSignInValid = false;
  bool _isSignUpValid = false;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  final _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _signInEmailController.addListener(_validateSignIn);
    _signInPasswordController.addListener(_validateSignIn);
    _signUpFirstNameController.addListener(_validateSignUp);
    _signUpLastNameController.addListener(_validateSignUp);
    _signUpEmailController.addListener(_validateSignUp);
    _signUpPasswordController.addListener(_validateSignUp);
    _signUpConfirmPasswordController.addListener(_validateSignUp);
  }

  void _validateSignIn() {
    setState(() {
      _isSignInValid =
          _emailRegex.hasMatch(_signInEmailController.text) &&
          _signInPasswordController.text.length >= 6;
    });
  }

  void _validateSignUp() {
    final pw = _signUpPasswordController.text;
    setState(() {
      _isSignUpValid =
          _signUpFirstNameController.text.isNotEmpty &&
          _signUpLastNameController.text.isNotEmpty &&
          _emailRegex.hasMatch(_signUpEmailController.text) &&
          pw.length >= 8 &&
          RegExp(r'[A-Z]').hasMatch(pw) &&
          RegExp(r'[a-z]').hasMatch(pw) &&
          RegExp(r'[0-9]').hasMatch(pw) &&
          pw == _signUpConfirmPasswordController.text;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpFirstNameController.dispose();
    _signUpLastNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  // ===== Auth Actions =====

  /// Sends a freshly authenticated account where it belongs. Shared by every
  /// sign-in path so email and Google behave identically — an account that
  /// has not chosen a display name yet must be prompted for one, instead of
  /// landing on the home screen labelled "Player".
  Future<void> _routeAfterAuth() async {
    final route =
        await AuthApiService.postAuthRoute(); // '/home' or '/onboarding'
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await AuthApiService.signIn(
      email: _signInEmailController.text,
      password: _signInPasswordController.text,
    );

    if (!mounted) return;

    if (result.success) {
      await _routeAfterAuth();
    } else {
      setState(() {
        _loading = false;
        _errorMessage = result.error;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await AuthApiService.signInWithGoogle();

    if (!mounted) return;

    if (result.success) {
      await _routeAfterAuth();
    } else if (result.cancelled) {
      // The user backed out of the Google sheet: no error banner, just stop
      // spinning so they can try again.
      setState(() => _loading = false);
    } else {
      setState(() {
        _loading = false;
        _errorMessage = result.error;
      });
    }
  }

  Future<void> _handleSignUp() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final fullName =
        '${_signUpFirstNameController.text.trim()} ${_signUpLastNameController.text.trim()}';
    final email = _signUpEmailController.text.trim();

    final result = await AuthApiService.signUp(
      email: email,
      password: _signUpPasswordController.text,
      fullName: fullName,
    );

    setState(() => _loading = false);

    if (result.success) {
      if (!mounted) return;
      if (result.requiresVerification) {
        Navigator.pushNamed(context, '/verify-otp', arguments: email);
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } else {
      setState(() => _errorMessage = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
          onPressed: () => Navigator.pop(context),
        ),
        title: ListenableBuilder(
          listenable: _tabController,
          builder: (context, child) {
            return Text(
              _tabController.index == 0 ? l10n.signInTab : l10n.createAccountTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildCustomToggle(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  AtlasButton(
                    label: l10n.continueWithGoogle,
                    isPrimary: false,
                    icon: Icons.g_mobiledata,
                    onPressed: _loading ? null : _handleGoogleSignIn,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l10n.orLabel,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildSignInForm(), _buildSignUpForm()],
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListenableBuilder(
              listenable: _tabController,
              builder: (context, child) {
                final isSignIn = _tabController.index == 0;
                final isValid = isSignIn ? _isSignInValid : _isSignUpValid;
                return AtlasButton(
                  label: isSignIn ? l10n.signInTab : l10n.registerButton,
                  useGradient: true,
                  isLoading: _loading,
                  onPressed: isValid && !_loading
                      ? () => isSignIn ? _handleSignIn() : _handleSignUp()
                      : null,
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              // Replaces the auth stack: a guest who later signs in through the
              // back button would otherwise land back on a signed-out screen.
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              ),
              child: Text(
                l10n.continueAsGuest,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomToggle() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceSubtleDark : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: l10n.signInTab),
            Tab(text: l10n.signUpTab),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInForm() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.welcomeBackTitle,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.signInSubtitle,
            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 32),
          AtlasTextField(
            controller: _signInEmailController,
            label: l10n.emailLabel,
            hint: l10n.emailHint,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icon(
              Icons.email_outlined,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 20),
          AtlasTextField(
            controller: _signInPasswordController,
            label: l10n.passwordLabel,
            hint: '••••••••',
            obscureText: _obscurePassword,
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loading ? null : _showForgotPasswordSheet,
              child: Text(
                l10n.forgotPassword,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showForgotPasswordSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const ForgotPasswordSheet(),
    );

    if (result == null || !mounted) return;

    final profile = await AuthApiService.fetchDisplayName();
    if (!mounted) return;

    if (!profile.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                profile.error ?? AppLocalizations.of(context).passwordUpdated)),
      );
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      profile.displayName == null || profile.displayName!.isEmpty
          ? '/onboarding'
          : '/home',
      (route) => false,
    );
  }

  Widget _buildSignUpForm() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.createAccountTitle,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.signUpSubtitle,
            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: AtlasTextField(
                  controller: _signUpFirstNameController,
                  label: l10n.firstNameLabel,
                  hint: l10n.firstNameHint,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AtlasTextField(
                  controller: _signUpLastNameController,
                  label: l10n.lastNameLabel,
                  hint: l10n.lastNameHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AtlasTextField(
            controller: _signUpEmailController,
            label: l10n.emailLabel,
            hint: 'email@gmail.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icon(
              Icons.email_outlined,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 20),
          AtlasTextField(
            controller: _signUpPasswordController,
            label: l10n.passwordLabel,
            hint: '••••••••',
            obscureText: _obscurePassword,
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 20),
          AtlasTextField(
            controller: _signUpConfirmPasswordController,
            label: l10n.confirmPasswordLabel,
            hint: '••••••••',
            obscureText: _obscurePassword,
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-step password reset flow, fully client-side via Supabase:
/// 1) request a recovery code by email, 2) confirm code + new password.
class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = AppLocalizations.of(context).errEnterValidEmail);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthApiService.requestPasswordReset(email: email);

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _loading = false;
        _codeSent = true;
      });
    } else {
      setState(() {
        _loading = false;
        _error = result.error;
      });
    }
  }

  Future<void> _confirmReset() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;

    if (code.length < 6) {
      setState(
          () => _error = AppLocalizations.of(context).errEnterCodeFromEmail);
      return;
    }
    if (password != _confirmController.text) {
      setState(
          () => _error = AppLocalizations.of(context).errPasswordsDoNotMatch);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthApiService.confirmPasswordReset(
      email: _emailController.text.trim(),
      token: code,
      newPassword: password,
    );

    if (!mounted) return;

    if (result.success) {
      Navigator.pop(context, {'success': true});
    } else {
      setState(() {
        _loading = false;
        _error = result.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;

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
            _codeSent ? l10n.enterResetCodeTitle : l10n.resetPasswordTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            _codeSent
                ? l10n.resetCodeSentIntro(_emailController.text.trim())
                : l10n.resetIntro,
            style: TextStyle(fontSize: 14, color: onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            enabled: !_codeSent,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.emailLabel),
          ),
          if (_codeSent) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: InputDecoration(
                labelText: l10n.recoveryCodeLabel,
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.newPasswordLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration:
                  InputDecoration(labelText: l10n.confirmNewPasswordLabel),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: AtlasButton(
              label: _codeSent ? l10n.updatePassword : l10n.sendRecoveryCode,
              useGradient: true,
              isLoading: _loading,
              onPressed: _loading
                  ? null
                  : () => _codeSent ? _confirmReset() : _requestReset(),
            ),
          ),
        ],
      ),
    );
  }
}




