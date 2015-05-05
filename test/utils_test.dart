// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for Shapeshift's utils.
library utils_tests;

import 'package:shapeshift/shapeshift_common.dart';
import 'package:test/test.dart';

void main() {
  test('Shapeshift scrubHyphens doesn\'t change OK strings', () {
    String api = 'not necessarily json';
    expect(scrubHyphens(api), equals(api));
  });

  test('Shapeshift scrubHyphens can scrub old-style names', () {
    String scrubbedApi = scrubHyphens('"name":"dart-foo.Foo');
    String expected = '"name":"dart:foo.Foo';
    expect(scrubbedApi, equals(expected));
  });

  test('Shapeshift scrubHyphens can scrub old-style qualifiedNames', () {
    String scrubbedApi = scrubHyphens('"qualifiedName":"dart-foo.Foo');
    String expected = '"qualifiedName":"dart:foo.Foo';
    expect(scrubbedApi, equals(expected));
  });

  test('Shapeshift scrubHyphens can scrub old-style outer fields', () {
    String scrubbedApi = scrubHyphens('"outer":"dart-foo.Foo');
    String expected = '"outer":"dart:foo.Foo';
    expect(scrubbedApi, equals(expected));
  });

  test('Shapeshift scrubHyphens can scrub old-style returns', () {
    String scrubbedApi = scrubHyphens('"return":"dart-foo.Foo');
    String expected = '"return":"dart:foo.Foo';
    expect(scrubbedApi, equals(expected));
  });

  test('Shapeshift scrubHyphens can scrub old-style superclasses', () {
    String scrubbedApi = scrubHyphens('"superclass":"dart-foo.Foo');
    String expected = '"superclass":"dart:foo.Foo';
    expect(scrubbedApi, equals(expected));
  });

  test('Shapeshift scrubHyphens can scrub old-style implements list', () {
    String scrubbedApi =
        scrubHyphens('"implements":["dart-foo.Foo", "dart-bar.Bar"]');
    String expected = '"implements":["dart:foo.Foo", "dart:bar.Bar"]';
    expect(scrubbedApi, equals(expected));
  });
}
