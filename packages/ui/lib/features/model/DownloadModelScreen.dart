import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/shared/widgets/PippoAvatar.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';
import 'package:atlas_core/atlas_core.dart';

class DownloadModelScreen extends StatefulWidget {
  const DownloadModelScreen({super.key});

  @override
  State<DownloadModelScreen> createState() => _DownloadModelScreenState();
}

class _DownloadModelScreenState extends State<DownloadModelScreen> {
  bool _isDownloading = false;
  bool _isLoadingEngine = false;
  String? _errorMessage;
  int _receivedBytes = 0;
  int? _totalBytes;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    try {
      final downloaded = await ModelApiService.isModelDownloaded();
      if (downloaded) {
        _startEngine();
      }
    } catch (e) {
      // If error checking, just show download screen
    }
  }

  Future<void> _startEngine() async {
    if (!mounted) return;
    setState(() {
      _isLoadingEngine = true;
      _errorMessage = null;
    });

    try {
      await PippoEngineService.instance.loadModel();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/play');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingEngine = false;
          _errorMessage = 'Failed to load engine: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _handleDownload() async {
    // No runtime permission gate is needed: the model is stored in the app's own
    // private storage (android.permission.STORAGE), which Android grants to
    // every app at install time on all phones. The old build instead required
    // the sensitive MANAGE_EXTERNAL_STORAGE ("All files access") permission,
    // which only some devices (e.g. Samsung) actually granted.
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _receivedBytes = 0;
      _totalBytes = null;
    });

    try {
      await ModelApiService.downloadModel(
        onProgress: (received, total) {
          setState(() {
            _receivedBytes = received;
            _totalBytes = total;
          });
        },
      );
      if (mounted) {
        setState(() => _isDownloading = false);
        _startEngine();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = _totalBytes != null && _totalBytes! > 0
        ? _receivedBytes / _totalBytes!
        : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text('Pippo'),
        backgroundColor: AppColors.backgroundOf(context),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PippoAvatar(size: 64, cornerRadius: 20),
              const SizedBox(height: 24),
              Text(
                'Pippo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context)),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage != null
                    ? _errorMessage!
                    : _isLoadingEngine
                        ? l10n.startingEngineStatus
                        : l10n.downloadPippoPrompt,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14),
              ),
              const SizedBox(height: 32),
              if (_isLoadingEngine) ...[
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 20),
              ] else if (_isDownloading && progress != null) ...[
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceSubtleOf(context),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.downloadProgressMbLabel(
                    (_receivedBytes / 1024 / 1024).toStringAsFixed(1),
                    (_totalBytes! / 1024 / 1024).toStringAsFixed(1),
                  ),
                  style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
                ),
                const SizedBox(height: 20),
              ] else if (_isDownloading) ...[
                LinearProgressIndicator(
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceSubtleOf(context),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.downloadingStatus,
                  style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
                ),
                const SizedBox(height: 20),
              ],
              if (!_isLoadingEngine)
                ElevatedButton(
                  onPressed: _isDownloading ? null : _handleDownload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isDownloading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : Text(l10n.downloadEngineButton, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}