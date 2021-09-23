// This is an example unit test.
//
// A unit test tests a single function, method, or class. To learn more about
// writing unit tests, visit
// https://flutter.dev/docs/cookbook/testing/unit/introduction

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Duration toString', () {
    test('should convert to string', () {
      int ago = -30;
      final duration = Duration(milliseconds: ago);
      final val = duration.toString();
      expect(val, '-0:00:00.030000');
    });
  });
}
