import 'dart:convert';

class BackupDocument {
  const BackupDocument({
    required this.version,
    required this.createdAt,
    required this.data,
  });

  final int version;
  final DateTime createdAt;
  final Map<String, Object?> data;

  Map<String, Object?> toJson() => <String, Object?>{
    'version': version,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'data': data,
  };

  String encode() => jsonEncode(toJson());
}
