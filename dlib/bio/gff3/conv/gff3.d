module bio.gff3.conv.gff3;

import std.stdio, std.array;
import bio.gff3.record_range, bio.gff3.record, bio.gff3.validation;
import util.esc_char_conv;

private {
  bool ignore;
}

void to_gff3(RecordRange records, File output, long at_most = -1, out bool limit_reached = ignore) {
  limit_reached = false;
  long counter = 0;
  foreach(rec; records) {
    output.writeln(rec.to_gff3());
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
 * Converts record to a GFF3 line.
 */
string to_gff3(Record record) {
  if (record.is_regular) {
    auto result = appender!(string)();
    record.to_gff3(false, result);
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
 * Converts a record to a string representstion in GFF3 format,
 * and appends the result to an Appender object.
 */
void to_gff3(Record record, bool add_newline, Appender!string app) {
  with (record) {
    if (is_regular) {
      append_fields(record, app);
      append_attributes(record, app);
    } else if (is_comment) {
      app.put(comment_text);
    } else if (is_pragma) {
      app.put(pragma_text);
    }
  }

  if (add_newline)
    app.put('\n');
}

void append_fields(T)(Record record, Appender!T app) {
    void append_field(string field_value, InvalidCharProc is_char_invalid) {
      if (field_value.length == 0)
        app.put(".");
      else
        escape_chars(field_value, is_char_invalid, app);
      app.put('\t');
    }

    with(record) {
      append_field(seqname, esc_chars ? is_invalid_in_seqname : null);
      append_field(source, esc_chars ? is_invalid_in_any_field : null);
      append_field(feature, esc_chars ? is_invalid_in_any_field : null);
      append_field(start, esc_chars ? is_invalid_in_any_field : null);
      append_field(end, esc_chars ? is_invalid_in_any_field : null);
      append_field(score, esc_chars ? is_invalid_in_any_field : null);
      append_field(strand, esc_chars ? is_invalid_in_any_field : null);
      append_field(phase, esc_chars ? is_invalid_in_any_field : null);
    }
}

void append_attributes(T)(Record record, Appender!T app) {
  if (record.attributes.length == 0) {
    app.put('.');
  } else {
    bool first_attr = true;
    foreach(attr_name, attr_value; record.attributes) {
      if (first_attr)
        first_attr = false;
      else
        app.put(';');
      escape_chars(attr_name, is_invalid_in_attribute, app);
      app.put('=');
      attr_value.to_string(app);
    }
  }
}

import bio.gff3.line;

unittest {
  // Testing to_gff3()
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
