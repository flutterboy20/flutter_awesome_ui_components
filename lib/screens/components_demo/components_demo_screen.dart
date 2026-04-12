import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../components/card_swiper/card_swiper_demo.dart';
import '../../components/rotary_switch/rotary_switch_demo.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

/// Initial route ('/') — dark scrollable list of all components.
/// Tap a card to navigate to that component's demo screen.
class ComponentsDemoScreen extends StatelessWidget {
  const ComponentsDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 24),
              Text('Flutter Boy', style: AppTextStyles.label),
              const SizedBox(height: 6),
              Text('UI Components', style: AppTextStyles.displayLarge),
              const SizedBox(height: 8),
              Text(
                'Premium, animated Flutter widgets',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: const <Widget>[
                    _ComponentCard(
                      route: CardSwiperDemo.routeName,
                      title: 'Card Swiper',
                      description:
                          'Multi-direction gesture-driven card stack with physics throw, real-time tilt, and spring-promoted background cards.',
                      tag: 'Gestures · Animation',
                      gradient: <Color>[Color(0xFF667EEA), Color(0xFF764BA2)],
                      icon: Icons.style_rounded,
                    ),
                    _ComponentCard(
                      route: RotarySwitchDemo.routeName,
                      title: 'Rotary Switch',
                      description:
                          'Metallic rotary dial with 6 positions, drag-to-rotate gesture, physics snap, vivid glow cone, and position-based color system.',
                      tag: 'Gestures · Animation',
                      gradient: <Color>[Color(0xFF43E97B), Color(0xFF38F9D7)],
                      icon: Icons.rotate_right_rounded,
                    ),
                    // Add more component cards here as the library grows.
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Component list card
// ─────────────────────────────────────────────

class _ComponentCard extends StatefulWidget {
  final String route;
  final String title;
  final String description;
  final String tag;
  final List<Color> gradient;
  final IconData icon;

  const _ComponentCard({
    required this.route,
    required this.title,
    required this.description,
    required this.tag,
    required this.gradient,
    required this.icon,
  });

  @override
  State<_ComponentCard> createState() => _ComponentCardState();
}

class _ComponentCardState extends State<_ComponentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    // Press-down scale: 0.97
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) {
          _pressCtrl.reverse();
          GoRouter.of(context).push(widget.route);
        },
        onTapCancel: () => _pressCtrl.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (BuildContext ctx, Widget? child) =>
              Transform.scale(scale: _scaleAnim.value, child: child),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: <Widget>[
                // Gradient icon block
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.gradient,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: widget.gradient.first.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 32),
                ),
                // Text content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(widget.tag, style: AppTextStyles.label),
                        const SizedBox(height: 4),
                        Text(widget.title, style: AppTextStyles.heading),
                        const SizedBox(height: 6),
                        Text(
                          widget.description,
                          style: AppTextStyles.body.copyWith(fontSize: 13),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textMuted,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
