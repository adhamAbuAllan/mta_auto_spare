import 'json_utils.dart';
import 'car_catalog_models.dart';

class ApiUser {
  const ApiUser({
    this.id,
    this.email = '',
    this.username = '',
    required this.name,
    this.avatar,
    this.phone,
    this.city,
    required this.role,
    this.rating,
    this.isActive = true,
    this.isAdmin = false,
    this.blockedAt,
    this.blockedReason,
    this.createdAt,
    this.password,
    this.supportedCarModelIds,
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
  final bool isActive;
  final bool isAdmin;
  final DateTime? blockedAt;
  final String? blockedReason;
  final DateTime? createdAt;
  final String? password;
  final List<int>? supportedCarModelIds;

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
      isActive: boolFromJson(json['is_active']) ?? true,
      isAdmin: boolFromJson(json['is_admin']) ?? false,
      blockedAt: dateTimeFromJson(json['blocked_at']),
      blockedReason: stringFromJson(json['blocked_reason']),
      createdAt: dateTimeFromJson(json['created_at']),
      password: stringFromJson(json['password']),
    );
  }

  JsonMap toJson() {
    final json = <String, dynamic>{'name': name, 'role': role};
    if (id != null) {
      json['id'] = id;
    }
    if (avatar != null && avatar!.isNotEmpty) {
      json['avatar'] = avatar;
    }
    if (phone != null && phone!.isNotEmpty) {
      json['phone'] = phone;
    }
    if (city != null) {
      json['city'] = city;
    }
    if (rating != null) {
      json['rating'] = rating;
    }
    json['is_active'] = isActive;
    json['is_admin'] = isAdmin;
    if (blockedAt != null) {
      json['blocked_at'] = blockedAt!.toIso8601String();
    }
    if (blockedReason != null) {
      json['blocked_reason'] = blockedReason;
    }
    if (createdAt != null) {
      json['created_at'] = createdAt!.toIso8601String();
    }
    if (password != null) {
      json['password'] = password;
    }
    if (supportedCarModelIds != null) {
      json['supported_car_model_ids'] = supportedCarModelIds;
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
      avatar: identical(avatar, _userBriefUnset)
          ? this.avatar
          : avatar as String?,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: identical(lastSeenAt, _userBriefUnset)
          ? this.lastSeenAt
          : lastSeenAt as DateTime?,
    );
  }
}

const _userBriefUnset = Object();

class PublicUserProfile {
  const PublicUserProfile({
    required this.id,
    required this.name,
    this.avatar,
    this.email,
    this.phone,
    this.city,
    required this.role,
    this.rating,
    required this.isOnline,
    this.isAdmin = false,
    this.lastSeenAt,
    this.supportedCarModels = const [],
    required this.createdAt,
  });

  final int id;
  final String name;
  final String? avatar;
  final String? email;
  final String? phone;
  final String? city;
  final String role;
  final String? rating;
  final bool isOnline;
  final bool isAdmin;
  final DateTime? lastSeenAt;
  final List<CarModelOption> supportedCarModels;
  final DateTime createdAt;

  factory PublicUserProfile.fromJson(JsonMap json) {
    return PublicUserProfile(
      id: intFromJson(json['id']) ?? 0,
      name: stringFromJson(json['name']) ?? '',
      avatar: stringFromJson(json['avatar']),
      email: stringFromJson(json['email']),
      phone: stringFromJson(json['phone']),
      city: stringFromJson(json['city']),
      role: stringFromJson(json['role']) ?? '',
      rating: stringFromJson(json['rating']),
      isOnline: boolFromJson(json['is_online']) ?? false,
      isAdmin: boolFromJson(json['is_admin']) ?? false,
      lastSeenAt: dateTimeFromJson(json['last_seen_at']),
      supportedCarModels: listFromJson(
        json['supported_car_models'],
        CarModelOption.fromJson,
      ),
      createdAt: dateTimeFromJson(json['created_at']) ?? DateTime.now(),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'email': email,
      'phone': phone,
      'city': city,
      'role': role,
      'rating': rating,
      'is_online': isOnline,
      'is_admin': isAdmin,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'supported_car_models': supportedCarModels
          .map((item) => item.toJson())
          .toList(growable: false),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class MeProfile {
  const MeProfile({
    required this.id,
    this.email = '',
    this.username = '',
    required this.name,
    this.avatar,
    this.phone,
    this.city,
    required this.role,
    this.rating,
    required this.isActive,
    required this.isAdmin,
    this.blockedAt,
    this.blockedReason,
    required this.chatPushEnabled,
    required this.chatMessagePreviewEnabled,
    this.supportedCarModels = const [],
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
  final bool isActive;
  final bool isAdmin;
  final DateTime? blockedAt;
  final String? blockedReason;
  final bool chatPushEnabled;
  final bool chatMessagePreviewEnabled;
  final List<CarModelOption> supportedCarModels;
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
      isActive: boolFromJson(json['is_active']) ?? true,
      isAdmin: boolFromJson(json['is_admin']) ?? false,
      blockedAt: dateTimeFromJson(json['blocked_at']),
      blockedReason: stringFromJson(json['blocked_reason']),
      chatPushEnabled: boolFromJson(json['chat_push_enabled']) ?? false,
      chatMessagePreviewEnabled:
          boolFromJson(json['chat_message_preview_enabled']) ?? false,
      supportedCarModels: listFromJson(
        json['supported_car_models'],
        CarModelOption.fromJson,
      ),
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
      'is_active': isActive,
      'is_admin': isAdmin,
      'blocked_at': blockedAt?.toIso8601String(),
      'blocked_reason': blockedReason,
      'chat_push_enabled': chatPushEnabled,
      'chat_message_preview_enabled': chatMessagePreviewEnabled,
      'supported_car_models': supportedCarModels
          .map((item) => item.toJson())
          .toList(growable: false),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UserReportEntry {
  const UserReportEntry({
    required this.id,
    required this.reporter,
    this.reporterDetails,
    required this.reportedUser,
    this.reportedUserDetails,
    required this.reason,
    required this.details,
    required this.status,
    this.reviewedBy,
    this.reviewedByDetails,
    this.reviewedAt,
    required this.adminNotes,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int reporter;
  final UserBrief? reporterDetails;
  final int reportedUser;
  final UserBrief? reportedUserDetails;
  final String reason;
  final String details;
  final String status;
  final int? reviewedBy;
  final UserBrief? reviewedByDetails;
  final DateTime? reviewedAt;
  final String adminNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOpen => status == 'open';
  bool get isReviewed => status == 'reviewed';
  bool get isDismissed => status == 'dismissed';
  bool get isActioned => status == 'actioned';

  factory UserReportEntry.fromJson(JsonMap json) {
    return UserReportEntry(
      id: intFromJson(json['id']) ?? 0,
      reporter: intFromJson(json['reporter']) ?? 0,
      reporterDetails: mapFromJson(json['reporter_details']) == null
          ? null
          : UserBrief.fromJson(mapFromJson(json['reporter_details'])!),
      reportedUser: intFromJson(json['reported_user']) ?? 0,
      reportedUserDetails: mapFromJson(json['reported_user_details']) == null
          ? null
          : UserBrief.fromJson(mapFromJson(json['reported_user_details'])!),
      reason: stringFromJson(json['reason']) ?? '',
      details: stringFromJson(json['details']) ?? '',
      status: stringFromJson(json['status']) ?? 'open',
      reviewedBy: intFromJson(json['reviewed_by']),
      reviewedByDetails: mapFromJson(json['reviewed_by_details']) == null
          ? null
          : UserBrief.fromJson(mapFromJson(json['reviewed_by_details'])!),
      reviewedAt: dateTimeFromJson(json['reviewed_at']),
      adminNotes: stringFromJson(json['admin_notes']) ?? '',
      createdAt: dateTimeFromJson(json['created_at']),
      updatedAt: dateTimeFromJson(json['updated_at']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'reporter': reporter,
      'reporter_details': reporterDetails?.toJson(),
      'reported_user': reportedUser,
      'reported_user_details': reportedUserDetails?.toJson(),
      'reason': reason,
      'details': details,
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_by_details': reviewedByDetails?.toJson(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'admin_notes': adminNotes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
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
    final json = <String, dynamic>{
      'device_id': deviceId,
      'platform': platform,
      'is_active': isActive,
    };
    if (id != null) {
      json['id'] = id;
    }
    if (pushToken != null) {
      json['push_token'] = pushToken;
    } else if (!isActive) {
      json['push_token'] = '';
    }
    if (deviceName != null && deviceName!.trim().isNotEmpty) {
      json['device_name'] = deviceName!.trim();
    }
    if (appVersion != null && appVersion!.trim().isNotEmpty) {
      json['app_version'] = appVersion!.trim();
    }
    if (lastSeenAt != null) {
      json['last_seen_at'] = lastSeenAt!.toIso8601String();
    }
    if (createdAt != null) {
      json['created_at'] = createdAt!.toIso8601String();
    }
    if (updatedAt != null) {
      json['updated_at'] = updatedAt!.toIso8601String();
    }
    return json;
  }
}
