import 'package:flutter/foundation.dart';
import 'package:fire_nex/data/repositories/automation_repo.dart';

import '../../data/database/app_database.dart';

class AutomationViewModel {
  final AutomationRepository _automationRepository;

  AutomationViewModel(this._automationRepository);

  Future<void> accessAutoArm(String panelSimNumber, bool isEnabled) async {
    try {
      await _automationRepository.accessAutoArm(panelSimNumber, isEnabled);
    } catch (e) {
      if (kDebugMode) {
        print('accessAutoArm failed: $e');
      }
    }
  }

  Future<void> resetAutoArm(String panelSimNumber) async {
    try {
      await _automationRepository.resetAutoArm(panelSimNumber);
    } catch (e) {
      if (kDebugMode) {
        print('resetAutoArm failed: $e');
      }
    }
  }

  Future<void> accessAutoDisarm(String panelSimNumber, bool isEnabled) async {
    try {
      await _automationRepository.accessAutoDisarm(panelSimNumber, isEnabled);
    } catch (e) {
      if (kDebugMode) {
        print('accessAutoDisarm failed: $e');
      }
    }
  }

  Future<void> resetAutoDisarm(String panelSimNumber) async {
    try {
      await _automationRepository.resetAutoDisarm(panelSimNumber);
    } catch (e) {
      print('resetAutoDisarm failed: $e');
    }
  }

  Future<void> accessHoliday(String panelSimNumber, bool isEnabled) async {
    try {
      await _automationRepository.accessHoliday(panelSimNumber, isEnabled);
    } catch (e) {
      if (kDebugMode) {
        print('accessHoliday failed: $e');
      }
    }
  }

  Future<void> resetHoliday(String panelSimNumber) async {
    try {
      await _automationRepository.resetHoliday(panelSimNumber);
    } catch (e) {
      print('resetHoliday failed: $e');
    }
  }

  Future<void> addAutoArmTime(String sim, String autoArmTime) async {
    try {
      await _automationRepository.insertAutoArm(sim, autoArmTime);
      print('Saving autoArmTime=$autoArmTime for panelSimNumber=$sim');
    } catch (e) {
      if (kDebugMode) {
        print('Insert failed: $e');
      }
    }
  }

  Future<void> addAutoDisarmTime(String sim, String autoDisarmTime) async {
    try {
      await _automationRepository.insertAutoDisarm(sim, autoDisarmTime);
      print('Saving autoDisarmTime=$autoDisarmTime for panelSimNumber=$sim');
    } catch (e) {
      if (kDebugMode) {
        print('Insert failed: $e');
      }
    }
  }

  Future<void> addHolidayTime(String sim, String holiday) async {
    try {
      await _automationRepository.insertHoliday(sim, holiday);
      print('Saving holiday=$holiday for panelSimNumber=$sim');
    } catch (e) {
      if (kDebugMode) {
        print('Insert failed: $e');
      }
    }
  }

  Future<List<AutomationTableData>> getAutomationBySim(String panelSimNumber) {
    return _automationRepository.getAutomationBySim(panelSimNumber);
  }
}
