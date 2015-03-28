// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_common;

class ClassReporter {
  static bool hideInherited = true;
  static bool shouldErase = true;
  static Function identityFormatter = (e, {link: null}) => e;

  final DiffNode diff;
  final MarkdownWriter io;

  String name, qualifiedName;

  ClassReporter(this.diff, this.io) {
    name = diff.metadata['name'];
    qualifiedName = diff.metadata['qualifiedName'];
  }

  void report() {
    if (diff == null)
      return;

    // TODO: also Errors and Typedefs?
    io.bufferH2(
        'class ${mdLinkToDartlang(qualifiedName, name)}');
    reportClass();

    // After reporting, prune and print anything remaining.
    diff.prune();
    diff.metadata.clear();
    String ds = diff.toString();
    if (ds.isNotEmpty) {
      print('$qualifiedName HAS UNRESOLVED NODES:');
      print(ds);
    }
  }

  void reportClass() {
    if (diff.containsKey('annotations'))
      _reportList('annotations', formatter: formattedAnnotation);

    _reportImmediateChanges();

    if (diff.containsKey('subclass'))
      _reportList('subclass', formatter: classFormatter);

    _reportImplements();

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

  void _reportImmediateChanges() {
    if (!diff.hasChanged)
      return;

    diff.forEachChanged((String key, List oldNew) {
      io.writeln("$name's `${key}` changed:\n");
      io.writeWasNow(oldNew[0], oldNew[1],
          blockquote: key == 'comment', link: ['superclass'].contains(key));
      io.writeHr();
    });
    diff.changed.clear();
  }

  void _reportImplements() {
    if (!diff.containsKey('implements'))
      return;

    DiffNode implements = diff['implements'];
    if (implements.hasAdded) {
      String added = implements.added.values.map(mdLinkToDartlang).join(', ');
      io.writeln("$name now implements ${added}.");
      erase(implements.added);
    }
    if (implements.hasRemoved) {
      String removed =
          implements.removed.values.map(mdLinkToDartlang).join(', ');
      io.writeln("$name no longer implements ${removed}.");
      erase(implements.removed);
    }
    io.writeHr();
  }

  void _reportEachMethodCategory(String methodCategory, DiffNode diff) =>
      new MethodsReporter(methodCategory, diff, io, erase).report();

  void _reportList(String key, {Function formatter: null}) {
    if (formatter == null)
      formatter = identityFormatter;

    if (diff[key].hasAdded) {
      io.writeln('$name has new ${pluralize(key)}:\n');
      diff[key].forEachAdded((String idx, Object el) {
        el = formatter(el, link: true);
        io.writeln('* $el');
      });
      io.writeHr();
      erase(diff[key].added);
    }

    if (diff[key].hasRemoved) {
      io.writeln('$name no longer has these ${pluralize(key)}:\n');
      diff[key].forEachRemoved((String idx, Object el) {
        el = formatter(el, link: false);
        io.writeln('* $el');
      });
      io.writeHr();
      erase(diff[key].removed);
    }

    if (diff[key].hasChanged) {
      io.writeln('$name has changed ${pluralize(key)}:\n');
      diff[key].forEachChanged((String idx, List oldNew) {
        var theOld = oldNew[0];
        var theNew = oldNew[1];
        theOld = formatter(theOld, link: false);
        theNew = formatter(theNew, link: false);
        io.writeln('* $theOld is now $theNew.');
      });
      io.writeHr();
      erase(diff[key].changed);
    }
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