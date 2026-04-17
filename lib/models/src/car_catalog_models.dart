import 'json_utils.dart';

class CarModelOption {
  const CarModelOption({
    required this.id,
    required this.makeId,
    required this.makeName,
    required this.name,
    required this.displayName,
    this.imageUrl,
    this.isActive = true,
  });

  final int id;
  final int makeId;
  final String makeName;
  final String name;
  final String displayName;
  final String? imageUrl;
  final bool isActive;

  factory CarModelOption.fromJson(JsonMap json) {
    final makeName = stringFromJson(json['make_name']) ?? '';
    final name = stringFromJson(json['name']) ?? '';
    return CarModelOption(
      id: intFromJson(json['id']) ?? 0,
      makeId: intFromJson(json['make_id']) ?? 0,
      makeName: makeName,
      name: name,
      displayName:
          stringFromJson(json['display_name']) ??
          [makeName, name].where((item) => item.trim().isNotEmpty).join(' '),
      imageUrl: stringFromJson(json['image_url']),
      isActive: boolFromJson(json['is_active']) ?? true,
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'make_id': makeId,
      'make_name': makeName,
      'name': name,
      'display_name': displayName,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }
}

class CarMakeOption {
  const CarMakeOption({
    required this.id,
    required this.name,
    required this.slug,
    this.models = const [],
  });

  final int id;
  final String name;
  final String slug;
  final List<CarModelOption> models;

  factory CarMakeOption.fromJson(JsonMap json) {
    return CarMakeOption(
      id: intFromJson(json['id']) ?? 0,
      name: stringFromJson(json['name']) ?? '',
      slug: stringFromJson(json['slug']) ?? '',
      models: listFromJson(json['models'], CarModelOption.fromJson),
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'models': models.map((item) => item.toJson()).toList(growable: false),
    };
  }
}
