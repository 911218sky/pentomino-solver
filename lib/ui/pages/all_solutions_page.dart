/// All solutions tab - displays all puzzle solutions in a grid
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pentomino/core/pentomino_solver.dart';
import 'package:pentomino/ui/theme.dart';

class AllSolutionsTab extends StatefulWidget {
  const AllSolutionsTab({super.key});

  @override
  State<AllSolutionsTab> createState() => _AllSolutionsTabState();
}

class _AllSolutionsTabState extends State<AllSolutionsTab> with AutomaticKeepAliveClientMixin {
  final List<List<List<int>>> _solutions = [];
  bool _solving = false;
  bool _completed = false;
  Duration? _solveTime;
  StreamSubscription<List<List<int>>>? _subscription;
  Stopwatch? _stopwatch;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _solve() {
    _subscription?.cancel();
    
    setState(() {
      _solving = true;
      _completed = false;
      _solutions.clear();
      _solveTime = null;
    });

    _stopwatch = Stopwatch()..start();
    final solver = PentominoSolver();
    
    var updateCounter = 0;
    _subscription = solver.solveStream().listen(
      (solution) {
        _solutions.add(solution);
        updateCounter++;
        // Update UI every 50 solutions for performance
        if (updateCounter % 50 == 0) {
          setState(() {});
        }
      },
      onDone: () {
        _stopwatch?.stop();
        setState(() {
          _solveTime = _stopwatch?.elapsed;
          _solving = false;
          _completed = true;
        });
      },
      onError: (Object e) {
        setState(() {
          _solving = false;
        });
      },
    );
  }

  void _stop() {
    _subscription?.cancel();
    _stopwatch?.stop();
    setState(() {
      _solveTime = _stopwatch?.elapsed;
      _solving = false;
      _completed = _solutions.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 10,
        children: [
          if (_solving)
            ElevatedButton.icon(
              onPressed: _stop,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              icon: const Icon(Icons.stop_rounded, size: 20),
              label: const Text('Stop', style: TextStyle(fontSize: 14)),
            )
          else
            ElevatedButton.icon(
              onPressed: _solve,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Find All', style: TextStyle(fontSize: 14)),
            ),
          if (_solving || _solutions.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _completed 
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _completed 
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_solving)
                    const SizedBox(
                      width: 16, 
                      height: 16, 
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.check_circle_rounded, 
                      color: _completed ? AppColors.success : AppColors.primary, 
                      size: 18,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _solving 
                        ? '${_solutions.length} solutions found...'
                        : '${_solutions.length} solutions • ${_solveTime?.inMilliseconds ?? 0}ms',
                    style: TextStyle(
                      color: _completed ? AppColors.success : AppColors.primary, 
                      fontWeight: FontWeight.w600, 
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          if (_solving)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${(_solutions.length / 2339 * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_solutions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _solving ? Icons.hourglass_top_rounded : Icons.grid_view_rounded,
                size: 48,
                color: _solving ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _solving ? 'Computing solutions...' : 'Click "Find All" to discover solutions',
              style: TextStyle(
                color: _solving ? AppColors.text : AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_solving) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _solutions.length / 2339,
                  backgroundColor: const Color(0xFFE8ECF4),
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_solving)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(
              value: _solutions.length / 2339,
              backgroundColor: const Color(0xFFE8ECF4),
              color: AppColors.primary,
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              childAspectRatio: 1.4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _solutions.length,
            cacheExtent: 800,
            itemBuilder: (ctx, i) => RepaintBoundary(
              child: _SolutionCard(
                key: ValueKey(i),
                board: _solutions[i],
                index: i + 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SolutionCard extends StatelessWidget {
  const _SolutionCard({required this.board, required this.index, super.key});

  final List<List<int>> board;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(16),
        hoverColor: AppColors.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '#$index',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(child: _MiniBoard(board: board)),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFB7299), Color(0xFFA66CFF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Solution #$index',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(width: 400, height: 240, child: _DetailBoard(board: board)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optimized mini board using CustomPaint for better performance
class _MiniBoard extends StatelessWidget {
  const _MiniBoard({required this.board});

  final List<List<int>> board;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _BoardPainter(board: board, showLabels: false),
        );
      },
    );
  }
}

/// Detail board with labels
class _DetailBoard extends StatelessWidget {
  const _DetailBoard({required this.board});

  final List<List<int>> board;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _BoardPainter(board: board, showLabels: true),
        );
      },
    );
  }
}

/// Custom painter for efficient board rendering
class _BoardPainter extends CustomPainter {
  _BoardPainter({required this.board, required this.showLabels});

  final List<List<int>> board;
  final bool showLabels;

  static const _pieceNames = ['F', 'I', 'L', 'N', 'P', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];
  static const _pieceColors = [
    Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFF5B8DEE), Color(0xFFFFE66D),
    Color(0xFFA66CFF), Color(0xFF2ED573), Color(0xFFFF9F43), Color(0xFF778CA3),
    Color(0xFFD4A574), Color(0xFF7BED9F), Color(0xFFFF85A2), Color(0xFF70A1FF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / 10;
    final cellH = size.height / 6;
    final cellSize = cellW < cellH ? cellW : cellH;
    
    final offsetX = (size.width - cellSize * 10) / 2;
    final offsetY = (size.height - cellSize * 6) / 2;

    final paint = Paint();
    final borderPaint = Paint()
      ..color = const Color(0xFFE8ECF4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Draw rounded background
    final outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(offsetX - 1, offsetY - 1, cellSize * 10 + 2, cellSize * 6 + 2),
      const Radius.circular(4),
    );
    canvas.drawRRect(outerRect, Paint()..color = const Color(0xFFF8F9FC));

    for (var r = 0; r < 6; r++) {
      for (var c = 0; c < 10; c++) {
        final idx = board[r][c];
        final rect = Rect.fromLTWH(
          offsetX + c * cellSize,
          offsetY + r * cellSize,
          cellSize,
          cellSize,
        );

        // Fill with slight rounding for corner cells
        paint.color = idx >= 0 ? _pieceColors[idx] : const Color(0xFFFAFBFD);
        canvas.drawRect(rect, paint);

        // Border
        canvas.drawRect(rect, borderPaint);

        // Label
        if (showLabels && idx >= 0 && cellSize > 20) {
          textPainter.text = TextSpan(
            text: _pieceNames[idx],
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: cellSize * 0.38,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 2,
                ),
              ],
            ),
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(
              rect.center.dx - textPainter.width / 2,
              rect.center.dy - textPainter.height / 2,
            ),
          );
        }
      }
    }

    // Outer border
    final borderRect = Rect.fromLTWH(offsetX, offsetY, cellSize * 10, cellSize * 6);
    canvas.drawRect(
      borderRect,
      Paint()
        ..color = const Color(0xFF18191C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_BoardPainter oldDelegate) {
    return oldDelegate.board != board || oldDelegate.showLabels != showLabels;
  }
}
