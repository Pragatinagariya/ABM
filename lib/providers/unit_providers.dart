// providers/unit_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/unit_model.dart';
import '../../data/services/unit_service.dart';

final unitProvider = FutureProvider<List<UnitModel>>((ref) async {
  return UnitService().fetchUnits();
});
