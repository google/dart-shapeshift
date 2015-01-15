// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of doc_coverage_frontend;

class ClassDocAnalyzer {
  final LibraryDocAnalyzer libraryDocAnalyzer;
  final String classType;
  final Map klass;

  ClassDocAnalyzer(this.libraryDocAnalyzer, this.classType, this.klass);

  void go(String screen) {
    String className = klass['qualifiedName'].replaceFirst(':', '-');
    HttpRequest.getString('${libraryDocAnalyzer.base}/$className.json').then((String json) {
      if (screen == 'score')
        reportClassScore(json, classType);
      else
        reportClassGaps(json, classType);
    });
  }

  void reportClassScore(String json, String classType) {
    Map<String,dynamic> klass = new JsonDecoder().convert(json);
    String className = klass['name'];
    DocCoverage dc = new DocCoverage();
    int score = (100*dc.calculateScore(json)).toInt();
    TableRowElement classRow = new TableRowElement();
    new TableCellElement();
    new TableRowElement();

    libraryDocAnalyzer.addToSortedRows(classRow, score.toInt(), reverse: true);
    ImageElement shieldImg = new ImageElement()
        ..attributes['src'] = dc.shieldUrl(json)
        ..classes.add('shield');
    SpanElement text = new SpanElement()..text = '$classType $className';
    classRow.dataset['count'] = '${score.toInt()}';
    classRow
        ..addCell().append(text)
        ..addCell().append(shieldImg);
  }

  void reportClassGaps(String json, String classType) {
    Map<String,dynamic> klass = new JsonDecoder().convert(json);
    Map<String,dynamic> gaps = new DocCoverage().calculateCoverage(json);
    if (gaps['gapCount'] == 0) { return; }
    int gapCount = gaps['gapCount'];
    Element classSection = new Element.section();

    libraryDocAnalyzer.bumpCount(gapCount);
    libraryDocAnalyzer.addToSortedSections(classSection, gapCount);
    classSection.dataset['count'] = '$gapCount';
    classSection.append(new HeadingElement.h2()
        ..text = '$classType ${gaps['name']}')
        ..append(new SpanElement()..text = '($gapCount points of coverage gaps)');

    reportOnTopLevelComment(gaps, classSection);
    reportOnMethods(gaps, classSection);
    reportOnVariables(gaps, classSection);
  }
}