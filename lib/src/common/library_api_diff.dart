// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_common;

class LibraryApiDiff {
  String libraryName;
  DiffNode lybrary;
  final List<DiffNode> classes = new List();
  MarkdownWriter io;
  
  void report(MarkdownWriter _io) {
    io = _io;
    io.writeMetadata(libraryName);
    reportFile(libraryName, lybrary);
    classes.forEach((k) => reportFile(libraryName, k));
    io.close();
  }

  reportFile(String name, DiffNode d) =>
    new FileReporter(name, d, io: io).report();
}