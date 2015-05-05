// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shaepshift.frontend.null_tree_sanitiver;

import 'dart:html';

class _NullTreeSanitizer implements NodeTreeSanitizer {
  const _NullTreeSanitizer();
  void sanitizeTree(Node node) {}
}

const nullTreeSanitizer = const _NullTreeSanitizer();
