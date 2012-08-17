import std.string, std.stdio;
import bio.fasta;
import util.split_file;

int main(string[] args) {
  string filename_input = args[1];
  string filename_output = args[2];

  File input = File(filename_input, "r");
  File output = File(filename_output, "w");

  auto fasta_records = new FastaRange!SplitFile(new SplitFile(input));
  foreach(rec; fasta_records) {
    output.writeln('>', rec.header);
    output.writeln(rec.sequence);
  }

  return 0;
}

