// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shapeshift;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:json_diff/json_diff.dart';

part 'src/package_reporter.dart';
part 'src/markdown_writer.dart';
part 'src/dartdoc_viewer_utils.dart';
