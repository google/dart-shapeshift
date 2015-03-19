// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of shapeshift_common;

// A commonized form of dartdoc_viewer's DocsLocation.

// These regular expressions are not strictly accurate for picking Dart
// identifiers out of arbitrary text, e.g. identifiers must start with an
// alphabetic or underscore, this would allow "9a" as a library name. But
// they should be sufficient for extracting them from URLs that were created
// from valid identifiers.

/// A package in one of our URIs is an identifer and ends with a slash
final packageMatch = new RegExp(r'(\w+)/');

/// A library in one of our URIs is an identifier but may contain either
/// ':' or '-' in place of the '.' that is legal in a Dart library name.
final libraryMatch = new RegExp(r'([\w\-\:]+)');

/// A member or sub-member in one of our URI's starts with a '.' and is
/// an identifier.
final memberMatch = new RegExp(r'\.(\w+)');

/// A sub-member can be a normal identifier but can also be an operator.
/// Constructors always contain a "-" and are of the form
/// "className-constructorName" (if constructorName is empty, it will just be
/// "className-".
final subMemberMatch = new RegExp(r'\.([\w\<\+\|\[\]\>\/\^\=\&\*\-\%]+)');

RegExp get anchorMatch {
  var anchorPrefix = ANCHOR_STRING;
  //if (useHistory) anchorPrefix = ANCHOR_PLUS_PREFIX;
  return new RegExp(
      r'\' + anchorPrefix + r'([\w\<\+\|\[\]\>\/\^\=\&\*\-\%\.\,]+)');
}

/// The separator to use between the "anchor" portion of the location, which
/// is shown as part of the larger page, and the main portion. This doesn't
/// necessarily correspond to an HTML anchor, though it may.
const ANCHOR_STRING = "#";

/// This represents a component described by a URI and can give us
/// the URI given the component or vice versa.
class DocsLocation {
  String packageName;
  String libraryName;
  String memberName;
  String subMemberName;
  String anchor;

  DocsLocation(String uri) {
    _extractPieces(uri);
  }

  /// Create the location from the pieces in [uri]. It will accept things
  /// that both do and do not start with our leading string. We also
  /// assume that anything that starts with a leading slash and does not
  /// have our indicator means the home page.
  void _extractPieces(String uri) {
    if (uri == null || uri.length == 0) return;
    var resultUri = uri;
    var position = 0;

    _check(regex) {
      var match = regex.matchAsPrefix(resultUri, position);
      if (match != null) {
        var matchedString = match.group(1);
        position = position + match.group(0).length;
        return matchedString;
      }
    }

    packageName = _check(packageMatch);
    libraryName = _check(libraryMatch);
    memberName = _check(memberMatch);
    subMemberName = _check(subMemberMatch);
    anchor = _check(anchorMatch);
    if (position < resultUri.length && anchor == null) {
      // allow an anchor that's just dotted, not @ if we don't find an @
      // form and we haven't reached the end.
      anchor = resultUri.substring(position + 1, resultUri.length);
    }
  }

  /// Return the last component for which we have a value, not counting
  /// the anchor.
  String get lastName {
    if (anchor != null) return anchor;
    if (subMemberName != null) return subMemberName;
    if (memberName != null) return memberName;
    if (libraryName != null) return libraryName;
    if (packageName != null) return packageName;
    return null;
  }
}
