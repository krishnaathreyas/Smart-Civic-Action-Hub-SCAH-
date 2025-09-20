// presentation/screens/onboarding/profile_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _wardController = TextEditingController();

  bool _isLoading = false;
  bool _isDisposed = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _isDisposed = true;
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _wardController.dispose();
    super.dispose();
  }

  void _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isDisposed) return;

    if (mounted && !_isDisposed) {
      setState(() => _isLoading = true);
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await authProvider.createProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        homeAddress: _addressController.text.trim(),
        municipalWard: _wardController.text.trim(),
      );

      if (mounted && !_isDisposed) {
        context.go('/tutorial');
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating profile: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      // Always check mounted and disposed before calling setState
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Your Profile'),
        centerTitle: true,
      ),
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
                  'Tell us about yourself',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Your profile helps us verify your location and build trust in the community.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.mediumGray,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 32),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
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
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 20),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'your.email@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                    helperText: 'We\'ll use this for sign-in',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 20),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Create a secure password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 20),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 20),

                // Phone Field (Optional)
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    hintText: '+1 234 567 8900',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (value.trim().length < 10) {
                        return 'Please enter a valid phone number';
                      }
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 20),

                // Home Address Field
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Home Address',
                    hintText: '123 Main St, City, State',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your home address';
                    }
                    if (value.trim().length < 10) {
                      return 'Please enter a complete address';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 20),

                // Municipal Ward Field
                TextFormField(
                  controller: _wardController,
                  decoration: const InputDecoration(
                    labelText: 'Municipal Ward/District',
                    hintText: 'Ward 5, District A',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your municipal ward or district';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submitProfile(),
                ),

                const SizedBox(height: 40),

                // Privacy Notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.privacy_tip_outlined,
                        color: AppTheme.primaryBlue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your information is kept private and secure. We only use your location to verify your eligibility to vote on local issues.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.darkGray, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Create Profile Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitProfile,
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
                            'Create Profile',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Sign In Link
                Center(
                  child: TextButton(
                    onPressed: () {
                      context.go('/sign-in');
                    },
                    child: const Text(
                      'Already have an account? Sign In',
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
