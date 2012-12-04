module bio.gff3.conv.gtf;

import std.stdio, std.array;
import bio.gff3.record_range, bio.gff3.record, bio.gff3.conv.gff3,
       bio.gff3.validation;
import util.esc_char_conv;

private {
  bool ignore;
}

void to_gtf(RecordRange records, File output, long at_most = -1, out bool limit_reached = ignore) {
  limit_reached = false;
  long counter = 0;
  foreach(rec; records) {
    output.writeln(rec.to_gtf());
    counter += 1;

    // Check if the "at_most" limit has been reached
    if (counter == at_most) {
      output.write("# ...");
      limit_reached = true;
      break;
    }
  }
}

/**
 * Converts record to a GTF line.
 */
string to_gtf(Record record) {
  if (record.is_regular) {
    auto result = appender!(string)();
    record.to_gtf(false, result);
    return cast(string)(result.data);
  } else if (record.is_comment) {
    return record.comment_text;
  } else if (record.is_pragma) {
    return record.pragma_text;
  } else {
    return null;
  }
}


/**
 * Converts a record to a string representstion in GTF format,
 * and appends the result to an Appender object.
 */
void to_gtf(Record record, bool add_newline, Appender!string app) {
  with (record) {
    if (is_regular) {
      bio.gff3.conv.gff3.append_fields(record, app);
      append_attributes(record, app);

      if (comment_text.length > 0)
        app.put(comment_text);
    } else if (is_comment) {
      app.put(comment_text);
    } else if (is_pragma) {
      app.put(pragma_text);
    }
  }

  if (add_newline)
    app.put('\n');
}

void append_attributes(T)(Record record, Appender!T app) {
  // Print attributes in GTF style
  with (record) {
    app.put("gene_id \"");
    if ("gene_id" in attributes)
      app.put(attributes["gene_id"].first);
    app.put("\"; transcript_id \"");
    if ("transcript_id" in attributes)
      app.put(attributes["transcript_id"].first);
    app.put("\";");
    foreach(attr_name, attr_value; attributes) {
      if ((attr_name != "gene_id") && (attr_name != "transcript_id")) {
        app.put(' ');
        escape_chars(attr_name, is_invalid_in_attribute, app);
        app.put(" \"");
        attr_value.to_string(app);
        app.put("\";");
      }
    }
  }
}

import bio.gff3.line;

unittest {
  // Test to_gtf() with GTF data
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tgene_id \"abc\"; transcript_id \"def\";", true, DataFormat.GTF)).to_gtf() == ".\t.\t.\t.\t.\t.\t.\t.\tgene_id \"abc\"; transcript_id \"def\";");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tgene_id \"abc\"; transcript_id \"def\"; test_attr \"gha\";", true, DataFormat.GTF)).to_gtf() == ".\t.\t.\t.\t.\t.\t.\t.\tgene_id \"abc\"; transcript_id \"def\"; test_attr \"gha\";");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tgene_id \"abc\"; transcript_id \"def\"; test_attr 1;", true, DataFormat.GTF)).to_gtf() == ".\t.\t.\t.\t.\t.\t.\t.\tgene_id \"abc\"; transcript_id \"def\"; test_attr \"1\";");

}

