module util.split_line;

import std.string;

/**
 * Returns the part of the line up to the character delim, and updates
 * the original string as to remove that part, including the delimiter
 * character.
 */
T get_and_skip_next_field(T)(ref T line, char delim = '\t') {
  T field;
  auto next_tab = line.indexOf(delim);
  if (next_tab != -1) {
    field = line[0..next_tab];
    line = line[next_tab+1..$];
  } else {
    field = line;
    line = null;
  }
  return field;
}

