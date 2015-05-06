// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shapeshift_common.method_attribute_reporter;

import 'package:doc_coverage/doc_coverage_common.dart';
import 'package:json_diff/json_diff.dart' show DiffNode;

import '../markdown_diff_writer.dart';

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
  final MarkdownDiffWriter io;
  final Function erase;

  String link;
  bool shouldHr;

  MethodAttributesReporter(
      this.category, this.method, this.attributes, this.io, this.erase) {
    link = mdLinkToDartlang(attributes.metadata['qualifiedName'], method);
    shouldHr = false;
  }

  void report() {
    attributes.forEach(reportEach);
    attributes.forEachChanged(reportEachChanged);
    erase(attributes.changed);
  }

  void reportEach(String attributeName, DiffNode attribute) {
    reportRemovedProperties(attributeName, attribute);
    reportAddedProperties(attributeName, attribute);
    reportChangedProperties(attributeName, attribute);

    if (shouldHr) io.writeHr();

    attribute.node.forEach((propertyName, property) {
      reportEachProperty(attributeName, propertyName, property);
    });
  }

  void reportEachChanged(String key, List oldNew) {
    // We don't care about commentFrom changing.
    if (key == 'commentFrom') return;

    io.writeln('The $link $category\'s `${key}` changed:\n');
    if (key == 'return') {
      io.writeWasNow(simpleType(oldNew[0]), simpleType(oldNew[1]));
    } else {
      io.writeWasNow(oldNew[0], oldNew[1], blockquote: key == 'comment');
    }
    io.writeHr();
  }

  void reportRemovedProperties(String attributeName, DiffNode attribute) {
    if (!attribute.hasRemoved) return;

    io.writeln('The $link $category has removed $attributeName:\n');
    shouldHr = true;

    attribute.forEachRemoved(
        (_, property) => io.writeln(propertyListItem(attributeName, property)));

    io.writeln('');
    erase(attribute.removed);
  }

  void reportAddedProperties(String attributeName, DiffNode attribute) {
    if (!attribute.hasAdded) return;

    if (shouldHr) {
      // TODO: get this font-weight up.
      io.writeln('and new $attributeName:\n');
    } else {
      io.writeln('The $link $category has new $attributeName:\n');
    }

    shouldHr = true;

    attribute.forEachAdded(
        (_, property) => io.writeln(propertyListItem(attributeName, property)));

    erase(attribute.added);
  }

  void reportChangedProperties(String attributeName, DiffNode attribute) {
    if (!attribute.hasChanged) return;

    if (shouldHr) {
      // TODO: get this font weight up.
      io.writeln('and changed $attributeName:\n');
    } else {
      io.writeln('The $link $category has changed $attributeName:\n');
    }

    shouldHr = true;

    attribute.forEachChanged((_, property) {
      if (attributeName == 'annotations') {
        io.writeln(
            '* ${formattedAnnotation(property[0])} is now ${formattedAnnotation(property[1])}.');
      } else {
        io.writeln('* `${property[0]}` is now `${property[1]}`.');
      }
    });

    erase(attribute.changed);
  }

  String propertyListItem(String attributeName, Map property) {
    if (attributeName == 'annotations') {
      return '* ${formattedAnnotation(property)}';
    }

    if (attributeName == 'parameters') {
      return '* `${parameterSignature(property)}`';
    }

    return '* `$property`';
  }

  void reportEachProperty(
      String attributeName, String propertyName, DiffNode property) {
    String methodQualifiedName = attributes.metadata['qualifiedName'];
    String methodLink = mdLinkToDartlang(methodQualifiedName, method);
    String propertyLink =
        mdLinkToDartlang('$methodQualifiedName,$propertyName', propertyName);
    String firstPart =
        'The $methodLink $category\'s $propertyLink ${singularize(attributeName)}\'s';
    property.forEachChanged((key, oldNew) {
      if (key == 'type') {
        io.writeln('$firstPart $key ${changedType(oldNew)}');
      } else {
        io.writeln(
            '$firstPart changed from `$key: ${oldNew[0]}` to `$key: ${oldNew[1]}`');
      }
      io.writeHr();
    });
    erase(property.changed);

    if (property.containsKey('type')) {
      String key = 'type';
      List<String> oldNew = property[key]['0'].changed['outer'];
      // This is so ugly because we are so deep, but an example would be:
      // The foo method's value parameter's type has changed from int to bool.
      io.writeln('The [$method](#) $category\'s [$propertyName](#) '
          '${singularize(attributeName)}\'s $key has changed from '
          '`${oldNew[0]}` to `${oldNew[1]}`');
      io.writeHr();
      erase(property.node, 'type');
    }

    if (property.containsKey('functionDeclaration')) {
      DiffNode declaration = property.node['functionDeclaration'];
      if (declaration.changed.containsKey('return')) {
        List<List<Map>> oldNew = declaration.changed['return'];
        // This is so ugly because we are so deep, but an example would be:
        // The foo method's callback parameter's return type has changed from
        // Object to String.
        io.writeln('The [$method](#) $category\'s [$propertyName](#) '
            '${singularize(attributeName)}\'s return type ${changedType(oldNew)}');
        io.writeHr();
        erase(declaration.changed, 'return');
      }
    }
  }
}

String changedType(List<List> oldNew) {
  String oldType = simpleType(oldNew[0]);
  String newType = simpleType(oldNew[1]);
  return 'changed from `$oldType` to `$newType`';
}
