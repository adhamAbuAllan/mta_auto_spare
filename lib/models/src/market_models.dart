import 'json_utils.dart';

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
    required this.title,
    required this.description,
    this.minPrice,
    this.maxPrice,
    required this.status,
    this.city,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int requester;
  final String title;
  final String description;
  final String? minPrice;
  final String? maxPrice;
  final int status;
  final String? city;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PartRequest.fromJson(JsonMap json) {
    return PartRequest(
      id: intFromJson(json['id']),
      requester: intFromJson(json['requester']) ?? 0,
      title: stringFromJson(json['title']) ?? '',
      description: stringFromJson(json['description']) ?? '',
      minPrice: stringFromJson(json['min_price']),
      maxPrice: stringFromJson(json['max_price']),
      status: intFromJson(json['status']) ?? 0,
      city: stringFromJson(json['city']),
      createdAt: dateTimeFromJson(json['created_at']),
      updatedAt: dateTimeFromJson(json['updated_at']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'requester': requester,
      'title': title,
      'description': description,
      'min_price': minPrice,
      'max_price': maxPrice,
      'status': status,
      'city': city,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
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
    this.minPrice,
    this.maxPrice,
  });

  final int id;
  final String title;
  final String? minPrice;
  final String? maxPrice;

  factory PartRequestBrief.fromJson(JsonMap json) {
    return PartRequestBrief(
      id: intFromJson(json['id']) ?? 0,
      title: stringFromJson(json['title']) ?? '',
      minPrice: stringFromJson(json['min_price']),
      maxPrice: stringFromJson(json['max_price']),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'title': title,
      'min_price': minPrice,
      'max_price': maxPrice,
    };
  }
}
