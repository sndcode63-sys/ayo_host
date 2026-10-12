import 'package:ayo_host/data/services/api_client.dart';
import 'package:ayo_host/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots into the red splash screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(AyoHostApp(apiClient: ApiClient()));

    expect(find.text('AYO'), findsOneWidget);
    expect(find.text('AYO HOST'), findsOneWidget);

    // Let the splash auto-navigation timer complete.
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 500));
  });
}
