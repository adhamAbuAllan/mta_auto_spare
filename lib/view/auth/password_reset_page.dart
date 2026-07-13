import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_exception.dart';
import '../../controllers/providers/api_provider.dart';
import '../../firebase/firebase_bootstrap.dart';
import '../../localization/firebase_error_localizer.dart';
import '../../localization/app_localizations_x.dart';
import '../../utils/phone_number.dart';
import '../common_widgets/app_error_card.dart';

class PasswordResetPage extends ConsumerStatefulWidget {
  const PasswordResetPage({super.key, this.initialPhone = ''});

  final String initialPhone;

  @override
  ConsumerState<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends ConsumerState<PasswordResetPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();
  Timer? _resendTimer;
  String? _verificationId;
  int? _resendToken;
  int _secondsUntilResend = 0;
  bool _isSending = false;
  bool _isSubmitting = false;
  bool _isPasswordObscure = true;
  String? _errorMessage;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.initialPhone.trim();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isSending || _isSubmitting;
    final codeWasSent = _verificationId?.isNotEmpty ?? false;
    final canSubmitCode =
        !busy && codeWasSent && _codeController.text.trim().length >= 6;

    final statusMessage = _statusMessage ?? context.l10n.passwordResetIntro;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.resetPasswordTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.forgotPassword,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      statusMessage,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF6F6A63),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (busy) const LinearProgressIndicator(),
                    if (busy) const SizedBox(height: 18),
                    TextFormField(
                      controller: _phoneController,
                      enabled: !busy && !codeWasSent,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: context.l10n.phone,
                        hintText: authPhoneHintText,
                      ),
                      validator: (value) => authPhoneInputError(value ?? ''),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !busy && !codeWasSent,
                      obscureText: _isPasswordObscure,
                      decoration: InputDecoration(
                        labelText: context.l10n.newPassword,
                        hintText: context.l10n.passwordMinHint,
                        suffixIcon: IconButton(
                          onPressed: busy || codeWasSent
                              ? null
                              : () => setState(() {
                                  _isPasswordObscure = !_isPasswordObscure;
                                }),
                          icon: Icon(
                            _isPasswordObscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l10n.enterPassword;
                        }
                        if (value.length < 6) {
                          return context.l10n.passwordMinHint;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmPasswordController,
                      enabled: !busy && !codeWasSent,
                      obscureText: _isPasswordObscure,
                      decoration: InputDecoration(
                        labelText: context.l10n.confirmNewPassword,
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return context.l10n.passwordsDoNotMatch;
                        }
                        return null;
                      },
                    ),
                    if (!codeWasSent) ...[
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: busy
                              ? null
                              : () => unawaited(_startPhoneVerification()),
                          child: Text(
                            _isSending
                                ? context.l10n.sendingSms
                                : context.l10n.sendSmsCode,
                          ),
                        ),
                      ),
                    ],
                    if (codeWasSent) ...[
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _codeController,
                        enabled: !busy,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: context.l10n.smsCode,
                          hintText: '123456',
                          counterText: '',
                        ),
                        onChanged: (_) => setState(() {}),
                        onFieldSubmitted: (_) {
                          if (canSubmitCode) {
                            unawaited(_submitManualCode());
                          }
                        },
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: canSubmitCode
                              ? () => unawaited(_submitManualCode())
                              : null,
                          child: Text(
                            _isSubmitting
                                ? context.l10n.changingPassword
                                : context.l10n.verifyAndChangePassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: busy || _secondsUntilResend > 0
                              ? null
                              : () => unawaited(
                                  _startPhoneVerification(resend: true),
                                ),
                          child: Text(
                            _secondsUntilResend > 0
                                ? context.l10n.resendInSeconds(
                                    _secondsUntilResend,
                                  )
                                : context.l10n.resendCode,
                          ),
                        ),
                      ),
                    ],
                    if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      AppErrorCard(message: _errorMessage!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startPhoneVerification({bool resend = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    final phone = normalizePhoneForAuth(_phoneController.text);

    setState(() {
      _isSending = true;
      _errorMessage = null;
      _statusMessage = resend
          ? context.l10n.sendingNewVerificationCode
          : context.l10n.sendingVerificationCodeToPhone(phone);
    });

    try {
      await ensureFirebaseInitialized(throwOnError: true);
      final firebaseAuth = FirebaseAuth.instance;
      await firebaseAuth.setLanguageCode(
        languageCode.trim().isEmpty ? 'en' : languageCode.trim(),
      );
      await firebaseAuth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resend ? _resendToken : null,
        verificationCompleted: (credential) {
          if (!mounted || _isSubmitting) {
            return;
          }
          setState(() {
            _statusMessage =
                context.l10n.phoneVerifiedAutomaticallyChangingPassword;
          });
          unawaited(_submitCredential(credential));
        },
        verificationFailed: (error) {
          if (!mounted) {
            return;
          }
          setState(() {
            _isSending = false;
            _errorMessage = _phoneVerificationErrorMessage(error);
            _statusMessage = context.l10n.checkPhoneNumberAndTryAgain;
          });
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) {
            return;
          }
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isSending = false;
            _statusMessage = context.l10n.enterSmsCodeSentToPhone(phone);
          });
          _startResendCountdown();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!mounted) {
            return;
          }
          setState(() {
            _verificationId = verificationId;
            _isSending = false;
            _statusMessage =
                context.l10n.automaticVerificationTimedOutEnterSmsCode;
          });
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSending = false;
        _errorMessage = _phoneVerificationErrorMessage(error);
        _statusMessage = context.l10n.phoneVerificationCouldNotStart;
      });
    }
  }

  Future<void> _submitManualCode() async {
    final verificationId = _verificationId;
    if (verificationId == null || verificationId.isEmpty) {
      setState(() => _errorMessage = context.l10n.waitForSmsCodeFirst);
      return;
    }

    final smsCode = _codeController.text.trim();
    if (smsCode.length < 6) {
      setState(() => _errorMessage = context.l10n.enterSixDigitSmsCode);
      return;
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _submitCredential(credential);
  }

  Future<void> _submitCredential(PhoneAuthCredential credential) async {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _statusMessage = context.l10n.changingPassword;
    });

    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Firebase did not return an ID token.');
      }

      await ref
          .read(authApiProvider)
          .resetPasswordWithVerifiedPhone(
            firebaseIdToken: idToken,
            phone: normalizePhoneForAuth(_phoneController.text),
            password: _passwordController.text,
          );
      await FirebaseAuth.instance.signOut();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.passwordChangedSignInAgain)),
      );
      Navigator.of(context).pop();
    } catch (error) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {
        // Firebase sign-out is best effort after a reset attempt.
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _errorMessage = _phoneVerificationErrorMessage(error);
        _statusMessage = context.l10n.passwordResetFailedTryCodeAgain;
      });
    }
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _secondsUntilResend = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsUntilResend <= 1) {
        timer.cancel();
        setState(() => _secondsUntilResend = 0);
      } else {
        setState(() => _secondsUntilResend -= 1);
      }
    });
  }

  String _phoneVerificationErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return localizeFirebaseError(error, context.l10n);
  }
}
