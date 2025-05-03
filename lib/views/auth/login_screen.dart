import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/auth_validators.dart';
import '../widgets/app_logo.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';
import '../chat_screen.dart';
import 'register_screen.dart';
import '../../main.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _errorMessage = null;
      });

      // Show loading overlay
      LoadingOverlay.show(context, message: 'Signing in...');

      try {
        final success = await ref
            .read(authProvider.notifier)
            .login(_usernameController.text.trim(), _passwordController.text);

        if (!mounted) return;

        if (success) {
          // Navigate first, then hide overlay for smoother transition
          navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          );

          // Hide loading overlay after navigation is initiated
          LoadingOverlay.hide();
        } else {
          // Hide loading overlay immediately for failed login
          LoadingOverlay.hide(context);

          final authState = ref.read(authProvider);
          setState(() {
            _errorMessage =
                authState.errorMessage ?? "Login failed. Please try again.";
          });
        }
      } catch (e) {
        if (mounted) {
          // Hide loading overlay on error
          LoadingOverlay.hide(context);
          setState(() {
            _errorMessage = "An unexpected error occurred. Please try again.";
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.primaryGradient,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Logo
                    AppLogo(size: LogoSize.medium, useDarkModeEffects: true),
                    SizedBox(height: 20.h),
                    // Welcome Text
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Sign in to continue',
                      style: TextStyle(fontSize: 16.sp, color: Colors.white70),
                    ),
                    SizedBox(height: 30.h),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Username Field
                              CustomTextField(
                                controller: _usernameController,
                                hintText: 'Enter your username',
                                prefixIcon: Icons.person_outline,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.text,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your username';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20.h),
                              // Password Field
                              CustomTextField(
                                controller: _passwordController,
                                hintText: 'Enter your password',
                                obscureText: _obscurePassword,
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _login(),
                                validator:
                                    (value) =>
                                        AuthValidators.validatePassword(value),
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (val) {
                                          setState(() {
                                            _rememberMe = val ?? false;
                                          });
                                        },
                                        activeColor: Colors.white,
                                        checkColor:
                                            AppColors.primaryGradient.first,
                                      ),
                                      Text(
                                        'Remember Me',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // TODO: Implement forgot password navigation
                                    },
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.sp,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Error Message
                              if (_errorMessage != null)
                                Padding(
                                  padding: EdgeInsets.only(top: 16.h),
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red[300],
                                      fontSize: 14.sp,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              SizedBox(height: 30.h),
                              // Login Button
                              CustomButton(
                                text: 'Sign In',
                                onPressed: _login,
                                isLoading: isLoading,
                              ),
                              SizedBox(height: 24.h),
                              // Register Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Don\'t have an account?',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
