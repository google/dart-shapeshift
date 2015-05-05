// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shapeshift_common.library_reporter;

import 'package:json_diff/json_diff.dart';

import '../markdown_diff_writer.dart';
import 'methods_reporter.dart';
import 'classes_reporter.dart';

class LibraryReporter {
  static bool shouldErase = true;

  final DiffNode diff;
  final MarkdownDiffWriter io;
  String qualifiedName;

  LibraryReporter(this.diff, this.io) {
    qualifiedName = diff.metadata['qualifiedName'];
  }

  void report() {
    if (diff == null) return;

    io.bufferH1(qualifiedName);
    reportLibrary();

    // After reporting, prune and print anything remaining.
    diff.prune();
    diff.metadata.clear();
    String diffString = diff.toString();
    if (diffString.isNotEmpty) {
      print('ERROR: $qualifiedName has unresolved nodes:\n$diffString');
    }
  }

  void reportLibrary() {
    if (diff.changed.containsKey('packageIntro')) {
      io.writeBad(
          'TODO: The <strong>packageIntro</strong> changed, which is probably '
          'huge. Not including here yet.');
      erase(diff.changed, 'packageIntro');
    }

    // Iterate over the class categories ('classes', 'typedefs', 'errors').
    diff.forEachOf('classes', (String classCategory, DiffNode classDiff) =>
        new ClassesReporter(classCategory, classDiff, qualifiedName, io, erase)
            .report());

    diff.changed.forEach((String key, List oldNew) {
      io.writeln("${diff.metadata['name']}'s `${key}` changed:\n");
      io.writeWasNow((oldNew as List<String>)[0], (oldNew as List<String>)[1],
          blockquote: key == 'comment');
      io.writeHr();
    });
    diff.changed.clear();

    // TODO: report variables.

    diff.forEachOf('functions', _reportEachMethodCategory);
  }

  void _reportEachMethodCategory(String methodCategory, DiffNode diff) =>
      new MethodsReporter(methodCategory, diff, io, erase).report();

  void erase(Map m, [String key]) {
    if (!shouldErase) return;

    if (key == null) m.clear();
    else m.remove(key);
  }
}
