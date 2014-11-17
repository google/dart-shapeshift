part of shapeshift_common;

String pluralize(String s) {
  if (s=='annotations') { return s; }
  if (s.endsWith('s')) { return s+'es'; }
  return s+'s';
}

String pretty(Object json) {
  return new JsonEncoder.withIndent('  ').convert(json);
}

String singularize(String s) {
  if (s=='return') { return s; }
  // Remove trailing character. Presumably an 's'.
  return s.substring(0, s.length-1);
}