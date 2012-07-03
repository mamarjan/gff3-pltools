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

  auto records = GFF3File.parse_by_records(filename,
                                           NO_VALIDATION,
                                           false);
  size_t records_counter = 0;
  foreach(rec; records) { if (rec.id !is null) records_counter++; }

  records = GFF3File.parse_by_records(filename,
                                      NO_VALIDATION,
                                      false);
  ID[] IDs = new ID[records_counter];
  size_t null_IDs = 0;
  size_t id_counter = 0;
  foreach(rec; records) {
    string rec_id = rec.id;
    int rec_id_hash = hash(rec_id);
    if (rec_id is null)
      null_IDs++;
    else {
      bool found = false;
      foreach(id; IDs[0..id_counter]) {
        if (id.hash == rec_id_hash) {
          if (id.id == rec_id) {
            found = true;
            break;
          }
        }
      }
      if (!found) {
        IDs[id_counter] = ID(rec_id_hash, rec_id.idup);
        id_counter++;
      }
    }
  }

  writeln("Found " ~ to!string(id_counter + null_IDs) ~ " features");

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

