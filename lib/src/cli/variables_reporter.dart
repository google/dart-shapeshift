// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_cli;

class VariablesReporter {
  final String variableListPlural, variableList;
  final DiffNode variables;
  final MarkdownWriter io;
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

    if (variable.node.isNotEmpty) {
      variable.node.forEach((attribute, dn) {
        if (attribute == 'annotations') {
          io.writeln(
              'The $link $variableList\'s annotations have changed:\n');
          dn.forEachChanged((String idx, List<Object> annotation) {
            io.writeWasNow(annotationFormatter(annotation[0]),
                annotationFormatter(annotation[1]));
          });
          io.writeHr();
        } else {
          io.writeBad(
              'TODO: The [$name](#) $variableList\'s `$attribute` has changed:\n',
              dn.toString(pretty: false));
        }
      });
    }
    erase(variable.node);
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
}

void reportVariables(DiffNode diff, String variableList, MarkdownWriter io, Function erase) {
  if (!diff.containsKey(variableList))
    return;

  new VariablesReporter(variableList, diff[variableList], io, erase).report();
}