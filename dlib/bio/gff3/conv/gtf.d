module bio.gff3.conv.gtf;

import std.stdio, std.array;
import bio.gff3.record_range, bio.gff3.record;

bool to_gtf(GenericRecordRange records, File output, long at_most = -1) {
  long counter = 0;
  foreach(rec; records) {
    output.writeln(rec.to_gtf());
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
 * Converts record to a GTF line.
 */
string to_gtf(Record record) {
  if (record.is_regular) {
    auto result = appender!(char[])();
    record.append_to(result, false, DataFormat.GTF);
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
  writeln("Testing to_gtf()...");

  // Test to_gtf() with GTF data
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tgene_id \"abc\"; transcript_id \"def\";", true, DataFormat.GTF)).to_gtf() == ".\t.\t.\t.\t.\t.\t.\t.\tgene_id \"abc\"; transcript_id \"def\";");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tgene_id \"abc\"; transcript_id \"def\"; test_attr \"gha\";", true, DataFormat.GTF)).to_gtf() == ".\t.\t.\t.\t.\t.\t.\t.\tgene_id \"abc\"; transcript_id \"def\"; test_attr \"gha\";");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tgene_id \"abc\"; transcript_id \"def\"; test_attr 1;", true, DataFormat.GTF)).to_gtf() == ".\t.\t.\t.\t.\t.\t.\t.\tgene_id \"abc\"; transcript_id \"def\"; test_attr \"1\";");

}

