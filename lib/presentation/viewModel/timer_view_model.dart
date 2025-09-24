import 'package:flutter/foundation.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/timer_repo.dart';

class TimerViewModel {
  final TimerRepository _timerRepository;

  TimerViewModel(this._timerRepository);

  // Insert Entry
  Future<void> addEntryTime(String sim, String entryTime) async {
    try {
      await _timerRepository.insertEntryTime(sim, entryTime);
      print('Saving entryTime=$entryTime for panelSimNumber=$sim');
    } catch (e) {
      if (kDebugMode) {
        print('Insert failed: $e');
      }
    }
  }

  // Insert Exit
  Future<void> addExitTime(String sim, String exitTime) async {
    try {
      await _timerRepository.insertExitTime(sim, exitTime);
    } catch (e) {
      if (kDebugMode) {
        print('Insert failed: $e');
      }
    }
  }

  // Insert Sounder Time
  Future<void> addSounderTime(String sim, String sounderTime) async {
    try {
      await _timerRepository.insertSounderTime(sim, sounderTime);
    } catch (e) {
      if (kDebugMode) {
        print('Insert failed: $e');
      }
    }
  }

  Future<List<TimerTableData>> getTimersByPanelSim(String panelSimNumber) {
    return _timerRepository.getTimersByPanelSim(panelSimNumber);
  }
}
