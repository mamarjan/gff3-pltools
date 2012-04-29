module lib_init;

import core.runtime : Runtime;
extern (C) export void attach() { Runtime.initialize(); }
extern (C) export void detach() { Runtime.terminate(); }

import std.array : array;
import std.algorithm : splitter;

extern (C) void foo() {
      array(splitter("abc", ' ')); 
}

void main() {}

