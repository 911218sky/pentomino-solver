/// Dancing Links (DLX) algorithm implementation for exact cover problems
library;

/// Node in the Dancing Links data structure
class DLXNode {
  DLXNode() {
    left = this;
    right = this;
    up = this;
    down = this;
    column = this;
  }

  late DLXNode left, right, up, down;
  late DLXNode column;
  int row = -1;
  int size = 0;
  int colIndex = -1;
}

/// Dancing Links solver for exact cover problems
class DLXSolver {
  DLXSolver({required int numPieces, required int numCells})
      : _totalColumns = numPieces + numCells {
    _buildMatrix();
  }

  late DLXNode header;
  final List<DLXNode> columns = [];
  final List<List<int>> solutions = [];
  final List<int> _currentSolution = [];
  final int _totalColumns;
  void Function(List<int>)? onSolutionFound;
  int _operationCount = 0;

  void _buildMatrix() {
    header = DLXNode();

    for (var i = 0; i < _totalColumns; i++) {
      final col = DLXNode();
      col.colIndex = i;
      col.left = header.left;
      col.right = header;
      header.left.right = col;
      header.left = col;
      columns.add(col);
    }
  }

  /// Add a row representing a piece placement
  void addRow(int pieceIndex, List<List<int>> cells, int rowId, int boardCols) {
    DLXNode? first;

    // Piece constraint
    final pieceNode = DLXNode();
    pieceNode.row = rowId;
    pieceNode.column = columns[pieceIndex];
    _insertInColumn(pieceNode, columns[pieceIndex]);
    first = pieceNode;

    // Cell constraints
    for (final cell in cells) {
      final colIdx = columns.length - (6 * boardCols) + cell[0] * boardCols + cell[1];
      final node = DLXNode();
      node.row = rowId;
      node.column = columns[colIdx];
      _insertInColumn(node, columns[colIdx]);

      node.left = first.left;
      node.right = first;
      first.left.right = node;
      first.left = node;
    }
  }

  void _insertInColumn(DLXNode node, DLXNode col) {
    node.up = col.up;
    node.down = col;
    col.up.down = node;
    col.up = node;
    col.size++;
  }

  void _cover(DLXNode col) {
    col.right.left = col.left;
    col.left.right = col.right;

    for (var row = col.down; row != col; row = row.down) {
      for (var node = row.right; node != row; node = node.right) {
        node.down.up = node.up;
        node.up.down = node.down;
        node.column.size--;
      }
    }
  }

  void _uncover(DLXNode col) {
    for (var row = col.up; row != col; row = row.up) {
      for (var node = row.left; node != row; node = node.left) {
        node.column.size++;
        node.down.up = node;
        node.up.down = node;
      }
    }
    col.right.left = col;
    col.left.right = col;
  }

  /// Solve the exact cover problem
  void solve({int maxSolutions = -1}) {
    _search(maxSolutions);
  }

  /// Async solve that yields control periodically for UI updates
  Future<void> solveAsync({
    int maxSolutions = -1,
    int yieldEvery = 5000,
  }) async {
    _operationCount = 0;
    await _searchAsync(maxSolutions, yieldEvery);
  }

  Future<void> _searchAsync(int maxSolutions, int yieldEvery) async {
    _operationCount++;
    if (_operationCount % yieldEvery == 0) {
      await Future<void>.delayed(Duration.zero);
    }

    if (header.right == header) {
      final solution = List<int>.from(_currentSolution);
      solutions.add(solution);
      onSolutionFound?.call(solution);
      return;
    }

    if (maxSolutions > 0 && solutions.length >= maxSolutions) return;

    // Choose column with minimum size (MRV heuristic)
    DLXNode? minCol;
    var minSize = 999999;
    for (var col = header.right; col != header; col = col.right) {
      if (col.size < minSize) {
        minSize = col.size;
        minCol = col;
      }
    }

    if (minCol == null || minSize == 0) return;

    _cover(minCol);

    for (var row = minCol.down; row != minCol; row = row.down) {
      _currentSolution.add(row.row);

      for (var node = row.right; node != row; node = node.right) {
        _cover(node.column);
      }

      await _searchAsync(maxSolutions, yieldEvery);

      for (var node = row.left; node != row; node = node.left) {
        _uncover(node.column);
      }

      _currentSolution.removeLast();

      if (maxSolutions > 0 && solutions.length >= maxSolutions) break;
    }

    _uncover(minCol);
  }

  void _search(int maxSolutions) {
    if (header.right == header) {
      final solution = List<int>.from(_currentSolution);
      solutions.add(solution);
      onSolutionFound?.call(solution);
      return;
    }

    if (maxSolutions > 0 && solutions.length >= maxSolutions) return;

    // Choose column with minimum size (MRV heuristic)
    DLXNode? minCol;
    var minSize = 999999;
    for (var col = header.right; col != header; col = col.right) {
      if (col.size < minSize) {
        minSize = col.size;
        minCol = col;
      }
    }

    if (minCol == null || minSize == 0) return;

    _cover(minCol);

    for (var row = minCol.down; row != minCol; row = row.down) {
      _currentSolution.add(row.row);

      for (var node = row.right; node != row; node = node.right) {
        _cover(node.column);
      }

      _search(maxSolutions);

      for (var node = row.left; node != row; node = node.left) {
        _uncover(node.column);
      }

      _currentSolution.removeLast();

      if (maxSolutions > 0 && solutions.length >= maxSolutions) break;
    }

    _uncover(minCol);
  }
}
