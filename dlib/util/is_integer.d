module util.is_integer;

/**
 * Returns true if the string contains a valid integer number.
 */
bool is_integer(T)(T[] data) {
  if (data.length == 0)
    return false;

  // Check for a sign
  if ((data[0] == '+') || (data[0] == '-'))
    data = data[1..$];

  bool integral_part_present = false;
  while ((data[0] >= '0') && (data[0] <= '9')) {
    integral_part_present = true;
    data = data[1..$];
    if (data.length == 0)
      break;
  }
  if (!integral_part_present)
    return false;

  // At this point nothing should be left 
  if (data.length == 0)
    return true;
  else
    return false;
}

