import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/supabase_auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_service.dart';
import '../../services/toast_service.dart';
import '../../services/popup_service.dart';
import '../../utils/app_theme.dart';
import '../onboarding/supabase_onboarding_screen.dart';
import 'signin_screen.dart';
import 'otp_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


  /// Sign up method with password
  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_agreeToTerms) {
      ToastService().showError('Please agree to the Terms & Privacy Policy');
      return;
    }

    final email = _emailController.text.trim();
    final name = _nameController.text.trim();

    try {
      // Skip email existence check since we're using password auth workaround
      // The auth provider will handle duplicate users

      final authProvider = Provider.of<SupabaseAuthProvider>(context, listen: false);
      
      ToastService().showLoading('Creating account...');
      
      final success = await authProvider.signUpWithPassword(
        email,
        _passwordController.text,
        name,
      );

      if (success && mounted) {
        ToastService().showSuccess('Account created successfully!');

        // CRITICAL: Wait for auth session to be fully established
        await Future.delayed(const Duration(milliseconds: 500));

        // Verify auth state is available
        final supabase = Supabase.instance.client;
        final currentSession = supabase.auth.currentSession;
        final currentUser = supabase.auth.currentUser;

        print('🔍 Auth check after signup:');
        print('  - Session: ${currentSession != null ? "Active" : "None"}');
        print('  - User ID: ${currentUser?.id ?? "None"}');

        // Since we're using password auth, go directly to onboarding
        // Store the name in the user profile
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.reloadUserData();

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const SupabaseOnboardingScreen(),
          ),
        );
      } else if (mounted && authProvider.error != null) {
        ToastService().showError(authProvider.error!);
      }

    } catch (e) {
      if (mounted) {
        PopupService.showNetworkError(
          context,
          onRetry: () => _signUp(),
          customMessage: 'Failed to send verification code. Please check your connection and try again.',
        );
      }
    }
  }
  
  Future<void> _signUpWithGoogle() async {
    if (!_agreeToTerms) {
      ToastService().showError('Please agree to the Terms & Privacy Policy');
      return;
    }
    
    final authProvider = Provider.of<SupabaseAuthProvider>(context, listen: false);
    
    ToastService().showLoading('Signing up with Google...');
    
    final success = await authProvider.signInWithGoogle();
    
    if (success && mounted) {
      ToastService().showSuccess('Welcome to Streaker! 🎉');
      
      // Navigate to onboarding for new users
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const SupabaseOnboardingScreen(),
        ),
      );
    } else if (mounted && authProvider.error != null) {
      ToastService().showError(authProvider.error!);
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize toast service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ToastService().initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Sign Up'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Consumer<SupabaseAuthProvider>(
          builder: (context, auth, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Center(
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: SvgPicture.asset(
                          'assets/images/streaker_logo.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Header
                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start your fitness journey today',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Confirm password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    
                    
                    SizedBox(height: 32),
                    
                    // Terms and conditions
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreeToTerms = value ?? false;
                            });
                          },
                          activeColor: AppTheme.primaryAccent,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodySmall,
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: TextStyle(
                                      color: AppTheme.primaryAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: AppTheme.primaryAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Error message
                    if (auth.error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.errorRed.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppTheme.errorRed,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                auth.error!,
                                style: TextStyle(
                                  color: AppTheme.errorRed,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                    
                    // Sign up button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: auth.isLoading ? null : _signUp,
                        icon: Icon(Icons.person_add),
                        label: auth.isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              )
                            : Text('Sign Up'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // OR divider
                    Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Google Sign Up button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: auth.isLoading ? null : _signUpWithGoogle,
                        icon: Image.network(
                          'https://www.google.com/favicon.ico',
                          height: 20,
                          width: 20,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.g_mobiledata,
                            size: 20,
                          ),
                        ),
                        label: Text('Continue with Google'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Sign in link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const SignInScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Sign In',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primaryAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}