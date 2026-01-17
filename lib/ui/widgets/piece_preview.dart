/// Piece shape preview widget
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pentomino/core/data/pentomino_data.dart';
import 'package:pentomino/ui/widgets/board_widget.dart';

/// Displays a preview of a pentomino piece shape
class PiecePreview extends StatelessWidget {
  const PiecePreview({
    required this.pieceIndex,
    required this.color,
    super.key,
    this.variantIndex = 0,
    this.showBorder = false,
  });

  final int pieceIndex;
  final int variantIndex;
  final Color color;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final shape = getShapeVariant(pieceIndex, variantIndex);

    var maxR = 0;
    var maxC = 0;
    for (final cell in shape) {
      if (cell[0] > maxR) maxR = cell[0];
      if (cell[1] > maxC) maxC = cell[1];
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / (maxC + 1);
        final cellH = constraints.maxHeight / (maxR + 1);
        final cellSize = cellW < cellH ? cellW : cellH;

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(maxR + 1, (r) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(maxC + 1, (c) {
                  final isFilled = shape.any((cell) => cell[0] == r && cell[1] == c);
                  return Container(
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      color: isFilled ? color : Colors.transparent,
                      border: showBorder && isFilled
                          ? Border.all(color: Colors.black26, width: 0.5)
                          : null,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              );
            }),
          ),
        );
      },
    );
  }
}

/// Draggable piece widget with keyboard rotation support
class DraggablePiece extends StatefulWidget {
  const DraggablePiece({
    required this.pieceIndex,
    required this.variantIndex,
    required this.color,
    required this.isUsed,
    required this.isSelected,
    required this.onTap,
    required this.onVariantChange,
    super.key,
  });

  final int pieceIndex;
  final int variantIndex;
  final Color color;
  final bool isUsed;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(int variant) onVariantChange;

  @override
  State<DraggablePiece> createState() => _DraggablePieceState();
}

class _DraggablePieceState extends State<DraggablePiece> {
  bool _isDragging = false;
  int _currentVariant = 0;
  DragPieceData? _currentDragData;

  @override
  void initState() {
    super.initState();
    _currentVariant = widget.variantIndex;
  }

  @override
  void didUpdateWidget(DraggablePiece oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging) {
      _currentVariant = widget.variantIndex;
    }
  }

  void _rotate() {
    final total = getVariantCount(widget.pieceIndex);
    setState(() {
      _currentVariant = (_currentVariant + 1) % total;
    });
    // Update the drag data if currently dragging
    _currentDragData?.variantIndex = _currentVariant;
    widget.onVariantChange(_currentVariant);
  }

  void _flip() {
    final total = getVariantCount(widget.pieceIndex);
    setState(() {
      _currentVariant = (_currentVariant + total ~/ 2) % total;
    });
    // Update the drag data if currently dragging
    _currentDragData?.variantIndex = _currentVariant;
    widget.onVariantChange(_currentVariant);
  }

  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isUsed) {
      return _buildContent();
    }

    // Create drag data that can be mutated during drag
    _currentDragData = DragPieceData(pieceIndex: widget.pieceIndex, variantIndex: _currentVariant);

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: (event) {
        if (!_isDragging || event is! KeyDownEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.keyR) {
          _rotate();
        } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
          _flip();
        }
      },
      child: Draggable<DragPieceData>(
        data: _currentDragData,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () => setState(() => _isDragging = true),
        onDragEnd: (_) => setState(() {
          _isDragging = false;
          _currentDragData = null;
          DragPieceData.clearActive();
        }),
        onDraggableCanceled: (_, __) => setState(() {
          _isDragging = false;
          _currentDragData = null;
          DragPieceData.clearActive();
        }),
        feedback: _DragFeedback(
          pieceIndex: widget.pieceIndex,
          color: widget.color,
          initialVariant: _currentVariant,
          onVariantChanged: (v) {
            _currentVariant = v;
            _currentDragData?.variantIndex = v;
            widget.onVariantChange(v);
          },
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: _buildContent()),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return GestureDetector(
      onTap: widget.isUsed ? null : widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.isUsed
              ? Colors.grey.shade200
              : (widget.isSelected ? widget.color : widget.color.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: PiecePreview(
                pieceIndex: widget.pieceIndex,
                variantIndex: _currentVariant,
                color: widget.isUsed ? Colors.grey : widget.color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              pieceNames[widget.pieceIndex],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: widget.isUsed ? Colors.grey : (widget.isSelected ? Colors.white : const Color(0xFF18191C)),
                decoration: widget.isUsed ? TextDecoration.lineThrough : null,
              ),
            ),
            const Spacer(),
            if (widget.isSelected) const Icon(Icons.check_circle, color: Colors.white, size: 16),
            if (!widget.isUsed && !widget.isSelected)
              Icon(Icons.drag_indicator, color: Colors.grey.shade400, size: 16),
          ],
        ),
      ),
    );
  }
}

/// Drag feedback that updates when variant changes
class _DragFeedback extends StatefulWidget {
  const _DragFeedback({
    required this.pieceIndex,
    required this.color,
    required this.initialVariant,
    required this.onVariantChanged,
  });

  final int pieceIndex;
  final Color color;
  final int initialVariant;
  final void Function(int) onVariantChanged;

  @override
  State<_DragFeedback> createState() => _DragFeedbackState();
}

class _DragFeedbackState extends State<_DragFeedback> {
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

  void _rotate() {
    final total = getVariantCount(widget.pieceIndex);
    setState(() => _variant = (_variant + 1) % total);
    DragPieceData.updateActiveVariant(widget.pieceIndex, _variant);
    widget.onVariantChanged(_variant);
  }

  void _flip() {
    final total = getVariantCount(widget.pieceIndex);
    setState(() => _variant = (_variant + total ~/ 2) % total);
    DragPieceData.updateActiveVariant(widget.pieceIndex, _variant);
    widget.onVariantChanged(_variant);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.keyR) {
          _rotate();
        } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
          _flip();
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
              child: const Text(
                'R: rotate  F: flip',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 100,
              height: 100,
              child: PiecePreview(
                pieceIndex: widget.pieceIndex,
                variantIndex: _variant,
                color: widget.color.withValues(alpha: 0.85),
                showBorder: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Large piece preview with rotation controls
class PiecePreviewWithControls extends StatelessWidget {
  const PiecePreviewWithControls({
    required this.pieceIndex,
    required this.variantIndex,
    required this.color,
    required this.totalVariants,
    required this.onRotate,
    required this.onFlip,
    super.key,
  });

  final int pieceIndex;
  final int variantIndex;
  final Color color;
  final int totalVariants;
  final VoidCallback onRotate;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Piece ${pieceNames[pieceIndex]}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${variantIndex + 1}/$totalVariants',
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            height: 80,
            child: PiecePreview(
              pieceIndex: pieceIndex,
              variantIndex: variantIndex,
              color: color,
              showBorder: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ControlButton(icon: Icons.rotate_right, tooltip: 'Rotate (R)', onPressed: onRotate),
              const SizedBox(width: 8),
              _ControlButton(icon: Icons.flip, tooltip: 'Flip (F)', onPressed: onFlip),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20),
          ),
        ),
      ),
    );
  }
}
