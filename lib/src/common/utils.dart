// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of shapeshift_common;

/// Pluralizes a String based on crazy simple rules.
///
/// Don't expect too much. It's very simple. It takes care of a few special
/// cases; see some examples:
///
///     pluralize("parameter") // -> "parameters"
///     pluralize("class") // -> "classes"
///     pluralize("annotations") // -> "annotations"
String pluralize(String s) {
  if (s == 'annotations') {
    return s;
  }
  if (s.endsWith('s')) {
    return s + 'es';
  }
  return s + 's';
}

/// Encodes a json object with JsonEncoder using '  ' as an indent.
String pretty(Object json) {
  return new JsonEncoder.withIndent('  ').convert(json);
}

String singularize(String s) {
  if (s == 'return') {
    return s;
  }
  // Remove trailing character. Presumably an 's'.
  return s.substring(0, s.length - 1);
}

String classFormatter(String c, {bool link: true}) {
  return link ? mdLinkToDartlang(c) : decoratedName(c);
}

String annotationFormatter(Map ann, {bool backticks: true, bool link: false}) {
  String result = '@' + (ann['name'] as String).split('.').last;
  if (ann.containsKey('parameters')) {
    result += '(${ann['parameters'].join(', ')})';
  }

  if (backticks)
    return '`$result`';
  else
    return result;
}

// TODO: just steal this from dartdoc-viewer
String parameterSignature(Map<String, Object> parameter) {
  String type = simpleType(parameter['type']);
  String signature = "$type ${parameter['name']}";
  bool optional = parameter.containsKey('optional') && parameter['optional'];
  bool named = parameter.containsKey('named') && parameter['named'];
  bool defaultt = parameter.containsKey('default') && parameter['default'];
  if (optional) {
    String def = '';
    if (named) {
      if (defaultt) {
        def = ': ${parameter['value']}';
      }
      signature = '{$signature$def}';
    } else {
      if (defaultt) {
        def = ' = ${parameter['value']}';
      }
      signature = '[$signature$def]';
    }
  }
  return signature;
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

String simpleType(List<Map> type) {
  if (type == null)
    return null;

  String innerTypeBrackets(List types) =>
      types.isEmpty ? '' : '<${simpleType(types)}>';

  return type
      .map((Map<String, Object> ty) =>
          decoratedName(ty['outer']) + innerTypeBrackets(ty['inner']))
      .join(',');
}