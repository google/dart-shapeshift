// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shaepshift.frontend.html_writer_provider;

import '../../shapeshift_common.dart';
import 'package:doc_coverage/doc_coverage_common.dart';

import 'html_writer.dart';

class HtmlWriterProvider extends WriterProvider {
  HtmlWriter sink;
  HtmlWriterProvider(this.sink);

  MarkdownWriter writerFor(String _) => new MarkdownDiffWriter(() => sink,
      shouldClose: false, shouldWriteMetadata: false);
}
