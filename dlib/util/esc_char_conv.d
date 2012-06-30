module util.esc_char_conv;

import std.string, std.conv, std.ascii, std.array;

/**
 * Converts the characters escaped using the URL escaping convention (%XX)
 * in a string to their real char values.
 */
char[] replace_url_escaped_chars(char[] original) {
  char * forward = original.ptr;
  char * end = forward + original.length;
  char * current = forward;
  // if true, next character is the first hex number
  bool start_esc = false;
  // if true, next character is the second hex number
  bool start_continue = false;
  char[2] hex;
  while(forward != end) {
    if (start_esc) {
      hex[0] = *forward;
      forward++;
      start_esc = false;
      start_continue = true;
      continue;
    } else if (start_continue) {
      hex[1] = *forward;
      forward++;
      start_continue = false;
      *current = convert_url_escaped_char(hex);
      current++;
    } else if (*forward == '%') {
      start_esc = true;
      forward++;
    } else {
      *current = *forward;
      forward++;
      current++;
    }
  }
  auto result_length = current-original.ptr;
  return original[0..result_length];
}

/**
  * Converts characters in hexadecimal format to their real char value.
  */
char convert_url_escaped_char(char[2] code) {
  if (std.ascii.fullHexDigits.indexOf(code[0]) == -1)
    throw new ConvException(cast(string) ("Invalid URL escaped code: " ~ code));
  if (std.ascii.fullHexDigits.indexOf(code[1]) == -1)
    throw new ConvException(cast(string) ("Invalid URL escaped code: " ~ code));

  return cast(char) (hex_to_int(code[0])*16 + hex_to_int(code[1]));
}

/**
 * Convert a character-encoded hex number to it's int value.
 */
int hex_to_int(char hex) {
  if ((hex >= '0') && (hex <= '9')) {
    return hex-'0';
  } else if ((hex >= 'a') && (hex <= 'f')) {
    return (hex-'a')+10;
  } else if ((hex >= 'A') && (hex <= 'F')) {
    return (hex-'A')+10;
  } else {
    throw new ConvException("Invalid hex character for conversion: " ~ hex);
  }
}

/**
 * A function which returns true if character is invalid and should be escaped.
 */
alias bool function(char) InvalidCharProc;

/**
 * The following function appends and escapes an array of characters
 * to an appender, while escaping the characters using the url
 * escaping conventions.
 */
void append_and_escape_chars(T)(Appender!T app, string field_value, InvalidCharProc is_invalid) {
  foreach(character; field_value) {
    if (is_invalid(character) || (character == '%')) {
      app.put('%');
      app.put(upper_4bits_to_hex(character));
      app.put(lower_4bits_to_hex(character));
    } else {
      app.put(character);
    }
  }
}

/**
 * Converts a number to characters 0..9, A..F.
 */
char to_hex_digit(ubyte input) {
  if (input < 10)
    return cast(char)('0' + input);
  else
    return cast(char)('A' + (input-10));
}

/**
 * Returns the hex representation of the upper 4bits of a char.
 */
char upper_4bits_to_hex(char character) {
  return to_hex_digit(cast(ubyte)character >> 4);
}


/**
 * Returns the hex representation of the lower 4bits of a char.
 */
char lower_4bits_to_hex(char character) {
  return to_hex_digit(cast(ubyte)character & 0x0F);
}


import std.stdio, std.exception;

unittest {
  writeln("Testing convert_url_escaped_char...");

  assert(convert_url_escaped_char("3D") == '=');
  assert(convert_url_escaped_char("00") == '\0');
  assertThrown!ConvException(convert_url_escaped_char("0H") == '\0');
}

unittest {
  writeln("Testing replace_url_escaped_chars...");

  assert(replace_url_escaped_chars("%3D".dup) == "=");
  assert(replace_url_escaped_chars("Testing %3D".dup) == "Testing =");
  assert(replace_url_escaped_chars("Multiple %3B replacements %00 and some %25 more".dup) == "Multiple ; replacements \0 and some % more");
  assert(replace_url_escaped_chars("One after another %3D%3B%25".dup) == "One after another =;%");
  assert(replace_url_escaped_chars("One after another %3D0%3B%25".dup) == "One after another =0;%");
  assertThrown!ConvException(replace_url_escaped_chars("One after another %3H%3B%25".dup) == "One after another =;%");
}

unittest {
  writeln("Testing append_and_escape_chars()...");
  
  auto is_invalid_char = function bool(char character) {
    return (std.ascii.isControl(character) ||
            (character == '%') ||
            (character == '=') ||
            (character == ';') ||
            (character == '&') ||
            (character == ','));
  };
  auto app = appender!string();
  append_and_escape_chars(app, "abc", is_invalid_char);
  assert(app.data == "abc");
  append_and_escape_chars(app, "\0\t", is_invalid_char);
  assert(app.data == "abc%00%09");
  append_and_escape_chars(app, "ab=,;", is_invalid_char);
  assert(app.data == "abc%00%09ab%3D%2C%3B");
  append_and_escape_chars(app, ">", is_invalid_char);
  assert(app.data == "abc%00%09ab%3D%2C%3B>");
}

