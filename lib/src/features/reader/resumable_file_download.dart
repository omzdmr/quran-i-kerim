import 'dart:async';
import 'dart:io';

enum ResumableDownloadResult { completed, interrupted }

typedef DownloadInterruptCheck = bool Function();

/// Downloads [uri] to [target] through a sibling `.part` file.
///
/// Existing partial bytes are resumed with an HTTP Range request when the
/// server supports it. If the server ignores Range and replies with 200, the
/// partial file is safely truncated and the response is written from byte 0.
/// Partial bytes are intentionally kept after interruption or transient
/// failure so a later attempt can continue instead of starting over.
Future<ResumableDownloadResult> downloadResumableFile({
  required File target,
  required Uri uri,
  DownloadInterruptCheck? shouldInterrupt,
  int maxAttempts = 3,
}) async {
  if (maxAttempts < 1) {
    throw ArgumentError.value(maxAttempts, 'maxAttempts', 'must be at least 1');
  }
  if (await target.exists() && await target.length() > 0) {
    return ResumableDownloadResult.completed;
  }

  final part = File('${target.path}.part');
  await part.parent.create(recursive: true);
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15)
    ..idleTimeout = const Duration(seconds: 20);

  try {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (shouldInterrupt?.call() ?? false) {
        return ResumableDownloadResult.interrupted;
      }

      final offset = await part.exists() ? await part.length() : 0;
      try {
        final request = await client.getUrl(uri);
        request.headers.set(HttpHeaders.acceptHeader, 'audio/mpeg,*/*;q=0.8');
        request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
        if (offset > 0) {
          request.headers.set(HttpHeaders.rangeHeader, 'bytes=$offset-');
        }

        final response = await request.close();
        if (_isRetryableStatus(response.statusCode)) {
          await response.drain<void>();
          throw _RetryableDownloadException(
            'Server returned ${response.statusCode}',
          );
        }

        if (response.statusCode == HttpStatus.requestedRangeNotSatisfiable &&
            offset > 0) {
          final total = _unsatisfiedRangeTotal(
            response.headers.value(HttpHeaders.contentRangeHeader),
          );
          await response.drain<void>();
          if (total != null && total == offset) {
            await _promotePart(part, target);
            return ResumableDownloadResult.completed;
          }
          if (await part.exists()) await part.delete();
          if (attempt + 1 < maxAttempts) continue;
          throw HttpException(
            'Server rejected the saved partial range',
            uri: uri,
          );
        }

        if (response.statusCode != HttpStatus.ok &&
            response.statusCode != HttpStatus.partialContent) {
          await response.drain<void>();
          throw _PermanentDownloadException(
            HttpException(
              'Download failed with ${response.statusCode}',
              uri: uri,
            ),
          );
        }

        var append = false;
        int? expectedTotal;
        if (response.statusCode == HttpStatus.partialContent) {
          final range = _parseContentRange(
            response.headers.value(HttpHeaders.contentRangeHeader),
          );
          if (range == null || range.start != offset) {
            await response.drain<void>();
            if (await part.exists()) await part.delete();
            if (attempt + 1 < maxAttempts) continue;
            throw HttpException(
              'Server returned an invalid Content-Range',
              uri: uri,
            );
          }
          append = offset > 0;
          expectedTotal = range.total;
        } else if (response.contentLength >= 0) {
          expectedTotal = response.contentLength;
        }

        final sink = part.openWrite(
          mode: append ? FileMode.append : FileMode.write,
        );
        var interrupted = false;
        try {
          await for (final chunk in response) {
            if (shouldInterrupt?.call() ?? false) {
              interrupted = true;
              break;
            }
            sink.add(chunk);
            if (shouldInterrupt?.call() ?? false) {
              interrupted = true;
              break;
            }
          }
          await sink.flush();
        } finally {
          await sink.close();
        }

        if (interrupted || (shouldInterrupt?.call() ?? false)) {
          return ResumableDownloadResult.interrupted;
        }

        final finalLength = await part.length();
        if (finalLength <= 0) {
          throw const FileSystemException('Downloaded file is empty');
        }
        if (expectedTotal != null && finalLength != expectedTotal) {
          throw _RetryableDownloadException(
            'Incomplete response: expected $expectedTotal bytes, got $finalLength',
          );
        }

        await _promotePart(part, target);
        return ResumableDownloadResult.completed;
      } on _PermanentDownloadException catch (error) {
        throw error.cause;
      } catch (_) {
        if (attempt + 1 >= maxAttempts) rethrow;
        await Future<void>.delayed(Duration(seconds: 1 << attempt));
      }
    }

    throw StateError('Resumable download ended without a result');
  } finally {
    client.close(force: true);
  }
}

bool _isRetryableStatus(int statusCode) =>
    statusCode == HttpStatus.tooManyRequests || statusCode >= 500;

Future<void> _promotePart(File part, File target) async {
  if (!await part.exists() || await part.length() <= 0) {
    throw const FileSystemException('Partial download is empty');
  }
  if (await target.exists()) await target.delete();
  await part.rename(target.path);
}

_ContentRange? _parseContentRange(String? value) {
  if (value == null) return null;
  final match = RegExp(r'^bytes\s+(\d+)-(\d+)/(\d+|\*)$').firstMatch(value.trim());
  if (match == null) return null;
  final start = int.tryParse(match.group(1)!);
  final end = int.tryParse(match.group(2)!);
  final totalText = match.group(3)!;
  final total = totalText == '*' ? null : int.tryParse(totalText);
  if (start == null || end == null || end < start) return null;
  if (total != null && (total <= end || total <= 0)) return null;
  return _ContentRange(start: start, total: total);
}

int? _unsatisfiedRangeTotal(String? value) {
  if (value == null) return null;
  final match = RegExp(r'^bytes\s+\*/(\d+)$').firstMatch(value.trim());
  return match == null ? null : int.tryParse(match.group(1)!);
}

class _ContentRange {
  const _ContentRange({required this.start, this.total});

  final int start;
  final int? total;
}

class _RetryableDownloadException implements Exception {
  const _RetryableDownloadException(this.message);
  final String message;

  @override
  String toString() => message;
}

class _PermanentDownloadException implements Exception {
  const _PermanentDownloadException(this.cause);
  final Object cause;
}
