import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/map_screen.dart';
import 'screens/tips_screen.dart';
import 'screens/gacha/inventory_manager.dart';
import 'state/app_data.dart';
import 'screens/gacha/coin_manager.dart';
import 'screens/gacha/inventory_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // AppDataを先に読み込む
  await AppData.instance.ensureLoaded();

  // Inventoryをアプリ全体で1つだけ作る
  final inventoryData = InventoryData();
  await inventoryData.loadFromStorage();

  // Coinもアプリ全体で1つだけ作る
  final coinData = CoinData();

  runApp(
    CoinDataProvider(
      coinData: coinData,
      child: InventoryProvider(
        inventoryData: inventoryData,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qoo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}
