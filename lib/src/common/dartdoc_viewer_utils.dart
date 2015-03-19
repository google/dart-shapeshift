// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_common;

String decoratedName(String qualifiedName) => qualifiedName
    .replaceAll('_', '\\_')
    .replaceFirst('dart-core.', '')
    .replaceAll('-dom-', '-')
    .replaceAll('-', ':');

/// Return the full URL for dart core APIs.
String fullDartlangLocation(String qualifiedName) =>
    'https://api.dartlang.org/apidocs/channels/dev'
        '/dartdoc-viewer/' + Uri.encodeFull(qualifiedName);

String linkToDartlang(String qualifiedName, [String text]) {
  String x = fullDartlangLocation(qualifiedName);
  return '<a href="${x}">${text !=null ? text : decoratedName(qualifiedName)}</a>';
}

/// Return a Markdown link to the Dart id specified by [qualifiedName]. If the
/// text should be something other than [qualifiedName], pass it in as [text].
String mdLinkToDartlang(String qualifiedName, [String text]) {
  return '[${text !=null ? text : decoratedName(qualifiedName)}](${fullDartlangLocation(qualifiedName)})';
}
