module bio.gff3.conv.table;

import std.array, std.stdio;
import bio.gff3.record_range, bio.gff3.selection, bio.gff3.record;

void to_table(GenericRecordRange records, File output, long at_most, string selection, out bool limit_reached = ignore) {
  limit_reached = false;
  ColumnsSelector selector = to_selector(selection);
  string[] columns = split(selection, ",");

  long counter = 0;
  foreach(rec; records) {
    output.writeln(rec.to_table(selector));
    counter += 1;

    if (counter == at_most) {
      output.write("# ...");
      limit_reached = true;
      break;
    }
  }
}

/**
 * Returns the fields selected by the selector separated by tab
 * characters in one string.
 */
string to_table(Record record, ColumnsSelector selector) {
  return selector(record).join("\t");
}

private {
  bool ignore;
}

import bio.gff3.line, bio.gff3.selection;

unittest {
  writeln("Testing to_table...");

  auto selector = to_selector("seqname,start,end,attr ID");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t.")).to_table(selector) == "\t\t\t");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=testing")).to_table(selector) == "\t\t\ttesting");
  assert((parse_line("selected\tnothing should change\t.\t.\t.\t.\t.\t.\tID=testing")).to_table(selector) == "selected\t\t\ttesting");
  assert((parse_line("selected\t\t.\t123\t456\t.\t.\t.\tID=testing")).to_table(selector) == "selected\t123\t456\ttesting");
}

