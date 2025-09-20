// presentation/screens/auth/sign_in_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class SignInScreen extends StatefulWidget {
  final String? redirectTo;
  const SignInScreen({super.key, this.redirectTo});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isDisposed = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _isDisposed = true;
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isDisposed) return;

    if (mounted && !_isDisposed) {
      setState(() => _isLoading = true);
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted && !_isDisposed) {
        final target = widget.redirectTo;
        if (target != null && target.isNotEmpty) {
          context.go(target);
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing in: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Sign In'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Header
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Sign in to continue your civic journey and make a difference in your community.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.mediumGray,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 40),

                // Email Field
                Text(
                  'Email Address',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Password Field
                Text(
                  'Password',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(
                      Icons.lock_outlined,
                      color: AppTheme.mediumGray,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.mediumGray,
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
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Sign Up Link
                Center(
                  child: TextButton(
                    onPressed: () {
                      context.go('/welcome');
                    },
                    child: const Text(
                      'Don\'t have an account? Sign Up',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
