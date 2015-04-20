// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

library shapeshift_common.variables_reporter;

import 'package:doc_coverage/doc_coverage_common.dart';
import 'package:json_diff/json_diff.dart' show DiffNode;

import '../markdown_diff_writer.dart';

class VariablesReporter {
  final String variableListPlural, variableList;
  final DiffNode variables;
  final MarkdownDiffWriter io;
  final Function erase;

  VariablesReporter(_variableListPlural, this.variables, this.io, this.erase)
      : this.variableListPlural = _variableListPlural,
        this.variableList = singularize(_variableListPlural);

  void report() {
    if (variables.hasAdded) {
      io.writeln('New $variableListPlural:\n');
      io.writeCodeblockHr(
          variables.added.values.map(variableSignature).join('\n\n'));
    }
    erase(variables.added);

    if (variables.hasRemoved) {
      io.writeln('Removed $variableListPlural:\n');
      io.writeCodeblockHr(
          variables.removed.values.map(variableSignature).join('\n\n'));
    }
    erase(variables.removed);

    if (variables.hasChanged) {
      variables.forEachChanged((k, v) {
        print('TODO: CHANGED: $k, $v');
      });
    }

    variables.forEach(reportEachVariable);
  }

  void reportEachVariable(String name, DiffNode variable) {
    if (!variable.metadata.containsKey('qualifiedName')) {
      // Magically renamed (I suspect docgen).
      if (variable.changed.containsKey('qualifiedName')) {
        var oldNew = variable.changed['qualifiedName'];
        io.writeBad(
            'The `$name` variable\'s qualifiedName changed from ${oldNew[0]} to ${oldNew[1]}');
      } else {
        io.writeBad('TODO: WHAT?');
      }
      return;
    }

    var link = mdLinkToDartlang(variable.metadata['qualifiedName'], name);
    if (variable.hasChanged) {
      variable.forEachChanged((attribute, value) =>
          reportChangedAttributes(attribute, value, link));
    }
    erase(variable.changed);

    if (variable.node.isNotEmpty) variable.node.forEach(
        (String attributeName, DiffNode attribute) =>
            reportDeepChange(name, variable, link, attributeName, attribute));
  }

  void reportChangedAttributes(String attribute, List value, String link) {
    io.writeln('The $link $variableList\'s `$attribute` changed:\n');
    if (attribute == 'type') {
      io.writeWasNow(simpleType(value[0]), simpleType(value[1]), link: true);
    } else {
      io.writeWasNow(value[0], value[1], blockquote: attribute == 'comment');
    }
    io.writeHr();
  }

  void reportDeepChange(String name, DiffNode variable, String link,
      String attributeName, DiffNode attribute) {
    if (attributeName == 'annotations') {
      if (attribute.hasAdded) {
        io.writeln('The $link $variableList has new annotations:\n');
        attribute.added.forEach((_, property) =>
            io.writeln(propertyListItem('annotations', property)));
      }
      erase(variables.added);
      if (attribute.hasChanged) {
        io.writeln('The $link $variableList\'s annotations have changed:\n');
        attribute.forEachChanged((String idx, List<Object> ann) {
          io.writeWasNow(
              formattedAnnotation(ann[0]), formattedAnnotation(ann[1]));
        });
      }
      erase(attribute.changed);
      io.writeHr();
    } else {
      io.writeBad(
          'TODO: The [$name](#) $variableList\'s `$attributeName` has changed:\n',
          attribute.toString(pretty: false));
    }
  }

  // TODO: yanked from method_attributes_reporter; these need a superclass!
  String propertyListItem(String attributeName, Map property) {
    if (attributeName ==
        'annotations') return '* ${formattedAnnotation(property)}';

    if (attributeName ==
        'parameters') return '* `${parameterSignature(property)}`';

    return '* `$property`';
  }
}

void reportVariables(
    DiffNode diff, String variableList, MarkdownWriter io, Function erase) {
  if (!diff.containsKey(variableList)) return;

  new VariablesReporter(variableList, diff[variableList], io, erase).report();
}
