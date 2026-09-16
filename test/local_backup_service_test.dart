import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = LocalBackupService();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('exports a versioned UTC backup with explicit sections only', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'last_ayah': 255,
      'bookmarks': <String>['2:255'],
      'verse_notes': '{"2:255":"note"}',
      'theme_mode': 'dark',
      'audio_cache_internal': 'do not export',
    });

    final encoded = await service.exportJson(
      now: DateTime.parse('2026-09-16T18:00:00+08:00'),
    );
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;

    expect(decoded['version'], 1);
    expect(decoded['createdAt'], '2026-09-16T10:00:00.000Z');
    expect((data['reading'] as Map)['last_surah'], 2);
    expect((data['bookmarks'] as Map)['bookmarks'], ['2:255']);
    expect((data['notes'] as Map)['verse_notes'], isNotNull);
    expect((data['preferences'] as Map)['theme_mode'], 'dark');
    expect(encoded, isNot(contains('audio_cache_internal')));
  });

  test('restores a valid backup and keeps unrelated local preferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 9,
      'last_ayah': 1,
      'bookmarks': <String>['9:1'],
      'unrelated': 'keep me',
    });

    await service.restoreDecoded(<String, Object?>{
      'version': 1,
      'createdAt': '2026-09-16T10:00:00Z',
      'data': <String, Object?>{
        'reading': <String, Object?>{
          'last_surah': 36,
          'last_ayah': 58,
          'reading_days': <Object>['2026-09-16'],
        },
        'bookmarks': <String, Object?>{
          'bookmarks': <Object>['36:58'],
        },
        'preferences': <String, Object?>{'theme_mode': 'dark'},
      },
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 36);
    expect(prefs.getInt('last_ayah'), 58);
    expect(prefs.getStringList('bookmarks'), ['36:58']);
    expect(prefs.getString('theme_mode'), 'dark');
    expect(prefs.getString('unrelated'), 'keep me');
  });

  test('rolls back if a valid-looking backup fails while applying', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 9,
      'last_ayah': 4,
      'unrelated': 'keep me',
    });

    await expectLater(
      service.restoreDecoded(<String, Object?>{
        'version': 1,
        'createdAt': '2026-09-16T10:00:00Z',
        'data': <String, Object?>{
          'reading': <String, Object?>{
            'last_surah': 12,
            'last_ayah': <Object>[42],
          },
        },
      }),
      throwsFormatException,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 9);
    expect(prefs.getInt('last_ayah'), 4);
    expect(prefs.getString('unrelated'), 'keep me');
  });

  test('rejects unsupported version before mutating local data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'last_surah': 9});

    await expectLater(
      service.restoreDecoded(<String, Object?>{
        'version': 99,
        'createdAt': '2026-09-16T10:00:00Z',
        'data': <String, Object?>{},
      }),
      throwsFormatException,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 9);
  });
}
