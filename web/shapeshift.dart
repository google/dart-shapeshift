// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:shapeshift/shapeshift_frontend.dart';

const String _storageApiBase =
    "https://www.googleapis.com/storage/v1/b/dart-archive/o";
const String _storageBase = "https://storage.googleapis.com/dart-archive";

final Map<int, Map<String, String>> _versionMaps =
    new Map<int, Map<String, String>>();

final Element statusElement = querySelector('#status');
void main() {
  leftVersionSelect = querySelector('#left-version');
  rightVersionSelect = querySelector('#right-version');
  leftVersionStableOptGroup = leftVersionSelect.querySelector('.stable');
  leftVersionDevOptGroup = leftVersionSelect.querySelector('.dev');
  rightVersionStableOptGroup = rightVersionSelect.querySelector('.stable');
  rightVersionDevOptGroup = rightVersionSelect.querySelector('.dev');
  includeCommentsCheck = querySelector('#include-comments');
  goButton = querySelector('#get-diff');
  goButton.onClick.listen(_go);
  diffContainer = querySelector('#diff-container');
  statusElement = querySelector('#status');

  _startDownload();
}

void _addToSelects(int rev) {
  Map version = _versionMaps[rev];
  OptionElement left = new OptionElement()
    ..text = version['version']
    ..attributes['value'] = version['revision'];
  OptionElement right = new OptionElement()
    ..text = version['version']
    ..attributes['value'] = version['revision'];

  if (version['channel'] == 'stable') {
    leftVersionStableOptGroup.children.add(left);
    rightVersionStableOptGroup.children.add(right);
  } else {
    leftVersionDevOptGroup.children.add(left);
    rightVersionDevOptGroup.children.add(right);
  }
}

_startDownload() async {
  await _getVersionFiles(
      'dev', "$_storageApiBase?prefix=channels/dev/release/&delimiter=/");
  await _getVersionFiles(
      'stable', "$_storageApiBase?prefix=channels/stable/release/&delimiter=/");

  _updateStatus();
  _updateSelectors();
}

_getVersionFiles(String channel, String url) async {
  _updateStatus('$channel: getting list');
  var respString = await HttpRequest.getString(url);

  Map<String, Object> resp = JSON.decode(respString);
  List<String> versions = (resp["prefixes"] as List<String>);
  versions.removeWhere((e) => e.contains('latest'));

  for (var i = 0; i < versions.length; i++) {
    _updateStatus('$channel: ${i+1} of ${versions.length}');

    var path = versions[i];

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

  leftVersionStableOptGroup.children.clear();
  leftVersionDevOptGroup.children.clear();
  rightVersionStableOptGroup.children.clear();
  rightVersionDevOptGroup.children.clear();

  List sortedVersions = _versionMaps.keys.toList()..sort();

  (sortedVersions.reversed).forEach(_addToSelects);

  // Cannot use the newest version as the older version.
  //leftVersionSelect.children.first.attributes['disabled'] = 'disabled';
  // Cannot use the oldest version as the newer version.
  //rightVersionSelect.children.last.attributes['disabled'] = 'disabled';
}

void _updateStatus([String value]) {
  if (value == null || value.isEmpty) {
    statusElement.classes.remove('active');
  } else {
    statusElement.classes.add('active');
    statusElement.setInnerHtml('<em>$value</em>');
  }
}

Future _go(Event event) async {
  try {
    if (goButton.disabled) {
      throw 'Slow down!';
    }
    goButton.disabled = true;

    _updateStatus('Calculating diff');

    int left =
        int.parse(leftVersionSelect.selectedOptions[0].attributes['value']);
    int right =
        int.parse(rightVersionSelect.selectedOptions[0].attributes['value']);
    bool includeComments = includeCommentsCheck.checked;

    if (left == right) {
      _updateStatus('Cannot compare the same version - $left');
      return;
    }

    // TODO: validate left is "before" right

    await _compareVersions(
        _versionMaps[left], _versionMaps[right], includeComments);
    _updateStatus();
  } finally {
    goButton.disabled = false;
  }
}

Future _compareVersions(Map left, Map right, bool includeComments) async {
  String leftUri = '$_storageBase/channels/${left['channel']}/release/' +
      '${left['revision']}/api-docs/dart-api-docs.zip';
  String rightUri = '$_storageBase/channels/${right['channel']}/release/' +
      '${right['revision']}/api-docs/dart-api-docs.zip';

  var rightData = await getBinaryContent(rightUri);

  var leftData = await getBinaryContent(leftUri);

  compareZips(left, leftData, right, rightData, includeComments);
}
