import 'dart:math';
import 'package:flutter/material.dart';
import '../models/vehicle.dart';

class GeneratedLevel {
  final int rows;
  final int cols;
  final List<Vehicle> vehicles;
  final int timeLimitSeconds;

  GeneratedLevel({
    required this.rows,
    required this.cols,
    required this.vehicles,
    required this.timeLimitSeconds,
  });
}

/// Generates procedural "traffic untangle" levels and *guarantees* every
/// level is solvable.
///
/// The trick: a vehicle can only be driven off once its straight-line path
/// to the board edge is completely empty (see [Vehicle.exitPath]). That
/// means vehicle A can only be "in the way" of vehicle B if A's cells
/// overlap B's exit path - a directed relationship (A must leave before B
/// can). Building that as a directed graph and checking it has no cycles
/// (Kahn's algorithm) tells us, with total certainty, whether *some* tap
/// order clears the whole board - without ever simulating the game itself.
class LevelGenerator {
  static const List<Color> _palette = [
    Color(0xFFE63946),
    Color(0xFFF4A261),
    Color(0xFF2A9D8F),
    Color(0xFF457B9D),
    Color(0xFF8338EC),
    Color(0xFFFFB703),
    Color(0xFF06D6A0),
    Color(0xFFEF476F),
    Color(0xFF3A86FF),
    Color(0xFFFB5607),
    Color(0xFF9B5DE5),
    Color(0xFF00BBF9),
    ];

  static GeneratedLevel generate(int levelNumber, {int? seed}) {
    final rng = Random(seed);

    final gridSize = (5 + (levelNumber / 3).floor()).clamp(5, 8);
    final rows = gridSize;
    final cols = gridSize;
    final maxCars = (rows * cols) ~/ 3;
    final targetCars = (5 + (levelNumber * 0.7).floor()).clamp(4, maxCars);
    final timeLimit = (28 + gridSize * 3 + targetCars * 2).clamp(25, 90);

    for (var attempt = 0; attempt < 400; attempt++) {
      final vehicles = _tryPlaceVehicles(rows, cols, targetCars, rng);
      if (vehicles == null) continue;
      if (_isSolvable(vehicles)) {
        return GeneratedLevel(
          rows: rows,
          cols: cols,
          vehicles: vehicles,
          timeLimitSeconds: timeLimit,
          );
      }
    }

    // Extremely unlikely fallback: fewer cars is always easier to place and
    // to prove solvable, so this loop is guaranteed to terminate quickly.
    for (var cars = targetCars - 1; cars >= 3; cars--) {
      for (var attempt = 0; attempt < 400; attempt++) {
        final vehicles = _tryPlaceVehicles(rows, cols, cars, rng);
        if (vehicles == null) continue;
        if (_isSolvable(vehicles)) {
          return GeneratedLevel(
            rows: rows,
            cols: cols,
            vehicles: vehicles,
            timeLimitSeconds: timeLimit,
            );
        }
      }
    }

    // Should never happen, but never crash the game over it.
    return GeneratedLevel(
      rows: rows,
      cols: cols,
      vehicles: const [],
      timeLimitSeconds: timeLimit,
      );
  }

  static List<Vehicle>? _tryPlaceVehicles(
    int rows,
    int cols,
    int count,
    Random rng,
    ) {
    final occupied = <Cell, int>{};
    final vehicles = <Vehicle>[];
    var placementTries = 0;

    while (vehicles.length < count && placementTries < 600) {
      placementTries++;
      final horizontal = rng.nextBool();
      final length = [2, 2, 3][rng.nextInt(3)];
      final direction = rng.nextBool() ? 1 : -1;

      List<Cell>? cells;
      if (horizontal) {
        if (cols < length) continue;
        final r = rng.nextInt(rows);
        final c0 = rng.nextInt(cols - length + 1);
        cells = List.generate(length, (i) => Cell(r, c0 + i));
      } else {
        if (rows < length) continue;
        final c = rng.nextInt(cols);
        final r0 = rng.nextInt(rows - length + 1);
        cells = List.generate(length, (i) => Cell(r0 + i, c));
      }

      if (cells.any((cell) => occupied.containsKey(cell))) continue;

      final exitPath = _computeExitPath(
        cells,
        horizontal ? VehicleOrientation.horizontal : VehicleOrientation.vertical,
        direction,
        rows,
        cols,
        );

      final id = vehicles.length;
      for (final cell in cells) {
        occupied[cell] = id;
      }
      vehicles.add(Vehicle(
        id: id,
        orientation:
        horizontal ? VehicleOrientation.horizontal : VehicleOrientation.vertical,
        direction: direction,
        length: length,
        color: _palette[id % _palette.length],
        cells: cells,
        exitPath: exitPath,
        ));
    }

    return vehicles.length == count ? vehicles : null;
  }

  static List<Cell> _computeExitPath(
    List<Cell> cells,
    VehicleOrientation orientation,
    int direction,
    int rows,
    int cols,
    ) {
    if (orientation == VehicleOrientation.horizontal) {
      final r = cells.first.row;
      if (direction == 1) {
        final lastCol = cells.last.col;
        return [for (var c = lastCol + 1; c < cols; c++) Cell(r, c)];
      } else {
        final firstCol = cells.first.col;
        return [for (var c = 0; c < firstCol; c++) Cell(r, c)];
      }
    } else {
      final c = cells.first.col;
      if (direction == 1) {
        final lastRow = cells.last.row;
        return [for (var r = lastRow + 1; r < rows; r++) Cell(r, c)];
      } else {
        final firstRow = cells.first.row;
        return [for (var r = 0; r < firstRow; r++) Cell(r, c)];
      }
    }
  }

  /// Kahn's algorithm over the "must leave before" graph.
  static bool _isSolvable(List<Vehicle> vehicles) {
    final cellOwner = <Cell, int>{};
    for (final v in vehicles) {
      for (final cell in v.cells) {
        cellOwner[cell] = v.id;
      }
    }

    final blockers = <int, Set<int>>{
      for (final v in vehicles) v.id: <int>{},
    };
    for (final v in vehicles) {
      for (final cell in v.exitPath) {
        final owner = cellOwner[cell];
        if (owner != null) blockers[v.id]!.add(owner);
      }
    }

    final remaining = vehicles.map((v) => v.id).toSet();
    var progress = true;
    while (remaining.isNotEmpty && progress) {
      progress = false;
      for (final id in remaining.toList()) {
        if (blockers[id]!.intersection(remaining).isEmpty) {
          remaining.remove(id);
          progress = true;
        }
      }
    }
    return remaining.isEmpty;
  }
}
