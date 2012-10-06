module util.first_of;

import std.string, std.algorithm;

long first_of(string data, string what) {
  long current_index = -1;
  foreach(c; what) {
    auto index = std.string.indexOf(data, c);
    if (index != -1) {
      if (current_index == -1)
        current_index = index;
      else
        current_index = min(index, current_index);
    }
  }
  
  return current_index;
}

unittest {
  assert(first_of("test2)", "() ") == 5);
  assert(first_of("abc", "d") == -1);
  assert(first_of("abc", "a") == 0);
  assert(first_of("abc", "b") == 1);
  assert(first_of("abc", "c") == 2);
  assert(first_of("abc", "bc") == 1);
  assert(first_of("abc", "bd") == 1);
  assert(first_of("abc", "cb") == 1);
  assert(first_of("abc", "cd") == 2);
  assert(first_of("abc", "abc") == 0);
  assert(first_of("abc", "abcd") == 0);
  assert(first_of("abc", "cdb") == 1);
}

