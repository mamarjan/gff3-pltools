module bio.util;

import std.stdio, std.conv, std.range, std.string, std.array, std.exception;
import std.ascii;

/**
 * General utilities useful for more then one project
 */

/**
 * Converts the characters escaped with the URL escaping convention (%XX)
 * in a string to their real char values.
 */
string replace_url_escaped_chars(string original) {
  auto index = indexOf(original, '%');
  if (index < 0) {
    return original;
  } else {
    return original[0..index] ~
           convert_url_escaped_char(original[index+1..index+3]) ~
           replace_url_escaped_chars(original[index+3..$]);
  }
}

/**
  * Converts characters in hexadecimal format to their real char value.
  */
char convert_url_escaped_char(string code) {
  // First check if code valid
  if (code.length != 2)
    throw new ConvException("Invalid URL escaped code: " ~ code);
  foreach(character; code)
    if (std.ascii.fullHexDigits.indexOf(character) == -1)
      throw new ConvException("Invalid URL escaped code: " ~ code);

  uint numeric = to!int(code, 16);
  return cast(char) numeric;
}

/**
 * A lazy string splitter. The constructor takes a string,
 * detects what the line terminator is and then returns lines
 * one by one. There is no copying involved, only slicing.
 *
 * FIXME: This class is not truely lazy (no delegation), though
 *        it defers parsing until calling. Look up terminology.
 */
class LazySplitLines {
  this(string data) {
    this.data = data;
    this.data_left = data;
    this.newline = detect_newline_delim(data);
  }

  /**
   * Returns the next line in range.
   */
  string front() {
    string result = null;
    auto nl_index = indexOf(data_left, newline);
    if (nl_index == -1) {
      // last line
      result = data_left;
    } else {
      result = data_left[0..nl_index];
    }
    return result;
  }

  /**
   * Pops the next line of the range.
   */
  void popFront() {
    auto nl_index = indexOf(data_left, newline);
    if (nl_index == -1) {
      // last line
      data_left = null;
    } else {
      data_left = data_left[(nl_index+newline.length)..$];
    }
  }

  /**
   * Return true if no more lines left in the range.
   */
  bool empty() {
    return data_left is null;
  }
  
  private {
    string newline;
    string data;
    string data_left;
  }
}

/**
 * Detects the character or a character sequence which is used in the string
 * for line termination.
 */
string detect_newline_delim(string data) {
  // TODO: Implement a better line termination detection strategy
  //
  // FIXME: We can assume newlines are platform specific. D has a way of handling these. 
  //        Any digressions are resposibility of the user, not this library.
  return "\n";
}

/**
 * Reads the whole file into a string. Works only for files
 * up to the size of 2^^32.
 */
string read(File file) {
  // TODO: Throw error if file too big for a D string
  char[] buf = new char[cast(uint)(file.size)];
  return cast(immutable)(file.rawRead(buf));
}

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

unittest {
  writeln("Testing convert_url_escaped_char...");
  assert(convert_url_escaped_char("3D") == '=');
  assert(convert_url_escaped_char("00") == '\0');
  assertThrown!ConvException(convert_url_escaped_char("000") == '\0');
  assertThrown!ConvException(convert_url_escaped_char("00F") == '\0');
  assertThrown!ConvException(convert_url_escaped_char("0H") == '\0');
}

unittest {
  writeln("Testing replace_url_escaped_chars...");
  assert(replace_url_escaped_chars("%3D") == "=");
  assert(replace_url_escaped_chars("Testing %3D") == "Testing =");
  assert(replace_url_escaped_chars("Multiple %3B replacements %00 and some %25 more") == "Multiple ; replacements \0 and some % more");
  assert(replace_url_escaped_chars("One after another %3D%3B%25") == "One after another =;%");
  assert(replace_url_escaped_chars("One after another %3D0%3B%25") == "One after another =0;%");
  assertThrown!ConvException(replace_url_escaped_chars("One after another %3H%3B%25") == "One after another =;%");
}

unittest {
  writeln("Testing LazySplitLines...");
  auto lines = new LazySplitLines("Test\n1\n2\n3");
  assert(lines.empty == false);
  assert(lines.front == "Test"); lines.popFront();
  assert(lines.empty == false);
  assert(lines.front == "1"); lines.popFront();
  assert(lines.empty == false);
  assert(lines.front == "2"); lines.popFront();
  assert(lines.empty == false);
  assert(lines.front == "3"); lines.popFront();
  assert(lines.empty == true);
  
  // Test for correct behavior when newline at the end of the file
  lines = new LazySplitLines("Test newline at the end\n");
  assert(lines.empty == false);
  assert(lines.front == "Test newline at the end"); lines.popFront();
  assert(lines.empty == false);
  assert(lines.front == ""); lines.popFront();
  assert(lines.empty == true);

  // Test if it's working with foreach
  lines = new LazySplitLines("1\n2\n3\n4");
  int i = 1;
  foreach(value; lines) {
    assert(value == to!string(i));
    i++;
  }
}

