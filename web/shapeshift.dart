// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

import 'dart:convert';
import 'dart:html';

import 'package:shapeshift/shapeshift_frontend.dart';

const String _storageApiBase =
    "https://www.googleapis.com/storage/v1/b/dart-archive/o";
const String _storageBase = "https://storage.googleapis.com/dart-archive";

final Map<int, Map<String, String>> _versionMaps =
    new Map<int, Map<String, String>>();

void main() {
  leftVersionSelect = querySelector('#left-version');
  rightVersionSelect = querySelector('#right-version');
  includeCommentsCheck = querySelector('#include-comments');
  goButton = querySelector('#get-diff');
  goButton.onClick.listen(_go);
  diffContainer = querySelector('#diff-container');

  _startDownload();
}

void _addToSelects(int rev) {
  Map version = _versionMaps[rev];
  OptionElement left = new OptionElement()
    ..text = version['version']
    ..attributes['value'] = version['revision'];
  leftVersionSelect.children.add(left);

  OptionElement right = new OptionElement()
    ..text = version['version']
    ..attributes['value'] = version['revision'];
  rightVersionSelect.children.add(right);
}

_startDownload() async {
  await _getVersionFiles(
      'dev', "$_storageApiBase?prefix=channels/dev/release/&delimiter=/");
  await _getVersionFiles(
      'stable', "$_storageApiBase?prefix=channels/stable/release/&delimiter=/");

  _updateSelectors();
}

_getVersionFiles(String channel, String url) async {
  var respString = await HttpRequest.getString(url);

  Map<String, Object> resp = JSON.decode(respString);
  List<String> versions = (resp["prefixes"] as List<String>);
  versions.removeWhere((e) => e.contains('latest'));

  for (var path in versions) {
    var versionString =
        await HttpRequest.getString("$_storageBase/${path}VERSION");

    var json = JSON.decode(versionString) as Map<String, String>;

    json['channel'] = channel;

    int revision = int.parse(json['revision']);
    _versionMaps[revision] = json;
  }
}

void _updateSelectors() {
  leftVersionSelect.disabled = false;
  rightVersionSelect.disabled = false;
  goButton.disabled = false;

  List sortedVersions = _versionMaps.keys.toList()..sort();

  (sortedVersions.reversed).forEach(_addToSelects);

  // Cannot use the newest version as the older version.
  leftVersionSelect.children.first.attributes['disabled'] = 'disabled';
  // Cannot use the oldest version as the newer version.
  rightVersionSelect.children.last.attributes['disabled'] = 'disabled';
}

void _go(Event event) {
  int left = int.parse(leftVersionSelect.selectedOptions[0].attributes['value']);
  int right = int.parse(rightVersionSelect.selectedOptions[0].attributes['value']);
  bool includeComments = includeCommentsCheck.checked;
  if (left == right)
      // TODO: error
      return;

  // TODO: validate left is "before" right

  _compareVersions(_versionMaps[left], _versionMaps[right], includeComments);
}

void _compareVersions(Map left, Map right, bool includeComments) {
  String leftUri = '$_storageBase/channels/${left['channel']}/release/' +
      '${left['revision']}/api-docs/dart-api-docs.zip';
  String rightUri = '$_storageBase/channels/${right['channel']}/release/' +
      '${right['revision']}/api-docs/dart-api-docs.zip';

  getBinaryContent(rightUri, (err, rightData) {
    //TODO: this, better
    if (err != null) throw err;

    getBinaryContent(leftUri, (err, leftData) {
      //TODO: this, better
      if (err != null) throw err;

      compareZips(left, leftData, right, rightData, includeComments);
    });
  });
}
