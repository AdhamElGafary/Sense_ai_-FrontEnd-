import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'utils/route_utils.dart';
import 'views/auth/login_screen.dart';
import 'views/chat_screen.dart';
import 'views/onboarding_screen.dart';

// Global navigator key for app-wide navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global SharedPreferences instance for easy access
late SharedPreferences prefs;

void main() async {
  // Preserve splash screen until app is fully loaded
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize shared preferences
  prefs = await SharedPreferences.getInstance();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _hasSeenOnboarding = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Check initialization status
    _checkOnboardingStatus();

    // Add a slight delay to ensure assets are loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      // Remove splash screen when the app is ready
      FlutterNativeSplash.remove();
    });
  }

  void _checkOnboardingStatus() {
    setState(() {
      _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      _isInitialized = true;
    });
  }

  void _onFinishOnboarding() {
    setState(() {
      _hasSeenOnboarding = true;
    });
    // Also save the preference
    prefs.setBool('hasSeenOnboarding', true);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    final authState = ref.watch(authProvider);

    // Check if auth is still initializing and show appropriate UI
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey, // Use global navigator key
          title: 'Sense AI',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.transparent,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF050133),
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            platform: TargetPlatform.android,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.transparent,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF050133),
              brightness: Brightness.dark,
            ),
          ),

          // Show appropriate screen based on onboarding and auth state
          home: _determineHomeScreen(authState),

          // Define named routes for navigation
          routes: {
            '/login': (context) => const LoginScreen(),
            '/chat': (context) => const ChatScreen(),
          },

          // Route generator for path-based navigation that respects auth state
          onGenerateRoute:
              (settings) => RouteUtils.onGenerateRoute(settings, context, ref),

          // Redirect if user navigates to undefined route
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder:
                  (_) =>
                      authState.isAuthenticated
                          ? const ChatScreen()
                          : const LoginScreen(),
            );
          },
        );
      },
    );
  }

  Widget _determineHomeScreen(AuthState authState) {
    // First check if user has seen onboarding
    if (!_hasSeenOnboarding) {
      return OnboardingScreen(onFinish: _onFinishOnboarding);
    }

    // If user has seen onboarding, check auth state
    // Show loading indicator while auth is loading
    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Then check authentication status
    return authState.isAuthenticated ? const ChatScreen() : const LoginScreen();
  }
}
