// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_cli;

class PackageReporter {
  final Map<String, DiffNode> diff = new Map<String, DiffNode>();
  final String leftPath, rightPath;
  final Writer writer;
  MarkdownWriter io;

  PackageReporter(this.leftPath, this.rightPath, {this.writer});

  void calculateDiff(String fileName) {
    File leftFile = new File(p.join(leftPath, fileName));
    File rightFile = new File(p.join(rightPath, fileName));
    if (!leftFile.existsSync()) {
      String associatedLibrary = associatedLibraryJsonPath(leftFile.path);
      if (associatedLibrary != null)
        // TODO: I'm thinking of not printing anything here.
        print('"${leftFile.path}" doesn\'t exist; diffing '
              '$associatedLibrary should catch this.');
      else
        print('Hmm... "${leftFile.path} doesn\'t exist, which is weird.');
      return;
    }
    diff[fileName] = diffApis(
        leftFile.readAsStringSync(), rightFile.readAsStringSync());
  }

  void calculateAllDiffs() {
    List<FileSystemEntity> rightRawLs =
        new Directory(rightPath).listSync(recursive: true);
    List<String> rightLs = rightRawLs
        .where((FileSystemEntity f) => f is File)
        .map((File f) => f.path)
        .toList();

    rightLs.forEach((String file) {
      file = p.relative(file, from: rightPath);
      if (p.basename(file) == 'index.json' ||
          p.basename(file) == 'library_list.json' ||
          p.extension(file) != '.json') {
        print('Skipping $file');
        return;
      }
      calculateDiff(file);
    });
  }

  void report() {
    Map<String, LibraryApiDiff> libraryDiffs = new Map();
    diff.forEach((String file, DiffNode node) {
      if (node.metadata['packageName'] != null) {
        String libraryName = node.metadata['qualifiedName'];
        if (!libraryDiffs.containsKey(libraryName))
          libraryDiffs[libraryName] = new LibraryApiDiff();
        libraryDiffs[libraryName].libraryName = libraryName;
        libraryDiffs[libraryName].lybrary = node;
      } else {
        String libraryName = node.metadata['qualifiedName'].split('.')[0];
        if (!libraryDiffs.containsKey(libraryName))
          libraryDiffs[libraryName] = new LibraryApiDiff();
        libraryDiffs[libraryName].classes.add(node);
      }
    });

    libraryDiffs.forEach((String name, LibraryApiDiff diff) {
      io = writer.writerFor(name);
      diff.report(io);
    });
  }
}
