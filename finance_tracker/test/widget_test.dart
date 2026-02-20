// Smoke test — verifies the app widget tree builds without throwing.
// Full integration tests require a running backend and are out of scope
// for this take-home assessment.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: FinanceTrackerApp()),
    );

    // HTTP requests are asynchronous; the first frame should render without
    // any synchronous exception.
    expect(tester.takeException(), isNull);
  });
}
