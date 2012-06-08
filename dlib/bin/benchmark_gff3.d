import std.stdio, std.file, std.conv;
import bio.gff3_file, bio.gff3_validation;

void main(string[] args) {
  // Check if one argument was passed
  if (args.length != 2)
    print_usage();

  alias char[] array;
  auto filename = to!array(args[1]);

  // Check if file exists
  if (!(filename.exists)) {
    writeln("Count not find file: " ~ filename ~ "\n");
    print_usage();
  }

  foreach(rec; bio.gff3_file.open(to!string(filename), NO_VALIDATION, false)) {}
}

void print_usage() {
  writeln("Usage: benchmark-gff3 FILE");
  writeln("Parse FILE without any validation");
}

