part of 'kt_client.dart';

// Trimmed port of Forgetrack's _KtNutritionParser (summary part only).
// Difference: values are looked up by nutrient `code` and stay null when the
// code is absent — Forgetrack collapsed absent codes to 0.
class _KtSummaryParser {
  const _KtSummaryParser();

  static const _kjPerKcal = 4.184;

  KtDayNutrition parse(Map<String, dynamic> data) {
    final byCode = _parseSummaryByCode(data);

    double? kcal;
    if (data.containsKey('foodstuffEnergyTotal')) {
      final v = _parseDouble(data['foodstuffEnergyTotal']);
      if (v != null && v != 0) kcal = v;
    }
    kcal ??= byCode['total'];

    // The coach sheet wants kcal. If the account reports energy in kJ,
    // convert (plan §17 risk: KT energy unit).
    final unit = data['energyUnit']?.toString().toLowerCase();
    if (kcal != null && unit != null && unit.contains('kj')) {
      AppLog.ktParse.warn('KT energyUnit=$unit — converting kJ to kcal');
      kcal = kcal / _kjPerKcal;
    }

    final parsed = KtDayNutrition(
      kcal: kcal,
      protein: byCode['protein'],
      carbs: byCode['carbohydrate'],
      fat: byCode['fat'],
      fiber: byCode['fiber'],
    );
    AppLog.ktParse.debug(
      'summary → $parsed',
      payload: _describeFields(data, [
        'foodstuffEnergyTotal',
        'energyUnit',
        'items',
        'itemsDynamic',
      ]),
    );
    return parsed;
  }

  /// Walks `items` + `itemsDynamic` (nested lists flattened) keyed by `code`.
  /// When a code appears twice, a non-zero value wins over a zero one.
  /// Entries whose value can't be parsed are skipped (→ null downstream).
  Map<String, double> _parseSummaryByCode(Map<String, dynamic> data) {
    final out = <String, double>{};

    void add(dynamic rawEntry) {
      if (rawEntry is! Map) return;
      final code = rawEntry['code']?.toString();
      if (code == null || code.isEmpty) return;

      final value = _parseMetricValue(rawEntry);
      if (value == null) return;
      final existing = out[code];
      if (existing == null || existing == 0 || value != 0) {
        out[code] = value;
      }
    }

    void addAll(dynamic rawEntries) {
      if (rawEntries is! List) return;
      for (final entry in rawEntries) {
        if (entry is List) {
          addAll(entry);
        } else {
          add(entry);
        }
      }
    }

    addAll(data['items']);
    addAll(data['itemsDynamic']);
    return out;
  }

  /// `actualValue` (number) first, then the localized `actual` string
  /// ('26,6', '2 700'). A present 0 is a real zero.
  double? _parseMetricValue(Map rawEntry) {
    final actualValue = _parseDouble(rawEntry['actualValue']);
    final actual = _parseDouble(rawEntry['actual']);

    if (actualValue != null && actualValue != 0) return actualValue;
    if (actual != null && actual != 0) return actual;
    return actualValue ?? actual;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(_cleanNumString(value.toString()));
  }

  String _cleanNumString(String raw) => raw
      .replaceAll(' ', '')
      .replaceAll(' ', '')
      .replaceAll(' ', '')
      .replaceAll(',', '.');
}
