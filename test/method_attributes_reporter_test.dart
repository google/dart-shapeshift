// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for Shapeshift's method attributes reporter.
library method_attributes_reporter_tests;

import 'package:shapeshift/shapeshift_common.dart';
import "package:test/test.dart";

import 'test_helpers.dart';

void main() {
  ReadableStringSink io;
  Map<String, dynamic> v1, v2;

  expectIoContains(RegExp re) => expect(io.read(), matches(re));

  setUp(() {
    io = new ReadableStringSink();
  });

  test('Shapeshift reports on changed method attributes', () {
    v1 = baseMethod;
    v2 = baseMethod..['abstract'] = true;

    diffAndReport(jsonFrom(v1), jsonFrom(v2), io);
    expectIoContains(new RegExp(
        r'''The \[foo\]\(.*\) method's `abstract` changed:

Was: `false`

Now: `true`'''));
  });

  test('Shapeshift reports on new method annotations', () {
    v1 = baseMethod;
    v2 = baseMethod..['annotations'].add({'name': 'foo.Bar', 'parameters': []});

    diffAndReport(jsonFrom(v1), jsonFrom(v2), io);
    expectIoContains(new RegExp(
        r'''The \[foo\]\(.*\) method has new annotations:

\* `@Bar\(\)`'''));
  });

  test('Shapeshift reports on removed method annotations', () {
    v1 = baseMethod..['annotations'].add({'name': 'foo.Bar', 'parameters': []});
    v2 = baseMethod;

    diffAndReport(jsonFrom(v1), jsonFrom(v2), io);
    expectIoContains(new RegExp(
        r'''The \[foo\]\(.*\) method has removed annotations:

\* `@Bar\(\)`'''));
  });

  test('Shapeshift reports on new method parameters', () {
    v1 = baseMethod;
    v2 = baseMethod..['parameters']['p'] = baseParameter;

    diffAndReport(jsonFrom(v1), jsonFrom(v2), io);
    expectIoContains(new RegExp(r'''The \[foo\]\(.*\) method has new parameters:

\* `dart:core.String p`'''));
  });

  test('Shapeshift reports on new method parameters', () {
    v1 = baseMethod..['parameters']['p'] = baseParameter;
    v2 = baseMethod;

    diffAndReport(jsonFrom(v1), jsonFrom(v2), io);
    expectIoContains(new RegExp(
        r'''The \[foo\]\(.*\) method has removed parameters:

\* `dart:core.String p`'''));
  });
}

void diffAndReport(String v1, String v2, ReadableStringSink io) {
  DiffNode diff = diffApis(v1, v2);
  MarkdownDiffWriter w = new MarkdownDiffWriter(() => io, shouldClose: false);
  Function noop = (Map m, [String key]) {};
  new MethodAttributesReporter('method', 'foo', diff, w, noop).report();
}
