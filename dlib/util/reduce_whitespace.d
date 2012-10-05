module util.reduce_whitespace;

import std.string, std.array, std.ascii;

/**
 * Reduces all grouped whitespace characters to single space character.
 */
string reduce_whitespace(string data) {
  Appender!string app;

  foreach(i, c; data) {
    if (c.isWhite())
      if ((i == 0) || (data[i-1].isWhite()))
        continue;
      else
        app.put(' ');
    else
      app.put(c);
  }

  return app.data.stripRight();
}

unittest {
  assert(reduce_whitespace("  aa  bb\t  c   ") == "aa bb c");
  assert(reduce_whitespace("  (aa  bb  )   c   ") == "(aa bb ) c");
  assert(reduce_whitespace("  (aa +\n  bb  )   c   ") == "(aa + bb ) c");
  assert(reduce_whitespace("  (aa +\n  bb  )\t  c  \n ") == "(aa + bb ) c");
}

