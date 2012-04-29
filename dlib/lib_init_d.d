module lib_init;

import core.runtime : Runtime;
import std.array;
extern (C) export void attach() { Runtime.initialize(); }
extern (C) export void detach() { Runtime.terminate(); }


extern (C) export void foo() {
  int x = 5;
  x++;
  split("test test 123");
}

void main() {}

