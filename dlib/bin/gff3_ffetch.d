import std.stdio, std.file, std.conv, std.getopt, std.string;
import bio.gff3.file, bio.gff3.validation, bio.gff3.filtering,
       bio.gff3.record_range, bio.gff3.selection, bio.gff3.record,
       bio.gff3.conv.json, bio.gff3.conv.table, bio.gff3.conv.gff3,
       bio.gff3.conv.gtf;
import util.split_file, util.version_helper;

/**
 * A utility for fetching sequences from GFF3 and FASTA files files.
 *
 *   gff3-ffetch cds path-to-file.fa path-to-file.gff3
 *
 * See package README for more information.
 */

int main(string[] args) {
  // Parse command line arguments
  string output_filename = null;
  bool translate = false;
  bool validate = false;
  bool fix = false;
  bool fix_wormbase = false;
  bool no_assemble = false;
  bool phase = false;
  bool show_version = false;
  bool help = false;
  try {
    getopt(args,
        std.getopt.config.passThrough,
        "output|o", &output_filename,
        "translate", &translate,
        "validate", &validate,
        "fix", &fix,
        "fix-wormbase", &fix_wormbase,
        "no-assemble", &no_assemble,
        "phase", &phase,
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

  // The first argument left should be the feature type
  auto feature_type = toLower(args[1]);
  if ((feature_type != "cds") && (feature_type != "mrna")) {
    writeln("Only CDS and mRNA features are supported at the moment.");
    return 5;
  }

  // The second argument left should be either a FASTA or a GFF3 file
  string fasta_filename;

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
      if (fasta_filename.lenth == 0) {
        fasta_filename = filename;
        continue;
      } else {
        writeln("Only one FASTA file allowed per GFF3");
        print_usage();
        return 6;
      }
    }

    // Prepare for parsing
    RecordRange!SplitFile records;
    string fasta_data;
    if (fasta_filename.length == 0) {
      records = GFF3File.parse_by_records(filename);
      records.set_validate(NO_VALIDATION)
             .set_replace_esc_chars(false)
             .set_keep_comments(false)
             .set_keep_pragmas(false);
      fasta_data = records.get_fasta_data();
    }

    if (no_assemble) {
      FeatureRange features = GFF3File.parse_by_features(filename);
      features.set_validate(NO_VALIDATION)
              .set_replace_esc_chars(false)
              .set_keep_comments(false)
              .set_keep_pragmas(false);
    } else {
      records = GFF3File.parse_by_records(gff3_filename);
      records.set_validate(NO_VALIDATION)
             .set_replace_esc_chars(false)
             .set_keep_comments(false)
             .set_keep_pragmas(false);
    }
  }

  return 0;
}

void print_usage() {
  writeln("Usage: gff3-ffetch [OPTIONS] [FILE1.fa] FILE2.gff3...");
  writeln("Fetch sequences form GFF3 and FASTA files");
  writeln();
  writeln("Options:");
  writeln("  --translate     Output as amino acid sequence.");
  writeln("  --validate      Validate GFF3 file by translating.");
  writeln("  --fix           Check 3-frame translation and fix, if possible.");
  writeln("  --fix-wormbase  Fix 3-frame translation on ORFs named 'gene1'.");
  writeln("  --no-assemble   Output each record as a sequence.");
  writeln("  --phase         Output records using phase (useful w. no-assemble CDS to AA).");
  writeln("  -o, --output    Instead of writing results to stdout, write them to");
  writeln("                  this file.");
  writeln("  --version       Output version information and exit.");
  writeln("  --help          Print this information and exit.");
  writeln();
}

