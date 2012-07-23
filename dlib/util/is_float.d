module util.is_float;

import std.stdio;

/**
 * Returns true if the string contains a valid floating point number.
 */
bool is_float(T)(T[] data) {
  if (data.length == 0)
    return false;

  // Check for a sign
  if ((data[0] == '+') || (data[0] == '-'))
    data = data[1..$];

  // Check for integral part
  if (data.length == 0)
    return false;

  bool integral_part_present = false;
  while ((data[0] >= '0') && (data[0] <= '9')) {
    integral_part_present = true;
    data = data[1..$];
    if (data.length == 0)
      break;
  }
  if (!integral_part_present)
    return false;

  // Check for point
  bool point_present = false;
  if (data.length == 0)
    return true;

  if (data[0] == '.') {
    point_present = true;
    data = data[1..$];
  }
  
  // Check for fractional part
  bool fractional_part_present = false;
  if (data.length == 0)
    return true;

  while ((data[0] >= '0') && (data[0] <= '9')) {
    fractional_part_present = true;
    data = data[1..$];
    if (data.length == 0)
      break;
  }

  // Check for exponent char
  if (data.length == 0)
    return true;

  if ((data[0] == 'e') || (data[0] == 'E')) {
    data = data[1..$];
  } else {
    return false;
  }

  // Check for a sign
  if (data.length == 0)
    return false;

  if ((data[0] == '+') || (data[0] == '-'))
    data = data[1..$];

  // Check for exponent part
  bool exponential_part_present = false;
  if (data.length == 0)
    return false;

  while ((data[0] >= '0') && (data[0] <= '9')) {
    exponential_part_present = true;
    data = data[1..$];
    if (data.length == 0)
      break;
  }
  if (!exponential_part_present)
    return false;
 
  // At this point nothing should be left 
  if (data.length == 0)
    return true;
  else
    return false;
}

unittest {
  writeln("Testing is_float()...");

  assert(is_float("1") == true);
  assert(is_float("123") == true);
  assert(is_float("123a") == false);
  assert(is_float("a123") == false);
  assert(is_float("123.") == true);
  assert(is_float("123.45") == true);
  assert(is_float("123.ab") == false);
  assert(is_float("123.e") == false);
  assert(is_float("abc") == false);
  assert(is_float(".") == false);
  assert(is_float(".abc") == false);
  assert(is_float("abc.") == false);
  assert(is_float("123.e2") == true);
  assert(is_float("123.+e2") == false);
  assert(is_float("123.e+2") == true);
  assert(is_float("123.e-2") == true);
  assert(is_float("123.ee2") == false);
  assert(is_float("123.ea2") == false);
  assert(is_float("123.4e2") == true);
  assert(is_float("123.45e2") == true);
  assert(is_float("123.45e23") == true);
  assert(is_float("123.45e+23") == true);
  assert(is_float("123.45e-23") == true);
  assert(is_float("123.45ea-23") == false);
  assert(is_float("123.45ee-23") == false);
  assert(is_float("0.45e-23") == true);
  assert(is_float("0.45e+23") == true);
  assert(is_float("0.45e23") == true);
  assert(is_float("-0.45e23") == true);
  assert(is_float("-.45e23") == false);
  assert(is_float(".45e23") == false);
  assert(is_float(".45") == false);
}

