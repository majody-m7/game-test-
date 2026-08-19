import 'package:flutter/material.dart';
import '../logic/ad_service.dart';
import '../logic/player_data.dart';
import '../logic/skins.dart';

class ShopScreen extends StatelessWidget {
  final PlayerData playerData;
  final AdService adService;

  const ShopScreen({super.key, required this.playerData, required this.adService});

  static const _powerUpInfo = {
    PowerUpType.extraTime: (
      icon: Icons.timer_outlined,
      name: 'Extra Time',
      desc: 'Adds 15 seconds to the clock mid-level.',
    ),
    PowerUpType.autoClear: (
      icon: Icons.flash_on_rounded,
      name: 'Auto-Clear',
      desc: 'Instantly drives one car off, even if blocked.',
    ),
    PowerUpType.shuffle: (
      icon: Icons.shuffle_rounded,
      name: 'Shuffle Traffic',
      desc: 'Re-arranges the remaining cars into a fresh, solvable layout.',
    ),
  };

  void _buyPowerUp(BuildContext context, String type) {
    final price = Prices.powerUps[type]!;
    final ok = playerData.buyPowerUp(type);
    _snack(context, ok ? 'Bought!' : 'Not enough credits (need $price).');
  }

  void _buySkin(BuildContext context, CarSkin skin) {
    if (playerData.unlockedSkins.contains(skin.id)) {
      playerData.equipSkin(skin.id);
      _snack(context, '${skin.name} equipped.');
      return;
    }
    final ok = playerData.buySkin(skin.id, skin.price);
    if (ok) {
      playerData.equipSkin(skin.id);
      _snack(context, '${skin.name} unlocked and equipped!');
    } else {
      _snack(context, 'Not enough credits (need ${skin.price}).');
    }
  }

  void _buyRemoveAds(BuildContext context) {
    final wasActive = playerData.adsRemoved;
    final ok = playerData.buyRemoveAds();
    _snack(
      context,
      ok
          ? (wasActive ? '30 more ad-free days added!' : 'Ads removed for 30 days!')
          : 'Not enough credits (need ${Prices.removeAdsPrice}).',
    );
  }

  Future<void> _watchAd(BuildContext context) async {
    final earned = await adService.showRewarded(context, rewardLabel: '${Prices.rewardedAdCredits} credits');
    if (earned) {
      playerData.addCredits(Prices.rewardedAdCredits);
      if (context.mounted) _snack(context, '+${Prices.rewardedAdCredits} credits!');
    }
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime dt) => '${_months[dt.month - 1]} ${dt.day}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6ED),
        elevation: 0,
        title: const Text('Shop', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          AnimatedBuilder(
            animation: playerData,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFB703)),
                  const SizedBox(width: 4),
                  Text('${playerData.credits}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: playerData,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _watchAd(context),
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  label: Text('Watch ad for +${Prices.rewardedAdCredits} credits'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: const Color(0xFF2A9D8F),
                    side: const BorderSide(color: Color(0xFF2A9D8F), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Go Ad-Free', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              _removeAdsTile(context),
              const SizedBox(height: 24),
              const Text('Helping Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final type in PowerUpType.all) _powerUpTile(context, type),
              const SizedBox(height: 24),
              const Text('Car Skins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final skin in kCarSkins) _skinTile(context, skin),
            ],
          );
        },
      ),
    );
  }

  Widget _removeAdsTile(BuildContext context) {
    final active = playerData.adsRemoved;
    final subtitle = active
        ? 'Active until ${_formatDate(playerData.adsRemovedUntil!)} - no interstitial ads between levels.'
        : 'Skip interstitial ads between levels for 30 days.';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: active ? const Color(0xFFE4F3EC) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: active ? const BorderSide(color: Color(0xFF2A9D8F), width: 1.2) : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEFE7DA),
          child: Icon(
            active ? Icons.verified_rounded : Icons.block_rounded,
            color: const Color(0xFF2A9D8F),
          ),
        ),
        title: const Text('Remove Ads (30 days)', style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        isThreeLine: true,
        trailing: FilledButton(
          onPressed: () => _buyRemoveAds(context),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2A9D8F)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text('${Prices.removeAdsPrice}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _powerUpTile(BuildContext context, String type) {
    final info = _powerUpInfo[type]!;
    final price = Prices.powerUps[type]!;
    final owned = playerData.ownedPowerUps(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFFEFE7DA), child: Icon(info.icon, color: const Color(0xFF457B9D))),
        title: Text(info.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${info.desc}\nOwned: $owned', style: const TextStyle(fontSize: 12)),
        isThreeLine: true,
        trailing: FilledButton(
          onPressed: () => _buyPowerUp(context, type),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFB703)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text('$price'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skinTile(BuildContext context, CarSkin skin) {
    final owned = playerData.unlockedSkins.contains(skin.id);
    final equipped = playerData.equippedSkin == skin.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: SizedBox(
          width: 44,
          height: 44,
          child: Wrap(
            spacing: 2,
            runSpacing: 2,
            children: [for (final c in skin.palette.take(6)) Container(width: 12, height: 12, color: c)],
          ),
        ),
        title: Text(skin.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(equipped ? 'Equipped' : (owned ? 'Owned' : 'Locked')),
        trailing: equipped
            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2A9D8F))
            : FilledButton(
                onPressed: () => _buySkin(context, skin),
                style: FilledButton.styleFrom(
                  backgroundColor: owned ? const Color(0xFF457B9D) : const Color(0xFFFFB703),
                ),
                child: owned
                    ? const Text('Equip')
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('${skin.price}'),
                        ],
                      ),
              ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../logic/ad_service.dart';
import '../logic/player_data.dart';
import '../logic/skins.dart';

class ShopScreen extends StatelessWidget {
    final PlayerData playerData;
    final AdService adService;

    const ShopScreen({super.key, required this.playerData, required this.adService});

    static const _powerUpInfo = {
          PowerUpType.extraTime: (
                  icon: Icons.timer_outlined,
                  name: 'Extra Time',
                  desc: 'Adds 15 seconds to the clock mid-level.',
                ),
          PowerUpType.autoClear: (
                  icon: Icons.flash_on_rounded,
                  name: 'Auto-Clear',
                  desc: 'Instantly drives one car off, even if blocked.',
                ),
          PowerUpType.shuffle: (
                  icon: Icons.shuffle_rounded,
                  name: 'Shuffle Traffic',
                  desc: 'Re-arranges the remaining cars into a fresh, solvable layout.',
                ),
    };

    void _buyPowerUp(BuildContext context, String type) {
          final price = Prices.powerUps[type]!;
          final ok = playerData.buyPowerUp(type);
          _snack(context, ok ? 'Bought!' : 'Not enough credits (need $price).');
    }

    void _buySkin(BuildContext context, CarSkin skin) {
          if (playerData.unlockedSkins.contains(skin.id)) {
                  playerData.equipSkin(skin.id);
                  _snack(context, '${skin.name} equipped.');
                  return;
          }
          final ok = playerData.buySkin(skin.id, skin.price);
          if (ok) {
                  playerData.equipSkin(skin.id);
                  _snack(context, '${skin.name} unlocked and equipped!');
          } else {
                  _snack(context, 'Not enough credits (need ${skin.price}).');
          }
    }

    Future<void> _watchAd(BuildContext context) async {
          final earned = await adService.showRewarded(context, rewardLabel: '${Prices.rewardedAdCredits} credits');
          if (earned) {
                  playerData.addCredits(Prices.rewardedAdCredits);
                  if (context.mounted) _snack(context, '+${Prices.rewardedAdCredits} credits!');
          }
    }

    void _snack(BuildContext context, String message) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
    }

    @override
    Widget build(BuildContext context) {
          return Scaffold(
                  backgroundColor: const Color(0xFFFAF6ED),
                  appBar: AppBar(
                            backgroundColor: const Color(0xFFFAF6ED),
                            elevation: 0,
                            title: const Text('Shop', style: TextStyle(fontWeight: FontWeight.w800)),
                            actions: [
                                        AnimatedBuilder(
                                                      animation: playerData,
                                                      builder: (context, _) => Padding(
                                                                      padding: const EdgeInsets.only(right: 16),
                                                                      child: Row(
                                                                                        children: [
                                                                                                            const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFB703)),
                                                                                                            const SizedBox(width: 4),
                                                                                                            Text('${playerData.credits}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                                                                                          ],
                                                                                      ),
                                                                    ),
                                                    ),
                                      ],
                          ),
                  body: AnimatedBuilder(
                            animation: playerData,
                            builder: (context, _) {
                                        return ListView(
                                                      padding: const EdgeInsets.all(16),
                                                      children: [
                                                                      SizedBox(
                                                                                        width: double.infinity,
                                                                                        child: OutlinedButton.icon(
                                                                                                            onPressed: () => _watchAd(context),
                                                                                                            icon: const Icon(Icons.play_circle_fill_rounded),
                                                                                                            label: Text('Watch ad for +${Prices.rewardedAdCredits} credits'),
                                                                                                            style: OutlinedButton.styleFrom(
                                                                                                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                                                                                                  foregroundColor: const Color(0xFF2A9D8F),
                                                                                                                                  side: const BorderSide(color: Color(0xFF2A9D8F), width: 1.5),
                                                                                                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                                                                                                ),
                                                                                                          ),
                                                                                      ),
                                                                      const SizedBox(height: 24),
                                                                      const Text('Helping Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                                                      const SizedBox(height: 8),
                                                                      for (final type in PowerUpType.all) _powerUpTile(context, type),
                                                                      const SizedBox(height: 24),
                                                                      const Text('Car Skins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                                                      const SizedBox(height: 8),
                                                                      for (final skin in kCarSkins) _skinTile(context, skin),
                                                                    ],
                                                    );
                            },
                          ),
                );
    }

    Widget _powerUpTile(BuildContext context, String type) {
          final info = _powerUpInfo[type]!;
          final price = Prices.powerUps[type]!;
          final owned = playerData.ownedPowerUps(type);

          return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                            leading: CircleAvatar(backgroundColor: const Color(0xFFEFE7DA), child: Icon(info.icon, color: const Color(0xFF457B9D))),
                            title: Text(info.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('${info.desc}\nOwned: $owned', style: const TextStyle(fontSize: 12)),
                            isThreeLine: true,
                            trailing: FilledButton(
                                        onPressed: () => _buyPowerUp(context, type),
                                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFB703)),
                                        child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                                      const Icon(Icons.monetization_on_rounded, size: 16, color: Colors.white),
                                                                      const SizedBox(width: 4),
                                                                      Text('$price'),
                                                                    ],
                                                    ),
                                      ),
                          ),
                );
    }

    Widget _skinTile(BuildContext context, CarSkin skin) {
          final owned = playerData.unlockedSkins.contains(skin.id);
          final equipped = playerData.equippedSkin == skin.id;

          return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                            leading: SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: Wrap(
                                                      spacing: 2,
                                                      runSpacing: 2,
                                                      children: [for (final c in skin.palette.take(6)) Container(width: 12, height: 12, color: c)],
                                                    ),
                                      ),
                            title: Text(skin.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(equipped ? 'Equipped' : (owned ? 'Owned' : 'Locked')),
                            trailing: equipped
                                ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2A9D8F))
                                : FilledButton(
                                                  onPressed: () => _buySkin(context, skin),
                                                  style: FilledButton.styleFrom(
                                                                      backgroundColor: owned ? const Color(0xFF457B9D) : const Color(0xFFFFB703),
                                                                    ),
                                                  child: owned
                                                      ? const Text('Equip')
                                                      : Row(
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                children: [
                                                                                                            const Icon(Icons.monetization_on_rounded, size: 16, color: Colors.white),
                                                                                                            const SizedBox(width: 4),
                                                                                                            Text('${skin.price}'),
                                                                                                          ],
                                                                              ),
                                                ),
                          ),
                );
    }
}
