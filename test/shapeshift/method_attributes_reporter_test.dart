// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for Shapeshift's method attributes reporter.
library method_attributes_reporter_tests;

import 'package:json_diff/json_diff.dart';
import 'package:shapeshift/shapeshift_cli.dart';
import 'package:shapeshift/shapeshift_common.dart';
import 'package:unittest/unittest.dart';


void main() {
  MethodAttributesReporter mar;
  ReadableStringSink io;

  expectIoContains(RegExp re) => expect(io.read(), matches(re));

  test('Shapeshift method attributes reporter:', () {
    String v1 = '{"name": "foo", "qualifiedName": "foo.Foo.foo", "comment":"<p>Send a data event to a stream.</p>", "abstract": false}';
    String v2 = '{"name": "foo", "qualifiedName": "foo.Foo.foo", "comment":"<p>Send a data event to a stream.</p>", "abstract": true}';
    io = new ReadableStringSink();

    diffAndReport(v1, v2, io);
    expectIoContains(new RegExp(
        '''The \\[foo\\]\\(.*\\) method\'s `abstract` changed:

Was: `false`

Now: `true`'''));
  });
}

void diffAndReport(String v1, String v2, ReadableStringSink io) {
  // TODO: This should _not_ just be copy/pasted from LibraryReporter.
  JsonDiffer differ = new JsonDiffer(v1, v2);
  differ.atomics
    ..add('type')
    ..add('return')
    ..add('annotations[]');
  differ.metadataToKeep..add('qualifiedName');
  differ.ensureIdentical(['name', 'qualifiedName']);
  DiffNode diff = differ.diff()
    ..metadata['qualifiedName'] = differ.leftJson['qualifiedName']
    ..metadata['name'] = differ.leftJson['name']
    ..metadata['packageName'] = differ.leftJson['packageName'];

  MarkdownWriter mw = new MarkdownWriter(() => io, false);
  Function noop = (Map m, [String key]) { };
  new MethodAttributesReporter('method', 'foo', diff, mw, noop).report();
}