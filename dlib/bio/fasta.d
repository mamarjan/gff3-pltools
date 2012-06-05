module bio.fasta;

import std.conv, std.array, std.stdio, std.algorithm, std.string;
import bio.util;

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
class FastaRange(SourceRangeType) {
  this(SourceRangeType data) {
    this.data = data;
  }

  /**
   * Return the next sequence in range.
   */
  @property FastaRecord front() {
    if (cache is null) {
      cache = get_next_record();
    }
    return cache;
  }

  /**
   * Pops the next sequence in range.
   */
  void popFront() {
    cache = null;
  }

  /**
   * Return true if no more records left in the range.
   */
  @property bool empty() {
    if (cache is null)
      cache = get_next_record();
    return cache is null;
  }

  private {
    alias typeof(SourceRangeType.front()) Array;

    SourceRangeType data;
    FastaRecord cache;

    FastaRecord get_next_record() {
      auto header = next_fasta_line().idup;
      if (header is null)
        return null;

      FastaRecord result = new FastaRecord();
      static if (is(typeof(data) == SplitIntoLines)) {
        result.header = header;
      } else {
        result.header = to!string(header);
      }
      data.popFront();

      auto sequence = appender!Array();
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

    Array next_fasta_line() {
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

private {

  bool is_fasta_header(T)(T[] line) {
    return line[0] == '>';
  }

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


unittest {
  writeln("Testing parsing FASTA data...");

  auto fasta = new FastaRange!(typeof(File.byLine()))(File("./test/data/fasta.fa", "r").byLine());
  assert(fasta.empty == false);
  auto seq1 = fasta.front; fasta.popFront();
  assert(fasta.empty == false);
  auto seq2 = fasta.front; fasta.popFront();
  assert(fasta.empty == true);
  with (seq1) {
    assert(header == ">ctg123");
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
    assert(header == ">cnda0123");
    assert(sequence == (
           "ttcaagtgctcagtcaatgtgattcacagtatgtcaccaaatattttggc" ~
           "agctttctcaagggatcaaaattatggatcattatggaatacctcggtgg" ~
           "aggctcagcgctcgatttaactaaaagtggaaagctggacgaaagtcata" ~
           "tcgctgtgattcttcgcgaaattttgaaaggtctcgagtatctgcatagt" ~
           "gaaagaaaaatccacagagatattaaaggagccaacgttttgttggaccg" ~
           "tcaaacagcggctgtaaaaatttgtgattatggttaaagg"));
  }
}

