import 'package:flutter/material.dart';
import 'package:atlas_ui/shared/widgets/ChessBoard.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/shared/widgets/ChessboardSettings.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:chess/chess.dart' as chess;

class ChessboardTest extends StatefulWidget {
  const ChessboardTest({super.key});

  @override
  State<ChessboardTest> createState() => _ChessboardTestState();
}

class _ChessboardTestState extends State<ChessboardTest> {
  late ChessboardController _controller;
  ChessboardSettings _settings = const ChessboardSettings();

  @override
  void initState() {
    super.initState();
    _controller = ChessboardController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text('Chessboard Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _controller.reset()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Interactive Chessboard Component',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Test drag & drop, legal moves, and settings below.',
              style: TextStyle(color: AppColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: 32),
            ChessBoard(
              controller: _controller,
              settings: _settings,
              onSettingsChanged: (newSettings) {
                setState(() => _settings = newSettings);
              },
            ),
            const SizedBox(height: 32),
            _buildInfoCard(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Debug Info',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
_infoRow('Turn', _controller.game.turn == chess.Color.WHITE ? 'White' : 'Black'),
                  _infoRow('FEN', _controller.game.fen),
                  _infoRow('Selected', _controller.selectedSquare ?? 'None'),
                  _infoRow('Piece Set', _settings.pieceSet.name),
                  _infoRow('Board', _settings.boardTheme.name),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context), fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}



