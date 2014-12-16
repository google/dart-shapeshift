// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of doc_coverage_frontend;

class LibraryDocAnalyzer {

  String name, base;
  final Element section = new Element.section();
  final ParagraphElement classShield = new ParagraphElement();
  List<Element> sortedSections = new List();

  LibraryDocAnalyzer(this.name, this.base);

  void prepareElements() {
    sortedSections.clear();

    section
        ..append(new HeadingElement.h1()..text = 'library ${name}')
        ..classes.add('hidden');
    gapsDiv.append(section);
    classShield.dataset['value'] = '0';
    section.append(classShield);
  }

  void analyzeScore() {
    prepareElements();
    getJsonAndReport(reportClassScore);
  }

  void analyzeGaps() {
    prepareElements();
    getJsonAndReport(reportClassGaps);
  }

  void getJsonAndReport(Function callback) {
    // TODO: Refactor into a ClassDocAnalyzer class!
    HttpRequest.getString('$base/${name}.json').then((String json) {
      Map<String,dynamic> package = new JsonDecoder().convert(json);
      //classes[class[], error[], typedef[]], comment, functions, variables
      ['class', 'error'].forEach((classType) =>
        (package['classes'][classType] as List).forEach((klass) {
          String className = klass['qualifiedName'].replaceFirst(':', '-');
          HttpRequest.getString('$base/$className.json').then(
              (String json) => callback.call(json, classType)
          );
        })
      );
    });
  }

  void reportClassScore(String json, String classType) {
    Map<String,dynamic> klass = new JsonDecoder().convert(json);
    String className = klass['name'];
    DocCoverage dc = new DocCoverage();
    int score = (100*dc.calculateScore(json)).toInt();
    Element classSection = new Element.section();

    section.classes.remove('hidden');
    addToSortedSections(classSection, score.toInt(), reverse: true);
    ImageElement shieldImg = new ImageElement()
        ..attributes['src'] = dc.shieldUrl(json)
        ..classes.add('shield');
    classSection.dataset['count'] = '${score.toInt()}';
    classSection.append(new ParagraphElement()
            ..text = '$classType $className')
            ..append(shieldImg);
  }

  void reportClassGaps(String json, String classType) {
    Map<String,dynamic> klass = new JsonDecoder().convert(json);
    Map<String,dynamic> gaps = new DocCoverage().calculateCoverage(json);
    if (gaps['gapCount'] == 0) { return; }
    int gapCount = gaps['gapCount'];
    Element classSection = new Element.section();

    section.classes.remove('hidden');
    int sum = (int.parse(classShield.dataset['value'])) + gapCount;
    classShield.dataset['value'] = sum.toString();
    classShield.innerHtml = '<em>Coverage gap total: $sum points</em>';

    addToSortedSections(classSection, gapCount);
    classSection.dataset['count'] = '$gapCount';
    classSection.append(new HeadingElement.h2()
        ..text = '$classType ${gaps['name']}')
        ..append(new SpanElement()..text = '($gapCount points of coverage gaps)');

    reportOnTopLevelComment(gaps, classSection);
    reportOnMethods(gaps, classSection);
    reportOnVariables(gaps, classSection);
  }

  void addToSortedSections(Element classSection, int gapCount, {bool reverse: false}) {
    // This is craziness. There has to be a better way.
    int i = 0;
    if (sortedSections.isEmpty) {
      sortedSections.add(classSection);
      section.append(classSection);
      return;
    }

    bool keepGoing() {
      int count = int.parse(sortedSections[i].dataset['count']);
      return reverse ? gapCount > count : gapCount < count;
    }

    while (i < sortedSections.length && keepGoing()) { i++; }

    if (i == sortedSections.length) {
      section.append(classSection);
    }
    else {
      section.insertBefore(classSection, sortedSections[i]);
    }
    sortedSections.insert(i, classSection);
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