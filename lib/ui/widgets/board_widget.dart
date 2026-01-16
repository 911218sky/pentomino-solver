/// Board display widgets
library;

import 'package:flutter/material.dart';
import 'package:pentomino/core/pentomino_data.dart';
import 'package:pentomino/ui/theme.dart';

/// Static board display widget with flexible sizing
class BoardWidget extends StatelessWidget {
  const BoardWidget({
    required this.board,
    super.key,
    this.cellSize,
    this.showLabels = true,
  });

  final List<List<int>> board;
  final double? cellSize;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxCellWidth = constraints.maxWidth / 10;
        final maxCellHeight = constraints.maxHeight / 6;
        final size = cellSize ?? maxCellWidth.clamp(4.0, maxCellHeight.isFinite ? maxCellHeight : 40.0);

        return FittedBox(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.text),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                board.length,
                (r) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(board[r].length, (c) {
                    final idx = board[r][c];
                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: idx >= 0 ? pieceColors[idx] : Colors.white,
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: showLabels && idx >= 0 && size > 15
                          ? Center(
                              child: Text(
                                pieceNames[idx],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: (size * 0.4).clamp(6.0, 14.0),
                                ),
                              ),
                            )
                          : null,
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Interactive board for piece placement with drag-and-drop support
class InteractiveBoard extends StatefulWidget {
  const InteractiveBoard({
    required this.board,
    required this.onCellTap,
    required this.onPieceDrop,
    super.key,
    this.cellSize = 45.0,
  });

  final List<List<int>> board;
  final void Function(int row, int col) onCellTap;
  final void Function(int row, int col, int pieceIndex, int variantIndex) onPieceDrop;
  final double cellSize;

  @override
  State<InteractiveBoard> createState() => _InteractiveBoardState();
}

class _InteractiveBoardState extends State<InteractiveBoard> {
  final GlobalKey _boardKey = GlobalKey();
  bool _isDragOver = false;
  int? _hoverRow;
  int? _hoverCol;

  (int, int)? _getCellFromPosition(Offset globalPosition) {
    final renderBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final localPos = renderBox.globalToLocal(globalPosition);
    // Account for border width (2px)
    final adjustedX = localPos.dx - 2;
    final adjustedY = localPos.dy - 2;
    
    final col = (adjustedX / widget.cellSize).floor();
    final row = (adjustedY / widget.cellSize).floor();

    if (row >= 0 && row < 6 && col >= 0 && col < 10) {
      return (row, col);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<DragPieceData>(
      onWillAcceptWithDetails: (details) {
        if (!_isDragOver) setState(() => _isDragOver = true);
        return true;
      },
      onMove: (details) {
        // Use the center of the dragged item for better accuracy
        final cell = _getCellFromPosition(details.offset);
        if (cell != null && (cell.$1 != _hoverRow || cell.$2 != _hoverCol)) {
          setState(() {
            _hoverRow = cell.$1;
            _hoverCol = cell.$2;
          });
        }
      },
      onLeave: (_) => setState(() {
        _isDragOver = false;
        _hoverRow = null;
        _hoverCol = null;
      }),
      onAcceptWithDetails: (details) {
        // Capture hover position before clearing it
        final dropRow = _hoverRow;
        final dropCol = _hoverCol;
        // Get the current variant (may have been updated during drag)
        final currentVariant = details.data.currentVariant;
        
        setState(() {
          _isDragOver = false;
          _hoverRow = null;
          _hoverCol = null;
        });
        
        // Use the hover position (which user saw) instead of recalculating
        if (dropRow != null && dropCol != null) {
          widget.onPieceDrop(dropRow, dropCol, details.data.pieceIndex, currentVariant);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          key: _boardKey,
          decoration: BoxDecoration(
            border: Border.all(
              color: _isDragOver ? AppColors.primary : AppColors.text,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: _isDragOver
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 2)]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                6,
                (r) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(10, (c) {
                    final idx = widget.board[r][c];
                    final isHover = _hoverRow == r && _hoverCol == c;
                    return GestureDetector(
                      onTap: () => widget.onCellTap(r, c),
                      child: Container(
                        width: widget.cellSize,
                        height: widget.cellSize,
                        decoration: BoxDecoration(
                          color: idx >= 0
                              ? pieceColors[idx]
                              : (isHover ? AppColors.primaryLight : Colors.grey.shade100),
                          border: Border.all(
                            color: isHover ? AppColors.primary : AppColors.border,
                            width: isHover ? 1.5 : 0.5,
                          ),
                        ),
                        child: idx >= 0
                            ? Center(
                                child: Text(
                                  pieceNames[idx],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: widget.cellSize * 0.38,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Data passed during drag operation
class DragPieceData {
  DragPieceData({
    required this.pieceIndex,
    required this.variantIndex,
  }) {
    // Register this as the active drag data
    _activeDragData = this;
  }

  final int pieceIndex;
  int variantIndex;
  
  // Static reference to track the currently active drag data
  static DragPieceData? _activeDragData;
  
  /// Get the current variant from the active drag, or from this instance
  int get currentVariant => _activeDragData?.pieceIndex == pieceIndex 
      ? _activeDragData!.variantIndex 
      : variantIndex;
  
  /// Update the variant on the active drag data
  static void updateActiveVariant(int pieceIndex, int variant) {
    if (_activeDragData?.pieceIndex == pieceIndex) {
      _activeDragData!.variantIndex = variant;
    }
  }
  
  /// Clear the active drag data
  static void clearActive() {
    _activeDragData = null;
  }
}
