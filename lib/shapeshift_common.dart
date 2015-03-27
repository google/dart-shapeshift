// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shapeshift_common;

import 'dart:async';
import 'dart:convert';

import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:json_diff/json_diff.dart';

export 'package:json_diff/json_diff.dart' show DiffNode;

part 'src/common/api_differ.dart';
part 'src/common/dartdoc_viewer_utils.dart';
part 'src/common/docs_location.dart';
part 'src/common/library_api_diff.dart';
part 'src/common/markdown_writer.dart';
part 'src/common/readable_string_sink.dart';
part 'src/common/utils.dart';
part 'src/common/writer.dart';

part 'src/common/reporters/classes_reporter.dart';
part 'src/common/reporters/class_reporter.dart';
part 'src/common/reporters/library_reporter.dart';
part 'src/common/reporters/method_attributes_reporter.dart';
part 'src/common/reporters/methods_reporter.dart';
part 'src/common/reporters/package_reporter.dart';
part 'src/common/reporters/variables_reporter.dart';