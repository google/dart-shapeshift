Shapeshift
==========

Understand how the shape of your Dart package is shifting.

Execute shapeshift against two versions of your Dart docgen-generated API to
expose how your API has changed. Shapeshift generates a set of markdown files
that list API differences in your Dart package.

(The Shapeshift repository also contains the Dart doc coverage tool, documented
in [it's own README](COVERAGE_README.md).)

Basic example
-------------

Assuming you have two versions of your docgen-generated docs at:

```bash
/Code/my_package/docs/docs-v1.6.0/
/Code/my_package/docs/docs-v1.7.0/
```

Then you can run the following command to generate reports of the API
differences.

```bash
shapeshift \
    --base=/Code/my_package/docs \
    --out=./diff-1.6.0_1.7.0 \
    docs-v1.6.0 docs-v1.7.0
```

In this command, `--base` specifies the directory where your two documentation
directories live. `--out` specifies a new or existing directory where you want
the output markdown files to be written. The final two arguments are the
directory with the _old_ and the directory with the _new_ documentation.

Options
-------

The shapeshift Dart script accepts the following options:

* `--base` is the file path that the two directories (old and new) have in
  common.
* `--out` is an optional directory where the API changes can be written to.
  Shapeshift will write a separate Markdown file for each library it finds.
  Each Markdown file will include changes for all member classes of a library.
  If `--out` is not used, the differences, still in Markdown format, will be
  printed to stdout.

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
