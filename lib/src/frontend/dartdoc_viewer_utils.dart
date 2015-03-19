// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_frontend;

AnchorElement dartlangAnchor(String qualifiedName, [String text]) {
  return new AnchorElement()
    ..text = text != null ? text : decoratedName(qualifiedName)
    ..attributes['href'] = fullDartlangLocation(qualifiedName);
}
