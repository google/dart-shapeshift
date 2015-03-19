// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_cli;

class PackageReporter {
  final Map<String, DiffNode> diff = new Map<String, DiffNode>();
  final String leftPath, rightPath, out;
  MarkdownWriter io;

  PackageReporter(this.leftPath, this.rightPath, {this.out});

  void calculateDiff(String fileName) {
    File leftFile = new File(p.join(leftPath, fileName));
    File rightFile = new File(p.join(rightPath, fileName));
    if (!leftFile.existsSync()) {
      print(
          '$leftFile doesn\'t exist, which should be caught in the package json.');
      return;
    }
    JsonDiffer differ = new JsonDiffer(
        leftFile.readAsStringSync(), rightFile.readAsStringSync());
    differ.atomics
      ..add('type')
      ..add('return')
      ..add('annotations[]');
    differ.metadataToKeep..add('qualifiedName');
    differ.ensureIdentical(['name', 'qualifiedName']);
    diff[fileName] = differ.diff()
      ..metadata['qualifiedName'] = differ.leftJson['qualifiedName']
      ..metadata['name'] = differ.leftJson['name']
      ..metadata['packageName'] = differ.leftJson['packageName'];
  }

  void calculateAllDiffs() {
    List<FileSystemEntity> rightRawLs =
        new Directory(rightPath).listSync(recursive: true);
    List<String> rightLs = rightRawLs
        .where((FileSystemEntity f) => f is File)
        .map((File f) => f.path)
        .toList();

    rightLs.forEach((String file) {
      file = p.relative(file, from: rightPath);
      if (p.basename(file) == 'index.json' ||
          p.basename(file) == 'library_list.json' ||
          p.extension(file) != '.json') {
        print('Skipping $file');
        return;
      }
      calculateDiff(file);
    });
  }

  void report() {
    Map<String, PackageSdk> diffsBySubpackage = new Map();
    diff.forEach((String file, DiffNode node) {
      if (node.metadata['packageName'] != null) {
        String subpackage = node.metadata['qualifiedName'];
        if (!diffsBySubpackage.containsKey(subpackage)) {
          diffsBySubpackage[subpackage] = new PackageSdk();
        }
        diffsBySubpackage[subpackage].package = node;
      } else {
        String subpackage = getSubpackage(node);
        if (!diffsBySubpackage.containsKey(subpackage)) {
          diffsBySubpackage[subpackage] = new PackageSdk();
        }
        diffsBySubpackage[subpackage].classes.add(node);
      }
    });

    diffsBySubpackage.forEach((String name, PackageSdk p) {
      setIo(name);
      reportFile(name, p.package);
      p.classes.forEach((k) => reportFile(name, k));
      io.close();
    });
  }

  void setIo(String packageName) {
    if (out == null) {
      io = new MarkdownWriter(() => stdout);
      return;
    }

    new Directory(out).createSync(recursive: true);
    io = new MarkdownWriter(() => (new File('$out/$packageName.markdown')
      ..createSync(recursive: true)).openWrite());
    io.writeMetadata(packageName);
  }

  void reportFile(String name, DiffNode d) {
    new FileReporter(name, d, io: io).report();
  }

  String getSubpackage(DiffNode node) {
    return (node.metadata['qualifiedName']).split('.')[0];
  }
}

class FileReporter {
  final String fileName;
  final DiffNode diff;
  final MarkdownWriter io;
  final bool shouldErase = true;
  bool hideInherited = true;

  FileReporter(this.fileName, this.diff, {this.io});

  void report() {
    if (diff == null) {
      return;
    }

    if (diff.metadata['packageName'] != null) {
      io.bufferH1(diff.metadata['qualifiedName']);
      reportPackage();
    } else {
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

  void reportPackage() {
    if (diff.changed.containsKey('packageIntro')) {
      io.writeBad(
          'TODO: The <strong>packageIntro</strong> changed, which is probably huge. Not including here yet.',
          '');
      if (shouldErase) {
        diff.changed.remove('packageIntro');
      }
    }

    // iterate over the class categories
    diff.forEachOf('classes', (String classCategory, DiffNode d) {
      reportEachClassThing(classCategory, d);
    });

    diff.changed.forEach((String key, List oldNew) {
      io.writeln("${diff.metadata['name']}'s `${key}` changed:\n");
      io.writeWasNow((oldNew as List<String>)[0], (oldNew as List<String>)[1],
          blockquote: key == 'comment');
      io.writeln('\n---\n');
    });
    diff.changed.clear();

    diff.forEachOf('functions', reportEachMethodThing);
  }

  String annotationFormatter(Map a, {bool backticks: true, bool link: false}) {
    String result = '@' + (a['name'] as String).split('.').last;
    if (a.containsKey('parameters')) {
      result += '(${a['parameters'].join(', ')})';
    }
    if (backticks) {
      return '`$result`';
    } else {
      return result;
    }
  }

  String classFormatter(String c, {bool link: true}) {
    return link ? mdLinkToDartlang(c) : decoratedName(c);
  }

  void reportClass() {
    if (diff.containsKey('annotations')) {
      reportList(diff.metadata['name'], 'annotations', diff,
          formatter: annotationFormatter);
    }

    if (diff.hasChanged) {
      diff.forEachChanged((String key, List oldNew) {
        io.writeln("${diff.metadata['name']}'s `${key}` changed:\n");
        io.writeWasNow((oldNew as List<String>)[0], (oldNew as List<String>)[1],
            blockquote: key == 'comment', link: ['superclass'].contains(key));
        io.writeln('\n---\n');
      });
      diff.changed.clear();
    }

    if (diff.containsKey('subclass')) {
      reportList(diff.metadata['name'], 'subclass', diff,
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
      io.writeln('\n---\n');
    }

    // Iterate over the method categories.
    diff.forEachOf('methods', (String methodCategory, DiffNode d) {
      reportEachMethodThing(methodCategory, d);
    });

    if (hideInherited) {
      diff.forEachOf('inheritedMethods', (String methodCategory, DiffNode d) {
        // TODO: hmm... io.writeln("_Hiding inherited $methodCategory changes._\n\n---\n");
      });
      if (diff.containsKey('inheritedMethods')) {
        if (shouldErase) {
          diff.node.remove('inheritedMethods');
        }
      }
    } else {
      diff.forEachOf('inheritedMethods', (String methodCategory, DiffNode d) {
        reportEachMethodThing(methodCategory, d, parenthetical: 'inherited');
      });
    }

    reportVariables('variables');
    if (hideInherited) {
      if (diff.containsKey('inheritedVariables')) {
        if (shouldErase) {
          diff.node.remove('inheritedVariables');
        }
      }
    } else {
      reportVariables('inheritedVariables');
    }
  }

  void reportVariables(String variableList) {
    if (!diff.containsKey(variableList)) {
      return;
    }
    DiffNode variables = diff[variableList];

    if (variables.hasAdded) {
      io.writeln('New $variableList:\n');
      io.writeCodeblockHr(
          variables.added.values.map(variableSignature).join('\n\n'));
    }
    erase(variables.added);

    if (variables.hasRemoved) {
      io.writeln('Removed $variableList:\n');
      io.writeCodeblockHr(
          variables.removed.values.map(variableSignature).join('\n\n'));
    }
    erase(variables.removed);

    if (variables.hasChanged) {
      variables.forEachChanged((k, v) {
        print('CHANGED: $k, $v');
      });
    }

    variables.forEach((key, variable) {
      if (!variable.metadata.containsKey('qualifiedName')) {
        // Magically renamed (I suspect docgen).
        if (variable.changed.containsKey('qualifiedName')) {
          var oldNew = variable.changed['qualifiedName'];
          io.writeBad(
              'The `$key` variable\'s qualifiedName changed from ${oldNew[0]} to ${oldNew[1]}',
              null);
        } else {
          io.writeBad('TODO: WHAT?', null);
        }
        return;
      }
      var link = mdLinkToDartlang(variable.metadata['qualifiedName'], key);
      if (variable.hasChanged) {
        variable.forEachChanged((attribute, value) {
          io.writeln(
              'The $link ${singularize(variableList)}\'s `$attribute` changed:\n');
          if (attribute == 'type') {
            io.writeWasNow(simpleType(value[0]), simpleType(value[1]),
                link: true);
          } else {
            io.writeWasNow(value[0], value[1],
                blockquote: attribute == 'comment');
          }
          io.writeln('\n---\n');
        });
      }
      erase(variable.changed);

      if (variable.node.isNotEmpty) {
        variable.node.forEach((attribute, dn) {
          if (attribute == 'annotations') {
            io.writeln(
                'The $link ${singularize(variableList)}\'s annotations have changed:\n');
            dn.forEachChanged((String idx, List<Object> annotation) {
              io.writeWasNow(annotationFormatter(annotation[0]),
                  annotationFormatter(annotation[1]));
            });
            io.writeln('\n---\n');
          } else {
            io.writeBad(
                'TODO: The [$key](#) ${singularize(variableList)}\'s `$attribute` has changed:\n',
                dn.toString(pretty: false));
          }
        });
      }
      erase(variable.node);
    });
  }

  void reportList(String owner, String key, DiffNode d, {Function formatter}) {
    if (d[key].hasAdded) {
      io.writeln('$owner has new ${pluralize(key)}:\n');
      d[key].forEachAdded((String idx, Object el) {
        if (formatter != null) {
          el = formatter(el, link: true);
        }
        io.writeln('* $el');
      });
      io.writeln('\n---\n');
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
      io.writeln('\n---\n');
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
      io.writeln('\n---\n');
      erase(d[key].changed);
    }
  }

  String comment(String c) {
    if (c.isEmpty) {
      return '';
    }
    return c.split('\n').map((String x) => '/// $x\n').join('');
  }

  void erase(Map m) {
    if (shouldErase) {
      m.clear();
    }
  }

  void reportEachClassThing(String classCategory, DiffNode d) {
    if (d.hasRemoved) {
      var cat =
          d.removed.length == 1 ? classCategory : pluralize(classCategory);
      var names = d.removed.values.map((klass) => klass['name']).join(', ');
      io.writeln('Removed $cat: $names.');
      io.writeln('\n---\n');
      erase(d.removed);
    }

    if (d.hasAdded) {
      var cat = d.added.length == 1 ? classCategory : pluralize(classCategory);
      var names = d.added.values
          .map((klass) =>
              mdLinkToDartlang(klass['qualifiedName'], klass['name']))
          .join(', ');
      io.writeln('New $cat: $names.');
      io.writeln('\n---\n');
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
          io.writeln('\n---\n');
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
        io.writeln('\n---\n');
        io.writeln('New $classCategory: $newThingLink.');
        io.writeln('\n---\n');
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
          io.writeln('\n---\n');
        });
      }

      erase(classThing.changed);
    });
  }

  void reportEachMethodThing(String methodCategory, DiffNode d,
      {String parenthetical: ""}) {
    String category = singularize(methodCategory);
    if (parenthetical.isNotEmpty) {
      parenthetical = ' _($parenthetical)_';
    }
    d.forEachAdded((methodName, method) {
      io.writeln(
          'New $category$parenthetical ${mdLinkToDartlang(method['qualifiedName'], methodName)}:\n');
      io.writeCodeblockHr(methodSignature(method as Map));
    });
    erase(d.added);

    d.forEachRemoved((methodName, method) {
      if (methodName == '') {
        methodName = diff.metadata['name'];
      }
      io.writeln('Removed $category$parenthetical $methodName:\n');
      io.writeCodeblockHr(methodSignature(method as Map,
          includeComment: false, includeAnnotations: false));
    });
    erase(d.removed);

    d.forEach((method, attributes) {
      reportEachMethodAttribute(category, method, attributes);
    });
  }

  void reportEachMethodAttribute(
      String category, String method, DiffNode attributes) {
    var link = mdLinkToDartlang(attributes.metadata['qualifiedName'], method);
    bool shouldHr = false;
    attributes.forEach((attributeName, attribute) {
      if (attribute.hasRemoved) {
        io.writeln('The $link $category has removed $attributeName:\n');
        shouldHr = true;
        attribute.forEachRemoved((k, v) {
          if (attributeName == 'annotations') {
            io.writeln('* ${annotationFormatter(v)}');
          } else if (attributeName == 'parameters') {
            io.writeln('* `${parameterSignature(v as Map)}`');
          } else {
            io.writeln('* `$v`');
          }
        });
        io.writeln('');
        erase(attribute.removed);
      }

      if (attribute.hasAdded) {
        if (shouldHr) {
          // TODO: get this font-weight up.
          io.writeln('and new $attributeName:\n');
        } else {
          io.writeln('The $link $category has new $attributeName:\n');
        }
        shouldHr = true;
        attribute.forEachAdded((k, v) {
          if (attributeName == 'annotations') {
            io.writeln('* ${annotationFormatter(v)}');
          } else if (attributeName == 'parameters') {
            io.writeln('* `${parameterSignature(v as Map)}`');
          } else {
            io.writeln('* `$v`');
          }
        });
        erase(attribute.added);
      }

      if (attribute.hasChanged) {
        if (shouldHr) {
          // TODO: get this font weight up.
          io.writeln('and changed $attributeName:\n');
        } else {
          io.writeln('The $link $category has changed $attributeName:\n');
        }
        shouldHr = true;
        attribute.forEachChanged((k, v) {
          if (attributeName == 'annotations') {
            io.writeln(
                '* ${annotationFormatter(v[0])} is now ${annotationFormatter(v[1])}.');
          } else {
            io.writeln('* `${v[0]}` is now `${v[1]}`.');
          }
        });
        erase(attribute.changed);
      }
      if (shouldHr) {
        io.writeln('\n---\n');
      }

      attribute.node.forEach((attributeAttributeName, attributeAttribute) {
        reportEachMethodAttributeAttribute(category, method,
            attributes.metadata['qualifiedName'], attributeName,
            attributeAttributeName, attributeAttribute);
      });
    });

    attributes.forEachChanged((String key, List oldNew) {
      if (key == 'commentFrom') {
        return;
      } // We don't care about commentFrom.
      io.writeln('The $link $category\'s `${key}` changed:\n');
      if (key == 'return') {
        io.writeWasNow(simpleType(oldNew[0]), simpleType(oldNew[1]));
      } else {
        io.writeWasNow((oldNew as List<String>)[0], (oldNew as List<String>)[1],
            blockquote: key == 'comment');
      }
      io.writeln('\n---\n');
    });
    erase(attributes.changed);
  }

  void reportEachMethodAttributeAttribute(String category, String method,
      String methodQname, String attributeName, String attributeAttributeName,
      DiffNode attributeAttribute) {
    attributeAttribute.forEachChanged((key, oldNew) {
      var methodLink = mdLinkToDartlang(methodQname, method);
      var attrLink = mdLinkToDartlang(
          '$methodQname,$attributeAttributeName', attributeAttributeName);
      var firstPart =
          'The $methodLink ${category}\'s $attrLink ${singularize(attributeName)}\'s';
      if (key == 'type') {
        io.writeln(
            '$firstPart $key changed from `${simpleType(oldNew[0])}` to `${simpleType(oldNew[1])}`');
      } else {
        io.writeln(
            '$firstPart changed from `$key: ${oldNew[0]}` to `$key: ${oldNew[1]}`');
      }
      io.writeln('\n---\n');
    });
    erase(attributeAttribute.changed);

    if (attributeAttribute.containsKey('type')) {
      String key = 'type';
      List<String> oldNew = attributeAttribute[key]['0'].changed['outer'];
      io.writeln(
          'The [$method](#) ${category}\'s [${attributeAttributeName}](#) ${singularize(attributeName)}\'s $key has changed from `${oldNew[0]}` to `${oldNew[1]}`');
      io.writeln('\n---\n');
      if (shouldErase) {
        attributeAttribute.node.remove('type');
      }
    }
  }

  // TODO: just steal this from dartdoc-viewer
  String methodSignature(Map<String, Object> method,
      {bool includeComment: true, bool includeAnnotations: true}) {
    String name = method['name'];
    String type = simpleType(method['return']);
    if (name == '') {
      name = diff.metadata['name'];
    }
    String s = '$type $name';
    if (includeComment) {
      s = comment(method['comment']) + s;
    }
    if (includeAnnotations) {
      (method['annotations'] as List).forEach((Map annotation) {
        s = annotationFormatter(annotation, backticks: false) + '\n' + s;
      });
    }
    List<String> p = new List<String>();
    (method['parameters'] as Map).forEach((k, v) {
      p.add(parameterSignature(v));
    });
    s = '$s(${p.join(', ')})';
    return s;
  }

  String simpleType(List<Map> t) {
    if (t == null) {
      return null;
    }
    return t
        .map((Map<String, Object> ty) => decoratedName(ty['outer'] as String) +
            ((ty['inner'] as List).isEmpty
                ? ''
                : '<${simpleType(ty['inner'])}>'))
        .join(',');
  }

  // TODO: just steal this from dartdoc-viewer
  String parameterSignature(Map<String, Object> parameter) {
    String type = simpleType(parameter['type']);
    String s = "$type ${parameter['name']}";
    bool optional = parameter.containsKey('optional') && parameter['optional'];
    bool named = parameter.containsKey('named') && parameter['named'];
    bool defaultt = parameter.containsKey('default') && parameter['default'];
    if (optional) {
      String def = '';
      if (named) {
        if (defaultt) {
          def = ': ${parameter['value']}';
        }
        s = '{$s$def}';
      } else {
        if (defaultt) {
          def = ' = ${parameter['value']}';
        }
        s = '[$s$def]';
      }
    }
    return s;
  }

  String variableSignature(Map<String, Object> variable) {
    String type = simpleType(variable['type']);
    String s = '$type ${variable['name']};';
    if (variable['constant']) {
      s = 'const $s';
    }
    if (variable['final']) {
      s = 'final $s';
    }
    if (variable['static']) {
      s = 'static $s';
    }
    (variable['annotations'] as List).forEach((Map annotation) {
      s = annotationFormatter(annotation, backticks: false) + '\n' + s;
    });
    return s;
  }
}

class PackageSdk {
  final List<DiffNode> classes = new List();
  DiffNode package;
}
