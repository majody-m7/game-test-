import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for the three purchasable power-ups. Kept as plain strings (rather
/// than an enum) so they can be used directly as SharedPreferences/JSON-ish
/// map keys without an extra layer of mapping.
class PowerUpType {
  static const extraTime = 'extra_time';
  static const autoClear = 'auto_clear';
  static const shuffle = 'shuffle';

  static const all = [extraTime, autoClear, shuffle];
}

/// Prices, in credits, for everything the player can buy. Centralized here
/// so the shop screen and any "can I afford this" check always agree.
class Prices {
  static const powerUps = {
    PowerUpType.extraTime: 40,
    PowerUpType.autoClear: 60,
    PowerUpType.shuffle: 30,
  };

  static const startingCredits = 50;
  static const rewardedAdCredits = 25;
  static const hardLevelBonus = 20;

  /// Credits cost of a 30-day "Remove Ads" pass. This is a placeholder,
  /// credit-funded stand-in for a real auto-renewing subscription - see
  /// the note on [PlayerData.buyRemoveAds] for how to wire up real store
  /// billing before shipping.
  static const removeAdsPrice = 200;
  static const removeAdsDays = 30;

  static int levelReward(int stars) => 15 + 5 * stars;
}

/// All persisted player/account state: currency, progress, and what's been
/// bought. A single instance is loaded once at app start (see [load]) and
/// passed down the widget tree; it's a ChangeNotifier so any screen holding
/// a reference can listen and rebuild when credits or inventory change.
class PlayerData extends ChangeNotifier {
  int credits;
  int bestLevel;
  final Map<String, int> _powerUps;
  final Set<String> unlockedSkins;
  String equippedSkin;
  DateTime? adsRemovedUntil;

  PlayerData._({
    required this.credits,
    required this.bestLevel,
    required Map<String, int> powerUps,
    required this.unlockedSkins,
    required this.equippedSkin,
    this.adsRemovedUntil,
  }) : _powerUps = powerUps;

  static const _kCredits = 'credits';
  static const _kBestLevel = 'best_level_reached';
  static const _kPowerUpPrefix = 'powerup_';
  static const _kUnlockedSkins = 'unlocked_skins';
  static const _kEquippedSkin = 'equipped_skin';
  static const _kAdsRemovedUntil = 'ads_removed_until';

  static Future<PlayerData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPlayedBefore = prefs.containsKey(_kCredits);
    final powerUps = <String, int>{
      for (final type in PowerUpType.all) type: prefs.getInt('$_kPowerUpPrefix$type') ?? 0,
    };
    final adsRemovedMs = prefs.getInt(_kAdsRemovedUntil);
    return PlayerData._(
      credits: prefs.getInt(_kCredits) ?? (hasPlayedBefore ? 0 : Prices.startingCredits),
      bestLevel: prefs.getInt(_kBestLevel) ?? 1,
      powerUps: powerUps,
      unlockedSkins: (prefs.getStringList(_kUnlockedSkins) ?? ['classic']).toSet(),
      equippedSkin: prefs.getString(_kEquippedSkin) ?? 'classic',
      adsRemovedUntil: adsRemovedMs != null ? DateTime.fromMillisecondsSinceEpoch(adsRemovedMs) : null,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCredits, credits);
    await prefs.setInt(_kBestLevel, bestLevel);
    for (final entry in _powerUps.entries) {
      await prefs.setInt('$_kPowerUpPrefix${entry.key}', entry.value);
    }
    await prefs.setStringList(_kUnlockedSkins, unlockedSkins.toList());
    await prefs.setString(_kEquippedSkin, equippedSkin);
    if (adsRemovedUntil != null) {
      await prefs.setInt(_kAdsRemovedUntil, adsRemovedUntil!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_kAdsRemovedUntil);
    }
  }

  int ownedPowerUps(String type) => _powerUps[type] ?? 0;

  /// True while a "Remove Ads" pass is active - interstitial ads should be
  /// skipped for as long as this is true.
  bool get adsRemoved => adsRemovedUntil != null && DateTime.now().isBefore(adsRemovedUntil!);

  void addCredits(int amount) {
    credits += amount;
    _save();
    notifyListeners();
  }

  /// Returns false (and changes nothing) if the player can't afford it.
  bool spendCredits(int amount) {
    if (credits < amount) return false;
    credits -= amount;
    _save();
    notifyListeners();
    return true;
  }

  bool buyPowerUp(String type) {
    final price = Prices.powerUps[type];
    if (price == null) return false;
    if (!spendCredits(price)) return false;
    _powerUps[type] = ownedPowerUps(type) + 1;
    _save();
    notifyListeners();
    return true;
  }

  /// Consumes one owned power-up of [type]. Returns false if none owned.
  bool usePowerUp(String type) {
    final owned = ownedPowerUps(type);
    if (owned <= 0) return false;
    _powerUps[type] = owned - 1;
    _save();
    notifyListeners();
    return true;
  }

  void recordLevelReached(int level) {
    if (level > bestLevel) {
      bestLevel = level;
      _save();
      notifyListeners();
    }
  }

  bool buySkin(String id, int price) {
    if (unlockedSkins.contains(id)) return true;
    if (!spendCredits(price)) return false;
    unlockedSkins.add(id);
    _save();
    notifyListeners();
    return true;
  }

  void equipSkin(String id) {
    if (!unlockedSkins.contains(id)) return;
    equippedSkin = id;
    _save();
    notifyListeners();
  }

  /// Buys (or extends) a 30-day ad-free pass for [Prices.removeAdsPrice]
  /// credits. Stacks on top of any time remaining, so buying early never
  /// wastes days already paid for.
  ///
  /// This spends in-game credits as a stand-in for a real recurring
  /// purchase. Before shipping to the stores, swap this for a genuine
  /// auto-renewing subscription via Google Play Billing / StoreKit, and
  /// call [grantAdsRemoved] from the purchase-verified callback instead.
  bool buyRemoveAds() {
    if (!spendCredits(Prices.removeAdsPrice)) return false;
    grantAdsRemoved();
    return true;
  }

  /// Extends the ad-free window by [Prices.removeAdsDays] days from now,
  /// or from the current expiry if a pass is already active. Split out
  /// from [buyRemoveAds] so a real store-billing integration can call this
  /// directly once a purchase is verified.
  void grantAdsRemoved() {
    final base = adsRemoved ? adsRemovedUntil! : DateTime.now();
    adsRemovedUntil = base.add(const Duration(days: Prices.removeAdsDays));
    _save();
    notifyListeners();
  }
}

