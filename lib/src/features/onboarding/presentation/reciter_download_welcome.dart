import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Optional reciter/download step inspired by the supplied onboarding
/// reference. The widget owns presentation only; catalogue identity, download
/// size and offline behavior are supplied by the caller.
class ReciterDownloadWelcome extends StatelessWidget {
  const ReciterDownloadWelcome({
    required this.title,
    required this.reciterName,
    required this.languageLabel,
    required this.body,
    required this.downloadLabel,
    required this.onDownload,
    super.key,
    this.avatar,
    this.downloadMeta,
    this.laterLabel,
    this.onLater,
  });

  final String title;
  final String reciterName;
  final String languageLabel;
  final String body;
  final String downloadLabel;
  final VoidCallback onDownload;
  final ImageProvider? avatar;
  final String? downloadMeta;
  final String? laterLabel;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF497D63),
              Color(0xFF496D5D),
              Color(0xFF5A456B),
            ],
            stops: [0, .48, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                  ),
                ),
                const Spacer(),
                _ReciterAvatar(avatar: avatar),
                const SizedBox(height: 20),
                Text(
                  reciterName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    languageLabel,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
                if (downloadMeta != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    downloadMeta!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onDownload();
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: Text(
                      downloadLabel,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0CB875),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                if (laterLabel != null && onLater != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onLater!();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: Text(
                        laterLabel!,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReciterAvatar extends StatelessWidget {
  const _ReciterAvatar({this.avatar});

  final ImageProvider? avatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 116,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .12),
        border: Border.all(color: Colors.white54, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipOval(
        child: avatar == null
            ? ColoredBox(
                color: const Color(0xFF254D40),
                child: const Center(
                  child: Icon(
                    Icons.record_voice_over_rounded,
                    size: 48,
                    color: Colors.white70,
                  ),
                ),
              )
            : Image(image: avatar!, fit: BoxFit.cover),
      ),
    );
  }
}
