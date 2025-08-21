import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _currentUserId;
  String? _error;

  AuthProvider(this._prefs) {
    _loadAuthState();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> _loadAuthState() async {
    final token = _prefs.getString('auth_token');
    final userId = _prefs.getString('user_id');
    
    if (token != null && userId != null) {
      _isAuthenticated = true;
      _currentUserId = userId;
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock validation
      if (email.isNotEmpty && password.isNotEmpty) {
        final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
        
        await _prefs.setString('auth_token', token);
        await _prefs.setString('user_id', userId);
        await _prefs.setString('user_email', email);
        
        _isAuthenticated = true;
        _currentUserId = userId;
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        throw Exception('Invalid email or password');
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock validation
      if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
        final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
        
        await _prefs.setString('auth_token', token);
        await _prefs.setString('user_id', userId);
        await _prefs.setString('user_email', email);
        await _prefs.setString('user_name', name);
        
        _isAuthenticated = true;
        _currentUserId = userId;
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        throw Exception('All fields are required');
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await _prefs.remove('auth_token');
      await _prefs.remove('user_id');
      await _prefs.remove('user_email');
      await _prefs.remove('user_name');
      
      _isAuthenticated = false;
      _currentUserId = null;
      
      _setLoading(false);
      notifyListeners();
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