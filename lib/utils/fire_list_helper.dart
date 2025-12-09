import '../core/data/pojo/fire_list.dart';

extension FireNumberHelper on FireNumber {
  List<String> getValidFireNumbers() {
    return [
          fire1,
          fire2,
          fire3,
          fire4,
          fire5,
          fire6,
          fire7,
          fire8,
          fire9,
          fire10,
        ]
        .where((number) => number != null && number.trim().isNotEmpty)
        .map((e) => e!)
        .toList();
  }
}
