// Component: AwesomeRotarySwitch
// Usage:
//   AwesomeRotarySwitch(
//     initialPosition: 0,          // 0 = OFF, 1–5 = speed levels
//     onChanged: (int pos) => print('Selected: $pos'),
//   )

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Constants ──────────────────────────────────────────────────────────────────

/// Angles (in radians) for each of the 6 dial positions.
/// Matches the CSS reference: positions span a 300° arc from 12 o'clock
/// clockwise, with a 60° gap on the right side (~3 o'clock).
const List<double> _kPositionAngles = <double>[
  -math.pi / 2,       // 0: OFF  (−90°, 12 o'clock)
  -math.pi / 6,       // 1       (−30°, ~1 o'clock)
   math.pi / 6,       // 2       ( 30°, ~5 o'clock)
   math.pi / 2,       // 3       ( 90°, 6 o'clock)
   5 * math.pi / 6,   // 4       (150°, ~7 o'clock)
   7 * math.pi / 6,   // 5       (210°, ~11 o'clock)
];

/// Radial divider lines at 0°, −60°, and +60°, matching the CSS hr.lines.
const List<double> _kDividerAngles = <double>[
  0.0,
  -math.pi / 3,
   math.pi / 3,
];

/// Default color per position: neutral gray → intensity ramp green → red.
const List<Color> _kDefaultPositionColors = <Color>[
  Color(0xFF7A7A8A), // 0: OFF   — neutral gray
  Color(0xFF4CAF50), // 1        — green
  Color(0xFF8BC34A), // 2        — lime
  Color(0xFFFF9800), // 3        — amber
  Color(0xFFFF5722), // 4        — deep-orange
  Color(0xFFF44336), // 5        — red
];

/// Default text labels for each dial position.
const List<String> _kDefaultPositionLabels = <String>[
  'OFF', '1', '2', '3', '4', '5',
];

// ── Widget ─────────────────────────────────────────────────────────────────────

/// A premium rotary dial switch with 6 positions (OFF + 1–5).
///
/// Enhanced over the HTML/CSS reference with:
/// • Drag-to-rotate gesture with live snapping and smooth easeOutCubic release
/// • Position-based color system (gray → green → lime → amber → orange → red)
/// • Metallic [_DialPainter] with specular highlight and beveled divider lines
/// • Vivid animated glow cone ([_GlowPainter]) adopting the active position color
/// • Center-knob tap animation (scale 0.93×) that resets the dial to OFF
/// • Active label scales up (1.2×) with easeOutBack and glows in position color
/// • Haptic feedback on every position snap
class AwesomeRotarySwitch extends StatefulWidget {
  const AwesomeRotarySwitch({
    super.key,
    this.initialPosition = 0,
    this.onChanged,
    this.size = 240.0,
    this.positionColors,
    this.positionLabels,
    this.enableHaptics = true,
    this.enableGlow = true,
    this.enableDrag = true,
  })  : assert(
          positionColors == null || positionColors.length == 6,
          'positionColors must contain exactly 6 colors',
        ),
        assert(
          positionLabels == null || positionLabels.length == 6,
          'positionLabels must contain exactly 6 labels',
        );

  /// Starting position. 0 = OFF, 1–5 = speed levels.
  final int initialPosition;

  /// Callback fired whenever the selected position changes.
  final ValueChanged<int>? onChanged;

  /// Diameter of the outer dial circle in logical pixels.
  final double size;

  /// Custom color for each of the 6 positions. Must have exactly 6 entries.
  final List<Color>? positionColors;

  /// Custom label for each of the 6 positions. Must have exactly 6 entries.
  final List<String>? positionLabels;

  /// Whether to trigger [HapticFeedback.selectionClick] on position change.
  final bool enableHaptics;

  /// Whether to render the animated glow-cone layer.
  final bool enableGlow;

  /// Whether pan/drag gestures rotate the needle.
  final bool enableDrag;

  @override
  State<AwesomeRotarySwitch> createState() => _AwesomeRotarySwitchState();
}

// ── State ──────────────────────────────────────────────────────────────────────

class _AwesomeRotarySwitchState extends State<AwesomeRotarySwitch>
    with TickerProviderStateMixin {

  // ── State variables ─────────────────────────────────────────────────────────

  late int _currentPosition;

  /// Visual angle of the needle in radians.
  /// Updated directly during drag and via the needle animation listener.
  late double _needleAngle;

  // ── Animation controllers ───────────────────────────────────────────────────

  /// Smoothly rotates the needle from its previous angle to the snap target.
  /// Duration: 350 ms · Curve: easeOutCubic.
  late final AnimationController _needleController;
  late Animation<double> _needleAnimation;

  /// Drives the center-knob scale-down (press) → spring-back (release).
  /// Forward: 120 ms · Reverse: 200 ms.
  late final AnimationController _pressController;

  /// Repeating opacity pulse (0.55 → 1.0) applied to the active glow cone.
  /// Period: 1600 ms · Reversing ease-in-out.
  late final AnimationController _glowController;

  /// One-shot scale pop for the active label when the position changes.
  /// Duration: 250 ms · Curve: easeOutBack.
  late final AnimationController _labelController;

  // ── Convenience getters ─────────────────────────────────────────────────────

  List<Color> get _colors => widget.positionColors ?? _kDefaultPositionColors;
  List<String> get _labels => widget.positionLabels ?? _kDefaultPositionLabels;
  Color get _activeColor => _colors[_currentPosition];

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
    _needleAngle = _kPositionAngles[_currentPosition];

    // Needle rotation ─────────────────────────────────────────────────────────
    _needleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _needleAnimation = Tween<double>(
      begin: _needleAngle,
      end: _needleAngle,
    ).animate(
      CurvedAnimation(parent: _needleController, curve: Curves.easeOutCubic),
    );
    // Mirror animation value into _needleAngle so build() reads one source.
    _needleController.addListener(() {
      setState(() => _needleAngle = _needleAnimation.value);
    });

    // Center-knob press effect ────────────────────────────────────────────────
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );

    // Glow pulse ──────────────────────────────────────────────────────────────
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // Label scale-pop ─────────────────────────────────────────────────────────
    _labelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..forward();
  }

  @override
  void dispose() {
    _needleController.dispose();
    _pressController.dispose();
    _glowController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  // ── Angle math ───────────────────────────────────────────────────────────────

  /// Converts an [Offset] relative to the dial centre into an angle in radians.
  double _angleFromOffset(Offset offset) => math.atan2(offset.dy, offset.dx);

  /// Returns the index of the position whose angle is closest to [angle].
  int _findNearestPosition(double angle) {
    int best = 0;
    double minDist = double.infinity;
    for (int i = 0; i < _kPositionAngles.length; i++) {
      // Shortest angular distance on the circle.
      double diff = (angle - _kPositionAngles[i]).abs() % (2 * math.pi);
      if (diff > math.pi) diff = 2 * math.pi - diff;
      if (diff < minDist) {
        minDist = diff;
        best = i;
      }
    }
    return best;
  }

  /// Returns true when [angle] falls in the 60° gap zone on the right side
  /// of the dial (~210° → ~270°) where no positions exist.
  bool _isInGapZone(double angle) {
    final double norm = (angle % (2 * math.pi) + 2 * math.pi) % (2 * math.pi);
    return norm > 7 * math.pi / 6 && norm < 3 * math.pi / 2;
  }

  // ── Gesture handling ─────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails details) {
    if (!widget.enableDrag) return;
    // Stop any ongoing snap animation so drag takes full control.
    _needleController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enableDrag) return;
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset center = Offset(box.size.width / 2, box.size.height / 2);
    final Offset fromCenter =
        box.globalToLocal(details.globalPosition) - center;

    // Ignore touches that stray well outside the dial boundary.
    if (fromCenter.distance > box.size.shortestSide * 0.6) return;

    final double rawAngle = _angleFromOffset(fromCenter);
    setState(() => _needleAngle = rawAngle);

    // Live-snap as the finger crosses into a new position sector.
    if (!_isInGapZone(rawAngle)) {
      final int nearest = _findNearestPosition(rawAngle);
      if (nearest != _currentPosition) {
        if (widget.enableHaptics) HapticFeedback.selectionClick();
        setState(() => _currentPosition = nearest);
        widget.onChanged?.call(nearest);
        _labelController
          ..reset()
          ..forward();
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enableDrag) return;
    _snapToPosition(_findNearestPosition(_needleAngle));
  }

  // ── Snap ─────────────────────────────────────────────────────────────────────

  /// Animates the needle to [newPosition], fires haptics and callbacks.
  void _snapToPosition(int newPosition) {
    final double targetAngle = _kPositionAngles[newPosition];

    if (newPosition != _currentPosition) {
      if (widget.enableHaptics) HapticFeedback.selectionClick();
      setState(() => _currentPosition = newPosition);
      widget.onChanged?.call(newPosition);
      _labelController
        ..reset()
        ..forward();
    }

    // Re-target the needle animation from the current visual angle.
    _needleAnimation = Tween<double>(
      begin: _needleAngle,
      end: targetAngle,
    ).animate(
      CurvedAnimation(parent: _needleController, curve: Curves.easeOutCubic),
    );
    _needleController
      ..reset()
      ..forward();
  }

  // ── Center-knob tap ───────────────────────────────────────────────────────────

  /// Tap the center knob → press-down bounce animation, then reset to OFF.
  void _onKnobTap() {
    _pressController.forward().then((_) {
      _pressController.reverse();
      _snapToPosition(0);
    });
  }

  // ── Build helpers ─────────────────────────────────────────────────────────────

  /// Builds the 6 position labels positioned radially around the dial.
  /// Active label gets an easeOutBack scale-pop and glows in its position color.
  List<Widget> _buildLabels(double s) {
    // Place label centres at ~82% of the metallic disc's radius,
    // matching the CSS reference where label arms span 50% of the 220px disc.
    final double labelRadius = s * 0.38;

    return List<Widget>.generate(6, (int i) {
      final double angle = _kPositionAngles[i];
      final double cx = s / 2 + math.cos(angle) * labelRadius;
      final double cy = s / 2 + math.sin(angle) * labelRadius;
      final bool isActive = i == _currentPosition;
      const double boxSize = 40.0;

      return Positioned(
        left: cx - boxSize / 2,
        top: cy - boxSize / 2,
        child: GestureDetector(
          onTap: () => _snapToPosition(i),
          // Scale-pop animation for the active label only.
          child: AnimatedBuilder(
            animation: _labelController,
            builder: (BuildContext ctx, Widget? child) {
              final double scale = isActive
                  ? Tween<double>(begin: 0.65, end: 1.0)
                      .chain(CurveTween(curve: Curves.easeOutBack))
                      .evaluate(_labelController)
                  : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: SizedBox(
              width: boxSize,
              height: boxSize,
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: isActive ? 14.0 : 11.0,
                    fontWeight: FontWeight.w800,
                    color: isActive
                        ? _colors[i]
                        : const Color(0xFFCCCCCC),
                    shadows: isActive
                        ? <Shadow>[
                            Shadow(
                              color: _colors[i].withAlpha(220),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isActive ? 1.0 : 0.38,
                    child: Text(_labels[i]),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Builds the glowing indicator dot that rotates at [_needleAngle].
  ///
  /// The dot orbits at a radius that places it on the surface of the inner
  /// knob — matching the CSS `.dot span` that rides the inner button face.
  /// It is placed last in the Stack so it renders above everything.
  Widget _buildNeedle(double s) {
    // Orbit radius: just inside the inner knob's outer edge.
    // CSS reference: dot is at ~36px from center on a 110px-radius disc.
    // Scaled: 36/110 * (s/2) ≈ s * 0.163.
    final double orbitRadius = s * 0.163;
    final double dx = math.cos(_needleAngle) * orbitRadius;
    final double dy = math.sin(_needleAngle) * orbitRadius;

    // Dot size scales slightly with the dial.
    final double dotSize = s * 0.052; // ~12.5px at size 240

    return Positioned(
      left: s / 2 + dx - dotSize / 2,
      top:  s / 2 + dy - dotSize / 2,
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Radial gradient: white specular highlight → position color.
          gradient: RadialGradient(
            colors: <Color>[
              Colors.white,
              _activeColor.withAlpha(220),
            ],
            stops: const <double>[0.0, 0.75],
          ),
          boxShadow: <BoxShadow>[
            // Outer color glow.
            BoxShadow(
              color: _activeColor.withAlpha(180),
              blurRadius: dotSize * 1.2,
              spreadRadius: dotSize * 0.2,
            ),
            // Soft white inner halo.
            const BoxShadow(
              color: Color(0x55FFFFFF),
              blurRadius: 3,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the nested metallic inner knob button.
  ///
  /// Three concentric circles with alternating gradient directions simulate
  /// the CSS bevel effect (.dene → .denem → .deneme).
  /// Tapping triggers [_onKnobTap] which scales the knob down then snaps to OFF.
  Widget _buildInnerKnob(double s) {
    // Scale the CSS px sizes (for a 240px dial) to the actual [size].
    final double outer  = s * 0.583; // 140 / 240
    final double middle = s * 0.500; // 120 / 240
    final double inner  = s * 0.417; // 100 / 240

    return AnimatedBuilder(
      animation: _pressController,
      builder: (BuildContext ctx, Widget? child) {
        // Press-controller maps 0→1 to scale 1.0→0.93.
        final double scale = 1.0 - _pressController.value * 0.07;
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: _onKnobTap,
        child: Container(
          width: outer,
          height: outer,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            // Outer bevel: light-top → dark-bottom (CSS .dene).
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFFF2F6F5), Color(0xFFCBD5D6)],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 13,
                offset: Offset(0, 3),
              ),
              // Inner highlight on top edge (inset bevel).
              BoxShadow(
                color: Color(0x66FFFFFF),
                blurRadius: 2,
                offset: Offset(0, -2),
                spreadRadius: -1,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: middle,
              height: middle,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                // Middle bevel: reversed gradient (CSS .denem).
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFFCBD5D6), Color(0xFFF2F6F5)],
                ),
              ),
              child: Center(
                child: Container(
                  width: inner,
                  height: inner,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    // Inner face: light-top → gray-bottom (CSS .deneme).
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Color(0xFFEEF7F6), Color(0xFF8D989A)],
                    ),
                    boxShadow: <BoxShadow>[
                      // Deep drop shadow for pronounced depth.
                      BoxShadow(
                        color: Color(0xE6000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                      // White inner highlight on top edge.
                      BoxShadow(
                        color: Color(0x99FFFFFF),
                        blurRadius: 3,
                        offset: Offset(0, -2),
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;

    return GestureDetector(
      onPanStart:  _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd:    _onPanEnd,
      child: SizedBox(
        width: s,
        height: s,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[

            // ── Layer 1: Metallic dial body + beveled divider lines ────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _DialPainter(size: s),
              ),
            ),

            // ── Layer 2: Animated glow cone (active positions only) ────────────
            if (widget.enableGlow && _currentPosition != 0)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (BuildContext ctx, Widget? child) {
                    return CustomPaint(
                      painter: _GlowPainter(
                        angle: _needleAngle,
                        color: _activeColor,
                        // Pulse: opacity oscillates between 0.55 and 1.0.
                        opacity: 0.55 + 0.45 * _glowController.value,
                        size: s,
                      ),
                    );
                  },
                ),
              ),

            // ── Layer 3: Position labels ──────────────────────────────────────
            ..._buildLabels(s),

            // ── Layer 4: Inner metallic knob (covers inner part of needle) ────
            Center(child: _buildInnerKnob(s)),

            // ── Layer 5: Indicator dot (on top of everything) ─────────────────
            _buildNeedle(s),
          ],
        ),
      ),
    );
  }
}

// ── _DialPainter ──────────────────────────────────────────────────────────────

/// Paints the metallic dial body with:
/// • Radial gradient from #888 (centre) to #333 (edge) — matches CSS
/// • Soft specular arc in the top-left quadrant simulating a light source
/// • Three beveled divider lines drawn as engraved ridges (dark groove +
///   offset light ridge — matching the CSS hr.line dual-border technique)
class _DialPainter extends CustomPainter {
  const _DialPainter({required this.size});
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final Offset center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final double r = size / 2;
    // The inner metallic disc is 220/240 = 91.7% of the full diameter.
    final double discR = r * 0.917;

    // ── Outer ambient shadow ──────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.black.withAlpha(25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
    );

    // ── Metallic body ─────────────────────────────────────────────────────────
    // CSS used a radial gradient from #888 at centre to #333 at edge.
    canvas.drawCircle(
      center,
      discR,
      Paint()
        ..shader = RadialGradient(
          colors: const <Color>[Color(0xFF888888), Color(0xFF2E2E2E)],
        ).createShader(Rect.fromCircle(center: center, radius: discR)),
    );

    // Inset shadow on the top of the disc edge (depth illusion).
    canvas.drawCircle(
      center,
      discR,
      Paint()
        ..color = Colors.black.withAlpha(100)
        ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 8),
    );

    // White rim highlight at the very edge (bottom-left, light from top-right).
    canvas.drawCircle(
      center,
      discR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = SweepGradient(
          startAngle: -math.pi * 0.75,
          endAngle:    math.pi * 1.25,
          colors: const <Color>[
            Color(0x00FFFFFF),
            Color(0x33FFFFFF),
            Color(0x00FFFFFF),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: discR)),
    );

    // ── Specular highlight ────────────────────────────────────────────────────
    // Soft bright arc in the upper-left quadrant — simulates a ceiling light.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: discR * 0.68),
      -math.pi * 0.85,  // start ~10 o'clock
       math.pi * 0.55,  // sweep ~100°
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = discR * 0.14
        ..color = Colors.white.withAlpha(55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, discR * 0.09),
    );

    // ── Beveled divider lines ─────────────────────────────────────────────────
    // Each line is drawn twice:
    //   1. A dark groove  (top/left edge) → Color(0xFF3C3D3F)
    //   2. A light ridge (bottom/right edge) → Color(0xFF666769)
    // Together they read as an engraved channel on the metallic surface.
    for (final double angle in _kDividerAngles) {
      final double cosA = math.cos(angle);
      final double sinA = math.sin(angle);

      final Offset p1 = Offset(
        center.dx - cosA * discR,
        center.dy - sinA * discR,
      );
      final Offset p2 = Offset(
        center.dx + cosA * discR,
        center.dy + sinA * discR,
      );

      // Dark groove.
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = const Color(0xFF3C3D3F)
          ..strokeWidth = 1.5,
      );

      // Light ridge — offset perpendicular to the line.
      final Offset perp = Offset(-sinA * 1.8, cosA * 1.8);
      canvas.drawLine(
        p1 + perp,
        p2 + perp,
        Paint()
          ..color = const Color(0xFF717375)
          ..strokeWidth = 0.9,
      );
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.size != size;
}

// ── _GlowPainter ─────────────────────────────────────────────────────────────

/// Paints the animated glow cone emanating from the dial centre.
///
/// Unlike the CSS reference (a barely-visible opacity-0.4 gradient blob),
/// this painter draws a vivid fan-shaped sector using a sweep gradient
/// and a radial feather — both keyed to the active position color.
/// A pulsing [opacity] from [AnimatedBuilder] adds breathing life to the glow.
class _GlowPainter extends CustomPainter {
  const _GlowPainter({
    required this.angle,
    required this.color,
    required this.opacity,
    required this.size,
  });

  final double angle;
  final Color color;
  /// Animated opacity in [0.55, 1.0] from the glow pulse controller.
  final double opacity;
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (opacity <= 0.02) return;

    final Offset center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    // Glow stays within the metallic disc boundary.
    final double discR = size / 2 * 0.91;

    // ±25° fan spread around the needle angle.
    const double halfSpread = 25 * math.pi / 180;
    final double startAngle = angle - halfSpread;
    const double sweepAngle = halfSpread * 2;

    // Pie sector path from center to the disc edge.
    final Path sector = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: discR * 0.94),
        startAngle,
        sweepAngle,
        false,
      )
      ..close();

    final Rect bounds = Rect.fromCircle(center: center, radius: discR);

    // ── Outer feathered glow ─────────────────────────────────────────────────
    // Radial gradient: transparent at centre, bright at the disc edge.
    canvas.drawPath(
      sector,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            color.withAlpha(0),
            color.withAlpha((255 * opacity * 0.55).round()),
            color.withAlpha((255 * opacity * 0.90).round()),
          ],
          stops: const <double>[0.0, 0.45, 1.0],
        ).createShader(bounds)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // ── Inner beam (brighter core at the tip) ────────────────────────────────
    canvas.drawPath(
      sector,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            color.withAlpha(0),
            color.withAlpha((255 * opacity * 0.50).round()),
          ],
          stops: const <double>[0.55, 1.0],
        ).createShader(bounds)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.angle != angle || old.color != color || old.opacity != opacity;
}
