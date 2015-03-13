// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Unit tests for Shapeshift's Doc Coverage tool.
library class_gaps_tests;

import 'dart:convert';
import 'package:shapeshift/doc_coverage_common.dart';
import 'package:unittest/unittest.dart';

void main() {
  String api;
  Map<String,List> gaps;

  test('package API has correct properties', () {
    api = '{"name":"foo","qualifiedName":"foo","comment":"<p>comment</p>","packageName":""}';
    gaps = new DocCoverage.fromJson(api).calculateCoverage();
    expect(gaps['qualifiedName'], equals('foo'));
    expect(gaps['name'], equals('foo'));
    expect(gaps['comment'], equals('<p>comment</p>'));
  });
  
  test('DocCoverage calculates gaps for package w/ no comment', () {
    api = '{"name":"foo","qualifiedName":"foo","comment":"","packageName":""}';
    gaps = new DocCoverage.fromJson(api).calculateCoverage();
    expect(gaps['gapCount'], equals(DocCoverage.libraryCommentGap));
  });
  
  test('DocCoverage calculates gaps for package w/ brief comment', () {
    api = '{"name":"foo","qualifiedName":"foo","comment":"<p>comment</p>","packageName":""}';
    gaps = new DocCoverage.fromJson(api).calculateCoverage();
    expect(gaps['gapCount'], equals(DocCoverage.libraryCommentBrief));
  });
  
  test('DocCoverage calculates gaps for package w/ long monoline comment', () {
    api = '{"name":"foo","qualifiedName":"foo","comment":"${'<p>comment</p>'*20}","packageName":""}';
    gaps = new DocCoverage.fromJson(api).calculateCoverage();
    expect(gaps['gapCount'], equals(DocCoverage.libraryCommentBrief));
  });
  
  test('DocCoverage calculates gaps for package w/ multiline comment', () {
    api = '{"name":"foo","qualifiedName":"foo","comment":"${'<p>comment</p>\\n\\n'*20}","packageName":""}';
    gaps = new DocCoverage.fromJson(api).calculateCoverage();
    expect(gaps['gapCount'], equals(0));
  });
  
  test('DocCoverage calculates gaps for class w/ no comment', () {
    gaps = new DocCoverage.fromJson(jsonFrom(classTemplate)).calculateCoverage();
    expect(gaps['gapCount'], equals(DocCoverage.classCommentGap));
  });
  
  test('DocCoverage calculates gaps for class w/ brief comment', () {
    gaps = new DocCoverage.fromJson(jsonFrom(
        classTemplate..['comment'] = '<p>brief</p>'
    )).calculateCoverage();
    expect(gaps['gapCount'], equals(DocCoverage.classCommentBrief));
  });
  
  test('DocCoverage calculates gaps for class w/ long monoline comment', () {
    gaps = new DocCoverage.fromJson(jsonFrom(
        classTemplate..['comment'] = '<p>longer</p>'*20
    )).calculateCoverage();
    expect(gaps['gapCount'], equals(DocCoverage.classCommentBrief));
  });
  
  test('DocCoverage calculates gaps for class w/ brief multiline comment', () {
    gaps = new DocCoverage.fromJson(jsonFrom(
        classTemplate..['comment'] = '<p>brief</p>\\n\\n'*20
    )).calculateCoverage();
    expect(gaps['gapCount'], equals(DocCoverage.classCommentBrief));
  });
  
  test('DocCoverage calculates gaps for class w/ brief multiline comment', () {
    gaps = new DocCoverage.fromJson(jsonFrom(
        classTemplate..['comment'] = '<p>longer</p>'*20 + '\n\n<p>line</p>'
    )).calculateCoverage();
    expect(gaps['gapCount'], equals(0));
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
    "methods":{}
  },
  "variables": {},
};