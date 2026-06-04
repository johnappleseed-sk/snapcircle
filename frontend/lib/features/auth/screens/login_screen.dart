import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _showPlaceholder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.loginPlaceholder)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'SnapCircle',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share moments, follow friends, and keep your circle close.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata,
                onPressed: () => _showPlaceholder(context),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Continue with Facebook',
                icon: Icons.facebook,
                onPressed: () => _showPlaceholder(context),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Preview app shell'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
