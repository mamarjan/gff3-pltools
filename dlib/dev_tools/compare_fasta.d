import std.string, std.stdio;
import bio.fasta;
import util.split_file;

int main(string[] args) {
  string filename_correct = args[1];
  string filename_to_check = args[2];

  File input_correct = File(filename_correct, "r");
  File input_to_check = File(filename_to_check, "r");

  auto fasta_records = new FastaRange!SplitFile(new SplitFile(input_correct));
  string[string] correct_map;
  foreach(rec; fasta_records) {
    string id = split(rec.header)[0];
    if (id in correct_map) {
      writefln("ID \"%s\" occured more then once in the correct file");
    } else {
      correct_map[id] = rec.sequence;
    }
  }

  ulong count_matches = 0;
  ulong count_all = 0;

  fasta_records = new FastaRange!SplitFile(new SplitFile(input_to_check));
  foreach(rec; fasta_records) {
    string id = split(rec.header)[0];
    if (id in correct_map) {
      count_all += 1;
      if (correct_map[id] == rec.sequence) {
        count_matches += 1;
      }
    } else {
      writeln("Sequence not found in original: ", id);
    }
  }

  writeln("All sequences count: ", count_all);
  writeln("Matching sequences: ", count_matches, ", ", count_matches*100/(cast(double) count_all), "%");

  return 0;
}

