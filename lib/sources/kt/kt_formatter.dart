part of 'kt_client.dart';

// Trimmed port of Forgetrack's kt_service_formatter.dart.

String _shortBody(String body, {int max = 300}) {
  final normalized =
      body.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.length <= max) return normalized;
  return '${normalized.substring(0, max)}...';
}

String _previewKeys(Iterable<Object?> keys, {int max = 12}) {
  final list = keys.map((key) => '$key').toList()..sort();
  if (list.isEmpty) return '<none>';
  if (list.length <= max) return list.join(', ');
  final shown = list.take(max).join(', ');
  return '$shown ... (+${list.length - max} more)';
}

String _describeValue(dynamic value) {
  if (value == null) return 'null';
  if (value is Map) return 'Map(keys=${_previewKeys(value.keys)})';
  if (value is List) return 'List(len=${value.length})';
  if (value is String) return '"${_shortBody(value, max: 80)}"';
  return '$value';
}

String _describeFields(Map<String, dynamic> data, List<String> keys) =>
    keys.map((key) => '$key=${_describeValue(data[key])}').join(', ');

/// KT diary date: `dd.MM.yyyy`, zero-padded (e.g. `05.03.2026`).
String _formatDiaryDate(LocalDate date) =>
    '${date.day.toString().padLeft(2, '0')}.'
    '${date.month.toString().padLeft(2, '0')}.'
    '${date.year.toString().padLeft(4, '0')}';
