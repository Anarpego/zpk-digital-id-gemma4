import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'features/demo/home_screen.dart';
import 'services/audit_archive.dart';
import 'services/local_authentication_service.dart';
import 'services/digital_identity_fabric.dart';
import 'services/reasoner_factory.dart';

void main() {
  const config = AppConfig.fromEnvironment();
  const identityFabric = DigitalIdentityFabric.device();
  final reasoner = const ReasonerFactory(
    identityFabric: identityFabric,
  ).build(config);
  runApp(
    KanApp(
      config: config,
      reasoner: reasoner,
      identityFabric: identityFabric,
      auditArchive: const NativeAuditArchive(),
    ),
  );
}

class KanApp extends StatelessWidget {
  const KanApp({
    super.key,
    AppConfig? config,
    this.reasoner,
    this.identityFabric,
    this.auditArchive,
    this.authenticationService,
  }) : config = config ?? const AppConfig.fromEnvironment();

  final AppConfig config;
  final Object? reasoner;
  final DigitalIdentityFabric? identityFabric;
  final AuditArchive? auditArchive;
  final LocalAuthenticationService? authenticationService;

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
      home: HomeScreen(
        reasoner: reasoner,
        reasonerLabel: config.label,
        identityFabric: identityFabric,
        auditArchive: auditArchive,
        authenticationService: authenticationService,
      ),
    );
  }
}
