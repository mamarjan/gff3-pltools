import std.stdio, std.file, std.conv, std.getopt;
import bio.gff3_file, bio.gff3_validation;

void main(string[] args) {
  // Parse command line arguments
  bool replace_escaped_chars = false;
  bool validate = false;
  getopt(args,
      std.getopt.config.passThrough,
      "r", &replace_escaped_chars,
      "v", &validate);

  // Only a filename should be left at this point
  auto filename = args[1];
  if (args.length != 2) {
    print_usage();
    return; // Exit the application
  }

  // Check if file exists
  alias char[] array;
  if (!(to!array(filename).exists)) {
    writeln("Could not find file: " ~ filename ~ "\n");
    print_usage();
    return;
  }

  // Open file and loop over all records
  auto records = bio.gff3_file.open(filename,
                                    validate ? WARNINGS_ON_ERROR : NO_VALIDATION,
                                    replace_escaped_chars);
  foreach(rec; records) {}
}

void print_usage() {
  writeln("Usage: benchmark-gff3 FILE");
  writeln("Parse FILE without any validation");
}

