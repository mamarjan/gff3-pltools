import std.stdio, std.file, std.conv, std.getopt, std.string;
import bio.gff3.file, bio.gff3.validation, bio.gff3.filtering;
import bio.gff3.record_range;
import util.split_file, util.version_helper;

/**
 * A utility for parsing GFF3 files. The only function supported for now is
 * filtering GFF3 files, for example, if your're only interested in CDS,
 * you can use this utility to extract all CDS records from a file like
 * this:
 *
 *   gff3-ffetch --filter field:feature:equals:CDS path-to-file.gff3
 *
 * See package README for more information.
 */

int main(string[] args) {
  // Parse command line arguments
  string filter_string = null;
  string output_filename = null;
  ulong at_most = -1;
  bool show_version = false;
  bool pass_fasta_through = false;
  bool keep_comments = false;
  bool keep_pragmas = false;
  bool gtf_input = false;
  bool gtf_output = false;
  if (args[0].indexOf("gtf-ffetch") != -1) {
    gtf_input = true;
    gtf_output = true;
  }
  bool help = false;
  try {
    getopt(args,
        std.getopt.config.passThrough,
        "filter|f", &filter_string,
        "output|o", &output_filename,
        "at-most|a", &at_most,
        "version", &show_version,
        "pass-fasta-through", &pass_fasta_through,
        "keep-comments", &keep_comments,
        "keep-pragmas", &keep_pragmas,
        "gtf-input", &gtf_input,
        "gtf-output", &gtf_output,
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
    writeln("gff3-ffetch (gff3-pltools) " ~ fetch_version());
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
  ulong record_counter = 0;
  if (at_most < 0) {
    foreach(rec; records) {
      output.writeln(rec.toString(gtf_output ? DataFormat.GTF : DataFormat.GFF3));
    }
  } else {
    foreach(rec; records) {
      if (record_counter == at_most) {
        output.write("# ...");
        break;
      } else {
        output.writeln(rec.toString(gtf_output ? DataFormat.GTF : DataFormat.GFF3));
        record_counter++;
      }
    }
  }

  // Print FASTA data if there is any and if the
  // line output limit has not been reached
  if (record_counter != at_most) {
    if (pass_fasta_through) {
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
  writeln("Usage: gff3-ffetch [OPTIONS] FILE");
  writeln("Parse GFF3 file and write records to stdout");
  writeln();
  writeln("Options:");
  writeln("  -f, --filter    A filtering expresion. Only records which match the");
  writeln("                  expression will be passed to stdout or output file.");
  writeln("  -o, --output    Instead of writing results to stdout, write them to");
  writeln("                  this file.");
  writeln("  -a, --at-most   At most this number of lines/records will be parsed.");
  writeln("                  If there are more records a line with \"# ...\" will");
  writeln("                  be appended at the end of the file.");
  writeln("  --pass-fasta-through");
  writeln("                  Copy the FASTA data at the end of the file to output");
  writeln("  --keep-comments Copy comments in GFF3 file to output");
  writeln("  --keep-pragmas  Copy pragmas in GFF3 file to output");
  writeln("  --gtf-input     Input data is in GTF format");
  writeln("  --gtf-output    Output data in GTF format");
  writeln("  --version       Output version information and exit.");
  writeln("  --help          Print this information and exit.");
  writeln();
  writeln("See package README for more information on what filtering expressions");
  writeln("are allowed.");
  writeln();
}

