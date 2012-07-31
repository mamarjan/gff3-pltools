module bio.gff3.conv.table;

import std.array, std.stdio;
import bio.gff3.record_range, bio.gff3.selection;

bool to_table(GenericRecordRange records, File output, long at_most, string selection) {
  ColumnsSelector selector = to_selector(selection);
  string[] columns = split(selection, ",");

  long counter = 0;
  foreach(rec; records) {
    output.writeln(rec.to_table(selector));
    counter += 1;

    if (counter == at_most) {
      output.write("# ...");
      return true;
    }
  }

  return false;
}

