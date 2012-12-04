import std.stdio, std.file, std.conv, std.getopt, std.string;
import bio.gff3.file, bio.gff3.validation,
       bio.gff3.record_range, bio.gff3.selection, bio.gff3.record,
       bio.gff3.conv.json, bio.gff3.conv.table, bio.gff3.conv.gff3,
       bio.gff3.conv.gtf;
import util.split_file, util.version_helper;

/**
 * A utility for selecting specific fields and/or attributes from
 * GFF3 files, with table output.
 *
 *   gff3-filter 
 *
 * See package README for more information.
 */
int main(string[] args) {
  // Parse command line arguments
  string output_filename = null;
  bool show_version = false;
  bool gtf_input = false;
  if (args[0].indexOf("gtf-select") != -1) {
    gtf_input = true;
  }
  bool json = false;
  bool help = false;
  try {
    getopt(args,
        std.getopt.config.passThrough,
        "output|o", &output_filename,
        "version", &show_version,
        "gtf-input", &gtf_input,
        "json", &json,
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
    writeln("gff3-select (gff3-pltools) " ~ fetch_version());
    return 0;
  }

  if (args.length != 3) {
    print_usage();
    return 2; // Exit the application
  }

  // A selection string should be the first parameter left
  string selection = args[1];

  // A filename should be the last parameter
  auto filename = args[2];

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

  // Increase output buffer size
  output.setvbuf(1048576);

  // Prepare for parsing
  RecordRange records;
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
         .set_replace_esc_chars(false)
         .set_keep_comments(false)
         .set_keep_pragmas(false);

  // Parsing, filtering and output
  try {
    if (json) {
      records.to_json(output, -1, selection);
    } else {
      records.to_table(output, -1, selection);
    }
  } catch (Exception e) {
    writeln(e.msg);
    return -1;
  }

  return 0;
}

void print_usage() {
  writeln("Usage: gff3-select SELECT_EXPR [OPTIONS] FILE");
  writeln("Select GFF3 fields and/or attributes and output in table format");
  writeln();
  writeln("Options:");
  writeln("  -o, --output    Instead of writing results to stdout, write them to");
  writeln("                  this file.");
  writeln("  --gtf-input     Input data is in GTF format");
  writeln("  --json          Output data in JSON format");
  writeln("  --version       Output version information and exit.");
  writeln("  --help          Print this information and exit.");
  writeln();
  writeln("See manual page for more information on what filtering expressions");
  writeln("are allowed.");
  writeln();
}

