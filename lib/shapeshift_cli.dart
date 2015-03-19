// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shapeshift_cli;

import 'dart:async';
import 'dart:io';

import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:json_diff/json_diff.dart';
import 'package:path/path.dart' as p;

import 'shapeshift_common.dart';

part 'src/cli/package_reporter.dart';
part 'src/cli/markdown_writer.dart';
