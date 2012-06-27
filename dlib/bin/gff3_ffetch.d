import std.stdio, std.file, std.conv, std.getopt;
import bio.gff3.file, bio.gff3.validation, bio.gff3.filtering;
import bio.gff3.record_range;
import util.split_file;

/**
 * A utility for parsing GFF3 files. The only function supported for now is
 * filtering GFF3 files, for example, if your're only interested in CDS,
 * you can use this utility to extract all CDS records from a file like
 * this:
 *
 *   gff3-ffetch --filter type:CDS path-to-file.gff3
 *
 * The output can be parsed using a GFF3 parser library, for example.
 * Another use-case might be looking for records with a particular ID:
 *
 *   gff3-ffetch --filter attrib:ID:gene1 path-to-file.gff3
 *
 * The parser library is written in D and therefore very fast. In normal
 * mode it's not doing any validation, so in case there is a core fault
 * or similar, use the validator utility to check the file for errors.
 *
 * More complicated filtering is currently not supported, but some
 * of the functionality can be added by combining multiple instances
 * and chaining them into unix pipelines.
 */

int main(string[] args) {
  // Parse command line arguments
  string filter_string = null;
  bool inverse_filter = false;
  string output_filename = null;
  try {
    getopt(args,
        std.getopt.config.passThrough,
        "filter|f", &filter_string,
        "inverse|i", &inverse_filter,
        "output|o", &output_file);
  } catch (Exception e) {
    writeln(e.msg);
    writeln();
    print_usage();
    return 1; // Exit the application
  }

  // Only a filename should be left at this point
  auto filename = args[1];
  if (args.length != 2) {
    print_usage();
    return 2; // Exit the application
  }

  // Check if file exists
  alias char[] array;
  if (filename != "-") {
    if (!(to!array(filename).exists)) {
      writeln("Could not find file: " ~ filename ~ "\n");
      print_usage();
      return 3;
    }
  }

  File output = stdout;
  if (output_filename !is null) {
    output = File(output_filename, "w");
  }

  RecordRange!SplitFile records;
  if (filename == "-") {
    records = GFF3File.parse_by_records(stdin,
                                        NO_VALIDATION,
                                        false,
                                        NO_BEFORE_FILTER,
                                        string_to_filter(filter_string));
  } else {
    records = GFF3File.parse_by_records(filename,
                                        NO_VALIDATION,
                                        false,
                                        NO_BEFORE_FILTER,
                                        string_to_filter(filter_string));
  }
  foreach(rec; records) {
    output.writeln(rec.toString());
  }
 
  return 0;
}

void print_usage() {
  writeln("Usage: gff3-ffetch [OPTIONS] FILE");
  writeln("Parse GFF3 file and write records to stdout");
  writeln();
  writeln("Options:");
  writeln("  -f, --filter   A filtering expresion. Only records which match the");
  writeln("                 expression will be passed to stdout");
  writeln("  -i, --inverse  Use inverse the filter expression");
}

