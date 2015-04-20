// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_frontend;

class HtmlWriter extends StringSink {
  Element el;

  HtmlWriter(this.el);

  void write(Object obj) {
    // I'm a little worried about this... I have to gunarantee _no_ nesting
    // here, like `write("* bullet"); write("* another bullet");`.
    el.setInnerHtml(el.innerHtml + markdownToHtml(obj.toString()),
        treeSanitizer: allHtml);
  }

  void writeAll(Iterable objects, [String separator = ""]) {
    // Don't use.
  }

  void writeCharCode(int charCode) {
    // Don't use.
  }

  void writeln([Object obj = '']) => write(obj.toString() + '\n');
}
