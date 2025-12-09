import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signInWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

      if (mounted) {
        final user = ref.read(firebaseAuthProvider).currentUser;
        if (user != null) {
          final profile =
              await ref.read(authRepositoryProvider).getUserProfile(user.uid);
          if (mounted) {
            if (profile != null) {
              context.go('/home');
            } else {
              context.go('/setup-profile');
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).createUserWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

      if (mounted) {
        context.go('/setup-profile');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to user profile changes
    ref.listen(userProfileProvider, (previous, next) {
      if (!next.isLoading && !next.hasError) {
        if (next.value != null) {
          context.go('/home');
        } else {
          final authState = ref.read(authStateProvider);
          if (authState.value != null) {
            context.go('/setup-profile');
          }
        }
      }
    });

    final size = MediaQuery.of(context).size;
    final isWebLayout = size.width > 900;
    final theme = Theme.of(context);

    // Common Form Widget
    Widget buildLoginForm() {
      return Container(
        width: isWebLayout ? 400 : double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: isWebLayout
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
                ],
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              'DUS Case Camp',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome Back',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style:
                      TextStyle(color: theme.colorScheme.error, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 32),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _signUp,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: theme.primaryColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Create Account'),
                  ),
                ],
              ),
          ],
        ),
      );
    }

    if (isWebLayout) {
      return Scaffold(
        body: Row(
          children: [
            // Left Side: Branding Image
            Expanded(
              flex: 6,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?q=80&w=2600&auto=format&fit=crop', // Dental/Medical Theme
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.primaryColor.withOpacity(0.8),
                        Colors.black.withOpacity(0.4),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.medical_services_outlined,
                          size: 64, color: Colors.white),
                      const SizedBox(height: 24),
                      Text(
                        'Master Dental Cases\nwith Confidence.',
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Join thousands of students and professionals enhancing their clinical skills with interactive case studies.',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),

            // Right Side: Login Form
            Expanded(
              flex: 4,
              child: Container(
                color: Colors.grey[50],
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: buildLoginForm(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile Layout
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: theme.primaryColor),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: buildLoginForm(),
          ),
        ),
      ),
    );
  }
}
