module util.array_includes;

import std.algorithm;
import util.equals;

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

