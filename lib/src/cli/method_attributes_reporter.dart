// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_cli;

/// Reporter for changes in a method's attributes.
///
/// This reporter can iterate over attributes with their own added, deleted, or
/// changed properties, and iterate over shallow attributes (such as `return`)
/// to list changes.
///
/// Definitions that might help:
///
/// * There are 5 method categories: constructor, method, getter, setter, and
///   operator.
/// * Each method has attributes, such as "parameters" and "annotations"
/// * Each method attribute, or member thereof, might have properties.
///   E.g. Each member of the "parameters" attribute (each parameter) has
///   properties such as "name", and "type".
///
/// It is unexpected to find any new or removed attributes themselves (a method
/// should never be missing the "parameters" attribute, or suddenly gain the
/// "annotations" attribute).
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
    reportRemovedProperties(attributeName, attribute);
    reportAddedProperties(attributeName, attribute);
    reportChangedProperties(attributeName, attribute);

    if (shouldHr)
      reporter.io.writeHr();

    attribute.node.forEach((propertyName, property) {
      reportEachProperty(
          attributeName, propertyName, property);
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
    reporter.io.writeHr();
  }

  void reportRemovedProperties(String attributeName, DiffNode attribute) {
    if (!attribute.hasRemoved)
      return;

    reporter.io.writeln('The $link $category has removed $attributeName:\n');
    shouldHr = true;

    attribute.forEachRemoved((_, property) =>
        reporter.io.writeln(propertyListItem(attributeName, property)));

    reporter.io.writeln('');
    reporter.erase(attribute.removed);
  }

  void reportAddedProperties(String attributeName, DiffNode attribute) {
    if (!attribute.hasAdded)
      return;

    if (shouldHr) {
      // TODO: get this font-weight up.
      reporter.io.writeln('and new $attributeName:\n');
    } else {
      reporter.io.writeln('The $link $category has new $attributeName:\n');
    }

    shouldHr = true;

    attribute.forEachAdded((_, property) =>
      reporter.io.writeln(propertyListItem(attributeName, property)));

    reporter.erase(attribute.added);
  }

  void reportChangedProperties(String attributeName, DiffNode attribute) {
    if (!attribute.hasChanged)
      return;

    if (shouldHr) {
      // TODO: get this font weight up.
      reporter.io.writeln('and changed $attributeName:\n');
    } else {
      reporter.io.writeln('The $link $category has changed $attributeName:\n');
    }

    shouldHr = true;

    attribute.forEachChanged((_, property) {
      if (attributeName == 'annotations') {
        reporter.io.writeln(
            '* ${annotationFormatter(property[0])} is now ${annotationFormatter(property[1])}.');
      } else {
        reporter.io.writeln('* `${property[0]}` is now `${property[1]}`.');
      }
    });

    reporter.erase(attribute.changed);
  }

  String propertyListItem(String attributeName, Map property) {
    if (attributeName == 'annotations')
      return '* ${annotationFormatter(property)}';

    if (attributeName == 'parameters')
      return '* `${parameterSignature(property)}`';

    return '* `$property`';
  }

  void reportEachProperty(String attributeName,
                          String propertyName,
                          DiffNode property) {
    String methodQualifiedName = attributes.metadata['qualifiedName'];
    String methodLink = mdLinkToDartlang(methodQualifiedName, method);
    String propertyLink = mdLinkToDartlang(
        '$methodQualifiedName,$propertyName', propertyName);
    String firstPart =
        'The $methodLink ${category}\'s $propertyLink ${singularize(attributeName)}\'s';
    property.forEachChanged((key, oldNew) {
      if (key == 'type') {
        reporter.io.writeln(
            '$firstPart $key changed from `${changedType(oldNew)}`');
      } else {
        reporter.io.writeln(
            '$firstPart changed from `$key: ${oldNew[0]}` to `$key: ${oldNew[1]}`');
      }
      reporter.io.writeHr();
    });
    reporter.erase(property.changed);

    if (property.containsKey('type')) {
      String key = 'type';
      List<String> oldNew = property[key]['0'].changed['outer'];
      // This is so ugly because we are so deep, but an example would be:
      // The foo method's value parameter's type has changed from int to bool.
      reporter.io.writeln(
          'The [$method](#) ${category}\'s [${propertyName}](#) '
          '${singularize(attributeName)}\'s $key has changed from '
          '`${oldNew[0]}` to `${oldNew[1]}`');
      reporter.io.writeHr();

      if (reporter.shouldErase)
        property.node.remove('type');
    }

    if (property.containsKey('functionDeclaration')) {
      DiffNode declaration = property.node['functionDeclaration'];
      if (declaration.changed.containsKey('return')) {
        List<List<Map>> oldNew = declaration.changed['return'];
        // This is so ugly because we are so deep, but an example would be:
        // The foo method's callback parameter's return type has changed from
        // Object to String.
        reporter.io.writeln(
            'The [$method](#) ${category}\'s [${propertyName}](#) '
            '${singularize(attributeName)}\'s return type has ${changedType(oldNew)}');
        reporter.io.writeHr();
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