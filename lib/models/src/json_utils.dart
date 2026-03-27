typedef JsonMap = Map<String, dynamic>;

DateTime? dateTimeFromJson(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.parse(value.toString());
}

int? intFromJson(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  return int.tryParse(value.toString());
}

bool? boolFromJson(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }
  final normalized = value.toString().toLowerCase();
  if (normalized == 'true' || normalized == '1') {
    return true;
  }
  if (normalized == 'false' || normalized == '0') {
    return false;
  }
  return null;
}

String? stringFromJson(dynamic value) {
  if (value == null) {
    return null;
  }
  return value.toString();
}

JsonMap? mapFromJson(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return null;
}

List<T> listFromJson<T>(dynamic value, T Function(JsonMap json) fromJson) {
  if (value is! List) {
    return const [];
  }
  return value
      .map(mapFromJson)
      .whereType<JsonMap>()
      .map(fromJson)
      .toList(growable: false);
}

List<int> intListFromJson(dynamic value) {
  if (value is! List) {
    return const [];
  }
  return value.map(intFromJson).whereType<int>().toList(growable: false);
}
