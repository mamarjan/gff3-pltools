module util.equals;

import std.ascii;

/**
 * Case insensitive comparison of two strings. Returns true if
 * strings are equal.
 */
bool equals_ci(string a, string b) {
  if (a.length != b.length)
    return false;
  foreach(i, c; a)
    if (toLower(c) != toLower(b[i]))
      return false;
  return true;
}

