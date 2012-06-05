module util.read_file;

import std.stdio;

/**
 * Reads the whole file into a string. Works only for files
 * up to the size of 2^^32.
 */
string read(File file) {
  // TODO: Throw error if file too big for a D string
  char[] buf = new char[cast(uint)(file.size)];
  return cast(immutable)(file.rawRead(buf));
}

