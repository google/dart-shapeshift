// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

import '../../shapeshift_common.dart';
import 'package:doc_coverage/doc_coverage_common.dart';

import 'js_zip_wrapper.dart';

/// A [PackageReporter] that calculates the diff between APIs found in two
/// directories.
///
/// The constructor takes the paths of the two directories, and a [WriterProvider].
/// After it has been constructed, a [DirectoryPackageReporter] can calculate
/// the diffs of all the files in the two directories, recursively, with
/// [calculateAllDiffs], and can report the diffs into the [WriterProvider] with
/// [report].
class JSZipPackageReporter extends PackageReporter {
  final JSZipWrapper leftZip, rightZip;
  final int leftRevision, rightRevision;

  JSZipPackageReporter(this.leftZip, this.rightZip, this.leftRevision,
      this.rightRevision, WriterProvider _writer, {includeComments: true})
      : super(_writer, includeComments: includeComments);

  void calculateDiff(String fileName) {
    // If fileName not found in the left Zip, it will be noted in the library
    // JSON file.
    if (!leftZip.hasFile(fileName)) return;
    add(fileName, diffSdkApis(leftZip.read(fileName), rightZip.read(fileName),
        leftRevision, rightRevision, includeComments: includeComments));
  }

  void calculateAllDiffs() {
    //rightZip.jsonFiles.forEach(calculateDiff);
    rightZip.filesByLibrary['dart-core'].forEach(calculateDiff);
  }
}
