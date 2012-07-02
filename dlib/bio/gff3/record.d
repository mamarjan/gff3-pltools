module bio.gff3.record;

import std.conv, std.stdio, std.array, std.string, std.exception;
import std.ascii;
import bio.exceptions, bio.gff3.validation;
import util.esc_char_conv, util.split_line;

/**
 * Represents a parsed line in a GFF3 file.
 */
class Record {
  /**
   * Constructor for the Record object, arguments are passed to the
   * parser_line() method.
   */
  this(string line, bool replace_esc_chars = true) {
    this.replace_esc_chars = replace_esc_chars;
    if (replace_esc_chars && (line.indexOf('%') != -1))
      parse_line_and_replace_esc_chars(line);
    else
      parse_line(line);
  }

  /**
   * Parse a line from a GFF3 file and set object values.
   * The line is first split into its parts and then escaped
   * characters are replaced in those fields.
   * 
   * Setting replace_esc_chars to false will skip replacing
   * escaped characters, and make parsing significantly faster.
   */
  void parse_line(string line) {
    seqname = get_and_skip_next_field(line);
    source = get_and_skip_next_field(line);
    feature = get_and_skip_next_field(line);
    start = get_and_skip_next_field(line);
    end = get_and_skip_next_field(line);
    score = get_and_skip_next_field(line);
    strand = get_and_skip_next_field(line);
    phase = get_and_skip_next_field(line);
    auto attributes_field = get_and_skip_next_field(line);

    attributes = parse_attributes(attributes_field);
  }

  void parse_line_and_replace_esc_chars(string original_line) {
    char[] line = original_line.dup;

    seqname = cast(string) replace_url_escaped_chars( get_and_skip_next_field(line) );
    source = cast(string) replace_url_escaped_chars( get_and_skip_next_field(line) );
    feature = cast(string) replace_url_escaped_chars( get_and_skip_next_field(line) );
    start = cast(string) get_and_skip_next_field(line);
    end = cast(string) get_and_skip_next_field(line);
    score = cast(string) get_and_skip_next_field(line);
    strand = cast(string) get_and_skip_next_field(line);
    phase = cast(string) get_and_skip_next_field(line);
    auto attributes_field = get_and_skip_next_field(line);

    attributes = parse_attributes(attributes_field);
  }

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
   * Returns the ID attribute from record attributes.
   */
  @property string id() {
    if ("ID" in attributes)
      return attributes["ID"].first;
    else
      return null;
  }

  /**
   * Returns the first value of the Parent attribute
   */
  @property string parent() {
    if ("Parent" in attributes)
      return attributes["Parent"].first;
    else
      return null;
  }

  /**
   * Returns all values in the Parent attribute
   */
  @property string[] parents() {
    if ("Parent" in attributes)
      return attributes["Parent"].all;
    else
      return null;
  }

  /**
   * Returns true if the attribute Is_circular is true for
   * this record.
   */
  @property bool is_circular() {
    if ("Is_circular" in attributes)
      return attributes["Is_circular"].first == "true";
    else
      return false;
  }

  /**
   * Converts this object to a GFF3 line.
   */
  string toString() {
    auto result = appender!(char[])();


    void append_field(string field_value, InvalidCharProc is_char_invalid) {
      if (field_value.length == 0) {
        result.put(".");
      } else {
        if ((!replace_esc_chars) || (is_char_invalid is null))
          result.put(field_value);
        else
          append_and_escape_chars(result, field_value, is_char_invalid);
      }
      result.put('\t');
    }

    append_field(seqname, is_invalid_in_seqname);
    append_field(source, is_invalid_in_any_field);
    append_field(feature, is_invalid_in_any_field);
    append_field(start, null);
    append_field(end, null);
    append_field(score, null);
    append_field(strand, null);
    append_field(phase, null);

    if (attributes.length == 0) {
      result.put('.');
    } else {
      bool first_attr = true;
      foreach(attr_name, attr_value; attributes) {
        if (first_attr)
          first_attr = false;
        else
          result.put(';');
        append_and_escape_chars(result, attr_name, is_invalid_in_attribute);
        result.put('=');
        attr_value.append_to_string(result);
      }
    }

    return cast(string)(result.data);
  }

  private {
    bool replace_esc_chars;

    static AttributeValue[string] parse_attributes(string attributes_field) {
      AttributeValue[string] attributes;
      if (attributes_field[0] != '.') {
        string attribute = attributes_field; // Required for the next while loop to start
        while(attributes_field.length != 0) {
          attribute = get_and_skip_next_field(attributes_field, ';');
          if (attribute == "") continue;
          auto attribute_name = get_and_skip_next_field( attribute, '=');
          attributes[attribute_name] = AttributeValue(attribute);
        }
      }
      return attributes;
    }

    static AttributeValue[string] parse_attributes(char[] attributes_field) {
      AttributeValue[string] attributes;
      if (attributes_field[0] != '.') {
        char[] attribute = attributes_field; // Required for the next while loop to start
        while(attributes_field.length != 0) {
          attribute = get_and_skip_next_field(attributes_field, ';');
          if (attribute == "") continue;
          auto attribute_name = cast(string) replace_url_escaped_chars( get_and_skip_next_field( attribute, '=') );
          attributes[attribute_name] = AttributeValue(attribute);
        }
      }
      return attributes;
    }
  }
}

/**
 * An attribute in a GFF3 record can have multiple values, separated by commas.
 * This struct can represent both attribute values with a single value and
 * multiple.
 */
struct AttributeValue {
  /**
   * This constructor doesn't do replacing of escaped characters.
   */
  this(string raw_attr_value) {
    replace_esc_chars = false;
    value_count = count_values(raw_attr_value);
    this.raw_attr_value = raw_attr_value;
    if (is_multi) {
      parsed_attr_values = new string[value_count];
      foreach(i; 0..value_count) {
        parsed_attr_values[i] = get_and_skip_next_field(raw_attr_value, ',');
      }
    }
  }

  /**
   * This constructo replaces escaped characters with their original char values.
   */
  this(char[] raw_attr_value) {
    replace_esc_chars = true;
    value_count = count_values(raw_attr_value);
    if (!is_multi) {
      this.raw_attr_value = cast(string) replace_url_escaped_chars(raw_attr_value);
    } else {
      parsed_attr_values = new string[value_count];
      foreach(i; 0..value_count) {
        parsed_attr_values[i] = cast(string) replace_url_escaped_chars(cast(char[]) get_and_skip_next_field(raw_attr_value, ','));
      }
    }
  }

  /**
   * Returns true if the attribute has multiple values.
   */
  @property bool is_multi() { return (value_count > 1); }

  /**
   * Returns the first attribute value.
   */
  @property string first() {
    return is_multi ? all[0] : raw_attr_value;
  }

  /**
   * Returns all attribute values as a list of strings.
   */
  @property string[] all() {
    if (parsed_attr_values is null)
      parsed_attr_values = [raw_attr_value];
    return parsed_attr_values;
  }

  /**
   * Appends the attribute values to the Appender object app.
   */
  void append_to_string(T)(Appender!T app) {
    if (is_multi) {
      if (replace_esc_chars) {
        bool first_value = true;
        foreach(value; all) {
          if (first_value)
            first_value = false;
          else
            app.put(',');
          append_and_escape_chars(app, value, is_invalid_in_attribute);
        }
      } else {
        app.put(raw_attr_value);
      }
    } else {
      if (replace_esc_chars)
        append_and_escape_chars(app, raw_attr_value, is_invalid_in_attribute);
      else
        app.put(raw_attr_value);
    }
  }

  private {
    bool replace_esc_chars;
    int value_count;
    string raw_attr_value;
    string[] parsed_attr_values;

    int count_values(T)(T attr_value) { 
      return cast(int)(attr_value.count(',')+1);
    }
  }
}


unittest {
  writeln("Testing AttributeValue...");

  auto value = AttributeValue("abc");
  assert(value.is_multi == false);
  assert(value.first == "abc");
  assert(value.all == ["abc"]);

  value = AttributeValue("abc%3Df".dup);
  assert(value.is_multi == false);
  assert(value.first == "abc=f");
  assert(value.all == ["abc=f"]);
  auto app = appender!string();
  value.append_to_string(app);
  assert(app.data == "abc%3Df");

  value = AttributeValue("abc%3Df");
  assert(value.is_multi == false);
  assert(value.first == "abc%3Df");
  assert(value.all == ["abc%3Df"]);
  app = appender!string();
  value.append_to_string(app);
  assert(app.data == "abc%3Df");

  value = AttributeValue("ab,cd,e");
  assert(value.is_multi == true);
  assert(value.first == "ab");
  assert(value.all == ["ab", "cd", "e"]);
  app = appender!string();
  value.append_to_string(app);
  assert(app.data == "ab,cd,e");

  value = AttributeValue("a%3Db,c%3Bd,e%2Cf,g%26h,ij".dup);
  assert(value.is_multi == true);
  assert(value.first == "a=b");
  assert(value.all == ["a=b", "c;d", "e,f", "g&h", "ij"]);
  app = appender!string();
  value.append_to_string(app);
  assert(app.data == "a%3Db,c%3Bd,e%2Cf,g%26h,ij");

  value = AttributeValue("a%3Db,c%3Bd,e%2Cf,g%26h,ij");
  assert(value.is_multi == true);
  assert(value.first == "a%3Db");
  assert(value.all == ["a%3Db", "c%3Bd", "e%2Cf", "g%26h", "ij"]);
  app = appender!string();
  value.append_to_string(app);
  assert(app.data == "a%3Db,c%3Bd,e%2Cf,g%26h,ij");
}

unittest {
  writeln("Testing parseAttributes...");

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
           [".", ".", ".", ".", ".", ".", ".", "."]);
    assert(attributes.length == 0);
  }

  // Test parsing lines with escaped characters
  record = new Record("EXON%3D00000131935\tASTD%25\texon%26\t27344088\t27344141\t.\t+\t.\tID=EXON%3D00000131935;Parent=TRAN%3B000000%3D17239");
  with (record) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["EXON=00000131935", "ASTD%", "exon&", "27344088", "27344141", ".", "+", "."]);
    assert(attributes.length == 2); 
    assert(attributes["ID"].all == ["EXON=00000131935"]);
    assert(attributes["Parent"].all == ["TRAN;000000=17239"]);
  }

  // Test id() method/property
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1")).id == "1");
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=")).id == "");
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t.")).id is null);

  // Test isCircular() method/property
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t.")).is_circular == false);
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\tIs_circular=false")).is_circular == false);
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\tIs_circular=true")).is_circular == true);

  // Test the Parent() method/property
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t.")).parent is null);
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\tParent=test")).parent == "test");
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=test;")).parent == "test");

  // Test toString()
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t.")).toString() == ".\t.\t.\t.\t.\t.\t.\t.\t.");
  assert(((new Record("EXON00000131935\tASTD\texon\t27344088\t27344141\t.\t+\t.\tID=EXON00000131935;Parent=TRAN00000017239")).toString()
          == "EXON00000131935\tASTD\texon\t27344088\t27344141\t.\t+\t.\tID=EXON00000131935;Parent=TRAN00000017239") ||
         ((new Record("EXON00000131935\tASTD\texon\t27344088\t27344141\t.\t+\t.\tID=EXON00000131935;Parent=TRAN00000017239")).toString()
          == "EXON00000131935\tASTD\texon\t27344088\t27344141\t.\t+\t.\tParent=TRAN00000017239;ID=EXON00000131935"));
  record = new Record(".\t.\t.\t.\t.\t.\t.\t.\t.");
  record.score = null;
  assert(record.toString() == ".\t.\t.\t.\t.\t.\t.\t.\t.");

  // Testing toString with escaping of characters
  assert((new Record("%00\t.\t.\t.\t.\t.\t.\t.\t.")).toString() == "%00\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((new Record("%00%01\t.\t.\t.\t.\t.\t.\t.\t.")).toString() == "%00%01\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((new Record("%3E_escaped_gt\t.\t.\t.\t.\t.\t.\t.\t.")).toString() == "%3E_escaped_gt\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((new Record("allowed_chars_0123456789\t.\t.\t.\t.\t.\t.\t.\t.")).toString() == "allowed_chars_0123456789\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((new Record("allowed_chars_abcdefghijklmnopqrstuvwxyz\t.\t.\t.\t.\t.\t.\t.\t.")).toString() == "allowed_chars_abcdefghijklmnopqrstuvwxyz\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((new Record("allowed_chars_.:^*$@!+?-|\t.\t.\t.\t.\t.\t.\t.\t.")).toString() == "allowed_chars_.:^*$@!+?-|\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((new Record("%7F\t.\t.\t.\t.\t.\t.\t.\t.")).toString() == "%7F\t.\t.\t.\t.\t.\t.\t.\t.");
  assert((new Record(".\t%7F\t.\t.\t.\t.\t.\t.\t.")).toString() == ".\t%7F\t.\t.\t.\t.\t.\t.\t.");
  assert((new Record(".\t.\t%7F\t.\t.\t.\t.\t.\t.")).toString() == ".\t.\t%7F\t.\t.\t.\t.\t.\t.");

  // The following fields should not contain any escaped characters, so to get
  // maximum speed they're not even checked for escaped chars, that means they
  // are stored as they are. toString() should not replace '%' with it's escaped
  // value in those fields.
  assert((new Record(".\t.\t.\t%7F\t.\t.\t.\t.\t.")).toString() == ".\t.\t.\t%7F\t.\t.\t.\t.\t.");
  assert((new Record(".\t.\t.\t.\t%7F\t.\t.\t.\t.")).toString() == ".\t.\t.\t.\t%7F\t.\t.\t.\t.");
  assert((new Record(".\t.\t.\t.\t.\t%7F\t.\t.\t.")).toString() == ".\t.\t.\t.\t.\t%7F\t.\t.\t.");
  assert((new Record(".\t.\t.\t.\t.\t.\t%7F\t.\t.")).toString() == ".\t.\t.\t.\t.\t.\t%7F\t.\t.");
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t%7F\t.")).toString() == ".\t.\t.\t.\t.\t.\t.\t%7F\t.");

  // Test toString with escaping of characters in the attributes
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t%3D=%3D")).toString() == ".\t.\t.\t.\t.\t.\t.\t.\t%3D=%3D");
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t%3B=%3B")).toString() == ".\t.\t.\t.\t.\t.\t.\t.\t%3B=%3B");
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C")).toString() == ".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C");
  assert((new Record(".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C;%3B=%3B")).toString() == ".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C;%3B=%3B");
}

