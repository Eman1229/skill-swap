import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:skill_swap/screens/reset/Reset%20Password.dart';
import 'package:skill_swap/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  static const _channel = MethodChannel('com.example.skill_swap/deeplink');


  final _appLinks = AppLinks();
  StreamSubscription? _linkSub;

  @override
  void initState() {
    super.initState();
    _getInitialLink();
    _listenToLinks();
  }

  void _getInitialLink() async {
    try {
      final link = await _channel.invokeMethod<String>('getInitialLink');
      if (link != null) {
        final uri = Uri.parse(link);
        _handleDeepLink(uri);
      }
    } catch (e) {
      print('Deep link error: $e');
    }

    // ✅ ADDED — also check via app_links for cold start
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      print('app_links initial error: $e');
    }
  }

  // ✅ ADDED — listens when app is already open or resumed
  void _listenToLinks() {
    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (e) {
      print('app_links stream error: $e');
    });
  }

  void _handleDeepLink(Uri uri) {
    final mode = uri.queryParameters['mode'];
    final oobCode = uri.queryParameters['oobCode'];

    if (mode == 'resetPassword' && oobCode != null && oobCode.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => NewPasswordScreen(oobCode: oobCode),
          ),
              (route) => false,
        );
      });
    }
  }

  // ✅ ADDED
  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: SplashScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SkillSwap"),
      ),
      body: const Center(),
    );
  }
}