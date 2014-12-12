// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of doc_coverage_common;

class DocCoverage {
  static const int memberCommentIssue = 1;
  static const int memberCommentGap = 2;
  static const int classCommentBrief = 7;
  static const int classCommentGap = 8;
  static const int libraryCommentBrief = 21;
  static const int libraryCommentGap = 24;
  static const int maxOneLinerLength = 140;

  Map<String,Object> api;

  // Poor man's class for now.
  final Map<String,Object> gaps = new Map();
  final List<String> methodCategories = ['getters', 'setters', 'constructors', 'methods'];

  Map<String,List> calculateCoverage(String apiString) {
    Object _api = new JsonDecoder().convert(apiString);
    if (_api is Map) {
      api = _api;
    } else {
      throw new FormatException('JSON must be a single object');
    }

    gaps['gapCount'] = 0;
    gaps['qualifiedName'] = api['qualifiedName'];
    gaps['name'] = api['name'];
    gaps['comment'] = api['comment'];

    if (api['packageName'] != null) {
      // This is a package.
      if (!api.containsKey('comment') || (api['comment'] as String).isEmpty ) {
        gaps['gapCount'] = (gaps['gapCount'] as int) + libraryCommentGap;
      }
      else if ((api['comment'] as String).split('\n').length < 2 ) {
        gaps['gapCount'] = (gaps['gapCount'] as int) + libraryCommentBrief;
      }

      gaps['packageName'] = api['qualifiedName'];
    }
    else {
      // This is a class.
      if (!api.containsKey('comment') || (api['comment'] as String).isEmpty ) {
        gaps['gapCount'] = (gaps['gapCount'] as int) + classCommentGap;
      }
      else if ((api['comment'] as String).split('\n').length < 2 ) {
        gaps['gapCount'] = (gaps['gapCount'] as int) + classCommentBrief;
      }

      methodCategories.forEach((String c) {
        Map<String,List> catGaps = searchCategory(c);
        gaps[c] = catGaps;
        gaps['gapCount'] = (gaps['gapCount'] as int) +
            catGaps['missing'].length * memberCommentGap +
            catGaps['no-one-liner'].length * memberCommentIssue;
      });

      Map<String,List> g = { 'missing': new List(), 'no-one-liner': new List() };
      Map variables = api['variables'];
      variables.forEach((String name, Map thing) => judgeThing(thing, g));
      gaps['variables'] = g;
      gaps['gapCount'] = (gaps['gapCount'] as int) +
          g['missing'].length * memberCommentGap +
          g['no-one-liner'].length * memberCommentIssue;
    }

    return gaps;
  }

  double calculateScore(String apiString) {
    Object _api = new JsonDecoder().convert(apiString);
    if (_api is Map) {
      api = _api;
    } else {
      throw new FormatException('JSON must be a single object');
    }

    double topLevelWeight = 0.5;
    double memberLevelWeight = 0.5;
    double topLevelScore = 1.0;
    double memberLevelScore = 1.0;

    if (api['packageName'] != null) {
      // This is a package.
    }
    else {
      // This is a class.
      if (!api.containsKey('comment') || (api['comment'] as String).isEmpty )
        topLevelScore = 0.0;
      else if ((api['comment'] as String).split('\n').length < 2 )
        topLevelScore = 0.5;

      double scoreSum = 0.0;
      int methodCount = 0;
      methodCategories.forEach((String c) {
        Map methods = (api['methods'] as Map)[c];
        if (methods == null) return;
        Iterable<double> scores = methods.values.map((Map thing) {
          if (!thing.containsKey('comment')) {
            print('ACK!');
            return 0.0;
          }

          String comment = resolveCommentText(thing['comment']);
          int score = 1.0;
          if (comment.isEmpty)
            return 0.0;

          if (comment.split('\n')[0].length > maxOneLinerLength)
            score -= 0.2;

          if (comment[comment.length-1] != '.')
            score -= 0.1;

          return score;
        });

        if (scores.length > 0) {
          scoreSum += scores.reduce((value, el) => value + el);
        }
        methodCount += methods.length;
      });

      if (methodCount > 0)
        memberLevelScore = scoreSum/methodCount;
    }
    return topLevelScore*topLevelWeight + memberLevelScore*memberLevelWeight;
  }

  Map searchCategory(String category) {
    Map<String,List> g = { 'missing': new List(), 'no-one-liner': new List() };
    Map methods = (api['methods'] as Map)[category];
    methods.forEach((String name, Map thing) => judgeThing(thing, g));
    return g;
  }

  void judgeThing(Map thing, Map g) {
    if (!thing.containsKey('comment')) {
      print('ACK!');
    }
    else {
      String comment = resolveCommentText(thing['comment']);
      thing['comment'] = comment;
      if (comment.isEmpty) {
        g['missing'].add(thing);
      } else if (comment.split('\n')[0].length > maxOneLinerLength) {
        g['no-one-liner'].add(thing);
      }
    }
  }

  String resolveCommentText(String rawComment) =>
    rawComment.replaceAllMapped(
        new RegExp(r'<a>([^<]+)</a>'),
        (Match match) => '<a>${new DocsLocation(match[1]).lastName}</a>'
    );
}
