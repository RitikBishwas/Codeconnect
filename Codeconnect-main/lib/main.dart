import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:nitd_code/pages/home_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nitd_code/secret_manager.dart';
import 'package:nitd_code/ui/login_screen.dart';

// Firebase options for web
final firebaseConfig = FirebaseOptions(
  apiKey: dotenv.env['WEB_API_KEY']!,
  authDomain: dotenv.env['WEB_AUTH_DOMAIN']!,
  projectId: dotenv.env['WEB_PROJECT_ID']!,
  storageBucket: dotenv.env['WEB_STORAGE_BUCKET']!,
  messagingSenderId: dotenv.env['WEB_MESSAGING_SENDER_ID']!,
  appId: dotenv.env['WEB_APP_ID']!,
  measurementId: dotenv.env['WEB_MEASUREMENT_ID']!,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: getFirebaseOptions());
  // await SecretsManager().loadSecrets(); // ✅ AFTER Firebase is initialized
  runApp(const MyApp());
}

FirebaseOptions getFirebaseOptions() {
  if (kIsWeb) {
    return firebaseConfig;
  } else if (Platform.isAndroid) {
    return FirebaseOptions(
      apiKey: dotenv.env['ANDROID_API_KEY']!,
      appId: dotenv.env['ANDROID_APP_ID']!,
      projectId: dotenv.env['ANDROID_PROJECT_ID']!,
      storageBucket: dotenv.env['ANDROID_STORAGE_BUCKET']!,
      messagingSenderId: dotenv.env['ANDROID_MESSAGING_SENDER_ID']!,
    );
  } else if (Platform.isIOS) {
    return FirebaseOptions(
      apiKey: dotenv.env['IOS_API_KEY']!,
      appId: dotenv.env['IOS_APP_ID']!,
      projectId: dotenv.env['IOS_PROJECT_ID']!,
      storageBucket: dotenv.env['IOS_STORAGE_BUCKET']!,
      messagingSenderId: dotenv.env['IOS_MESSAGING_SENDER_ID']!,
      iosBundleId: dotenv.env['IOS_BUNDLE_ID']!,
    );
  } else if (Platform.isMacOS) {
    return FirebaseOptions(
      apiKey: dotenv.env['MACOS_API_KEY']!,
      appId: dotenv.env['MACOS_APP_ID']!,
      projectId: dotenv.env['MACOS_PROJECT_ID']!,
      storageBucket: dotenv.env['MACOS_STORAGE_BUCKET']!,
      messagingSenderId: dotenv.env['MACOS_MESSAGING_SENDER_ID']!,
      iosBundleId: dotenv.env['MACOS_BUNDLE_ID']!,
    );
  } else if (Platform.isWindows) {
    return FirebaseOptions(
      apiKey: dotenv.env['WINDOWS_API_KEY']!,
      appId: dotenv.env['WINDOWS_APP_ID']!,
      projectId: dotenv.env['WINDOWS_PROJECT_ID']!,
      storageBucket: dotenv.env['WINDOWS_STORAGE_BUCKET']!,
      messagingSenderId: dotenv.env['WINDOWS_MESSAGING_SENDER_ID']!,
      authDomain: dotenv.env['WINDOWS_AUTH_DOMAIN']!,
      measurementId: dotenv.env['WINDOWS_MEASUREMENT_ID'],
    );
  } else {
    throw UnsupportedError("Unsupported platform");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Code Connect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, userSnp) {
          if (userSnp.hasData) {
            return const HomePage();
          }
          return const LoginScreen();
        },
      ),
      // home: ScheduleInterviewPage(),
      // routes: {
      //   '/interview': (context) => ScheduleInterviewPage(), // ✅ Route added
      // },
    );
  }
}
