// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of doc_coverage_frontend;

class TypedefDocAnalyzer extends MemberDocAnalyzer {
  TypedefDocAnalyzer(LibraryDocAnalyzer libraryDocAnalyzer, Map member) :
    super(libraryDocAnalyzer, member);

  String get decoratedName => 'typedef $name';

  void reportGaps() {
    // TODO;
  }

  Element gapsSection() {
    Element section = new Element.section();
    section.appendHtml('<em>Typedef gap analysis is unimplemented.</em>');
    return section;
  }
}