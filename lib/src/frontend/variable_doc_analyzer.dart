// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of doc_coverage_frontend;

class VariableDocAnalyzer extends MemberDocAnalyzer {
  VariableDocAnalyzer(LibraryDocAnalyzer libraryDocAnalyzer, Map member) :
    super(libraryDocAnalyzer, member);

  String get decoratedName => 'property $name';

  void reportGaps() {
    // TODO;
  }
}