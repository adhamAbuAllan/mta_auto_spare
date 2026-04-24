import 'json_utils.dart';
import 'car_catalog_models.dart';
import 'user_models.dart';

class SparePart {
  const SparePart({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    this.createdAt,
  });

  final int? id;
  final String name;
  final String description;
  final String price;
  final DateTime? createdAt;

  factory SparePart.fromJson(JsonMap json) {
    return SparePart(
      id: intFromJson(json['id']),
      name: stringFromJson(json['name']) ?? '',
      description: stringFromJson(json['description']) ?? '',
      price: stringFromJson(json['price']) ?? '',
      createdAt: dateTimeFromJson(json['created_at']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class PartRequestStatus {
  const PartRequestStatus({
    this.id,
    required this.code,
    required this.label,
    required this.isTerminal,
    this.createdAt,
  });

  final int? id;
  final String code;
  final String label;
  final bool isTerminal;
  final DateTime? createdAt;

  factory PartRequestStatus.fromJson(JsonMap json) {
    return PartRequestStatus(
      id: intFromJson(json['id']),
      code: stringFromJson(json['code']) ?? '',
      label: stringFromJson(json['label']) ?? '',
      isTerminal: boolFromJson(json['is_terminal']) ?? false,
      createdAt: dateTimeFromJson(json['created_at']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'code': code,
      'label': label,
      'is_terminal': isTerminal,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class PartRequest {
  const PartRequest({
    this.id,
    required this.requester,
    this.requesterDetails,
    required this.title,
    this.translatedTitle,
    this.titleLanguage,
    required this.description,
    this.translatedDescription,
    this.descriptionLanguage,
    this.minPrice,
    this.maxPrice,
    required this.status,
    this.statusDetails,
    this.carModelId,
    this.carModel,
    this.city,
    this.images = const [],
    this.isOwner = false,
    this.canUpdateStatus = false,
    this.myAccessStatus,
    this.grantedUser,
    this.translationTargetLanguage,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int requester;
  final UserBrief? requesterDetails;
  final String title;
  final String? translatedTitle;
  final String? titleLanguage;
  final String description;
  final String? translatedDescription;
  final String? descriptionLanguage;
  final String? minPrice;
  final String? maxPrice;
  final int status;
  final PartRequestStatus? statusDetails;
  final int? carModelId;
  final CarModelOption? carModel;
  final String? city;
  final List<PartImage> images;
  final bool isOwner;
  final bool canUpdateStatus;
  final String? myAccessStatus;
  final UserBrief? grantedUser;
  final String? translationTargetLanguage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayTitle => translatedTextOrOriginal(title, translatedTitle);
  String get displayDescription =>
      translatedTextOrOriginal(description, translatedDescription);
  bool get hasTranslatedTitle => hasVisibleTranslation(title, translatedTitle);
  bool get hasTranslatedDescription =>
      hasVisibleTranslation(description, translatedDescription);
  bool get hasTranslatedContent =>
      hasTranslatedTitle || hasTranslatedDescription;
  bool get isAssignedToCurrentUser => canUpdateStatus && !isOwner;

  factory PartRequest.fromJson(JsonMap json) {
    return PartRequest(
      id: intFromJson(json['id']),
      requester: intFromJson(json['requester']) ?? 0,
      requesterDetails: mapFromJson(json['requester_details']) == null
          ? null
          : UserBrief.fromJson(mapFromJson(json['requester_details'])!),
      title: stringFromJson(json['title']) ?? '',
      translatedTitle: stringFromJson(json['translated_title']),
      titleLanguage: stringFromJson(json['title_language']),
      description: stringFromJson(json['description']) ?? '',
      translatedDescription: stringFromJson(json['translated_description']),
      descriptionLanguage: stringFromJson(json['description_language']),
      minPrice: stringFromJson(json['min_price']),
      maxPrice: stringFromJson(json['max_price']),
      status: intFromJson(json['status']) ?? 0,
      statusDetails: mapFromJson(json['status_details']) == null
          ? null
          : PartRequestStatus.fromJson(mapFromJson(json['status_details'])!),
      carModelId: intFromJson(json['car_model']),
      carModel: mapFromJson(json['car_model_details']) == null
          ? null
          : CarModelOption.fromJson(mapFromJson(json['car_model_details'])!),
      city: stringFromJson(json['city']),
      images: listFromJson(json['images'], PartImage.fromJson),
      isOwner: boolFromJson(json['is_owner']) ?? false,
      canUpdateStatus: boolFromJson(json['can_update_status']) ?? false,
      myAccessStatus: stringFromJson(json['my_access_status']),
      grantedUser: mapFromJson(json['granted_user']) == null
          ? null
          : UserBrief.fromJson(mapFromJson(json['granted_user'])!),
      translationTargetLanguage: stringFromJson(
        json['translation_target_language'],
      ),
      createdAt: dateTimeFromJson(json['created_at']),
      updatedAt: dateTimeFromJson(json['updated_at']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'requester': requester,
      'requester_details': requesterDetails?.toJson(),
      'title': title,
      'translated_title': translatedTitle,
      'title_language': titleLanguage,
      'description': description,
      'translated_description': translatedDescription,
      'description_language': descriptionLanguage,
      'min_price': minPrice,
      'max_price': maxPrice,
      'status': status,
      'status_details': statusDetails?.toJson(),
      'car_model': carModelId,
      'city': city,
      'images': images.map((item) => item.toJson()).toList(growable: false),
      'is_owner': isOwner,
      'can_update_status': canUpdateStatus,
      'my_access_status': myAccessStatus,
      'granted_user': grantedUser?.toJson(),
      'translation_target_language': translationTargetLanguage,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class RequestUploadImage {
  const RequestUploadImage({
    required this.path,
    required this.fileName,
    required this.contentType,
  });

  final String path;
  final String fileName;
  final String contentType;
}

class PartImage {
  const PartImage({
    this.id,
    required this.partRequest,
    required this.image,
    this.createdAt,
  });

  final int? id;
  final int partRequest;
  final String image;
  final DateTime? createdAt;

  factory PartImage.fromJson(JsonMap json) {
    return PartImage(
      id: intFromJson(json['id']),
      partRequest: intFromJson(json['part_request']) ?? 0,
      image: stringFromJson(json['image']) ?? '',
      createdAt: dateTimeFromJson(json['created_at']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'part_request': partRequest,
      'image': image,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class PartRequestBrief {
  const PartRequestBrief({
    required this.id,
    required this.title,
    this.translatedTitle,
    this.titleLanguage,
    this.minPrice,
    this.maxPrice,
    this.status,
    this.statusDetails,
    this.carModel,
    this.translationTargetLanguage,
  });

  final int id;
  final String title;
  final String? translatedTitle;
  final String? titleLanguage;
  final String? minPrice;
  final String? maxPrice;
  final int? status;
  final PartRequestStatus? statusDetails;
  final CarModelOption? carModel;
  final String? translationTargetLanguage;

  String get displayTitle => translatedTextOrOriginal(title, translatedTitle);
  bool get hasTranslatedTitle => hasVisibleTranslation(title, translatedTitle);

  factory PartRequestBrief.fromJson(JsonMap json) {
    return PartRequestBrief(
      id: intFromJson(json['id']) ?? 0,
      title: stringFromJson(json['title']) ?? '',
      translatedTitle: stringFromJson(json['translated_title']),
      titleLanguage: stringFromJson(json['title_language']),
      minPrice: stringFromJson(json['min_price']),
      maxPrice: stringFromJson(json['max_price']),
      status: intFromJson(json['status']),
      statusDetails: mapFromJson(json['status_details']) == null
          ? null
          : PartRequestStatus.fromJson(mapFromJson(json['status_details'])!),
      carModel: mapFromJson(json['car_model_details']) == null
          ? null
          : CarModelOption.fromJson(mapFromJson(json['car_model_details'])!),
      translationTargetLanguage: stringFromJson(
        json['translation_target_language'],
      ),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'title': title,
      'translated_title': translatedTitle,
      'title_language': titleLanguage,
      'min_price': minPrice,
      'max_price': maxPrice,
      'status': status,
      'status_details': statusDetails?.toJson(),
      'car_model_details': carModel?.toJson(),
      'translation_target_language': translationTargetLanguage,
    };
  }
}

class PartRequestAccess {
  const PartRequestAccess({
    required this.id,
    required this.partRequest,
    this.partRequestDetails,
    this.conversation,
    required this.user,
    this.userDetails,
    required this.status,
    this.resolvedBy,
    this.resolvedByDetails,
    this.requestedAt,
    this.resolvedAt,
    this.updatedAt,
    this.canApprove = false,
  });

  final int id;
  final int partRequest;
  final PartRequestBrief? partRequestDetails;
  final int? conversation;
  final int user;
  final UserBrief? userDetails;
  final String status;
  final int? resolvedBy;
  final UserBrief? resolvedByDetails;
  final DateTime? requestedAt;
  final DateTime? resolvedAt;
  final DateTime? updatedAt;
  final bool canApprove;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  factory PartRequestAccess.fromJson(JsonMap json) {
    return PartRequestAccess(
      id: intFromJson(json['id']) ?? 0,
      partRequest: intFromJson(json['part_request']) ?? 0,
      partRequestDetails: mapFromJson(json['part_request_details']) == null
          ? null
          : PartRequestBrief.fromJson(
              mapFromJson(json['part_request_details'])!,
            ),
      conversation: intFromJson(json['conversation']),
      user: intFromJson(json['user']) ?? 0,
      userDetails: mapFromJson(json['user_details']) == null
          ? null
          : UserBrief.fromJson(mapFromJson(json['user_details'])!),
      status: stringFromJson(json['status']) ?? '',
      resolvedBy: intFromJson(json['resolved_by']),
      resolvedByDetails: mapFromJson(json['resolved_by_details']) == null
          ? null
          : UserBrief.fromJson(mapFromJson(json['resolved_by_details'])!),
      requestedAt: dateTimeFromJson(json['requested_at']),
      resolvedAt: dateTimeFromJson(json['resolved_at']),
      updatedAt: dateTimeFromJson(json['updated_at']),
      canApprove: boolFromJson(json['can_approve']) ?? false,
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'part_request': partRequest,
      'part_request_details': partRequestDetails?.toJson(),
      'conversation': conversation,
      'user': user,
      'user_details': userDetails?.toJson(),
      'status': status,
      'resolved_by': resolvedBy,
      'resolved_by_details': resolvedByDetails?.toJson(),
      'requested_at': requestedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'can_approve': canApprove,
    };
  }
}
