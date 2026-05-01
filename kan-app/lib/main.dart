import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'features/demo/home_screen.dart';
import 'services/reasoner_factory.dart';

void main() {
  const config = AppConfig.fromEnvironment();
  final reasoner = const ReasonerFactory().build(config);
  runApp(KanApp(config: config, reasoner: reasoner));
}

class KanApp extends StatelessWidget {
  const KanApp({super.key, AppConfig? config, this.reasoner})
    : config = config ?? const AppConfig.fromEnvironment();

  final AppConfig config;
  final Object? reasoner;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xff006d5b);

    return MaterialApp(
      title: 'ZPK Digital ID',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff7f7f2),
        useMaterial3: true,
      ),
      home: HomeScreen(reasoner: reasoner, reasonerLabel: config.label),
    );
  }
}
