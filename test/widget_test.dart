import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shift_tomo/main.dart';
import 'package:shift_tomo/src/features/calendar/ui/calendar_page.dart';

void main() {
  testWidgets('CalendarPage basic rendering test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Verify that CalendarPage is rendered.
    expect(find.byType(CalendarPage), findsOneWidget);
    
    // Check if some weekdays are present.
    expect(find.text('月'), findsOneWidget);
    expect(find.text('日'), findsOneWidget);
  });
}
