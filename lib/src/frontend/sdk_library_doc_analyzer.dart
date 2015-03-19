// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of doc_coverage_frontend;

class SdkLibraryDocAnalyzer extends LibraryDocAnalyzer {
  static final String apiDartlang =
      'https://api.dartlang.org/apidocs/channels/stable';
  SdkLibraryDocAnalyzer(String name) : super(name, '$apiDartlang/docs');

  void analyzeScore() {
    htmlUrl = '$apiDartlang/dartdoc-viewer/$nameWithColon';

    super.analyzeScore();

    AnchorElement linkToDocs = new AnchorElement()
      ..attributes['href'] = htmlUrl
      ..text = 'api.dartlang.org';
    ParagraphElement p = new ParagraphElement()
      ..appendText('View $name docs at ')
      ..append(linkToDocs)
      ..appendText('.');
    section.insertBefore(p, section.lastChild);
  }
}
