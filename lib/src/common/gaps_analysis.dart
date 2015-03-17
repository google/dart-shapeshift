// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of doc_coverage_common;

class GapsAnalysis {
  static const Map<String, int> gapWeights = const {
    'missing': DocCoverage.memberCommentGap,
    'no-one-liner': DocCoverage.memberCommentIssue,
  };

  final Map gaps = new Map();

  GapsAnalysis(name, qualifiedName, comment) {
    // Metadata.
    gaps['gapCount'] = 0;
    gaps['name'] = name;
    gaps['qualifiedName'] = qualifiedName;
    gaps['comment'] = comment;

    // Gap lists.
    gapWeights.keys.forEach((String listName) {
      gaps[listName] = new List();
    });
  }

  operator [](key) => gaps[key];

  //operator []=(key, value) => gaps[key] = value;

  void analyzeGaps(Map thing) {
    if (!thing.containsKey('comment')) {
      print('ACK!');
      return;
    }

    String commentUnparsed = resolveCommentText(thing['comment']);
    CommentAnalyses analyses = new CommentAnalyses(commentUnparsed);
    thing['comment'] = commentUnparsed;

    if (analyses.commentIsEmpty)
      gaps['missing'].add(thing);

    if (analyses.summaryTooLong)
      gaps['no-one-liner'].add(thing);

    gaps['gapCount'] = gapCount;
  }

  int get gapCount {
    int g = 0;
    gapWeights.forEach((String listName, weight) {
      g += gaps[listName].length * weight;
    });
    return g;
  }
}