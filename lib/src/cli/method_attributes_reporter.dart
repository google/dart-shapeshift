// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_cli;

class MethodAttributesReporter {
  final String category;
  final String method;
  final DiffNode attributes;
  final FileReporter reporter;

  String link;
  bool shouldHr;

  MethodAttributesReporter(this.category, this.method, this.attributes,
      this.reporter) {
    link = mdLinkToDartlang(attributes.metadata['qualifiedName'], method);
    shouldHr = false;
  }

  void report() {
    attributes.forEach(reportEach);
    attributes.forEachChanged(reportEachChanged);
    reporter.erase(attributes.changed);
  }

  void reportEach(String attributeName, DiffNode attribute) {
    if (attribute.hasRemoved) {
      reporter.io.writeln('The $link $category has removed $attributeName:\n');
      shouldHr = true;
      attribute.forEachRemoved((k, v) {
        if (attributeName == 'annotations') {
          reporter.io.writeln('* ${annotationFormatter(v)}');
        } else if (attributeName == 'parameters') {
          reporter.io.writeln('* `${parameterSignature(v as Map)}`');
        } else {
          reporter.io.writeln('* `$v`');
        }
      });
      reporter.io.writeln('');
      reporter.erase(attribute.removed);
    }

    if (attribute.hasAdded) {
      if (shouldHr) {
        // TODO: get this font-weight up.
        reporter.io.writeln('and new $attributeName:\n');
      } else {
        reporter.io.writeln('The $link $category has new $attributeName:\n');
      }
      shouldHr = true;
      attribute.forEachAdded((k, v) {
        if (attributeName == 'annotations') {
          reporter.io.writeln('* ${annotationFormatter(v)}');
        } else if (attributeName == 'parameters') {
          reporter.io.writeln('* `${parameterSignature(v as Map)}`');
        } else {
          reporter.io.writeln('* `$v`');
        }
      });
      reporter.erase(attribute.added);
    }

    if (attribute.hasChanged) {
      if (shouldHr) {
        // TODO: get this font weight up.
        reporter.io.writeln('and changed $attributeName:\n');
      } else {
        reporter.io.writeln('The $link $category has changed $attributeName:\n');
      }
      shouldHr = true;
      attribute.forEachChanged((k, v) {
        if (attributeName == 'annotations') {
          reporter.io.writeln(
              '* ${annotationFormatter(v[0])} is now ${annotationFormatter(v[1])}.');
        } else {
          reporter.io.writeln('* `${v[0]}` is now `${v[1]}`.');
        }
      });
      reporter.erase(attribute.changed);
    }
    if (shouldHr) {
      reporter.io.writeln('\n---\n');
    }

    attribute.node.forEach((attributeAttributeName, attributeAttribute) {
      reportEachMethodAttributeAttribute(
          attributeName, attributeAttributeName, attributeAttribute);
    });
  }

  void reportEachChanged(String key, List oldNew) {
    // We don't care about commentFrom changing.
    if (key == 'commentFrom')
      return;

    reporter.io.writeln('The $link $category\'s `${key}` changed:\n');
    if (key == 'return') {
      reporter.io.writeWasNow(simpleType(oldNew[0]), simpleType(oldNew[1]));
    } else {
      reporter.io.writeWasNow(oldNew[0], oldNew[1],
          blockquote: key == 'comment');
    }
    reporter.io.writeln('\n---\n');
  }

  void reportEachMethodAttributeAttribute(
      String attributeName,
      String attributeAttributeName,
      DiffNode attributeAttribute) {
    String methodQualifiedName = attributes.metadata['qualifiedName'];
    String methodLink = mdLinkToDartlang(methodQualifiedName, method);
    String attrLink = mdLinkToDartlang(
        '$methodQualifiedName,$attributeAttributeName', attributeAttributeName);
    String firstPart =
        'The $methodLink ${category}\'s $attrLink ${singularize(attributeName)}\'s';
    attributeAttribute.forEachChanged((key, oldNew) {
      if (key == 'type') {
        reporter.io.writeln(
            '$firstPart $key changed from `${changedType(oldNew)}`');
      } else {
        reporter.io.writeln(
            '$firstPart changed from `$key: ${oldNew[0]}` to `$key: ${oldNew[1]}`');
      }
      reporter.io.writeln('\n---\n');
    });
    reporter.erase(attributeAttribute.changed);

    if (attributeAttribute.containsKey('type')) {
      String key = 'type';
      List<String> oldNew = attributeAttribute[key]['0'].changed['outer'];
      // This is so ugly because we are so deep, but an example would be:
      // The foo method's value parameter's type has changed from int to bool.
      reporter.io.writeln(
          'The [$method](#) ${category}\'s [${attributeAttributeName}](#) '
          '${singularize(attributeName)}\'s $key has changed from '
          '`${oldNew[0]}` to `${oldNew[1]}`');
      reporter.io.writeln('\n---\n');
      if (reporter.shouldErase) {
        attributeAttribute.node.remove('type');
      }
    }

    if (attributeAttribute.containsKey('functionDeclaration')) {
      DiffNode declaration = attributeAttribute.node['functionDeclaration'];
      if (declaration.changed.containsKey('return')) {
        List<List<Map>> oldNew = declaration.changed['return'];
        // This is so ugly because we are so deep, but an example would be:
        // The foo method's callback parameter's return type has changed from
        // Object to String.
        reporter.io.writeln(
            'The [$method](#) ${category}\'s [${attributeAttributeName}](#) '
            '${singularize(attributeName)}\'s return type has ${changedType(oldNew)}');
        reporter.io.writeln('\n---\n');
        if (reporter.shouldErase) {
          declaration.changed.remove('return');
        }
      }
    }
  }
}

String changedType(List<List> oldNew) {
  String oldType = simpleType(oldNew[0]);
  String newType = simpleType(oldNew[1]);
  return 'changed from `$oldType` to `$newType`';
}