// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for Shapeshift's variables reporter.
library variables_reporter_tests;

import 'dart:convert';

import 'package:json_diff/json_diff.dart';
import 'package:shapeshift/shapeshift_cli.dart';
import 'package:shapeshift/shapeshift_common.dart';
import 'package:unittest/unittest.dart';


void main() {
  ReadableStringSink io;
  Map<String, dynamic> v1, v2;

  jsonFrom(Map obj) => new JsonEncoder().convert(obj);
  expectIoContains(RegExp re) => expect(io.read(), matches(re));

  setUp(() {
    io = new ReadableStringSink();
  });

  test('Shapeshift reports on new variables', () {
    v1 = classWith({'foo': variableNamed('foo')});
    v2 = classWith({'foo': variableNamed('foo'),
                    'bar': variableNamed('bar')});

    diffAndReport(jsonFrom(v1), jsonFrom(v2), io);
    expectIoContains(new RegExp(
        r'''New variables:

```dart
dart:core.String bar;
```'''));
  });

  test('Shapeshift reports on removed variables', () {
    v1 = classWith({'foo': variableNamed('foo'),
                    'bar': variableNamed('bar')});
    v2 = classWith({'foo': variableNamed('foo')});

    diffAndReport(jsonFrom(v1), jsonFrom(v2), io);
    expectIoContains(new RegExp(
        r'''Removed variables:

```dart
dart:core.String bar;
```'''));
  });
}

Map<String, dynamic> classWith(Map variables) =>
  baseClass
    ..['variables'] = variables;

Map<String, dynamic> get baseClass => {
  'name': 'Foo',
  'qualifiedName': 'foo.Foo',
  'variables': {},
};

Map<String, dynamic> variableNamed(String name) =>
    baseVariable
      ..['name'] = name
      ..['qualifiedName'] = 'foo.Foo.$name';

Map<String, dynamic> get baseVariable => {
  'name': 'foo',
  'qualifiedName': 'foo.Foo.foo',
  'comment': '<p>Send a data event to a stream.</p>',
  'final': false,
  'static': false,
  'constant': false,
  'type': [
    {'outer': 'dart:core.String', 'inner': []},
  ],
  'annotations': [],
};

void diffAndReport(String v1, String v2, ReadableStringSink io) {
  DiffNode diff = diffApis(v1, v2);
  MarkdownWriter mw = new MarkdownWriter(() => io, false);
  Function noop = (Map m, [String key]) { };
  new VariablesReporter('variables', diff['variables'], mw, noop).report();
}