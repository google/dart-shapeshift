// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for shapeshift's Doc Coverage tool.
library class_score_tests;

import 'dart:convert';
import 'package:shapeshift/doc_coverage_common.dart';
import 'package:unittest/unittest.dart';

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
    expect(score, equals(1.0));
  });

  test('scores a class with a long comment summary, and without methods', () {
    Map<String,dynamic> cls = new Map.from(classTemplate)
        ..['comment'] = 'This first line is the summary and should be short ' +
            'but its so long wow no one could ever think that this ' +
            'summarizes the behavior of a method.';
    double score = new DocCoverage().calculateScore(jsonFrom(cls));
    expect(score, equals(0.9));
  });

  test('scores a class with a good comment, and without methods', () {
    Map<String,dynamic> cls = new Map.from(classTemplate)
        ..['comment'] = 'A comment\n\nwith a nice and detailed paragraph.';
    double score = new DocCoverage().calculateScore(jsonFrom(cls));
    expect(score, equals(1.0));
  });

  test('1 undocumented method', () {
    Map<String,dynamic> cls = newClassWithComments(
        'A comment\n\nwith a nice and detailed paragraph.', ['']);
    double score = new DocCoverage().calculateScore(jsonFrom(cls));
    expect(score, equals(0.5));
  });

  test('1 method doc with long summary', () {
    Map<String,dynamic> cls = newClassWithComments(
        'A comment\n\nwith a nice and detailed paragraph.',
        ['This first line is the summary and should be short but its so ' +
         'long wow no one could ever think that this summarizes the ' +
         'behavior of a method.']);
    double score = new DocCoverage().calculateScore(jsonFrom(cls));
    expect(score, equals(0.9));
  });

  test('1 method with docs w/o period', () {
    Map<String,dynamic> cls = newClassWithComments(
        'A comment\n\nwith a nice and detailed paragraph.',
        ['Where\'s the period']);
    double score = new DocCoverage().calculateScore(jsonFrom(cls));
    expect(score, equals(0.95));
  });

  test('1 method with docs w/ period and code', () {
    Map<String,dynamic> cls = newClassWithComments(
        'A comment\n\nwith a nice and detailed paragraph.',
        ['<p>Here\'s a period.</p>\n\n<pre>// And code.\n\nvar a = 1;</pre>']);
    double score = new DocCoverage().calculateScore(jsonFrom(cls));
    expect(score, equals(1.0));
  });

  test('1 method with good docs', () {
    Map<String,dynamic> cls = newClassWithComments(
        'A comment\n\nwith a nice and detailed paragraph.',
        ['Another comment.\n\nWith a nice and detailed paragraph.']);
    double score = new DocCoverage().calculateScore(jsonFrom(cls));
    expect(score, equals(1.0));
  });

  test('1 method with good docs, 1 without', () {
    Map<String,dynamic> cls = newClassWithComments(
        'A comment\n\nwith a nice and detailed paragraph.',
        ['Another comment.\n\nWith a nice and detailed paragraph.', '']);
    double score = new DocCoverage().calculateScore(jsonFrom(cls));
    expect(score, equals(0.75));
  });

  test('2 methods with good docs', () {
    Map<String,dynamic> cls = newClassWithComments(
        'A comment\n\nwith a nice and detailed paragraph.',
        ['Another comment.\n\nWith a nice and detailed paragraph.',
         'Another another comment.\n\nWith a nice and detailed paragraph.']);
    double score = new DocCoverage().calculateScore(jsonFrom(cls));
    expect(score, equals(1.0));
  });

  test('1 method with good docs, 2 without', () {
    Map<String,dynamic> cls = newClassWithComments(
        'A comment\n\nwith a nice and detailed paragraph.',
        ['Another comment.\n\nWith a nice and detailed paragraph.', '', '']);
    double score = new DocCoverage().calculateScore(jsonFrom(cls));
    expect(score, closeTo(0.66666, 0.00001));
  });

  test('2 methods with good docs, 1 without', () {
    Map<String,dynamic> cls = newClassWithComments(
        'A comment\n\nwith a nice and detailed paragraph.',
        ['Another comment.\n\nWith a nice and detailed paragraph.',
         'Another another comment.\n\nWith a nice and detailed paragraph.',
         '']);
    double score = new DocCoverage().calculateScore(jsonFrom(cls));
    expect(score, closeTo(0.83333, 0.00001));
  });
}

Map<String,dynamic> newClassWithComments(String clsComment, List<String> comments) {
  int counter = 0;
  Map<String,dynamic> cls = new Map.from(classTemplate)
      ..['comment'] = clsComment;
  comments.forEach((String c) {
    counter++;
    cls['methods']['methods']['m$counter'] = {
        "name": "m$counter",
        "qualifiedName": "foo.Foo.m$counter",
        "comment": c
    };
  });

  return cls;
}

String jsonFrom(Map<String,Object> obj) {
  return new JsonEncoder().convert(obj);
}