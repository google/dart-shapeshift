// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of doc_coverage_frontend;

class LibraryCommentDocAnalyzer extends MemberDocAnalyzer {
  LibraryCommentDocAnalyzer(LibraryDocAnalyzer libraryDocAnalyzer, Map member) :
    super(libraryDocAnalyzer, member);

  String get decoratedName => 'library $name';

  void reportGaps() {
    // TODO;
  }

  Element gapsSection() {
    Element section = new Element.section();
    section.appendHtml('<em>Library comment gap analysis is unimplemented.</em>');
    return section;
  }
}