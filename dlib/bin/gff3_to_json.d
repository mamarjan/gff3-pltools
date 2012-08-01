import std.stdio, std.file, std.conv, std.getopt, std.string;
import bio.gff3.file, bio.gff3.validation, bio.gff3.record_range,
       bio.gff3.conv.json, bio.gff3.feature_range;
import util.split_file, util.version_helper;

/**
 * A utility for conversion of data in GFF3 format to JSON.
 */

int main(string[] args) {
  // Parse command line arguments
  string output_filename = null;
  bool show_version = false;
  bool keep_comments = false;
  bool keep_pragmas = false;
  bool gtf_input = false;
  if (args[0].indexOf("gtf-to-json") != -1) {
    gtf_input = true;
  }
  bool features_selected = false;
  uint feature_cache_size = 1000;
  bool help = false;
  try {
    getopt(args,
        std.getopt.config.passThrough,
        "output|o", &output_filename,
        "version", &show_version,
        "keep-comments", &keep_comments,
        "keep-pragmas", &keep_pragmas,
        "gtf-input", &gtf_input,
        "features", &features_selected,
        "cache-size", &feature_cache_size,
        "help", &help);
  } catch (Exception e) {
    writeln(e.msg);
    writeln();
    print_usage();
    return 1; // Exit the application
  }

  if (help) {
    print_usage();
    return 0;
  }

  if (show_version) {
    writeln("gff3-to-json (gff3-pltools) " ~ fetch_version());
    return 0;
  }

  // Only a filename should be left at this point
  auto filename = args[1];
  if (args.length != 2) {
    print_usage();
    return 2; // Exit the application
  }

  // Check if file exists, if not stdin
  alias char[] array;
  if (filename != "-") {
    if (!(to!array(filename).exists)) {
      writeln("Could not find file: " ~ filename ~ "\n");
      print_usage();
      return 3;
    }
  }

  // Prepare File object for output
  File output = stdout;
  if (output_filename !is null) {
    output = File(output_filename, "w");
  }

  // Prepare for parsing
  if (features_selected) {
    FeatureRange features;
    if (gtf_input) {
      // raise error
    } else {
      if (filename == "-") {
        features = GFF3File.parse_by_features(stdin);
      } else {
        features = GFF3File.parse_by_features(filename, feature_cache_size);
      }
    }

    features.set_validate(NO_VALIDATION)
            .set_replace_esc_chars(true)
            .set_keep_comments(keep_comments)
            .set_keep_pragmas(keep_pragmas);

    features.to_json(output);
  } else {
    RecordRange!SplitFile records;
    if (filename == "-") {
      if (!gtf_input)
        records = GFF3File.parse_by_records(stdin);
      else
        records = GTFFile.parse_by_records(stdin);
    } else {
      if (!gtf_input)
        records = GFF3File.parse_by_records(filename);
      else
        records = GTFFile.parse_by_records(filename);
    }

    records.set_validate(NO_VALIDATION)
           .set_replace_esc_chars(true)
           .set_keep_comments(keep_comments)
           .set_keep_pragmas(keep_pragmas);

    records.to_json(output);
  }

  return 0;
}

void print_usage() {
  writeln("Usage: gff3-to-json [OPTIONS] FILE");
  writeln("Parse GFF3 file and write records to stdout");
  writeln();
  writeln("Options:");
  writeln("  -o, --output    Instead of writing results to stdout, write them to");
  writeln("                  this file.");
  writeln("  --keep-comments Copy comments in GFF3 file to output");
  writeln("  --keep-pragmas  Copy pragmas in GFF3 file to output");
  writeln("  --gtf-input     Input data is in GTF format");
  writeln("  --features      merge records into features");
  writeln("  --cache-size N  feature cache size (how many features to keep in memory), default=1000");
  writeln("  --version       Output version information and exit.");
  writeln("  --help          Print this information and exit.");
  writeln();
}

