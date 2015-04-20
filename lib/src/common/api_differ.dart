// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shapeshift_common.api_differ;

import 'package:json_diff/json_diff.dart';

import 'utils.dart';

class ApiDiffer {
  final String a, b;
  final bool includeComments;

  ApiDiffer(this.a, this.b, {this.includeComments: true});

  DiffNode diff() {
    JsonDiffer differ = new JsonDiffer(a, b);
    differ.atomics
      ..add('type')
      ..add('return')
      ..add('annotations[]');
    differ.metadataToKeep..add('qualifiedName');
    if (!includeComments) differ.ignored.add('comment');
    differ.ensureIdentical(['name', 'qualifiedName']);
    return differ.diff()
      ..metadata['qualifiedName'] = differ.leftJson['qualifiedName']
      ..metadata['name'] = differ.leftJson['name']
      ..metadata['packageName'] = differ.leftJson['packageName'];
  }
}

DiffNode diffApis(String a, String b, {includeComments: true}) =>
    new ApiDiffer(a, b, includeComments: includeComments).diff();

DiffNode diffSdkApis(String left, String right, int leftRevision,
    int rightRevision, {includeComments: true}) {
  // The dartdoc utility used to generate JSON for the Dart SDK with names of
  // libraries and library members that looked like "dart-core",
  // "dart-core.String", etc. After revision 41515 (Dart 1.8.0-dev.3.0),
  // dartdoc generated JSON with names that look instead like "dart:core", and
  // "dart:core.String". So when comparing a revision <= 41515 with a
  // revision > 41515, the diff will think that every single library and
  // library member was renamed. So we have to do this ugly munging.
  int lastRevisionWithHyphens = 41515;

  if (leftRevision <= lastRevisionWithHyphens
      && rightRevision > lastRevisionWithHyphens) {
    left = scrubHyphens(left);
  }

  return diffApis(left, right, includeComments: includeComments);
}
