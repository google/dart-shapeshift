// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js';

import 'package:shapeshift/shapeshift_frontend.dart';

const String latestApi = 'https://storage.googleapis.com/dart-archive/channels/stable/release/44672/api-docs/dart-api-docs.zip';

const String storageApiBase = "https://www.googleapis.com/storage/v1/b/dart-archive/o";
const String storageBase = "https://storage.googleapis.com/dart-archive";

void main() {
  leftVersionSelect = querySelector('#left-version');
  rightVersionSelect = querySelector('#right-version');
  diffEl = querySelector('#diff');

  context['processZip'] = (err, data) {
    if (err != null) {
      throw 'something something dark side';
    }
    JSZipWrapper zip = new JSZipWrapper(data);
    Map<String, List> files = zip.filesByLibrary;
    List<String> libs = files.keys.toList()..sort((a, b) => a.compareTo(b));
    libs.forEach((String lib) {
      diffEl.innerHtml += '$lib<br />';
    });
  };

  // TODO: add dev channel.
  HttpRequest.getString("$storageApiBase?prefix=channels/stable/release/&delimiter=/")
        .then((resp) { getVersionFiles('stable', resp); });
}

void addToSelects(Map<String, String> version) {
  OptionElement left = new OptionElement()
        ..text = version['version']
        ..attributes['value'] = version['version'];
  leftVersionSelect.children.add(left);

  OptionElement right = new OptionElement()
        ..text = version['version']
        ..attributes['value'] = version['version'];
  rightVersionSelect.children.add(right);
}

void getVersionFiles(String channel, String respString) {
  Map<String,Object> resp = JSON.decode(respString);
  List<String> versions = (resp["prefixes"] as List<String>);
  versions.removeWhere((e) => e.contains('latest'));

  // Format is lines of "channels/stable/release/\d+/".
  Iterable<Future> versionRequests =
      versions.map(
          (String path) => HttpRequest.getString("$storageBase/${path}VERSION"));
  Future versionResponses = Future.wait(versionRequests.toList());
  versionResponses.then((Iterable versionStringsIter) {
    List<String> versionStrings = versionStringsIter.toList();
    List<Map<String, String>> versionMaps =
        versionStrings.map((e) => JSON.decode(e)).toList();
    versionMaps.forEach((map) => map['channel'] = channel);
    versionMaps.sort((a,b) => - a['date'].compareTo(b['date']));
    versionMaps.forEach(addToSelects);

    // Cannot use the newest version as the older version.
    leftVersionSelect.children.first.attributes['disabled'] = 'disabled';
    // Cannot use the oldest version as the newer version.
    rightVersionSelect.children.last.attributes['disabled'] = 'disabled';
    compareVersions(versionMaps[2], versionMaps[0]);
  });
}

void compareVersions(Map<String,String> left, Map<String,String> right) {
  String leftUri = '$storageBase/channels/${left['channel']}/release/' +
      '${left['revision']}/api-docs/dart-api-docs.zip';
  String rightUri = '$storageBase/channels/${right['channel']}/release/' +
      '${right['revision']}/api-docs/dart-api-docs.zip';

  getBinaryContent(rightUri, (err, rightData) {
    //TODO: this, better
    if (err != null)
      throw err;

    getBinaryContent(leftUri, (err, leftData) {
      //TODO: this, better
      if (err != null)
        throw err;

      compareZips(left, leftData, right, rightData);
    });
  });
}