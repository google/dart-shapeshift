// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shapeshift_common.libarry_api_diff;

import 'package:doc_coverage/doc_coverage_common.dart';
import 'package:json_diff/json_diff.dart' show DiffNode;

import 'reporters/class_reporter.dart';
import 'reporters/library_reporter.dart';

class LibraryApiDiff {
  String libraryName;
  DiffNode lybrary;
  final List<DiffNode> classes = new List();

  void report(MarkdownWriter _io) {
    _io.writeMetadata(libraryName);
    new LibraryReporter(lybrary, _io).report();
    classes.forEach((diff) => new ClassReporter(diff, _io).report());
    _io.close();
  }
}
