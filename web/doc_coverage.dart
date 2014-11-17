import 'dart:convert';
import 'dart:html';

import 'package:shapeshift/doc_coverage_common.dart';
import 'package:shapeshift/shapeshift_common.dart';
import 'package:shapeshift/shapeshift_frontend.dart';

Element log = querySelector("#log");
Element gapsDiv = querySelector('#gaps');

void main() {
  querySelector('#upload').onChange.listen(readFile);
  querySelector('#getUrl').onClick.listen(getUrl);
  querySelector('#getPackage').onClick.listen(getPackage);
  String p = window.location.pathname;
  String dir = p.substring(0, p.lastIndexOf('/'));
  /*querySelector('.such-as')
      ..appendHtml(' or<br />')
      ..append(new SpanElement()
          ..appendText('${window.location.protocol}//${window.location.host}/${dir}/dart-collection.SetMixin.json')
      );*/
}

// http://www.dartdocs.org/documentation/args/0.12.1/index.html
// http://www.dartdocs.org/documentation/args/0.12.1/docs/library_list.json
// http://www.dartdocs.org/documentation/args/0.12.1/docs/args/args.json
// http://www.dartdocs.org/documentation/args/0.12.1/docs/args/args.ArgParser.json

void readFile(Event event) {
  FileList fs = (event.target as InputElement).files;
  File f = fs.item(0);
  FileReader reader = new FileReader();
  reader.onLoad.listen((fe) => report(fe.target.result) );
  reader.readAsText(f);
}

void getUrl(Event event) {
  String url = (querySelector("#url") as InputElement).value;
  HttpRequest.getString(url).then(report);
}

String base;

void getPackage(Event event) {
  String nameVersion = (querySelector("#package") as InputElement).value;
  String url = 'http://www.dartdocs.org/documentation/$nameVersion/index.html';
  base = url.substring(0, url.lastIndexOf('/')) + '/docs';
  String library_list = '$base/library_list.json';
  HttpRequest.getString(library_list).then(reportPackages);
}


void report(json) {
  Map<String,dynamic> gaps = new DocCoverage().calculateCoverage(json);
  log.text = "raw gaps: ${gaps}";
  gapsDiv.innerHtml = '';
  
  if (gaps['packageName'] != null) reportLibraryGaps(gaps);
  else reportClassGaps(gaps);
}

void reportPackages(json) {
  Map<String,dynamic> package;
  dynamic _package = new JsonDecoder().convert(json);
  if (_package is Map) {
    package = _package;
  } else {
    throw new FormatException('JSON must be JSON, not $json');
  }
  gapsDiv.text = '';

  (package['libraries'] as List).forEach((Map lib) {
    if ((lib['name'] as String).startsWith('dart-')) return;
    gapsDiv.append(new HeadingElement.h2()..text = 'package ${lib['packageName']}');
    HttpRequest.getString('$base/${lib['qualifiedName']}.json').then(reportPackage);
  });
}

void reportPackage(String json) {
  Map<String,dynamic> package = new JsonDecoder().convert(json);
  //classes[class[], error[], typedef[]], comment, functions, variables
  (package['classes']['class'] as List).forEach((klass) {
    HttpRequest.getString('$base/${klass['qualifiedName']}.json').then(reportClass);
  });
}

void reportClass(String json) {
  Map<String,dynamic> klass = new JsonDecoder().convert(json);
  //gapsDiv.append(new HeadingElement.h3()..text = 'class ${klass['name']}');
  Map<String,dynamic> gaps = new DocCoverage().calculateCoverage(json);
  reportClassGaps(gaps);
}

void reportLibraryGaps(Map<String,dynamic> gaps) {
  gapsDiv.children.add(new HeadingElement.h1()..text = 'library ${gaps['qualifiedName']}');
  gapsDiv.children.add(new HeadingElement.h2()..text = 'Gap Count: ${gaps['gapCount'].toString()}');
  
  reportOnTopLevelComment(gaps);
}

void reportClassGaps(Map<String,dynamic> gaps) {
  gapsDiv.children.add(new HeadingElement.h1()..text = 'class ${gaps['name']}');
  gapsDiv.children.add(new HeadingElement.h2()..text = 'Gap Count: ${gaps['gapCount'].toString()}');
  
  reportOnTopLevelComment(gaps);
  reportOnMethods(gaps);
  reportOnVariables(gaps);
}

void reportOnTopLevelComment(Map<String,dynamic> gaps) {
  if (!gaps.containsKey('comment') || (gaps['comment'] as String).isEmpty) {
    gapsDiv.append(new ParagraphElement()
        ..append(dartlangAnchor(gaps['qualifiedName']))
        ..appendText(' has no comment!')
    );
  }
  else if ((gaps['comment'] as String).split('\n').length < 2 ) {
    String x = linkToDartlang(gaps['qualifiedName']);
    gapsDiv.append(new ParagraphElement()
        ..append(dartlangAnchor(gaps['qualifiedName']))
        ..appendText('\'s comment is too short:')
    );
    gapsDiv.append(new ParagraphElement()
        ..innerHtml = gaps['comment']
        ..className = 'quote'
    );
  }
}

reportOnMethods(Map<String,dynamic> gaps) {
  bool any = false;
  ['getters', 'setters', 'constructors', 'methods'].forEach((cat) {
    if (gaps[cat].length > 0) {
      any = true;
    }
  });
  if (!any) { return; }
  
  ['getters', 'setters', 'constructors', 'methods'].forEach((cat) => reportOnCategory(cat, gaps));
}

void reportOnVariables(Map<String,dynamic> gaps) {
  if (!gaps.containsKey('variables')) return;
  bool any = false;
  if (gaps['variables'].length > 0) {
    any = true;
  }
  if (!any) { return; }
  
  reportOnCategory('variables', gaps);
}

void reportOnCategory(String cat, Map<String,dynamic> gaps) {
  List missing = gaps[cat]['missing'];
  List noOneLiner = gaps[cat]['no-one-liner'];

  if (missing.length > 0) {
    String catMsg = missing.length == 1 ? '${singularize(cat)} is' : '$cat are';
    gapsDiv.append(new ParagraphElement()
        ..text = '${missing.length} ${catMsg} missing comments:'
    );
    UListElement l = new UListElement();
    gapsDiv.append(l);
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
    gapsDiv.append(new ParagraphElement()
        ..text = '${noOneLiner.length} ${catMsg} no one-liner (the first line is too long):'
    );
    UListElement l = new UListElement();
    gapsDiv.append(l);
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