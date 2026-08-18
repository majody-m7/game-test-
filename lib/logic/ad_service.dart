import 'dart:async';
import 'package:flutter/material.dart';

/// Thin interface between the game and whatever ad SDK actually runs.
///
/// HOW TO SWAP IN REAL ADMOB LATER:
/// 1. Add `google_mobile_ads` to pubspec.yaml and run `flutter pub get`.
/// 2. Create a new class, e.g. `AdMobAdService implements AdService`, that
///    loads/shows real InterstitialAd / RewardedAd objects using your real
///    AdMob App ID and Ad Unit IDs (from your AdMob account).
/// 3. In main.dart, change `final adService = MockAdService();` to
///    `final adService = AdMobAdService();` - nothing else in the app
///    needs to change, because every screen only ever talks to this
///    interface.
abstract class AdService {
    /// Shows a short, non-rewarded ad. Used between levels. Completes when
    /// the ad is done/dismissed.
    Future<void> showInterstitial(BuildContext context);

    /// Offers a rewarded ad. Returns true if the player watched it to
    /// completion and should receive the reward, false if they declined or
    /// closed it early.
    Future<bool> showRewarded(BuildContext context, {required String rewardLabel});
}

/// A placeholder ad service that simulates the timing and flow of a real
/// ad network (loading -> playing -> closable) without any real network
/// calls or SDK, so the whole ad-triggered economy can be built and tested
/// today. Swap for a real implementation per the instructions above.
class MockAdService implements AdService {
    @override
    Future<void> showInterstitial(BuildContext context) async {
          await showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const _MockAdDialog(
                            title: 'Advertisement',
                            watchSeconds: 3,
                            isRewarded: false,
                          ),
                );
    }

    @override
    Future<bool> showRewarded(BuildContext context, {required String rewardLabel}) async {
          final agreed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text("Watch a short ad?"),
                            content: Text("Watch a short video ad to earn $rewardLabel."),
                            actions: [
                                        TextButton(
                                                      onPressed: () => Navigator.of(context).pop(false),
                                                      child: const Text("No thanks"),
                                                    ),
                                        FilledButton(
                                                      onPressed: () => Navigator.of(context).pop(true),
                                                      child: const Text("Watch"),
                                                    ),
                                      ],
                          ),
                );
          if (agreed != true) return false;
          if (!context.mounted) return false;

          final completed = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const _MockAdDialog(
                            title: 'Advertisement',
                            watchSeconds: 3,
                            isRewarded: true,
                          ),
                );
          return completed ?? false;
    }
}

class _MockAdDialog extends StatefulWidget {
    final String title;
    final int watchSeconds;
    final bool isRewarded;

    const _MockAdDialog({
          required this.title,
          required this.watchSeconds,
          required this.isRewarded,
    });

    @override
    State<_MockAdDialog> createState() => _MockAdDialogState();
}

class _MockAdDialogState extends State<_MockAdDialog> {
    late int _secondsLeft = widget.watchSeconds;
    Timer? _timer;

    @override
    void initState() {
          super.initState();
          _timer = Timer.periodic(const Duration(seconds: 1), (_) {
                  setState(() => _secondsLeft -= 1);
                  if (_secondsLeft <= 0) {
                            _timer?.cancel();
                            Navigator.of(context).pop(widget.isRewarded ? true : null);
                  }
          });
    }

    @override
    void dispose() {
          _timer?.cancel();
          super.dispose();
    }

    @override
    Widget build(BuildContext context) {
          return PopScope(
                  canPop: false,
                  child: Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                                        padding: const EdgeInsets.all(28.0),
                                        child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                                      const Icon(Icons.play_circle_fill_rounded, size: 64, color: Color(0xFF457B9D)),
                                                                      const SizedBox(height: 16),
                                                                      Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                                                      const SizedBox(height: 8),
                                                                      Text(
                                                                                        "This is a placeholder ad (no real ad network is wired in yet).",
                                                                                        textAlign: TextAlign.center,
                                                                                        style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.6)),
                                                                                      ),
                                                                      const SizedBox(height: 20),
                                                                      Text('$_secondsLeft', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                                                                      const SizedBox(height: 4),
                                                                      const Text('seconds remaining', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                                                    ],
                                                    ),
                                      ),
                          ),
                );
    }
}
