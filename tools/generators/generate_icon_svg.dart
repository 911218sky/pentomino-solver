// ignore_for_file: avoid_print
// Run: dart tools/generate_icon_svg.dart > assets/icon.svg
// Then convert SVG to PNG using online tools or Inkscape

void main() {
  const size = 512;
  const cellSize = 64;
  const radius = 80;

  // T-pentomino shape (iconic and recognizable)
  const cells = [
    [0, 0], [1, 0], [2, 0], // top row
    [1, 1], // middle
    [1, 2], // bottom
  ];

  const offsetX = (size - 3 * cellSize) / 2;
  const offsetY = (size - 3 * cellSize) / 2;

  print('''
<svg xmlns="http://www.w3.org/2000/svg" width="$size" height="$size" viewBox="0 0 $size $size">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#FF6B8A"/>
      <stop offset="100%" style="stop-color:#FF8FA3"/>
    </linearGradient>
    <linearGradient id="cell" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#FFFFFF"/>
      <stop offset="100%" style="stop-color:#F0F0F0"/>
    </linearGradient>
  </defs>
  
  <!-- Background -->
  <rect width="$size" height="$size" rx="$radius" fill="url(#bg)"/>
  
  <!-- Pentomino cells -->''');

  for (final cell in cells) {
    final x = offsetX + cell[0] * cellSize + 4;
    final y = offsetY + cell[1] * cellSize + 4;
    const w = cellSize - 8;
    print(
      '  <rect x="$x" y="$y" width="$w" height="$w" rx="8" '
      'fill="url(#cell)" opacity="0.95"/>',
    );
  }

  print('</svg>');
}
