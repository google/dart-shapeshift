// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

import 'dart:convert';
import 'dart:html';
import 'dart:js';

import 'package:route/client.dart';
import 'package:route/url_pattern.dart';

import 'package:shapeshift/doc_coverage_frontend.dart';

UrlPattern baseUrl = new UrlPattern(r'(.*).html');
UrlPattern libraryScoreUrl = new UrlPattern(r'(.*)#/library/([^/]*)/');
UrlPattern packageScoreUrl = new UrlPattern(r'(.*)#/package/([^/]*)/');
UrlPattern libraryGapsUrl  = new UrlPattern(r'(.*)#/library/([^/]*)/gaps');
UrlPattern packageGapsUrl  = new UrlPattern(r'(.*)#/package/([^/]*)/gaps');
Router router = new Router();

String dartdocs = 'http://www.dartdocs.org/documentation';
String version;
String base;
String versionUrl;


void main() {
  gapsDiv = querySelector('#gaps');
  getPackageButton = querySelector('#getPackage');
  getPackageButton.onClick.listen((_) {
    String name = packageInput.value;
    window.location.hash = name.startsWith('dart:') ?
        '/library/$name/' : '/package/$name/';
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
        ..addHandler(libraryScoreUrl, showLibraryScore)
        ..addHandler(packageScoreUrl, showPackageScore)
        ..addHandler(libraryGapsUrl, showLibraryGaps)
        ..addHandler(packageGapsUrl, showPackageGaps)
        ..listen()
        ..handle(window.location.toString());
}

void sendGaPageview(String path) {
  // Dart JS interop to call:
  //     ga('set', 'page', '/some-path');
  //     ga('send', 'pageview');
  context.callMethod('ga', ['set', 'page', path]);
  context.callMethod('ga', ['send', 'pageview']);
}

void showLibraryScore(String path) {
  String names = libraryScoreUrl.parse(path)[1];
  gapsDiv.innerHtml = '';
  names.split(',').forEach((String name) {
    sendGaPageview('/library/$name');
    // https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/dart-collection.json
    // https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/dart-collection.DoubleLinkedQueue.json
    new SdkLibraryDocAnalyzer(name.replaceFirst(':', '-'))..analyzeScore();
  });
}

void showLibraryGaps(String path) {
  String names = libraryGapsUrl.parse(path)[1];
  gapsDiv.innerHtml = '';
  names.split(',').forEach((String name) {
    // https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/dart-collection.json
    // https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/dart-collection.DoubleLinkedQueue.json
    new SdkLibraryDocAnalyzer(name.replaceFirst(':', '-'))..analyzeGaps();
  });
}

void showPackageScore(String path) {
  String name = packageScoreUrl.parse(path)[1];
  sendGaPageview('/package/$name');
  new PackageDiscovery(name, 'score').discover();
}

void showPackageGaps(String path) {
  String name = packageGapsUrl.parse(path)[1];
  new PackageDiscovery(name, 'gaps').discover();
}

class PackageDiscovery {
  final String name, screen;

  PackageDiscovery(this.name, this.screen);

  void discover() {
    // http://www.dartdocs.org/documentation/args/0.12.1/index.html
    // http://www.dartdocs.org/documentation/args/0.12.1/docs/library_list.json
    // http://www.dartdocs.org/documentation/args/0.12.1/docs/args/args.json
    // http://www.dartdocs.org/documentation/args/0.12.1/docs/args/args.ArgParser.json
    String url = '$dartdocs/$name/latest/';
    HttpRequest.getString(url)
        .then(redirectToPackageVersion)
        .catchError(_handleError);
  }

  void _handleError(ProgressEvent error) =>
      handleError(error, gapsDiv, name: 'Package "$name"');

  void redirectToPackageVersion(String html) {
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

      LibraryDocAnalyzer lda = new LibraryDocAnalyzer(lib['qualifiedName'], base, package: name);
      if (screen == 'score')
        lda.analyzeScore();
      else
        lda.analyzeGaps();
    });
  }
}