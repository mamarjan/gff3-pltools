module bio.gff3.record;

import std.conv, std.stdio, std.array, std.string, std.exception,
       std.ascii, std.algorithm;
import bio.exceptions, bio.gff3.validation, bio.gff3.selection,
       bio.gff3.conv.gff3, bio.gff3.conv.gtf, bio.gff3.line;
import util.esc_char_conv, util.split_line, util.join_fields;

public import bio.gff3.data_formats;

enum RecordType {
  REGULAR,
  COMMENT,
  PRAGMA
}

/**
 * Represents a parsed line in a GFF3 file.
 */
class Record {

  RecordType record_type = RecordType.REGULAR;
  string pragma_text;
  string comment_text;

  string seqname;
  string source;
  string feature;
  string start;
  string end;
  string score;
  string strand;
  string phase;
  AttributeValue[string] attributes;

  /**
   * Accessor methods for most important attributes:
   */
  @property string   id()             { return ("ID" in attributes)            ? attributes["ID"].first                      : null;  }
  @property string   name()           { return ("Name" in attributes)          ? attributes["Name"].first                    : null;  }
  @property string   alias_attr()     { return ("Alias" in attributes)         ? attributes["Alias"].first                   : null;  }
  @property string[] aliases()        { return ("Alias" in attributes)         ? attributes["Alias"].all                     : null;  }
  @property string   parent()         { return ("Parent" in attributes)        ? attributes["Parent"].first                  : null;  }
  @property string[] parents()        { return ("Parent" in attributes)        ? attributes["Parent"].all                    : null;  }
  @property string   target()         { return ("Target" in attributes)        ? attributes["Target"].first                  : null;  }
  @property string   gap()            { return ("Gap" in attributes)           ? attributes["Gap"].first                     : null;  }
  @property string   derives_from()   { return ("Derives_from" in attributes)  ? attributes["Derives_from"].first            : null;  }
  @property string   note()           { return ("Note" in attributes)          ? attributes["Note"].first                    : null;  }
  @property string[] notes()          { return ("Note" in attributes)          ? attributes["Note"].all                      : null;  }
  @property string   dbxref()         { return ("Dbxref" in attributes)        ? attributes["Dbxref"].first                  : null;  }
  @property string[] dbxrefs()        { return ("Dbxref" in attributes)        ? attributes["Dbxref"].all                    : null;  }
  @property string   ontology_term()  { return ("Ontology_term" in attributes) ? attributes["Ontology_term"].first           : null;  }
  @property string[] ontology_terms() { return ("Ontology_term" in attributes) ? attributes["Ontology_term"].all             : null;  }
  @property bool     is_circular()    { return ("Is_circular" in attributes)   ? (attributes["Is_circular"].first == "true") : false; }

  /**
   * Accessor methods for GTF attributes:
   */
  @property string   gene_id()        { return ("gene_id" in attributes)       ? attributes["gene_id"].first                 : null;  }
  @property string   transcript_id()  { return ("transcript_id" in attributes) ? attributes["transcript_id"].first           : null;  }

  /**
   * A record can be a comment, a pragma, or a regular record. Use these
   * functions to test for the type of a record.
   */
  @property bool is_regular() { return record_type == RecordType.REGULAR; }
  @property bool is_comment() { return record_type == RecordType.COMMENT; }
  @property bool is_pragma() { return record_type == RecordType.PRAGMA; }

  /**
   * Converts the record to a string representstion, which can be a GFF3
   * or GTF line, and then appends the result to an Appender object.
   */
  void append_to(Appender!(char[]) app, bool add_newline = false, DataFormat format = DataFormat.GFF3) {
    if (is_regular) {
      void append_field(string field_value, InvalidCharProc is_char_invalid) {
        if (field_value.length == 0) {
          app.put(".");
        } else {
          if ((!esc_chars) || (is_char_invalid is null))
            app.put(field_value);
          else
            escape_chars(field_value, is_char_invalid, app);
        }
        app.put('\t');
      }

      append_field(seqname, is_invalid_in_seqname);
      append_field(source, is_invalid_in_any_field);
      append_field(feature, is_invalid_in_any_field);
      append_field(start, is_invalid_in_any_field);
      append_field(end, is_invalid_in_any_field);
      append_field(score, is_invalid_in_any_field);
      append_field(strand, is_invalid_in_any_field);
      append_field(phase, is_invalid_in_any_field);

      if (format == DataFormat.GFF3) {
        // Print attributes in GFF3 style
        if (attributes.length == 0) {
          app.put('.');
        } else {
          bool first_attr = true;
          foreach(attr_name, attr_value; attributes) {
            if (first_attr)
              first_attr = false;
            else
              app.put(';');
            escape_chars(attr_name, is_invalid_in_attribute, app);
            app.put('=');
            attr_value.to_string(app);
          }
        }
      } else {
        // Print attributes in GTF style
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
        if (comment_text !is null) {
          app.put(comment_text);
        }
      }
    } else if (is_comment) {
      app.put(comment_text);
    } else if (is_pragma) {
      app.put(pragma_text);
    }

    if (add_newline)
      app.put('\n');
  }

  /**
   * The following is required for compiler warnings.
   */
  string toString() {
    return to_gff3(this);
  }

  /**
   * Returns the fields selected by the selector separated by tab
   * characters in one string.
   */
  string to_table(ColumnsSelector selector) {
    return selector(this).join("\t");
  }

  bool esc_chars;
}

/**
 * An attribute in a GFF3 or GTF record can have multiple values, separated by
 * commas. This struct can represent both attribute values with a single value
 * and multiple values.
 */
struct AttributeValue {
  this(string[] values, bool esc_chars) {
    this.values = values;
    this.esc_chars = esc_chars;
  }

  /**
   * Returns true if the attribute has multiple values.
   */
  @property bool is_multi() { return values.length > 1; }

  /**
   * Returns the first attribute value.
   */
  @property string first() {
    return values[0];
  }

  /**
   * Returns all attribute values as a list of strings.
   */
  @property string[] all() {
    return values;
  }

  /**
   * Appends the attribute values to the Appender object app.
   */
  void to_string(ArrayType)(Appender!ArrayType app) {
    string helper(string value) {
      return escape_chars(value, is_invalid_in_attribute);
    }

    if (esc_chars)
      join_fields(map!(helper)(values), ',', app);
    else
      join_fields(values, ',', app);
  }

  /**
   * Converts the attribute value to string.
   */
  string toString() {
    auto app = appender!(char[])();
    this.to_string(app);
    return cast(string)(app.data);
  }

  private {
    bool esc_chars;
    string[] values;
  }
}

unittest {
  writeln("Testing AttributeValue...");

  // Testing to_string()/toString()
  auto value = parse_attr_value("abc%3Df", true);
  auto app = appender!string();
  value.to_string(app);
  assert(app.data == "abc%3Df");

  value = parse_attr_value("abc%3Df", false);
  assert(value.toString() == "abc%3Df");

  value = parse_attr_value("ab,cd,e");
  app = appender!string();
  value.to_string(app);
  assert(app.data == "ab,cd,e");

  value = parse_attr_value("a%3Db,c%3Bd,e%2Cf,g%26h,ij", true);
  app = appender!string();
  value.to_string(app);
  assert(app.data == "a%3Db,c%3Bd,e%2Cf,g%26h,ij");

  value = parse_attr_value("a%3Db,c%3Bd,e%2Cf,g%26h,ij", false);
  app = appender!string();
  value.to_string(app);
  assert(app.data == "a%3Db,c%3Bd,e%2Cf,g%26h,ij");
}

unittest {
  writeln("Testing GFF3 Record...");

  // Test id() method/property
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1")).id == "1");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=")).id == "");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t.")).id is null);

  // Test name() method/property
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tName=my_name")).name == "my_name");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tName=")).name == "");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t.")).name is null);

  // Test isCircular() method/property
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t.")).is_circular == false);
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tIs_circular=false")).is_circular == false);
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tIs_circular=true")).is_circular == true);

  // Test the Parent() method/property
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t.")).parent is null);
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tParent=test")).parent == "test");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=test;")).parent == "test");

  // Test to_table conversion
  auto selector = to_selector("seqname,start,end,attr ID");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t.")).to_table(selector) == "\t\t\t");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=testing")).to_table(selector) == "\t\t\ttesting");
  assert((parse_line("selected\tnothing should change\t.\t.\t.\t.\t.\t.\tID=testing")).to_table(selector) == "selected\t\t\ttesting");
  assert((parse_line("selected\t\t.\t123\t456\t.\t.\t.\tID=testing")).to_table(selector) == "selected\t123\t456\ttesting");

  // Test is_comment
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C")).is_comment == false);
  assert((parse_line("# test")).is_comment == true);
  assert((parse_line("## test")).is_comment == false);
  assert((parse_line("# test")).toString == "# test");

  // Test is_pragma
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C")).is_pragma == false);
  assert((parse_line("# test")).is_pragma == false);
  assert((parse_line("## test")).is_pragma == true);
  assert((parse_line("## test")).toString == "## test");

  // Test is_regular
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C")).is_regular == true);
  assert((parse_line("# test")).is_regular == false);
  assert((parse_line("## test")).is_regular == false);
}

