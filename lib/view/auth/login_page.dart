import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/auth_provider.dart';
import '../../localization/app_localizations_x.dart';
import '../../localization/language_selector.dart';
import '../../utils/phone_number.dart';
import '../common_widgets/app_error_card.dart';
import '../common_widgets/privacy_policy_link.dart';
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
    final phoneController = ref.watch(loginPhoneControllerProvider);
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
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: AppLanguageMenuButton(
                              foregroundColor: const Color(0xFF0C4A63),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            context.l10n.appTitle,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            context.l10n.signInToBrowseSellerRequests,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: const Color(0xFF6F6A63)),
                          ),
                          const SizedBox(height: 24),
                          // _InfoBanner(
                          //   title: context.l10n.backend,
                          //   message: ApiConstants.baseUrl,
                          // ),
                          // const SizedBox(height: 20),
                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: context.l10n.phone,
                              hintText: authPhoneHintText,
                            ),
                            validator: (value) {
                              return authPhoneInputError(value ?? '');
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: passwordController,
                            obscureText: isPasswordObscure,
                            decoration: InputDecoration(
                              labelText: context.l10n.password,
                              hintText: context.l10n.passwordHint,
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
                              phone: phoneController.text,
                              password: passwordController.text,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return context.l10n.enterPassword;
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
                                      phone: phoneController.text,
                                      password: passwordController.text,
                                    ),
                              child: Text(
                                loginState.isLoading
                                    ? context.l10n.signingIn
                                    : context.l10n.signIn,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: loginState.isLoading
                                  ? null
                                  : () {
                                      // تم إيقاف الكود مؤقتاً لتخطي مشكلة الملف الناقص
                                      /*
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => PasswordResetPage(
                                            initialPhone: normalizePhoneForAuth(
                                              phoneController.text,
                                            ),
                                          ),
                                        ),
                                      );
                                      */
                                    },
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const RegisterPage(),
                                  ),
                                );
                              },
                              child: Text(context.l10n.createNewAccount),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const PrivacyPolicyLink(),
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

  void _submit({required String phone, required String password}) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ref
        .read(loginNotifierProvider.notifier)
        .login(phone: normalizePhoneForAuth(phone), password: password);
  }
}
