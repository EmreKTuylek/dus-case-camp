import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class SetupProfileScreen extends ConsumerStatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  ConsumerState<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends ConsumerState<SetupProfileScreen> {
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _yearController = TextEditingController();
  UserRole _role = UserRole.student;
  bool _isLoading = false;

  Future<void> _saveProfile() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newUser = UserModel(
        id: user.uid,
        fullName: _nameController.text.trim(),
        email: user.email!,
        role: _role,
        school: _schoolController.text.trim().isEmpty ? null : _schoolController.text.trim(),
        yearOfStudy: int.tryParse(_yearController.text.trim()),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(authRepositoryProvider).createUserProfile(newUser);
      
      // Force refresh of user profile provider
      ref.invalidate(userProfileProvider);
      
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
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
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _role = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _schoolController,
                decoration: const InputDecoration(labelText: 'School / University (Optional)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Year of Study (Optional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save & Continue'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
