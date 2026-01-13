import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'pump_test_app.dart';

GoRouter buildPropertyPageRouter({
  required Widget child,
  List<GoRoute> extraRoutes = const [],
}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => child),
      GoRoute(
        path: '/property/:id/edit',
        builder: (_, __) => const Scaffold(body: SizedBox()),
      ),
      ...extraRoutes,
    ],
  );
}

Future<void> pumpWithRouter(
  WidgetTester tester,
  Widget child, {
  TestAppDependencies? dependencies,
  List<GoRoute> extraRoutes = const [],
  bool disableAnimations = true,
}) {
  final router = buildPropertyPageRouter(
    child: child,
    extraRoutes: extraRoutes,
  );
  return pumpTestApp(
    tester,
    child,
    dependencies: dependencies,
    disableAnimations: disableAnimations,
    router: router,
  );
}
