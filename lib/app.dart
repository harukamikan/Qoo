import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'state/app_data.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

/// アプリのエントリーウィジェット。
/// 起動時にローカル保存データ（またはシードデータ）を読み込んでから
/// [HomeShell] を表示する。
class JamApp extends StatelessWidget {
  const JamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JAM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AppLoader(),
    );
  }
}

class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = AppData.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.travel_explore,
                      size: 56, color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'JAM',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                    ),
                  ),
                  SizedBox(height: 20),
                  CircularProgressIndicator(color: AppColors.primary),
                ],
              ),
            ),
          );
        }
        return const HomeShell();
      },
    );
  }
}
