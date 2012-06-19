import std.stdio, std.file, std.conv;
import bio.gff3.file, bio.gff3.validation;
import util.string_hash;

void main(string[] args) {
  // There should be only one command line argument present
  if (args.length != 2) {
    print_usage();
    return; // Exit the application
  }

  auto filename = args[1];

  // Check if file exists
  alias char[] array;
  if (!(to!array(filename).exists)) {
    writeln("Could not find file: " ~ filename ~ "\n");
    print_usage();
    return;

  }

  auto records = GFF3File.parse_by_records(filename,
                                           NO_VALIDATION,
                                           false);

  ID[] IDs;
  size_t null_IDs = 0;
  foreach(rec; records) {
    string rec_id = rec.id;
    int rec_id_hash = hash(rec_id);
    if (rec_id is null)
      null_IDs++;
    else {
      bool found = false;
      foreach(id; IDs) {
        if (id.hash == rec_id_hash) {
          if (id.id == rec_id) {
            found = true;
            break;
          }
        }
      }
      if (!found) {
        IDs ~= ID(rec_id_hash, rec_id.idup);
      }
    }
  }

  writeln("Found " ~ to!string(IDs.length + null_IDs) ~ " features");
}

struct ID {
  int hash;
  string id;
}

void print_usage() {
  writeln("Usage: count-features FILE");
  writeln("Count features in FILE correctly");
  writeln();
}

