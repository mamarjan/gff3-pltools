module util.equals_ci;

import std.ascii;

/**
 * Case insensitive comparison of two strings. Returns true if
 * strings are equal.
 */
bool equals_ci(string a, string b) {
  bool equal = true;
  if (a.length == b.length) {
    foreach(i, c; a)
      if (toLower(c) != toLower(b[i]))
        equal = false;
  } else {
    equal = false;
  }
  return equal;
}

unittest {
  assert(equals_ci("", "") == true);
  assert(equals_ci("abc", "abc") == true);
  assert(equals_ci("abc", "ABC") == true);
  assert(equals_ci("abc", "Abc") == true);
  assert(equals_ci("aBc", "AbC") == true);
  assert(equals_ci("ABc", "AbC") == true);
  assert(equals_ci("ABC", "ABC") == true);
  assert(equals_ci("abc def", "ABC DEF") == true);
  assert(equals_ci("abc def \n", "ABC DEF \n") == true);

  assert(equals_ci("", "a") == false);
  assert(equals_ci("a", "") == false);
  assert(equals_ci("a", "ab") == false);
  assert(equals_ci("a", "aB") == false);
  assert(equals_ci("a", "AB") == false);
  assert(equals_ci("abc", "abd") == false);
  assert(equals_ci("abc", "ABD") == false);
  assert(equals_ci("abc def", "abc ghi") == false);
}

