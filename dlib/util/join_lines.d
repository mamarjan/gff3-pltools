module util.join_lines;

import std.array;

/**
 * Joins a range of strings or char arrays into lines.
 */
string join_lines(T)(T range) {
  alias typeof(range.front()) ArrayType;

  auto result = appender!(ArrayType)();
  while (!range.empty) {
    result.put(range.front);
    result.put("\n");
    range.popFront();
  }
  return cast(immutable)(result.data);
}


