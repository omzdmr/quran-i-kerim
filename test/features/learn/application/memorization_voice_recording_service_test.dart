import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_voice_recording_service.dart';

void main() {
  group('memorization voice recording file names', () {
    test('uses stable zero-padded page file names', () {
      expect(memorizationVoiceRecordingFileName(1), 'page_001.m4a');
      expect(memorizationVoiceRecordingFileName(42), 'page_042.m4a');
      expect(memorizationVoiceRecordingFileName(604), 'page_604.m4a');
    });

    test('uses a hidden pending file beside the final recording', () {
      expect(
        memorizationVoiceRecordingPendingFileName(42),
        '.pending_page_042.m4a',
      );
    });

    test('rejects pages outside the 604-page Madinah layout', () {
      expect(() => memorizationVoiceRecordingFileName(0), throwsArgumentError);
      expect(() => memorizationVoiceRecordingFileName(605), throwsArgumentError);
    });
  });
}
