// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of doc_coverage_frontend;

abstract class MemberDocAnalyzer {
  final LibraryDocAnalyzer libraryDocAnalyzer;
  final Map member;

  String name, classQualifiedName, docUrl;
  TableSectionElement scoreSection;

  MemberDocAnalyzer(this.libraryDocAnalyzer, this.member);

  void go(String screen) {
    name = member['name'];
    // name, qualifiedName (path/path.method), comment
    docUrl = libraryDocAnalyzer.htmlUrl != null ?
        '${libraryDocAnalyzer.htmlUrl}.$name' : null;
    if (screen == 'score')
      reportScore();
    else
      reportGaps();
  }

  String get decoratedName;

  void reportScore() {
    int score = (100*DocCoverage.scoreThing(member)).toInt();
    scoreSection = libraryDocAnalyzer.scoresTable.createTBody();
    TableRowElement classRow = scoreSection.addRow();

    libraryDocAnalyzer.addToSortedRows(scoreSection, score.toInt(), reverse: true);
    ImageElement shieldImg = new ImageElement()
      ..attributes['src'] = DocCoverage.shieldUrlForScore(score)
      ..classes.add('shield');

    Element text;
    if (docUrl == null) {
      text = new SpanElement()..innerHtml = '$decoratedName';
    }
    else {
      text = new AnchorElement()
        ..attributes['href'] = docUrl
        ..text = '$decoratedName '
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
      ..append(gapsSection(detailed: false))
      ..attributes['colspan'] = '4';
  }

  void reportGaps();

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

  Element gapsSection({detailed: true}) {
    Element section = new Element.section();
    GapsAnalysis analysis = new GapsAnalysis(
        member['name'],
        member['qualifiedName'],
        member['comment'])
      ..analyzeGaps(member);
    int gapCount = analysis['gapCount'];
    section.dataset['count'] = '$gapCount';
    if (detailed) {
      section.append(new HeadingElement.h2()
        ..text = decoratedName);
    }

    if (analysis['gapCount'] == 0) {
      section.appendHtml('<em>No gaps</em>');
      return section;
    }

    section
      ..append(new SpanElement()..text = '($gapCount points of coverage gaps)');

    reportOnTopLevelComment(analysis.gaps, section);

    return section;
  }
}