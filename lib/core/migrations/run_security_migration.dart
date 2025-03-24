import 'package:firebase_core/firebase_core.dart';
import 'package:fftcg_companion/core/migrations/security_migration.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// This is a standalone script to run the security migration.
/// It should be run once by the developers to set up the security enhancements.
///
/// To run this script:
/// 1. Ensure Firebase is properly configured
/// 2. Run: flutter run -t lib/core/migrations/run_security_migration.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final talker = Talker();

  try {
    talker.info('Starting security migration...');

    // Run the migration
    final migration = SecurityMigration();
    await migration.run();

    talker.info('Security migration completed successfully');
  } catch (e) {
    talker.error('Error running security migration: $e');
  } finally {
    // Exit the app after migration
    talker.info('Migration script completed. Exiting...');
  }
}
