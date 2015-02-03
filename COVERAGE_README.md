Dart doc coverage
=================

For mostly accidental reasons, the
[Shapeshift](https://github.com/google/dart-shapeshift) project grew to include
a [Dart doc coverage tool](http://google.github.io/dart-shapeshift/). That is,
a tool that uses an opinionated metric to score a library's or a class's
"documentation coverage", as a percentage:

* _0%_ means that a library or class has 0 comments on any methods, variables,
  etc.
* _100%_ means that a library or class has a comment for every method,
  variable, etc., and that each comment is formatted properly, according to
  some opinions.

In general, the formatting of comments is expected to follow the
[Guidelines for Dart Doc Comments](https://www.dartlang.org/articles/doc-comment-guidelines/).
Specifically, the Dart doc coverage tool checks the following rules:

Rules
=====

* The following should have a comment: classes, methods, getters, setters,
  operators, constructors, and variables.
* The first paragraph of any comment should be a one-sentence description.
* A method comment should have at least two paragraphs. A variable comment
  can have just one.
* A comment should end with a period.

License
-------

[Apache v2](LICENSE)

Contributing
------------

Contributions welcome! Please read the
[contribution guidelines](CONTRIBUTING.md).

Disclaimer
----------

This is not an official Google product.