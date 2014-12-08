// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for json_diff.
library doc_score_tests;

import 'dart:convert';
import 'package:shapeshift/doc_coverage_common.dart';
import 'package:unittest/unittest.dart';

void main() {
  test('scores a class without a comment, and without methods', () {
    Map<String,dynamic> cls = new Map.from(classTemplate);
    double score = new DocCoverage().calculateScore(jsonFrom(cls));
    expect(score, equals(0.5));
  });

  test('scores a class with a brief comment, and without methods', () {
    Map<String,dynamic> cls = new Map.from(classTemplate)
        ..['comment'] = 'brief';
    double score = new DocCoverage().calculateScore(jsonFrom(cls));
    expect(score, equals(0.75));
  });

  test('scores a class with a good comment, and without methods', () {
    Map<String,dynamic> cls = new Map.from(classTemplate)
        ..['comment'] = 'A comment\n\nwith a nice and detailed paragraph.';
    double score = new DocCoverage().calculateScore(jsonFrom(cls));
    expect(score, equals(1.0));
  });

  test('scores a class with 1 undocumented method', () {
    Map<String,dynamic> cls = new Map.from(classTemplate)
        ..['comment'] = 'A comment\n\nwith a nice and detailed paragraph.'
        ..['methods']['methods'] = {
          "m1": {
            "name": "m1",
            "qualifiedName": "foo.Foo.m1",
            "comment": ""
          }
        };
    double score = new DocCoverage().calculateScore(jsonFrom(cls));
    expect(score, equals(0.5));
  });
}

String jsonFrom(Map<String,Object> obj) {
  return new JsonEncoder().convert(obj);
}

Map<String,dynamic> classTemplate = {
  "name": "Foo",
  "qualifiedName": "foo.Foo",
  "comment": "",
  "methods": {
    "getters": {},
    "setters": {},
    "constructors": {},
    "operators": {},
    "methods": {}
  },
  "variables": {},
};