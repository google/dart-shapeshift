// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of doc_coverage_frontend;

class FunctionDocAnalyzer {
  final LibraryDocAnalyzer libraryDocAnalyzer;
  final String methodType;
  final Map method;

  String name, classQualifiedName, docUrl;
  TableSectionElement scoreSection;

  FunctionDocAnalyzer(this.libraryDocAnalyzer, _methodType, this.method) :
    // For some reason, the method types are delivered plural.
    methodType = _methodType.replaceFirst(new RegExp('s\$'), '');

  void go(String screen) {
    name = method['name'];
    // name, qualifiedName (path/path.method), comment
    docUrl = libraryDocAnalyzer.htmlUrl != null ?
        '${libraryDocAnalyzer.htmlUrl}.$name' : null;
    if (screen == 'score')
      reportScore();
    else
      reportGaps();
  }

  void reportScore() {
    DocCoverage dc = new DocCoverage();
    int score = (100*DocCoverage.scoreThing(method)).toInt();
    scoreSection = libraryDocAnalyzer.scoresTable.createTBody();
    TableRowElement classRow = scoreSection.addRow();

    libraryDocAnalyzer.addToSortedRows(scoreSection, score.toInt(), reverse: true);
    ImageElement shieldImg = new ImageElement()
      ..attributes['src'] = DocCoverage.shieldUrlForScore(score)
      ..classes.add('shield');

    Element text;
    if (docUrl == null) {
      text = new SpanElement()..innerHtml = '$methodType $name';
    }
    else {
      text = new AnchorElement()
        ..attributes['href'] = docUrl
        ..text = '$methodType $name '
        ..append(new SpanElement()..innerHtml = '&#x2197;'..classes.add('sup'));
    }

    SpanElement gapsToggle = new SpanElement()
      ..append(new SpanElement()..innerHtml = '&#x25ba;'..classes.add('arrow'))
      ..appendText(' gaps')
      ..classes.add('button')
      ..onClick.listen(toggleGaps);

    scoreSection.dataset['count'] = '${score.toInt()}';
    scoreSection.dataset['size'] = '1';
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
      ..append(gapsSection())
      ..attributes['colspan'] = '4';
  }

  void reportGaps() {
    // TODO;
  }

  void toggleGaps(Event event) {
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

  Element gapsSection() {
    Element section = new Element.section();
    section.appendHtml('<em>Library function gap analysis is unimplemented.</em>');
    return section;
  }
}