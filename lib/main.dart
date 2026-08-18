import 'package:flutter/material.dart';
import 'logic/ad_service.dart';
import 'logic/player_data.dart';
import 'screens/home_screen.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final playerData = await PlayerData.load();
    // Swap MockAdService() for a real AdMob-backed AdService before shipping
    // to the stores - see the instructions in lib/logic/ad_service.dart.
    final adService = MockAdService();
    runApp(TrafficUntangleApp(playerData: playerData, adService: adService));
}

class TrafficUntangleApp extends StatelessWidget {
    final PlayerData playerData;
    final AdService adService;

    const TrafficUntangleApp({super.key, required this.playerData, required this.adService});

    @override
    Widget build(BuildContext context) {
          return MaterialApp(
                  title: 'Traffic Untangle',
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(
                            useMaterial3: true,
                            colorSchemeSeed: const Color(0xFF457B9D),
                            scaffoldBackgroundColor: const Color(0xFFFAF6ED),
                            fontFamily: 'Roboto',
                          ),
                  home: HomeScreen(playerData: playerData, adService: adService),
                );
    }
}
