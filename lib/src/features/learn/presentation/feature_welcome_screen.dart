import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable first-entry welcome surface for Learn and Memorize.
///
/// The shell is intentionally content-agnostic. Product copy and persistence
/// live in the caller so this visual can be reused without embedding religious
/// text or account requirements into presentation code.
class FeatureWelcomeScreen extends StatelessWidget {
  const FeatureWelcomeScreen({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.icon,
    super.key,
    this.secondaryLabel,
    this.onSecondary,
    this.eyebrow,
    this.accent = const Color(0xFF14B878),
  });

  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final IconData icon;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? eyebrow;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF174C3D),
              Color(0xFF214538),
              Color(0xFF4B3B62),
            ],
            stops: [0, .52, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
            child: Column(
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .8,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
                const Spacer(flex: 2),
                _RosetteMark(icon: icon, accent: accent),
                const Spacer(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15.5,
                      height: 1.5,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onPrimary();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          primaryLabel,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(width: 7),
                        Icon(
                          textDirection == TextDirection.rtl
                              ? Icons.arrow_back_rounded
                              : Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onSecondary!();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: Text(
                        secondaryLabel!,
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

class _RosetteMark extends StatelessWidget {
  const _RosetteMark({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 214,
      height: 214,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 142,
              height: 142,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                color: accent.withValues(alpha: .22),
                border: Border.all(
                  color: accent.withValues(alpha: .75),
                  width: 2,
                ),
              ),
            ),
          ),
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(42),
              color: const Color(0xFF0C654A).withValues(alpha: .78),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .18),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .1),
                ),
                child: Icon(icon, color: Colors.white, size: 42),
              ),
            ),
          ),
          Positioned(
            top: 24,
            right: 36,
            child: _Sparkle(color: accent),
          ),
          Positioned(
            bottom: 34,
            left: 31,
            child: _Sparkle(color: Colors.white70, small: true),
          ),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.color, this.small = false});

  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 9.0 : 13.0;
    return Icon(Icons.auto_awesome_rounded, size: size, color: color);
  }
}
