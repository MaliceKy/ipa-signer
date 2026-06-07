import 'package:flutter_test/flutter_test.dart';

import 'package:ipasigner/main.dart';

void main() {
  testWidgets('app boots', (tester) async {
    await tester.pumpWidget(const IpaSignerApp());
    expect(find.byType(IpaSignerApp), findsOneWidget);
  });
}
