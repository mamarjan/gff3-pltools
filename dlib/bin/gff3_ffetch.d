import std.stdio, std.file, std.conv, std.getopt, std.string;
import bio.gff3.file, bio.gff3.validation,
       bio.gff3.record_range, bio.gff3.selection, bio.gff3.record,
       bio.gff3.conv.json, bio.gff3.conv.table, bio.gff3.conv.gff3,
       bio.gff3.conv.gtf, bio.gff3.conv.fasta, bio.fasta;
import util.split_file, util.version_helper, util.read_file,
       util.split_into_lines, util.logger;

/**
 * A utility for fetching sequences from GFF3 and FASTA files.
 *
 *   gff3-ffetch cds path-to-file.fa path-to-file.gff3
 *
 * See package README for more information.
 */

int gff3_ffetch(string[] args) {
  // Parse command line arguments
  string parent_feature_type = null;
  string output_filename = null;
  bool translate = false;
  bool fix = false;
  bool fix_wormbase = false;
  bool no_assemble = false;
  bool phase = false;
  bool frame = false;
  bool trim_end = false;
  int verbosity_level = 1;
  bool show_version = false;
  bool help = false;
  void verbosity_level_handler(string option) {
    switch(option) {
      case "v":
        verbosity_level += 1;
        break;
      case "q":
        verbosity_level -= 1;
        break;
      default:
        throw new Exception("This should never happen. Please report to maintainer.");
        break;
    }
  }
  try {
    getopt(args,
        std.getopt.config.passThrough,
        "parent-type", &parent_feature_type,
        "output|o", &output_filename,
        "translate", &translate,
        "fix", &fix,
        "no-assemble", &no_assemble,
        "phase", &phase,
        "frame", &frame,
        "trim-end", &trim_end,
        "v", &verbosity_level_handler,
        "q", &verbosity_level_handler,
        "version", &show_version,
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

  if (fix) {
    phase = true;
    frame = true;
    trim_end = true;
  }

  init_default_logger(verbosity_level);

  // The first argument left should be the feature type
  auto feature_type = toLower(args[1]);
  if ((feature_type != "cds") && (feature_type != "mrna")) {
    writeln("Only CDS and mRNA features are supported at the moment.");
    return 5;
  }

  // The second argument left should be either a FASTA or a GFF3 file
  string fasta_filename;
  string fasta_data;
  string[string] fasta_map;

  // Prepare File object for output
  File output = stdout;
  if (output_filename !is null) {
    output = File(output_filename, "w");
  }

  // Increase output buffer size
  output.setvbuf(1048576);

  foreach(filename; args[2..$]) {
    // Check if files exist
    alias char[] array;
    if (!(to!array(filename).exists)) {
      writeln("Could not find file: " ~ filename ~ "\n");
      print_usage();
      return 3;
    }

    if (filename.endsWith(".fa") || filename.endsWith(".fas") || filename.endsWith(".fas")) {
      if (fasta_filename.length == 0) {
        fasta_filename = filename;
        continue;
      } else {
        writeln("Only one FASTA file allowed per GFF3");
        print_usage();
        return 6;
      }
    }

    if (fasta_data is null) {
      if (fasta_filename !is null) {
        fasta_data = read(File(fasta_filename, "r"));
        fasta_map = (new FastaRange(new SplitIntoLines(fasta_data))).all;
      }
    }

    auto records = GFF3File.parse_by_records(filename);
    records.set_validate(NO_VALIDATION)
           .set_replace_esc_chars(false)
           .set_keep_comments(false)
           .set_keep_pragmas(false);

    records.to_fasta(feature_type, parent_feature_type, fasta_map, no_assemble, phase, frame, trim_end, translate, output);
  }

  return 0;
}

void print_usage() {
  writeln("Usage: gff3-ffetch FEATURE_TYPE [FASTA_FILE] GFF3_FILE... [OPTIONS]");
  writeln("Assemble sequences form GFF3 and FASTA files");
  writeln();
  writeln("Options:");
  writeln("  --parent-type   Use parent features for grouping instead of ID attr");
  writeln("  --translate     Output as amino acid sequence.");
  writeln("  --fix           Same as phase, frame and trim-end options together.");
  writeln("  --no-assemble   Output each record as a sequence.");
  writeln("  --phase         Take into account the phase field of a GFF3 record and adjust");
  writeln("                  the sequence.");
  writeln("  --frame         Try to guess the best reading frame, by optimising the");
  writeln("                  sequence for the least possible number of stop codons.");
  writeln("  --trim-end      Trim the end of each sequence to make sure it's");
  writeln("                  length modulo 3 is 0");
  writeln("  -o, --output    Instead of writing results to stdout, write them to");
  writeln("                  this file.");
  writeln("  -v, -q          Increase/decrease verbosity level. Multiple can be used in");
  writeln("                  one command.");
  writeln("  --version       Output version information and exit.");
  writeln("  --help          Print this information and exit.");
  writeln();
}

int main(string[] args) {
  return gff3_ffetch(args);
}

