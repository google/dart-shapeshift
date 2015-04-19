// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_common;

abstract class PackageReporter {
  final Map<String, DiffNode> diff = new Map<String, DiffNode>();
  Map<String, LibraryApiDiff> libraryDiffs = new Map();
  WriterProvider writer;
  bool includeComments;

  void calculateAllDiffs();

  void add(String name, DiffNode node) {
    diff[name] = node;

    if (node.metadata['packageName'] != null) {
      // Here, file represents the API of a library.
      String libraryName = node.metadata['qualifiedName'];
      if (!libraryDiffs.containsKey(libraryName))
        libraryDiffs[libraryName] = new LibraryApiDiff();
      libraryDiffs[libraryName].libraryName = libraryName;
      libraryDiffs[libraryName].lybrary = node;
    } else {
      // Here, file represents the API of a class...
      // or other library member(?).
      String libraryName = node.metadata['qualifiedName'].split('.')[0];
      if (!libraryDiffs.containsKey(libraryName))
        libraryDiffs[libraryName] = new LibraryApiDiff();
      libraryDiffs[libraryName].classes.add(node);
    }
  }

  void report() {
    libraryDiffs.forEach((String name, LibraryApiDiff libraryDiff) {
      libraryDiff.report(writer.writerFor(name));
    });
  }
}