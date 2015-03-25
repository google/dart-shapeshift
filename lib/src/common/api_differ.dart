// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_common;

class ApiDiffer {
  final String a, b;

  ApiDiffer(this.a, this.b);

  DiffNode diff() {
    JsonDiffer differ = new JsonDiffer(a, b);
    differ.atomics
      ..add('type')
      ..add('return')
      ..add('annotations[]');
    differ.metadataToKeep
      ..add('qualifiedName');
    differ.ensureIdentical(['name', 'qualifiedName']);
    return differ.diff()
      ..metadata['qualifiedName'] = differ.leftJson['qualifiedName']
      ..metadata['name'] = differ.leftJson['name']
      ..metadata['packageName'] = differ.leftJson['packageName'];
  }
}

DiffNode diffApis(String a, String b) => new ApiDiffer(a, b).diff();