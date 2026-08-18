import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import 'level_generator.dart';

enum RoundStatus { playing, won, lost }

class GameState extends ChangeNotifier {
  int level;
  late GeneratedLevel _generated;
  Timer? _ticker;
  int remainingSeconds = 0;
  RoundStatus status = RoundStatus.playing;
  int movesUsed = 0;

  /// Per-vehicle counter, bumped every time a tap on that specific vehicle
  /// fails (car still blocked), so the UI can play a one-shot "shake"
  /// animation for exactly that vehicle without disturbing the others.
  final Map<int, int> _shakeCounts = {};
  int shakeCountFor(int id) => _shakeCounts[id] ?? 0;

  GameState({required this.level}) {
    _startLevel();
  }

  int get rows => _generated.rows;
  int get cols => _generated.cols;
  List<Vehicle> get vehicles => _generated.vehicles;
  int get timeLimitSeconds => _generated.timeLimitSeconds;

  int get totalCount => vehicles.length;
  int get clearedCount => vehicles.where((v) => v.exited).length;

  void _startLevel() {
    _generated = LevelGenerator.generate(level);
    remainingSeconds = _generated.timeLimitSeconds;
    status = RoundStatus.playing;
    movesUsed = 0;
    _shakeCounts.clear();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (status != RoundStatus.playing) return;
    remainingSeconds -= 1;
    if (remainingSeconds <= 0) {
      remainingSeconds = 0;
      status = RoundStatus.lost;
      _ticker?.cancel();
    }
    notifyListeners();
  }

  Set<Cell> get _occupiedCells {
    final set = <Cell>{};
    for (final v in vehicles) {
      if (!v.exited) set.addAll(v.cells);
    }
    return set;
  }

  bool _canExit(Vehicle v) {
    final occupied = _occupiedCells;
    return v.exitPath.every((cell) => !occupied.contains(cell));
  }

  /// Returns true if the tap actually drove the car off the board.
  bool tapVehicle(int id) {
    if (status != RoundStatus.playing) return false;
    final vehicle = vehicles.firstWhere((v) => v.id == id, orElse: () => vehicles.first);
    if (vehicle.exited) return false;

    if (_canExit(vehicle)) {
      vehicle.exited = true;
      movesUsed += 1;
      if (clearedCount == totalCount) {
        status = RoundStatus.won;
        _ticker?.cancel();
      }
      notifyListeners();
      return true;
    } else {
      _shakeCounts[id] = (_shakeCounts[id] ?? 0) + 1;
      notifyListeners();
      return false;
    }
  }

  /// Finds a currently-movable vehicle to nudge a stuck player, or null if
  /// (in the extremely rare case) none is immediately obvious.
  int? get hintVehicleId {
    for (final v in vehicles) {
      if (!v.exited && _canExit(v)) return v.id;
    }
    return null;
  }

  int get starsEarned {
    if (status != RoundStatus.won) return 0;
    final fractionLeft = remainingSeconds / timeLimitSeconds;
    if (fractionLeft > 0.5) return 3;
    if (fractionLeft > 0.2) return 2;
    return 1;
  }

  void restart() {
    _startLevel();
    notifyListeners();
  }

  void nextLevel() {
    level += 1;
    _startLevel();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
