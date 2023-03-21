import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_octocrab/main.dart';
import 'package:simple_octocrab/services/shared_preferences_service.dart';

void main() {
  group('Testing App', () {

    testWidgets('Connect test', (tester) async {

      WidgetsFlutterBinding.ensureInitialized();


      final sharedPreferences = await SharedPreferences.getInstance();

      final myApp= MyApp();

      runApp(ProviderScope(overrides: [
        sharedPreferencesServiceProvider.overrideWithValue(
          SharedPreferencesService(sharedPreferences),
        ),
      ], child: myApp));


      await tester.pumpWidget(myApp);
      print('pump myApp');
      final buttonKeys = [
        'on/off button',

      ];

      for (var button in buttonKeys) {
        await tester.tap(find.byKey(ValueKey(button)));
        print('tapped');
        await tester.pumpAndSettle(const Duration(milliseconds: 200 ));
        expect(reason: '1',find.text('connecting...'), findsOneWidget);
        print('expected');
        await tester.pumpAndSettle(const Duration(milliseconds: 400 ));
        expect(reason: '2',find.text('connecting...'), findsOneWidget);
        print('expected');
        await tester.pumpAndSettle(const Duration(milliseconds: 800 ));
        expect(reason: '3',find.text('connecting...'), findsOneWidget);
        print('expected');
        await tester.pumpAndSettle(const Duration(milliseconds: 1600 ));
        expect(reason: '4',find.text('connecting...'), findsOneWidget);
        print('expected');
        await tester.pumpAndSettle(const Duration(milliseconds: 3200 ));
        expect(reason: '5',find.text('connecting...'), findsOneWidget);
        print('expected');
        await tester.pumpAndSettle(const Duration(milliseconds: 6400 ));
        expect(reason: '6',find.text('connecting...'), findsOneWidget);
        print('expected');

        await tester.pumpAndSettle(const Duration(milliseconds: 10000 ));
        expect(find.text('connecting...'), findsNothing );
        print('expected 2');
      }
      /*
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();

      final removeIconKeys = [
        'remove_icon_0',
        'remove_icon_1',
        'remove_icon_2',
      ];

      for (final iconKey in removeIconKeys) {
        await tester.tap(find.byKey(ValueKey(iconKey)));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text('Removed from favorites.'), findsOneWidget);
      }
      */
    });
  });
}