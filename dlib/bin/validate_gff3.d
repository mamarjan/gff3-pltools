import std.stdio, std.file, std.conv;
import bio.gff3_file, bio.gff3_validation;

void main(string[] args) {
  // Check if one argument was passed
  if (args.length != 2) {
    print_usage();
    return; // Exit the application
  }

  auto filename = args[1];

  // Check if file exists
  alias char[] array;
  if (!(to!array(filename).exists)) {
    writeln("Could not find file: " ~ filename ~ "\n");
    print_usage();
    return;
  }

  // Open file and loop over all records, while printing error messages
  foreach(rec; GFF3File.parse_by_records(filename, WARNINGS_ON_ERROR)) {}
}

void print_usage() {
  writeln("Usage: validate-gff3 FILE");
  writeln("Check FILE for errors");
}

