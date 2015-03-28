// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for Shapeshift's class reporter.
library class_reporter_tests;

import 'package:shapeshift/shapeshift_common.dart';
import 'package:unittest/unittest.dart';

import 'test_helpers.dart';

void main() {
  ReadableStringSink io;
  Map<String, dynamic> v1, v2;

  expectIoContains(RegExp re) => expect(io.read(), matches(re));

  setUp(() {
    io = new ReadableStringSink();
  });

  test('Shapeshift reports on changed class superclass', () {
    v1 = baseClass;
    v2 = baseClass
      ..['superclass'] = 'dart:core.String';

    diffAndReport(jsonFrom(v1), jsonFrom(v2), io);
    expectIoContains(new RegExp(
        r'''class \[Foo\]\(.*\)
---+

Foo's `superclass` changed:

Was: dart:core.Object

Now: \[dart:core.String\]\(.*\)'''));
  });

  test('Shapeshift reports on new class annotations', () {
    v1 = baseClass;
    v2 = baseClass
      ..['annotations']
          .add({'name':'metadata.Unstable.Unstable-','parameters':[]});

    diffAndReport(jsonFrom(v1), jsonFrom(v2), io);
    expectIoContains(new RegExp(
        r'''class \[Foo\]\(.*\)
---+

Foo has new annotations:

\* `@Unstable-\(\)`'''));
  });

  test('Shapeshift reports on new subclasses', () {
    v1 = baseClass;
    v2 = baseClass
      ..['subclass'].add('foo.Bar');

    diffAndReport(jsonFrom(v1), jsonFrom(v2), io);
    expectIoContains(new RegExp(
        r'''class \[Foo\]\(.*\)
---+

Foo has new subclasses:

\* \[foo.Bar\]\(.*\)'''));
  });
}

void diffAndReport(String v1, String v2, ReadableStringSink io) {
  DiffNode diff = diffApis(v1, v2);
  MarkdownWriter writer = new MarkdownWriter(() => io, false);
  new ClassReporter(diff, writer).report();
}