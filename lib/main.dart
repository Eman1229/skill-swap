import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_swap/firebase_options.dart';
import 'package:skill_swap/l10n/app_localizations.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/screens/splash/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skill_swap/services/presence_service.dart';
import 'package:skill_swap/services/fcm_service.dart';
import 'package:skill_swap/screens/Setting/app_settings.dart';

const Color _skillSwapPrimary = Color(0xFF00C2FF); // Cyan Blue
const Color _skillSwapSecondary = Color(0xFF00C2FF); // Use Cyan for system-wide secondary
const Color _skillSwapBackground = Color(0xFFF0F4FF);
const Color _skillSwapText = Color(0xFF0D0D1A);
const Color _skillSwapSlate = Color(0xFFB0BAD0);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 🔵 Firebase init
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Push Notifications (FCM)
    await FcmService().init();

    // Start presence tracking service
    PresenceService().start();

    // Enable Firestore offline persistence/caching
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // 🟣 Supabase init
    await Supabase.initialize(
      url: 'https://dvmqgwosltkmtltwfvpp.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2bXFnd29zbHRrbXRsdHdmdnBwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzMTg3NjcsImV4cCI6MjA5Mzg5NDc2N30.OlvpVDEcYSzm8C-hu-JYTh-bjgLVoK1JajmrQMsDULY',
    );

    final languageProvider = LanguageProvider.instance;
    await languageProvider.loadSavedLocale();

    runApp(
      ChangeNotifierProvider<LanguageProvider>.value(
        value: languageProvider,
        child: const MyApp(),
      ),
    );
  } catch (e) {
    debugPrint("Initialization Error: $e");
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text("Error initializing app: $e"))),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings();
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return ListenableBuilder(
          listenable: settings.isDarkMode,
          builder: (context, _) {
            return MaterialApp(
              navigatorKey: FcmService.navigatorKey,
              debugShowCheckedModeBanner: false,
              locale: languageProvider.locale,
              supportedLocales: LanguageProvider.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              onGenerateTitle: (context) => AppLocalizations.of(context)?.appTitle ?? 'Skill Swap',
              theme: _buildLightTheme(),
              darkTheme: _buildDarkTheme(),
              themeMode: settings.themeMode,
              themeAnimationDuration: const Duration(milliseconds: 250),
              themeAnimationCurve: Curves.easeInOut,
              builder: (context, child) {
                return Directionality(
                  textDirection: languageProvider.textDirection,
                  child: child!,
                );
              },
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _skillSwapPrimary,
      brightness: Brightness.light,
      primary: _skillSwapPrimary,
      secondary: _skillSwapSecondary,
      surface: Colors.white,
      onSurface: _skillSwapText,
      onSurfaceVariant: const Color(0xFF4B5870),
      outline: _skillSwapSlate,
      outlineVariant: const Color(0xFFD8E1F2),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _skillSwapBackground,
      fontFamily: 'Schyler',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _skillSwapText,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: _skillSwapText,
            displayColor: _skillSwapText,
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _skillSwapPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      switchTheme: _buildSwitchTheme(colorScheme),
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _skillSwapPrimary,
      brightness: Brightness.dark,
      primary: _skillSwapPrimary,
      secondary: _skillSwapSecondary,
      tertiary: _skillSwapPrimary,
      surface: const Color(0xFF1E293B),
      onSurface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      fontFamily: 'Schyler',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardColor: const Color(0xFF1E293B),
      switchTheme: _buildSwitchTheme(colorScheme),
    );
  }

  SwitchThemeData _buildSwitchTheme(ColorScheme colorScheme) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return colorScheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.outlineVariant;
      }),
    );
  }
}
