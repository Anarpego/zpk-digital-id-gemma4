import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../models/kan_case.dart';

class LocalBreachCatalog {
  LocalBreachCatalog({
    DateTime? now,
    Map<String, List<BreachRecord>>? recordsByCui,
    this.source = 'memory',
  }) : _now = now ?? DateTime.now(),
       _recordsByCui = recordsByCui ?? fallbackSyntheticCuis;

  static const assetPath = 'assets/breach_catalog.json';
  static Future<LocalBreachCatalog>? _cachedDefaultCatalog;

  final DateTime _now;
  final Map<String, List<BreachRecord>> _recordsByCui;
  final String source;

  static final fallbackSyntheticCuis = {
    '1234567890101': [
      BreachRecord(
        slug: 'mintrab-tu-empleo-2026-04',
        name: 'Portal Tu Empleo Mintrab',
        exposedFields: ['CUI', 'nombre', 'telefono', 'correo'],
        reportedOn: DateTime.utc(2026, 4, 12),
      ),
    ],
    '2890123450101': [
      BreachRecord(
        slug: 'digecam-registro-2026-04',
        name: 'Registro publico Digecam',
        exposedFields: ['CUI', 'direccion', 'telefono'],
        reportedOn: DateTime.utc(2026, 4, 23),
      ),
    ],
  };

  static Future<LocalBreachCatalog> loadEmbedded({
    AssetBundle? bundle,
    DateTime? now,
  }) async {
    final data = await (bundle ?? rootBundle).loadString(assetPath);
    final decoded = jsonDecode(data) as Map<String, Object?>;
    final rawRecords = decoded['recordsByCui'] as Map<String, Object?>;

    return LocalBreachCatalog(
      now: now,
      source: 'asset:$assetPath',
      recordsByCui: rawRecords.map((cui, records) {
        final items = records as List<Object?>;
        return MapEntry(cui, items.map(_recordFromJson).toList());
      }),
    );
  }

  static Future<LocalBreachCatalog> loadEmbeddedOrFallback({
    AssetBundle? bundle,
    DateTime? now,
  }) async {
    if (bundle == null && now == null) {
      return _cachedDefaultCatalog ??= loadEmbeddedOrFallback(
        bundle: rootBundle,
      );
    }

    try {
      return await loadEmbedded(bundle: bundle, now: now);
    } catch (_) {
      return LocalBreachCatalog(
        now: now,
        source: 'fallback-memory-after-asset-error',
      );
    }
  }

  static BreachRecord _recordFromJson(Object? value) {
    final json = value as Map<String, Object?>;
    final fields = json['exposedFields'] as List<Object?>;
    return BreachRecord(
      slug: json['slug']! as String,
      name: json['name']! as String,
      exposedFields: fields.cast<String>(),
      reportedOn: DateTime.parse(json['reportedOn']! as String),
    );
  }

  VerificationResult verify(String rawCui) {
    final normalized = rawCui.replaceAll(RegExp(r'[^0-9]'), '');
    final matches = _recordsByCui[normalized] ?? const <BreachRecord>[];

    return VerificationResult(
      cui: normalized,
      matches: matches,
      checkedAt: _now,
      catalogSource: source,
    );
  }
}
