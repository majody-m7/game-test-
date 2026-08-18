import 'package:flutter/material.dart';
import '../logic/progress_storage.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bestLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final best = await ProgressStorage.getBestLevel();
    if (mounted) setState(() => _bestLevel = best);
  }

  void _play() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(startLevel: _bestLevel)),
      );
    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6ED),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_car_filled_rounded,
                           size: 96, color: Color(0xFF457B9D)),
                const SizedBox(height: 16),
                const Text(
                  'Traffic Untangle',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Tap a car to drive it off the grid.\nClear the jam before time runs out!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _play,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE63946),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                      ),
                    child: Text(
                      _bestLevel > 1 ? 'Continue - Level $_bestLevel' : 'Play',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                if (_bestLevel > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GameScreen(startLevel: 1)),
                        );
                      _loadProgress();
                    },
                    child: const Text('Start over from Level 1'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}
