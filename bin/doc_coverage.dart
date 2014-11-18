// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

import 'dart:io';

import 'package:shapeshift/doc_coverage_cli.dart';
import 'package:args/args.dart';

class DocCoverage {
  ArgResults args;
  
  void go(List<String> arguments) {
    parseArgs(arguments);
    if (args.rest.length == 0) {
      print("Error! Supply subdirectory to search in.");
      exit(1);
    }
    String x = args.rest[0];
    String path = "${args['base']}/$x";
    if (args['subset'].isNotEmpty) {
      path += "/${args['subset']}";
    }
    new DocCoverageReporter(path, out: args['out'])
        ..calculateAllCoverage()..report();
  }
  
  void parseArgs(List<String> arguments) {
    var parser = new ArgParser();
    parser.addOption('base', defaultsTo: '/Users/srawlins/code/dartlang.org/api-docs');
    parser.addOption('subset', defaultsTo: '');
    parser.addOption('out');
    args = parser.parse(arguments);
  }
}

void main(List<String> arguments) => new DocCoverage().go(arguments);