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

  static const double topLevelWeight = 0.5;
  static const double memberLevelWeight = 0.5;
  static const int methodWeight = 2;
  static const int variableWeight = 1;

  static const List<String> methodCategories =
      const ['getters', 'setters', 'constructors', 'methods', 'operators'];

  Map<String,Object> api;

  // Poor man's class for now.
  final Map<String,Object> gaps = new Map();

  static String shieldUrlForScore(int score) {
    String color;
    if (score < 60) color = 'orange';
    else if (score < 85) color = 'yellow';
    else color = 'brightgreen';
    return 'http://img.shields.io/badge/doc%20coverage-$score%25-$color.svg';
  }

  static double scoreThing(Map thing) {
    if (!thing.containsKey('comment')) {
      print('ACK!');
      return 0.0;
    }

    double score = 1.0;
    CommentAnalyses analyses = new CommentAnalyses(resolveCommentText(thing['comment']));
    if (analyses.commentIsEmpty)
      return 0.0;

    if (analyses.summaryTooLong)
      score -= 0.2;

    if (analyses.commentMissingPeriod)
      score -= 0.1;

    return score;
  }

  static String resolveCommentText(String rawComment) =>
    rawComment.replaceAllMapped(
        new RegExp(r'<a>([^<]+)</a>'),
        (Match match) => '<a>${new DocsLocation(match[1]).lastName}</a>'
    );

  /// members is a List of Maps with keys 'size' and 'score' with numeric values.
  static double weightedScore(List<Map> members) {
    int weight = members.fold(0, (memo, Map member) => memo + member['size']);
    double mass = members.fold(0.0, (memo, Map member) => memo + member['size'] * member['score']);
    // If no members, then we say 100%.
    if (weight == 0) return 1.00;
    return mass / weight;
  }

  Map<String,dynamic> calculateCoverage(String apiString) {
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
        Map<String,List> catGaps = categoryGaps(c);
        gaps[c] = catGaps;
        gaps['gapCount'] = (gaps['gapCount'] as int) +
            catGaps['missing'].length * memberCommentGap +
            catGaps['no-one-liner'].length * memberCommentIssue;
      });

      Map<String,List> g = { 'missing': new List(), 'no-one-liner': new List() };
      Map variables = api['variables'];
      variables.forEach((String name, Map thing) => annotateGaps(thing, g));
      gaps['variables'] = g;
      gaps['gapCount'] = (gaps['gapCount'] as int) +
          g['missing'].length * memberCommentGap +
          g['no-one-liner'].length * memberCommentIssue;
    }

    return gaps;
  }

  Map categoryGaps(String category) {
    Map<String,List> g = { 'missing': new List(), 'no-one-liner': new List() };
    Map methods = (api['methods'] as Map)[category];
    methods.forEach((String name, Map thing) => annotateGaps(thing, g));
    return g;
  }

  void annotateGaps(Map thing, Map g) {
    if (!thing.containsKey('comment')) {
      print('ACK!');
      return;
    }

    String commentUnparsed = resolveCommentText(thing['comment']);
    CommentAnalyses analyses = new CommentAnalyses(commentUnparsed);
    thing['comment'] = commentUnparsed;

    if (analyses.commentIsEmpty)
      g['missing'].add(thing);

    if (analyses.summaryTooLong)
      g['no-one-liner'].add(thing);
  }

  double calculateScore(String apiString) {
    Object _api = new JsonDecoder().convert(apiString);
    if (_api is Map) {
      api = _api;
    } else {
      throw new FormatException('JSON must be a single object');
    }

    double topLevelScore = 1.0;
    double memberLevelScore = 1.0;

    if (api['packageName'] != null) {
      // This is a package.
    }
    else {
      // This is a class.
      if (!api.containsKey('comment'))
        topLevelScore = 0.0;
      else {
        CommentAnalyses analyses = new CommentAnalyses(api['comment']);
        if (analyses.commentIsEmpty)
          topLevelScore = 0.0;

        // This analysis is too strict for now... I should re-add when I can make
        // the analysis configurable.
        /*if (analyses.commentIsOneLine)
          topLevelScore = 0.5;*/

        if (analyses.summaryTooLong)
          topLevelScore -= 0.2;
      }

      double methodScoreSum = 0.0;
      int methodCount = 0;
      methodCategories.forEach((String c) {
        Map methods = (api['methods'] as Map)[c];
        if (methods == null) return;
        Iterable<double> scores = methods.values.map(scoreThing);

        if (scores.isNotEmpty)
          methodScoreSum += scores.reduce((value, el) => value + el);
        methodCount += methods.length;
      });

      Map variables = api['variables'] as Map;
      double variableScoreSum = 0.0;
      Iterable<double> scores = variables.values.map(scoreThing);
      if (scores.isNotEmpty)
        variableScoreSum = scores.reduce((value, el) => value + el);
      int variableCount = variables.length;

      methodScoreSum *= methodWeight;
      methodCount *= methodWeight;
      variableScoreSum *= variableWeight;
      variableCount *= variableWeight;

      if (methodCount + variableCount > 0)
        memberLevelScore = (methodScoreSum + variableScoreSum) / (methodCount + variableCount);
    }
    return topLevelScore*topLevelWeight + memberLevelScore*memberLevelWeight;
  }

  int calculateSize0(String apiString) {
    Object _api = new JsonDecoder().convert(apiString);
    if (_api is Map) {
      api = _api;
    } else {
      throw new FormatException('JSON must be a single object');
    }
    return calculateSize();
  }

  int calculateSize() {
    Function numMethodThings = (memo, el) =>
        memo + ((api['methods'] as Map)[el] == null ? 0 : (api['methods'] as Map)[el].length);

    return (api['variables'] as Map).length +
        methodCategories.fold(0, numMethodThings);
  }

  String shieldUrl(String apiString) {
    return shieldUrlForScore((100*calculateScore(apiString)).toInt());
  }
}