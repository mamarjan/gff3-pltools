module util.esc_char_conv;

import std.string, std.exception, std.conv, std.stdio, std.ascii;

/**
 * Converts the characters escaped with the URL escaping convention (%XX)
 * in a string to their real char values.
 */
char[] replace_url_escaped_chars(char[] original) {
  char * forward = original.ptr;
  char * end = forward + original.length;
  char * current = forward;
  size_t count = 0;
  bool start_esc = false;
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
      count++;
    } else if (*forward == '%') {
      start_esc = true;
      forward++;
    } else {
      *current = *forward;
      forward++;
      current++;
      count++;
    }
  }
  return original[0..count];
}

char convert_url_escaped_char(char[2] code) {
  uint numeric = 0;
  char first = code[0];
  char second = code[1];
  if ((first > '0') && (first <= '9')) {
    numeric += (first-'0')*16;
  } else if ((first >= 'a') && (first <= 'f')) {
    numeric += ((first-'a')+10)*16;
  } else if ((first >= 'A') && (first <= 'F')) {
    numeric += ((first-'A')+10)*16;
  }
  if ((second > '0') && (second <= '9')) {
    numeric += second-'0';
  } else if ((second >= 'a') && (second <= 'f')) {
    numeric += (second-'a')+10;
  } else if ((second >= 'A') && (second <= 'F')) {
    numeric += (second-'A')+10;
  }
  //uint numeric = to!int(code, 16);
  return cast(char) numeric;
}

/**
  * Converts characters in hexadecimal format to their real char value.
  */
  // First check if code valid
  //if (code.length != 2)
  //  throw new ConvException("Invalid URL escaped code: " ~ code);
  //foreach(character; code)
  //  if (std.ascii.fullHexDigits.indexOf(character) == -1)
  //    throw new ConvException("Invalid URL escaped code: " ~ code);

/*
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
*/
