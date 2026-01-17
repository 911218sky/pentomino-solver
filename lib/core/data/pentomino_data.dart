/// Pentomino piece definitions and transformation utilities
library;

/// 12 Pentomino shapes defined as relative coordinates
const Map<String, List<List<int>>> pentominoes = {
  'F': [[0, 1], [1, 0], [1, 1], [1, 2], [2, 2]],
  'I': [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]],
  'L': [[0, 0], [1, 0], [2, 0], [3, 0], [3, 1]],
  'N': [[0, 0], [0, 1], [1, 1], [1, 2], [1, 3]],
  'P': [[0, 0], [0, 1], [1, 0], [1, 1], [2, 0]],
  'T': [[0, 0], [0, 1], [0, 2], [1, 1], [2, 1]],
  'U': [[0, 0], [0, 2], [1, 0], [1, 1], [1, 2]],
  'V': [[0, 0], [1, 0], [2, 0], [2, 1], [2, 2]],
  'W': [[0, 0], [1, 0], [1, 1], [2, 1], [2, 2]],
  'X': [[0, 1], [1, 0], [1, 1], [1, 2], [2, 1]],
  'Y': [[0, 1], [1, 0], [1, 1], [2, 1], [3, 1]],
  'Z': [[0, 0], [0, 1], [1, 1], [2, 1], [2, 2]],
};

const List<String> pieceNames = ['F', 'I', 'L', 'N', 'P', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];

/// Rotate shape 90 degrees clockwise
List<List<int>> rotateShape(List<List<int>> shape) {
  return shape.map((p) => [-p[1], p[0]]).toList();
}

/// Flip shape horizontally
List<List<int>> flipShape(List<List<int>> shape) {
  return shape.map((p) => [p[0], -p[1]]).toList();
}

/// Normalize shape to origin (top-left corner)
List<List<int>> normalizeShape(List<List<int>> shape) {
  final minR = shape.map((p) => p[0]).reduce((a, b) => a < b ? a : b);
  final minC = shape.map((p) => p[1]).reduce((a, b) => a < b ? a : b);
  final result = shape.map((p) => [p[0] - minR, p[1] - minC]).toList();
  result.sort((a, b) => a[0] != b[0] ? a[0].compareTo(b[0]) : a[1].compareTo(b[1]));
  return result;
}

/// Get all unique variants of a shape (rotations + flips)
List<List<List<int>>> getAllVariants(List<List<int>> shape) {
  final seen = <String>{};
  final variants = <List<List<int>>>[];

  var current = shape;
  for (var f = 0; f < 2; f++) {
    for (var r = 0; r < 4; r++) {
      final norm = normalizeShape(current);
      final key = norm.map((p) => '${p[0]},${p[1]}').join('|');
      if (!seen.contains(key)) {
        seen.add(key);
        variants.add(norm);
      }
      current = rotateShape(current);
    }
    current = flipShape(shape);
  }
  return variants;
}

/// Cached variants for all pieces (computed once)
final List<List<List<List<int>>>> _cachedVariants = List.generate(
  12,
  (i) => getAllVariants(pentominoes[pieceNames[i]]!),
);

/// Get shape at specific variant index (uses cache)
List<List<int>> getShapeVariant(int pieceIndex, int variantIndex) {
  final variants = _cachedVariants[pieceIndex];
  return variants[variantIndex % variants.length];
}

/// Get total number of variants for a piece (uses cache)
int getVariantCount(int pieceIndex) {
  return _cachedVariants[pieceIndex].length;
}
