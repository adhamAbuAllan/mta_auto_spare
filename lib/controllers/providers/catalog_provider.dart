import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import 'api_provider.dart';

final carCatalogProvider = FutureProvider<List<CarMakeOption>>((ref) async {
  return ref.read(catalogApiProvider).getAllCarMakes();
});

final allCarModelsProvider = Provider<List<CarModelOption>>((ref) {
  final catalog = ref.watch(carCatalogProvider).valueOrNull ?? const [];
  return [
    for (final make in catalog) ...make.models,
  ];
});
