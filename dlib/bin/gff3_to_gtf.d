module bin.gff3_to_gtf;

import std.stdio, std.file, std.conv, std.getopt, std.string;
import bio.gff3.record_range, bio.gff3.validation, bio.gff3.conv.gtf;
import util.version_helper;

int gff3_to_gtf(string[] args) {
  // Parse command line arguments
  string output_filename = null;
  bool show_version = false;
  try {
    getopt(args,
        std.getopt.config.passThrough,
        "output|o", &output_filename,
        "version", &show_version);
  } catch (Exception e) {
    writeln(e.msg);
    writeln();
    print_usage();
    return 1; // Exit the application
  }

  if (show_version) {
    writeln("gff3-to-gtf (gff3-pltools) " ~ fetch_version());
    return 0;
  }

  // Only one or two filenames should be left at this point
  if (args.length != 2) {
    print_usage();
    return 2; // Exit the application
  }
  auto input_filename = args[1];

  // Check if input file exists
  alias char[] array;
  if (!(to!array(input_filename).exists)) {
    writeln("Could not find file: " ~ input_filename ~ "\n");
    print_usage();
    return 3;
  }

  // Prepare File object for output
  File output = stdout;
  if (output_filename !is null) {
    output = File(output_filename, "w");
  }

  // Open file and loop over all records
  RecordRange records;
  if (input_filename == "-")
    records = (new RecordRange).set_input_file(stdin);
  else
    records = (new RecordRange).set_input_file(input_filename);

  records.set_validate(NO_VALIDATION)
         .set_replace_esc_chars(false)
         .set_keep_pragmas(true)
         .set_keep_comments(true);
  foreach(rec; records) {
    output.writeln(rec.to_gtf());
  }

  return 0;
}

void print_usage() {
  writeln("Usage: gff3-to-gtf [OPTIONS] [FILE]");
  writeln("Converts a GFF3 file to GTF. Use - for stdin.");
  writeln();
  writeln("  -o, --output Instead of writing results to stdout, write them to");
  writeln("               this file.");
  writeln("  --version    Output version information and exit.");
  writeln();
}

