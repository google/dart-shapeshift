// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_cli;

class FileReporter {
  static bool hideInherited = true;
  static bool shouldErase = true;

  final String fileName;
  final DiffNode diff;
  final MarkdownWriter io;

  FileReporter(this.fileName, this.diff, {this.io});

  void report() {
    if (diff == null)
      return;

    if (diff.metadata['packageName'] != null) {
      // The file I'm reporting on represents a library.
      io.bufferH1(diff.metadata['qualifiedName']);
      reportLibrary();
    } else {
      // The file I'm reporting on represents a "class".
      // TODO: also Errors and Typedefs?
      io.bufferH2(
          'class ${mdLinkToDartlang(diff.metadata['qualifiedName'], diff.metadata['name'])}');
      reportClass();
    }

    // After reporting, prune and print anything remaining.
    diff.prune();
    String qn = diff.metadata['qualifiedName'];
    diff.metadata.clear();
    String ds = diff.toString();
    if (ds.isNotEmpty) {
      print('${qn} HAS UNRESOLVED NODES:');
      print(ds);
    }
  }

  void reportLibrary() {
    if (diff.changed.containsKey('packageIntro')) {
      io.writeBad(
          'TODO: The <strong>packageIntro</strong> changed, which is probably huge. Not including here yet.',
          '');
      erase(diff.changed, 'packageIntro');
    }

    // Iterate over the class categories ('classes', 'typedefs', 'errors').
    diff.forEachOf('classes', (String classCategory, DiffNode d) {
      reportEachClassThing(classCategory, d);
    });

    diff.changed.forEach((String key, List oldNew) {
      io.writeln("${diff.metadata['name']}'s `${key}` changed:\n");
      io.writeWasNow((oldNew as List<String>)[0], (oldNew as List<String>)[1],
          blockquote: key == 'comment');
      io.writeHr();
    });
    diff.changed.clear();

    // TODO: report variables.

    diff.forEachOf('functions', _reportEachMethodCategory);
  }

  void reportClass() {
    if (diff.containsKey('annotations')) {
      _reportList(diff.metadata['name'], 'annotations', diff,
          formatter: annotationFormatter);
    }

    if (diff.hasChanged) {
      diff.forEachChanged((String key, List oldNew) {
        io.writeln("${diff.metadata['name']}'s `${key}` changed:\n");
        io.writeWasNow((oldNew as List<String>)[0], (oldNew as List<String>)[1],
            blockquote: key == 'comment', link: ['superclass'].contains(key));
        io.writeHr();
      });
      diff.changed.clear();
    }

    if (diff.containsKey('subclass')) {
      _reportList(diff.metadata['name'], 'subclass', diff,
          formatter: classFormatter);
    }

    if (diff.containsKey('implements')) {
      DiffNode implements = diff['implements'];
      if (implements.hasAdded) {
        String added = implements.added.values.map(mdLinkToDartlang).join(', ');
        io.writeln("${diff.metadata['name']} now implements ${added}.");
        erase(implements.added);
      }
      if (implements.hasRemoved) {
        String removed =
            implements.removed.values.map(mdLinkToDartlang).join(', ');
        io.writeln("${diff.metadata['name']} no longer implements ${removed}.");
        erase(implements.removed);
      }
      io.writeHr();
    }

    // Iterate over the method categories.
    diff.forEachOf('methods', _reportEachMethodCategory);

    if (hideInherited)
      erase(diff.node, 'inheritedMethods');
    else
      diff.forEachOf('inheritedMethods', _reportEachMethodCategory);

    reportVariables(diff, 'variables', io, erase);
    if (hideInherited)
      erase(diff.node, 'inheritedVariables');
    else
      reportVariables(diff, 'inheritedVariables', io, erase);
  }

  void _reportEachMethodCategory(String methodCategory, DiffNode diff) =>
      new MethodsReporter(methodCategory, diff, io, erase).report();

  void _reportList(String owner, String key, DiffNode d, {Function formatter}) {
    if (d[key].hasAdded) {
      io.writeln('$owner has new ${pluralize(key)}:\n');
      d[key].forEachAdded((String idx, Object el) {
        if (formatter != null) {
          el = formatter(el, link: true);
        }
        io.writeln('* $el');
      });
      io.writeHr();
      erase(d[key].added);
    }

    if (d[key].hasRemoved) {
      io.writeln('$owner no longer has these ${pluralize(key)}:\n');
      d[key].forEachRemoved((String idx, Object el) {
        if (formatter != null) {
          el = formatter(el, link: false);
        }
        io.writeln('* $el');
      });
      io.writeHr();
      erase(d[key].removed);
    }

    if (d[key].hasChanged) {
      io.writeln('$owner has changed ${pluralize(key)}:\n');
      d[key].forEachChanged((String idx, List oldNew) {
        var theOld = oldNew[0];
        var theNew = oldNew[1];
        if (formatter != null) {
          theOld = formatter(theOld, link: false);
          theNew = formatter(theNew, link: false);
        }
        io.writeln('* $theOld is now $theNew.');
      });
      io.writeHr();
      erase(d[key].changed);
    }
  }

  void reportEachClassThing(String classCategory, DiffNode d) {
    if (d.hasRemoved) {
      var cat =
          d.removed.length == 1 ? classCategory : pluralize(classCategory);
      var names = d.removed.values.map((klass) => klass['name']).join(', ');
      io.writeln('Removed $cat: $names.');
      io.writeHr();
      erase(d.removed);
    }

    if (d.hasAdded) {
      var cat = d.added.length == 1 ? classCategory : pluralize(classCategory);
      var names = d.added.values
          .map((klass) =>
              mdLinkToDartlang(klass['qualifiedName'], klass['name']))
          .join(', ');
      io.writeln('New $cat: $names.');
      io.writeHr();
      erase(d.added);
    }

    d.forEach((String classThingName, DiffNode classThing) {
      if (classThing.hasAdded) {
        classThing.added.forEach((String key, dynamic thing) {
          String name = classThing.metadata['qualifiedName'].replaceAll(
              new RegExp(r'.*\.'), '');
          String classThingLink =
              mdLinkToDartlang(classThing.metadata['qualifiedName'], name);
          io.writeln(
              "${diff.metadata['name']}'s $classThingLink $classCategory has a new `$key`:\n");
          if (key == 'preview') {
            io.writeBlockquote(thing);
          } else {
            io.writeCodeblockHr(thing);
          }
          io.writeHr();
        });
      }
      erase(classThing.added);

      if (classThing.hasChanged &&
          classThing.changed.containsKey('name') &&
          classThing.changed.containsKey('qualifiedName')) {
        // A "changed" class thing probably means a class was removed and
        // another was added, at the same index in the class thing list.
        // Awkward.
        var changed = classThing.changed;
        String newThingLink =
            mdLinkToDartlang(changed['qualifiedName'][1], changed['name'][1]);
        io.writeln('Removed $classCategory: ${changed['name'][0]}.');
        io.writeHr();
        io.writeln('New $classCategory: $newThingLink.');
        io.writeHr();
      }

      if (classThing.hasChanged) {
        classThing.changed.forEach((String key, List oldNew) {
          String name = classThing.metadata['name'];
          String qualifiedName = classThing.metadata['qualifiedName'];
          // If a class's name changed, then "name" won't be in the metadata,
          // so we'll grab it from the changed map.
          // TODO: make this better...
          if (name == null) {
            if (classThing.changed.containsKey('name')) {
              name = classThing.changed['name'][0];
            }
          }
          if (qualifiedName == null) {
            if (classThing.changed.containsKey('qualifiedName')) {
              qualifiedName = classThing.changed['qualifiedName'][0];
            }
          }
          qualifiedName = qualifiedName.replaceAll(new RegExp(r'.*\.'), '');
          String classThingLink =
              mdLinkToDartlang(qualifiedName, qualifiedName);
          io.writeln(
              "${name}'s $classThingLink $classCategory `$key` changed:\n");
          io.writeWasNow(
              (oldNew as List<String>)[0], (oldNew as List<String>)[1],
              blockquote: ['comment', 'preview'].contains(key));
          io.writeHr();
        });
      }
      erase(classThing.changed);

      if (classThing.containsKey('parameters')) {
        classThing.forEachOf('parameters', (String name, DiffNode parameter) {
          if (!parameter.changed.containsKey('type'))
            return;

          String key = 'type';
          String oldType = simpleType(parameter.changed[key][0]);
          String newType = simpleType(parameter.changed[key][1]);
          // This is so ugly because we are so deep, but an example would be:
          // The foo typedef's value parameter's type has changed from int to bool.
          io.writeln(
              'The [${classThing.metadata['qualifiedName']}](#) $classCategory\'s [$name](#) '
              'parameter\'s $key has changed from '
              '`$oldType` to `$newType`');
          io.writeHr();
          erase(parameter.changed, 'type');
        });
      }
    });
  }

  void erase(Map m, [String key]) {
    if (!shouldErase)
      return;

    if (key == null)
      m.clear();
    else
      m.remove(key);
  }
}