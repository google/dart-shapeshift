// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_cli;

class FileReporter {
  final String fileName;
  final DiffNode diff;
  final MarkdownWriter io;
  final bool shouldErase = true;
  bool hideInherited = true;

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
    if (!diff.containsKey(variableList))
      return;

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

  void erase(Map m) {
    if (shouldErase)
      m.clear();
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
          io.writeln('\n---\n');
          if (shouldErase) {
            parameter.changed.remove('type');
          }
        });
      }
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
      // This is so ugly because we are so deep, but an example would be:
      // The foo method's value parameter's type has changed from int to bool.
      io.writeln(
          'The [$method](#) ${category}\'s [${attributeAttributeName}](#) '
          '${singularize(attributeName)}\'s $key has changed from '
          '`${oldNew[0]}` to `${oldNew[1]}`');
      io.writeln('\n---\n');
      if (shouldErase) {
        attributeAttribute.node.remove('type');
      }
    }

    // TODO: Clean up? But really I need to start OOing more of this from
    // above. reportEachMethodAttributeAttribute takes 6 args. :/
    if (attributeAttribute.containsKey('functionDeclaration')) {
      DiffNode declaration = attributeAttribute.node['functionDeclaration'];
      if (declaration.changed.containsKey('return')) {
        String key = 'return type';
        List<List<Map>> oldNew = declaration.changed['return'];
        String oldType = simpleType(oldNew[0]);
        String newType = simpleType(oldNew[1]);
        // This is so ugly because we are so deep, but an example would be:
        // The foo method's callback parameter's return type has changed from
        // Object to String.
        io.writeln(
            'The [$method](#) ${category}\'s [${attributeAttributeName}](#) '
            '${singularize(attributeName)}\'s $key has changed from '
            '`$oldType` to `$newType`');
        io.writeln('\n---\n');
        if (shouldErase) {
          declaration.changed.remove('return');
        }
      }
    }
  }
}