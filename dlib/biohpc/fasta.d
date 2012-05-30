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
    return getNextRecord() is null;
  }

  private {
    alias typeof(SourceRangeType.front()) Array;

    SourceRangeType data;
    FastaRecord cache;

    FastaRecord getNextRecord() {
      auto header = nextFastaLine();
      data.popFront();

      Array[] sequence = [];
      auto currentFastaLine = nextFastaLine();
      while ((currentFastaLine != null) && (!isFastaHeader(currentFastaLine))) {
        sequence ~= currentFastaLine;
        data.popFront();
        currentFastaLine = nextFastaLine();
      }
      auto fastaSequence = join(sequence);

      FastaRecord result = new FastaRecord();
      static if (is(typeof(data) == LazySplitLines)) {
        result.header = header;
        result.sequence = fastaSequence;
      } else {
        result.header = to!string(header);
        result.sequence = to!string(fastaSequence);
      }
      return result;
    }

    Array nextFastaLine() {
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
    return line[0] == ';';
  }
}

