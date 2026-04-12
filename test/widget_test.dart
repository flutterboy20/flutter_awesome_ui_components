import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_awesome_ui_components/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const FlutterAwesomeApp());
    expect(find.byType(FlutterAwesomeApp), findsOneWidget);
  });
}
