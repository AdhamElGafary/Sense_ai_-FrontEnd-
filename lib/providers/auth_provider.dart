import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../constants/api_constants.dart';

// User class to represent authenticated user
class User {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String? token;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    this.token,
  });

  // Convert user to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'email': email,
      'token': token,
    };
  }

  // Create user from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? json['profile']?['full_name'] ?? '',
      email: json['email'] ?? '',
      token: json['token'],
    );
  }
}

// Auth state to track authentication status
class AuthState {
  final bool isAuthenticated;
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.isAuthenticated = false,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Auth notifier to handle authentication logic
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    // Initialize by checking for stored user
    _initializeAuth();
  }

  // Constants for storage keys
  static const _userKey = 'auth_user';
  static const _authStatusKey = 'auth_status';
  static const _tokenKey = 'auth_token';

  // Create Dio instance
  final _dio =
      Dio()
        ..options.connectTimeout = const Duration(seconds: 30)
        ..options.receiveTimeout = const Duration(seconds: 30)
        ..options.responseType = ResponseType.json
        ..options.contentType = 'application/json';

  // Initialize authentication state from storage
  Future<void> _initializeAuth() async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuthenticated = prefs.getBool(_authStatusKey) ?? false;
      final token = prefs.getString(_tokenKey);

      if (isAuthenticated && token != null) {
        // Set auth header for all future requests using our custom token
        _dio.options.headers['Authorization'] = 'Bearer $token';

        final userJson = prefs.getString(_userKey);
        if (userJson != null) {
          final userData = jsonDecode(userJson);
          final user = User.fromJson(userData);

          state = state.copyWith(
            isAuthenticated: true,
            user: user,
            isLoading: false,
          );
          return;
        }
      }

      // No valid stored auth found
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Error during initialization
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize authentication',
      );
    }
  }

  // Save authentication state to storage
  Future<void> _saveAuthState(bool isAuthenticated, User? user) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_authStatusKey, isAuthenticated);

      if (user != null && isAuthenticated) {
        await prefs.setString(_userKey, jsonEncode(user.toJson()));
        if (user.token != null) {
          await prefs.setString(_tokenKey, user.token!);
          _dio.options.headers['Authorization'] = 'Bearer ${user.token}';
        }
      } else {
        await prefs.remove(_userKey);
        await prefs.remove(_tokenKey);
        _dio.options.headers.remove('Authorization');
      }
    } catch (e) {
      // Error handling is silent to prevent UI disruption
    }
  }

  // Handle API errors
  String _handleApiError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        // Try to get error message from response
        final data = error.response!.data;
        if (data is Map) {
          // Django REST Framework often returns errors in specific formats
          if (data.containsKey('message')) {
            return data['message'];
          } else if (data.containsKey('error')) {
            return data['error'];
          } else if (data.containsKey('detail')) {
            return data['detail'];
          } else if (data.containsKey('non_field_errors')) {
            // Django REST often puts validation errors here
            if (data['non_field_errors'] is List &&
                (data['non_field_errors'] as List).isNotEmpty) {
              return (data['non_field_errors'] as List).join(', ');
            }
          }

          // If we still haven't found an error message, look through all fields
          String errorMessages = '';
          data.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              errorMessages += '$key: ${value.join(', ')}; ';
            } else if (value is String) {
              errorMessages += '$key: $value; ';
            }
          });

          if (errorMessages.isNotEmpty) {
            return errorMessages;
          }
        }
        return 'Server error: ${error.response!.statusCode}';
      } else if (error.type == DioExceptionType.connectionTimeout) {
        return 'Connection timeout: Unable to reach the server';
      } else if (error.type == DioExceptionType.receiveTimeout) {
        return 'Response timeout: Server took too long to respond';
      } else if (error.type == DioExceptionType.connectionError) {
        return 'No internet connection: Please check your network';
      }
      return 'Network error: ${error.message}';
    }
    return 'Error: ${error.toString()}';
  }

  // Login with username and password
  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Create request exactly like Postman but with optimized settings
      var headers = {'Content-Type': 'application/json'};
      var data = jsonEncode({'username': username, 'password': password});

      var dio = Dio();
      // Faster timeouts for quicker response/failure
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);
      dio.options.sendTimeout = const Duration(seconds: 10);

      // Set faster response type handling
      dio.options.responseType = ResponseType.json;

      var response = await dio.request(
        ApiConstants.login,
        options: Options(
          method: 'POST',
          headers: headers,
          contentType: 'application/json',
        ),
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // Extract user data from response
        final userData = data['user'];
        if (userData == null) {
          throw Exception('User data not found in response');
        }

        // Generate a random token since backend doesn't provide one
        const uuid = Uuid();
        final token = uuid.v4(); // Generate a random UUID as token

        // Set token in headers for future API calls
        _dio.options.headers['Authorization'] = 'Bearer $token';

        // Create user from response using the new structure
        final user = User(
          id: userData['id']?.toString() ?? '',
          username: userData['username'] ?? '',
          fullName: userData['profile']?['full_name'] ?? '',
          email: userData['email'] ?? '',
          token: token, // Use our generated token
        );

        // Save auth state before updating UI state for faster perceived performance
        // Use a future that doesn't block the return
        _saveAuthState(true, user);

        // Update state with authenticated user
        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          isLoading: false,
        );

        return true;
      } else {
        throw Exception('Authentication failed: ${response.statusMessage}');
      }
    } catch (e) {
      final errorMessage = _handleApiError(e);

      // Update state with error
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: errorMessage,
      );

      return false;
    }
  }

  // Register new user
  Future<bool> register(
    String fullName,
    String username,
    String email,
    String password,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Create request exactly like Postman
      var headers = {'Content-Type': 'application/json'};

      var data = jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'password2': password,
        'full_name': fullName,
      });

      var dio = Dio();
      var response = await dio.request(
        ApiConstants.register,
        options: Options(method: 'POST', headers: headers),
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // After successful registration, don't automatically log in
        // Just return true so the UI can navigate to login screen
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        throw Exception('Registration failed: ${response.statusMessage}');
      }
    } catch (e) {
      final errorMessage = _handleApiError(e);

      // Update state with error
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: errorMessage,
      );

      return false;
    }
  }

  // Logout user - simplified synchronous version
  void logout() {
    try {
      // Clear the auth state
      state = AuthState();

      // Clear token from Dio headers
      _dio.options.headers.remove('Authorization');

      // Clear SharedPreferences in the background
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove(_userKey);
        prefs.remove(_authStatusKey);
        prefs.remove(_tokenKey);
      });
    } catch (e) {
      // Even if there's an error, ensure the user is logged out
      state = AuthState();
    }
  }

  // Get current user details
  Future<bool> getCurrentUser() async {
    if (!state.isAuthenticated || state.user?.token == null) {
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      // We're using a custom token, so we need to add it to the headers
      final response = await _dio.get(
        ApiConstants.currentUser,
        options: Options(
          headers: {'Authorization': 'Bearer ${state.user?.token}'},
        ),
      );

      if (response.statusCode == 200) {
        final userData = response.data;

        // Update user data, handling the profile structure
        // Keep using the same token we generated at login
        final updatedUser = User(
          id: userData['id']?.toString() ?? state.user!.id,
          username: userData['username'] ?? state.user!.username,
          fullName: userData['profile']?['full_name'] ?? state.user!.fullName,
          email: userData['email'] ?? state.user!.email,
          token: state.user!.token, // Keep the existing token
        );

        state = state.copyWith(user: updatedUser, isLoading: false);

        // Save updated user info
        await _saveAuthState(true, updatedUser);

        return true;
      } else {
        throw Exception('Failed to get user details');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }
}

// Provider for auth state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
