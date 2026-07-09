import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SmsAttemptLimiter {
  SmsAttemptLimiter({
    required SharedPreferences preferences,
    DateTime Function()? now,
    this.cooldown = const Duration(seconds: 60),
    this.shortWindow = const Duration(minutes: 15),
    this.longWindow = const Duration(hours: 24),
    this.shortWindowLimit = 3,
    this.longWindowLimit = 8,
  }) : _preferences = preferences,
       _now = now ?? DateTime.now;

  static const String _attemptsKey = 'firebase_phone_sms_attempts';

  final SharedPreferences _preferences;
  final DateTime Function() _now;
  final Duration cooldown;
  final Duration shortWindow;
  final Duration longWindow;
  final int shortWindowLimit;
  final int longWindowLimit;

  Future<SmsAttemptDecision> check() async {
    final now = _now();
    final attempts = await _recentAttempts(now);

    if (attempts.isNotEmpty) {
      final nextAllowedAt = attempts.last.add(cooldown);
      if (now.isBefore(nextAllowedAt)) {
        return SmsAttemptDecision.blocked(
          retryAfter: nextAllowedAt.difference(now),
          message: _cooldownMessage(nextAllowedAt.difference(now)),
        );
      }
    }

    final shortWindowStart = now.subtract(shortWindow);
    final shortWindowAttempts = attempts
        .where((attempt) => !attempt.isBefore(shortWindowStart))
        .length;
    if (shortWindowAttempts >= shortWindowLimit) {
      final retryAt = attempts
          .where((attempt) => !attempt.isBefore(shortWindowStart))
          .first
          .add(shortWindow);
      return SmsAttemptDecision.blocked(
        retryAfter: retryAt.difference(now),
        message:
            'Too many SMS code requests. Wait ${_formatWait(retryAt.difference(now))} before trying again.',
      );
    }

    if (attempts.length >= longWindowLimit) {
      final retryAt = attempts.first.add(longWindow);
      return SmsAttemptDecision.blocked(
        retryAfter: retryAt.difference(now),
        message:
            'Daily SMS code request limit reached on this device. Try again in ${_formatWait(retryAt.difference(now))}.',
      );
    }

    return const SmsAttemptDecision.allowed();
  }

  Future<void> recordAttempt() async {
    final now = _now();
    final attempts = await _recentAttempts(now);
    attempts.add(now);
    await _saveAttempts(attempts, now);
  }

  Future<List<DateTime>> _recentAttempts(DateTime now) async {
    final attempts = _readAttempts();
    final cutoff = now.subtract(longWindow);
    final recent =
        attempts
            .where(
              (attempt) => !attempt.isBefore(cutoff) && !attempt.isAfter(now),
            )
            .toList()
          ..sort();
    if (recent.length != attempts.length) {
      await _saveAttempts(recent, now);
    }
    return recent;
  }

  List<DateTime> _readAttempts() {
    final raw = _preferences.getString(_attemptsKey);
    if (raw == null || raw.isEmpty) {
      return <DateTime>[];
    }

    try {
      final values = jsonDecode(raw);
      if (values is! List) {
        return <DateTime>[];
      }
      return values
          .whereType<int>()
          .map(DateTime.fromMillisecondsSinceEpoch)
          .toList();
    } catch (_) {
      return <DateTime>[];
    }
  }

  Future<void> _saveAttempts(List<DateTime> attempts, DateTime now) async {
    final cutoff = now.subtract(longWindow);
    final encoded = attempts
        .where((attempt) => !attempt.isBefore(cutoff) && !attempt.isAfter(now))
        .map((attempt) => attempt.millisecondsSinceEpoch)
        .toList();
    await _preferences.setString(_attemptsKey, jsonEncode(encoded));
  }

  String _cooldownMessage(Duration wait) {
    return 'Wait ${_formatWait(wait)} before requesting another SMS code.';
  }

  String _formatWait(Duration wait) {
    if (wait.inHours >= 1) {
      final hours = wait.inHours;
      final minutes = wait.inMinutes.remainder(60);
      if (minutes == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      }
      return '$hours h $minutes min';
    }
    if (wait.inMinutes >= 1) {
      final minutes = wait.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }
    final seconds = wait.inSeconds <= 0 ? 1 : wait.inSeconds;
    return '$seconds seconds';
  }
}

class SmsAttemptDecision {
  const SmsAttemptDecision.allowed()
    : isAllowed = true,
      retryAfter = Duration.zero,
      message = null;

  const SmsAttemptDecision.blocked({
    required this.retryAfter,
    required this.message,
  }) : isAllowed = false;

  final bool isAllowed;
  final Duration retryAfter;
  final String? message;
}
