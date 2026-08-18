import 'package:flutter/material.dart';
import '../logic/ad_service.dart';
import '../logic/player_data.dart';
import 'game_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatelessWidget {
    final PlayerData playerData;
    final AdService adService;

    const HomeScreen({super.key, required this.playerData, required this.adService});

    void _play(BuildContext context, {int? level}) {
          Navigator.of(context).push(
                  MaterialPageRoute(
                            builder: (_) => GameScreen(
                                        startLevel: level ?? playerData.bestLevel,
                                        playerData: playerData,
                                        adService: adService,
                                      ),
                          ),
                );
    }

    void _openShop(BuildContext context) {
          Navigator.of(context).push(
                  MaterialPageRoute(
                            builder: (_) => ShopScreen(playerData: playerData, adService: adService),
                          ),
                );
    }

    @override
    Widget build(BuildContext context) {
          return Scaffold(
                  backgroundColor: const Color(0xFFFAF6ED),
                  body: SafeArea(
                            child: AnimatedBuilder(
                                        animation: playerData,
                                        builder: (context, _) {
                                                      return Column(
                                                                      children: [
                                                                                        Padding(
                                                                                                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                                                                                                            child: Row(
                                                                                                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                                                                                                  children: [
                                                                                                                                                          Container(
                                                                                                                                                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                                                                                                                                                    decoration: BoxDecoration(
                                                                                                                                                                                                                color: Colors.white,
                                                                                                                                                                                                                borderRadius: BorderRadius.circular(20),
                                                                                                                                                                                                                boxShadow: [
                                                                                                                                                                                                                                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
                                                                                                                                                                                                                                            ],
                                                                                                                                                                                                              ),
                                                                                                                                                                                    child: Row(
                                                                                                                                                                                                                children: [
                                                                                                                                                                                                                                              const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFB703), size: 20),
                                                                                                                                                                                                                                              const SizedBox(width: 6),
                                                                                                                                                                                                                                              Text('${playerData.credits}',
                                                                                                                                                                                                                                                                                   style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                                                                                                                                                                                                                            ],
                                                                                                                                                                                                              ),
                                                                                                                                                                                  ),
                                                                                                                                                        ],
                                                                                                                                ),
                                                                                                          ),
                                                                                        Expanded(
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
                                                                                                                                                                                                                                              "Tap a car to drive it off the grid.\nClear the jam before time runs out!",
                                                                                                                                                                                                                                              textAlign: TextAlign.center,
                                                                                                                                                                                                                                              style: TextStyle(fontSize: 16, color: Colors.black54),
                                                                                                                                                                                                                                            ),
                                                                                                                                                                                                                const SizedBox(height: 40),
                                                                                                                                                                                                                SizedBox(
                                                                                                                                                                                                                                              width: double.infinity,
                                                                                                                                                                                                                                              height: 56,
                                                                                                                                                                                                                                              child: FilledButton(
                                                                                                                                                                                                                                                                              onPressed: () => _play(context),
                                                                                                                                                                                                                                                                              style: FilledButton.styleFrom(
                                                                                                                                                                                                                                                                                                                backgroundColor: const Color(0xFFE63946),
                                                                                                                                                                                                                                                                                                                shape: RoundedRectangleBorder(
                                                                                                                                                                                                                                                                                                                                                      borderRadius: BorderRadius.circular(16)),
                                                                                                                                                                                                                                                                                                              ),
                                                                                                                                                                                                                                                                              child: Text(
                                                                                                                                                                                                                                                                                                                playerData.bestLevel > 1 ? 'Continue - Level ${playerData.bestLevel}' : 'Play',
                                                                                                                                                                                                                                                                                                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                                                                                                                                                                                                                                                                                                              ),
                                                                                                                                                                                                                                                                            ),
                                                                                                                                                                                                                                            ),
                                                                                                                                                                                                                const SizedBox(height: 12),
                                                                                                                                                                                                                SizedBox(
                                                                                                                                                                                                                                              width: double.infinity,
                                                                                                                                                                                                                                              height: 52,
                                                                                                                                                                                                                                              child: OutlinedButton.icon(
                                                                                                                                                                                                                                                                              onPressed: () => _openShop(context),
                                                                                                                                                                                                                                                                              icon: const Icon(Icons.storefront_rounded),
                                                                                                                                                                                                                                                                              label: const Text('Shop', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                                                                                                                                                                                                                                                                              style: OutlinedButton.styleFrom(
                                                                                                                                                                                                                                                                                                                foregroundColor: const Color(0xFF457B9D),
                                                                                                                                                                                                                                                                                                                side: const BorderSide(color: Color(0xFF457B9D), width: 1.5),
                                                                                                                                                                                                                                                                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                                                                                                                                                                                                                                                                              ),
                                                                                                                                                                                                                                                                            ),
                                                                                                                                                                                                                                            ),
                                                                                                                                                                                                                if (playerData.bestLevel > 1)
                                                                                                                                                                                                                  Padding(
                                                                                                                                                                                                                                                  padding: const EdgeInsets.only(top: 12),
                                                                                                                                                                                                                                                  child: TextButton(
                                                                                                                                                                                                                                                                                    onPressed: () => _play(context, level: 1),
                                                                                                                                                                                                                                                                                    child: const Text('Start over from Level 1'),
                                                                                                                                                                                                                                                                                  ),
                                                                                                                                                                                                                                                ),
                                                                                                                                                                                                              ],
                                                                                                                                                                                  ),
                                                                                                                                                        ),
                                                                                                                                ),
                                                                                                          ),
                                                                                      ],
                                                                    );
                                        },
                                      ),
                          ),
                );
    }
}
