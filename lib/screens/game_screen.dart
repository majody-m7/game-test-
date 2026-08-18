import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../logic/game_state.dart';
import '../logic/progress_storage.dart';
import '../widgets/grid_board.dart';

class GameScreen extends StatefulWidget {
  final int startLevel;
  const GameScreen({super.key, required this.startLevel});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _gameState = GameState(level: widget.startLevel);
    _gameState.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (_gameState.status == RoundStatus.won && !_dialogShown) {
      _dialogShown = true;
      ProgressStorage.saveBestLevel(_gameState.level + 1);
      HapticFeedback.mediumImpact();
      Future.microtask(() => _showResultDialog(won: true));
    } else if (_gameState.status == RoundStatus.lost && !_dialogShown) {
      _dialogShown = true;
      HapticFeedback.heavyImpact();
      Future.microtask(() => _showResultDialog(won: false));
    }
    setState(() {});
  }

  void _restart() {
    setState(() {
      _dialogShown = false;
      _gameState.restart();
    });
  }

  void _nextLevel() {
    setState(() {
      _dialogShown = false;
      _gameState.nextLevel();
    });
  }

  void _showResultDialog({required bool won}) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(won ? 'Traffic Cleared!' : "Time's Up!",
                      textAlign: TextAlign.center),
          content: won
          ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final filled = i < _gameState.starsEarned;
              return Icon(
                filled ? Icons.star_rounded : Icons.star_border_rounded,
                color: Colors.amber,
                size: 40,
                );
            }),
            )
          : const Text('The jam beat the clock. Give it another go?',
                       textAlign: TextAlign.center),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Home'),
              ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (won) {
                  _nextLevel();
                } else {
                  _restart();
                }
              },
              child: Text(won ? 'Next Level' : 'Retry'),
              ),
            ],
          );
      },
      );
  }

  void _onTapVehicle(int id) {
    final moved = _gameState.tapVehicle(id);
    if (moved) {
      HapticFeedback.selectionClick();
      SystemSound.play(SystemSoundType.click);
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _useHint() {
    final hintId = _gameState.hintVehicleId;
    if (hintId == null) return;
    _onTapVehicle(hintId);
  }

  @override
  void dispose() {
    _gameState.removeListener(_onStateChanged);
    _gameState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _gameState.remainingSeconds ~/ 60;
    final seconds = _gameState.remainingSeconds % 60;
    final timeLow = _gameState.remainingSeconds <= 10;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6ED),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  Expanded(
                    child: Text(
                      'Level ${_gameState.level}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    ),
                  IconButton(
                    onPressed: _useHint,
                    icon: const Icon(Icons.lightbulb_outline_rounded),
                    tooltip: 'Hint',
                    ),
                  IconButton(
                    onPressed: _restart,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Restart',
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_car_filled_rounded, size: 20),
                      const SizedBox(width: 6),
                      Text('${_gameState.clearedCount}/${_gameState.totalCount}',
                           style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  Row(
                    children: [
                      Icon(Icons.timer_rounded,
                           size: 20, color: timeLow ? Colors.red : Colors.black87),
                      const SizedBox(width: 6),
                      Text(
                        '${minutes.toString().padLeft(1, "0")}:${seconds.toString().padLeft(2, "0")}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: timeLow ? Colors.red : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridBoard(gameState: _gameState, onTapVehicle: _onTapVehicle),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
