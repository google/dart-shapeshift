// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shapeshift_cli;

import 'dart:io';

import 'package:json_diff/json_diff.dart';
import 'package:path/path.dart' as p;

import 'shapeshift_common.dart';

part 'src/cli/classes_reporter.dart';
part 'src/cli/directory_writer.dart';
part 'src/cli/file_reporter.dart';
part 'src/cli/library_reporter.dart';
part 'src/cli/method_attributes_reporter.dart';
part 'src/cli/methods_reporter.dart';
part 'src/cli/single_sink_writer.dart';
part 'src/cli/variables_reporter.dart';
