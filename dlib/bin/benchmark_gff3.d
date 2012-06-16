import std.stdio, std.file, std.conv, std.getopt;
import bio.gff3_file, bio.gff3_validation;

void main(string[] args) {
  // Parse command line arguments
  bool replace_escaped_chars = false;
  bool validate = false;
  bool parse_features = false;
  uint feature_cache_size = 1000;
  getopt(args,
      std.getopt.config.passThrough,
      "r", &replace_escaped_chars,
      "v", &validate,
      "f", &parse_features,
      "c", &feature_cache_size);

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

  if (parse_features) {
    // Open file and loop over all features
    auto features = GFF3File.parse_by_features(filename,
                                               validate ? WARNINGS_ON_ERROR : NO_VALIDATION,
                                               replace_escaped_chars,
                                               feature_cache_size);
    size_t counter = 0;
    foreach(feature; features) { counter++; }
    writeln("Parsed " ~ to!string(counter) ~ " features");
  } else {
    // Open file and loop over all records
    auto records = GFF3File.parse_by_records(filename,
                                             validate ? WARNINGS_ON_ERROR : NO_VALIDATION,
                                             replace_escaped_chars);
    size_t counter = 0;
    foreach(rec; records) { counter++; }
    writeln("Parsed " ~ to!string(counter) ~ " records");
  }
}

void print_usage() {
  writeln("Usage: benchmark-gff3 FILE");
  writeln("Parse FILE without any validation");
  writeln();
  writeln("  -v     turn on validation");
  writeln("  -r     turn on replacement of escaped characters");
  writeln("  -f     merge records into features");
  writeln("  -c N   feature cache size (how many features to keep in memory), default=1000");
  writeln();
}

