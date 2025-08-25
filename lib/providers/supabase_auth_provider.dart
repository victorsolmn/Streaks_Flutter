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

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        _currentUser = response.user;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        throw Exception('Sign in failed - no user returned');
      }
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        name: name,
      );
      
      if (response.user != null) {
        _currentUser = response.user;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        throw Exception('Sign up failed - no user returned');
      }
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _setError(null);

    try {
      await _supabaseService.signOut();
      _currentUser = null;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
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