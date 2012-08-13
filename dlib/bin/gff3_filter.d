import std.stdio, std.file, std.conv, std.getopt, std.string;
import bio.gff3.file, bio.gff3.validation, bio.gff3.filtering,
       bio.gff3.record_range, bio.gff3.selection, bio.gff3.record,
       bio.gff3.conv.json, bio.gff3.conv.table, bio.gff3.conv.gff3,
       bio.gff3.conv.gtf;
import util.split_file, util.version_helper;

/**
 * A utility for filtering GFF3 files, for example, if your're only
 * interested in CDS, you can use this utility to extract all CDS
 * records from a file like this:
 *
 *   gff3-filter --filter field:feature:equals:CDS path-to-file.gff3
 *
 * See package README for more information.
 */

int main(string[] args) {
  // Parse command line arguments
  string filter_string = null;
  string output_filename = null;
  long at_most = -1;
  bool show_version = false;
  bool keep_fasta = false;
  bool keep_comments = false;
  bool keep_pragmas = false;
  bool gtf_input = false;
  bool gtf_output = false;
  if (args[0].indexOf("gtf-filter") != -1) {
    gtf_input = true;
    gtf_output = true;
  }
  bool gff3_output = false;
  string selection = null;
  bool json = false;
  bool help = false;
  try {
    getopt(args,
        std.getopt.config.passThrough,
        "filter|f", &filter_string,
        "output|o", &output_filename,
        "at-most|a", &at_most,
        "version", &show_version,
        "keep-fasta", &keep_fasta,
        "keep-comments", &keep_comments,
        "keep-pragmas", &keep_pragmas,
        "gtf-input", &gtf_input,
        "gtf-output", &gtf_output,
        "gff3-output", &gff3_output,
        "select", &selection,
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
    writeln("gff3-filter (gff3-pltools) " ~ fetch_version());
    return 0;
  }

  if (gff3_output) {
    gtf_output = false;
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

  // Increase output buffer size
  output.setvbuf(1048576);

  // Prepare for parsing
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
         .set_replace_esc_chars(false)
         .set_after_filter(string_to_filter(filter_string))
         .set_keep_comments(keep_comments)
         .set_keep_pragmas(keep_pragmas);

  // Parsing, filtering and output
  bool at_most_reached = false;
  if (selection is null) {
    if (gtf_output) {
      at_most_reached = records.to_gtf(output, at_most);
    } else if (json) {
      at_most_reached = records.to_json(output, at_most);
    } else {
      at_most_reached = records.to_gff3(output, at_most);
    }
  } else {
    if (json) {
      at_most_reached = records.to_json(output, at_most, selection);
    } else {
      at_most_reached = records.to_table(output, at_most, selection);
    }
  }

  // Print FASTA data if there is any and if the
  // line output limit has not been reached
  if (!at_most_reached) {
    if (keep_fasta) {
      auto fasta_data = records.get_fasta_data();
      if (fasta_data !is null) {
        output.writeln("##FASTA");
        output.write(fasta_data);
      }
    }
  }
 
  return 0;
}

void print_usage() {
  writeln("Usage: gff3-filter [OPTIONS] FILE");
  writeln("Filter GFF3 file and write records to stdout");
  writeln();
  writeln("Options:");
  writeln("  -f, --filter    A filtering expresion. Only records which match the");
  writeln("                  expression will be passed to stdout or output file.");
  writeln("  --select        Output data table format with columns specified by an argument");
  writeln("  -o, --output    Instead of writing results to stdout, write them to");
  writeln("                  this file.");
  writeln("  -a, --at-most   At most this number of lines/records will be parsed.");
  writeln("                  If there are more records a line with \"# ...\" will");
  writeln("                  be appended at the end of the file.");
  writeln("  --keep-fasta    Copy FASTA data at the end of input file to output");
  writeln("  --keep-comments Copy comments in GFF3 file to output");
  writeln("  --keep-pragmas  Copy pragmas in GFF3 file to output");
  writeln("  --gtf-input     Input data is in GTF format");
  writeln("  --gtf-output    Output data in GTF format");
  writeln("  --gff3-output   Output data in GFF3 format");
  writeln("  --json          Output data in JSON format");
  writeln("  --version       Output version information and exit.");
  writeln("  --help          Print this information and exit.");
  writeln();
  writeln("See package README for more information on what filtering expressions");
  writeln("are allowed.");
  writeln();
}

