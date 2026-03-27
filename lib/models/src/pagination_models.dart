import 'json_utils.dart';

class ApiPage<T> {
  const ApiPage({this.count, this.next, this.previous, required this.results});

  final int? count;
  final String? next;
  final String? previous;
  final List<T> results;

  factory ApiPage.fromJson(JsonMap json, T Function(JsonMap json) fromJson) {
    return ApiPage<T>(
      count: intFromJson(json['count']),
      next: stringFromJson(json['next']),
      previous: stringFromJson(json['previous']),
      results: listFromJson(json['results'], fromJson),
    );
  }

  JsonMap toJson(JsonMap Function(T value) toJson) {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map(toJson).toList(growable: false),
    };
  }
}
