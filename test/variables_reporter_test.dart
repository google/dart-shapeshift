// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for Shapeshift's variables reporter.
library variables_reporter_tests;

import 'package:shapeshift/shapeshift_common.dart';
import "package:test/test.dart";

import 'test_helpers.dart';

void main() {
  ReadableStringSink io;
  Map<String, dynamic> v1, v2;

  expectIoContains(String re) => expect(io.read(), matches(new RegExp(re)));

  setUp(() {
    io = new ReadableStringSink();
  });

  test('Shapeshift reports on new variables', () {
    v1 = classWithVariables({'foo': variableNamed('foo')});
    v2 = classWithVariables(
        {'foo': variableNamed('foo'), 'bar': variableNamed('bar')});

    diffAndReport(jsonFrom(v1), jsonFrom(v2), io);
    expectIoContains(r'New variables:\n'
        r'\n'
        r'```dart\n'
        r'dart:core.String bar;\n'
        r'```');
  });

  test('Shapeshift reports on removed variables', () {
    v1 = classWithVariables(
        {'foo': variableNamed('foo'), 'bar': variableNamed('bar')});
    v2 = classWithVariables({'foo': variableNamed('foo')});

    diffAndReport(jsonFrom(v1), jsonFrom(v2), io);
    expectIoContains(r'Removed variables:\n'
        r'\n'
        r'```dart\n'
        r'dart:core.String bar;\n'
        r'```');
  });

  test('Shapeshift reports on variables with changed attributes', () {
    v1 = classWithVariables({'foo': variableNamed('foo')});
    Map v2Variable = variableNamed('foo')
      ..['annotations']
          .add({'name': 'metadata.Unstable.Unstable-', 'parameters': []});
    v2 = classWithVariables({'foo': v2Variable});

    diffAndReport(jsonFrom(v1), jsonFrom(v2), io);
    expectIoContains(r"The \[foo\]\(.*\) variable has new annotations:\n"
        r'\n'
        r'\* `@Unstable-\(\)`');
  });
}

void diffAndReport(String v1, String v2, ReadableStringSink io) {
  DiffNode diff = diffApis(v1, v2);
  MarkdownDiffWriter w = new MarkdownDiffWriter(() => io, shouldClose: false);
  Function noop = (Map m, [String key]) {};
  new VariablesReporter('variables', diff['variables'], w, noop).report();
}
