import 'package:flutter/foundation.dart';
import 'package:fire_nex/data/database/app_database.dart';
import 'package:fire_nex/data/repositories/fire_repo.dart';

class FireNumberViewModel {
  final FireRepository _fireRepository;

  FireNumberViewModel(this._fireRepository);

  Future<bool> insertFireNumber(
    String panelSimNumber,
    String fireNumber,
  ) async {
    try {
      await _fireRepository.insertFireNumber(panelSimNumber, fireNumber);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Insert failed: $e');
      }
      return false;
    }
  }

  Future<List<FireNumber>> getFireNumbersByPanelSimNumber(
    String panelSimNumber,
  ) {
    return _fireRepository.getFireNumbersByPanelSimNumber(panelSimNumber);
  }
}
