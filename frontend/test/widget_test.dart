import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:frontend/main.dart';
import 'package:frontend/di/service_locator.dart';
import 'package:frontend/logic/controllers/locale_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_auth'),
      (methodCall) async {
        if (methodCall.method == 'startListen' || methodCall.method == 'registerIdTokenListener' || methodCall.method == 'registerAuthStateListener') {
          return {
            'appName': '[DEFAULT]',
          };
        }
        return null;
      },
    );
    await Firebase.initializeApp();
  });

  testWidgets('App builds without crashing', (WidgetTester tester) async {
    setupServiceLocator();
    final localeProvider = LocaleProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: localeProvider,
        child: const LevelApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
