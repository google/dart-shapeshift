// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shapeshift_cli.directory_diff_writer_provider;

import 'package:doc_coverage/doc_coverage_cli.dart';
import 'package:doc_coverage/doc_coverage_common.dart';
import '../../shapeshift_common.dart';

/// A [WriterProvider] that provides a [MarkdownDiffWriter] that writes to a new
/// Markdown file for each library.
class DirectoryDiffWriterProvider extends DirectoryWriterProvider {
  /// Constructs a [DirectoryDiffWriterProvider] that will use [path] when creating
  /// new writers.
  DirectoryDiffWriterProvider(path) : super(path);

  MarkdownWriter writerCtor(fileTargetBuilder, {bool shouldClose: true}) =>
      new MarkdownDiffWriter(fileTargetBuilder, shouldClose: shouldClose);
}
