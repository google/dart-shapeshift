part of doc_coverage_cli;

class DocCoverageReporter {
  final String path, out;
  final Map<String,Map> gaps = new Map();
  MarkdownWriter io;

  DocCoverageReporter(this.path, { this.out });
  
  void calculateAllCoverage() {
    //gaps['docgen/dart-async.Stream.json'] = new FileDocCoverage().calculateCoverage(path, 'docgen/dart-async.Stream.json');
    
    List<FileSystemEntity> rawLs = new Directory(path).listSync(recursive: true);
    List<String> ls = rawLs
        .where((FileSystemEntity f) => f is File)
        .map((File f) => f.path)
        .toList();

    int i = 0;
    ls.forEach((String file) {
      i += 1;
      if (i < 1200) {
        file = file.replaceFirst(path, '');
        if (file == '/docgen/index.json' || file == '/docgen/library_list.json' || !file.endsWith('.json')) {
          print('Skipping $file');
          return;
        }
        print('$i: inspecting $file');
        File f = new File('$path/$file');
        String apiString = f.readAsStringSync();
        Map y = new DocCoverage().calculateCoverage(apiString);
        if (y.isNotEmpty) { gaps[file] = y; }
      }
    });
  }

  void report() {
    print('\n');
    print('Top Ten:');
    List<Map> sortedGaps = gaps.values.toList();
    // Skip dom- classes.
    sortedGaps = sortedGaps.where((gap) => !(gap['qualifiedName'] as String).contains('-dom-')).toList();
    sortedGaps..sort((a, b) => b['gapCount'] - a['gapCount']);
    sortedGaps.getRange(0, 10).forEach(
        (gap) => print('${gap['qualifiedName']} has ${gap['gapCount']} gaps.'));
    int moreThan10 = sortedGaps.where((gap) => gap['gapCount'] >= 10).length;
    print('\nThere are $moreThan10 classes with >= 10 gaps.\n');

    Map<String,PackageDocSdk> coverageBySubpackage = new Map();
    gaps.forEach((String file, Map gapsInFile) {
      if ((gapsInFile['qualifiedName'] as String).contains('-dom-')) {
        return;
      }

      if (gapsInFile['packageName'] != null) {
        String subpackage = gapsInFile['packageName'];
        if (!coverageBySubpackage.containsKey(subpackage)) {
          coverageBySubpackage[subpackage] = new PackageDocSdk();
        }
        coverageBySubpackage[subpackage].package = gapsInFile;
      } else {
        String subpackage = getSubpackage(gapsInFile);
        if (!coverageBySubpackage.containsKey(subpackage)) {
          coverageBySubpackage[subpackage] = new PackageDocSdk();
        }
        coverageBySubpackage[subpackage].classes.add(gapsInFile);
      }
    });

    coverageBySubpackage.forEach((String name, PackageDocSdk p) {
      setIo(name);
      if (p.package == null) {
        print('No package for $name???');
      }
      else {
        reportFile(name, p.package);
      }
      p.classes.sort((a, b) => (b['gapCount'] as int) - (a['gapCount'] as int));
      p.classes.forEach((k) => reportFile(name, k));
      io.close();
    });
  }

  void setIo(String packageName) {
    if (out == null) {
      io = new MarkdownWriter(() => stdout);
      return;
    }

    Directory dir = new Directory(out)..createSync(recursive: true);
    io = new MarkdownWriter(() => (new File('$out/$packageName.markdown')..createSync(recursive: true)).openWrite());
    io.writeMetadata(packageName);
  }

  void reportFile(String name, Map cov) {
    if (cov.containsKey('packageName')) {
      io.bufferH1(cov['qualifiedName']);
      
      if (!cov.containsKey('comment') || (cov['comment'] as String).isEmpty) {
        io.writeln('**${mdLinkToDartlang(cov['qualifiedName'])} has no comment!**\n');
      } else if ((cov['comment'] as String).split('\n').length < 2 ) {
        io.writeln('**${mdLinkToDartlang(cov['qualifiedName'])}\'s comment is too short:**\n');
        io.writeBlockquote(cov['comment']);
      }
    }
    else {
      bool any = false;
      String msg = '${cov['qualifiedName']} (${cov['gapCount']}): ';
      ['getters', 'setters', 'constructors', 'methods'].forEach((cat) {
        if (cov[cat].length > 0) {
          msg += '$cat: ${cov[cat].length}, ';
          any = true;
        }
      });
      if (!any) { return; }
      
      int gapCount = cov['gapCount'] as int;
      String gapMsg = gapCount == 1 ? '$gapCount gap point' : '$gapCount gap points';
      io.bufferH2('class ${mdLinkToDartlang(cov['qualifiedName'], cov['name'])} ($gapMsg)');
      
      if (!cov.containsKey('comment') || (cov['comment'] as String).isEmpty) {
        io.writeln('**${mdLinkToDartlang(cov['qualifiedName'])} has no comment!**\n');
        io.writeln('---\n');
      } else if ((cov['comment'] as String).split('\n').length < 2 ) {
        io.writeln('**${mdLinkToDartlang(cov['qualifiedName'])}\'s comment is too short:**\n');
        io.writeBlockquote(cov['comment']);
        io.writeln('---\n');
      }
      
      ['getters', 'setters', 'constructors', 'methods'].forEach((cat) {
        List missing = cov[cat]['missing'];
        List noOneLiner = cov[cat]['no-one-liner'];
        
        if (missing.length > 0) {
          String catMsg = missing.length == 1 ? '${singularize(cat)} is' : '$cat are';
          io.writeln('${missing.length} ${catMsg} missing comments:\n');
          missing.forEach((Map<String,Object> meth) {
            String name = meth['name'] as String;
            if (name.isEmpty) { name = "(default constructor)"; }
            String link = mdLinkToDartlang(meth['qualifiedName'] as String, name);
            io.writeln('* $link\n');
          });
          io.writeln('---\n');
        }
        
        if (noOneLiner.length > 0) {
          String catMsg = noOneLiner.length == 1 ? '${singularize(cat)} has' : '$cat have';
          io.writeln('${noOneLiner.length} ${catMsg} no one-liner (the first line is too long):\n');
          noOneLiner.forEach((Map<String,Object> meth) {
            String name = meth['name'] as String;
            if (name.isEmpty) { name = "(default constructor)"; }
            String link = mdLinkToDartlang(meth['qualifiedName'] as String, name);
            io.writeln('$link:\n');
            io.writeBlockquote(meth['comment']);
          });
          io.writeln('---\n');
        }
      });
    }
  }

  String getSubpackage(Map cov) {
    return (cov['qualifiedName']).split('.')[0];
  }
}

String singularize(String s) {
  if (s=='return') { return s; }
  // Remove trailing character. Presumably an 's'.
  return s.substring(0, s.length-1);
}

class PackageDocSdk {
  final List<Map> classes = new List();
  Map package;
}