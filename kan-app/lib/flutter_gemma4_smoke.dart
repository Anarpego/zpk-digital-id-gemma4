import 'dart:async';

import 'package:flutter/material.dart';

import 'models/kan_case.dart';
import 'services/flutter_gemma4_reasoner.dart';
import 'services/local_breach_catalog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlutterGemma4SmokeApp());
}

class FlutterGemma4SmokeApp extends StatefulWidget {
  const FlutterGemma4SmokeApp({super.key});

  @override
  State<FlutterGemma4SmokeApp> createState() => _FlutterGemma4SmokeAppState();
}

class _FlutterGemma4SmokeAppState extends State<FlutterGemma4SmokeApp> {
  static const modelUrl = String.fromEnvironment('KAN_FLUTTER_GEMMA_MODEL_URL');
  static const modelId = String.fromEnvironment(
    'KAN_FLUTTER_GEMMA_MODEL_ID',
    defaultValue: 'gemma-4-E2B-it.litertlm',
  );
  static const timeoutSeconds = int.fromEnvironment(
    'KAN_FLUTTER_GEMMA_TIMEOUT_SECONDS',
    defaultValue: 600,
  );

  var _status = 'Arrancando prueba Flutter Gemma 4.';
  var _trace = const <String>[];

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    final reasoner = FlutterGemma4Reasoner(
      modelUrl: modelUrl,
      modelId: modelId,
      maxTokens: 2048,
    );
    try {
      setState(() {
        _status = 'Instalando o abriendo Gemma 4 local.';
        _trace = const ['flutter_gemma4_smoke.start -> running'];
      });
      final before = await reasoner.runtimeStatus();
      _setTrace('Estado inicial: ${before.state}', before.trace);
      if (!before.isOfflineCapable) {
        final install = await reasoner.installRuntimeAssets().timeout(
          const Duration(seconds: timeoutSeconds),
        );
        _setTrace(install.summary, install.trace);
      }
      final selfTest = await reasoner.runRuntimeSelfTest().timeout(
        const Duration(seconds: timeoutSeconds),
      );
      _setTrace(selfTest.summary, selfTest.trace);
      final catalog = await LocalBreachCatalog.loadEmbeddedOrFallback();
      final guidance = await reasoner
          .explain(
            result: catalog.verify('1234567890101'),
            scenario: CaseScenario.discoveredVictim,
          )
          .timeout(const Duration(seconds: timeoutSeconds));
      final trace = [
        'flutter_gemma4_smoke.model -> $modelId',
        'flutter_gemma4_smoke.used_local_only -> ${guidance.usedLocalOnly}',
        'flutter_gemma4_smoke.summary -> ${guidance.summary}',
        ...guidance.toolTrace,
      ];
      for (final line in trace) {
        debugPrint(line);
      }
      _setTrace('OK: Gemma 4 local genero guia ZPK.', trace);
    } catch (error, stackTrace) {
      debugPrint('flutter_gemma4_smoke.error -> $error');
      debugPrintStack(stackTrace: stackTrace);
      _setTrace('ERROR: $error', [
        'flutter_gemma4_smoke.error -> $error',
        'flutter_gemma4_smoke.model -> $modelId',
      ]);
    }
  }

  void _setTrace(String status, List<String> trace) {
    if (!mounted) {
      return;
    }
    setState(() {
      _status = status;
      _trace = trace;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('ZPK Flutter Gemma 4')),
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
