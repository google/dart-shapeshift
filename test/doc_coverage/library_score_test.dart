// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for shapeshift's Doc Coverage tool.
library library_score_tests;

import 'dart:convert';
import 'package:shapeshift/doc_coverage_common.dart';
import 'package:unittest/unittest.dart';

Map<String,dynamic> get libraryTemplate => {
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

List<Map> variableScores(Map lib) {
  List<Map> scores = new List();
    scores.addAll(lib['variables'].values.map((Map variable) {
        return {
          'size': 1,
          'score': DocCoverage.scoreThing(variable)
        };
    }));
  return scores;
}

List<Map> allScores(Map lib) {
  return new List()
    ..addAll(classScores(lib))
    ..addAll(functionScores(lib))
    ..addAll(variableScores(lib));
}

void main() {
  // TODO: This.
  test('scores a library without a comment, and without classes or members', () {
    Map<String,dynamic> lib = new Map.from(libraryTemplate);
    
    List<Map> scores = new List();
    scores.addAll(allScores(lib));
    double score = DocCoverage.weightedScore(scores);
    expect(score, equals(1.0));
  });

  // TODO: This.
  test('scores a library with a brief comment, and without classes or members', () {
    Map<String,dynamic> lib = new Map.from(libraryTemplate)
      ..['comment'] = 'brief';

    double score = DocCoverage.weightedScore(allScores(lib));
    expect(score, equals(1.0));
  });

  // TODO: This.
  test('scores a library with a good comment, and without classes or members', () {
    Map<String,dynamic> lib = new Map.from(libraryTemplate)
      ..['comment'] = 'A comment\n\nwith a nice and detailed paragraph.';

    double score = DocCoverage.weightedScore(allScores(lib));
    expect(score, equals(1.0));
  });

  test('1 undocumented function', () {
    Map<String,dynamic> lib = newLibraryWith(
        'A comment\n\nwith a nice and detailed paragraph.', funcComments: ['']);

    double score = DocCoverage.weightedScore(allScores(lib));
    expect(score, equals(0.0));
  });

  test('1 function doc with long summary', () {
    Map<String,dynamic> lib = newLibraryWith(
        'A comment\n\nwith a nice and detailed paragraph.',
        funcComments: ['This first line is the summary and should be short but its so ' +
         'long wow no one could ever think that this summarizes the ' +
         'behavior of a method.']);

    double score = DocCoverage.weightedScore(allScores(lib));
    expect(score, equals(0.8));
  });

  test('1 function with docs w/o period', () {
    Map<String,dynamic> lib = newLibraryWith(
        'A comment\n\nwith a nice and detailed paragraph.',
        funcComments: ['Where\'s the period']);

    double score = DocCoverage.weightedScore(allScores(lib));
    expect(score, equals(0.9));
  });

  test('1 undocumented variable', () {
    Map<String,dynamic> lib = newLibraryWith(
        'A comment\n\nwith a nice and detailed paragraph.', varComments: ['']);

    double score = DocCoverage.weightedScore(allScores(lib));
    expect(score, equals(0.0));
  });
}

Map<String,dynamic> newLibraryWith(String libComment,
    { List<String> funcComments: const [], List<String> varComments: const [] }) {
  Map<String,dynamic> lib = libraryTemplate
    ..['comment'] = libComment;
  int counter = 0;

  funcComments.forEach((String c) {
    counter++;
    lib['functions']['methods']['m$counter'] = {
        'name': 'm$counter',
        'qualifiedName': 'foo.Foo.m$counter',
        'comment': c
    };
  });

  varComments.forEach((String c) {
    counter++;
    lib['variables']['v$counter'] = {
        'name': 'v$counter',
        'qualifiedName': 'foo.Foo.v$counter',
        'comment': c
    };
  });

  return lib;
}

String jsonFrom(Map<String,Object> obj) {
  return new JsonEncoder().convert(obj);
}