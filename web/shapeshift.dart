// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

import 'package:shapeshift/shapeshift_frontend.dart';

const String _storageApiBase =
    "https://www.googleapis.com/storage/v1/b/dart-archive/o";
const String _storageBase = "https://storage.googleapis.com/dart-archive";

const String _flavor = 'raw';

final Map<int, Map<String, String>> _versionMaps =
    new Map<int, Map<String, String>>();

final InputElement _includeCommentsCheck = querySelector('#include-comments');
final InputElement _goButton = querySelector('#get-diff');
final Element _statusElement = querySelector('#status');

final DivElement _diffContainer = querySelector('#diff-container');

final SelectElement _leftVersionSelect = querySelector('#left-version');
final OptGroupElement _leftVersionStableOptGroup =
    _leftVersionSelect.querySelector('.stable');
final OptGroupElement _leftVersionDevOptGroup =
    _leftVersionSelect.querySelector('.dev');

final SelectElement _rightVersionSelect = querySelector('#right-version');
final OptGroupElement _rightVersionStableOptGroup =
    _rightVersionSelect.querySelector('.stable');
final OptGroupElement _rightVersionDevOptGroup =
    _rightVersionSelect.querySelector('.dev');

void main() {
  _goButton.onClick.listen(_go);

  _startDownload();
}

void _addToSelects(int rev) {
  Map version = _versionMaps[rev];
  var left = new OptionElement()
    ..text = version['version']
    ..attributes['value'] = version['revision'];
  var right = new OptionElement()
    ..text = version['version']
    ..attributes['value'] = version['revision'];

  if (version['channel'] == 'stable') {
    _leftVersionStableOptGroup.children.add(left);
    _rightVersionStableOptGroup.children.add(right);
  } else {
    _leftVersionDevOptGroup.children.add(left);
    _rightVersionDevOptGroup.children.add(right);
  }
}

_startDownload() async {
  await _getVersionFiles('dev');
  await _getVersionFiles('stable');

  _updateStatus();
  _updateSelectors();
}

Future _getVersionFiles(String channel) async {
  var url =
      "$_storageApiBase?prefix=channels/${channel}/${_flavor}/&delimiter=/";

  _updateStatus('$channel: getting list');
  var respString = await HttpRequest.getString(url);

  Map<String, Object> resp = JSON.decode(respString);
  List<String> versions = (resp["prefixes"] as List<String>);
  versions.removeWhere((e) => e.contains('latest'));

  for (var i = 0; i < versions.length; i++) {
    _updateStatus('$channel: ${i+1} of ${versions.length}');

    var path = versions[i];

    String versionString;
    try {
      versionString =
          await HttpRequest.getString("$_storageBase/${path}VERSION");
    } catch (_) {
      continue;
    }

    var json = JSON.decode(versionString) as Map<String, String>;

    json['channel'] = channel;

    int revision = int.parse(json['revision']);
    _versionMaps[revision] = json;
  }
}

void _updateSelectors() {
  _leftVersionSelect.disabled = false;
  _rightVersionSelect.disabled = false;
  _goButton.disabled = false;

  _leftVersionStableOptGroup.children.clear();
  _leftVersionDevOptGroup.children.clear();
  _rightVersionStableOptGroup.children.clear();
  _rightVersionDevOptGroup.children.clear();

  List sortedVersions = _versionMaps.keys.toList()..sort();

  (sortedVersions.reversed).forEach(_addToSelects);

  // Cannot use the newest version as the older version.
  //leftVersionSelect.children.first.attributes['disabled'] = 'disabled';
  // Cannot use the oldest version as the newer version.
  //rightVersionSelect.children.last.attributes['disabled'] = 'disabled';
}

void _updateStatus([String value]) {
  if (value == null || value.isEmpty) {
    _statusElement.classes.remove('active');
  } else {
    _statusElement.classes.add('active');
    _statusElement.setInnerHtml('<em>$value</em>');
  }
}

Future _go(Event event) async {
  try {
    if (_goButton.disabled) {
      throw 'Slow down!';
    }
    _goButton.disabled = true;

    int left =
        int.parse(_leftVersionSelect.selectedOptions[0].attributes['value']);
    int right =
        int.parse(_rightVersionSelect.selectedOptions[0].attributes['value']);
    bool includeComments = _includeCommentsCheck.checked;

    if (left == right) {
      _updateStatus('Cannot compare the same version - $left');
      return;
    }

    // TODO: validate left is "before" right

    try {
      await _compareVersions(
          _versionMaps[left], _versionMaps[right], includeComments);
      _updateStatus();
    } catch (e, stack) {
      print('Error comparing versions');
      print(e);
      print(stack);
      _updateStatus('Error comparing versions. See console output.');
    }
  } finally {
    _goButton.disabled = false;
  }
}

Future _compareVersions(Map left, Map right, bool includeComments) async {
  var leftData = await _getData(left['channel'], left['revision']);
  var rightData = await _getData(right['channel'], right['revision']);

  _updateStatus('Calculating diff');
  compareZips(
      left, leftData, right, rightData, includeComments, _diffContainer);
}

Future<ByteBuffer> _getData(String channel, String revision) async {
  var uri = '$_storageBase/channels/$channel/${_flavor}/${revision}'
      '/api-docs/dart-api-docs.zip';

  _updateStatus('Downloading docs: $channel $revision');
  return await getBinaryContent(uri);
}
