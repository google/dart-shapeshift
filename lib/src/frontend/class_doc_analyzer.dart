// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of doc_coverage_frontend;

class ClassDocAnalyzer {
  final LibraryDocAnalyzer libraryDocAnalyzer;
  final String classType;
  final Map klassBrief;

  Map<String, dynamic> klass;
  DocCoverage dc;
  String name, docUrl;
  TableSectionElement scoreSection;

  ClassDocAnalyzer(this.libraryDocAnalyzer, this.classType, this.klassBrief);

  void go(String screen) {
    name = klassBrief['name'];
    String qualifiedName = klassBrief['qualifiedName'].replaceFirst(':', '-');
    docUrl = libraryDocAnalyzer.htmlUrl != null
        ? '${libraryDocAnalyzer.htmlUrl}.$name'
        : null;
    HttpRequest
        .getString('${libraryDocAnalyzer.base}/$qualifiedName.json')
        .then((String json) {
      klass = new JsonDecoder().convert(json);
      dc = new DocCoverage(klass);
      if (screen == 'score') _reportClassScore();
      else reportClassGaps();
    }).catchError(_reportError);
  }

  void _reportError(Error err) {
    if (err is! ProgressEvent) throw err;

    HttpRequest target = (err as ProgressEvent).target;
    scoreSection = libraryDocAnalyzer.scoresTable.createTBody();
    TableRowElement classRow = scoreSection.addRow()..classes.add('error');

    libraryDocAnalyzer.addToSortedRows(scoreSection, 0, reverse: true);

    String nameHtml = '$classType $name';
    if (classType == 'class') nameHtml = '<strong>$nameHtml</strong>';
    Element errorText = new AnchorElement()
      ..attributes['href'] = target.responseUrl
      ..innerHtml =
      'Error fetching docs: Error ${target.status}: ${target.statusText}'
      ..append(new SpanElement()
        ..innerHtml = '&#x2197;'
        ..classes.add('sup'));

    scoreSection.dataset['count'] = '0';
    scoreSection.dataset['size'] = '1';
    classRow
      ..addCell().appendText(' ')
      ..addCell().appendText(nameHtml)
      ..addCell().append(errorText);

    classRow.addCell()
      ..innerHtml = '&nbsp;'
      ..classes.add('expando');

    TableRowElement classGapsRow = scoreSection.addRow()
      ..classes.add('hidden')
      ..classes.add('gaps-row');
    classGapsRow.addCell()
      ..append(classGapsSection())
      ..attributes['colspan'] = '4';
  }

  void _reportClassScore() {
    String className = klass['name'];
    int score = (100 * dc.score).toInt();
    scoreSection = libraryDocAnalyzer.scoresTable.createTBody();
    TableRowElement classRow = scoreSection.addRow();

    libraryDocAnalyzer.addToSortedRows(scoreSection, score.toInt(),
        reverse: true);
    ImageElement shieldImg = new ImageElement()
      ..attributes['src'] = dc.shieldUrl()
      ..classes.add('shield');

    String nameHtml = '$classType $className';
    if (classType == 'class') nameHtml = '<strong>$nameHtml</strong>';
    Element text;
    if (docUrl == null) {
      text = new SpanElement()..innerHtml = nameHtml;
    } else {
      text = new AnchorElement()
        ..attributes['href'] = docUrl
        ..innerHtml = '$nameHtml '
        ..append(new SpanElement()
          ..innerHtml = '&#x2197;'
          ..classes.add('sup'));
    }

    SpanElement gapsToggle = new SpanElement()
      ..append(new SpanElement()
        ..innerHtml = '&#x25ba;'
        ..classes.add('arrow'))
      ..appendText(' gaps')
      ..classes.add('button')
      ..onClick.listen(toggleClassGaps);

    scoreSection.dataset['count'] = '${score.toInt()}';
    scoreSection.dataset['size'] = '${dc.calculateSize()}';
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
    classGapsRow.addCell()
      ..append(classGapsSection(detailed: false))
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
    } else {
      gapsRow.classes.add('hidden');
      e.querySelector('.arrow').innerHtml = '&#x25b6;';
    }
  }

  Element classGapsSection({detailed: true}) {
    Map<String, dynamic> gaps = dc.calculateCoverage();
    Element classSection = new Element.section();
    int gapCount = gaps['gapCount'];
    classSection.dataset['count'] = '$gapCount';
    if (detailed) {
      classSection
          .append(new HeadingElement.h2()..text = '$classType ${gaps['name']}');
    }

    if (gaps['gapCount'] == 0) {
      classSection.appendHtml('<em>No gaps</em>');
      return classSection;
    }

    classSection
      ..append(new SpanElement()..text = '($gapCount points of coverage gaps)');

    reportOnTopLevelComment(gaps, classSection);
    reportOnMethods(gaps, classSection);
    reportOnVariables(gaps, classSection);

    return classSection;
  }
}
