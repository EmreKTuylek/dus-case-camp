import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userProfile = ref.watch(userProfileProvider);

    // Listen to state changes to navigate
    // Listen to auth state changes
    ref.listen(authStateProvider, (previous, next) {
      if (!next.isLoading && !next.hasError) {
        if (next.value == null) {
          context.go('/login');
        }
      }
    });

    // Listen to user profile changes
    ref.listen(userProfileProvider, (previous, next) {
      if (!next.isLoading && !next.hasError) {
        if (next.value != null) {
          context.go('/home');
        } else {
          // Check if we are actually logged in before sending to setup-profile
          // Because userProfile is null if authState is null too (see provider)
          final authState = ref.read(authStateProvider);
          if (authState.value != null) {
            context.go('/setup-profile');
          }
        }
      }
    });

    if (authState.hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Initialization Error',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Error: ${authState.error}', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Go to Login (Try anyway)'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services, size: 80, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'DUS Case Camp',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Weekly case camp for dentistry students'),
            SizedBox(height: 32),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
