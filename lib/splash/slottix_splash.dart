import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';

/// Which app the splash is for. One widget, two skins.
enum SplashVariant { user, owner }

/// Splash sound effect. Files live in assets/sfx/.
enum SplashSound {
  none(null),
  classicCourt('sfx/classic_court.mp3'), // swoosh, thump, ref whistle, crowd, chime
  stadiumRoar('sfx/stadium_roar.mp3'), // boom, air horn, crowd roar
  racketShuttle('sfx/racket_shuttle.mp3'), // racket pock, shuttle swish, ding
  bassDrop('sfx/bass_drop.mp3'), // riser, bass drop, arpeggio
  subtlePop('sfx/subtle_pop.mp3'); // soft pop + chime (quietest)

  const SplashSound(this.asset);
  final String? asset;
}

class _Skin {
  const _Skin({
    required this.solid,
    required this.bgTop,
    required this.bgBottom,
    required this.glowOpacity,
    required this.title,
    required this.subtitle,
    required this.ripple,
    required this.arc1,
    required this.arc2,
    required this.shadow,
  });

  final Color solid; // must equal flutter_native_splash color
  final Color bgTop, bgBottom;
  final double glowOpacity;
  final Color title, subtitle;
  final Color ripple, arc1, arc2;
  final double shadow;

  static const user = _Skin(
    solid: Color(0xFF042B19),
    bgTop: Color(0xFF063D22),
    bgBottom: Color(0xFF021A10),
    glowOpacity: 0.30,
    title: Colors.white,
    subtitle: Color(0xFFA7D2B8),
    ripple: Color(0xFF4ADE80),
    arc1: Color(0xFFBEFF78),
    arc2: Color(0xFF22C55E),
    shadow: 0.40,
  );

  static const owner = _Skin(
    solid: Color(0xFFFFFFFF),
    bgTop: Color(0xFFFFFFFF),
    bgBottom: Color(0xFFF0FAF3),
    glowOpacity: 0.24,
    title: Color(0xFF0B3D1E),
    subtitle: Color(0xFF587864),
    ripple: Color(0xFF15803D),
    arc1: Color(0xFF15803D),
    arc2: Color(0xFF4ADE80),
    shadow: 0.18,
  );
}

double _c(double x) => x.clamp(0.0, 1.0).toDouble();
double _seg(double t, double a, double b) => _c((t - a) / (b - a));
double _eo(double t, [double p = 2.5]) => 1 - math.pow(1 - _c(t), p).toDouble();
double _eb(double t, [double s = 1.9]) {
  final x = _c(t) - 1;
  return x * x * ((s + 1) * x + s) + 1;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Animated launch screen shown after the native splash.
///
/// Sequence (seconds after the native splash hands over):
///  0.00  tennis ball (same as native splash icon) squashes, jumps, drops
///  0.95  impact -> ripples + sparks + glow burst
///  1.05  ball morphs into the app icon tile
///  1.30  two arcs orbit the tile
///  1.55  "Slottix" letters rise one by one (OWNER stamp / tagline follow)
///  Sound: sound effect starts together with the ball jump (see SplashSound).
///
/// [onReady] runs your start-up work; the screen is shown for at least
/// [minDuration], then [onDone] is called.
class SlottixSplash extends StatefulWidget {
  const SlottixSplash({
    super.key,
    required this.variant,
    required this.onReady,
    required this.onDone,
    this.sound = SplashSound.classicCourt,
    this.minDuration = const Duration(milliseconds: 2800),
  });

  final SplashVariant variant;
  final Future<void> Function() onReady;
  final VoidCallback onDone;
  final SplashSound sound;
  final Duration minDuration;

  @override
  State<SlottixSplash> createState() => _SlottixSplashState();
}

class _SlottixSplashState extends State<SlottixSplash>
    with SingleTickerProviderStateMixin {
  static const _total = 3.4; // seconds of choreography

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_total * 1000).round()),
  );

  bool _started = false;
  ui.Image? _tileImage;
  AudioPlayer? _player;

  @override
  void initState() {
    super.initState();
    _loadTile();
  }

  Future<void> _loadTile() async {
    final data = await rootBundle.load('assets/splash/logo_tile.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _tileImage = frame.image);
  }

  _Skin get _skin =>
      widget.variant == SplashVariant.user ? _Skin.user : _Skin.owner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _ctrl.value = 1; // accessibility: show the final state
    } else {
      _ctrl.forward();
      _playSound(); // no sound when animations are turned off
    }
    _run();
  }

  /// Plays the splash sound. It is "ambient" on iOS (follows the silent
  /// switch, never interrupts the user's music) and takes no audio focus on
  /// Android. Any audio error is swallowed so it can never block app start.
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

  @override
  Widget build(BuildContext context) {
    final skin = _skin;
    return Semantics(
      label: widget.variant == SplashVariant.owner ? 'Slottix Owner' : 'Slottix',
      child: Scaffold(
        backgroundColor: skin.solid,
        body: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _SplashPainter(
                  f: _ctrl.value * _total,
                  skin: skin,
                  owner: widget.variant == SplashVariant.owner,
                  tile: _tileImage,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

}

class _SplashPainter extends CustomPainter {
  _SplashPainter({
    required this.f,
    required this.skin,
    required this.owner,
    required this.tile,
  });

  final double f;
  final _Skin skin;
  final bool owner;
  final ui.Image? tile;

  static const double _ballR = 65; // 130dp ball == native splash icon
  static const double _tileS = 135;
  static const double _jump = 200; // dp

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rect = Offset.zero & size;

    // Background: solid (matches native) -> gradient.
    final bgm = _eo(_seg(f, 0, 0.2));
    canvas.drawRect(rect, Paint()..color = skin.solid);
    if (bgm > 0) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              skin.bgTop.withValues(alpha: bgm),
              skin.bgBottom.withValues(alpha: bgm),
            ],
          ).createShader(rect),
      );
    }

    // Glow burst behind the logo.
    final flash = math.max(0.0, 1 - _seg(f, 0.95, 1.35)) * 0.55;
    final g = _eo(_seg(f, 0.95, 2.0)) + flash;
    if (g > 0) {
      final o = (skin.glowOpacity * math.min(g, 1.6)).clamp(0.0, 0.9);
      canvas.drawCircle(
        Offset(cx, cy),
        190,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF4ADE80).withValues(alpha: o),
            const Color(0xFF4ADE80).withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 190)),
      );
    }

    // Ball state.
    final b = _ballState(f);
    final groundY = cy + _ballR;

    // Ground shadow.
    final s = 1 - math.min(b.h / _jump, 1);
    final sa = skin.shadow *
        (0.25 + 0.75 * s) *
        _eo(_seg(f, 0, 0.2)) *
        (1 - _seg(f, 1.1, 1.5));
    if (sa > 0.01) {
      final sw = _ballR * (0.55 + 0.55 * s);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, groundY + 7),
            width: sw * 2,
            height: 12 * (0.6 + 0.4 * s)),
        Paint()
          ..color = Colors.black.withValues(alpha: sa)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // Ball.
    final ballA = 1 - _eo(_seg(f, 1.05, 1.40));
    if (ballA > 0.01) {
      final w = _ballR * 2 * b.sx;
      final h = _ballR * 2 * b.sy;
      final bottom = groundY - b.h;
      _paintBall(
        canvas,
        Rect.fromLTWH(cx - w / 2, bottom - h, w, h),
        ballA,
      );
    }

    // Tile morph (ball -> app icon).
    final ta = _eo(_seg(f, 1.05, 1.40));
    final img = tile;
    if (ta > 0.01 && img != null) {
      final sc = 0.86 + 0.14 * _eb(_seg(f, 1.05, 1.6), 2.2);
      final n = _tileS * sc;
      final rad = _lerp(n / 2, n * 0.25, _eo(_seg(f, 1.05, 1.5), 2));
      final r = Rect.fromCenter(center: Offset(cx, cy), width: n, height: n);
      final rr = RRect.fromRectAndRadius(r, Radius.circular(rad));
      canvas.drawRRect(
        rr.shift(const Offset(0, 11)),
        Paint()
          ..color = Colors.black.withValues(alpha: skin.shadow * ta)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13),
      );
      canvas.save();
      canvas.clipRRect(rr);
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        r,
        Paint()
          ..filterQuality = FilterQuality.high
          ..color = Colors.white.withValues(alpha: ta),
      );
      canvas.restore();
    }

    // Ripples on the ground.
    for (final delay in [0.0, 0.14, 0.28]) {
      final p = _seg(f, 0.95 + delay, 1.75 + delay);
      if (p > 0 && p < 1) {
        final rad = 200 * _eo(p, 2);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, groundY),
              width: rad * 2,
              height: rad * 0.64),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1 + 3 * (1 - p)
            ..color = skin.ripple.withValues(alpha: 0.55 * (1 - p)),
        );
      }
    }

    // Sparks.
    final sp = _seg(f, 0.97, 1.55);
    if (sp > 0 && sp < 1) {
      for (var i = 0; i < 12; i++) {
        final ang = (-172 + i * (164 / 11)) * math.pi / 180;
        final dist = 115 * _eo(sp, 2.2) * (0.75 + 0.25 * ((i * 37) % 5) / 4);
        final pos = Offset(cx + math.cos(ang) * dist, groundY + math.sin(ang) * dist);
        final col = i.isEven
            ? const Color(0xFFBEF23C)
            : (owner ? const Color(0xFF15803D) : Colors.white);
        canvas.drawCircle(
            pos, math.max(1.0, 4.5 * (1 - sp)), Paint()..color = col.withValues(alpha: 1 - sp));
      }
    }

    // Orbit arcs.
    final ap = _seg(f, 1.30, 2.25);
    if (ap > 0 && ap < 1) {
      final head = -130 + 430 * _eo(ap, 2.2);
      final fade = 1 - _seg(ap, 0.72, 1.0);
      _orbit(canvas, Offset(cx, cy), 105, 1, head, 120, skin.arc1, fade);
      _orbit(canvas, Offset(cx, cy), 117, -1, head, 90, skin.arc2, fade);
    }

    // Wordmark letters.
    const word = 'Slottix';
    final top = cy + _tileS / 2 + 32;
    final style = GoogleFonts.poppins(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: skin.title,
    );
    final painters = [
      for (final ch in word.split(''))
        TextPainter(
            text: TextSpan(text: ch, style: style),
            textDirection: TextDirection.ltr)
          ..layout()
    ];
    final totalW = painters.fold<double>(0, (a, p) => a + p.width);
    var x = cx - totalW / 2;
    for (var i = 0; i < painters.length; i++) {
      final p = _seg(f, 1.55 + 0.065 * i, 1.95 + 0.065 * i);
      if (p > 0) {
        final off = (1 - _eo(p, 3)) * 23;
        canvas.saveLayer(
          Rect.fromLTWH(x - 4, top + off - 4, painters[i].width + 8, 60),
          Paint()..color = Colors.white.withValues(alpha: _eo(p)),
        );
        painters[i].paint(canvas, Offset(x, top + off));
        canvas.restore();
      }
      x += painters[i].width;
    }

    // Tagline / OWNER stamp.
    final tagY = top + 56;
    if (!owner) {
      _tag(canvas, cx, tagY, 'Book your game', _eo(_seg(f, 2.05, 2.55)));
    } else {
      final p = _seg(f, 2.0, 2.5);
      const pw = 82.0, ph = 24.0;
      if (p > 0) {
        final k = 1.35 - 0.35 * _eb(p, 2.2);
        canvas.save();
        canvas.translate(cx, tagY + ph / 2);
        canvas.scale(k);
        final pill = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: pw, height: ph),
            const Radius.circular(12));
        canvas.drawRRect(
            pill, Paint()..color = const Color(0xFF15803D).withValues(alpha: _c(p * 3)));
        final tp = TextPainter(
          text: TextSpan(
            text: 'OWNER',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: Colors.white.withValues(alpha: _c(p * 3)),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(-tp.width / 2 + 1.5, -tp.height / 2));
        canvas.restore();
      }
      _tag(canvas, cx, tagY + ph + 14, 'Run your venue, effortlessly',
          _eo(_seg(f, 2.4, 2.9)));
    }
  }

  void _tag(Canvas canvas, double cx, double y, String text, double a) {
    if (a <= 0) return;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          letterSpacing: 0.4,
          color: skin.subtitle.withValues(alpha: a),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, y + (1 - a) * 7));
  }

  void _orbit(Canvas canvas, Offset c, double radius, int flip, double head,
      double tail, Color col, double fade) {
    const segs = 36;
    for (var j = 0; j < segs; j++) {
      final frac = j / segs;
      double ang(double fr) =>
          (flip * (head - tail * (1 - fr))) * math.pi / 180 +
          (flip < 0 ? math.pi : 0);
      final a1 = ang(frac), a2 = ang((j + 1) / segs);
      canvas.drawLine(
        c + Offset(math.cos(a1), math.sin(a1)) * radius,
        c + Offset(math.cos(a2), math.sin(a2)) * radius,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.3 + 4.7 * frac
          ..color = col.withValues(alpha: 0.9 * frac * fade),
      );
    }
  }

  void _paintBall(Canvas canvas, Rect r, double a) {
    final c = r.center;
    final rad = r.width / 2;
    canvas.save();
    canvas.clipPath(Path()..addOval(r));
    canvas.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.40),
          radius: 1.35,
          colors: [
            const Color(0xFFE4FF7A).withValues(alpha: a),
            const Color(0xFFBEF328).withValues(alpha: a),
            const Color(0xFF78BE0F).withValues(alpha: a),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(r),
    );
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rad * 0.09
      ..color = Colors.white.withValues(alpha: 0.92 * a);
    canvas.drawCircle(Offset(c.dx - rad * 1.3, c.dy - rad * 0.05), rad * 1.1, seam);
    canvas.drawCircle(Offset(c.dx + rad * 1.3, c.dy + rad * 0.05), rad * 1.1, seam);
    canvas.restore();
  }

  ({double h, double sx, double sy}) _ballState(double f) {
    if (f < 0.18) {
      final p = f / 0.18;
      return (h: 0, sx: 1 + 0.08 * p, sy: 1 - 0.12 * p);
    }
    if (f < 0.55) {
      final p = (f - 0.18) / 0.37;
      final sy = p < 0.25
          ? _lerp(0.88, 1.10, _eo(p / 0.25, 2))
          : 1.10 - 0.10 * ((p - 0.25) / 0.75);
      return (h: _jump * _eo(p, 2), sx: 1 / math.sqrt(sy), sy: sy);
    }
    if (f < 0.95) {
      final p = (f - 0.55) / 0.40;
      final sy = 1 + 0.08 * p;
      return (h: _jump * (1 - p * p), sx: 1 / math.sqrt(sy), sy: sy);
    }
    if (f < 1.12) {
      final p = (f - 0.95) / 0.17;
      final sy = 1 - 0.22 * math.sin(math.pi * p);
      return (h: 0, sx: 1 / math.sqrt(sy), sy: sy);
    }
    return (h: 0, sx: 1, sy: 1);
  }

  @override
  bool shouldRepaint(covariant _SplashPainter old) =>
      old.f != f || old.tile != tile;
}
