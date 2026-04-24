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

Map<int, DateTime?> dateTimeMapByIntKeyFromJson(dynamic value) {
  final map = mapFromJson(value);
  if (map == null || map.isEmpty) {
    return const {};
  }

  final result = <int, DateTime?>{};
  map.forEach((key, rawValue) {
    final parsedKey = int.tryParse(key);
    if (parsedKey == null) {
      return;
    }
    result[parsedKey] = dateTimeFromJson(rawValue);
  });
  return result;
}

String translatedTextOrOriginal(String originalText, String? translatedText) {
  final normalizedTranslation = translatedText?.trim() ?? '';
  if (normalizedTranslation.isEmpty) {
    return originalText;
  }
  return normalizedTranslation;
}

bool hasVisibleTranslation(String originalText, String? translatedText) {
  final normalizedOriginal = originalText.trim();
  final normalizedTranslation = translatedText?.trim() ?? '';
  if (normalizedTranslation.isEmpty) {
    return false;
  }
  return normalizedTranslation != normalizedOriginal;
}
