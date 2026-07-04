// ignore_for_file: directives_ordering
// Driver entrypoint — enables flutter_driver extension for integration tests.
// Run: flutter run -d chrome --target=lib/driver_main.dart ...

import 'package:flutter_driver/driver_extension.dart';
import 'main.dart' as app;

void main() {
  enableFlutterDriverExtension();
  app.main();
}
