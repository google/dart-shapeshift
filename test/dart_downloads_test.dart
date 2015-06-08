library shapshift.test.dart_downloads_test;

import 'package:shapeshift/src/frontend/dart_downloads.dart';
import 'package:test/test.dart';

DartDownloads _dd;

main() async {
  setUp(() {
    _dd = new DartDownloads();
  });

  tearDown(() {
    if (_dd != null) {
      _dd.close();
    }
    _dd = null;
  });

  test('get version', () async {
    var revision = '31822';
    var channel = 'stable';

    var version = await _dd.getVersion(channel, revision);

    expect(version, '1.1.1');
  });

  test('get version paths', () async {
    var channel = 'stable';

    var paths = await _dd.getVersionPaths(channel).toList();

    expect(paths, contains('channels/stable/release/29803/'));
    expect(paths, contains('channels/stable/release/latest/'));
    expect(paths.length, greaterThanOrEqualTo(28));
  });

  test('getVersionMap', () async {
    var channel = 'stable';
    var revision = '44672';

    var content = await _dd.getVersionMap(channel, revision);

    expect(content, {
      'revision': '44672',
      'version': '1.9.1',
      'date': '201503250347'
    });
  });

  test('getLink', () async {
    var channel = 'stable';
    var revision = '44672';

    var content = await _dd.getDownloadLink(
        channel, revision, 'api-docs/dart-api-docs.zip');
    expect(content.pathSegments, [
      'download',
      'storage',
      'v1',
      'b',
      'dart-archive',
      'o',
      'channels/$channel/release/$revision/api-docs/dart-api-docs.zip'
    ]);
  });
}
