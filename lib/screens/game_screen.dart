import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../logic/ad_service.dart';
import '../logic/game_state.dart';
import '../logic/player_data.dart';
import '../logic/skins.dart';
import '../widgets/grid_board.dart';

class GameScreen extends StatefulWidget {
  final int startLevel;
  final PlayerData playerData;
  final AdService adService;

  const GameScreen({
    super.key,
    required this.startLevel,
    required this.playerData,
    required this.adService,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;
  bool _dialogShown = false;
  String? _armedPowerUp;

  @override
  void initState() {
    super.initState();
    _gameState = GameState(
      level: widget.startLevel,
      palette: skinById(widget.playerData.equippedSkin).palette,
    );
    _gameState.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (_gameState.status == RoundStatus.won && !_dialogShown) {
      _dialogShown = true;
      final reward = Prices.levelReward(_gameState.starsEarned) +
          (_gameState.isHardLevel ? Prices.hardLevelBonus : 0);
      widget.playerData.addCredits(reward);
      widget.playerData.recordLevelReached(_gameState.level + 1);
      HapticFeedback.mediumImpact();
      Future.microtask(() => _showResultDialog(won: true, creditsEarned: reward));
    } else if (_gameState.status == RoundStatus.lost && !_dialogShown) {
      _dialogShown = true;
      HapticFeedback.heavyImpact();
      Future.microtask(() => _showResultDialog(won: false, creditsEarned: 0));
    }
    setState(() {});
  }

  void _restart() {
    setState(() {
      _dialogShown = false;
      _armedPowerUp = null;
      _gameState.restart();
    });
  }

  void _nextLevel() {
    setState(() {
      _dialogShown = false;
      _armedPowerUp = null;
      _gameState.nextLevel();
    });
  }

  void _showResultDialog({required bool won, required int creditsEarned}) {
    if (!mounted) return;
    final rootContext = context;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(won ? 'Traffic Cleared!' : "Time's Up!", textAlign: TextAlign.center),
          content: won
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final filled = i < _gameState.starsEarned;
                        return Icon(
                          filled ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 40,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFB703), size: 18),
                        const SizedBox(width: 4),
                        Text('+$creditsEarned credits', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final earned = await widget.adService.showRewarded(
                          rootContext,
                          rewardLabel: '${Prices.rewardedAdCredits} bonus credits',
                        );
                        if (earned) widget.playerData.addCredits(Prices.rewardedAdCredits);
                      },
                      icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                      label: Text('+${Prices.rewardedAdCredits} bonus (watch ad)'),
                    ),
                  ],
                )
              : const Text('The jam beat the clock. Give it another go?', textAlign: TextAlign.center),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Home'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                if (won) {
                  final completedLevel = _gameState.level;
                  if (completedLevel % 3 == 0 && !widget.playerData.adsRemoved) {
                    await widget.adService.showInterstitial(rootContext);
                  }
                  if (!mounted) return;
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
    if (_armedPowerUp == PowerUpType.autoClear) {
      final consumed = widget.playerData.usePowerUp(PowerUpType.autoClear);
      setState(() => _armedPowerUp = null);
      if (!consumed) return;
      final moved = _gameState.forceClearVehicle(id);
      if (moved) {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
      }
      return;
    }
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

  static const _powerUpNames = {
    PowerUpType.extraTime: 'Extra Time',
    PowerUpType.autoClear: 'Auto-Clear',
    PowerUpType.shuffle: 'Shuffle Traffic',
  };

  void _promptBuy(String type) {
    final name = _powerUpNames[type] ?? 'that tool';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("You're out of $name - buy more from the Shop."), duration: const Duration(seconds: 2)),
    );
  }

  void _togglePowerUp(String type) {
    if (type == PowerUpType.autoClear) {
      setState(() => _armedPowerUp = (_armedPowerUp == type) ? null : type);
      return;
    }
    if (widget.playerData.ownedPowerUps(type) <= 0) {
      _promptBuy(type);
      return;
    }
    widget.playerData.usePowerUp(type);
    if (type == PowerUpType.extraTime) {
      _gameState.addTime(15);
    } else if (type == PowerUpType.shuffle) {
      _gameState.shuffleRemaining();
    }
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _gameState.removeListener(_onStateChanged);
    _gameState.dispose();
    super.dispose();
  }

  Widget _powerUpButton(String type, IconData icon) {
    final owned = widget.playerData.ownedPowerUps(type);
    final armed = _armedPowerUp == type;
    return GestureDetector(
      onTap: () => _togglePowerUp(type),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: armed ? const Color(0xFF457B9D) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF457B9D), width: armed ? 0 : 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, color: armed ? Colors.white : const Color(0xFF457B9D))),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xFFE63946), borderRadius: BorderRadius.circular(8)),
                child: Text('$owned', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
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
                    child: Column(
                      children: [
                        Text(
                          'Level ${_gameState.level}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        if (_gameState.isHardLevel)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFE63946), borderRadius: BorderRadius.circular(10)),
                            child: const Text('HARD LEVEL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                      ],
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _powerUpButton(PowerUpType.extraTime, Icons.timer_outlined),
                  const SizedBox(width: 14),
                  _powerUpButton(PowerUpType.autoClear, Icons.flash_on_rounded),
                  const SizedBox(width: 14),
                  _powerUpButton(PowerUpType.shuffle, Icons.shuffle_rounded),
                ],
              ),
            ),
            if (_armedPowerUp == PowerUpType.autoClear)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Tap any car to instantly clear it', style: TextStyle(fontSize: 12, color: Color(0xFF457B9D), fontWeight: FontWeight.w600)),
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

