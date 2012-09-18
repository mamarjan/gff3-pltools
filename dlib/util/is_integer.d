module util.is_integer;

import std.string, std.ascii;

/**
 * Returns true if the string contains a valid integer number.
 */
bool is_integer(T)(T[] data) {
  data = data.strip;

  // Check first for empty string
  if (data.length == 0)
    return false;

  // Check for a sign
  if ((data[0] == '+') || (data[0] == '-'))
    data = data[1..$];

  // Check for integral part
  bool integral_part_present = false;
  while ((data.length > 0) && isDigit(data[0])) {
    integral_part_present = true;
    data = data[1..$];
  }
  if (!integral_part_present)
    return false;

  // At this point nothing should be left 
  return (data.length == 0);
}

import std.stdio;

unittest {
  writeln("Testing is_integer()...");

  assert(is_integer("1") == true);
  assert(is_integer(" 1") == true);
  assert(is_integer("1 ") == true);
  assert(is_integer(" 1 ") == true);
  assert(is_integer("123") == true);
  assert(is_integer("123") == true);
  assert(is_integer("+123") == true);
  assert(is_integer("-123") == true);
  assert(is_integer("\t   -123   \t\n") == true);

  assert(is_integer("") == false);
  assert(is_integer(" ") == false);
  assert(is_integer("-") == false);
  assert(is_integer("+") == false);
  assert(is_integer("a") == false);
  assert(is_integer("\n") == false);
  assert(is_integer("abc") == false);
  assert(is_integer("a123") == false);
  assert(is_integer("a 123") == false);
  assert(is_integer("123a") == false);
  assert(is_integer("123 a") == false);
  assert(is_integer("123a123") == false);
  assert(is_integer("0.01") == false);
  assert(is_integer("1.01") == false);
  assert(is_integer("1.01e2") == false);
  assert(is_integer("1.") == false);
  assert(is_integer("one") == false);
}

