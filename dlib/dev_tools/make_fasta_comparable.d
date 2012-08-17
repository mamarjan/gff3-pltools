import std.string, std.stdio;
import bio.fasta;
import util.split_file;

int main(string[] args) {
  string filename_correct = args[1];
  string filename_to_fix = args[2];
  string filename_output = args[3];

  File input_correct = File(filename_correct, "r");
  File input_to_fix = File(filename_to_fix, "r");
  File output = File(filename_output, "w");

  auto fasta_records = new FastaRange!SplitFile(new SplitFile(input_correct));
  string[string] id_list;
  foreach(rec; fasta_records) {
    string id = split(rec.header)[0];
    if (id in id_list) {
      writefln("ID \"%s\" occured more then once in the correct file");
    } else {
      id_list[id] = rec.sequence;
    }
  }

  fasta_records = new FastaRange!SplitFile(new SplitFile(input_to_fix));
  foreach(rec; fasta_records) {
    string id = split(rec.header)[0];
    if (id in id_list) {
      if (id_list[id] == rec.sequence;
      output.writeln('>', rec.header);
      output.writeln(rec.sequence);
    }
  }

  return 0;
}

