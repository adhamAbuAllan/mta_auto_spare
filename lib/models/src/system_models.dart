import 'json_utils.dart';
import 'user_models.dart';

class HealthStatus {
  const HealthStatus({required this.status});

  final String status;

  factory HealthStatus.fromJson(JsonMap json) {
    return HealthStatus(status: stringFromJson(json['status']) ?? '');
  }

  JsonMap toJson() {
    return {'status': status};
  }
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.updateAvailable,
    required this.updateRequired,
    this.latestVersion,
    this.latestBuildNumber,
    this.minimumSupportedVersion,
    this.minimumSupportedBuildNumber,
    this.title,
    this.message,
    this.releaseNotes,
    this.storeUrl,
    this.androidStoreUrl,
    this.iosStoreUrl,
  });

  final bool updateAvailable;
  final bool updateRequired;
  final String? latestVersion;
  final int? latestBuildNumber;
  final String? minimumSupportedVersion;
  final int? minimumSupportedBuildNumber;
  final String? title;
  final String? message;
  final String? releaseNotes;
  final String? storeUrl;
  final String? androidStoreUrl;
  final String? iosStoreUrl;

  factory AppUpdateInfo.fromJson(JsonMap json) {
    return AppUpdateInfo(
      updateAvailable:
          boolFromJson(json['update_available'] ?? json['updateAvailable']) ??
          false,
      updateRequired:
          boolFromJson(json['update_required'] ?? json['updateRequired']) ??
          false,
      latestVersion: stringFromJson(
        json['latest_version'] ?? json['latestVersion'],
      ),
      latestBuildNumber: intFromJson(
        json['latest_build_number'] ??
            json['latest_build'] ??
            json['latestBuildNumber'] ??
            json['latestBuild'],
      ),
      minimumSupportedVersion: stringFromJson(
        json['minimum_supported_version'] ??
            json['min_supported_version'] ??
            json['minimumSupportedVersion'] ??
            json['minSupportedVersion'],
      ),
      minimumSupportedBuildNumber: intFromJson(
        json['minimum_supported_build_number'] ??
            json['min_supported_build'] ??
            json['minimumSupportedBuildNumber'] ??
            json['minSupportedBuild'],
      ),
      title: stringFromJson(json['title']),
      message: stringFromJson(json['message']),
      releaseNotes: stringFromJson(
        json['release_notes'] ?? json['releaseNotes'],
      ),
      storeUrl: stringFromJson(json['store_url'] ?? json['storeUrl']),
      androidStoreUrl: stringFromJson(
        json['android_store_url'] ??
            json['android_url'] ??
            json['androidStoreUrl'] ??
            json['androidUrl'],
      ),
      iosStoreUrl: stringFromJson(
        json['ios_store_url'] ??
            json['ios_url'] ??
            json['iosStoreUrl'] ??
            json['iosUrl'],
      ),
    );
  }

  JsonMap toJson() {
    return {
      'update_available': updateAvailable,
      'update_required': updateRequired,
      if (latestVersion != null) 'latest_version': latestVersion,
      if (latestBuildNumber != null) 'latest_build_number': latestBuildNumber,
      if (minimumSupportedVersion != null)
        'minimum_supported_version': minimumSupportedVersion,
      if (minimumSupportedBuildNumber != null)
        'minimum_supported_build_number': minimumSupportedBuildNumber,
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (releaseNotes != null) 'release_notes': releaseNotes,
      if (storeUrl != null) 'store_url': storeUrl,
      if (androidStoreUrl != null) 'android_store_url': androidStoreUrl,
      if (iosStoreUrl != null) 'ios_store_url': iosStoreUrl,
    };
  }
}

class AuthTokenPair {
  const AuthTokenPair({required this.refresh, required this.access});

  final String refresh;
  final String access;

  factory AuthTokenPair.fromJson(JsonMap json) {
    return AuthTokenPair(
      refresh: stringFromJson(json['refresh']) ?? '',
      access: stringFromJson(json['access']) ?? '',
    );
  }

  JsonMap toJson() {
    return {'refresh': refresh, 'access': access};
  }
}

class AuthenticatedSession {
  const AuthenticatedSession({required this.tokens, required this.profile});

  final AuthTokenPair tokens;
  final MeProfile profile;

  factory AuthenticatedSession.fromJson(JsonMap json) {
    return AuthenticatedSession(
      tokens: AuthTokenPair.fromJson(json),
      profile: MeProfile.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
      ),
    );
  }
}
