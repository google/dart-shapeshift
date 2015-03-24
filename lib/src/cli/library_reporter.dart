// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_cli;

class LibraryReporter {
  final Map<String, DiffNode> diff = new Map<String, DiffNode>();
  final String leftPath, rightPath;
  final Writer writer;
  MarkdownWriter io;

  LibraryReporter(this.leftPath, this.rightPath, {this.writer});

  void calculateDiff(String fileName) {
    File leftFile = new File(p.join(leftPath, fileName));
    File rightFile = new File(p.join(rightPath, fileName));
    if (!leftFile.existsSync()) {
      print(
          '$leftFile doesn\'t exist, which should be caught in the package json.');
      return;
    }
    JsonDiffer differ = new JsonDiffer(
        leftFile.readAsStringSync(), rightFile.readAsStringSync());
    differ.atomics
      ..add('type')
      ..add('return')
      ..add('annotations[]');
    differ.metadataToKeep..add('qualifiedName');
    differ.ensureIdentical(['name', 'qualifiedName']);
    diff[fileName] = differ.diff()
      ..metadata['qualifiedName'] = differ.leftJson['qualifiedName']
      ..metadata['name'] = differ.leftJson['name']
      ..metadata['packageName'] = differ.leftJson['packageName'];
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
    Map<String, PackageSdk> diffsBySubpackage = new Map();
    diff.forEach((String file, DiffNode node) {
      if (node.metadata['packageName'] != null) {
        String subpackage = node.metadata['qualifiedName'];
        if (!diffsBySubpackage.containsKey(subpackage)) {
          diffsBySubpackage[subpackage] = new PackageSdk();
        }
        diffsBySubpackage[subpackage].package = node;
      } else {
        String subpackage = getSubpackage(node);
        if (!diffsBySubpackage.containsKey(subpackage)) {
          diffsBySubpackage[subpackage] = new PackageSdk();
        }
        diffsBySubpackage[subpackage].classes.add(node);
      }
    });

    diffsBySubpackage.forEach((String name, PackageSdk p) {
      io = writer.writerFor(name);
      io.writeMetadata(name);
      reportFile(name, p.package);
      p.classes.forEach((k) => reportFile(name, k));
      io.close();
    });
  }

  void reportFile(String name, DiffNode d) {
    new FileReporter(name, d, io: io).report();
  }

  String getSubpackage(DiffNode node) {
    return (node.metadata['qualifiedName']).split('.')[0];
  }
}

class PackageSdk {
  final List<DiffNode> classes = new List();
  DiffNode package;
}
