// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:shapeshift/shapeshift_frontend.dart';

const String storageApiBase =
    "https://www.googleapis.com/storage/v1/b/dart-archive/o";
const String storageBase = "https://storage.googleapis.com/dart-archive";

final Map<String, Map<String, String>> versionMaps = new Map();

void main() {
  leftVersionSelect = querySelector('#left-version');
  rightVersionSelect = querySelector('#right-version');
  includeCommentsCheck = querySelector('#include-comments');
  goButton = querySelector('#get-diff');
  goButton.onClick.listen(go);
  diffContainer = querySelector('#diff-container');

  // TODO: add dev channel.
  HttpRequest
      .getString("$storageApiBase?prefix=channels/stable/release/&delimiter=/")
      .then((resp) {
    getVersionFiles('stable', resp);
  });
  HttpRequest
      .getString("$storageApiBase?prefix=channels/dev/release/&delimiter=/")
      .then((resp) {
    getVersionFiles('dev', resp);
  });
}

void addToSelects(String rev) {
  Map version = versionMaps[rev];
  OptionElement left = new OptionElement()
    ..text = version['version']
    ..attributes['value'] = version['revision'];
  leftVersionSelect.children.add(left);

  OptionElement right = new OptionElement()
    ..text = version['version']
    ..attributes['value'] = version['revision'];
  rightVersionSelect.children.add(right);
}

void getVersionFiles(String channel, String respString) {
  Map<String, Object> resp = JSON.decode(respString);
  List<String> versions = (resp["prefixes"] as List<String>);
  versions.removeWhere((e) => e.contains('latest'));

  // Format is lines of "channels/stable/release/\d+/".
  Iterable<Future> versionRequests = versions.map(
      (String path) => HttpRequest.getString("$storageBase/${path}VERSION"));
  Future versionResponses = Future.wait(versionRequests.toList());
  versionResponses.then((Iterable versionStringsIter) {
    List<String> versionStrings = versionStringsIter.toList();
    versionStrings.map((e) => JSON.decode(e)).forEach((Map<String, String> v) {
      v['channel'] = channel;
      versionMaps[v['revision']] = v;
    });
    List sortedVersions = versionMaps.keys.toList()..sort();
    (sortedVersions.reversed).forEach(addToSelects);

    // Cannot use the newest version as the older version.
    leftVersionSelect.children.first.attributes['disabled'] = 'disabled';
    // Cannot use the oldest version as the newer version.
    rightVersionSelect.children.last.attributes['disabled'] = 'disabled';
  });
}

void go(Event event) {
  String left = leftVersionSelect.selectedOptions[0].attributes['value'];
  String right = rightVersionSelect.selectedOptions[0].attributes['value'];
  bool includeComments = includeCommentsCheck.checked;
  if (left == right)
      // TODO: error
      return;

  // TODO: validate left is "before" right

  compareVersions(versionMaps[left], versionMaps[right], includeComments);
}

void compareVersions(Map left, Map right, bool includeComments) {
  String leftUri = '$storageBase/channels/${left['channel']}/release/' +
      '${left['revision']}/api-docs/dart-api-docs.zip';
  String rightUri = '$storageBase/channels/${right['channel']}/release/' +
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
