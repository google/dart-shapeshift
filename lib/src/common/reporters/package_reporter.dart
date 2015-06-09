// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shapeshift_common.package_reporter;

import 'package:doc_coverage/doc_coverage_common.dart';
import 'package:json_diff/json_diff.dart';

import '../library_api_diff.dart';

abstract class PackageReporter {
  final Map<String, DiffNode> diff = new Map<String, DiffNode>();
  final Map<String, LibraryApiDiff> libraryDiffs =
      new Map<String, LibraryApiDiff>();
  final bool includeComments;

  PackageReporter({bool includeComments: false})
      : this.includeComments = includeComments;

  void calculateAllDiffs();

  void add(String name, DiffNode node) {
    diff[name] = node;

    if (node.metadata['packageName'] != null) {
      // Here, file represents the API of a library.
      String libraryName = node.metadata['qualifiedName'];
      if (!libraryDiffs.containsKey(libraryName)) {
        libraryDiffs[libraryName] = new LibraryApiDiff(libraryName, node);
      } else if (libraryDiffs[libraryName].isUninitialized) {
        libraryDiffs[libraryName].libraryName = libraryName;
        libraryDiffs[libraryName].lybrary = node;
      }
    } else {
      // Here, file represents the API of a class...
      // or other library member(?).
      String libraryName = node.metadata['qualifiedName'].split('.')[0];
      var lib = libraryDiffs.putIfAbsent(libraryName, () {
        return new LibraryApiDiff(null, null);
      });
      lib.classes.add(node);
    }
  }

  void writeReport(WriterProvider writer) {
    libraryDiffs.forEach((String name, LibraryApiDiff libraryDiff) {
      libraryDiff.report(writer.writerFor(name));
    });
  }
}
