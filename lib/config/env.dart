import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'FIREBASE_API_KEY')
  static const String firebaseApiKey = _Env.firebaseApiKey;

  @EnviedField(varName: 'FIREBASE_APP_ID')
  static const String firebaseAppId = _Env.firebaseAppId;

  @EnviedField(varName: 'FIREBASE_MESSAGING_SENDER_ID')
  static const String firebaseMessagingSenderId =
      _Env.firebaseMessagingSenderId;

  @EnviedField(varName: 'FIREBASE_PROJECT_ID')
  static const String firebaseProjectId = _Env.firebaseProjectId;

  @EnviedField(varName: 'FIREBASE_AUTH_DOMAIN')
  static const String firebaseAuthDomain = _Env.firebaseAuthDomain;

  @EnviedField(varName: 'FIREBASE_STORAGE_BUCKET')
  static const String firebaseStorageBucket = _Env.firebaseStorageBucket;

  @EnviedField(varName: 'FIREBASE_IOS_CLIENT_ID')
  static const String firebaseIosClientId = _Env.firebaseIosClientId;

  @EnviedField(varName: 'FIREBASE_IOS_BUNDLE_ID')
  static const String firebaseIosBundleId = _Env.firebaseIosBundleId;

  @EnviedField(varName: 'FIREBASE_ANDROID_CLIENT_ID')
  static const String firebaseAndroidClientId = _Env.firebaseAndroidClientId;

  @EnviedField(varName: 'FIREBASE_ANDROID_PACKAGE_NAME')
  static const String firebaseAndroidPackageName =
      _Env.firebaseAndroidPackageName;
}
