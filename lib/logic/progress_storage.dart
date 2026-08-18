import 'package:shared_preferences/shared_preferences.dart';

/// Tiny wrapper around shared_preferences so the rest of the app never
/// touches the plugin directly.
class ProgressStorage {
  static const _bestLevelKey = 'best_level_reached';

  static Future<int> getBestLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestLevelKey) ?? 1;
  }

  static Future<void> saveBestLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_bestLevelKey) ?? 1;
    if (level > current) {
      await prefs.setInt(_bestLevelKey, level);
    }
  }
}
