// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shapeshift_common.method_reporter;

import 'package:doc_coverage/doc_coverage_common.dart';
import 'package:json_diff/json_diff.dart' show DiffNode;

import 'method_attributes_reporter.dart';

class MethodsReporter {
  final DiffNode diff;
  final MarkdownWriter io;
  final Function erase;

  String category;
  String parenthetical;

  MethodsReporter(_category, this.diff, this.io, this.erase, {this.parenthetical: ''}) {
    category = singularize(_category);
    if (parenthetical.isNotEmpty)
      parenthetical = ' _($parenthetical)_';
  }

  void report() {
    diff.forEachAdded(reportEachAdded);
    erase(diff.added);

    diff.forEachRemoved(reportEachRemoved);
    erase(diff.removed);

    diff.forEach((method, attributes) {
      new MethodAttributesReporter(category, method, attributes, io, erase)
        .report();
    });
  }

  void reportEachAdded(String methodName, Map method) {
    String link = mdLinkToDartlang(method['qualifiedName'], methodName);
    io.writeln('New $category$parenthetical $link:\n');
    io.writeCodeblockHr(methodSignature(method));
  }

  void reportEachRemoved(String methodName, Map method) {
    if (methodName == '')
      methodName = diff.metadata['name'];
    io.writeln('Removed $category$parenthetical $methodName:\n');
    io.writeCodeblockHr(methodSignature(method,
        includeComment: false, includeAnnotations: false));
  }
}
