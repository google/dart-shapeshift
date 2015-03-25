// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for Shapeshift's method attributes reporter.
library method_attributes_reporter_tests;

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

  test('Shapeshift reports on changed method attributes', () {
    v1 = base;
    v2 = base
      ..['abstract'] = true;

    diffAndReport(jsonFrom(v1), jsonFrom(v2), io);
    expectIoContains(new RegExp(
        r'''The \[foo\]\(.*\) method's `abstract` changed:

Was: `false`

Now: `true`'''));
  });

  test('Shapeshift reports on deep method attribute additions', () {
    v1 = base;
    v2 = base
      ..['annotations'].add({'name':'foo.Bar','parameters':[]});

    diffAndReport(jsonFrom(v1), jsonFrom(v2), io);
    expectIoContains(new RegExp(
        r'''The \[foo\]\(.*\) method has new annotations:

\* `@Bar\(\)`'''));
  });

  test('Shapeshift reports on deep method attribute removals', () {
    v1 = base
      ..['annotations'].add({'name':'foo.Bar','parameters':[]});
    v2 = base;

    diffAndReport(jsonFrom(v1), jsonFrom(v2), io);
    expectIoContains(new RegExp(
        r'''The \[foo\]\(.*\) method has removed annotations:

\* `@Bar\(\)`'''));
  });
}

Map<String, dynamic> get base => {
  'name': 'foo',
  'qualifiedName': 'foo.Foo.foo',
  'comment': '<p>Send a data event to a stream.</p>',
  'commentFrom': '',
  'inheritedFrom': '',
  'static': false,
  'abstract': false,
  'constant': false,
  'return': [
    {'outer': 'dart:core.Foo', 'inner': []},
  ],
  'parameters': {},
  'annotations': [],
};

void diffAndReport(String v1, String v2, ReadableStringSink io) {
  DiffNode diff = diffApis(v1, v2);
  MarkdownWriter mw = new MarkdownWriter(() => io, false);
  Function noop = (Map m, [String key]) { };
  new MethodAttributesReporter('method', 'foo', diff, mw, noop).report();
}