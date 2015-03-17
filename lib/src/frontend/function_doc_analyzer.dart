// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of doc_coverage_frontend;

class FunctionDocAnalyzer extends MemberDocAnalyzer {
  final String methodType;

  FunctionDocAnalyzer(LibraryDocAnalyzer libraryDocAnalyzer, _methodType, Map member) :
    super(libraryDocAnalyzer, member),
    // For some reason, the method types are delivered plural.
    methodType = _methodType.replaceFirst(new RegExp('s\$'), '');

  String get decoratedName => '$methodType $name';

  void reportGaps() {
    // TODO;
  }
}