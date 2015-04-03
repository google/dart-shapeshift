// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for Shapeshift's methods reporter.
library methods_reporter_tests;

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

  test('Shapeshift reports on new methods', () {
    v1 = classWithMethods({'foo': methodNamed('foo')});
    v2 = classWithMethods({'foo': methodNamed('foo'),
                           'bar': methodNamed('bar')});

    diffAndReport(jsonFrom(v1), jsonFrom(v2), io);
    expectIoContains(new RegExp(
        r'''New method \[bar\]\(.*\):

```dart
/// <p>Send a data event to a stream.</p>
dart:core.String bar\(\)
```'''));
  });
}

void diffAndReport(String v1, String v2, ReadableStringSink io) {
  DiffNode diff = diffApis(v1, v2);
  MarkdownDiffWriter writer = new MarkdownDiffWriter(() => io, false);
  Function noop = (Map m, [String key]) { };
  new MethodsReporter('methods', diff['methods']['methods'], writer, noop).report();
}