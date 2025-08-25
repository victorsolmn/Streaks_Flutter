import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _currentUserId;
  String? _error;
  
  // Mock database to store registered users
  static const String _registeredUsersKey = 'registered_users';

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
      
      // Check if user exists in our mock database
      final registeredUsers = await _getRegisteredUsers();
      final existingUser = registeredUsers.firstWhere(
        (user) => user['email'] == email,
        orElse: () => <String, dynamic>{},
      );
      
      if (existingUser.isEmpty) {
        throw Exception('No account found with this email. Please sign up first.');
      }
      
      // Mock password validation (in real app, this would be hashed)
      if (existingUser['password'] != password) {
        throw Exception('Incorrect password. Please try again.');
      }
      
      // Valid existing user - sign them in
      final userId = existingUser['userId'];
      final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
      
      await _prefs.setString('auth_token', token);
      await _prefs.setString('user_id', userId);
      await _prefs.setString('user_email', email);
      
      _isAuthenticated = true;
      _currentUserId = userId;
      
      _setLoading(false);
      notifyListeners();
      return true;
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
      
      // Check if all fields are provided
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        throw Exception('All fields are required');
      }
      
      // Check if user already exists
      final registeredUsers = await _getRegisteredUsers();
      final existingUser = registeredUsers.any((user) => user['email'] == email);
      
      if (existingUser) {
        throw Exception('An account with this email already exists. Please sign in instead.');
      }
      
      // Create new user
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
      
      // Add user to mock database
      await _addRegisteredUser({
        'userId': userId,
        'name': name,
        'email': email,
        'password': password, // In real app, this would be hashed
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      // Set authentication state
      await _prefs.setString('auth_token', token);
      await _prefs.setString('user_id', userId);
      await _prefs.setString('user_email', email);
      await _prefs.setString('user_name', name);
      
      _isAuthenticated = true;
      _currentUserId = userId;
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      // Clear authentication data
      await _prefs.remove('auth_token');
      await _prefs.remove('user_id');
      await _prefs.remove('user_email');
      await _prefs.remove('user_name');
      
      // Clear user profile data
      await _prefs.remove('user_profile');
      
      // Clear any other session-specific data
      await _prefs.remove('onboarding_completed');
      
      _isAuthenticated = false;
      _currentUserId = null;
      _error = null;
      
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
  
  // Mock database methods for user management
  Future<List<Map<String, dynamic>>> _getRegisteredUsers() async {
    final usersJson = _prefs.getString(_registeredUsersKey);
    if (usersJson == null) return [];
    
    final List<dynamic> usersList = jsonDecode(usersJson);
    return usersList.cast<Map<String, dynamic>>();
  }
  
  Future<void> _addRegisteredUser(Map<String, dynamic> user) async {
    final users = await _getRegisteredUsers();
    users.add(user);
    await _prefs.setString(_registeredUsersKey, jsonEncode(users));
  }
  
  // Helper method to check if email exists (can be used by UI)
  Future<bool> checkEmailExists(String email) async {
    final users = await _getRegisteredUsers();
    return users.any((user) => user['email'] == email);
  }
}