import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/reader/resumable_file_download.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('quran-resume-test-');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('resumes an existing partial file with HTTP Range', () async {
    final payload = List<int>.generate(2048, (index) => index % 251);
    final target = File('${tempDirectory.path}/verse.mp3');
    final part = File('${target.path}.part');
    await part.writeAsBytes(payload.sublist(0, 512));

    String? receivedRange;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      receivedRange = request.headers.value(HttpHeaders.rangeHeader);
      request.response
        ..statusCode = HttpStatus.partialContent
        ..headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes 512-${payload.length - 1}/${payload.length}',
        )
        ..contentLength = payload.length - 512
        ..add(payload.sublist(512));
      await request.response.close();
    });

    final result = await downloadResumableFile(
      target: target,
      uri: Uri.parse('http://127.0.0.1:${server.port}/verse.mp3'),
    );

    expect(result, ResumableDownloadResult.completed);
    expect(receivedRange, 'bytes=512-');
    expect(await target.readAsBytes(), payload);
    expect(await part.exists(), isFalse);
  });

  test('restarts safely when the server ignores Range', () async {
    final payload = List<int>.generate(1024, (index) => (index * 3) % 251);
    final target = File('${tempDirectory.path}/verse.mp3');
    final part = File('${target.path}.part');
    await part.writeAsBytes(payload.sublist(0, 300));

    String? receivedRange;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      receivedRange = request.headers.value(HttpHeaders.rangeHeader);
      request.response
        ..statusCode = HttpStatus.ok
        ..contentLength = payload.length
        ..add(payload);
      await request.response.close();
    });

    final result = await downloadResumableFile(
      target: target,
      uri: Uri.parse('http://127.0.0.1:${server.port}/verse.mp3'),
    );

    expect(result, ResumableDownloadResult.completed);
    expect(receivedRange, 'bytes=300-');
    expect(await target.readAsBytes(), payload);
  });

  test('interruption preserves partial bytes for a later resume', () async {
    final payload = List<int>.generate(1500, (index) => (index * 7) % 251);
    final target = File('${tempDirectory.path}/verse.mp3');
    final part = File('${target.path}.part');
    await part.writeAsBytes(payload.sublist(0, 400));

    final interrupted = await downloadResumableFile(
      target: target,
      uri: Uri.parse('http://127.0.0.1:1/not-used'),
      shouldInterrupt: () => true,
    );
    expect(interrupted, ResumableDownloadResult.interrupted);
    expect(await part.length(), 400);
    expect(await target.exists(), isFalse);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      expect(request.headers.value(HttpHeaders.rangeHeader), 'bytes=400-');
      request.response
        ..statusCode = HttpStatus.partialContent
        ..headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes 400-${payload.length - 1}/${payload.length}',
        )
        ..contentLength = payload.length - 400
        ..add(payload.sublist(400));
      await request.response.close();
    });

    final resumed = await downloadResumableFile(
      target: target,
      uri: Uri.parse('http://127.0.0.1:${server.port}/verse.mp3'),
    );
    expect(resumed, ResumableDownloadResult.completed);
    expect(await target.readAsBytes(), payload);
  });

  test('promotes a complete partial file after a 416 response', () async {
    final payload = List<int>.generate(900, (index) => index % 239);
    final target = File('${tempDirectory.path}/verse.mp3');
    final part = File('${target.path}.part');
    await part.writeAsBytes(payload);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      expect(
        request.headers.value(HttpHeaders.rangeHeader),
        'bytes=${payload.length}-',
      );
      request.response
        ..statusCode = HttpStatus.requestedRangeNotSatisfiable
        ..headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes */${payload.length}',
        );
      await request.response.close();
    });

    final result = await downloadResumableFile(
      target: target,
      uri: Uri.parse('http://127.0.0.1:${server.port}/verse.mp3'),
    );

    expect(result, ResumableDownloadResult.completed);
    expect(await target.readAsBytes(), payload);
    expect(await part.exists(), isFalse);
  });
}
