import std.stdio, std.file, std.conv, std.getopt;
import bio.gff3.file, bio.gff3.validation, bio.gff3.feature,
       bio.gff3.conv.json;
import util.string_hash, util.version_helper;

int main(string[] args) {
  // Parse command line arguments
  string output_filename = null;
  bool keep_fasta = false;
  bool keep_comments = false;
  bool keep_pragmas = false;
  bool json = false;
  bool show_version = false;
  try {
    getopt(args,
        std.getopt.config.passThrough,
        "output|o", &output_filename,
        "keep-fasta", &keep_fasta,
        "keep-comments", &keep_comments,
        "keep-pragmas", &keep_pragmas,
        "json", &json,
        "version", &show_version);
  } catch (Exception e) {
    writeln(e.msg);
    writeln();
    print_usage();
    return 1; // Exit the application
  }

  if (show_version) {
    writeln("gff3-sort (gff3-pltools) " ~ fetch_version());
    return 0;
  }

  // There should be only one filename left
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

  // Prepare File object for output
  File output = stdout;
  if (output_filename !is null) {
    output = File(output_filename, "w");
  }

  // Increase output buffer size
  output.setvbuf(1_048_576);

  // First pass - collecting info
  auto records = GFF3File.parse_by_records(filename);
  records.set_validate(NO_VALIDATION)
         .set_replace_esc_chars(false);
  IDData[string] IDs;
  foreach(rec; records) {
    if (rec.id !is null) {
      if (rec.id in IDs)
        IDs[rec.id.idup].total_records += 1;
      else
        IDs[rec.id.idup] = IDData(1, null);
    }
  }

  // Second pass - collect and output features
  records = GFF3File.parse_by_records(filename);
  records.set_validate(NO_VALIDATION)
         .set_replace_esc_chars(false)
         .set_keep_comments(keep_comments)
         .set_keep_pragmas(keep_pragmas);

  if (json) {
    output.write("{\"features\":[");
  }

  bool first_feature = true;
  foreach(rec; records) {
    if (rec.id is null) {
      if (json) {
        if (!first_feature)
          output.write(',');
        output.write("{\"records\":[");
        output.write(rec.to_json());
        output.write("]}");
      } else {
        output.writeln(rec.toString());
      }
    } else {
      auto tmp = IDs[rec.id];

      if (tmp.feature is null)
        tmp.feature = IDs[rec.id].feature = new Feature(rec);
      else
        tmp.feature.add_record(rec);

      if (tmp.feature.records.length == tmp.total_records) {
        if (json) {
          if (!first_feature)
            output.write(',');
          output.write(tmp.feature.to_json());
        } else {
          output.writeln(tmp.feature.toString());
        }
        IDs.remove(rec.id);
      } else {
        continue;
      }
    }
    first_feature = false;
  }

  if (json) {
    output.write("]}");
  }

  // Print FASTA data if there is any
  if (!json && keep_fasta) {
    auto fasta_data = records.get_fasta_data();
    if (fasta_data !is null) {
      output.writeln("##FASTA");
      output.write(fasta_data);
    }
  }
 
  return 0;
}

struct IDData {
  uint total_records;
  Feature feature;
}

void print_usage() {
  writeln("Usage: count-features [OPTIONS] FILE");
  writeln("Sort features in FILE so that records which are part of the same feature");
  writeln("are in the same place in the file.");
  writeln();
  writeln("Options:");
  writeln("  -o, --output    Instead of writing results to stdout, write them to");
  writeln("                  this file.");
  writeln("  --keep-fasta    Copy FASTA data at the end of input file to output");
  writeln("  --keep-comments Copy comments in GFF3 file to output");
  writeln("  --keep-pragmas  Copy pragmas in GFF3 file to output");
  writeln("  --json          Output data in JSON format");
  writeln("  --version       Output version information and exit.");
  writeln();
}

