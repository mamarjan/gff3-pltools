module util.read_file;

import std.stdio;

/**
 * Reads the whole file into a string. Works only for files
 * up to the size of size_t.max.
 */
string read(File file) {
  if (file.size > size_t.max)
    throw new Exception("File bigger then the largest array possible");
  char[] buf = new char[cast(size_t)(file.size)];
  return cast(immutable)(file.rawRead(buf));
}

