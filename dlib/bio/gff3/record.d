module bio.gff3.record;

import std.conv, std.stdio, std.array, std.string, std.exception,
       std.ascii, std.algorithm;
import bio.exceptions, bio.gff3.validation, bio.gff3.selection,
       bio.gff3.conv.gff3, bio.gff3.conv.gtf;
import util.esc_char_conv, util.split_line, util.join_fields;

public import bio.gff3.data_formats;

/**
 * Represents a parsed line in a GFF3 file.
 */
class Record {
  enum RecordType {
    REGULAR,
    COMMENT,
    PRAGMA
  }

  /**
   * Constructor for the Record object, arguments are passed to the
   * parse_line() method.
   */
  this(string line, bool replace_esc_chars = true, DataFormat format = DataFormat.GFF3) {
    this.data_format = format;

    if (line_is_pragma(line)) {
      record_type = RecordType.PRAGMA;
      comment_or_pragma = line;
    } else if (line_is_comment(line)) {
      record_type = RecordType.COMMENT;
      comment_or_pragma = line;
    } else {
      record_type = RecordType.REGULAR;
      this.replace_esc_chars = replace_esc_chars;
      if (replace_esc_chars && (std.string.indexOf(line, '%') != -1))
        parse_line_and_replace_esc_chars(line);
      else
        parse_line(line);
    }
  }

  /**
   * Parse a line from a GFF3 or GTF file and set object values.
   */
  void parse_line(string line) {
    seqname = get_and_skip_next_field(line);
    if ((seqname.length == 1) && (seqname[0] == '.')) seqname = null;
    source = get_and_skip_next_field(line);
    if ((source.length == 1) && (source[0] == '.')) source = null;
    feature = get_and_skip_next_field(line);
    if ((feature.length == 1) && (feature[0] == '.')) feature = null;
    start = get_and_skip_next_field(line);
    if ((start.length == 1) && (start[0] == '.')) start = null;
    end = get_and_skip_next_field(line);
    if ((end.length == 1) && (end[0] == '.')) end = null;
    score = get_and_skip_next_field(line);
    if ((score.length == 1) && (score[0] == '.')) score = null;
    strand = get_and_skip_next_field(line);
    if ((strand.length == 1) && (strand[0] == '.')) strand = null;
    phase = get_and_skip_next_field(line);
    if ((phase.length == 1) && (phase[0] == '.')) phase = null;

    if (data_format == DataFormat.GFF3)
      attributes = parse_attributes(get_and_skip_next_field(line));
    else
      attributes = parse_gtf_attributes(line);
  }

  /**
   * Parse a line from a GFF3 or GTF file and set object values.
   * The line is first split into its parts and then escaped
   * characters are replaced in those fields.
   * 
   * Setting replace_esc_chars to false will skip replacing
   * escaped characters, and make parsing faster.
   */
  void parse_line_and_replace_esc_chars(string original_line) {
    char[] line = original_line.dup;

    seqname = cast(string) replace_url_escaped_chars( get_and_skip_next_field(line) );
    if ((seqname.length == 1) && (seqname[0] == '.')) seqname = null;
    source = cast(string) replace_url_escaped_chars( get_and_skip_next_field(line) );
    if ((source.length == 1) && (source[0] == '.')) source = null;
    feature = cast(string) replace_url_escaped_chars( get_and_skip_next_field(line) );
    if ((feature.length == 1) && (feature[0] == '.')) feature = null;
    start = cast(string) get_and_skip_next_field(line);
    if ((start.length == 1) && (start[0] == '.')) start = null;
    end = cast(string) get_and_skip_next_field(line);
    if ((end.length == 1) && (end[0] == '.')) end = null;
    score = cast(string) get_and_skip_next_field(line);
    if ((score.length == 1) && (score[0] == '.')) score = null;
    strand = cast(string) get_and_skip_next_field(line);
    if ((strand.length == 1) && (strand[0] == '.')) strand = null;
    phase = cast(string) get_and_skip_next_field(line);
    if ((phase.length == 1) && (phase[0] == '.')) phase = null;

    if (data_format == DataFormat.GFF3)
      attributes = parse_attributes(get_and_skip_next_field(line));
    else
      attributes = parse_gtf_attributes(line);
  }

  string seqname;
  string source;
  string feature;
  string start;
  string end;
  string score;
  string strand;
  string phase;
  AttributeValue!(string)[string] attributes;
  string comment_or_pragma;

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
  void append_to(Appender!(char[]) app, bool add_newline = false, DataFormat format = DataFormat.DEFAULT) {
    if (is_regular) {
      void append_field(string field_value, InvalidCharProc is_char_invalid) {
        if (field_value.length == 0) {
          app.put(".");
        } else {
          if ((!replace_esc_chars) || (is_char_invalid is null))
            app.put(field_value);
          else
            escape_chars(field_value, is_char_invalid, app);
        }
        app.put('\t');
      }

      append_field(seqname, is_invalid_in_seqname);
      append_field(source, is_invalid_in_any_field);
      append_field(feature, is_invalid_in_any_field);
      append_field(start, null);
      append_field(end, null);
      append_field(score, null);
      append_field(strand, null);
      append_field(phase, null);

      if ((format == DataFormat.GFF3) || ((format == DataFormat.DEFAULT) && (this.data_format == DataFormat.GFF3))) {
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
        if (comment_or_pragma !is null) {
          app.put(comment_or_pragma);
        }
      }
    } else {
      app.put(comment_or_pragma);
    }

    if (add_newline)
      app.put('\n');
  }

  /**
   * The following is required for compiler warnings.
   */
  string toString() {
    if (data_format == DataFormat.GFF3)
      return to_gff3(this);
    else
      return to_gtf(this);
  }

  /**
   * Returns the fields selected by the selector separated by tab
   * characters in one string.
   */
  string to_table(ColumnsSelector selector) {
    return selector(this).join("\t");
  }

  private {
    bool replace_esc_chars;
    RecordType record_type = RecordType.REGULAR;
    DataFormat data_format = DataFormat.GFF3;

    AttributeValue!(string)[string] parse_attributes(string attributes_field) {
      AttributeValue!(string)[string] attributes;
      if (attributes_field[0] != '.') {
        string attribute;
        while(attributes_field.length != 0) {
          attribute = get_and_skip_next_field(attributes_field, ';');
          if (attribute == "") continue;
          auto attribute_name = get_and_skip_next_field( attribute, '=');
          attributes[attribute_name] = AttributeValue!(string)(attribute);
        }
      }
      return attributes;
    }

    AttributeValue!(string)[string] parse_attributes(char[] attributes_field) {
      AttributeValue!(string)[string] attributes;
      if (attributes_field[0] != '.') {
        char[] attribute;
        while(attributes_field.length != 0) {
          attribute = get_and_skip_next_field(attributes_field, ';');
          if (attribute == "") continue;
          auto attribute_name = cast(string) replace_url_escaped_chars( get_and_skip_next_field( attribute, '=') );
          attributes[attribute_name] = AttributeValue!(string)(cast(string)attribute, true);
        }
      }
      return attributes;
    }

    AttributeValue!(string)[string] parse_gtf_attributes(string attributes_field) {
      auto comment_start = std.string.indexOf(attributes_field, '#');
      if (comment_start != -1) {
        this.comment_or_pragma = attributes_field[comment_start..$];
        attributes_field = attributes_field[0..comment_start];
      }
      AttributeValue!(string)[string] attributes;
      if (attributes_field[0] != '.') {
        string attribute;
        while(attributes_field.length != 0) {
          attribute = get_and_skip_next_field(attributes_field, ';');
          if (attribute == "") continue;
          if (attribute[0] == ' ')
            attribute = attribute[1..$];
          auto attribute_name = get_and_skip_next_field( attribute, ' ');
          if (attribute[0] == '"')
            attribute = attribute[1..$];
          if (attribute[$-1] == '"')
            attribute = attribute[0..$-1];
          attributes[attribute_name] = AttributeValue!(string)(attribute);
        }
      }
      return attributes;
    }

    AttributeValue!(string)[string] parse_gtf_attributes(char[] attributes_field) {
      auto comment_start = std.string.indexOf(attributes_field, '#');
      if (comment_start != -1) {
        this.comment_or_pragma = cast(string) (attributes_field[comment_start..$]);
        attributes_field = attributes_field[0..comment_start];
      }
      AttributeValue!(string)[string] attributes;
      if (attributes_field[0] != '.') {
        char[] attribute;
        while(attributes_field.length != 0) {
          attribute = get_and_skip_next_field(attributes_field, ';');
          if (attribute == "") continue;
          auto attribute_name = cast(string) replace_url_escaped_chars( get_and_skip_next_field( attribute, ' ') );
          if (attribute_name[0] == ' ')
            attribute_name = attribute_name[1..$];
          if (attribute[0] == '"')
            attribute = attribute[1..$];
          if (attribute[1] == '"')
            attribute = attribute[0..$-1];
          attributes[attribute_name] = AttributeValue!(string)(cast(string)attribute, true);
        }
      }
      return attributes;
    }


  }
}

/**
 * An attribute in a GFF3 or GTF record can have multiple values, separated by
 * commas. This struct can represent both attribute values with a single value
 * and multiple values.
 */
struct AttributeValue(T) {
  this(T raw_attr_value, bool replace_esc_chars = false) {
    this.esc_chars = replace_esc_chars;
    auto value_count = count_values(raw_attr_value);
    values = new T[value_count];
    foreach(i; 0..value_count)
      values[i] = cast(T) get_and_skip_next_field(raw_attr_value, ',');
    if (replace_esc_chars) {
      foreach(i; 0..value_count) {
        static if (is(T == string))
          values[i] = cast(T) replace_url_escaped_chars(values[i].dup);
        else
          values[i] = replace_url_escaped_chars(values[i]);
      }
    }
  }

  /**
   * Returns true if the attribute has multiple values.
   */
  @property bool is_multi() { return values.length > 1; }

  /**
   * Returns the first attribute value.
   */
  @property T first() {
    return values[0];
  }

  /**
   * Returns all attribute values as a list of strings.
   */
  @property T[] all() {
    return values;
  }

  /**
   * Appends the attribute values to the Appender object app.
   */
  void to_string(ArrayType)(Appender!ArrayType app) {
    T helper(T value) { return escape_chars(value, is_invalid_in_attribute); }
    if (is_multi) {
      if (esc_chars)
        join_fields(map!(helper)(values), ',', app);
      else
        join_fields(values, ',', app);
    } else {
      if (esc_chars)
        escape_chars(first, is_invalid_in_attribute, app);
      else
        app.put(first);
    }
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
    T[] values;

    auto count_values(T)(T raw_attr_value) { 
      return raw_attr_value.count(',') + 1;
    }
  }
}

package {
  bool line_is_pragma(T)(T[] line) {
    return (line.length >= 2) && (line[0..2] == "##");
  }

  bool line_is_comment(T)(T[] line) {
    return (line.length >= 1) && (line[0] == '#') &&
           ((line.length == 1) || (line[1] != '#'));
  }
}

unittest {
  writeln("Testing AttributeValue...");

  auto value = AttributeValue!(string)("abc");
  assert(value.is_multi == false);
  assert(value.first == "abc");
  assert(value.all == ["abc"]);

  value = AttributeValue!(string)("abc%3Df", true);
  assert(value.is_multi == false);
  assert(value.first == "abc=f");
  assert(value.all == ["abc=f"]);
  auto app = appender!string();
  value.to_string(app);
  assert(app.data == "abc%3Df");

  value = AttributeValue!(string)("abc%3Df");
  assert(value.is_multi == false);
  assert(value.first == "abc%3Df");
  assert(value.all == ["abc%3Df"]);
  app = appender!string();
  value.to_string(app);
  assert(app.data == "abc%3Df");

  value = AttributeValue!(string)("ab,cd,e");
  assert(value.is_multi == true);
  assert(value.first == "ab");
  assert(value.all == ["ab", "cd", "e"]);
  app = appender!string();
  value.to_string(app);
  assert(app.data == "ab,cd,e");

  value = AttributeValue!(string)("a%3Db,c%3Bd,e%2Cf,g%26h,ij", true);
  assert(value.is_multi == true);
  assert(value.first == "a=b");
  assert(value.all == ["a=b", "c;d", "e,f", "g&h", "ij"]);
  app = appender!string();
  value.to_string(app);
  writeln(app.data);
  assert(app.data == "a%3Db,c%3Bd,e%2Cf,g%26h,ij");

  value = AttributeValue!(string)("a%3Db,c%3Bd,e%2Cf,g%26h,ij");
  assert(value.is_multi == true);
  assert(value.first == "a%3Db");
  assert(value.all == ["a%3Db", "c%3Bd", "e%2Cf", "g%26h", "ij"]);
  app = appender!string();
  value.to_string(app);
  assert(app.data == "a%3Db,c%3Bd,e%2Cf,g%26h,ij");
}

unittest {
  writeln("Testing parse_attributes...");

  // Minimal test
  auto record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1");
  assert(record.attributes.length == 1);
  assert(record.attributes["ID"].all == ["1"]);
  // Test splitting multiple attributes
  record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=45");
  assert(record.attributes.length == 2);
  assert(record.attributes["ID"].all == ["1"]);
  assert(record.attributes["Parent"].all == ["45" ]);
  // Test if first splitting and then replacing escaped chars
  record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tID%3D=1");
  assert(record.attributes.length == 1);
  assert(record.attributes["ID="].all == ["1"]);
  // Test if parser survives trailing semicolon
  record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=45;");
  assert(record.attributes.length == 2);
  assert(record.attributes["ID"].all == ["1"]);
  assert(record.attributes["Parent"].all == ["45"]);
  // Test for an attribute with the value of a single space
  record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tID= ;");
  assert(record.attributes.length == 1);
  assert(record.attributes["ID"].all == [" " ]);
  // Test for an attribute with no value
  record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=;");
  assert(record.attributes.length == 1);
  assert(record.attributes["ID"].all == [""]);
  // Test for comments on the end of a feature in GTF data
  record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tgene_id \"abc\"; transcript_id \"def\";# test comment", true, DataFormat.GTF);
  assert(record.toString() == ".\t.\t.\t.\t.\t.\t.\t.\tgene_id \"abc\"; transcript_id \"def\";# test comment");
  assert(record.attributes.length == 2);
  assert(record.attributes["gene_id"].first == "abc");
  assert(record.attributes["transcript_id"].first == "def");
}

unittest {
  writeln("Testing parse_gtf_attributes...");
  
  auto record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tgene_id \"abc\"; transcript_id \"def\";", false, DataFormat.GTF);
  assert(record.attributes.length == 2);
  assert(record.gene_id == "abc");
  assert(record.transcript_id == "def");
}

unittest {
  writeln("Testing GFF3 Record...");
  // Test line parsing with a normal line
  auto record = new Record("ENSRNOG00000019422\tEnsembl\tgene\t27333567\t27357352\t1.0\t+\t2\tID=ENSRNOG00000019422;Dbxref=taxon:10116;organism=Rattus norvegicus;chromosome=18;name=EGR1_RAT;source=UniProtKB/Swiss-Prot;Is_circular=true");
  with (record) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["ENSRNOG00000019422", "Ensembl", "gene", "27333567", "27357352", "1.0", "+", "2"]);
    assert(attributes.length == 7);
    assert(attributes["ID"].all == ["ENSRNOG00000019422"]);
    assert(attributes["Dbxref"].all == ["taxon:10116"]);
    assert(attributes["organism"].all == ["Rattus norvegicus"]);
    assert(attributes["chromosome"].all == ["18"]);
    assert(attributes["name"].all == ["EGR1_RAT"]);
    assert(attributes["source"].all == ["UniProtKB/Swiss-Prot"]);
    assert(attributes["Is_circular"].all == ["true"]);
  }

  // Test parsing lines with dots - undefined values
  record = new Record(".\t.\t.\t.\t.\t.\t.\t.\t.");
  with (record) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["", "", "", "", "", "", "", ""]);
    assert(attributes.length == 0);
  }

  // Test parsing lines with escaped characters
  record = new Record("EXON%3D00000131935\tASTD%25\texon%26\t27344088\t27344141\t.\t+\t.\tID=EXON%3D00000131935;Parent=TRAN%3B000000%3D17239");
  with (record) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["EXON=00000131935", "ASTD%", "exon&", "27344088", "27344141", "", "+", ""]);
    assert(attributes.length == 2); 
    assert(attributes["ID"].all == ["EXON=00000131935"]);
    assert(attributes["Parent"].all == ["TRAN;000000=17239"]);
  }

  // Test id() method/property
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1")).id == "1");
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=")).id == "");
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t.")).id is null);

  // Test name() method/property
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\tName=my_name")).name == "my_name");
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\tName=")).name == "");
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t.")).name is null);

  // Test isCircular() method/property
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t.")).is_circular == false);
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\tIs_circular=false")).is_circular == false);
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\tIs_circular=true")).is_circular == true);

  // Test the Parent() method/property
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t.")).parent is null);
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\tParent=test")).parent == "test");
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=test;")).parent == "test");

  // Test to_table conversion
  auto selector = to_selector("seqname,start,end,attr ID");
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t.")).to_table(selector) == "\t\t\t");
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=testing")).to_table(selector) == "\t\t\ttesting");
  assert((new Record("selected\tnothing should change\t.\t.\t.\t.\t.\t.\tID=testing")).to_table(selector) == "selected\t\t\ttesting");
  assert((new Record("selected\t\t.\t123\t456\t.\t.\t.\tID=testing")).to_table(selector) == "selected\t123\t456\ttesting");

  // Test comments
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C")).is_comment == false);
  assert((new Record("# test")).is_comment == true);
  assert((new Record("## test")).is_comment == false);
  assert((new Record("# test")).toString == "# test");

  // Test pragmas
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C")).is_pragma == false);
  assert((new Record("# test")).is_pragma == false);
  assert((new Record("## test")).is_pragma == true);
  assert((new Record("## test")).toString == "## test");

  // Test is_regular
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C")).is_regular == true);
  assert((new Record("# test")).is_regular == false);
  assert((new Record("## test")).is_regular == false);
}

unittest {
  writeln("Testing line_is_comment...");
  assert(line_is_comment("# test") == true);
  assert(line_is_comment("# test\n") == true);

  writeln("Testing line_is_pragma...");
  assert(line_is_pragma("# test") == false);
  assert(line_is_pragma("## test") == true);
  assert(line_is_pragma("test") == false);
  assert(line_is_pragma("### test") == true);
}

