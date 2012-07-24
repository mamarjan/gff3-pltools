import std.stdio, std.file, std.conv, std.getopt;
import bio.gff3.file, bio.gff3.validation;
import util.version_helper;

int main(string[] args) {
  // Parse command line arguments
  bool show_version = false;
  try {
    getopt(args,
        std.getopt.config.passThrough,
        "version", &show_version);
  } catch (Exception e) {
    writeln(e.msg);
    writeln();
    print_usage();
    return 1; // Exit the application
  }

  if (show_version) {
    writeln("validate-gff3 (gff3-pltools) " ~ fetch_version());
    return 0;
  }

  // Check if only filename left
  if (args.length != 2) {
    print_usage();
    return 1; // Exit the application
  }

  auto filename = args[1];

  // Check if file exists
  alias char[] array;
  if (!(to!array(filename).exists)) {
    writeln("Could not find file: " ~ filename ~ "\n");
    print_usage();
    return 2;
  }

  // Open file and loop over all records, while printing error messages
  foreach(rec; GFF3File.parse_by_records(filename).set_validate(WARNINGS_ON_ERROR)) {}

  return 0;
}

void print_usage() {
  writeln("Usage: validate-gff3 [OPTIONS] FILE");
  writeln("Check FILE for errors");
  writeln();
  writeln("Options:");
  writeln("  --version      Output version information and exit.");
  writeln();
}

