// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_cli;

/// A [PackageReporter] that calculates the diff between APIs found in two
/// directories.
///
/// The constructor takes the paths of the two directories, and a [Writer].
/// After it has been constructed, a [DirectoryPackageReporter] can calculate
/// the diffs of all the files in the two directories, recursively, with
/// [calculateAllDiffs], and can report the diffs into the [Writer] with
/// [report].
class DirectoryPackageReporter extends PackageReporter {
  final String leftPath, rightPath;

  DirectoryPackageReporter(this.leftPath, this.rightPath, Writer _writer) {
    writer = _writer;
  }

  void calculateDiff(String fileName) {
    File left = new File(path.join(leftPath, fileName));
    File right = new File(path.join(rightPath, fileName));
    if (!left.existsSync()) {
      String associatedLibrary = associatedLibraryJsonPath(left.path);
      if (associatedLibrary != null)
        // TODO: I'm thinking of not printing anything here.
        print('"${left.path}" doesn\'t exist; diffing '
              '$associatedLibrary should catch this.');
      else
        print('Hmm... "${left.path} doesn\'t exist, which is weird.');
      return;
    }
    diff[fileName] = diffApis(left.readAsStringSync(), right.readAsStringSync());
  }

  void calculateAllDiffs() {
    List rightRawLs = new Directory(rightPath).listSync(recursive: true);
    List rightLs = rightRawLs
        .where((FileSystemEntity f) => f is File)
        .map((File f) => f.path)
        .toList();

    rightLs.forEach((String file) {
      file = path.relative(file, from: rightPath);
      if (path.basename(file) == 'index.json' ||
          path.basename(file) == 'library_list.json' ||
          path.extension(file) != '.json') {
        print('Skipping $file');
        return;
      }
      calculateDiff(file);
    });
  }
}
