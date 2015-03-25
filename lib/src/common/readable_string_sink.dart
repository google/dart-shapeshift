// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_common;

class ReadableStringSink extends StringSink {
  String _buffer = '';

  void write(Object obj) {
    _buffer += obj.toString();
  }

  void writeAll(Iterable objects, [String separator=""]) {
    // Don't use.
  }

  void writeCharCode(int charCode) {
    // Don't use.
  }

  void writeln([Object obj='']) => write(obj.toString() + '\n');

  String read() => _buffer;
}