module bio.gff3_file;

import std.conv, std.stdio, std.array, std.string, std.range, std.exception;
import std.ascii;
import bio.fasta, bio.exceptions, bio.gff3_record, bio.gff3_validation;
import util.join_lines, util.split_into_lines, util.read_file;
import util.range_with_cache, util.split_file;

auto open(string filename) {
  return new RecordRange!(SplitFile)(new SplitFile(File(filename, "r")));
}

class RecordRange(SourceRangeType) : RangeWithCache!Record {
  this(SourceRangeType data) {
    this.data = data;
  }

  protected Record next_item() {
    auto line = data.front;
    data.popFront();
    return new Record(to!string(line));
  }

  private {
    SourceRangeType data;
  }
}

