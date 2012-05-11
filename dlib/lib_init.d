import core.runtime, core.memory;

extern (C) void lib_init() {
  Runtime.initialize();
  GC.disable();
}

void main() {}

