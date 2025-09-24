import 'package:flutter/foundation.dart';
import 'package:fire_nex/data/database/app_database.dart';
import 'package:fire_nex/data/repositories/intrusion_repo.dart';

class IntrusionViewModel {
  final IntrusionRepository _intrusionRepository;

  IntrusionViewModel(this._intrusionRepository);

  Future<bool> insertIntrusionNumber(
    String panelSimNumber,
    String intrusionNumber,
  ) async {
    try {
      await _intrusionRepository.insertIntrusionNumber(
        panelSimNumber,
        intrusionNumber,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Insert failed: $e');
      }
      return false;
    }
  }

  Future<List<IntrusionNumber>> getIntrusionNumbersByPanelSimNumber(
    String panelSimNumber,
  ) {
    return _intrusionRepository.getIntrusionNumbersByPanelSimNumber(
      panelSimNumber,
    );
  }
}
