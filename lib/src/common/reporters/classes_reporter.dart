// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shapeshift_common.classes_reporter;

import 'package:doc_coverage/doc_coverage_common.dart';
import 'package:json_diff/json_diff.dart';

import '../markdown_diff_writer.dart';

class ClassesReporter {
  final String category;
  final DiffNode diff;
  final String libraryName;
  final MarkdownDiffWriter io;
  final Function erase;

  ClassesReporter(this.category, this.diff, this.libraryName, this.io,
      this.erase);

  void report() {
    reportRemovedClasses();
    reportAddedClasses();
    diff.forEach(reportEachClass);
  }

  void reportRemovedClasses() {
    if (!diff.hasRemoved) return;

    var cat = diff.removed.length == 1 ? category : pluralize(category);
    var names = diff.removed.values.map((klass) => klass['name']).join(', ');
    io.writeln('Removed $cat: $names.');
    io.writeHr();
    erase(diff.removed);
  }

  void reportAddedClasses() {
    if (!diff.hasAdded) return;

    var cat = diff.added.length == 1 ? category : pluralize(category);
    var names = diff.added.values
        .map((klass) => mdLinkToDartlang(klass['qualifiedName'], klass['name']))
        .join(', ');
    io.writeln('New $cat: $names.');
    io.writeHr();
    erase(diff.added);
  }

  void reportEachClass(String klassName, DiffNode klass) {
    String qualifiedName = klass.metadata['qualifiedName'];
    reportAddedClassMembers(qualifiedName, klass);

    if (klass.hasChanged &&
        klass.changed.containsKey('name') &&
        klass.changed.containsKey('qualifiedName')) {
      // A "changed" class thing probably means a class was removed and
      // another was added, at the same index in the class thing list.
      // Awkward.
      var changed = klass.changed;
      String link =
          mdLinkToDartlang(changed['qualifiedName'][1], changed['name'][1]);
      io
        ..writeln('Removed $category: ${changed['name'][0]}.')
        ..writeHr()
        ..writeln('New $category: $link.')
        ..writeHr();
    }

    if (klass.hasChanged) {
      klass.changed.forEach((String key, List oldNew) {
        String name = klass.metadata['name'];
        // If a class's name changed, then "name" won't be in the metadata,
        // so we'll grab it from the changed map.
        // TODO: make this better...
        if (name == null && klass.changed.containsKey('name')) name =
            klass.changed['name'][0];
        if (qualifiedName == null &&
            klass.changed.containsKey('qualifiedName')) qualifiedName =
            klass.changed['qualifiedName'][0];
        qualifiedName = qualifiedName.replaceAll(new RegExp(r'.*\.'), '');
        String classThingLink = mdLinkToDartlang(qualifiedName, qualifiedName);
        io
          ..writeln('${libraryName}\'s $classThingLink $category `$key` changed:\n')
          ..writeWasNow(oldNew[0], oldNew[1],
              blockquote: ['comment', 'preview'].contains(key))
          ..writeHr();
      });
    }
    erase(klass.changed);

    klass.forEachOf('parameters', (String name, DiffNode p) =>
        reportChangedTypedefParameter(qualifiedName, name, p));
  }

  void reportAddedClassMembers(String qualifiedName, DiffNode klass) {
    if (!klass.hasAdded) return;

    klass.added.forEach((String key, dynamic thing) {
      String name = qualifiedName.replaceAll(new RegExp(r'.*\.'), '');
      String classThingLink = mdLinkToDartlang(qualifiedName, name);
      io.writeln(
          '${diff.metadata['name']}\'s $classThingLink $category has a new `$key`:\n');
      if (key == 'preview') io.writeBlockquote(thing);
      else io.writeCodeblockHr(thing);
      io.writeHr();
    });
    erase(klass.added);
  }

  void reportChangedTypedefParameter(
      String qualifiedName, String name, DiffNode parameter) {
    if (!parameter.changed.containsKey('type')) return;

    String oldType = simpleType(parameter.changed['type'][0]);
    String newType = simpleType(parameter.changed['type'][1]);
    // This is so ugly because we are so deep, but an example would be:
    // The foo typedef's value parameter's type has changed from int to bool.
    io.writeln('The [$qualifiedName](#) $category\'s [$name](#) '
        'parameter\'s type has changed from `$oldType` to `$newType`');
    io.writeHr();
    erase(parameter.changed, 'type');
  }
}
