// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shapeshift_common.utils;

RegExp oldStyle = new RegExp(r'"(name|outer|qualifiedName|return|superclass)":\s*"dart-');
RegExp oldStyleList =
    new RegExp(r'"implements":\s*\[(("dart-[^"]+"(,\s*)?)+)\]');
RegExp oldStyleLink =
    new RegExp(r'a( href="[^"]*")?>dart-');

String scrubHyphens(String json) {
  String _replaceAllNamesInAList(Match m) {
    var names = m[1].replaceAll(new RegExp(r'"dart-'), r'"dart:');
    return '"implements":[$names]';
  }

  return json
      .replaceAllMapped(oldStyle, (Match m) => '"${m[1]}":"dart:')
      .replaceAllMapped(oldStyleList, _replaceAllNamesInAList)
      .replaceAllMapped(oldStyleLink,
          (Match m) => 'a${m[1] == null ? '' : m[1]}>dart:');
}