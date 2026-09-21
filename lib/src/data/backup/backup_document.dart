import 'dart:convert';

import 'package:crypto/crypto.dart';

class BackupDocument {
  const BackupDocument({
    required this.version,
    required this.createdAt,
    required this.data,
  });

  final int version;
  final DateTime createdAt;
  final Map<String, Object?> data;

  /// SHA-256 of the exact JSON representation stored in [data].
  ///
  /// This is an integrity check, not authentication or encryption. It lets an
  /// import reject truncated/corrupted portable bundles before touching local
  /// user data.
  String get dataSha256 => sha256.convert(utf8.encode(jsonEncode(data))).toString();

  Map<String, Object?> toJson() => <String, Object?>{
    'version': version,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'integrity': <String, Object?>{
      'algorithm': 'sha256',
      'dataSha256': dataSha256,
    },
    'data': data,
  };

  String encode() => jsonEncode(toJson());
}
