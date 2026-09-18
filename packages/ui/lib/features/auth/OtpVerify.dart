import 'dart:async';
import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/shared/widgets/AtlasButton.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

class OtpVerify extends StatefulWidget {
  final String email;

  const OtpVerify({super.key, required this.email});

  @override
  State<OtpVerify> createState() => _OtpVerifyState();
}

class _OtpVerifyState extends State<OtpVerify> {
  final List<TextEditingController> _controllers = List.generate(8, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(8, (index) => FocusNode());
  
  bool _loading = false;
  bool _resending = false;
  String? _errorMessage;
  int _resendCooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendCooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown == 0) {
        timer.cancel();
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 8) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await AuthApiService.verifyOtp(
      email: widget.email,
      token: otp,
    );

    if (!mounted) return;

    if (result.success) {
      Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (route) => false);
    } else {
      setState(() {
        _loading = false;
        _errorMessage = result.error;
      });
    }
  }

  Future<void> _resendCode() async {
    if (_resendCooldown > 0 || _resending) return;

    setState(() {
      _resending = true;
      _errorMessage = null;
    });

    final result = await AuthApiService.resendOtp(email: widget.email);

    if (!mounted) return;

    setState(() => _resending = false);

    if (result.success) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).verificationCodeResent)),
      );
    } else {
      setState(() => _errorMessage = result.error);
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 7) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Auto-verify when last digit is entered
    if (_controllers.every((c) => c.text.isNotEmpty)) {
      _verifyOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.verifyEmailTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.enterVerificationCodeTitle,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
                  children: [
                    TextSpan(text: l10n.otpSentPrefix),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    TextSpan(text: l10n.otpSentSuffix),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(8, (index) => _buildOtpField(index)),
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AtlasButton(
                  label: l10n.verifyCodeButton,
                  isLoading: _loading,
                  useGradient: true,
                  onPressed: _controllers.any((c) => c.text.isEmpty) ? null : _verifyOtp,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.didntReceiveCode, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _resendCooldown == 0 ? _resendCode : null,
                    child: Text(
                      _resendCooldown == 0
                          ? l10n.resend
                          : l10n.resendInSeconds(_resendCooldown),
                      style: TextStyle(
                        color: _resendCooldown == 0 ? AppColors.primary : AppColors.textTertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return Container(
      width: 38,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _controllers[index].text.isNotEmpty ? AppColors.primary : AppColors.border,
          width: _controllers[index].text.isNotEmpty ? 2 : 1,
        ),
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          decoration: const InputDecoration(counterText: '', border: InputBorder.none),
          onChanged: (value) => _onOtpChanged(index, value),
        ),
      ),
    );
  }
}




