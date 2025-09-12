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
      } else {
        _setError(e.message);
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to create account. Please try again.');
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
      } else {
        _setError(e.message);
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to sign in. Please try again.');
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
      }

      final response = await _supabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.streaker.streaker://callback',
        scopes: 'email profile',
      );
      
      if (kDebugMode) {
        print('📨 OAuth response received: $response');
      }
      
      if (!response) {
        if (kDebugMode) {
          print('❌ Google sign-in was cancelled by user');
        }
        throw Exception('Google sign in was cancelled');
      }
      
      if (kDebugMode) {
        print('✅ OAuth initiated successfully, waiting for callback...');
      }
      
      // Wait a bit for the auth state to update via deep link
      await Future.delayed(Duration(seconds: 2));
      
      // Check if user is now authenticated
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        if (kDebugMode) {
          print('🎉 Google sign-in successful! User: ${currentUser.email}');
        }
        _currentUser = currentUser;
        _setLoading(false);
        return true;
      } else {
        if (kDebugMode) {
          print('⚠️ OAuth callback completed but no user session found');
        }
        // Give it a bit more time for the callback to complete
        await Future.delayed(Duration(seconds: 3));
        
        final retryUser = _supabaseService.currentUser;
        if (retryUser != null) {
          _currentUser = retryUser;
          _setLoading(false);
          return true;
        }
      }
      
      throw Exception('Authentication completed but no user session was created');
      
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('❌ Supabase Auth Exception: ${e.message}');
      }
      _setError('Google sign-in failed: ${e.message}');
      _setLoading(false);
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Google sign-in error: $e');
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
}