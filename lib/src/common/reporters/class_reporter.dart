// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_common;

class ClassReporter {
  static bool hideInherited = true;
  static bool shouldErase = true;
  static Function identityFormatter = (e, {link: null}) => e;

  final DiffNode diff;
  final MarkdownWriter io;

  ClassReporter(this.diff, this.io);

  void report() {
    if (diff == null)
      return;

    // TODO: also Errors and Typedefs?
    io.bufferH2(
        'class ${mdLinkToDartlang(diff.metadata['qualifiedName'], diff.metadata['name'])}');
    reportClass();

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

  void _reportList(String owner, String key, DiffNode diff,
                   {Function formatter: null}) {
    if (formatter == null)
      formatter = identityFormatter;

    if (diff[key].hasAdded) {
      io.writeln('$owner has new ${pluralize(key)}:\n');
      diff[key].forEachAdded((String idx, Object el) {
        el = formatter(el, link: true);
        io.writeln('* $el');
      });
      io.writeHr();
      erase(diff[key].added);
    }

    if (diff[key].hasRemoved) {
      io.writeln('$owner no longer has these ${pluralize(key)}:\n');
      diff[key].forEachRemoved((String idx, Object el) {
        el = formatter(el, link: false);
        io.writeln('* $el');
      });
      io.writeHr();
      erase(diff[key].removed);
    }

    if (diff[key].hasChanged) {
      io.writeln('$owner has changed ${pluralize(key)}:\n');
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