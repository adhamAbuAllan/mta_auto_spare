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
            colors: [Color(0xFF111827), Color(0xFF1F2937), Color(0xFFF4F6F8)],
            stops: [0, 0.32, 0.32],
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
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A101828),
                        blurRadius: 24,
                        offset: Offset(0, 10),
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
                              foregroundColor: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            context.l10n.appTitle,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF111827),
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            context.l10n.signInToBrowseSellerRequests,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: const Color(0xFF667085),
                                  height: 1.35,
                                ),
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
                              child: Text(context.l10n.forgotPassword),
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
