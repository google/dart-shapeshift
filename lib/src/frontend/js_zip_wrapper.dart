// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_frontend;

class JSZipWrapper {
  final JsObject zip;

  JSZipWrapper(data)
      : zip = new JsObject(context['JSZip'], [data]);

  static String libraryFor(String file) =>
      new RegExp('docgen/([^.]+)').firstMatch(file)[1];

  List<String> get files {
    JsArray fileArray = context['Object'].callMethod('keys', [zip['files']]);
    return fileArray.map((e) => e).toList();
  }

  List<String> get jsonFiles =>
    files..removeWhere((file) =>
        !file.endsWith('.json') || file.endsWith('index.json') || file.endsWith('library_list.json'));

  Map<String, List<String>> get filesByLibrary {
    Map<String, List<String>> map = new Map();

    jsonFiles.forEach((file) {
      String lib = libraryFor(file);
      if (!map.containsKey(lib))
        map[lib] = new List();
      map[lib].add(file);
    });

    return map;
  }

  bool hasFile(String fileName) => zip['files'].hasProperty(fileName);

  String read(String fileName) => zip.callMethod('file', [fileName]).callMethod('asText', []) as String;
}

void compareZips(Map<String, String> leftVersion, leftData, Map<String, String> rightVersion, rightData) {
  diffEl.innerHtml += '<h2>${leftVersion['version']}</h2>';
  diffEl.innerHtml += '<h2>${rightVersion['version']}</h2>';
  JSZipWrapper leftZip = new JSZipWrapper(leftData);
  JSZipWrapper rightZip = new JSZipWrapper(rightData);
  WriterProvider writer = new HtmlWriterProvider(new HtmlWriter(diffEl));

  new JSZipPackageReporter(leftZip, rightZip, writer)
    ..calculateAllDiffs()
    ..report();
}