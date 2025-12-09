import '../core/data/pojo/intru_list.dart';

extension IntrusionNumberHelper on IntrusionNumber {
  List<String> getValidIntrusionNumbers() {
    return [
          intru1,
          intru2,
          intru3,
          intru4,
          intru5,
          intru6,
          intru7,
          intru8,
          intru9,
          intru10,
        ]
        .where((number) => number != null && number.trim().isNotEmpty)
        .map((e) => e!)
        .toList();
  }
}
