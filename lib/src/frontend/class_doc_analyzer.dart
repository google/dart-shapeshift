// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of doc_coverage_frontend;

class ClassDocAnalyzer {
  final LibraryDocAnalyzer libraryDocAnalyzer;
  final String classType;
  final Map klass;

  String name, qualifiedName, docUrl, json;
  TableSectionElement scoreSection;

  ClassDocAnalyzer(this.libraryDocAnalyzer, this.classType, this.klass);

  void go(String screen) {
    name = klass['name'];
    qualifiedName = klass['qualifiedName'].replaceFirst(':', '-');
    docUrl = libraryDocAnalyzer.htmlUrl != null ?
        '${libraryDocAnalyzer.htmlUrl}.$name' : null;
    HttpRequest.getString('${libraryDocAnalyzer.base}/$qualifiedName.json').then((String _json) {
      json = _json;
      if (screen == 'score')
        reportClassScore();
      else
        reportClassGaps();
    });
  }

  void reportClassScore() {
    Map<String,dynamic> klass = new JsonDecoder().convert(json);
    String className = klass['name'];
    DocCoverage dc = new DocCoverage();
    int score = (100*dc.calculateScore(json)).toInt();
    scoreSection = libraryDocAnalyzer.scoresTable.createTBody();
    TableRowElement classRow = scoreSection.addRow();

    libraryDocAnalyzer.addToSortedRows(scoreSection, score.toInt(), reverse: true);
    ImageElement shieldImg = new ImageElement()
        ..attributes['src'] = dc.shieldUrl(json)
        ..classes.add('shield');

    String nameHtml = '$classType $className';
    if (classType == 'class')
        nameHtml = '<strong>$nameHtml</strong>';
    Element text;
    if (docUrl == null) {
      text = new SpanElement()..innerHtml = nameHtml;
    }
    else {
      text = new AnchorElement()
          ..attributes['href'] = docUrl
          ..text = '$nameHtml '
          ..append(new SpanElement()..innerHtml = '&#x2197;'..classes.add('sup'));
    }

    SpanElement gapsToggle = new SpanElement()
        ..append(new SpanElement()..innerHtml = '&#x25ba;'..classes.add('arrow'))
        ..appendText(' gaps')
        ..classes.add('button')
        ..onClick.listen(toggleClassGaps);

    scoreSection.dataset['count'] = '${score.toInt()}';
    scoreSection.dataset['size'] = '${dc.calculateSize(json)}';
    libraryDocAnalyzer.updateLibraryBadge();
    classRow
        ..addCell().append(gapsToggle)
        ..addCell().append(text)
        ..addCell().append(shieldImg);

    classRow.addCell()
            ..innerHtml = '&nbsp;'
            ..classes.add('expando');

    TableRowElement classGapsRow = scoreSection.addRow()
        ..classes.add('hidden')
        ..classes.add('gaps-row');
    TableCellElement classGaps = classGapsRow.addCell()
        ..append(classGapsSection())
        ..attributes['colspan'] = '4';
  }

  void reportClassGaps() {
    Element classSection = classGapsSection();
    int gapCount = int.parse(classSection.dataset['count']);
    libraryDocAnalyzer.bumpCount(gapCount);
    libraryDocAnalyzer.addToSortedSections(classSection, gapCount);
  }

  void toggleClassGaps(Event event) {
    Element e = event.target;
    // Hopefully. I don't see any query selector for ancestors :(
    Element tbody = e.parent.parent.parent;
    Element gapsRow = tbody.querySelector('.gaps-row');
    if (gapsRow.classes.contains('hidden')) {
      gapsRow.classes.remove('hidden');
      e.querySelector('.arrow').innerHtml = '&#x25bc;';
    }
    else {
      gapsRow.classes.add('hidden');
      e.querySelector('.arrow').innerHtml = '&#x25b6;';
    }
  }

  Element classGapsSection() {
    Map<String,dynamic> klass = new JsonDecoder().convert(json);
    Map<String,dynamic> gaps = new DocCoverage().calculateCoverage(json);
    Element classSection = new Element.section();
    if (gaps['gapCount'] == 0) {
      classSection.appendHtml('<em>No gaps</em>');
      return classSection;
    }
    int gapCount = gaps['gapCount'];

    classSection.dataset['count'] = '$gapCount';
    classSection.append(new HeadingElement.h2()
        ..text = '$classType ${gaps['name']}')
        ..append(new SpanElement()..text = '($gapCount points of coverage gaps)');

    reportOnTopLevelComment(gaps, classSection);
    reportOnMethods(gaps, classSection);
    reportOnVariables(gaps, classSection);

    return classSection;
  }
}