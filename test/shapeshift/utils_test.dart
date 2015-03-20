// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for Shapeshift's utilities.
library utils_tests;

import 'package:shapeshift/shapeshift_common.dart';
import 'package:unittest/unittest.dart';

void main() {
  test('Shapeshift utils: pluralize pluralizes', () {
    expect(pluralize('parameter'), equals('parameters'));
    expect(pluralize('class'), equals('classes'));
    expect(pluralize('annotations'), equals('annotations'));
  });

  test('Shapeshift utils: pretty prettifies', () {
    expect(pretty({'a': 'b'}), equals('{\n  "a": "b"\n}'));
  });

  test('Shapeshift utils: singularize singularizes', () {
    expect(singularize('annotations'), equals('annotation'));
    expect(singularize('return'), equals('return'));
  });

  test('Shapeshift utils: annotationFormatter formats annotations', () {
    Map ann = {'name': 'Foo'};
    expect(annotationFormatter(ann), equals('`@Foo`'));
    expect(annotationFormatter(ann, backticks: false), equals('@Foo'));
  });

  group('Shapeshift utils: variableSignature', () {
    List<Map> type = [{'outer': 'String', 'inner': ''}];
    Map variable = {
      'name': 'foo',
      'type': type,
      'annotations': [],
      'constant': false,
      'final': false,
      'static': false,
    };

    test('of plane ole\' variable', () {
      expect(variableSignature(variable), equals('String foo;'));
    });

    test('of const variable', () {
      Map v = new Map.from(variable)..['constant'] = true;
      expect(variableSignature(v), equals('const String foo;'));
    });

    test('of final variable', () {
      Map v = new Map.from(variable)..['final'] = true;
      expect(variableSignature(v), equals('final String foo;'));
    });

    test('of static variable', () {
      Map v = new Map.from(variable)..['static'] = true;
      expect(variableSignature(v), equals('static String foo;'));
    });
  });
}
