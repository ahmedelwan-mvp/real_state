import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpLocalization(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 80),
  int maxTries = 25,
}) async {
  for (var attempt = 0; attempt < maxTries; attempt++) {
    if (tester.any(finder)) return;
    await tester.pump(step);
  }
  throw StateError('Finder $finder was not found after ${step * maxTries}');
}

Finder byKeyStr(String key) => find.byKey(ValueKey(key));
