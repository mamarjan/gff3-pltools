import std.stdio, std.string;

import bio.fasta;
import util.split_file;

int main(string[] args) {
  string filename = args[1];

  File input = File(filename, "r");

  auto fasta_records = new FastaRange!SplitFile(new SplitFile(input));

  ulong count_sequences = 0;
  ulong count_atg_starts = 0;
  ulong count_taa_ends = 0;
  ulong count_tga_ends = 0;
  ulong count_tag_ends = 0;
  ulong count_length_ok = 0;

  ulong count_stop_codons = 0;
  ulong count_seq_with_stop_codons = 0;

  foreach(rec; fasta_records) {
    auto line = rec.sequence;
    if (line[$-1] == '\n')
      line = line[0..$-1];
    if (line.length == 0)
      continue;
    count_sequences += 1;
    if ((line[0..3] == "ATG") || (line[0..3] == "atg")) {
      count_atg_starts += 1;
    }
    switch(line[($-3)..$]) {
      case "TAA", "taa":
        count_taa_ends += 1;
        break;
      case "TGA", "tga":
        count_tga_ends += 1;
        break;
      case "TAG", "tag":
        count_taa_ends += 1;
        break;
      default:
        break;
    }
    if ((line.length % 3) == 0) {
      count_length_ok += 1;
    }

    bool valid_sequence = true;
    while(line.length > 5) {
      switch(line[0..3]) {
        case "TAA", "taa":
        case "TGA", "tga":
        case "TAG", "tag":
          count_stop_codons += 1;
          valid_sequence = false;
          break;
        default:
          break;
      }
      line = line[3..$];
    }

    if (!valid_sequence) {
      count_seq_with_stop_codons += 1;
    }
  }

  writeln("Number of sequences: ", count_sequences);
  writeln("Number of valid starts: ", count_atg_starts, ", ", count_atg_starts*100/(cast(double) count_sequences), "%");
  writeln("Number of valid seq ends: ", count_taa_ends + count_tga_ends + count_tag_ends, ", ", (count_taa_ends + count_tga_ends + count_tag_ends)*100/(cast(double) count_sequences),"%");
  writeln("Number of valid lengths: ", count_length_ok, ", ", count_length_ok*100/(cast(double) count_sequences),"%");
  writeln("Total stop codons in sequences: ", count_stop_codons);
  writeln("Sequences with premature stop codons: ", count_seq_with_stop_codons, ", ", count_seq_with_stop_codons*100/(cast(double) count_sequences),"%");

  return 0;
}

