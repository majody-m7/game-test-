import 'package:flutter/material.dart';
import '../logic/game_state.dart';
import '../models/vehicle.dart';
import 'vehicle_tile.dart';

/// The square puzzle board: a light grid background plus every vehicle,
/// each positioned absolutely so it can smoothly animate off-screen once
/// it exits.
class GridBoard extends StatelessWidget {
  final GameState gameState;
  final void Function(int vehicleId) onTapVehicle;

  const GridBoard({super.key, required this.gameState, required this.onTapVehicle});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.biggest.shortestSide;
        final cellSize = boardSize / gameState.cols;

        return Center(
          child: ClipRect(
            child: SizedBox(
              width: boardSize,
              height: boardSize,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(boardSize, boardSize),
                    painter: _GridPainter(rows: gameState.rows, cols: gameState.cols),
                    ),
                  for (final v in gameState.vehicles)
                  _buildVehiclePositioned(v, cellSize),
                  ],
                ),
              ),
            ),
          );
      },
      );
  }

  Widget _buildVehiclePositioned(Vehicle v, double cellSize) {
    final horizontal = v.orientation == VehicleOrientation.horizontal;
    double left;
    double top;

    if (!v.exited) {
      // cells are ordered top-left-first by construction, for both
      // orientations, so this is always the vehicle's resting position.
      left = v.cells.first.col * cellSize;
      top = v.cells.first.row * cellSize;
    } else {
      // Slide fully clear of the board in the direction it was heading.
      final travel = (horizontal ? gameState.cols : gameState.rows) * cellSize;
      if (horizontal) {
        top = v.cells.first.row * cellSize;
        left = v.direction == 1
          ? v.cells.first.col * cellSize + travel
          : v.cells.first.col * cellSize - travel;
      } else {
        left = v.cells.first.col * cellSize;
        top = v.direction == 1
          ? v.cells.first.row * cellSize + travel
          : v.cells.first.row * cellSize - travel;
      }
    }

    return AnimatedPositioned(
      key: ValueKey(v.id),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInCubic,
      left: left,
      top: top,
      width: horizontal ? cellSize * v.length : cellSize,
      height: horizontal ? cellSize : cellSize * v.length,
      child: VehicleTile(
        vehicle: v,
        cellSize: cellSize,
        shakeSignal: gameState.shakeCountFor(v.id),
        onTap: () => onTapVehicle(v.id),
        ),
      );
  }
}

class _GridPainter extends CustomPainter {
  final int rows;
  final int cols;
  _GridPainter({required this.rows, required this.cols});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFEFE7DA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final line = Paint()
      ..color = const Color(0xFFD9CDB8)
      ..strokeWidth = 1.5;

    final cellW = size.width / cols;
    final cellH = size.height / rows;
    for (var c = 0; c <= cols; c++) {
      final x = c * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var r = 0; r <= rows; r++) {
      final y = r * cellH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
    oldDelegate.rows != rows || oldDelegate.cols != cols;
}
