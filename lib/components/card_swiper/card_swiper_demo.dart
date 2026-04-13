import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import 'awesome_card_swiper.dart';

// ─────────────────────────────────────────────
//  Demo screen
// ─────────────────────────────────────────────

class CardSwiperDemo extends StatefulWidget {
  static const String routeName = '/components/card-swiper';

  const CardSwiperDemo({super.key});

  @override
  State<CardSwiperDemo> createState() => _CardSwiperDemoState();
}

class _CardSwiperDemoState extends State<CardSwiperDemo> {
  AllowedSwipeDirections _activeVariant = AllowedSwipeDirections.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHeader(context),
            _buildVariantChips(),
            Expanded(child: _buildSwiperArea()),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: () => GoRouter.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Card Swiper', style: AppTextStyles.heading),
              Text(
                'Multi-direction · Physics throw',
                style: AppTextStyles.label,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Variant chip selector ─────────────────────

  Widget _buildVariantChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: <Widget>[
          _VariantChip(
            label: 'All Directions',
            selected: _activeVariant == AllowedSwipeDirections.all,
            onTap: () =>
                setState(() => _activeVariant = AllowedSwipeDirections.all),
          ),
          const SizedBox(width: 8),
          _VariantChip(
            label: 'Up Only',
            selected: _activeVariant == AllowedSwipeDirections.upOnly,
            onTap: () =>
                setState(() => _activeVariant = AllowedSwipeDirections.upOnly),
          ),
          const SizedBox(width: 8),
          _VariantChip(
            label: 'Horizontal',
            selected: _activeVariant == AllowedSwipeDirections.horizontalOnly,
            onTap: () => setState(
              () => _activeVariant = AllowedSwipeDirections.horizontalOnly,
            ),
          ),
        ],
      ),
    );
  }

  // ── Swiper area ───────────────────────────────

  Widget _buildSwiperArea() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: AwesomeCardSwiper(
          // Key forces a rebuild (and new entrance animation) when variant changes.
          key: ValueKey<AllowedSwipeDirections>(_activeVariant),
          cards: _buildDemoCards(),
          allowedDirections: _activeVariant,
          visibleCardCount: 3,
          stackScaleFactor: 0.07,
          stackOffsetY: 20,
          onSwipe: (swipedCard, direction) {
            // Do the required action based on swipe direction and card data.
          },
        ),
      ),
    );
  }

  List<Widget> _buildDemoCards() {
    final List<_DemoCardData> data = <_DemoCardData>[
      _DemoCardData(
        gradientColors: AppColors.cardGradients[0],
        bankName: 'AURORA BANK',
        cardHolder: 'ALEX MORGAN',
        lastFour: '4291',
        expiry: '09 / 28',
        network: _CardNetwork.visa,
      ),
      _DemoCardData(
        gradientColors: AppColors.cardGradients[1],
        bankName: 'NOVA CREDIT',
        cardHolder: 'JAMIE CHEN',
        lastFour: '7834',
        expiry: '03 / 27',
        network: _CardNetwork.mastercard,
      ),
      _DemoCardData(
        gradientColors: AppColors.cardGradients[2],
        bankName: 'ZENITH PAY',
        cardHolder: 'SAM RIVERA',
        lastFour: '1056',
        expiry: '11 / 26',
        network: _CardNetwork.amex,
      ),
      _DemoCardData(
        gradientColors: AppColors.cardGradients[3],
        bankName: 'APEX WEALTH',
        cardHolder: 'TAYLOR SWIFT',
        lastFour: '3782',
        expiry: '07 / 29',
        network: _CardNetwork.visa,
      ),
      _DemoCardData(
        gradientColors: AppColors.cardGradients[4],
        bankName: 'PRIME CARD',
        cardHolder: 'JORDAN LEE',
        lastFour: '6419',
        expiry: '01 / 27',
        network: _CardNetwork.mastercard,
      ),
      _DemoCardData(
        gradientColors: AppColors.cardGradients[5],
        bankName: 'LUMIS ELITE',
        cardHolder: 'CASEY PARK',
        lastFour: '9023',
        expiry: '05 / 28',
        network: _CardNetwork.amex,
      ),
    ];

    return data.map((d) => _DemoCard(data: d)).toList(growable: false);
  }
}

// ─────────────────────────────────────────────
//  Card network enum
// ─────────────────────────────────────────────

enum _CardNetwork { visa, mastercard, amex }

// ─────────────────────────────────────────────
//  Variant chip
// ─────────────────────────────────────────────

class _VariantChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _VariantChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.divider,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: selected ? Colors.white : AppColors.textMuted,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Demo card data model
// ─────────────────────────────────────────────

class _DemoCardData {
  final List<Color> gradientColors;
  final String bankName;
  final String cardHolder;
  final String lastFour;
  final String expiry;
  final _CardNetwork network;

  const _DemoCardData({
    required this.gradientColors,
    required this.bankName,
    required this.cardHolder,
    required this.lastFour,
    required this.expiry,
    required this.network,
  });
}

// ─────────────────────────────────────────────
//  Credit card widget
// ─────────────────────────────────────────────

class _DemoCard extends StatelessWidget {
  final _DemoCardData data;

  const _DemoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: data.gradientColors,
        ),
        // Two-layer shadow for premium depth feel.
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: data.gradientColors.last.withValues(alpha: 0.55),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          // ── Holographic shimmer: diagonal light sweep ──
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const <double>[0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // ── Decorative circle top-right (depth) ──
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),

          // ── Decorative circle bottom-left ──
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.12),
              ),
            ),
          ),

          // ── Card content ──
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Row 1: bank name + network logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      data.bankName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                    _NetworkLogo(network: data.network),
                  ],
                ),

                const SizedBox(height: 16),

                // Row 2: EMV chip + contactless icon
                Row(
                  children: <Widget>[
                    const _ChipWidget(),
                    const SizedBox(width: 12),
                    // Contactless payment icon (concentric arcs)
                    CustomPaint(
                      size: const Size(20, 20),
                      painter: _ContactlessPainter(),
                    ),
                  ],
                ),

                const Spacer(),

                // Row 3: masked card number
                Text(
                  '\u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022  ${data.lastFour}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 2.5,
                    fontFamily: 'monospace',
                  ),
                ),

                const SizedBox(height: 14),

                // Row 4: cardholder name + expiry
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'CARD HOLDER',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.60),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.cardHolder,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          'EXPIRES',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.60),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.expiry,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EMV chip widget
// ─────────────────────────────────────────────

class _ChipWidget extends StatelessWidget {
  const _ChipWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(38, 28), painter: _ChipPainter());
  }
}

/// Draws a gold EMV chip with circuit-line grooves.
class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final RRect body = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(5),
    );

    // Gradient fill — gold metallic.
    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          const Color(0xFFD4A843),
          const Color(0xFFF5D679),
          const Color(0xFFB8892A),
          const Color(0xFFE8C355),
        ],
        stops: const <double>[0.0, 0.35, 0.65, 1.0],
      ).createShader(Offset.zero & size);

    canvas.drawRRect(body, bodyPaint);

    // Inner groove lines (circuit pattern).
    final Paint linePaint = Paint()
      ..color = const Color(0xFF8A6510).withValues(alpha: 0.55)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final double w = size.width;
    final double h = size.height;

    // Vertical center divider
    canvas.drawLine(Offset(w / 2, 4), Offset(w / 2, h - 4), linePaint);
    // Horizontal center divider
    canvas.drawLine(Offset(4, h / 2), Offset(w - 4, h / 2), linePaint);
    // Top horizontal groove
    canvas.drawLine(Offset(4, h * 0.28), Offset(w - 4, h * 0.28), linePaint);
    // Bottom horizontal groove
    canvas.drawLine(Offset(4, h * 0.72), Offset(w - 4, h * 0.72), linePaint);

    // Subtle inner highlight (top-left sheen)
    final Paint sheenPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, w - 2, h / 2 - 1),
        const Radius.circular(4),
      ),
      sheenPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
//  Contactless payment icon (concentric arcs)
// ─────────────────────────────────────────────

class _ContactlessPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // Three concentric arcs emanating from center-left.
    for (int i = 1; i <= 3; i++) {
      final double radius = i * 4.0;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx - 2, cy), radius: radius),
        -0.9, // start angle (roughly -52°)
        1.8, // sweep angle (roughly 103°)
        false,
        paint..color = Colors.white.withValues(alpha: 0.75 - (i - 1) * 0.15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
//  Network logo
// ─────────────────────────────────────────────

class _NetworkLogo extends StatelessWidget {
  final _CardNetwork network;

  const _NetworkLogo({required this.network});

  @override
  Widget build(BuildContext context) {
    return switch (network) {
      _CardNetwork.visa => const Text(
        'VISA',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
      _CardNetwork.mastercard => SizedBox(
        width: 42,
        height: 26,
        child: Stack(
          children: <Widget>[
            // Left circle — red-orange
            Positioned(
              left: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEB001B).withValues(alpha: 0.90),
                ),
              ),
            ),
            // Right circle — amber (overlapping)
            Positioned(
              left: 16,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF79E1B).withValues(alpha: 0.90),
                ),
              ),
            ),
          ],
        ),
      ),
      _CardNetwork.amex => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.40),
            width: 0.8,
          ),
        ),
        child: const Text(
          'AMEX',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    };
  }
}
