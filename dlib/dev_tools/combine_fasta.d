import std.string, std.stdio;
import bio.fasta;
import util.split_file;

int main(string[] args) {
  string filename_correct = args[1];
  string filename_to_check = args[2];
  string filename_output = args[3];

  File input_correct = File(filename_correct, "r");
  File input_to_check = File(filename_to_check, "r");
  File output = File(filename_output, "w");

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


  fasta_records = new FastaRange!SplitFile(new SplitFile(input_to_check));
  foreach(rec; fasta_records) {
    string id = split(rec.header)[0];
    if (id in correct_map) {
      if (correct_map[id] != rec.sequence) {
        output.writeln('>', rec.header);
        output.writeln("Correct: ", correct_map[id]);
        output.writeln("Wrong:   ", rec.sequence);
      }
    } else {
      writeln("Sequence not found in original: ", id);
    }
  }

  return 0;
}

