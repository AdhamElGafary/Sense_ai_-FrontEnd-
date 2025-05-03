import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart'; // Import for navigatorKey and prefs
import '../providers/auth_provider.dart';
import '../views/auth/login_screen.dart';
import '../views/chat_screen.dart';
import '../views/onboarding_screen.dart';

/// Navigation utilities for auth-based routing
class RouteUtils {
  /// Redirects to the appropriate screen based on authentication status
  static void redirectBasedOnAuth(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authProvider);
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!hasSeenOnboarding) {
      navigateToOnboarding(() {
        // After onboarding completion, navigate based on auth state
        if (authState.isAuthenticated) {
          navigateToChat();
        } else {
          navigateToLogin();
        }
      });
    } else if (authState.isAuthenticated) {
      navigateToChat();
    } else {
      navigateToLogin();
    }
  }

  /// Navigate to onboarding screen using global navigator key
  static void navigateToOnboarding(VoidCallback onFinish) {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => OnboardingScreen(onFinish: onFinish)),
      (route) => false,
    );
  }

  /// Navigate to login screen using global navigator key
  static void navigateToLogin() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Navigate to chat screen using global navigator key
  static void navigateToChat() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
      (route) => false,
    );
  }

  /// Comprehensive logout method that handles the entire logout process
  ///
  /// This method handles:
  /// 1. Clearing auth state via provider
  /// 2. Displaying user feedback
  /// 3. Navigating to login screen
  ///
  /// @param context The BuildContext for showing feedback
  /// @param ref The WidgetRef for accessing providers
  static void performLogout(BuildContext context, WidgetRef ref) {
    // Show immediate user feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logging out...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Execute logout through auth provider
    ref.read(authProvider.notifier).logout();

    // Navigate to login screen using global navigator
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Ensures users can only access authenticated routes when logged in
  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
    BuildContext context,
    WidgetRef ref,
  ) {
    final authState = ref.read(authProvider);
    final isAuthenticated = authState.isAuthenticated;

    // Check onboarding status with global prefs
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    // Define your routes and their authentication requirements here
    switch (settings.name) {
      case '/onboarding':
        return MaterialPageRoute(
          builder:
              (_) => OnboardingScreen(
                onFinish: () {
                  // After onboarding completion, navigate based on auth state
                  if (authState.isAuthenticated) {
                    navigateToChat();
                  } else {
                    navigateToLogin();
                  }
                },
              ),
        );
      case '/login':
        if (!hasSeenOnboarding) {
          return MaterialPageRoute(
            builder: (_) => OnboardingScreen(onFinish: () => navigateToLogin()),
          );
        }
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/chat':
        if (!hasSeenOnboarding) {
          return MaterialPageRoute(
            builder:
                (_) => OnboardingScreen(
                  onFinish:
                      () =>
                          isAuthenticated
                              ? navigateToChat()
                              : navigateToLogin(),
                ),
          );
        }
        if (!isAuthenticated) {
          // Redirect to login if trying to access authenticated route
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
        return MaterialPageRoute(builder: (_) => const ChatScreen());
      default:
        // Default route based on onboarding and auth status
        if (!hasSeenOnboarding) {
          return MaterialPageRoute(
            builder:
                (_) => OnboardingScreen(
                  onFinish:
                      () =>
                          isAuthenticated
                              ? navigateToChat()
                              : navigateToLogin(),
                ),
          );
        }
        if (isAuthenticated) {
          return MaterialPageRoute(builder: (_) => const ChatScreen());
        } else {
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
    }
  }
}
