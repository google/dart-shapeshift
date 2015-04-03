// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_common;

class MarkdownDiffWriter extends MarkdownWriter {
  MarkdownDiffWriter(openIo, shouldClose)
      : super(openIo, shouldClose);

  void writeWasNow(Object theOld, Object theNew,
      {bool blockquote: false, bool link: false}) {
    String theOldStr = theOld.toString();
    String theNewStr = theNew.toString();
    if (blockquote) {
      if (theOldStr.isEmpty) {
        writeln('Was: _empty_');
      } else {
        writeln('Was:\n');
        writeBlockquote(highlightDeleted(theOldStr, theNewStr));
        //writeBlockquote(theOldStr);
      }
      if (theNewStr.isEmpty) {
        writeln('Now: _empty_');
      } else {
        writeln('Now:\n');
        writeBlockquote(highlightInserted(theOldStr, theNewStr));
        //writeBlockquote(theNewStr);
      }
    } else {
      if (theOldStr.isEmpty) {
        theOldStr = '_empty_';
      } else if (link) {
        theOldStr = decoratedName(theOldStr);
      } else {
        theOldStr = '`$theOldStr`';
      }
      if (theNewStr.isEmpty) {
        theNewStr = '_empty_';
      } else if (link) {
        theNewStr = mdLinkToDartlang(theNewStr);
      } else {
        theNewStr = '`$theNewStr`';
      }
      writeln('Was: $theOldStr\n');
      writeln('Now: $theNewStr');
    }
  }
}

String highlightInserted(String theOld, String theNew) {
  List<Diff> diffResult = diffAndCleanup(theOld, theNew);
  String result = '';
  String greenBg = 'background-color: rgba(153, 255, 153, 0.7)';
  diffResult.forEach((Diff d) {
    if (d.operation == DIFF_EQUAL) {
      result += d.text;
    } else if (d.operation == DIFF_INSERT) {
      // TODO: more block element tags
      if (d.text.contains('<blockquote>') ||
          d.text.contains('<p>') ||
          d.text.contains('<pre>')) {
        result +=
            '<div '
            'style="$greenBg; display: inline-block; padding: 2px; margin: 0 1px; width: 100%;">'
            '${d.text}'
            '</div>';
      } else {
        result +=
            '<span style="$greenBg; padding: 1px;">${d.text}</span>';
      }
    }
  });
  return result;
}

String highlightDeleted(String theOld, String theNew) {
  List<Diff> diffResult = diffAndCleanup(theOld, theNew);
  String result = '';
  String redBg = 'background-color: rgba(255, 153, 153, 0.7)';
  diffResult.forEach((Diff d) {
    if (d.operation == DIFF_EQUAL) {
      result += d.text;
    } else if (d.operation == DIFF_DELETE) {
      // TODO: more block element tags
      if (d.text.contains('<blockquote>') ||
          d.text.contains('<p>') ||
          d.text.contains('<pre>')) {
        result +=
            '<div style="$redBg; display: inline-block; padding: 1px; margin: 0 1px;">${d.text}</div>';
      } else {
        result +=
            '<span style="$redBg; padding: 1px; margin: 0 1px;">${d.text}</span>';
      }
    }
  });
  return result;
}

List<Diff> diffAndCleanup(String theOld, String theNew) {
  List<Diff> result = diff(theOld, theNew);
  cleanupSemantic(result);
  RegExp unclosedTag = new RegExp(r'<[^>]*$');
  RegExp unopenedTag = new RegExp(r'^[^<]*>');
  for (int i = 0; i < result.length; i++) {
    Diff d = result[i];
    if (d.text.contains(unclosedTag)) {
      String dirtyDom = unclosedTag.stringMatch(d.text);
      removeFromDiff(d, unclosedTag);
      if (d.operation == DIFF_EQUAL) {
        prependToDiff(result[i + 1], dirtyDom);
        if (result[i + 2].operation != DIFF_EQUAL) {
          prependToDiff(result[i + 2], dirtyDom);
        }
      } else {
        if (result[i + 1].operation == DIFF_EQUAL) {
          prependToDiff(result[i + 1], dirtyDom);
        } else {
          // If dirtyDom in result[i+1] != dirtyDom, then we should pull the
          // unopened back instead of pushing the unclosed forward.
          if (unclosedTag.stringMatch(result[i + 1].text) == dirtyDom) {
            removeFromDiff(result[i + 1], unclosedTag);
            prependToDiff(result[i + 2], dirtyDom);
          } else {
            if (result[i + 2].text.contains(unopenedTag)) {
              String plus2DirtyDom =
                  unopenedTag.stringMatch(result[i + 2].text);
              removeFromDiff(result[i + 2], unopenedTag);
              // Just kidding put it back!
              appendToDiff(d, dirtyDom);
              appendToDiff(d, plus2DirtyDom);
              appendToDiff(result[i + 1], plus2DirtyDom);
            }
          }
        }
      }
    }
  }

  return result;
}

void appendToDiff(Diff d, String suffix) {
  d.text = '${d.text}$suffix';
}

void prependToDiff(Diff d, String prefix) {
  d.text = '$prefix${d.text}';
}

void removeFromDiff(Diff d, Pattern p) {
  d.text = d.text.replaceAll(p, '');
}
