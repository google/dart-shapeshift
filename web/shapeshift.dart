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

  HttpRequest.getString("$storageApiBase?prefix=channels/stable/release/&delimiter=/")
        .then((resp) { getListing('stable', resp); });
}

void getListing(String channel, String respString) {
  Map<String,Object> resp = JSON.decode(respString);
  List<String> versions = (resp["prefixes"] as List<String>);
  versions.removeWhere((e) => e.contains('latest'));

  // Format is lines of "channels/stable/release/\d+/".
  Iterable<Future> versionRequests = versions.map((String path) => HttpRequest.getString("$storageBase/${path}VERSION"));
  Future versionResponses = Future.wait(versionRequests.toList());
  versionResponses.then((Iterable versionStringsIter) {
    List<String> versionStrings = versionStringsIter.toList();
    List<Map<String,String>> versionMaps = versionStrings.map((e) => JSON.decode(e)).toList();
    versionMaps.forEach((map) => map['channel'] = channel);
    versionMaps.sort((a,b) => - a['date'].compareTo(b['date']));
    compareVersions(versionMaps[1], versionMaps[0]);
  });
}

void compareVersions(Map<String,String> left, Map<String,String> right) {
  String leftUri = '$storageBase/channels/${left['channel']}/release/' +
      '${left['revision']}/api-docs/dart-api-docs.zip';
  String rightUri = '$storageBase/channels/${right['channel']}/release/' +
      '${right['revision']}/api-docs/dart-api-docs.zip';
  diffEl.innerHtml += '<h2>${left['version']} =&gt; ${right['version']}</h2>';
  context['JSZipUtils']
      .callMethod('getBinaryContent', [rightUri, (err, rightData) {
        if (err != null)
          throw err;
        context['JSZipUtils']
            .callMethod('getBinaryContent', [leftUri, (err, leftData) {
              if (err != null)
                throw err;
              compareZips(left, leftData, right, rightData);
            }]);
      }]);
}