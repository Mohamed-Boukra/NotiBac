import 'package:flutter_test/flutter_test.dart';
import 'package:notibac_app/main.dart';

void main() {
  testWidgets('NotiBac app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NotiBacApp());
    expect(find.text('NotiBac'), findsOneWidget);
  });
}
