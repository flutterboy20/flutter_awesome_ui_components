// Component: AwesomeCardSwiper
// Usage:
//   AwesomeCardSwiper(
//     cards: [MyCard(), MyCard(), MyCard()],
//     onSwipe: (index, direction) => print('Swiped $index $direction'),
//   )
//
// Drop-in card stack with multi-direction gesture-driven physics:
//   • Drag in any direction to throw a card off the stack
//   • Real-time tilt continuously follows your finger while dragging
//   • Velocity-aware fling: a fast flick triggers throw even with short travel
//   • Background cards promote forward with easeOutBack spring feel
//   • Directional glow indicator (color shifts with swipe direction)
//   • Shadow depth grows as card lifts off the stack
//   • Entrance stagger animation on first render

import 'dart:math' as math;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  Public enums
// ─────────────────────────────────────────────

/// Direction a card was swiped away.
enum SwipeDirection { up, left, right }

/// Which swipe directions the user is allowed to trigger.
enum AllowedSwipeDirections {
  /// Only upward swipes are accepted.
  upOnly,

  /// Only left / right swipes are accepted.
  horizontalOnly,

  /// All three directions are accepted (default).
  all,
}

// ─────────────────────────────────────────────
//  Widget
// ─────────────────────────────────────────────

class AwesomeCardSwiper extends StatefulWidget {
  /// The card content widgets. Cards cycle infinitely in a loop.
  final List<Widget> cards;

  /// Restricts which swipe directions trigger a throw. Default: all.
  final AllowedSwipeDirections allowedDirections;

  /// Fired when a card is fully thrown off screen.
  /// [index] is the index into [cards]; [direction] is where it went.
  final void Function(int index, SwipeDirection direction)? onSwipe;

  /// Number of cards visible in the stack at once. Clamped to cards.length.
  final int visibleCardCount;

  /// Scale step between consecutive stacked cards (recommended 0.04 – 0.10).
  final double stackScaleFactor;

  /// Vertical pixel gap between consecutive stacked cards.
  final double stackOffsetY;

  /// Duration of the throw-away flight animation.
  final Duration swipeDuration;

  /// Minimum drag distance (px) to trigger a throw.
  /// A fast fling overrides this threshold.
  final double throwDistanceThreshold;

  /// Minimum fling velocity (px/s) to trigger a throw regardless of distance.
  final double throwVelocityThreshold;

  const AwesomeCardSwiper({
    super.key,
    required this.cards,
    this.allowedDirections = AllowedSwipeDirections.all,
    this.onSwipe,
    this.visibleCardCount = 3,
    this.stackScaleFactor = 0.07,
    this.stackOffsetY = 18.0,
    this.swipeDuration = const Duration(milliseconds: 500),
    this.throwDistanceThreshold = 80.0,
    this.throwVelocityThreshold = 600.0,
  }) : assert(cards.length > 0, 'cards must not be empty');

  @override
  State<AwesomeCardSwiper> createState() => _AwesomeCardSwiperState();
}

// ─────────────────────────────────────────────
//  Internal state machine phase
// ─────────────────────────────────────────────

enum _Phase { idle, dragging, throwing }

// ─────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────

class _AwesomeCardSwiperState extends State<AwesomeCardSwiper>
    with TickerProviderStateMixin {
  // ── Controllers ────────────────────────────

  /// Drives the front card flying off screen (throw phase).
  late final AnimationController _throwCtrl;

  /// Drives background cards promoting one step forward (throw phase).
  late final AnimationController _promoteCtrl;

  /// Drives the initial stagger-in entrance animation (one-shot).
  late final AnimationController _entranceCtrl;

  // ── Per-throw animations (rebuilt each throw) ──

  /// Translation of the flying front card toward off-screen target.
  late Animation<Offset> _throwTranslateAnim;

  /// Rotation of the flying front card (radians).
  late Animation<double> _throwRotateAnim;

  /// Opacity fade of the flying front card (fades out in last 40%).
  late Animation<double> _throwFadeAnim;

  // ── Card ordering ───────────────────────────

  /// Ordered indices into widget.cards.
  /// Index 0 = back-most card in the visual stack.
  /// Last index = front card (interactive).
  late List<int> _cardOrder;

  // ── Drag state (zero-lag — raw setState) ────

  _Phase _phase = _Phase.idle;
  Offset _dragOffset = Offset.zero;

  // ─────────────────────────────────────────────
  //  Lifecycle
  // ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // cards[0] starts at the back; cards.last is the first front card.
    _cardOrder = List<int>.generate(widget.cards.length, (int i) => i);

    // Throw controller: drives the front card flight.
    _throwCtrl = AnimationController(
      vsync: this,
      duration: widget.swipeDuration,
    )..addStatusListener(_onThrowStatus);

    // Promote controller: background cards spring to their next positions.
    // Shorter than throw so cards settle before the flight ends.
    _promoteCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // Entrance controller: stagger-in on first render.
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Placeholder animations replaced on first throw.
    _throwTranslateAnim = const AlwaysStoppedAnimation<Offset>(Offset.zero);
    _throwRotateAnim = const AlwaysStoppedAnimation<double>(0.0);
    _throwFadeAnim = const AlwaysStoppedAnimation<double>(1.0);

    // Kick off the entrance stagger after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _throwCtrl.dispose();
    _promoteCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  Gesture callbacks
  // ─────────────────────────────────────────────

  void _onDragStart(DragStartDetails details) {
    if (_phase != _Phase.idle) return;
    setState(() {
      _phase = _Phase.dragging;
      _dragOffset = Offset.zero;
    });
  }

  /// Zero-lag: directly update offset, no TweenAnimationBuilder lag.
  void _onDragUpdate(DragUpdateDetails details) {
    if (_phase != _Phase.dragging) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_phase != _Phase.dragging) return;

    final Offset velocity = details.velocity.pixelsPerSecond;
    final bool fastEnough = velocity.distance >= widget.throwVelocityThreshold;
    final bool farEnough = _dragOffset.distance >= widget.throwDistanceThreshold;

    if (!fastEnough && !farEnough) {
      // Snap card back to resting position.
      setState(() {
        _phase = _Phase.idle;
        _dragOffset = Offset.zero;
      });
      return;
    }

    // Use velocity direction for fast flings; fall back to drag offset direction.
    final Offset dominant =
        velocity.distance > 200.0 ? velocity : _dragOffset;
    final SwipeDirection direction = _resolveDirection(dominant);

    if (!_isAllowed(direction)) {
      setState(() {
        _phase = _Phase.idle;
        _dragOffset = Offset.zero;
      });
      return;
    }

    _startThrow(direction);
  }

  // ─────────────────────────────────────────────
  //  Direction helpers
  // ─────────────────────────────────────────────

  /// Maps a 2D vector to the dominant SwipeDirection.
  SwipeDirection _resolveDirection(Offset vector) {
    if (vector.dy.abs() > vector.dx.abs()) {
      // Vertical dominant → only up makes sense for a card stack.
      return SwipeDirection.up;
    }
    return vector.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
  }

  bool _isAllowed(SwipeDirection dir) {
    switch (widget.allowedDirections) {
      case AllowedSwipeDirections.upOnly:
        return dir == SwipeDirection.up;
      case AllowedSwipeDirections.horizontalOnly:
        return dir != SwipeDirection.up;
      case AllowedSwipeDirections.all:
        return true;
    }
  }

  // ─────────────────────────────────────────────
  //  Throw sequence
  // ─────────────────────────────────────────────

  void _startThrow(SwipeDirection direction) {
    final Size screen = MediaQuery.sizeOf(context);

    // ── Translation: card flies toward off-screen target ──
    // Starts from current drag position for a seamless transition.
    _throwTranslateAnim = Tween<Offset>(
      begin: _dragOffset,
      end: _throwTarget(direction, screen),
    ).animate(CurvedAnimation(
      parent: _throwCtrl,
      // easeInCubic: slow start → accelerates, feels like a real throw.
      curve: Curves.easeInCubic,
    ));

    // ── Rotation: starts from current tilt, flies to final angle ──
    final double currentTilt = (_dragOffset.dx / 280.0).clamp(-0.22, 0.22);
    _throwRotateAnim = Tween<double>(
      begin: currentTilt,
      end: _throwRotation(direction),
    ).animate(CurvedAnimation(
      parent: _throwCtrl,
      curve: Curves.easeInCubic,
    ));

    // ── Opacity: fades out in the last 40% of the animation ──
    _throwFadeAnim = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _throwCtrl,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    setState(() {
      _phase = _Phase.throwing;
    });

    // Start throw animation.
    _throwCtrl.forward(from: 0.0);

    // Background cards promote with a small delay so the front card
    // visually separates before the stack moves.
    Future<void>.delayed(const Duration(milliseconds: 60), () {
      if (mounted) _promoteCtrl.forward(from: 0.0);
    });

    // Notify the caller immediately so they can update their state.
    widget.onSwipe?.call(_cardOrder.last, direction);
  }

  /// Returns the off-screen translation target for the given direction.
  Offset _throwTarget(SwipeDirection direction, Size screen) {
    switch (direction) {
      case SwipeDirection.up:
        // Carry horizontal drift so diagonal flicks feel natural.
        return Offset(
          _dragOffset.dx * 2.5,
          -(screen.height * 0.9 + _dragOffset.dy.abs()),
        );
      case SwipeDirection.left:
        return Offset(-(screen.width * 1.4), screen.height * 0.1);
      case SwipeDirection.right:
        return Offset(screen.width * 1.4, screen.height * 0.1);
    }
  }

  /// Returns the final rotation angle (radians) for the given direction.
  double _throwRotation(SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.up:
        // Full 360° flip; direction follows horizontal drag bias.
        return _dragOffset.dx >= 0 ? 2.0 * math.pi : -2.0 * math.pi;
      case SwipeDirection.left:
        return -math.pi * 0.45; // ~80° counter-clockwise
      case SwipeDirection.right:
        return math.pi * 0.45;
    }
  }

  /// Called when the throw AnimationController reaches its end.
  void _onThrowStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _cycleCards();
  }

  /// Rotates _cardOrder so the thrown card moves to the back.
  /// Resets both controllers — by the time this runs:
  ///   • promoteCtrl has already finished (350ms < 500ms throw)
  ///   • cards are already visually in their promoted positions
  /// Resetting controllers and updating order produces no visible snap.
  void _cycleCards() {
    setState(() {
      final int thrownIndex = _cardOrder.removeLast();
      _cardOrder.insert(0, thrownIndex);
      _phase = _Phase.idle;
      _dragOffset = Offset.zero;
    });
    _throwCtrl.reset();
    _promoteCtrl.reset();
  }

  // ─────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final int visibleCount =
        math.min(widget.visibleCardCount, widget.cards.length);

    // AnimatedBuilder listens to all three controllers.
    // Rebuilds only when animation values change — not on drag setState.
    // (Drag setState triggers a normal rebuild which is intentional for zero lag.)
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        _throwCtrl,
        _promoteCtrl,
        _entranceCtrl,
      ]),
      builder: (BuildContext context, Widget? _) {
        return Stack(
          // center: all cards share the same center point; transforms offset them.
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: List<Widget>.generate(visibleCount, (int i) {
            // i = 0 → back-most card (rendered first, visually behind).
            // i = visibleCount-1 → front card (rendered last, visually on top).
            final int orderIndex =
                _cardOrder.length - visibleCount + i;
            final int cardIndex = _cardOrder[orderIndex];
            final bool isFront = i == visibleCount - 1;

            return _buildCard(
              positionFromBack: i,
              visibleCount: visibleCount,
              cardIndex: cardIndex,
              isFront: isFront,
            );
          }),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  //  Card construction
  // ─────────────────────────────────────────────

  Widget _buildCard({
    required int positionFromBack,
    required int visibleCount,
    required int cardIndex,
    required bool isFront,
  }) {
    // positionFromFront = 0 for the front card, increases toward the back.
    final int positionFromFront = (visibleCount - 1) - positionFromBack;

    // ── Base stack position: no animation ──
    // Front card: scale=1.0, yOffset=0.
    // Each step back: scale decreases, card shifts down (peeks from below).
    final double baseScale =
        1.0 - positionFromFront * widget.stackScaleFactor;
    final double baseYOffset = positionFromFront * widget.stackOffsetY;

    // ── Promote animation: background cards spring one step forward ──
    // At promoteCtrl.value=0 → cards at their base positions.
    // At promoteCtrl.value=1 → each card is where the card in front of it was.
    // Uses easeOutBack for a subtle elastic overshoot (spring feel).
    double displayScale = baseScale;
    double displayYOffset = baseYOffset;

    if (!isFront && _phase == _Phase.throwing) {
      final double t = CurvedAnimation(
        parent: _promoteCtrl,
        curve: Curves.easeOutBack,
      ).value;
      // Target: one step forward = scale+step, yOffset-step.
      displayScale = _lerp(baseScale, baseScale + widget.stackScaleFactor, t);
      displayYOffset =
          _lerp(baseYOffset, baseYOffset - widget.stackOffsetY, t);
    }

    // ── Entrance animation: stagger-in from below ──
    // Cards enter back-to-front; each has a slightly later interval.
    final double entranceStart = positionFromBack / visibleCount * 0.55;
    final double entranceEnd = (entranceStart + 0.45).clamp(0.0, 1.0);
    final double entranceT = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Interval(entranceStart, entranceEnd, curve: Curves.easeOutCubic),
    ).value;

    // During entrance: slide up from 100px below, fade from 0.
    final double entranceYShift = _lerp(100.0, 0.0, entranceT);
    final double entranceOpacity = entranceT;

    // ── Drag tilt (front card only, dragging phase) ──
    // The card tilts continuously as you drag left/right.
    // Max tilt ≈ ±12.6° (0.22 radians) at 280px horizontal drag.
    double dragTilt = 0.0;
    double liftFactor = 0.0; // 0..1, drives shadow intensity

    if (isFront && _phase == _Phase.dragging) {
      dragTilt = (_dragOffset.dx / 280.0).clamp(-0.22, 0.22);
      liftFactor = (_dragOffset.distance / 160.0).clamp(0.0, 1.0);
    }

    // ─── Assemble the widget tree (inner → outer) ───────────────────
    // Inner: raw card content
    Widget card = widget.cards[cardIndex];

    // Layer 1: shadow — depth grows as card lifts off the stack.
    card = _withShadow(card, liftFactor);

    // Layer 2: directional glow overlay (front card, dragging only).
    if (isFront && _phase == _Phase.dragging) {
      card = _withDirectionalGlow(card);
    }

    // Layer 3: drag tilt rotation (pivots around card center).
    if (dragTilt != 0.0) {
      card = Transform.rotate(
        angle: dragTilt,
        alignment: Alignment.center,
        child: card,
      );
    }

    // Layer 4: drag translation (zero-lag finger tracking).
    if (isFront && _phase == _Phase.dragging) {
      card = Transform.translate(
        offset: _dragOffset,
        child: card,
      );
    }

    // Layer 5: throw animation (replaces drag transforms during throw).
    if (isFront && _phase == _Phase.throwing) {
      card = Opacity(
        opacity: _throwFadeAnim.value,
        child: Transform.translate(
          offset: _throwTranslateAnim.value,
          child: Transform.rotate(
            angle: _throwRotateAnim.value,
            child: card,
          ),
        ),
      );
    }

    // Layer 6: stack position — scale and Y-offset relative to stack center.
    // Order matters: translate OUTSIDE scale so the offset is in parent pixels.
    card = Transform.translate(
      offset: Offset(0.0, displayYOffset + entranceYShift),
      child: Transform.scale(
        scale: displayScale,
        child: card,
      ),
    );

    // Layer 7: entrance fade.
    if (_entranceCtrl.value < 1.0) {
      card = Opacity(
        opacity: entranceOpacity.clamp(0.0, 1.0),
        child: card,
      );
    }

    // Layer 8: gesture detection — only on front card, only when not throwing.
    if (isFront && _phase != _Phase.throwing) {
      card = GestureDetector(
        onPanStart: _onDragStart,
        onPanUpdate: _onDragUpdate,
        onPanEnd: _onDragEnd,
        child: card,
      );
    }

    return card;
  }

  // ─────────────────────────────────────────────
  //  Visual helpers
  // ─────────────────────────────────────────────

  /// Wraps [child] with layered box shadows.
  /// [liftFactor] 0→1 intensifies the upper shadow as the card is dragged.
  Widget _withShadow(Widget child, double liftFactor) {
    return DecoratedBox(
      // position: DecorationPosition.background draws behind the child.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: <BoxShadow>[
          // Base ambient shadow — always visible.
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14.0,
            offset: const Offset(0.0, 8.0),
          ),
          // Lift shadow — grows when dragging (card "floats" off the stack).
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.14 + 0.22 * liftFactor),
            blurRadius: 10.0 + 36.0 * liftFactor,
            offset: Offset(0.0, 4.0 + 18.0 * liftFactor),
            spreadRadius: liftFactor * 3.0,
          ),
        ],
      ),
      child: child,
    );
  }

  /// Overlays a subtle colored gradient glow on the edge toward which
  /// the user is swiping, giving direction feedback without any text labels.
  Widget _withDirectionalGlow(Widget child) {
    final double dx = _dragOffset.dx;
    final double dy = _dragOffset.dy;

    // Determine dominant direction for glow color/alignment.
    Color glowColor;
    AlignmentGeometry glowFrom;
    AlignmentGeometry glowTo;

    if (dy < -30 && dy.abs() > dx.abs()) {
      // Swiping up → cool blue glow from the top.
      glowColor = const Color(0xFF4FACFE);
      glowFrom = Alignment.topCenter;
      glowTo = Alignment.bottomCenter;
    } else if (dx > 30) {
      // Swiping right → green glow from the right edge.
      glowColor = const Color(0xFF43E97B);
      glowFrom = Alignment.centerRight;
      glowTo = Alignment.centerLeft;
    } else if (dx < -30) {
      // Swiping left → red glow from the left edge.
      glowColor = const Color(0xFFF5576C);
      glowFrom = Alignment.centerLeft;
      glowTo = Alignment.centerRight;
    } else {
      // Not yet in a decisive direction — no glow.
      return child;
    }

    // Glow intensity scales with drag distance (max ~60% opacity).
    final double intensity =
        (_dragOffset.distance / 160.0).clamp(0.0, 0.55);

    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                gradient: LinearGradient(
                  begin: glowFrom,
                  end: glowTo,
                  colors: <Color>[
                    glowColor.withValues(alpha: intensity),
                    Colors.transparent,
                  ],
                  stops: const <double>[0.0, 0.6],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  Utilities
  // ─────────────────────────────────────────────

  /// Linear interpolation helper — avoids importing dart:ui lerpDouble.
  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
