// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

import 'dart:convert';
import 'dart:html';

import 'package:route/client.dart';
import 'package:route/url_pattern.dart';

import 'package:shapeshift/doc_coverage_common.dart';
import 'package:shapeshift/doc_coverage_frontend.dart';

UrlPattern baseUrl = new UrlPattern(r'(.*).html');
UrlPattern libraryScoreUrl = new UrlPattern(r'(.*)#/library/([^/]*)');
UrlPattern packageScoreUrl = new UrlPattern(r'(.*)#/package/([^/]*)');
UrlPattern libraryGapsUrl = new UrlPattern(r'(.*)#/library/([^/]*)/gaps');
UrlPattern packageGapsUrl = new UrlPattern(r'(.*)#/package/([^/]*)/gaps');
Router router;

void main() {
  //querySelector('#upload').onChange.listen(readFile);
  //querySelector('#getUrl').onClick.listen(getUrl);
  gapsDiv = querySelector('#gaps');
  getPackageButton = querySelector('#getPackage');
  getPackageButton.onClick.listen((_) {
    String name = packageInput.value;
    window.location.hash = name.startsWith('dart:') ?
        '/library/$name' : '/package/$name';
  });
  packageInput = querySelector('#package');
  packageInput.onKeyUp.listen((keyboardEvent) {
    var keyEvent = new KeyEvent.wrap(keyboardEvent);
    if (keyEvent.keyCode == KeyCode.ENTER && packageInput.value.isNotEmpty) {
      getPackageButton.click();
    }
  });

  router = new Router()
        ..addHandler(baseUrl, (_) => null)
        ..addHandler(libraryGapsUrl, showLibraryGaps)
        ..addHandler(packageGapsUrl, showPackageGaps)
        ..listen()
        ..handle(window.location.toString());
}

void showLibraryGaps(String path) {
  String names = libraryGapsUrl.parse(path)[1];
  gapsDiv.innerHtml = '';
  names.split(',').forEach((String name) {
    getLibrary(name);
  });
}

void showPackageGaps(String path) {
  String name = packageGapsUrl.parse(path)[1];
  getPackage(name);
}

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


String apidocs = 'https://api.dartlang.org/apidocs/channels/stable/docs';
String dartdocs = 'http://www.dartdocs.org/documentation';
String version;
String base;
String versionUrl;

void getLibrary(String name) {
  // https://api.dartlang.org/apidocs/channels/stable/docs/dart-collection.json
  // https://api.dartlang.org/apidocs/channels/stable/docs/dart-collection.DoubleLinkedQueue.json
  new LibraryDocAnalyzer(name.replaceFirst(':', '-'), apidocs)..go();
}

void getPackage(String name) {
  // http://www.dartdocs.org/documentation/args/0.12.1/index.html
  // http://www.dartdocs.org/documentation/args/0.12.1/docs/library_list.json
  // http://www.dartdocs.org/documentation/args/0.12.1/docs/args/args.json
  // http://www.dartdocs.org/documentation/args/0.12.1/docs/args/args.ArgParser.json
  String url = '$dartdocs/$name/latest/';
  HttpRequest.getString(url)
      .then((data) => redirectToPackageVersion(data, name))
      .catchError((err) {
        var target = err.currentTarget;
        gapsDiv.innerHtml = '';
        gapsDiv.append(new DivElement()
            ..classes.add('error')
            ..text = 'Error from ${target.responseUrl}: ${target.status} ${target.statusText}'
        );
      });
}

void redirectToPackageVersion(String html, String name) {
  // This is wacky. dartdocs.org doesn't offer a URL that reports back the
  // latest version of a package (AFAIK). So, I punch out to latest/, which
  // gives me back an HTML file which includes some JavaScript that redirects
  // to the latest package version. Wah-wah. So we parse that HTML (really the
  // JavaScript inside), for said version:
  RegExp pattern = new RegExp("latestUrl='$dartdocs/$name/([^/]+)/index.html'");
  if (pattern.hasMatch(html)) {
    version = pattern.firstMatch(html)[1];
    versionUrl = '$dartdocs/$name/$version/index.html';
    base = '$dartdocs/$name/$version/docs';
    String url = '$base/library_list.json';
    HttpRequest.getString(url).then(reportPackage);
  } else {
    gapsDiv.text = 'Error! $html';
  }
}

void report(String json) {
  Map<String,dynamic> gaps = new DocCoverage().calculateCoverage(json);
  gapsDiv.innerHtml = '';
  
  /*if (gaps['packageName'] != null) reportLibraryGaps(gaps);
  else reportClassGaps(gaps);*/
}

void reportPackage(String json) {
  Map<String,dynamic> package;
  dynamic _package = new JsonDecoder().convert(json);
  if (_package is Map) {
    package = _package;
  } else {
    throw new FormatException('JSON must be JSON, not $json');
  }
  gapsDiv.innerHtml = '';

  // A hack to get past the dart: libraries up front.
  Map lastLib = package['libraries'][package['libraries'].length - 1];
  AnchorElement versionAnchor = new AnchorElement()
      ..text = 'Using version $version docs from dartdocs.org'
      ..classes.add('version')
      ..attributes['href'] = '$versionUrl#${lastLib['qualifiedName']}';

  gapsDiv
      ..append(new HeadingElement.h1()..text = 'package ${lastLib['packageName']}')
      ..append(versionAnchor);

  (package['libraries'] as List).forEach((Map lib) {
    if (!(lib['name'] as String).startsWith('dart-pkg') &&
        ((lib['name'] as String).startsWith('dart-') ||
         (lib['name'] as String).startsWith('dart:'))) return;

    new LibraryDocAnalyzer(lib['qualifiedName'], base)..go();
  });
}

/*void reportLibraryGaps(Map<String,dynamic> gaps) {
  gapsDiv.children.add(new HeadingElement.h2()..text = 'library ${gaps['qualifiedName']}');
  gapsDiv.children.add(new HeadingElement.h3()..text = 'Gap Count: ${gaps['gapCount'].toString()}');

  reportOnTopLevelComment(gaps);
}*/

