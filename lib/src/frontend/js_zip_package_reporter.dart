// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

import 'dart:async';

import 'package:doc_coverage/doc_coverage_common.dart';
import 'package:sdk_builds/sdk_builds.dart';

import '../../shapeshift_common.dart';
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
  final VersionInfo leftRevision, rightRevision;

  JSZipPackageReporter(
      this.leftZip, this.rightZip, this.leftRevision, this.rightRevision,
      {includeComments: true})
      : super(includeComments: includeComments);

  void _calculateDiff(PackageReport report, String fileName) {
    // If fileName not found in the left Zip, it will be noted in the library
    // JSON file.
    if (!leftZip.hasFile(fileName)) return;
    report.add(fileName, diffSdkApis(leftZip.read(fileName),
        rightZip.read(fileName), leftRevision, rightRevision,
        includeComments: includeComments));
  }

  /// This can be *slow*, so it is async and it inserts a small delay before
  /// processing each file to ensure UI – like a web page – can update.
  Future<PackageReport> calculateDiffForLibrary(String library) async {
    var report = new PackageReport();

    for (var fileName in rightZip.filesByLibrary[library]) {
      await _calculateDiff(report, fileName);
      await letHtmlUpdate();
    }

    return report;
  }

  PackageReport calculateAllDiffs() {
    var report = new PackageReport();

    for (var fileName in rightZip.filesByLibrary['dart-core']) {
      _calculateDiff(report, fileName);
    }

    return report;
  }
}

Future letHtmlUpdate() async {
  // inject a delay so that the html updates
  await new Future.delayed(const Duration(seconds: 0));
}
