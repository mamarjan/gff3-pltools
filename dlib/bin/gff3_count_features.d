import std.stdio, std.file, std.conv, std.getopt;
import bio.gff3.file, bio.gff3.validation;
import util.string_hash, util.version_helper;

int main(string[] args) {
  // Parse command line arguments
  bool show_version = false;
  try {
    getopt(args,
        std.getopt.config.passThrough,
        "version", &show_version);
  } catch (Exception e) {
    writeln(e.msg);
    writeln();
    print_usage();
    return 1; // Exit the application
  }

  if (show_version) {
    writeln("count-features (gff3-pltools) " ~ fetch_version());
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

  auto records = GFF3File.parse_by_records(filename)
                         .set_validate(NO_VALIDATION)
                         .set_replace_esc_chars(false);
  bool[string] IDs;
  size_t null_IDs = 0;
  foreach(rec; records) {
    if (rec.id is null) {
      null_IDs +=1;
    } else {
      IDs[rec.id.idup] = true;
    }
  }

  writeln("Found " ~ to!string(IDs.length + null_IDs) ~ " features");

  return 0;
}

struct ID {
  int hash;
  string id;
}

void print_usage() {
  writeln("Usage: count-features [OPTIONS] FILE");
  writeln("Count features in FILE correctly");
  writeln();
  writeln("Options:");
  writeln("  --version      Output version information and exit.");
  writeln();
}

