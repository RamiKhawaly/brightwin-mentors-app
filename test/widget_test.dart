// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:brightwin_mentors/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BrightwinMentorsApp());

    // Verify that the app loads
    expect(find.byType(BrightwinMentorsApp), findsOneWidget);
  });
}
