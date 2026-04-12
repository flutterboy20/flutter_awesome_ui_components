import 'package:go_router/go_router.dart';

import '../screens/components_demo/components_demo_screen.dart';
import '../components/card_swiper/card_swiper_demo.dart';
import '../components/rotary_switch/rotary_switch_demo.dart';

/// All application routes live here — never define routes inline.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) => const ComponentsDemoScreen(),
    ),
    GoRoute(
      path: CardSwiperDemo.routeName,
      builder: (context, state) => const CardSwiperDemo(),
    ),
    GoRoute(
      path: RotarySwitchDemo.routeName,
      builder: (context, state) => const RotarySwitchDemo(),
    ),
  ],
);
