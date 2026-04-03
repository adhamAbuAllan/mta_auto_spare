import 'package:flutter_test/flutter_test.dart';

import 'package:mta_auto_spare/models/models.dart';

void main() {
  test('PartRequest parses nullable city and images from api payload', () {
    final request = PartRequest.fromJson({
      'id': 14,
      'requester': 2,
      'title': 'Need bumper',
      'description': 'Original preferred',
      'min_price': '100.00',
      'max_price': '250.00',
      'status': 1,
      'city': null,
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
  });
}
