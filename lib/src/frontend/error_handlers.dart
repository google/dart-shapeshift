// Copyright 2015 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.

part of doc_coverage_frontend;

handleError(ProgressEvent error, HtmlElement el, { String name: 'That library' }) {
  var target = error.currentTarget;
  el.innerHtml = '';
  if (target.status == 404) {
    ParagraphElement p = new ParagraphElement()
      ..text ='$name could not be found. Did you misspell it?';
    el.append(p);
  }
  el.append(new DivElement()
      ..classes.add('error')
      ..text = 'Error from ${target.responseUrl}: ${target.status} ${target.statusText}'
  );
}