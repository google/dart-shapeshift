Shapeshift
==========

Understand how the shape of your package is shifting.

Execute shapeshift against two versions of your docgen-generated API to expose
how your API has changed. Shapeshift generates a set of markdown files that
list API differences in your package.

Basic example
-------------

Assuming you have two versions of your docgen-generated docs at:

```bash
/Users/me/code/my_package/api_docs/docs-v1.6.0
/Users/me/code/my_package/api_docs/docs-v1.7.0
```

Then you can run the following command to generate reports of the API
differences.

```bash
shapeshift \
    --base=/Users/me/code/my_package/api_docs \
    --out=./diff-1.6.0_1.7.0 \
    docs-v1.6.0 docs-v1.7.0
```

In this command, `--base` specifies the directory where your two documentation
directories live. `--out` specifies a new or existing directory where you want
the output markdown files to be written. The final two arguments are the
directories with the old and the new documentation.

Contributing
------------

Contributions welcome! Please read the
[contribution guidelines](CONTRIBUTING.md).

Disclaimer
----------

This is not an official Google product.
