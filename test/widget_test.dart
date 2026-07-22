import 'package:flutter_test/flutter_test.dart';

import 'package:partner_ledger_pro/main.dart';

void main() {
  testWidgets('App should build without error', (WidgetTester tester) async {
    await tester.pumpWidget(const PartnerLedgerProApp());
    expect(find.byType(PartnerLedgerProApp), findsOneWidget);
  });
}
