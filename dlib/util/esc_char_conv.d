module util.esc_char_conv;

import std.string, std.exception, std.conv, std.stdio, std.ascii;

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

