import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'firebase_mock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> setupFirebaseForTesting() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup Firebase mock
  final mock = MockFirebasePlatform();
  FirebasePlatform.instance = mock;
}

Widget createTestableWidget({required Widget child}) {
  return MaterialApp(
    home: Material(
      child: MediaQuery(
        data: const MediaQueryData(),
        child: child,
      ),
    ),
  );
}
