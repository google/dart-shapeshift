// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

/// Test helpers for Shapeshift's tests.
library test_helpers;

import 'dart:convert';

jsonFrom(Map obj) => new JsonEncoder().convert(obj);

Map<String, dynamic> classWithVariables(Map variables) =>
  baseClass
    ..['variables'] = variables;

Map<String, dynamic> classWithMethods(Map methods) =>
  baseClass
    ..['methods']['methods'] = methods;

Map<String, dynamic> get baseClass => {
  'name': 'Foo',
  'qualifiedName': 'foo.Foo',
  'variables': {},
  'methods': {
    'setters': {},
    'getters': {},
    'constructors': {},
    'operators': {},
    'methods': {},
  }
};

Map<String, dynamic> variableNamed(String name) =>
    baseVariable
      ..['name'] = name
      ..['qualifiedName'] = 'foo.Foo.$name';

Map<String, dynamic> get baseVariable => {
  'name': 'foo',
  'qualifiedName': 'foo.Foo.foo',
  'comment': '<p>Send a data event to a stream.</p>',
  'final': false,
  'static': false,
  'constant': false,
  'type': [
    {'outer': 'dart:core.String', 'inner': []},
  ],
  'annotations': [],
};

Map<String, dynamic> methodNamed(String name) =>
    baseMethod
      ..['name'] = name
      ..['qualifiedName'] = 'foo.Foo.$name';

Map<String, dynamic> get baseMethod => {
  'name': 'foo',
  'qualifiedName': 'foo.Foo.foo',
  'comment': '<p>Send a data event to a stream.</p>',
  'commentFrom': '',
  'inheritedFrom': '',
  'static': false,
  'abstract': false,
  'constant': false,
  'return': [
    {'outer': 'dart:core.String', 'inner': []},
  ],
  'parameters': {},
  'annotations': [],
};

Map<String, dynamic> get baseParameter => {
  'name': 'p',
  'optional': false,
  'named': false,
  'default': false,
  'type': [
    {'outer': 'dart:core.String', 'inner': []}
  ],
};