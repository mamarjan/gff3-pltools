module util.join_lines;

import std.array;

/**
 * Joins a range of strings or char arrays into one string with delim between them.
 */
string join_lines(T)(T range) {
  return join(range, "\n");
}

unittest {
  alias string[] string_array;
  assert((new string[0]).join_lines == "");
  assert(["abc"].join_lines == "abc");
  assert(["abc", "def"].join_lines == "abc\ndef");
  assert(["abc", "def", "ghi"].join_lines == "abc\ndef\nghi");
}

