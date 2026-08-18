import 'package:flutter/material.dart';

/// A single grid cell coordinate (row, col).
class Cell {
  final int row;
  final int col;
  const Cell(this.row, this.col);

  @override
  bool operator ==(Object other) =>
    other is Cell && other.row == row && other.col == col;

  @override
  int get hashCode => row * 1000003 + col;

  @override
  String toString() => '($row,$col)';
}

enum VehicleOrientation { horizontal, vertical }

/// A vehicle occupies [length] contiguous cells in a straight line and can
/// only ever move in one fixed direction: toward the edge of the board that
/// [direction] points to. There is no "reverse" - just like the real
/// traffic-jam games this is modeled after, once you commit to clearing a
/// lane you drive straight through.
///
/// direction == -1 means "toward row/col 0" (up for vertical, left for
/// horizontal). direction == 1 means "toward the last row/col" (down /
/// right).
class Vehicle {
  final int id;
  final VehicleOrientation orientation;
  final int direction;
  final int length;
  final Color color;

  /// Cells occupied while the vehicle is still on the board. These never
  /// change - a vehicle either sits still or fully exits, there is no
  /// partial slide, which keeps the puzzle logic (and the generator's
  /// solvability guarantee) simple and airtight.
  final List<Cell> cells;

  /// The empty lane of cells between this vehicle and the edge it exits
  /// through, computed once at generation time.
  final List<Cell> exitPath;

  bool exited = false;

  Vehicle({
    required this.id,
    required this.orientation,
    required this.direction,
    required this.length,
    required this.color,
    required this.cells,
    required this.exitPath,
  });
}
