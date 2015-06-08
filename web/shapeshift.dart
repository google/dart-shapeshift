// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:http/browser_client.dart' as http;
import 'package:path/path.dart' as p;
import 'package:quiver/async.dart' as qa;
import 'package:route_hierarchical/client.dart';
import 'package:shapeshift/shapeshift_frontend.dart';

final Map<HybridRevision, Map<String, String>> _versionMaps =
    new Map<HybridRevision, Map<String, String>>();

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

final Router _router = new Router(useFragment: true);

void main() {
  _goButton.onClick.listen(_goClicked);

  _startDownload();

  _router.root
    ..addRoute(
        name: 'compare',
        path: '/compare',
        enter: (e) => _compareToNavigation(e.route));

  _router.listen();
}

void _addToSelects(HybridRevision rev) {
  Map version = _versionMaps[rev];
  var left = new OptionElement()
    ..text = version['version']
    ..attributes['value'] = rev.value.toString();
  var right = new OptionElement()
    ..text = version['version']
    ..attributes['value'] = rev.value.toString();

  if (version['channel'] == 'stable') {
    _leftVersionStableOptGroup.children.add(left);
    _rightVersionStableOptGroup.children.add(right);
  } else {
    _leftVersionDevOptGroup.children.add(left);
    _rightVersionDevOptGroup.children.add(right);
  }
}

_startDownload() async {
  await _populateVersionFiles('dev');
  await _populateVersionFiles('stable');

  _updateStatus();
  _updateSelectors();

  if (_router.activePath.isNotEmpty) {
    var active = _router.activePath.last;
    if (active.name == 'compare') {
      _router.reload();
    }
  }
}

Future _populateVersionFiles(String channel) async {
  _updateStatus('$channel: getting list');
  List<String> versions;

  var client = new http.BrowserClient();
  var dd = new DartDownloads(client: client);
  try {
    versions = await dd.getVersionPaths(channel).toList();

    versions.removeWhere((e) => e.contains('latest'));

    int finished = 0;
    await qa.forEachAsync(versions, (path) async {
      try {
        var revisionString = p.basename(path);

        var json = await dd.getVersionMap(channel, revisionString);

        json['channel'] = channel;

        json['path'] = revisionString;

        var revision = HybridRevision.parse(revisionString);

        _versionMaps[revision] = json;
      } catch (e) {
        window.console.error("Error with $path - $e");
        return;
      } finally {
        finished++;
        _updateStatus('$channel: $finished of ${versions.length}');
      }
    }, maxTasks: 6);
  } finally {
    dd.close();
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

Future _goClicked(Event event) async {
  var leftVersionString =
      _leftVersionSelect.selectedOptions[0].attributes['value'];
  var rightVersionString =
      _rightVersionSelect.selectedOptions[0].attributes['value'];

  var params = {
    'leftVersion': leftVersionString,
    'rightVersion': rightVersionString
  };

  if (_includeCommentsCheck.checked) {
    params['includeComments'] = 'true';
  }

  await _router.go('compare', {}, queryParameters: params);
}

Future _compareToNavigation(Route route) async {
  var leftVersionString = route.queryParameters['leftVersion'];
  var rightVersionString = route.queryParameters['rightVersion'];

  var includeComments = route.queryParameters.containsKey('includeComments');

  await _compareValues(leftVersionString, rightVersionString, includeComments);
}

Future _compareValues(
    String leftValue, String rightValue, bool includeComments) async {
  try {
    if (_goButton.disabled) {
      print('Waiting on navigation...');
      return;
    }
    _goButton.disabled = true;
    _diffContainer.children.clear();

    _select(_leftVersionSelect, leftValue);
    _select(_rightVersionSelect, rightValue);

    HybridRevision left = HybridRevision.parse(leftValue);
    HybridRevision right = HybridRevision.parse(rightValue);

    // TODO: update selection, right?

    if (left == right) {
      _updateStatus('Cannot compare the same version - $left');
      return;
    }

    try {
      await _compareVersions(
          _versionMaps[left], _versionMaps[right], includeComments);
      _updateStatus();
    } catch (e, stack) {
      _printError(e, stack, 'Error comparing versions.');
    }
  } finally {
    _goButton.disabled = false;
  }
}

Future _compareVersions(Map left, Map right, bool includeComments) async {
  var leftData = await _getData(left['channel'], left['path']);
  var rightData = await _getData(right['channel'], right['path']);

  _updateStatus('Calculating diff');
  compareZips(
      left, leftData, right, rightData, includeComments, _diffContainer);
}

Future<ByteBuffer> _getData(String channel, String revision) async {
  Uri docsUri;

  var client = new http.BrowserClient();
  var dd = new DartDownloads(client: client);
  try {
    docsUri = await dd.getDownloadLink(
        channel, revision, 'api-docs/dart-api-docs.zip');
  } finally {
    dd.close();
  }

  _updateStatus('Downloading docs: $channel $revision');
  return await getBinaryContent(docsUri.toString());
}

void _printError(e, stack, String message) {
  print(message);
  print(e);
  print(stack);
  _updateStatus('$message See console output.');
}

void _select(SelectElement element, String valueAttrValue) {
  var option = element.options.firstWhere((OptionElement oe) {
    return oe.attributes['value'] == valueAttrValue;
  }, orElse: () => null);

  if (option == null) return;

  if (element.selectedOptions.contains(option)) return;

  var index = element.options.indexOf(option);
  element.selectedIndex = index;
}
