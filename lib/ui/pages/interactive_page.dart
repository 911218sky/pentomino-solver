/// Interactive puzzle tab - allows users to place pieces via drag-and-drop
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pentomino/core/algorithms/pentomino_solver.dart';
import 'package:pentomino/core/data/pentomino_data.dart';
import 'package:pentomino/ui/theme.dart';
import 'package:pentomino/ui/widgets/board_widget.dart';
import 'package:pentomino/ui/widgets/piece_preview.dart';

class _SolveParams {
  _SolveParams(this.board, this.usedPieces);
  final List<List<int>> board;
  final List<int> usedPieces;
}

List<List<List<int>>> _solvePartial(_SolveParams params) {
  return PentominoSolver().solveWithBoard(params.board, params.usedPieces.toSet());
}

class InteractiveTab extends StatefulWidget {
  const InteractiveTab({super.key});

  @override
  State<InteractiveTab> createState() => _InteractiveTabState();
}

class _InteractiveTabState extends State<InteractiveTab> with AutomaticKeepAliveClientMixin {
  late List<List<int>> _board;
  int? _selectedPiece;
  int _selectedVariant = 0;
  List<List<List<int>>> _possibleSolutions = [];
  bool _computing = false;
  final Set<int> _usedPieces = {};
  final FocusNode _focusNode = FocusNode();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _resetBoard();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _resetBoard() {
    _board = List.generate(6, (_) => List.filled(10, -1));
    _usedPieces.clear();
    _possibleSolutions = [];
    _selectedPiece = null;
    _selectedVariant = 0;
  }

  Future<void> _computeSolutions() async {
    if (_usedPieces.isEmpty) {
      setState(() => _possibleSolutions = []);
      return;
    }
    setState(() => _computing = true);
    final boardCopy = _board.map((r) => r.toList()).toList();
    final usedCopy = _usedPieces.toList();
    final results = await compute(_solvePartial, _SolveParams(boardCopy, usedCopy));
    setState(() {
      _possibleSolutions = results;
      _computing = false;
    });
  }

  void _onCellTap(int r, int c) {
    setState(() {
      if (_board[r][c] >= 0) {
        final piece = _board[r][c];
        for (var i = 0; i < 6; i++) {
          for (var j = 0; j < 10; j++) {
            if (_board[i][j] == piece) _board[i][j] = -1;
          }
        }
        _usedPieces.remove(piece);
      } else if (_selectedPiece != null && !_usedPieces.contains(_selectedPiece)) {
        if (_tryPlace(r, c, _selectedPiece!, _selectedVariant)) {
          _usedPieces.add(_selectedPiece!);
          _selectedPiece = null;
          _selectedVariant = 0;
        }
      }
    });
    _computeSolutions();
  }

  void _onPieceDrop(int r, int c, int pieceIndex, int variantIndex) {
    if (_usedPieces.contains(pieceIndex)) return;
    setState(() {
      if (_tryPlace(r, c, pieceIndex, variantIndex)) {
        _usedPieces.add(pieceIndex);
        if (_selectedPiece == pieceIndex) {
          _selectedPiece = null;
          _selectedVariant = 0;
        }
      }
    });
    _computeSolutions();
  }

  bool _tryPlace(int r, int c, int pieceIdx, int variantIdx) {
    final shape = getShapeVariant(pieceIdx, variantIdx);
    
    // Try placing with (r,c) as each cell of the shape
    for (final anchor in shape) {
      final dr = r - anchor[0];
      final dc = c - anchor[1];
      var canPlace = true;
      final cells = <List<int>>[];
      
      for (final cell in shape) {
        final nr = cell[0] + dr;
        final nc = cell[1] + dc;
        if (nr < 0 || nr >= 6 || nc < 0 || nc >= 10 || _board[nr][nc] >= 0) {
          canPlace = false;
          break;
        }
        cells.add([nr, nc]);
      }
      
      if (canPlace) {
        for (final cell in cells) {
          _board[cell[0]][cell[1]] = pieceIdx;
        }
        return true;
      }
    }
    return false;
  }

  /// Apply a solution to the board
  void _applySolution(List<List<int>> solution) {
    setState(() {
      _board = solution.map((r) => r.toList()).toList();
      _usedPieces.clear();
      for (var r = 0; r < 6; r++) {
        for (var c = 0; c < 10; c++) {
          if (_board[r][c] >= 0) {
            _usedPieces.add(_board[r][c]);
          }
        }
      }
      _selectedPiece = null;
      _selectedVariant = 0;
      _possibleSolutions = [solution];
    });
  }

  void _rotateSelected() {
    if (_selectedPiece == null) return;
    setState(() {
      final total = getVariantCount(_selectedPiece!);
      _selectedVariant = (_selectedVariant + 1) % total;
    });
  }

  void _flipSelected() {
    if (_selectedPiece == null) return;
    setState(() {
      final total = getVariantCount(_selectedPiece!);
      _selectedVariant = (_selectedVariant + total ~/ 2) % total;
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      _rotateSelected();
    } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
      _flipSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800) return _buildVerticalLayout();
          return _buildHorizontalLayout();
        },
      ),
    );
  }

  Widget _buildHorizontalLayout() => Row(
        children: [
          _buildPieceSelector(),
          Expanded(flex: 2, child: _buildBoardArea()),
          _buildSolutionsPanel(),
        ],
      );

  Widget _buildVerticalLayout() => Column(
        children: [
          SizedBox(height: 90, child: _buildPieceSelectorHorizontal()),
          Expanded(child: _buildBoardArea()),
          SizedBox(height: 140, child: _buildSolutionsPanelHorizontal()),
        ],
      );

  Widget _buildPieceSelector() => Container(
        width: 140,
        margin: const EdgeInsets.all(8),
        child: Card(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.extension, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('Pieces', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(6),
                  itemCount: 12,
                  itemBuilder: (_, i) => DraggablePiece(
                    pieceIndex: i,
                    variantIndex: _selectedPiece == i ? _selectedVariant : 0,
                    color: pieceColors[i],
                    isUsed: _usedPieces.contains(i),
                    isSelected: _selectedPiece == i,
                    onTap: () => setState(() {
                      _selectedPiece = _selectedPiece == i ? null : i;
                      _selectedVariant = 0;
                    }),
                    onVariantChange: (v) {
                      if (_selectedPiece == i) {
                        setState(() => _selectedVariant = v);
                      }
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(_resetBoard),
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('Reset', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildPieceSelectorHorizontal() => Card(
        margin: const EdgeInsets.all(6),
        child: Row(
          children: [
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(6),
                itemCount: 12,
                itemBuilder: (_, i) => _buildDraggableChip(i),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: IconButton(
                onPressed: () => setState(_resetBoard),
                icon: const Icon(Icons.refresh, size: 20),
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );

  Widget _buildDraggableChip(int i) {
    final used = _usedPieces.contains(i);
    final selected = _selectedPiece == i;
    final variant = selected ? _selectedVariant : 0;

    if (used) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Chip(
          backgroundColor: Colors.grey.shade300,
          avatar: SizedBox(
            width: 20,
            height: 20,
            child: PiecePreview(pieceIndex: i, color: Colors.grey),
          ),
          label: Text(
            pieceNames[i],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: _HorizontalDraggableChip(
        pieceIndex: i,
        variant: variant,
        isSelected: selected,
        onTap: () => setState(() {
          _selectedPiece = selected ? null : i;
          _selectedVariant = 0;
        }),
      ),
    );
  }

  Widget _buildBoardArea() => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInstructions(),
              const SizedBox(height: 12),
              if (_selectedPiece != null) ...[
                PiecePreviewWithControls(
                  pieceIndex: _selectedPiece!,
                  variantIndex: _selectedVariant,
                  color: pieceColors[_selectedPiece!],
                  totalVariants: getVariantCount(_selectedPiece!),
                  onRotate: _rotateSelected,
                  onFlip: _flipSelected,
                ),
                const SizedBox(height: 12),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: InteractiveBoard(
                    board: _board,
                    onCellTap: _onCellTap,
                    onPieceDrop: _onPieceDrop,
                    cellSize: 42,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildStatus(),
            ],
          ),
        ),
      );

  Widget _buildInstructions() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          _selectedPiece != null
              ? 'Drag to board or click • R: rotate, F: flip'
              : 'Drag pieces to board • Click placed piece to remove',
          style: const TextStyle(color: AppColors.primary, fontSize: 12),
        ),
      );

  Widget _buildStatus() {
    if (_computing) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
          SizedBox(width: 6),
          Text('Computing...', style: TextStyle(fontSize: 12)),
        ],
      );
    }
    if (_usedPieces.isEmpty) {
      return const Text('Place pieces to see solutions', style: TextStyle(color: AppColors.textSecondary, fontSize: 12));
    }
    final hasNoSolution = _possibleSolutions.isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasNoSolution ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasNoSolution ? Icons.warning_rounded : Icons.lightbulb_rounded, size: 16, color: hasNoSolution ? AppColors.error : AppColors.success),
          const SizedBox(width: 4),
          Text(
            hasNoSolution ? 'No solutions' : '${_possibleSolutions.length} solution${_possibleSolutions.length == 1 ? '' : 's'}',
            style: TextStyle(fontWeight: FontWeight.w600, color: hasNoSolution ? AppColors.error : AppColors.success, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionsPanel() => Container(
        width: 220,
        margin: const EdgeInsets.all(8),
        child: Card(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    const Text('Solutions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    if (_possibleSolutions.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                        child: Text('${_possibleSolutions.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              Expanded(child: _buildSolutionsList()),
            ],
          ),
        ),
      );

  Widget _buildSolutionsList() {
    if (_possibleSolutions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_usedPieces.isEmpty ? Icons.touch_app : Icons.search_off, size: 32, color: AppColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 6),
              Text(
                _usedPieces.isEmpty ? 'Place pieces' : (_computing ? '' : 'No solutions'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(6),
      itemCount: _possibleSolutions.length,
      cacheExtent: 300,
      itemBuilder: (_, i) => RepaintBoundary(
        child: _SolutionItem(
          board: _possibleSolutions[i],
          index: i + 1,
          onApply: () => _applySolution(_possibleSolutions[i]),
        ),
      ),
    );
  }

  Widget _buildSolutionsPanelHorizontal() => Card(
        margin: const EdgeInsets.all(6),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('Solutions: ${_possibleSolutions.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              child: _possibleSolutions.isEmpty
                  ? Center(child: Text(_usedPieces.isEmpty ? 'Place pieces' : 'No solutions', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      itemCount: _possibleSolutions.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => _applySolution(_possibleSolutions[i]),
                          child: Column(
                            children: [
                              Text('#${i + 1}', style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold)),
                              Expanded(child: SizedBox(width: 100, child: BoardWidget(board: _possibleSolutions[i], showLabels: false))),
                              const Text('Tap to apply', style: TextStyle(fontSize: 8, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      );
}

/// Solution item with apply button
class _SolutionItem extends StatelessWidget {
  const _SolutionItem({
    required this.board,
    required this.index,
    required this.onApply,
  });

  final List<List<int>> board;
  final int index;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Card(
        color: AppColors.background,
        child: InkWell(
          onTap: onApply,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#$index', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 10, color: AppColors.primary),
                          SizedBox(width: 2),
                          Text('Apply', style: TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(height: 50, child: BoardWidget(board: board, showLabels: false)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal draggable chip with keyboard rotation
class _HorizontalDraggableChip extends StatefulWidget {
  const _HorizontalDraggableChip({
    required this.pieceIndex,
    required this.variant,
    required this.isSelected,
    required this.onTap,
  });

  final int pieceIndex;
  final int variant;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_HorizontalDraggableChip> createState() => _HorizontalDraggableChipState();
}

class _HorizontalDraggableChipState extends State<_HorizontalDraggableChip> {
  late int _variant;

  @override
  void initState() {
    super.initState();
    _variant = widget.variant;
  }

  @override
  void didUpdateWidget(_HorizontalDraggableChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _variant = widget.variant;
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<DragPieceData>(
      data: DragPieceData(pieceIndex: widget.pieceIndex, variantIndex: _variant),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragEnd: (_) => DragPieceData.clearActive(),
      onDraggableCanceled: (_, __) => DragPieceData.clearActive(),
      feedback: _DragFeedbackChip(
        pieceIndex: widget.pieceIndex,
        initialVariant: _variant,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Chip(
          backgroundColor: widget.isSelected ? pieceColors[widget.pieceIndex] : pieceColors[widget.pieceIndex].withValues(alpha: 0.3),
          avatar: SizedBox(
            width: 20,
            height: 20,
            child: PiecePreview(pieceIndex: widget.pieceIndex, variantIndex: _variant, color: pieceColors[widget.pieceIndex]),
          ),
          label: Text(
            pieceNames[widget.pieceIndex],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.isSelected ? Colors.white : AppColors.text,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _DragFeedbackChip extends StatefulWidget {
  const _DragFeedbackChip({
    required this.pieceIndex,
    required this.initialVariant,
  });

  final int pieceIndex;
  final int initialVariant;

  @override
  State<_DragFeedbackChip> createState() => _DragFeedbackChipState();
}

class _DragFeedbackChipState extends State<_DragFeedbackChip> {
  late int _variant;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _variant = widget.initialVariant;
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        final total = getVariantCount(widget.pieceIndex);
        if (event.logicalKey == LogicalKeyboardKey.keyR) {
          setState(() => _variant = (_variant + 1) % total);
          DragPieceData.updateActiveVariant(widget.pieceIndex, _variant);
        } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
          setState(() => _variant = (_variant + total ~/ 2) % total);
          DragPieceData.updateActiveVariant(widget.pieceIndex, _variant);
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('R: rotate  F: flip', style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 80,
              height: 80,
              child: PiecePreview(
                pieceIndex: widget.pieceIndex,
                variantIndex: _variant,
                color: pieceColors[widget.pieceIndex].withValues(alpha: 0.85),
                showBorder: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
