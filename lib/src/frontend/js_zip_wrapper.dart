// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shaepshift.frontend.js_zip_wrapper;

import 'dart:async';
import 'dart:html';
import 'dart:js';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sdk_builds/sdk_builds.dart';

import 'js_zip_package_reporter.dart';
import 'html_writer.dart';
import 'html_writer_provider.dart';

String _libraryFor(String file) {
  var segments = p.split(file);
  var fileSegment = segments.last;
  assert(p.extension(fileSegment) == '.json');
  var fileParts = fileSegment.split('.');
  return fileParts.first;
}

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

void compareZips(VersionInfo leftVersion, ByteBuffer leftData,
    VersionInfo rightVersion, ByteBuffer rightData, bool includeComments,
    DivElement diffContainer) {
  String leftV = leftVersion.version.toString();
  String rightV = rightVersion.version.toString();
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

  JSZipWrapper leftZip = new JSZipWrapper(leftData);
  JSZipWrapper rightZip = new JSZipWrapper(rightData);

  var reporter = new JSZipPackageReporter(
      leftZip, rightZip, leftVersion, rightVersion,
      includeComments: includeComments);

  var contentHost = new DivElement()..classes.add("the-host");

  new _UIManager(contentHost, reporter);

  diffContainer.append(contentHost);
}

class _UIManager {
  static const _disabledClass = 'disabled';
  bool get _working => _header.classes.contains(_disabledClass);

  final DivElement _host;
  final JSZipPackageReporter _reporter;
  final DivElement _header;

  DivElement _content;

  _UIManager(this._host, this._reporter) : this._header = new DivElement()
        ..classes.add('the-header') {
    var libraryNames = _reporter.rightZip.filesByLibrary.keys.toList();
    libraryNames.sort();

    for (var libText in libraryNames) {
      assert(libText.startsWith('dart-'));

      var link = new AnchorElement()..text = libText.substring(5);

      link.onClick.listen((_) {
        _writeContent(libText);
      });

      _header.children.add(link);

      _header.appendHtml(r' ');
    }

    _host.append(_header);

    _content = new DivElement()
      ..text = 'content here!'
      ..classes.add('the-content');

    _host.append(_content);

    _writeContent('dart-core');
  }

  Future _writeContent(String library) async {
    if (_working) return;

    try {
      _header.classes.add(_disabledClass);
      _content.children.clear();

      _content.text = 'Loading $library ...';

      await letHtmlUpdate();

      var report = await _reporter.calculateDiffForLibrary(library);

      _content.children.clear();
      var writer = new HtmlWriterProvider(new HtmlWriter(_content));
      report.write(writer);
    } finally {
      _header.classes.remove(_disabledClass);
    }
  }
}
