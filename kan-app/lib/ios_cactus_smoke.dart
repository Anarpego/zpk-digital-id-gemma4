import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cactus/cactus.dart';

import 'models/kan_case.dart';
import 'services/cactus_reasoner.dart';
import 'services/digital_identity_fabric.dart';
import 'services/local_breach_catalog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IosCactusSmokeApp());
}

class IosCactusSmokeApp extends StatefulWidget {
  const IosCactusSmokeApp({super.key});

  @override
  State<IosCactusSmokeApp> createState() => _IosCactusSmokeAppState();
}

class _IosCactusSmokeAppState extends State<IosCactusSmokeApp> {
  static const model = String.fromEnvironment(
    'KAN_CACTUS_MODEL',
    defaultValue: 'functiongemma-270m-pro',
  );
  static const timeoutSeconds = int.fromEnvironment(
    'KAN_CACTUS_TIMEOUT_SECONDS',
    defaultValue: 180,
  );
  static const enableTools = bool.fromEnvironment(
    'KAN_CACTUS_ENABLE_TOOLS',
    defaultValue: false,
  );

  var _status = 'Arrancando prueba iOS Cactus local.';
  var _trace = const <String>[];

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    try {
      setState(() {
        _status = 'Descargando o abriendo modelo local: $model';
        _trace = const ['ios_cactus_smoke.start -> running'];
      });
      CactusConfig.isTelemetryEnabled = false;
      final catalog = await LocalBreachCatalog.loadEmbeddedOrFallback();
      final result = catalog.verify('1234567890101');
      final guidance =
          await CactusReasoner(
                model: model,
                maxTokens: 384,
                enableTools: enableTools,
                identityFabric: const DigitalIdentityFabric.device(),
              )
              .explain(result: result, scenario: CaseScenario.discoveredVictim)
              .timeout(const Duration(seconds: timeoutSeconds));
      final trace = [
        'ios_cactus_smoke.model -> $model',
        'ios_cactus_smoke.tools -> ${enableTools ? 'enabled' : 'disabled'}',
        'ios_cactus_smoke.used_local_only -> ${guidance.usedLocalOnly}',
        'ios_cactus_smoke.summary -> ${guidance.summary}',
        ...guidance.toolTrace,
      ];
      for (final line in trace) {
        debugPrint(line);
      }
      if (mounted) {
        setState(() {
          _status = 'OK: modelo local genero guia y paso contrato.';
          _trace = trace;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('ios_cactus_smoke.error -> $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _status = 'ERROR: $error';
          _trace = [
            'ios_cactus_smoke.error -> $error',
            'ios_cactus_smoke.model -> $model',
          ];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('ZPK iOS Cactus Smoke')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(_status, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final line in _trace)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(line),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
