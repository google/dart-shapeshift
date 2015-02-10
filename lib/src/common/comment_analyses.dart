// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of doc_coverage_common;

class CommentAnalyses {
  static const int maxOneLinerLength = 140;

  final String commentUnparsed;
  final Document comment;

  CommentAnalyses(_commentUnparsed)
      : commentUnparsed = _commentUnparsed,
        comment = parse(_commentUnparsed);

  bool get commentMissingPeriod {
    Element lastPara = comment.querySelector('body >p');
    String endingText = (lastPara == null)
      ? comment.querySelector('body').text
      : lastPara.text;
    return endingText[endingText.length-1] != '.';
  }

  bool get commentIsEmpty {
    return commentUnparsed.isEmpty;
  }

  bool get commentIsOneLine {
    return comment.children.length < 2;
  }

  bool get summaryTooLong {
    return commentUnparsed.split('\n')[0].length > maxOneLinerLength;
  }
}