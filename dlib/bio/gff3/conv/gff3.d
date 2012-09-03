module bio.gff3.conv.gff3;

import std.stdio, std.array;
import bio.gff3.record_range, bio.gff3.record;

bool to_gff3(GenericRecordRange records, File output, long at_most = -1) {
  long counter = 0;
  foreach(rec; records) {
    output.writeln(rec.to_gff3());
    counter += 1;

    // Check if the "at_most" limit has been reached
    if (counter == at_most) {
      output.write("# ...");
      return true;
    }
  }

  return false;
}

/**
 * Converts record to a GFF3 line.
 */
string to_gff3(Record record) {
  if (record.is_regular) {
    auto result = appender!(char[])();
    record.append_to(result, false, DataFormat.GFF3);
    return cast(string)(result.data);
  } else {
    return record.comment_or_pragma;
  }
}

unittest {
  // Test to_gff3()
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t.")).to_gff3() == ".\t.\t.\t.\t.\t.\t.\t.\t.");
  assert(((new Record("EXON00000131935\tASTD\texon\t27344088\t27344141\t.\t+\t.\tID=EXON00000131935;Parent=TRAN00000017239")).to_gff3()
          == "EXON00000131935\tASTD\texon\t27344088\t27344141\t.\t+\t.\tID=EXON00000131935;Parent=TRAN00000017239") ||
         ((new Record("EXON00000131935\tASTD\texon\t27344088\t27344141\t.\t+\t.\tID=EXON00000131935;Parent=TRAN00000017239")).to_gff3()
          == "EXON00000131935\tASTD\texon\t27344088\t27344141\t.\t+\t.\tParent=TRAN00000017239;ID=EXON00000131935"));
  auto record = new Record(".\t.\t.\t.\t.\t.\t.\t.\t.");
  record.score = null;
  assert(record.to_gff3() == ".\t.\t.\t.\t.\t.\t.\t.\t.");

  // Testing to_gff3() with escaping of characters
  assert((new Record("%00\t.\t.\t.\t.\t.\t.\t.\t.")).to_gff3() == "%00\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((new Record("%00%01\t.\t.\t.\t.\t.\t.\t.\t.")).to_gff3() == "%00%01\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((new Record("%3E_escaped_gt\t.\t.\t.\t.\t.\t.\t.\t.")).to_gff3() == "%3E_escaped_gt\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((new Record("allowed_chars_0123456789\t.\t.\t.\t.\t.\t.\t.\t.")).to_gff3() == "allowed_chars_0123456789\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((new Record("allowed_chars_abcdefghijklmnopqrstuvwxyz\t.\t.\t.\t.\t.\t.\t.\t.")).to_gff3() == "allowed_chars_abcdefghijklmnopqrstuvwxyz\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((new Record("allowed_chars_.:^*$@!+?-|\t.\t.\t.\t.\t.\t.\t.\t.")).to_gff3() == "allowed_chars_.:^*$@!+?-|\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((new Record("%7F\t.\t.\t.\t.\t.\t.\t.\t.")).to_gff3() == "%7F\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((new Record(".\t%7F\t.\t.\t.\t.\t.\t.\t.")).to_gff3() == ".\t%7F\t.\t.\t.\t.\t.\t.\t.");
  assert((new Record(".\t.\t%7F\t.\t.\t.\t.\t.\t.")).to_gff3() == ".\t.\t%7F\t.\t.\t.\t.\t.\t.");

  // The following fields should not contain any escaped characters, so to get
  // maximum speed they're not even checked for escaped chars, that means they
  // are stored as they are. to_gff3() should not replace '%' with it's escaped
  // value in those fields.
  assert((new Record(".\t.\t.\t%7F\t.\t.\t.\t.\t.")).to_gff3() == ".\t.\t.\t%7F\t.\t.\t.\t.\t.");
  assert((new Record(".\t.\t.\t.\t%7F\t.\t.\t.\t.")).to_gff3() == ".\t.\t.\t.\t%7F\t.\t.\t.\t.");
  assert((new Record(".\t.\t.\t.\t.\t%7F\t.\t.\t.")).to_gff3() == ".\t.\t.\t.\t.\t%7F\t.\t.\t.");
  assert((new Record(".\t.\t.\t.\t.\t.\t%7F\t.\t.")).to_gff3() == ".\t.\t.\t.\t.\t.\t%7F\t.\t.");
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t%7F\t.")).to_gff3() == ".\t.\t.\t.\t.\t.\t.\t%7F\t.");

  // Test to_gff3() with escaping of characters in the attributes
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t%3D=%3D")).to_gff3() == ".\t.\t.\t.\t.\t.\t.\t.\t%3D=%3D");
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t%3B=%3B")).to_gff3() == ".\t.\t.\t.\t.\t.\t.\t.\t%3B=%3B");
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C")).to_gff3() == ".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C");
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C;%3B=%3B")).to_gff3() == ".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C;%3B=%3B");

}
