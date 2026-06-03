import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_exception.dart';
import '../api/system_api.dart';
import '../constants/api_constants.dart';
import '../localization/notification_strings.dart';
import '../models/models.dart';

const _lastShownAppUpdateVersionKey = 'last_shown_app_update_version';
const _lastCheckedAppUpdateAtKey = 'last_checked_app_update_at';

class ResolvedAppUpdate {
  const ResolvedAppUpdate({
    required this.info,
    required this.installedVersion,
    required this.installedBuildNumber,
    required this.storeUrl,
  });

  final AppUpdateInfo info;
  final String installedVersion;
  final String installedBuildNumber;
  final Uri storeUrl;

  String get notificationKey {
    final latestVersion = info.latestVersion?.trim();
    final latestBuild = info.latestBuildNumber;
    if (latestVersion != null && latestVersion.isNotEmpty) {
      return latestBuild == null
          ? latestVersion
          : '$latestVersion+$latestBuild';
    }
    return latestBuild?.toString() ?? storeUrl.toString();
  }
}

class AppUpdateService {
  AppUpdateService({
    required SystemApi systemApi,
    required SharedPreferences preferences,
    FlutterLocalNotificationsPlugin? notificationsPlugin,
    Future<PackageInfo> Function()? loadPackageInfo,
    Duration checkInterval = const Duration(hours: 12),
  }) : _systemApi = systemApi,
       _preferences = preferences,
       _notificationsPlugin =
           notificationsPlugin ?? FlutterLocalNotificationsPlugin(),
       _loadPackageInfo = loadPackageInfo ?? PackageInfo.fromPlatform,
       _checkInterval = checkInterval;

  final SystemApi _systemApi;
  final SharedPreferences _preferences;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final Future<PackageInfo> Function() _loadPackageInfo;
  final Duration _checkInterval;

  Future<ResolvedAppUpdate?> checkForUpdate({bool force = false}) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return null;
    }
    if (!force && !_canCheckNow()) {
      return null;
    }

    await _preferences.setString(
      _lastCheckedAppUpdateAtKey,
      DateTime.now().toIso8601String(),
    );

    try {
      final packageInfo = await _loadPackageInfo();
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final updateInfo = await _systemApi.appUpdate(
        platform: platform,
        version: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        packageName: packageInfo.packageName,
      );
      final resolved = _resolveUpdate(packageInfo, updateInfo);
      if (resolved == null) {
        return null;
      }
      await _showNotificationIfNeeded(resolved);
      return resolved;
    } on ApiException catch (error) {
      debugPrint('App update check skipped: $error');
      return null;
    } catch (error, stackTrace) {
      debugPrint('App update check failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> openStore(ResolvedAppUpdate update) async {
    final opened = await launchUrl(
      update.storeUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      throw StateError('Could not open ${update.storeUrl}.');
    }
  }

  bool _canCheckNow() {
    final lastChecked = DateTime.tryParse(
      _preferences.getString(_lastCheckedAppUpdateAtKey) ?? '',
    );
    if (lastChecked == null) {
      return true;
    }
    return DateTime.now().difference(lastChecked) >= _checkInterval;
  }

  ResolvedAppUpdate? _resolveUpdate(
    PackageInfo packageInfo,
    AppUpdateInfo updateInfo,
  ) {
    final updateAvailable =
        updateInfo.updateAvailable ||
        _isNewerVersion(updateInfo.latestVersion, packageInfo.version) ||
        _isNewerBuild(updateInfo.latestBuildNumber, packageInfo.buildNumber);
    final updateRequired =
        updateInfo.updateRequired ||
        _isNewerVersion(
          updateInfo.minimumSupportedVersion,
          packageInfo.version,
        ) ||
        _isNewerBuild(
          updateInfo.minimumSupportedBuildNumber,
          packageInfo.buildNumber,
        );
    if (!updateAvailable && !updateRequired) {
      return null;
    }

    final storeUrl = _resolveStoreUrl(packageInfo, updateInfo);
    if (storeUrl == null) {
      return null;
    }

    return ResolvedAppUpdate(
      info: AppUpdateInfo(
        updateAvailable: updateAvailable,
        updateRequired: updateRequired,
        latestVersion: updateInfo.latestVersion,
        latestBuildNumber: updateInfo.latestBuildNumber,
        minimumSupportedVersion: updateInfo.minimumSupportedVersion,
        minimumSupportedBuildNumber: updateInfo.minimumSupportedBuildNumber,
        title: updateInfo.title,
        message: updateInfo.message,
        releaseNotes: updateInfo.releaseNotes,
        storeUrl: updateInfo.storeUrl,
        androidStoreUrl: updateInfo.androidStoreUrl,
        iosStoreUrl: updateInfo.iosStoreUrl,
      ),
      installedVersion: packageInfo.version,
      installedBuildNumber: packageInfo.buildNumber,
      storeUrl: storeUrl,
    );
  }

  Uri? _resolveStoreUrl(PackageInfo packageInfo, AppUpdateInfo updateInfo) {
    final explicitUrl = Platform.isAndroid
        ? _firstNonEmpty(updateInfo.androidStoreUrl, updateInfo.storeUrl)
        : _firstNonEmpty(updateInfo.iosStoreUrl, updateInfo.storeUrl);
    final parsedExplicitUrl = Uri.tryParse(explicitUrl ?? '');
    if (parsedExplicitUrl != null && parsedExplicitUrl.hasScheme) {
      return parsedExplicitUrl;
    }

    if (Platform.isAndroid) {
      return Uri.parse(
        'https://play.google.com/store/apps/details?id=${packageInfo.packageName}',
      );
    }
    return null;
  }

  Future<void> _showNotificationIfNeeded(ResolvedAppUpdate update) async {
    final notificationKey = update.notificationKey;
    if (_preferences.getString(_lastShownAppUpdateVersionKey) ==
        notificationKey) {
      return;
    }

    final strings = await loadNotificationStrings(preferences: _preferences);
    await _initializeNotifications();
    await _createChannel(strings);
    await _notificationsPlugin.show(
      id: 3001,
      title: update.info.title?.trim().isNotEmpty == true
          ? update.info.title!.trim()
          : strings.appUpdateTitle,
      body: update.info.message?.trim().isNotEmpty == true
          ? update.info.message!.trim()
          : strings.appUpdateBody,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          ApiConstants.appUpdatesNotificationChannelId,
          strings.appUpdatesChannel.name,
          channelDescription: strings.appUpdatesChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.status,
          tag: 'app-update-$notificationKey',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: update.storeUrl.toString(),
    );
    await _preferences.setString(
      _lastShownAppUpdateVersionKey,
      notificationKey,
    );
  }

  Future<void> _initializeNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _notificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        final storeUrl = Uri.tryParse(payload ?? '');
        if (storeUrl == null || !storeUrl.hasScheme) {
          return;
        }
        unawaited(launchUrl(storeUrl, mode: LaunchMode.externalApplication));
      },
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _createChannel(NotificationStrings strings) async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        ApiConstants.appUpdatesNotificationChannelId,
        strings.appUpdatesChannel.name,
        description: strings.appUpdatesChannel.description,
        importance: Importance.high,
      ),
    );
  }

  bool _isNewerBuild(int? latestBuildNumber, String currentBuildNumber) {
    final currentBuild = int.tryParse(currentBuildNumber);
    return latestBuildNumber != null &&
        currentBuild != null &&
        latestBuildNumber > currentBuild;
  }

  bool _isNewerVersion(String? latestVersion, String currentVersion) {
    final latestParts = _versionParts(latestVersion);
    final currentParts = _versionParts(currentVersion);
    if (latestParts.isEmpty || currentParts.isEmpty) {
      return false;
    }

    final maxLength = latestParts.length > currentParts.length
        ? latestParts.length
        : currentParts.length;
    for (var index = 0; index < maxLength; index += 1) {
      final latestPart = index < latestParts.length ? latestParts[index] : 0;
      final currentPart = index < currentParts.length ? currentParts[index] : 0;
      if (latestPart > currentPart) {
        return true;
      }
      if (latestPart < currentPart) {
        return false;
      }
    }
    return false;
  }

  List<int> _versionParts(String? version) {
    final normalized = version?.trim();
    if (normalized == null || normalized.isEmpty) {
      return const [];
    }
    return normalized
        .split(RegExp(r'[.+-]'))
        .map((part) => int.tryParse(part))
        .whereType<int>()
        .toList(growable: false);
  }

  String? _firstNonEmpty(String? first, String? second) {
    final normalizedFirst = first?.trim();
    if (normalizedFirst != null && normalizedFirst.isNotEmpty) {
      return normalizedFirst;
    }
    final normalizedSecond = second?.trim();
    return normalizedSecond == null || normalizedSecond.isEmpty
        ? null
        : normalizedSecond;
  }
}
