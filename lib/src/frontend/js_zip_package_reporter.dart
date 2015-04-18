// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_frontend;

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

  JSZipPackageReporter(this.leftZip, this.rightZip, WriterProvider _writer) {
    writer = _writer;
  }

  void calculateDiff(String fileName) {
    if (!leftZip.hasFile(fileName)) {
      // fileName not found in the left Zip, which will be noted in the library
      // JSON file.
      return;
    }
    add(fileName, diffApis(leftZip.read(fileName), rightZip.read(fileName)));
  }

  void calculateAllDiffs() {
    //rightZip.jsonFiles.forEach(calculateDiff);
    rightZip.filesByLibrary['dart-async'].forEach(calculateDiff);
  }
}
