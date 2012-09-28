module util.array_includes;

import std.algorithm;
import util.equals_ci;

/**
 * Returns true if needle is found in haystack. Comparison is
 * case insensitive.
 */
bool includes_ci(string[] haystack, string needle) {
    bool is_requested(string a) {
      return a.equals_ci(needle);
    }

    return reduce!("a || b")(false, map!(is_requested)(haystack));
}

unittest {
  assert(includes_ci(["hello", "you", "there"], "hello") == true);
  assert(includes_ci(["hello", "you", "there"], "you") == true);
  assert(includes_ci(["hello", "you", "there"], "there") == true);
  assert(includes_ci(["hello", "YOU", "there"], "you") == true);
  assert(includes_ci(["hello", "You", "there"], "you") == true);
  assert(includes_ci(["hello", "you", "there"], "YOU") == true);

  assert(includes_ci(["hello", "you", "there"], "anybody") == false);
  assert(includes_ci(["hello", "you", "there"], "you too") == false);
  assert(includes_ci(["hello", "you", "there"], "you ") == false);
  assert(includes_ci(["hello", "you", "there"], " you ") == false);
  assert(includes_ci(["hello", "you", "there"], "YOU ") == false);
}

