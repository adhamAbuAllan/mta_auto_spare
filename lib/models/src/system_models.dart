import 'json_utils.dart';

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
