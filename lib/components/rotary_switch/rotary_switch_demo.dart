import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import 'awesome_rotary_switch.dart';

// ── Color themes ───────────────────────────────────────────────────────────────

/// Default "Heat" palette: gray → green → lime → amber → orange → red.
/// Mirrors _kDefaultPositionColors in the component (duplicated for demo use).
const List<Color> _kHeatColors = <Color>[
  Color(0xFF7A7A8A),
  Color(0xFF4CAF50),
  Color(0xFF8BC34A),
  Color(0xFFFF9800),
  Color(0xFFFF5722),
  Color(0xFFF44336),
];

/// Monochrome silver palette — same structure, escalating brightness.
const List<Color> _kMonochromeColors = <Color>[
  Color(0xFF555566),
  Color(0xFF8888A0),
  Color(0xFFAAAAAC),
  Color(0xFFCCCCD4),
  Color(0xFFE0E0E8),
  Color(0xFFF6F6FF),
];

/// Ocean palette: steel → cyan → sky → blue → indigo → violet.
const List<Color> _kOceanColors = <Color>[
  Color(0xFF607D8B),
  Color(0xFF00BCD4),
  Color(0xFF29B6F6),
  Color(0xFF42A5F5),
  Color(0xFF5C6BC0),
  Color(0xFF9575CD),
];

// ── Position descriptions ──────────────────────────────────────────────────────

const List<String> _kDescriptions = <String>[
  'Fan stopped',
  'Barely a breeze',
  'Gentle airflow',
  'Comfortable cool',
  'Strong gust',
  'Maximum power',
];

// ── Color theme enum ───────────────────────────────────────────────────────────

enum _ColorTheme { heat, mono, ocean }

// ── Demo screen ────────────────────────────────────────────────────────────────

class RotarySwitchDemo extends StatefulWidget {
  static const String routeName = '/components/rotary-switch';

  const RotarySwitchDemo({super.key});

  @override
  State<RotarySwitchDemo> createState() => _RotarySwitchDemoState();
}

class _RotarySwitchDemoState extends State<RotarySwitchDemo> {
  int _position = 0;
  _ColorTheme _colorTheme = _ColorTheme.heat;
  bool _glowEnabled = true;
  bool _dragEnabled = true;

  /// Returns the resolved color list for the active theme.
  /// Always non-null so the status bar can read [_position]'s color directly.
  List<Color> get _colors => switch (_colorTheme) {
        _ColorTheme.heat  => _kHeatColors,
        _ColorTheme.mono  => _kMonochromeColors,
        _ColorTheme.ocean => _kOceanColors,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHeader(context),
            _buildThemeChips(),
            const SizedBox(height: 4),
            _buildToggleRow(),
            Expanded(child: _buildDialArea()),
            _buildStatusBar(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

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
              Text('Rotary Switch', style: AppTextStyles.heading),
              Text(
                'Drag to rotate · Physics snap',
                style: AppTextStyles.label,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Color theme chips ───────────────────────────────────────────────────────

  Widget _buildThemeChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: <Widget>[
          _Chip(
            label: 'Heat',
            selected: _colorTheme == _ColorTheme.heat,
            onTap: () => setState(() => _colorTheme = _ColorTheme.heat),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Mono',
            selected: _colorTheme == _ColorTheme.mono,
            onTap: () => setState(() => _colorTheme = _ColorTheme.mono),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Ocean',
            selected: _colorTheme == _ColorTheme.ocean,
            onTap: () => setState(() => _colorTheme = _ColorTheme.ocean),
          ),
        ],
      ),
    );
  }

  // ── Glow / Drag toggles ─────────────────────────────────────────────────────

  Widget _buildToggleRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: <Widget>[
          _Chip(
            label: 'Glow',
            selected: _glowEnabled,
            onTap: () => setState(() => _glowEnabled = !_glowEnabled),
            // Inactive toggles render as dimmed rather than accent-colored.
            dimWhenUnselected: true,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Drag',
            selected: _dragEnabled,
            onTap: () => setState(() => _dragEnabled = !_dragEnabled),
            dimWhenUnselected: true,
          ),
        ],
      ),
    );
  }

  // ── Dial area ───────────────────────────────────────────────────────────────

  Widget _buildDialArea() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Subtle ambient glow behind the dial.
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.accent.withAlpha(18),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: AwesomeRotarySwitch(
              // Rebuild (and reset to current _position) when theme changes.
              key: ValueKey<_ColorTheme>(_colorTheme),
              initialPosition: _position,
              size: 260,
              positionColors: _colors,
              enableGlow: _glowEnabled,
              enableDrag: _dragEnabled,
              onChanged: (int pos) => setState(() => _position = pos),
            ),
          ),
          const SizedBox(height: 20),
          // Tap-to-reset hint (shows only when not at OFF).
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _position != 0 ? 0.45 : 0.0,
            child: Text(
              'Tap the centre knob to turn off',
              style: AppTextStyles.label.copyWith(letterSpacing: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status bar ──────────────────────────────────────────────────────────────

  Widget _buildStatusBar() {
    final Color dot = _colors[_position];
    final String posLabel = _position == 0 ? 'OFF' : 'Speed $_position';
    final String description = _kDescriptions[_position];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        transitionBuilder: (Widget child, Animation<double> anim) =>
            FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        child: Row(
          key: ValueKey<int>(_position),
          children: <Widget>[
            // Colored dot mirrors the active position color.
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dot,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: dot.withAlpha(160),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            Text(
              '$posLabel — $description',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _Chip ──────────────────────────────────────────────────────────────────────

/// A compact selection chip used for both theme variants and feature toggles.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dimWhenUnselected = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// When true, the chip looks dimmed (not just neutral) when unselected.
  /// Used for binary toggle chips (Glow, Drag) to convey OFF state clearly.
  final bool dimWhenUnselected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: selected
                ? Colors.white
                : dimWhenUnselected
                    ? AppColors.textMuted.withAlpha(130)
                    : AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
