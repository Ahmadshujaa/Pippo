import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:atlas_core/atlas_core.dart';
import 'package:tactics/app/app.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://hfnfmtyiblxmifuzbmze.supabase.co',
      publishableKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhmbmZtdHlpYmx4bWlmdXpibXplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3MzcyMDIsImV4cCI6MjA4NDMxMzIwMn0.T0cAtNMcaOdajte6d3d1kkQY1vzq_JR73uEeOYTPByg',
    );
    await AuthService.init();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // `initialRoute` is resolved by bootstrap (`AuthApiService.startupRoute()`);
    // the smoke test starts on the welcome screen, exactly like a device with no
    // stored session.
    await tester.pumpWidget(const TacticsApp(initialRoute: '/'));

    expect(
      find.text('Get better at chess fast with Pippo, your personal '
          'coach to help you learn, improve, and win more games.'),
      findsOneWidget,
    );
  });
}


