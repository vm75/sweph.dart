import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Directory creation tests', () {
    test('Directory does not exist before createSync', () {
      final testDir = Directory('./.test_ephe_dummy');
      if (testDir.existsSync()) {
        testDir.deleteSync(recursive: true);
      }
      expect(testDir.existsSync(), isFalse);
    });
  });
}
