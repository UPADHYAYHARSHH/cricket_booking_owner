import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'slottix_splash.dart' show SplashSound;

/// Clean, white launch screen for the owner app.
///
/// Sequence (seconds after the native splash hands over):
///  0.00  plain white (same as the native launch screen)
///  0.20  app icon tile pops in with a small overshoot
///  0.70  "Slottix" rises in
///  1.00  "Manage bookings." appears word by word
///  1.40  "Grow your turf." appears word by word (brand green)
///  0.00-2.40  thin green progress line fills along the bottom
///  Sound: the chosen [SplashSound] starts together with the animation,
///  exactly like the previous splash.
///
/// [onReady] runs your start-up work; the screen is shown for at least
/// [minDuration], then [onDone] is called.
class OwnerMinimalSplash extends StatefulWidget {
  const OwnerMinimalSplash({
    super.key,
    required this.onReady,
    required this.onDone,
    this.sound = SplashSound.classicCourt,
    this.minDuration = const Duration(milliseconds: 3000),
  });

  final Future<void> Function() onReady;
  final VoidCallback onDone;
  final SplashSound sound;
  final Duration minDuration;

  /// Must equal the flutter_native_splash `color` so the hand-over is seamless.
  static const background = Color(0xFFFFFFFF);

  @override
  State<OwnerMinimalSplash> createState() => _OwnerMinimalSplashState();
}

class _OwnerMinimalSplashState extends State<OwnerMinimalSplash>
    with SingleTickerProviderStateMixin {
  static const double _total = 2.4; // seconds of choreography
  static const double _tileSize = 120; // dp

  static const _green = Color(0xFF15803D);
  static const _title = Color(0xFF0B3D1E);
  static const _subtitle = Color(0xFF587864);

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_total * 1000).round()),
  );

  bool _started = false;
  AudioPlayer? _player;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    precacheImage(const AssetImage('assets/splash/logo_tile.png'), context);
    if (MediaQuery.of(context).disableAnimations) {
      _ctrl.value = 1; // accessibility: show the final state
    } else {
      _ctrl.forward();
      _playSound(); // no sound when animations are turned off
    }
    _run();
  }

  /// Same sound behaviour as before: "ambient" on iOS (follows the silent
  /// switch, never interrupts the user's music), no audio focus on Android.
  /// Any audio error is swallowed so it can never block app start.
  Future<void> _playSound() async {
    final asset = widget.sound.asset;
    if (asset == null) return;
    try {
      final player = AudioPlayer();
      _player = player;
      await player.setAudioContext(AudioContext(
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        android: const AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.none,
        ),
      ));
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> _run() async {
    await Future.wait<void>([
      widget.onReady(),
      Future<void>.delayed(widget.minDuration),
    ]);
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _player?.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  /// Progress (0..1) of a segment that runs from [a] to [b] seconds.
  double _seg(double a, double b, [Curve curve = Curves.easeOutCubic]) {
    final t = ((_ctrl.value * _total - a) / (b - a)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  Widget _rise(double p, Widget child, {double dy = 10}) => Opacity(
        opacity: p,
        child: Transform.translate(offset: Offset(0, (1 - p) * dy), child: child),
      );

  @override
  Widget build(BuildContext context) {
    final wordStyle = GoogleFonts.poppins(
      fontSize: 14,
      letterSpacing: 0.3,
      color: _subtitle,
    );
    final accentStyle = wordStyle.copyWith(
      color: _green,
      fontWeight: FontWeight.w600,
    );

    return Semantics(
      label: 'Slottix Owner. Manage bookings. Grow your turf.',
      child: Scaffold(
        backgroundColor: OwnerMinimalSplash.background,
        body: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final tileIn = _seg(0.20, 0.80, Curves.easeOutBack);
            final tileFade = _seg(0.20, 0.45);
            final title = _seg(0.70, 1.10);
            final bar = _seg(0.0, _total, Curves.easeInOut);

            Widget word(String text, double start, TextStyle style) => _rise(
                  _seg(start, start + 0.35),
                  Text(text, style: style),
                  dy: 8,
                );

            return LayoutBuilder(builder: (context, box) {
              final cy = box.maxHeight / 2;
              return Stack(
                children: [
                  // App icon tile pops in at the exact screen centre.
                  Center(
                    child: Opacity(
                      opacity: tileFade,
                      child: Transform.scale(
                        scale: 0.3 + 0.7 * tileIn,
                        child: Container(
                          width: _tileSize,
                          height: _tileSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(_tileSize * 0.24),
                            boxShadow: [
                              BoxShadow(
                                color: _title.withValues(alpha: 0.18 * tileFade),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(_tileSize * 0.24),
                            child: Image.asset(
                              'assets/splash/logo_tile.png',
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Wordmark + two-line tagline below the tile.
                  Positioned(
                    left: 24,
                    right: 24,
                    top: cy + _tileSize / 2 + 26,
                    child: Column(
                      children: [
                        _rise(
                          title,
                          Text(
                            'Slottix',
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: _title,
                            ),
                          ),
                          dy: 18,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 5,
                          children: [
                            word('Manage', 1.00, wordStyle),
                            word('bookings.', 1.12, wordStyle),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 5,
                          children: [
                            word('Grow', 1.40, accentStyle),
                            word('your', 1.52, accentStyle),
                            word('turf.', 1.64, accentStyle),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Thin progress line along the bottom edge.
                  Positioned(
                    left: 0,
                    bottom: 0,
                    height: 4,
                    width: box.maxWidth * bar,
                    child: const ColoredBox(color: _green),
                  ),
                ],
              );
            });
          },
        ),
      ),
    );
  }
}
