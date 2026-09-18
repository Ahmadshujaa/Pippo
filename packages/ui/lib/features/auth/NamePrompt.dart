import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/shared/widgets/AtlasButton.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

class NamePrompt extends StatefulWidget {
  const NamePrompt({super.key});

  @override
  State<NamePrompt> createState() => _NamePromptState();
}

class _NamePromptState extends State<NamePrompt> {
  final TextEditingController _nameController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submitName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthApiService.updateDisplayName(name);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() => _error = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 32),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.namePromptTitle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.namePromptSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 48),
                      TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: l10n.yourNameHint,
                          hintStyle: TextStyle(color: Colors.grey.shade300),
                          border: InputBorder.none,
                        ),
                        maxLength: 10,
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                      const Spacer(),
                      AtlasButton(
                        label: l10n.getStartedTitle,
                        isLoading: _loading,
                        onPressed: _loading ? null : _submitName,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}




