// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for shapeshift's Doc Coverage tool.
library library_score_tests;

import 'dart:convert';
import 'package:shapeshift/doc_coverage_common.dart';
import 'package:unittest/unittest.dart';

Map<String,dynamic> libraryTemplate = {
  "name": "foo",
  "qualifiedName": "foo",
  "comment": "",
  "functions": {
    "getters": {},
    "setters": {},
    "constructors": {},
    "operators": {},
    "methods": {}
  },
  "classes": {
    "class": [],
    "typedef": [],
    "error": [],
  },
  "variables": {},
};

List<Map> classScores(Map lib) {
  List<Map> scores = new List();
  scores.addAll(lib['classes']['class'].map((Map cls) {
      DocCoverage dc = new DocCoverage();
      double score = dc.calculateScore(jsonFrom(cls));
      return {
        'size': dc.calculateSize(),
        'score': score
      };
  }));
  // TODO: 'error'
  // TODO: 'typedef'
  return scores;
}

List<Map> functionScores(Map lib) {
  List<Map> scores = new List();
  DocCoverage.methodCategories.forEach((String category) {
    scores.addAll(lib['functions'][category].values.map((Map method) {
        return {
          'size': 1,
          'score': DocCoverage.scoreThing(method)
        };
    }));
  });
  return scores;
}

void main() {
  // TODO: THIS
  test('scores a library without a comment, and without classes or functions', () {
    Map<String,dynamic> lib = new Map.from(libraryTemplate);
    
    List<Map> scores = new List();
    scores.addAll(classScores(lib));
    scores.addAll(functionScores(lib));
    double score = DocCoverage.weightedScore(scores);
    expect(score, equals(1.0));
  });

  // TODO: THIS
  test('scores a library with a brief comment, and without classes or functions', () {
    Map<String,dynamic> lib = new Map.from(libraryTemplate)
      ..['comment'] = 'brief';
    
    List<Map> scores = new List();
    scores.addAll(classScores(lib));
    scores.addAll(functionScores(lib));
    double score = DocCoverage.weightedScore(scores);
    expect(score, equals(1.0));
  });

  test('scores a library with a good comment, and without classes or functions', () {
    Map<String,dynamic> lib = new Map.from(libraryTemplate)
      ..['comment'] = 'A comment\n\nwith a nice and detailed paragraph.';
    
    List<Map> scores = new List();
    scores.addAll(classScores(lib));
    scores.addAll(functionScores(lib));
    double score = DocCoverage.weightedScore(scores);
    expect(score, equals(1.0));
  });

  test('1 undocumented function', () {
    Map<String,dynamic> lib = newLibraryWithFunctions(
        'A comment\n\nwith a nice and detailed paragraph.', ['']);
    
    List<Map> scores = new List();
    scores.addAll(classScores(lib));
    scores.addAll(functionScores(lib));
    double score = DocCoverage.weightedScore(scores);
    expect(score, equals(0.0));
  });

  test('1 undocumented function', () {
    Map<String,dynamic> lib = newLibraryWithFunctions(
        'A comment\n\nwith a nice and detailed paragraph.', ['']);
    
    List<Map> scores = new List();
    scores.addAll(classScores(lib));
    scores.addAll(functionScores(lib));
    double score = DocCoverage.weightedScore(scores);
    expect(score, equals(0.0));
  });

  test('1 method doc with long summary', () {
    Map<String,dynamic> lib = newLibraryWithFunctions(
        'A comment\n\nwith a nice and detailed paragraph.',
        ['This first line is the summary and should be short but its so ' +
         'long wow no one could ever think that this summarizes the ' +
         'behavior of a method.']);
    
    List<Map> scores = new List();
    scores.addAll(classScores(lib));
    scores.addAll(functionScores(lib));
    double score = DocCoverage.weightedScore(scores);
    expect(score, equals(0.8));
  });

  test('1 method with docs w/o period', () {
    Map<String,dynamic> lib = newLibraryWithFunctions(
        'A comment\n\nwith a nice and detailed paragraph.',
        ['Where\'s the period']);
    
    List<Map> scores = new List();
    scores.addAll(classScores(lib));
    scores.addAll(functionScores(lib));
    double score = DocCoverage.weightedScore(scores);
    expect(score, equals(0.9));
  });
}

Map<String,dynamic> newLibraryWithFunctions(String libComment, List<String> comments) {
  int counter = 0;
  Map<String,dynamic> lib = new Map.from(libraryTemplate)
      ..['comment'] = libComment;
  comments.forEach((String c) {
    counter++;
    lib['functions']['methods']['m$counter'] = {
        "name": "m$counter",
        "qualifiedName": "foo.Foo.m$counter",
        "comment": c
    };
  });

  return lib;
}

String jsonFrom(Map<String,Object> obj) {
  return new JsonEncoder().convert(obj);
}