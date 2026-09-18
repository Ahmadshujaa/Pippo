import 'package:flutter/material.dart';
import 'package:atlas_ui/shared/widgets/ChessBoard.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/shared/widgets/ChessboardSettings.dart';
import 'package:atlas_ui/shared/widgets/AtlasButton.dart';
import 'package:atlas_ui/shared/widgets/AtlasCard.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';

class MoveClassificationTestScreen extends StatefulWidget {
  const MoveClassificationTestScreen({super.key});

  @override
  State<MoveClassificationTestScreen> createState() => _MoveClassificationTestScreenState();
}

class _MoveClassificationTestScreenState extends State<MoveClassificationTestScreen> {
  late ChessboardController _controller;
  final TextEditingController _fenController = TextEditingController(
    text: 'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3'
  );
  final TextEditingController _moveController = TextEditingController(text: 'f3e5');
  
  ClassificationResult? _result;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = ChessboardController();
    _updateBoardFromFen();
  }

  void _updateBoardFromFen() {
    try {
      _controller.loadFen(_fenController.text);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid FEN: $e')),
      );
    }
  }

  Future<void> _classify() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final res = await MoveClassificationService.instance.classifyMove(
        _fenController.text,
        _moveController.text,
      );
      if (!mounted) return;
      setState(() {
        _result = res;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Classification Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classification Lab'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fenController.text = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
              _moveController.text = 'e2e4';
              _updateBoardFromFen();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Move Classification Testing',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fenController,
              decoration: const InputDecoration(
                labelText: 'FEN (Before Move)',
                border: OutlineInputBorder(),
                hintText: 'Paste FEN here',
              ),
              onChanged: (_) => _updateBoardFromFen(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _moveController,
              decoration: const InputDecoration(
                labelText: 'Move (UCI)',
                border: OutlineInputBorder(),
                hintText: 'e.g. e2e4, f3e5',
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: ChessBoard(
                  controller: _controller,
                  settings: const ChessboardSettings(
                    enableDragAndDrop: false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AtlasButton(
              label: 'Classify Move',
              onPressed: _isLoading ? null : _classify,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 32),
            if (_result != null) _buildResultCard(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final res = _result!;
    final color = _getClassificationColor(res.classification);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analysis Result:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        AtlasCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      res.classification.name.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (res.isSacrifice)
                    const Icon(Icons.flash_on, color: Colors.orange),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                res.comment,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const Divider(height: 32),
              _statRow('Evaluation Before', res.evalBefore.toStringAsFixed(2)),
              _statRow('Evaluation After', res.evalAfter.toStringAsFixed(2)),
              _statRow('Best Move', res.bestMove),
              _statRow('EP Loss', res.loss.toStringAsFixed(3)),
              if (res.isPassiveSacrifice)
                _statRow('Passive Sacrifice', 'Yes (on ${res.sacrificedSquare})'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Color _getClassificationColor(MoveClassification classification) {
    switch (classification) {
      case MoveClassification.brilliant: return Colors.cyan;
      case MoveClassification.great: return Colors.blue;
      case MoveClassification.best: return Colors.green;
      case MoveClassification.excellent: return Colors.lightGreen;
      case MoveClassification.good: return Colors.grey;
      case MoveClassification.inaccuracy: return Colors.orange;
      case MoveClassification.mistake: return Colors.deepOrange;
      case MoveClassification.blunder: return Colors.red;
      case MoveClassification.book: return Colors.brown;
      case MoveClassification.forced: return Colors.blueGrey;
      case MoveClassification.miss: return Colors.deepOrangeAccent;
    }
  }
}
