import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/kan_case.dart';
import '../../services/agent/agent_loop.dart';
import '../../services/agent/agent_reasoner.dart';
import '../../services/agent/agent_step.dart';
import '../../services/agent/default_tool_registry.dart';
import '../../services/agent/local_deterministic_agent_reasoner.dart';
import '../../services/agent/tool_registry.dart';
import '../../services/multimodal/ocr_service.dart';
import '../../services/multimodal/stt_service.dart';
import '../../services/multimodal/tts_service.dart';
import '../zpk/scan_acuse_sheet.dart';
import '../zpk/share_packet_sheet.dart';
import 'widgets/agent_stream_panel.dart';
import 'widgets/artifact_card.dart';
import 'widgets/privacy_diff_card.dart';

/// Pantalla principal del Modo Ciudadano: una sola pantalla, pregunta
/// directa, agente visible, documento al final.
class CitizenHome extends StatefulWidget {
  const CitizenHome({
    super.key,
    this.onOpenAdvancedMode,
    this.onOpenVentanilla,
    AgentReasoner? reasoner,
    ToolRegistry? toolRegistry,
  }) : _injectedReasoner = reasoner,
       _injectedTools = toolRegistry;

  final VoidCallback? onOpenAdvancedMode;
  final VoidCallback? onOpenVentanilla;
  final AgentReasoner? _injectedReasoner;
  final ToolRegistry? _injectedTools;

  @override
  State<CitizenHome> createState() => _CitizenHomeState();
}

class _CitizenHomeState extends State<CitizenHome> {
  final _controller = TextEditingController();
  final _steps = <AgentStep>[];
  StreamSubscription<AgentStep>? _sub;
  bool _running = false;
  late final AgentReasoner _reasoner;
  late final ToolRegistry _tools;
  final _stt = SttService();
  final _tts = TtsService();
  bool _listening = false;
  String _liveTranscript = '';

  @override
  void initState() {
    super.initState();
    _reasoner = widget._injectedReasoner ?? LocalDeterministicAgentReasoner();
    _tools = widget._injectedTools ?? buildDefaultToolRegistry();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    _stt.cancel();
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    if (_running) return;
    if (_listening) {
      await _stt.stopListening();
      setState(() {
        _listening = false;
        if (_liveTranscript.isNotEmpty) {
          _controller.text = _liveTranscript;
          _liveTranscript = '';
        }
      });
      return;
    }
    final ok = await _stt.ensureInitialized();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tu telefono no permite STT on-device. Usa el teclado o la camara.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _listening = true;
      _liveTranscript = '';
    });
    await _stt.startListening(
      onResult: (text) {
        if (!mounted) return;
        setState(() {
          _liveTranscript = text;
          _controller.text = text;
        });
      },
    );
  }

  Future<void> _capturePhoto() async {
    if (_running) return;
    final picker = ImagePicker();
    final XFile? picked;
    try {
      picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Camara no disponible: $e')));
      return;
    }
    if (picked == null) return;
    final ocr = OcrService();
    try {
      final result = await ocr.recognize(File(picked.path));
      if (!mounted) return;
      setState(() {
        _controller.text = result.text;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No pude leer la imagen: $e')));
    } finally {
      await ocr.dispose();
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _running) return;
    setState(() {
      _running = true;
      _steps.clear();
    });
    await _sub?.cancel();
    // Si el reasoner principal es Gemma (o cualquier no-deterministico),
    // metemos el deterministico como fallback. Asi si Gemma cierra
    // prematuro o tira excepcion, el plan local termina el trabajo
    // preservando lo que ya se hizo.
    final fallback = _reasoner is LocalDeterministicAgentReasoner
        ? null
        : LocalDeterministicAgentReasoner();

    final stream = runAgentLoop(
      input: CitizenInput(rawText: text),
      caseHint: CaseScenario.preventive,
      reasoner: _reasoner,
      tools: _tools,
      config: AgentLoopConfig(
        stepDelay: const Duration(milliseconds: 180),
        maxIterations: 10,
        fallbackReasoner: fallback,
      ),
    );
    _sub = stream.listen(
      (step) {
        if (!mounted) return;
        setState(() => _steps.add(step));
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _running = false);
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _steps.add(ErrorStep('Error inesperado: $e'));
          _running = false;
        });
      },
    );
  }

  FinalStep? get _finalStep => _steps
      .whereType<FinalStep>()
      .cast<FinalStep?>()
      .firstWhere((e) => true, orElse: () => null);

  List<String> get _redactedCategories {
    final obs = _steps.whereType<ObservationStep>();
    for (final o in obs) {
      final data = o.data;
      if (data == null) continue;
      final cats = data['categories'];
      if (cats is List) {
        return cats.map((e) => e.toString()).toList();
      }
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZPK · Modo Ciudadano'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flight),
            tooltip: 'Modo avion: nada sale del telefono',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cero red. Todo se procesa localmente.'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Escanear acuse de ventanilla',
            onPressed: _running
                ? null
                : () async {
                    await scanAcuseFromInstitution(context);
                  },
          ),
          if (widget.onOpenVentanilla != null)
            IconButton(
              icon: const Icon(Icons.business_center_outlined),
              tooltip: 'Modo Ventanilla (institucion)',
              onPressed: widget.onOpenVentanilla,
            ),
          if (widget.onOpenAdvancedMode != null)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Modo avanzado',
              onPressed: widget.onOpenAdvancedMode,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Que te paso?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Contame con tus palabras. El agente piensa en tu telefono '
                'y te genera los papeles. Nada sale.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AgentStreamPanel(steps: _steps, label: _reasoner.label),
                      if (_steps.isNotEmpty) const SizedBox(height: 12),
                      if (_finalStep != null)
                        ArtifactCard(
                          artifact: _finalStep!.artifact,
                          nextSteps: _finalStep!.nextSteps,
                          tts: _tts,
                          onShowQr: () => showSharePacketSheet(
                            context: context,
                            artifact: _finalStep!.artifact,
                            caseCode:
                                _finalStep!.artifact.camposClave['caso'] ??
                                'caso',
                            institutionLabel:
                                _finalStep!.artifact.camposClave['institucion'],
                          ),
                        ),
                      if (_finalStep != null) const SizedBox(height: 12),
                      if (_steps.isNotEmpty)
                        PrivacyDiffCard(
                          redactedCategories: _redactedCategories,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        enabled: !_running,
                        minLines: 2,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText:
                              'Ej: me llego un mensaje raro pidiendo dinero',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton.outlined(
                            tooltip: 'Tomar foto (OCR local)',
                            onPressed: _running ? null : _capturePhoto,
                            icon: const Icon(Icons.photo_camera_outlined),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: _running ? null : _send,
                            icon: _running
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: Text(
                              _running ? 'Pensando...' : 'Ayudame ahora',
                            ),
                          ),
                          const Spacer(),
                          IconButton.outlined(
                            tooltip: _listening
                                ? 'Estoy escuchando, toca para detener'
                                : 'Hablar (STT on-device)',
                            onPressed: _running ? null : _toggleMic,
                            icon: Icon(
                              _listening ? Icons.mic : Icons.mic_none,
                              color: _listening ? Colors.red : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
