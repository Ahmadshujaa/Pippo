import 'package:flutter/material.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/features/dashboard/HomeScreen.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

class Auth extends StatelessWidget {
  const Auth({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final textSecondaryColor = isDark ? Colors.white54 : Colors.black54;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.getStartedTitle,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.signInOrSignUpSubtitle,
                style: TextStyle(fontSize: 16, color: textSecondaryColor),
              ),
              const Spacer(),

              // Continue with Google Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await AuthApiService.signInWithGoogle();
                    if (!context.mounted) return;

                    if (result.success) {
                      // '/home' for an account that already has a display name,
                      // '/onboarding' otherwise — same rule the email flow uses.
                      final route = await AuthApiService.postAuthRoute();
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        route,
                        (route) => false,
                      );
                    } else if (!result.cancelled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result.error ??
                                l10n.errGoogleSignIn,
                          ),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    Icons.g_mobiledata,
                    size: 32,
                    color: textColor,
                  ),
                  label: Text(
                    l10n.continueWithGoogle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Continue as Guest Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Home(),
                      ),
                      (route) => false,
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: textSecondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.continueAsGuest,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}





