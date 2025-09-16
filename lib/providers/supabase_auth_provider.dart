import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class SupabaseAuthProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  bool _isLoading = false;
  String? _error;
  User? _currentUser;
  
  SupabaseAuthProvider() {
    _initializeAuth();
  }

  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _currentUser;
  String? get currentUserId => _currentUser?.id;

  void _initializeAuth() {
    _currentUser = _supabaseService.currentUser;
    
    // Listen to auth state changes
    _supabaseService.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      _currentUser = session?.user;
      notifyListeners();
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Sign up with email and password
  Future<bool> signUpWithPassword(String email, String password, String name) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _supabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      
      if (response.user != null) {
        _currentUser = response.user;

        // Ensure user profile exists (in case database trigger failed)
        await _ensureUserProfileExists(response.user!);

        _setLoading(false);
        return true;
      } else {
        _setError('Failed to create account');
        _setLoading(false);
        return false;
      }
    } on AuthException catch (e) {
      if (e.message.contains('User already registered')) {
        _setError('An account with this email already exists');
      } else if (e.message.contains('Database error granting user')) {
        _setError('Account creation service temporarily unavailable. Please try again in a moment.');
      } else {
        _setError(e.message);
      }
      _setLoading(false);
      return false;
    } catch (e) {
      if (e.toString().contains('Database error granting user')) {
        _setError('Account creation service temporarily unavailable. Please try again in a moment.');
      } else {
        _setError('Failed to create account. Please try again.');
      }
      _setLoading(false);
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signInWithPassword(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _supabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = response.user;

        // Check if user profile exists, create if not
        await _ensureUserProfileExists(response.user!);

        _setLoading(false);
        return true;
      } else {
        _setError('Invalid email or password');
        _setLoading(false);
        return false;
      }
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        _setError('Invalid email or password');
      } else if (e.message.contains('Database error granting user')) {
        // This is likely a database trigger/profile creation issue
        // Let's try to handle it gracefully
        _setError('Authentication service temporarily unavailable. Please try again in a moment.');
      } else {
        _setError(e.message);
      }
      _setLoading(false);
      return false;
    } catch (e) {
      if (e.toString().contains('Database error granting user')) {
        _setError('Authentication service temporarily unavailable. Please try again in a moment.');
      } else {
        _setError('Failed to sign in. Please try again.');
      }
      _setLoading(false);
      return false;
    }
  }

  // Legacy OTP method - kept for compatibility
  Future<bool> sendOTP(String email, {bool isSignUp = false}) async {
    // Redirect to password auth
    if (isSignUp) {
      _setError('Please use the Sign Up screen');
    } else {
      _setError('Please use the Sign In screen');
    }
    return false;
  }

  // Verify OTP and complete authentication
  Future<bool> verifyOTP(String email, String otp, {String? name}) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _supabaseService.client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );
      
      if (response.user != null) {
        _currentUser = response.user;
        
        // If name is provided (signup), update user profile
        if (name != null && name.isNotEmpty) {
          await _supabaseService.client.auth.updateUser(
            UserAttributes(data: {'name': name}),
          );
        }
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        throw Exception('OTP verification failed');
      }
    } on AuthException catch (e) {
      _setError(e.message == 'Token has expired or is invalid' 
        ? 'Invalid or expired OTP. Please request a new one.'
        : e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Invalid OTP. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);

    try {
      if (kDebugMode) {
        print('🔐 Starting Google OAuth sign-in...');
        print('📱 Redirect URL: com.streaker.streaker://callback');
        print('🔍 Current auth state before OAuth: ${_supabaseService.client.auth.currentSession?.user?.email ?? "None"}');
      }

      final response = await _supabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.streaker.streaker://callback',
        scopes: 'email profile',
      );

      if (kDebugMode) {
        print('📨 OAuth response received: $response');
        print('🔍 Auth state immediately after OAuth: ${_supabaseService.client.auth.currentSession?.user?.email ?? "None"}');
      }

      if (!response) {
        if (kDebugMode) {
          print('❌ Google sign-in was cancelled by user');
        }
        throw Exception('Google sign in was cancelled');
      }

      if (kDebugMode) {
        print('✅ OAuth initiated successfully, waiting for callback...');
        print('🔍 Listening to auth state changes...');
      }

      // Listen for auth state changes for a limited time
      bool authCompleted = false;
      final authSubscription = _supabaseService.client.auth.onAuthStateChange.listen((data) {
        if (kDebugMode) {
          print('🔄 Auth state change detected: ${data.event}');
          print('🔍 Session: ${data.session?.user?.email ?? "None"}');
          print('🔍 User metadata: ${data.session?.user?.userMetadata}');
        }

        if (data.session != null && data.session!.user != null) {
          authCompleted = true;
          _currentUser = data.session!.user;
        }
      });

      // Wait for up to 10 seconds for the callback
      int attempts = 0;
      while (!authCompleted && attempts < 20) { // 10 seconds total
        await Future.delayed(Duration(milliseconds: 500));
        attempts++;

        // Check current user status
        final currentUser = _supabaseService.currentUser;
        if (currentUser != null) {
          if (kDebugMode) {
            print('🎉 User session detected during wait: ${currentUser.email}');
          }
          authCompleted = true;
          _currentUser = currentUser;
          break;
        }

        if (kDebugMode && attempts % 4 == 0) {
          print('⏳ Still waiting for callback... (${attempts * 500}ms)');
        }
      }

      authSubscription.cancel();

      if (authCompleted && _currentUser != null) {
        if (kDebugMode) {
          print('🎉 Google sign-in successful! User: ${_currentUser!.email}');
          print('🔍 User ID: ${_currentUser!.id}');
          print('🔍 User metadata: ${_currentUser!.userMetadata}');
        }

        // Ensure user profile exists
        await _ensureUserProfileExists(_currentUser!);

        _setLoading(false);
        return true;
      } else {
        if (kDebugMode) {
          print('⚠️ OAuth callback timeout - no user session found after 10 seconds');
          print('🔍 Final auth check: ${_supabaseService.currentUser?.email ?? "None"}');
        }
      }

      throw Exception('Authentication completed but no user session was created');

    } on AuthException catch (e) {
      if (kDebugMode) {
        print('❌ Supabase Auth Exception: ${e.message}');
        print('🔍 Auth exception details: ${e.toString()}');
      }
      _setError('Google sign-in failed: ${e.message}');
      _setLoading(false);
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Google sign-in error: $e');
        print('🔍 Error type: ${e.runtimeType}');
      }
      _setError('Google sign in failed. Please check your internet connection and try again.');
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setError(null);

    try {
      await _supabaseService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      // Even on error, clear the user
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    _setLoading(true);
    _setError(null);

    try {
      await _supabaseService.resetPassword(email);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper method to ensure user profile exists
  Future<void> _ensureUserProfileExists(User user) async {
    try {
      // Check if profile exists
      final existingProfile = await _supabaseService.getUserProfile(user.id);

      if (existingProfile == null) {
        // Profile doesn't exist, create it
        await _supabaseService.createUserProfile(
          userId: user.id,
          email: user.email ?? '',
          name: user.userMetadata?['name'] ?? user.userMetadata?['full_name'] ?? '',
        );
      }
    } catch (e) {
      // Log the error but don't fail the authentication
      print('Warning: Could not ensure user profile exists: $e');
    }
  }
}