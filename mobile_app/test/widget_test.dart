import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_mobile_app/main.dart';

void main() {
  testWidgets('App boots to auth gate', (WidgetTester tester) async {
    await tester.pumpWidget(const HostelApp());
    expect(find.byType(AuthGate), findsOneWidget);
  });
}
