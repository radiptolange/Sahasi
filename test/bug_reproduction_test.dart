
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahasi/screens/main_navigation_screen.dart';
import 'package:sahasi/screens/home_page.dart';

void main() {
  testWidgets('MainNavigationScreen updates HomePage when isSOSActive changes', (WidgetTester tester) async {
    // Create a mock app wrapper that simulates parent state change
    bool isSOSActive = false;
    late StateSetter setParentState;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setParentState = setState;
            return MainNavigationScreen(isSOSActive: isSOSActive);
          },
        ),
      ),
    );

    // Verify initial state
    expect(find.byType(HomePage), findsOneWidget);
    HomePage homePage = tester.widget(find.byType(HomePage));
    expect(homePage.isSOSActive, isFalse);

    // Update parent state to toggle isSOSActive
    setParentState(() {
      isSOSActive = true;
    });
    await tester.pump();

    // Verify HomePage has been updated
    homePage = tester.widget(find.byType(HomePage));
    expect(homePage.isSOSActive, isTrue);
  });
}
