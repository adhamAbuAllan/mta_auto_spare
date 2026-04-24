import 'package:flutter_test/flutter_test.dart';

import 'package:mta_auto_spare/models/models.dart';

void main() {
  test('PartRequest parses nullable city and images from api payload', () {
    final request = PartRequest.fromJson({
      'id': 14,
      'requester': 2,
      'title': 'Need bumper',
      'translated_title': 'احتاج صدام',
      'title_language': 'en',
      'description': 'Original preferred',
      'translated_description': 'يفضل الأصلي',
      'description_language': 'en',
      'min_price': '100.00',
      'max_price': '250.00',
      'status': 1,
      'city': null,
      'translation_target_language': 'ar',
      'images': [
        {
          'id': 9,
          'part_request': 14,
          'image': '/media/part_requests/sample.jpg',
          'created_at': '2026-04-03T10:00:00Z',
        },
      ],
    });

    expect(request.city, isNull);
    expect(request.images, hasLength(1));
    expect(request.images.single.image, '/media/part_requests/sample.jpg');
    expect(request.displayTitle, 'احتاج صدام');
    expect(request.displayDescription, 'يفضل الأصلي');
    expect(request.hasTranslatedContent, isTrue);
  });
}
