// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of doc_coverage_frontend;

class LibraryDocAnalyzer {

  final String name, nameWithColon, base, package;
  final Element section = new Element.section();
  final Element sectionHeading = new HeadingElement.h1();
  final ImageElement sectionShield = new ImageElement();
  final TableElement scoresTable = new TableElement();
  final ParagraphElement gapSummary = new ParagraphElement();
  List<Element> sortedSections = new List();
  String htmlUrl;

  LibraryDocAnalyzer(name, this.base, {this.package: null})
      : name = name,
        nameWithColon = name.replaceFirst('-', ':');

  void prepareElements() {
    sortedSections.clear();


    sectionShield
        ..attributes['src'] = DocCoverage.shieldUrlForScore(0)
        ..classes.add('shield');
    section
        ..append(sectionHeading..text = 'library $name'
            ..append(sectionShield));
    gapsDiv.append(section);
    gapSummary.dataset['value'] = '0';
    section.append(gapSummary);
  }

  void analyzeScore() {
    prepareElements();
    String gapsUrl = (package == null) ?
        '#/library/${name.replaceFirst('-', ':')}/gaps' :
        '#/package/${package}/gaps';

    AnchorElement linkToGaps = new AnchorElement()
        ..attributes['href'] = gapsUrl
        ..text = 'See';
    ParagraphElement p = new ParagraphElement()
        ..append(linkToGaps)
        ..appendText(' the gaps in doc coverage.');
    section.append(p);
    section.append(scoresTable);
    scoresTable.classes..add('hidden')..add('scores-table');
    getJsonAndReport('score');
  }
  
  void updateLibraryBadge() {
    int size = sortedSections.fold(0, (memo, Element el) =>
        memo + int.parse(el.dataset['size']));
    int mass =
        sortedSections.fold(0, (memo, Element el) =>
            memo + int.parse(el.dataset['size']) * int.parse(el.dataset['count']));
    int score = mass ~/ size;
    sectionShield.attributes['src'] = DocCoverage.shieldUrlForScore(score);
  }

  void analyzeGaps() {
    prepareElements();
    section.classes.add('hidden');
    getJsonAndReport('gaps');
  }

  void getJsonAndReport(String screen) {
    HttpRequest.getString('$base/${name}.json').then((String json) {
      Map<String,dynamic> package = new JsonDecoder().convert(json);
      //classes[class[], error[], typedef[]], comment, functions, variables
      ['class', 'error'].forEach((classType) =>
        (package['classes'][classType] as List).forEach((klass) {
          new ClassDocAnalyzer(this, classType, klass).go(screen);
        })
      );
    });
  }

  void addToSortedRows(Element classRow, int gapCount, {bool reverse: false}) {
    addToSortedList(classRow, scoresTable, sortedSections, gapCount, reverse: reverse);
  }

  void addToSortedSections(Element classSection, int gapCount, {bool reverse: false}) {
    addToSortedList(classSection, section, sortedSections, gapCount, reverse: reverse);
  }

  void addToSortedList(Element element,
                       Element listElement,
                       List<Element> list,
                       int value,
                       {bool reverse: false}) {
    // This is craziness. There has to be a better way.
    listElement.classes.remove('hidden');
    if (list.isEmpty) {
      list.add(element);
      listElement.append(element);
      return;
    }

    int i = 0;

    bool keepGoing() {
      int count = int.parse(list[i].dataset['count']);
      return reverse ? value > count : value < count;
    }

    while (i < list.length && keepGoing()) { i++; }

    if (i == list.length) {
      listElement.append(element);
    }
    else {
      listElement.insertBefore(element, list[i]);
    }
    list.insert(i, element);
  }

  void bumpCount(int gapCount) {
    int sum = (int.parse(gapSummary.dataset['value'])) + gapCount;
    gapSummary.dataset['value'] = sum.toString();
    gapSummary.innerHtml = '<em>Coverage gap total: $sum points</em>';
  }

}

void reportOnTopLevelComment(Map<String,dynamic> gaps, [Element section]) {
  if (section == null) { section = gapsDiv; }
  if (!gaps.containsKey('comment') || (gaps['comment'] as String).isEmpty) {
    section.append(new ParagraphElement()
        ..append(dartlangAnchor(gaps['qualifiedName']))
        ..appendText(' has no comment!')
    );
  }
  else if ((gaps['comment'] as String).split('\n').length < 2 ) {
    String x = linkToDartlang(gaps['qualifiedName']);
    section.append(new ParagraphElement()
        ..append(dartlangAnchor(gaps['qualifiedName']))
        ..appendText('''\'s comment is too short (under 2 paragraphs)
                        (${DocCoverage.classCommentBrief} points each):''')
    );
    section.append(new ParagraphElement()
        ..innerHtml = gaps['comment']
        ..className = 'quote'
    );
  }
}

void reportOnMethods(Map<String,dynamic> gaps, [Element section]) {
  bool any = false;
  ['getters', 'setters', 'constructors', 'methods'].forEach((cat) {
    if (gaps[cat].length > 0) {
      any = true;
    }
  });
  if (!any) { return; }

  ['getters', 'setters', 'constructors', 'methods'].forEach((cat) => reportOnCategory(cat, gaps, section));
}

void reportOnVariables(Map<String,dynamic> gaps, [Element section]) {
  if (!gaps.containsKey('variables')) return;
  bool any = false;
  if (gaps['variables'].length > 0) {
    any = true;
  }
  if (!any) { return; }

  reportOnCategory('variables', gaps, section);
}

void reportOnCategory(String cat, Map<String,dynamic> gaps, [Element section]) {
  if (section == null) { section = gapsDiv; }
  List missing = gaps[cat]['missing'];
  List noOneLiner = gaps[cat]['no-one-liner'];

  if (missing.length > 0) {
    String catMsg = missing.length == 1 ? '${singularize(cat)} is' : '$cat are';
    section.append(new ParagraphElement()
        ..text = '''${missing.length} $catMsg missing comments
                    (${DocCoverage.memberCommentGap} points each):'''
    );
    UListElement l = new UListElement();
    section.append(l);
    missing.forEach((Map<String,Object> meth) {
      String name = meth['name'] as String;
      if (name.isEmpty) { name = "(default constructor)"; }
      l.append(new LIElement()
          ..append(dartlangAnchor(meth['qualifiedName'] as String, name))
      );
    });
  }

  if (noOneLiner.length > 0) {
    String catMsg = noOneLiner.length == 1 ? '${singularize(cat)} has' : '$cat have';
    section.append(new ParagraphElement()
        ..text = '''${noOneLiner.length} $catMsg no one-liner (the first line is too
                    long) (${DocCoverage.memberCommentIssue} point each):'''
    );
    UListElement l = new UListElement();
    section.append(l);
    noOneLiner.forEach((Map<String,Object> meth) {
      String name = meth['name'] as String;
      if (name.isEmpty) { name = "(default constructor)"; }
      String link = linkToDartlang(meth['qualifiedName'] as String, name);
      l.append(new LIElement()
          ..append(dartlangAnchor(meth['qualifiedName'] as String, name))
          ..append(new ParagraphElement()
              ..innerHtml = meth['comment']
              ..className = 'quote'
          )
      );
    });
  }
}