import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.registerWithEmail(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && context.mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join SnapCircle',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  'Use email auth for local testing, demos, and production accounts.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (authProvider.errorMessage != null) ...[
                  const SizedBox(height: AppSizes.paddingLarge),
                  Text(
                    authProvider.errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.paddingLarge),
                AppTextField(
                  label: 'Name',
                  controller: _nameController,
                  enabled: !authProvider.isLoading,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) =>
                      (value?.trim().isEmpty ?? true) ? 'Name is required.' : null,
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  enabled: !authProvider.isLoading,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.alternate_email),
                  validator: _validateEmail,
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                AppTextField(
                  label: 'Password',
                  controller: _passwordController,
                  enabled: !authProvider.isLoading,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                  validator: _validatePassword,
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                AppButton(
                  label: 'Create account',
                  icon: Icons.person_add_alt_1,
                  isLoading: authProvider.isLoading,
                  onPressed: () => _register(context),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                TextButton(
                  onPressed: authProvider.isLoading ? null : () => context.pop(),
                  child: const Text('I already have an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }
    if (!email.contains('@')) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }
}
