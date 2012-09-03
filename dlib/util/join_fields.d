module util.join_fields;

import std.array;

void join_fields(T,P)(T input_array, char delim, Appender!P app) {
  bool first_value = true;
  foreach(value; input_array) {
    if (first_value)
      first_value = false;
    else
      app.put(delim);
    app.put(value);
  }
}

