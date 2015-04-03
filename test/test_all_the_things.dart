import './shapeshift/class_reporter_test.dart' as class_reporter_test;
import './shapeshift/method_attributes_reporter_test.dart' as method_attributes_reporter_test;
import './shapeshift/methods_reporter_test.dart' as methods_reporter_test;
import './shapeshift/utils_test.dart' as utils_test;
import './shapeshift/variables_reporter_test.dart' as variables_reporter_test;

void main() {
  // Shapeshift tests.
  class_reporter_test.main();
  method_attributes_reporter_test.main();
  methods_reporter_test.main();
  utils_test.main();
  variables_reporter_test.main();
}
