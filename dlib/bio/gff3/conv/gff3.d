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
  } else if (record.is_comment) {
    return record.comment_text;
  } else if (record.is_pragma) {
    return record.pragma_text;
  } else {
    return null;
  }
}

import bio.gff3.line;

unittest {
  writeln("Testing to_gff3()...");

  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t.")).to_gff3() == ".\t.\t.\t.\t.\t.\t.\t.\t.");
  assert(((parse_line("EXON00000131935\tASTD\texon\t27344088\t27344141\t.\t+\t.\tID=EXON00000131935;Parent=TRAN00000017239")).to_gff3()
          == "EXON00000131935\tASTD\texon\t27344088\t27344141\t.\t+\t.\tID=EXON00000131935;Parent=TRAN00000017239") ||
         ((parse_line("EXON00000131935\tASTD\texon\t27344088\t27344141\t.\t+\t.\tID=EXON00000131935;Parent=TRAN00000017239")).to_gff3()
          == "EXON00000131935\tASTD\texon\t27344088\t27344141\t.\t+\t.\tParent=TRAN00000017239;ID=EXON00000131935"));
  auto record = parse_line(".\t.\t.\t.\t.\t.\t.\t.\t.");
  record.score = null;
  assert(record.to_gff3() == ".\t.\t.\t.\t.\t.\t.\t.\t.");

  // Testing to_gff3() with escaping of characters
  assert((parse_line("%00\t.\t.\t.\t.\t.\t.\t.\t.")).to_gff3() == "%00\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((parse_line("%00%01\t.\t.\t.\t.\t.\t.\t.\t.")).to_gff3() == "%00%01\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((parse_line("%3E_escaped_gt\t.\t.\t.\t.\t.\t.\t.\t.")).to_gff3() == "%3E_escaped_gt\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((parse_line("allowed_chars_0123456789\t.\t.\t.\t.\t.\t.\t.\t.")).to_gff3() == "allowed_chars_0123456789\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((parse_line("allowed_chars_abcdefghijklmnopqrstuvwxyz\t.\t.\t.\t.\t.\t.\t.\t.")).to_gff3() == "allowed_chars_abcdefghijklmnopqrstuvwxyz\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((parse_line("allowed_chars_.:^*$@!+?-|\t.\t.\t.\t.\t.\t.\t.\t.")).to_gff3() == "allowed_chars_.:^*$@!+?-|\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((parse_line("%7F\t.\t.\t.\t.\t.\t.\t.\t.")).to_gff3() == "%7F\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((parse_line(".\t%7F\t.\t.\t.\t.\t.\t.\t.")).to_gff3() == ".\t%7F\t.\t.\t.\t.\t.\t.\t.");
  assert((parse_line(".\t.\t%7F\t.\t.\t.\t.\t.\t.")).to_gff3() == ".\t.\t%7F\t.\t.\t.\t.\t.\t.");
  assert((parse_line(".\t.\t.\t%7F\t.\t.\t.\t.\t.")).to_gff3() == ".\t.\t.\t%7F\t.\t.\t.\t.\t.");
  assert((parse_line(".\t.\t.\t.\t%7F\t.\t.\t.\t.")).to_gff3() == ".\t.\t.\t.\t%7F\t.\t.\t.\t.");
  assert((parse_line(".\t.\t.\t.\t.\t%7F\t.\t.\t.")).to_gff3() == ".\t.\t.\t.\t.\t%7F\t.\t.\t.");
  assert((parse_line(".\t.\t.\t.\t.\t.\t%7F\t.\t.")).to_gff3() == ".\t.\t.\t.\t.\t.\t%7F\t.\t.");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t%7F\t.")).to_gff3() == ".\t.\t.\t.\t.\t.\t.\t%7F\t.");

  // Test to_gff3() with escaping of characters in the attributes
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t%3D=%3D")).to_gff3() == ".\t.\t.\t.\t.\t.\t.\t.\t%3D=%3D");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t%3B=%3B")).to_gff3() == ".\t.\t.\t.\t.\t.\t.\t.\t%3B=%3B");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C")).to_gff3() == ".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C;%3B=%3B")).to_gff3() == ".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C;%3B=%3B");

}
