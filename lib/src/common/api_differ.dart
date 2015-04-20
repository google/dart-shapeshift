// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shapeshift_common.api_differ;

import 'package:json_diff/json_diff.dart';

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
