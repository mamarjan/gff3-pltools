module biohpc.fasta;

import std.conv, std.array, std.stdio, std.algorithm, std.string;
import biohpc.util;

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
      cache = getNextRecord();
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
      cache = getNextRecord();
    return cache is null;
  }

  private {
    alias typeof(SourceRangeType.front()) Array;

    SourceRangeType data;
    FastaRecord cache;

    FastaRecord getNextRecord() {
      auto header = nextFastaLine().idup;
      if (header is null)
        return null;

      FastaRecord result = new FastaRecord();
      static if (is(typeof(data) == LazySplitLines)) {
        result.header = header;
      } else {
        result.header = to!string(header);
      }
      data.popFront();

      auto sequence = appender!Array();
      auto currentFastaLine = nextFastaLine();
      while ((currentFastaLine != null) && (!isFastaHeader(currentFastaLine)) && (!data.empty)) {
        sequence.put(currentFastaLine);
        data.popFront();
        currentFastaLine = nextFastaLine();
      }
      auto fastaSequence = sequence.data;

      static if (is(typeof(data) == LazySplitLines)) {
        result.sequence = fastaSequence;
      } else {
        result.sequence = to!string(fastaSequence);
      }
      return result;
    }

    Array nextFastaLine() {
      if (data.empty)
        return null;
      auto line = data.front;
      while ((isComment(line) || isEmptyLine(line)) && !data.empty) {
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

  bool isFastaHeader(T)(T[] line) {
    return line[0] == '>';
  }

  bool isEmptyLine(T)(T[] line) {
    return line.strip() == "";
  }

  bool isComment(T)(T[] line) {
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

