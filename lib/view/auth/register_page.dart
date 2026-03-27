import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/auth_provider.dart';
import '../../controllers/statuses/auth_state.dart';
import '../common_widgets/app_error_card.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'user';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registerNotifierProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(registerNotifierProvider, (previous, next) {
      final justRegistered =
          next.registeredUser != null &&
          previous?.registeredUser?.id != next.registeredUser?.id;
      if (!justRegistered) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account created for ${next.registeredUser!.username}. You can sign in now.',
          ),
        ),
      );
      ref.read(registerNotifierProvider.notifier).reset();
      Navigator.of(context).pop();
    });

    final registerState = ref.watch(registerNotifierProvider);
    final emailController = ref.watch(registerEmailControllerProvider);
    final usernameController = ref.watch(registerUsernameControllerProvider);
    final nameController = ref.watch(registerNameControllerProvider);
    final passwordController = ref.watch(registerPasswordControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set up your marketplace profile',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Suppliers can post requests, and users can browse requests and start conversations.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF6F6A63),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Account role',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: 'user',
                          label: Text('User'),
                          icon: Icon(Icons.shopping_bag_outlined),
                        ),
                        ButtonSegment<String>(
                          value: 'supplier',
                          label: Text('Supplier'),
                          icon: Icon(Icons.storefront_outlined),
                        ),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (selection) {
                        setState(() => _selectedRole = selection.first);
                      },
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        hintText: 'Mona Ibrahim',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your full name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: emailController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'mona@example.com',
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) {
                          return 'Enter your email.';
                        }
                        if (!email.contains('@')) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'mona_ksa',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Choose a username.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'At least 6 characters',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter a password.';
                        }
                        if (value.length < 6) {
                          return 'Use at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                    if (registerState.hasError) ...[
                      const SizedBox(height: 16),
                      AppErrorCard(message: registerState.errorMessage!),
                    ],
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: registerState.isLoading ? null : _submit,
                            child: Text(
                              registerState.isLoading
                                  ? 'Creating...'
                                  : 'Create Account',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ref
        .read(registerNotifierProvider.notifier)
        .register(
          email: ref.read(registerEmailControllerProvider).text.trim(),
          username: ref.read(registerUsernameControllerProvider).text.trim(),
          name: ref.read(registerNameControllerProvider).text.trim(),
          password: ref.read(registerPasswordControllerProvider).text,
          role: _selectedRole,
        );
  }
}
