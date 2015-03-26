// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_common;

abstract class PackageReporter {
  final Map<String, DiffNode> diff = new Map<String, DiffNode>();
  Writer writer;
  MarkdownWriter io;

  void calculateAllDiffs();

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