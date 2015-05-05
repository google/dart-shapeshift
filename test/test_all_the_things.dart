import 'package:test/test.dart';

import 'class_reporter_test.dart' as class_reporter_test;
import 'method_attributes_reporter_test.dart'
    as method_attributes_reporter_test;
import 'methods_reporter_test.dart' as methods_reporter_test;
import 'utils_test.dart' as utils_test;
import 'variables_reporter_test.dart' as variables_reporter_test;

void main() {
  group('class_reporter', class_reporter_test.main);
  group('method_attributes_reporter', method_attributes_reporter_test.main);
  group('methods_reporter', methods_reporter_test.main);
  group('utils', utils_test.main);
  group('variables_reporter', variables_reporter_test.main);
}
