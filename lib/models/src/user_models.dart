import 'json_utils.dart';

class ApiUser {
  const ApiUser({
    this.id,
    required this.email,
    required this.username,
    required this.name,
    this.avatar,
    this.phone,
    this.city,
    required this.role,
    this.rating,
    this.createdAt,
    this.password,
  });

  final int? id;
  final String email;
  final String username;
  final String name;
  final String? avatar;
  final String? phone;
  final String? city;
  final String role;
  final String? rating;
  final DateTime? createdAt;
  final String? password;

  factory ApiUser.fromJson(JsonMap json) {
    return ApiUser(
      id: intFromJson(json['id']),
      email: stringFromJson(json['email']) ?? '',
      username: stringFromJson(json['username']) ?? '',
      name: stringFromJson(json['name']) ?? '',
      avatar: stringFromJson(json['avatar']),
      phone: stringFromJson(json['phone']),
      city: stringFromJson(json['city']),
      role: stringFromJson(json['role']) ?? '',
      rating: stringFromJson(json['rating']),
      createdAt: dateTimeFromJson(json['created_at']),
      password: stringFromJson(json['password']),
    );
  }

  JsonMap toJson() {
    final json = <String, dynamic>{
      'email': email,
      'username': username,
      'name': name,
      'role': role,
    };
    if (id != null) {
      json['id'] = id;
    }
    if (avatar != null && avatar!.isNotEmpty) {
      json['avatar'] = avatar;
    }
    if (phone != null) {
      json['phone'] = phone;
    }
    if (city != null) {
      json['city'] = city;
    }
    if (rating != null) {
      json['rating'] = rating;
    }
    if (createdAt != null) {
      json['created_at'] = createdAt!.toIso8601String();
    }
    if (password != null) {
      json['password'] = password;
    }
    return json;
  }
}

class UserBrief {
  const UserBrief({
    required this.id,
    required this.name,
    this.avatar,
    this.isOnline = false,
    this.lastSeenAt,
  });

  final int id;
  final String name;
  final String? avatar;
  final bool isOnline;
  final DateTime? lastSeenAt;

  factory UserBrief.fromJson(JsonMap json) {
    return UserBrief(
      id: intFromJson(json['id']) ?? 0,
      name: stringFromJson(json['name']) ?? '',
      avatar: stringFromJson(json['avatar']),
      isOnline: boolFromJson(json['is_online']) ?? false,
      lastSeenAt: dateTimeFromJson(json['last_seen_at']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'is_online': isOnline,
      'last_seen_at': lastSeenAt?.toIso8601String(),
    };
  }

  UserBrief copyWith({
    int? id,
    String? name,
    Object? avatar = _userBriefUnset,
    bool? isOnline,
    Object? lastSeenAt = _userBriefUnset,
  }) {
    return UserBrief(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: identical(avatar, _userBriefUnset) ? this.avatar : avatar as String?,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: identical(lastSeenAt, _userBriefUnset)
          ? this.lastSeenAt
          : lastSeenAt as DateTime?,
    );
  }
}

const _userBriefUnset = Object();

class MeProfile {
  const MeProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.name,
    this.avatar,
    this.phone,
    this.city,
    required this.role,
    this.rating,
    required this.chatPushEnabled,
    required this.chatMessagePreviewEnabled,
    required this.createdAt,
  });

  final int id;
  final String email;
  final String username;
  final String name;
  final String? avatar;
  final String? phone;
  final String? city;
  final String role;
  final String? rating;
  final bool chatPushEnabled;
  final bool chatMessagePreviewEnabled;
  final DateTime createdAt;

  factory MeProfile.fromJson(JsonMap json) {
    return MeProfile(
      id: intFromJson(json['id']) ?? 0,
      email: stringFromJson(json['email']) ?? '',
      username: stringFromJson(json['username']) ?? '',
      name: stringFromJson(json['name']) ?? '',
      avatar: stringFromJson(json['avatar']),
      phone: stringFromJson(json['phone']),
      city: stringFromJson(json['city']),
      role: stringFromJson(json['role']) ?? '',
      rating: stringFromJson(json['rating']),
      chatPushEnabled: boolFromJson(json['chat_push_enabled']) ?? false,
      chatMessagePreviewEnabled:
          boolFromJson(json['chat_message_preview_enabled']) ?? false,
      createdAt: dateTimeFromJson(json['created_at']) ?? DateTime.now(),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'name': name,
      'avatar': avatar,
      'phone': phone,
      'city': city,
      'role': role,
      'rating': rating,
      'chat_push_enabled': chatPushEnabled,
      'chat_message_preview_enabled': chatMessagePreviewEnabled,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class MobileDevice {
  const MobileDevice({
    this.id,
    required this.deviceId,
    required this.platform,
    this.pushToken,
    this.deviceName,
    this.appVersion,
    required this.isActive,
    this.lastSeenAt,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String deviceId;
  final String platform;
  final String? pushToken;
  final String? deviceName;
  final String? appVersion;
  final bool isActive;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory MobileDevice.fromJson(JsonMap json) {
    return MobileDevice(
      id: intFromJson(json['id']),
      deviceId: stringFromJson(json['device_id']) ?? '',
      platform: stringFromJson(json['platform']) ?? '',
      pushToken: stringFromJson(json['push_token']),
      deviceName: stringFromJson(json['device_name']),
      appVersion: stringFromJson(json['app_version']),
      isActive: boolFromJson(json['is_active']) ?? true,
      lastSeenAt: dateTimeFromJson(json['last_seen_at']),
      createdAt: dateTimeFromJson(json['created_at']),
      updatedAt: dateTimeFromJson(json['updated_at']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'platform': platform,
      'push_token': pushToken,
      'device_name': deviceName,
      'app_version': appVersion,
      'is_active': isActive,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
