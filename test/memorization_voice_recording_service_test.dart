import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/learn/application/memorization_voice_recording_service.dart';

void main() {
  test('recording file names are stable and page-scoped', () {
    expect(memorizationVoiceRecordingFileName(1), 'page_001.m4a');
    expect(memorizationVoiceRecordingFileName(42), 'page_042.m4a');
    expect(memorizationVoiceRecordingFileName(604), 'page_604.m4a');
  });

  test('pending recording never overwrites the last saved take directly', () {
    expect(
      memorizationVoiceRecordingPendingFileName(7),
      '.pending_page_007.m4a',
    );
    expect(
      memorizationVoiceRecordingPendingFileName(7),
      isNot(memorizationVoiceRecordingFileName(7)),
    );
  });

  test('invalid Mushaf pages are rejected before platform recording starts', () {
    expect(() => memorizationVoiceRecordingFileName(0), throwsArgumentError);
    expect(() => memorizationVoiceRecordingFileName(605), throwsArgumentError);
  });
}
