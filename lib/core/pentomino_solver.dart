/// Pentomino puzzle solver using Dancing Links algorithm
library;

import 'package:pentomino/core/dlx_solver.dart';
import 'package:pentomino/core/pentomino_data.dart';

/// Solver for pentomino puzzles
class PentominoSolver {
  PentominoSolver({this.boardRows = 6, this.boardCols = 10});

  final int boardRows;
  final int boardCols;
  List<List<List<List<int>>>>? _allPlacements;

  /// Generate all possible placements for each piece
  void _generatePlacements() {
    if (_allPlacements != null) return;
    
    _allPlacements = [];

    for (var p = 0; p < pieceNames.length; p++) {
      final variants = getAllVariants(pentominoes[pieceNames[p]]!);
      final placements = <List<List<int>>>[];

      for (final variant in variants) {
        final maxR = variant.map((c) => c[0]).reduce((a, b) => a > b ? a : b);
        final maxC = variant.map((c) => c[1]).reduce((a, b) => a > b ? a : b);

        for (var r = 0; r <= boardRows - 1 - maxR; r++) {
          for (var c = 0; c <= boardCols - 1 - maxC; c++) {
            final cells = variant.map((cell) => [cell[0] + r, cell[1] + c]).toList();
            placements.add(cells);
          }
        }
      }
      _allPlacements!.add(placements);
    }
  }

  /// Check if a solution is the "canonical" one (not a mirror/rotation duplicate)
  /// 6x10 board has D2 symmetry: H-mirror, V-mirror, 180° rotation
  /// We pick canonical by requiring F piece to be in top-left quadrant
  bool _isCanonicalSolution(List<List<int>> board) {
    // Find F piece (index 0) bounding box
    var fMinRow = boardRows;
    var fMaxRow = 0;
    var fMinCol = boardCols;
    var fMaxCol = 0;
    
    for (var r = 0; r < boardRows; r++) {
      for (var c = 0; c < boardCols; c++) {
        if (board[r][c] == 0) { // F is piece index 0
          if (r < fMinRow) fMinRow = r;
          if (r > fMaxRow) fMaxRow = r;
          if (c < fMinCol) fMinCol = c;
          if (c > fMaxCol) fMaxCol = c;
        }
      }
    }
    
    // F piece center must be in top-left quadrant
    final fCenterRow = (fMinRow + fMaxRow) / 2;
    final fCenterCol = (fMinCol + fMaxCol) / 2;
    
    // Strict: top-left quadrant (row < 3, col < 5)
    return fCenterRow < boardRows / 2 && fCenterCol < boardCols / 2;
  }

  /// Solve and return all solutions
  List<List<List<int>>> solve({int maxSolutions = -1, bool eliminateSymmetry = true}) {
    _generatePlacements();

    final dlx = DLXSolver(numPieces: pieceNames.length, numCells: boardRows * boardCols);
    final rowInfo = <(int, List<List<int>>)>[];

    var rowId = 0;
    for (var p = 0; p < pieceNames.length; p++) {
      for (final cells in _allPlacements![p]) {
        dlx.addRow(p, cells, rowId, boardCols);
        rowInfo.add((p, cells));
        rowId++;
      }
    }

    dlx.solve(maxSolutions: maxSolutions < 0 ? -1 : maxSolutions * 2);

    var solutions = _convertSolutions(dlx.solutions, rowInfo);
    
    // Filter out mirror duplicates
    if (eliminateSymmetry) {
      solutions = solutions.where(_isCanonicalSolution).toList();
      if (maxSolutions > 0 && solutions.length > maxSolutions) {
        solutions = solutions.sublist(0, maxSolutions);
      }
    }
    
    return solutions;
  }

  /// Solve with streaming results (for progressive UI updates)
  Stream<List<List<int>>> solveStream({bool eliminateSymmetry = true}) async* {
    _generatePlacements();

    final dlx = DLXSolver(numPieces: pieceNames.length, numCells: boardRows * boardCols);
    final rowInfo = <(int, List<List<int>>)>[];

    var rowId = 0;
    for (var p = 0; p < pieceNames.length; p++) {
      for (final cells in _allPlacements![p]) {
        dlx.addRow(p, cells, rowId, boardCols);
        rowInfo.add((p, cells));
        rowId++;
      }
    }

    // Use callback to yield solutions as they're found
    final pendingSolutions = <List<List<int>>>[];
    
    dlx.onSolutionFound = (solution) {
      final board = _convertSolution(solution, rowInfo);
      if (!eliminateSymmetry || _isCanonicalSolution(board)) {
        pendingSolutions.add(board);
      }
    };

    // Run solver in chunks to allow UI updates
    dlx.solve();
    
    // Yield all solutions
    for (final solution in pendingSolutions) {
      yield solution;
    }
  }

  /// Convert a single solution
  List<List<int>> _convertSolution(List<int> solution, List<(int, List<List<int>>)> rowInfo) {
    final board = List.generate(boardRows, (_) => List.filled(boardCols, -1));
    for (final rowIdx in solution) {
      final (pieceIdx, cells) = rowInfo[rowIdx];
      for (final cell in cells) {
        board[cell[0]][cell[1]] = pieceIdx;
      }
    }
    return board;
  }

  /// Solve with pre-placed pieces on the board
  List<List<List<int>>> solveWithBoard(List<List<int>> initialBoard, Set<int> usedPieces) {
    _generatePlacements();

    // Find occupied cells
    final occupiedCells = <int>{};
    for (var r = 0; r < boardRows; r++) {
      for (var c = 0; c < boardCols; c++) {
        if (initialBoard[r][c] >= 0) {
          occupiedCells.add(r * boardCols + c);
        }
      }
    }

    // Check if remaining cells match remaining pieces
    final remainingCells = boardRows * boardCols - occupiedCells.length;
    final remainingPieces = pieceNames.length - usedPieces.length;
    if (remainingCells != remainingPieces * 5) return [];

    final dlx = DLXSolver(numPieces: pieceNames.length, numCells: boardRows * boardCols);
    final rowInfo = <(int, List<List<int>>)>[];

    var rowId = 0;
    for (var p = 0; p < pieceNames.length; p++) {
      if (usedPieces.contains(p)) continue;

      for (final cells in _allPlacements![p]) {
        final conflict = cells.any((cell) => occupiedCells.contains(cell[0] * boardCols + cell[1]));
        if (conflict) continue;

        dlx.addRow(p, cells, rowId, boardCols);
        rowInfo.add((p, cells));
        rowId++;
      }
    }

    // Add dummy rows for used pieces
    for (final p in usedPieces) {
      final dummyNode = DLXNode();
      dummyNode.row = rowId;
      dummyNode.column = dlx.columns[p];
      dummyNode.up = dlx.columns[p].up;
      dummyNode.down = dlx.columns[p];
      dlx.columns[p].up.down = dummyNode;
      dlx.columns[p].up = dummyNode;
      dlx.columns[p].size++;
      rowInfo.add((p, []));
      rowId++;
    }

    // Add dummy rows for occupied cells
    for (final cellIdx in occupiedCells) {
      final colIdx = pieceNames.length + cellIdx;
      final dummyNode = DLXNode();
      dummyNode.row = rowId;
      dummyNode.column = dlx.columns[colIdx];
      dummyNode.up = dlx.columns[colIdx].up;
      dummyNode.down = dlx.columns[colIdx];
      dlx.columns[colIdx].up.down = dummyNode;
      dlx.columns[colIdx].up = dummyNode;
      dlx.columns[colIdx].size++;
      rowId++;
    }

    dlx.solve();

    return _convertSolutionsWithInitial(dlx.solutions, rowInfo, initialBoard);
  }

  List<List<List<int>>> _convertSolutions(
    List<List<int>> solutions,
    List<(int, List<List<int>>)> rowInfo,
  ) {
    return solutions.map((solution) {
      final board = List.generate(boardRows, (_) => List.filled(boardCols, -1));
      for (final rowIdx in solution) {
        final (pieceIdx, cells) = rowInfo[rowIdx];
        for (final cell in cells) {
          board[cell[0]][cell[1]] = pieceIdx;
        }
      }
      return board;
    }).toList();
  }

  List<List<List<int>>> _convertSolutionsWithInitial(
    List<List<int>> solutions,
    List<(int, List<List<int>>)> rowInfo,
    List<List<int>> initialBoard,
  ) {
    return solutions.map((solution) {
      final board = List.generate(boardRows, (r) => List<int>.from(initialBoard[r]));
      for (final rowIdx in solution) {
        if (rowIdx < rowInfo.length) {
          final (pieceIdx, cells) = rowInfo[rowIdx];
          for (final cell in cells) {
            board[cell[0]][cell[1]] = pieceIdx;
          }
        }
      }
      return board;
    }).toList();
  }
}
