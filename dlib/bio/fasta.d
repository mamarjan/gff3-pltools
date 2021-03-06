module bio.fasta;

import std.conv, std.array, std.stdio, std.algorithm, std.string;
import util.split_into_lines, util.range_with_cache, util.lines_range;

/**
 * A minimal class for grouping the header and sequence
 * data of a FASTA sequence.
 */
class FastaRecord {
  string header;
  string sequence;
}

/**
 * Fasta range for FASTA sequences appended to the end of GFF3 data.
 */
class FastaRange : RangeWithCache!FastaRecord {
  this(LinesRange data) {
    this.data = data;
  }

  /**
   * Return all remaining sequences as a dictionary.
   */
  @property string[string] all() {
    string[string] all_data;
    foreach(rec; this) {
      auto id = split(rec.header)[0];
      all_data[id] = rec.sequence;
    }

    return all_data;
  }

  private {
    LinesRange data;

    protected FastaRecord next_item() {
      auto header = next_fasta_line().idup;
      if (header is null)
        return null;

      FastaRecord result = new FastaRecord();
      static if (is(typeof(data) == SplitIntoLines)) {
        result.header = header[1..$];
      } else {
        result.header = to!string(header[1..$]);
      }
      data.popFront();

      auto sequence = appender!string();
      auto current_fasta_line = next_fasta_line();
      while ((current_fasta_line != null) && (!is_fasta_header(current_fasta_line)) && (!data.empty)) {
        sequence.put(current_fasta_line);
        data.popFront();
        current_fasta_line = next_fasta_line();
      }
      auto fasta_sequence = sequence.data;

      static if (is(typeof(data) == SplitIntoLines)) {
        result.sequence = fasta_sequence;
      } else {
        result.sequence = to!string(fasta_sequence);
      }
      return result;
    }

    string next_fasta_line() {
      if (data.empty)
        return null;
      auto line = data.front;
      while ((is_comment(line) || is_empty_line(line)) && !data.empty) {
        data.popFront();
        if (!data.empty)
          line = data.front;
      }
      if (data.empty)
        return null;
      else
        return line;
    }
  }
}

bool is_fasta_header(T)(T[] line) {
  return line[0] == '>';
}

private {

  bool is_empty_line(T)(T[] line) {
    return line.strip() == "";
  }

  bool is_comment(T)(T[] line) {
    if (line.length >= 1)
      return line[0] == ';';
    else
      return false;
  }
}

version (unittest) {
  import util.split_file;
}

unittest {
  auto fasta = new FastaRange(new SplitFile(File("./test/data/fasta.fa", "r")));
  assert(fasta.empty == false);
  auto seq1 = fasta.front; fasta.popFront();
  assert(fasta.empty == false);
  auto seq2 = fasta.front; fasta.popFront();
  assert(fasta.empty == true);
  with (seq1) {
    assert(header == "ctg123");
    assert(sequence == (
           "cttctgggcgtacccgattctcggagaacttgccgcaccattccgccttg" ~
           "tgttcattgctgcctgcatgttcattgtctacctcggctacgtgtggcta" ~
           "tctttcctcggtgccctcgtgcacggagtcgagaaaccaaagaacaaaaa" ~
           "aagaaattaaaatatttattttgctgtggtttttgatgtgtgttttttat" ~
           "aatgatttttgatgtgaccaattgtacttttcctttaaatgaaatgtaat" ~
           "cttaaatgtatttccgacgaattcgaggcctgaaaagtgtgacgccattc" ~
           "gtatttgatttgggtttactatcgaataatgagaattttcaggcttaggc" ~
           "ttaggcttaggcttaggcttaggcttaggcttaggcttaggcttaggctt" ~
           "aggcttaggcttaggcttaggcttaggcttaggcttaggcttaggcttag" ~
           "aatctagctagctatccgaaattcgaggcctgaaaagtgtgacgccattc" ));
  }
  with (seq2) {
    assert(header == "cnda0123");
    assert(sequence == (
           "ttcaagtgctcagtcaatgtgattcacagtatgtcaccaaatattttggc" ~
           "agctttctcaagggatcaaaattatggatcattatggaatacctcggtgg" ~
           "aggctcagcgctcgatttaactaaaagtggaaagctggacgaaagtcata" ~
           "tcgctgtgattcttcgcgaaattttgaaaggtctcgagtatctgcatagt" ~
           "gaaagaaaaatccacagagatattaaaggagccaacgttttgttggaccg" ~
           "tcaaacagcggctgtaaaaatttgtgattatggttaaagg"));
  }
}

