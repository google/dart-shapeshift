// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_cli;

class DirectoryWriter extends Writer {
  String path;
  Directory dir;

  DirectoryWriter(this.path) {
    dir = new Directory(path)
      ..createSync(recursive: true);
  }

  MarkdownWriter writerFor(String libraryName) {
    return new MarkdownWriter(() {
      File f = new File('$path/$libraryName.markdown')
        ..createSync(recursive: true);
      return f.openWrite();
    });
  }
}