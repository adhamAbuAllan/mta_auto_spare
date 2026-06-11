import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/auth_provider.dart';
import '../../firebase/firebase_bootstrap.dart';
import '../../localization/app_localizations_x.dart';
import '../common_widgets/app_error_card.dart';

class PhoneRegistrationDraft {
  const PhoneRegistrationDraft({
    required this.phone,
    required this.name,
    required this.password,
    required this.role,
    this.supportedCarModelIds,
  });

  final String phone;
  final String name;
  final String password;
  final String role;
  final List<int>? supportedCarModelIds;
}

class PhoneOtpPage extends ConsumerStatefulWidget {
  const PhoneOtpPage({super.key, required this.draft});

  final PhoneRegistrationDraft draft;

  @override
  ConsumerState<PhoneOtpPage> createState() => _PhoneOtpPageState();
}

class _PhoneOtpPageState extends ConsumerState<PhoneOtpPage> {
  final _codeController = TextEditingController();
  Timer? _resendTimer;
  String? _verificationId;
  int? _resendToken;
  int _secondsUntilResend = 0;
  bool _isSending = false;
  bool _isSubmitting = false;
  String? _localError;
  String _statusMessage = 'Sending verification code...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startPhoneVerification());
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerNotifierProvider);
    final busy = _isSending || _isSubmitting || registerState.isLoading;
    final canSubmitCode =
        !busy &&
        (_verificationId?.isNotEmpty ?? false) &&
        _codeController.text.trim().length >= 6;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.createAccount)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verify ${widget.draft.phone}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _statusMessage,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF6F6A63),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (busy) const LinearProgressIndicator(),
                  if (busy) const SizedBox(height: 18),
                  TextFormField(
                    controller: _codeController,
                    enabled: !busy && (_verificationId?.isNotEmpty ?? false),
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'SMS code',
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
                  if (_localError != null && _localError!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    AppErrorCard(message: _localError!),
                  ],
                  if (registerState.hasError) ...[
                    const SizedBox(height: 16),
                    AppErrorCard(message: registerState.errorMessage!),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: canSubmitCode
                              ? () => unawaited(_submitManualCode())
                              : null,
                          child: Text(
                            registerState.isLoading || _isSubmitting
                                ? context.l10n.creating
                                : 'Verify and create account',
                          ),
                        ),
                      ),
                    ],
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
                            ? 'Resend in $_secondsUntilResend s'
                            : 'Resend code',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startPhoneVerification({bool resend = false}) async {
    final languageCode = Localizations.localeOf(context).languageCode;

    setState(() {
      _isSending = true;
      _localError = null;
      _statusMessage = resend
          ? 'Sending a new verification code...'
          : 'Sending verification code...';
    });

    try {
      await ensureFirebaseInitialized(throwOnError: true);
      final firebaseAuth = FirebaseAuth.instance;
      await firebaseAuth.setLanguageCode(
        languageCode.trim().isEmpty ? 'en' : languageCode.trim(),
      );
      await firebaseAuth.verifyPhoneNumber(
        phoneNumber: widget.draft.phone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resend ? _resendToken : null,
        verificationCompleted: (credential) {
          if (!mounted || _isSubmitting) {
            return;
          }
          setState(() {
            _statusMessage =
                'Phone verified automatically. Creating account...';
          });
          unawaited(_submitCredential(credential));
        },
        verificationFailed: (error) {
          if (!mounted) {
            return;
          }
          setState(() {
            _isSending = false;
            _localError = _phoneVerificationErrorMessage(error);
            _statusMessage = 'Check the phone number and try again.';
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
            _statusMessage =
                'Enter the SMS code if the phone is not verified automatically.';
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
                'Automatic verification timed out. Enter the SMS code.';
          });
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSending = false;
        _localError = _phoneVerificationErrorMessage(error);
        _statusMessage = 'Phone verification could not start.';
      });
    }
  }

  Future<void> _submitManualCode() async {
    final verificationId = _verificationId;
    if (verificationId == null || verificationId.isEmpty) {
      setState(() => _localError = 'Wait for the SMS code first.');
      return;
    }

    final smsCode = _codeController.text.trim();
    if (smsCode.length < 6) {
      setState(() => _localError = 'Enter the 6-digit SMS code.');
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
      _localError = null;
      _statusMessage = 'Creating account...';
    });

    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Firebase did not return an ID token.');
      }

      final registered = await ref
          .read(registerNotifierProvider.notifier)
          .registerVerifiedPhone(
            firebaseIdToken: idToken,
            phone: widget.draft.phone,
            name: widget.draft.name,
            password: widget.draft.password,
            role: widget.draft.role,
            supportedCarModelIds: widget.draft.supportedCarModelIds,
          );
      await FirebaseAuth.instance.signOut();

      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      if (registered) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {
        // Firebase sign-out is best effort here; Django auth owns the app session.
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _localError = _phoneVerificationErrorMessage(error);
        _statusMessage = 'Verification failed. Try the code again.';
      });
    }
  }

  String _phoneVerificationErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      final code = error.code.trim();
      final message = (error.message ?? '').trim();
      final searchable = '$code $message'.toLowerCase();

      if (code == 'operation-not-allowed' ||
          searchable.contains('sms unable') ||
          searchable.contains('region')) {
        return 'Firebase is blocking this SMS request. Confirm Phone sign-in is enabled and allow Israel (+972) and Palestinian Territory (+970) in Firebase SMS region policy.';
      }
      if (code == 'invalid-phone-number') {
        return 'Enter a valid +970 or +972 phone number.';
      }
      if (code == 'too-many-requests' || code == 'quota-exceeded') {
        return 'Too many SMS attempts. Wait before requesting another code.';
      }
      if (code == 'invalid-verification-code') {
        return 'The SMS code is incorrect.';
      }
      if (code == 'session-expired') {
        return 'The SMS code expired. Request a new code.';
      }
      if (message.isNotEmpty) {
        return message;
      }
    }

    final fallback = error.toString().trim();
    return fallback.isEmpty ? 'Phone verification failed.' : fallback;
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
        return;
      }
      setState(() => _secondsUntilResend -= 1);
    });
  }
}
