import std.stdio, std.file, std.conv, std.getopt, std.string;
import bio.gff3.file, bio.gff3.record_range, bio.gff3.validation;
import util.version_helper;

int main(string[] args) {
  // Parse command line arguments
  bool replace_escaped_chars = false;
  bool validate = false;
  bool parse_features = false;
  uint feature_cache_size = 1000;
  bool link_features = false;
  bool gtf_input = false;
  if (args[0].indexOf("gtf-benchmark") != -1) {
    gtf_input = true;
  }
  bool show_version = false;
  try {
    getopt(args,
        std.getopt.config.passThrough,
        "r", &replace_escaped_chars,
        "v", &validate,
        "f", &parse_features,
        "c", &feature_cache_size,
        "l", &link_features,
        "gtf-input", &gtf_input,
        "version", &show_version);
  } catch (Exception e) {
    writeln(e.msg);
    writeln();
    print_usage();
    return 1; // Exit the application
  }

  if (show_version) {
    writeln("gff3-benchmark (gff3-pltools) " ~ fetch_version());
    return 0;
  }

  // Only a filename should be left at this point
  if (args.length != 2) {
    print_usage();
    return 2; // Exit the application
  }
  auto filename = args[1];

  // Check if file exists
  alias char[] array;
  if (!(to!array(filename).exists)) {
    writeln("Could not find file: " ~ filename ~ "\n");
    print_usage();
    return 3;
  }

  if (parse_features) {
    if (gtf_input) {
      writeln("Parsing GTF features not yet supported!");
      return 4;
    }
    // Open file and loop over all features
    auto features = GFF3File.parse_by_features(filename,
                                               feature_cache_size,
                                               link_features);
    features.set_validate(validate ? WARNINGS_ON_ERROR : NO_VALIDATION)
            .set_replace_esc_chars(replace_escaped_chars);
    size_t counter = 0;
    foreach(feature; features) { counter++; }
    writeln("Parsed " ~ to!string(counter) ~ " features");
  } else {
    // Open file and loop over all records
    GenericRecordRange records;
    if (!gtf_input) {
      records = GFF3File.parse_by_records(filename);
    } else {
      records = GTFFile.parse_by_records(filename);
    }
    records.set_validate(validate ? WARNINGS_ON_ERROR : NO_VALIDATION)
           .set_replace_esc_chars(replace_escaped_chars);
    size_t counter = 0;
    foreach(rec; records) { counter++; }
    writeln("Parsed " ~ to!string(counter) ~ " records");
  }

  return 0;
}

void print_usage() {
  writeln("Usage: gff3-benchmark [OPTIONS] FILE");
  writeln("Parse FILE without any validation");
  writeln();
  writeln("  -v           turn on validation");
  writeln("  -r           turn on replacement of escaped characters");
  writeln("  -f           merge records into features");
  writeln("  -c N         feature cache size (how many features to keep in memory), default=1000");
  writeln("  -l           link feature into parent-child relationships");
  writeln("  --gtf-input  Input data is in GTF format");
  writeln("  --version    Output version information and exit.");
  writeln();
}

