import 'dart:math';
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import 'skins.dart';

class GeneratedLevel {
  final int rows;
  final int cols;
  final List<Vehicle> vehicles;
  final int timeLimitSeconds;
  final bool isHardLevel;

  GeneratedLevel({
    required this.rows,
    required this.cols,
    required this.vehicles,
    required this.timeLimitSeconds,
    required this.isHardLevel,
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
  /// Every 5th level is a deliberate difficulty spike: more vehicles and a
  /// tighter clock than the smooth curve would normally give you.
  static bool isHardLevel(int levelNumber) => levelNumber % 5 == 0;

  static GeneratedLevel generate(int levelNumber, {int? seed, List<Color>? palette}) {
    final rng = Random(seed);
    final hard = isHardLevel(levelNumber);

    final gridSize = (5 + (levelNumber / 3).floor()).clamp(5, 8);
    final rows = gridSize;
    final cols = gridSize;
    final maxCars = (rows * cols) ~/ 3;
    var targetCars = (5 + (levelNumber * 0.7).floor()).clamp(4, maxCars);
    if (hard) targetCars = (targetCars + 3).clamp(4, maxCars);

    var timeLimit = (28 + gridSize * 3 + targetCars * 2).clamp(25, 90);
    if (hard) timeLimit = (timeLimit * 0.7).round().clamp(18, 90);

    final vehicles = _generateVehicles(
      rows,
      cols,
      targetCars,
      rng,
      palette ?? skinById("classic").palette,
    );

    return GeneratedLevel(
      rows: rows,
      cols: cols,
      vehicles: vehicles,
      timeLimitSeconds: timeLimit,
      isHardLevel: hard,
    );
  }

  /// Generates a fresh, guaranteed-solvable set of vehicles for an existing
  /// board size, independent of level progression. Used by the "Shuffle
  /// Traffic" power-up to re-lay-out whatever vehicles are still on the
  /// board mid-level.
  static List<Vehicle> generateVehiclesOnly(
    int rows,
    int cols,
    int count, {
    int? seed,
    List<Color>? palette,
  }) {
    final rng = Random(seed);
    return _generateVehicles(rows, cols, count, rng, palette ?? skinById("classic").palette);
  }

  static List<Vehicle> _generateVehicles(
    int rows,
    int cols,
    int targetCars,
    Random rng,
    List<Color> palette,
  ) {
    for (var attempt = 0; attempt < 400; attempt++) {
      final vehicles = _tryPlaceVehicles(rows, cols, targetCars, rng, palette);
      if (vehicles == null) continue;
      if (_isSolvable(vehicles)) return vehicles;
    }

    // Extremely unlikely fallback: fewer cars is always easier to place and
    // to prove solvable, so this loop is guaranteed to terminate quickly.
    for (var cars = targetCars - 1; cars >= 3; cars--) {
      for (var attempt = 0; attempt < 400; attempt++) {
        final vehicles = _tryPlaceVehicles(rows, cols, cars, rng, palette);
        if (vehicles == null) continue;
        if (_isSolvable(vehicles)) return vehicles;
      }
    }

    // Should never happen, but never crash the game over it.
    return const [];
  }

  static List<Vehicle>? _tryPlaceVehicles(
    int rows,
    int cols,
    int count,
    Random rng,
    List<Color> palette,
  ) {
    final occupied = <Cell, int>{};
    final vehicles = <Vehicle>[];
    var placementTries = 0;

    while (vehicles.length < count && placementTries < 600) {
      placementTries++;
      final horizontal = rng.nextBool();
      final length = [1, 2, 2, 2, 3][rng.nextInt(5)];
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
        color: palette[id % palette.length],
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

