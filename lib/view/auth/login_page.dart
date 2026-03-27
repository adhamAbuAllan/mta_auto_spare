import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/api_constants.dart';
import '../../controllers/providers/auth_provider.dart';
import '../common_widgets/app_error_card.dart';
import 'register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginNotifierProvider);
    final usernameController = ref.watch(loginUsernameControllerProvider);
    final passwordController = ref.watch(loginPasswordControllerProvider);
    final isPasswordObscure = ref.watch(isPasswordObscureProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0C4A63), Color(0xFF116466), Color(0xFFF6F0E8)],
            stops: [0, 0.34, 0.34],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x180C2533),
                        blurRadius: 28,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auto Spare Hub',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sign in to browse seller requests, post your own request, and continue your chats.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: const Color(0xFF6F6A63)),
                          ),
                          const SizedBox(height: 24),
                          _InfoBanner(
                            title: 'Backend',
                            message: ApiConstants.baseUrl,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: usernameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              hintText: 'chat_user_a',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter your username.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: passwordController,
                            obscureText: isPasswordObscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Your password',
                              suffixIcon: IconButton(
                                onPressed: () {
                                  ref
                                          .read(
                                            isPasswordObscureProvider.notifier,
                                          )
                                          .state =
                                      !isPasswordObscure;
                                },
                                icon: Icon(
                                  isPasswordObscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            onFieldSubmitted: (_) => _submit(
                              username: usernameController.text,
                              password: passwordController.text,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter your password.';
                              }
                              return null;
                            },
                          ),
                          if (loginState.hasError) ...[
                            const SizedBox(height: 16),
                            AppErrorCard(message: loginState.errorMessage!),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: loginState.isLoading
                                  ? null
                                  : () => _submit(
                                      username: usernameController.text,
                                      password: passwordController.text,
                                    ),
                              child: Text(
                                loginState.isLoading
                                    ? 'Signing In...'
                                    : 'Sign In',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const RegisterPage(),
                                  ),
                                );
                              },
                              child: const Text('Create a New Account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit({required String username, required String password}) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ref
        .read(loginNotifierProvider.notifier)
        .login(username: username.trim(), password: password);
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5E8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6F6A63)),
          ),
        ],
      ),
    );
  }
}
