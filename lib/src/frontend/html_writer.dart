// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shapeshift.frontend.html_writer;

import 'dart:html';

import 'package:markdown/markdown.dart' hide Element, Node;

import 'null_tree_sanitizer.dart';

class HtmlWriter extends StringSink {
  final Element el;

  HtmlWriter(this.el);

  void write(Object obj) {
    // I'm a little worried about this... I have to gunarantee _no_ nesting
    // here, like `write("* bullet"); write("* another bullet");`.
    el.setInnerHtml(el.innerHtml + markdownToHtml(obj.toString()),
        treeSanitizer: nullTreeSanitizer);
  }

  void writeAll(Iterable objects, [String separator = ""]) {
    // Don't use.
  }

  void writeCharCode(int charCode) {
    // Don't use.
  }

  void writeln([Object obj = '']) => write(obj.toString() + '\n');
}
