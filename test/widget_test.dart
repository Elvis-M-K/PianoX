import 'package:flutter_test/flutter_test.dart';
import 'package:pianox/main.dart';

void main() {
  testWidgets('PianoX dashboard loads correctly', (WidgetTester tester) async {
    // Launch the application.
    await tester.pumpWidget(const PianoXApp());
    await tester.pumpAndSettle();

    // Confirm the learning workspace is displayed.
    expect(find.text('Your Learning Workspace'), findsOneWidget);

    // Confirm all four feature cards are present.
    expect(find.text('Virtual Piano'), findsOneWidget);
    expect(find.text('Lessons'), findsNWidgets(2));
    expect(find.text('Song Library'), findsNWidgets(2));
    expect(find.text('Progress'), findsOneWidget);

    // Confirm the main practice button is displayed.
    expect(find.text('Start Practising'), findsOneWidget);
  });
}