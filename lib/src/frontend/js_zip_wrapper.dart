// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shaepshift.frontend.js_zip_wrapper;

import 'dart:async';
import 'dart:html';
import 'dart:js';
import 'dart:typed_data';

import 'package:doc_coverage/doc_coverage_common.dart';

import '../../shapeshift_common.dart';

import 'js_zip_package_reporter.dart';
import 'html_writer.dart';
import 'html_writer_provider.dart';

String _libraryFor(String file) =>
    new RegExp('docgen/([^.]+)').firstMatch(file)[1];

class JSZipWrapper {
  final JsObject zip;
  final List<String> files;

  factory JSZipWrapper(ByteBuffer data) {
    var zip = new JsObject(context['JSZip'], [data]);

    var files = new List<String>.from(
        context['Object'].callMethod('keys', [zip['files']]));

    return new JSZipWrapper._(zip, files);
  }

  JSZipWrapper._(this.zip, this.files);

  Iterable<String> get _jsonFiles => files.where((file) {
    return file.endsWith('.json') &&
        !file.endsWith('index.json') &&
        !file.endsWith('library_list.json');
  });

  Map<String, List<String>> get filesByLibrary {
    var map = <String, List<String>>{};

    for (var file in _jsonFiles) {
      String lib = _libraryFor(file);
      var fileList = map.putIfAbsent(lib, () => <String>[]);
      fileList.add(file);
    }

    return map;
  }

  bool hasFile(String fileName) => files.contains(fileName);

  String read(String fileName) =>
      zip.callMethod('file', [fileName]).callMethod('asText', []) as String;
}

Future<ByteBuffer> getBinaryContent(String uri) {
  var completer = new Completer<ByteBuffer>();

  context['JSZipUtils'].callMethod('getBinaryContent', [
    uri,
    (err, data) {
      if (err != null) {
        completer.completeError(err);
      } else {
        completer.complete(data);
      }
    }
  ]);

  return completer.future;
}

const String issuesUrl = 'https://github.com/google/dart-shapeshift/issues';

void compareZips(Map<String, String> leftVersion, ByteBuffer leftData,
    Map<String, String> rightVersion, ByteBuffer rightData,
    bool includeComments, DivElement diffContainer) {
  String leftV = leftVersion['version'];
  String rightV = rightVersion['version'];
  var header = new HeadingElement.h1()..text = 'Changes from $leftV to $rightV';
  AnchorElement issuesLink = new AnchorElement(href: issuesUrl)
    ..text = 'GitHub';
  var summaryText = new ParagraphElement()
    ..appendText('''The following report is the difference in the public API
             between the Dart $leftV SDK and the Dart $rightV SDK. The
             Shapeshift tool is still very new, and and issue reports at ''')
    ..append(issuesLink)
    ..appendText(' are highly appreciated!');

  diffContainer.children.clear();

  diffContainer..append(header)..append(summaryText);

  DivElement diffElement = new DivElement();
  WriterProvider writer = new HtmlWriterProvider(new HtmlWriter(diffElement));

  var leftHybrid = HybridRevision.parse(leftVersion['path']);
  var rightHybrid = HybridRevision.parse(rightVersion['path']);

  JSZipWrapper leftZip = new JSZipWrapper(leftData);
  JSZipWrapper rightZip = new JSZipWrapper(rightData);

  new JSZipPackageReporter(leftZip, rightZip, leftHybrid, rightHybrid,
      includeComments: includeComments)
    ..calculateAllDiffs()
    ..writeReport(writer);

  diffContainer.append(diffElement);
}
