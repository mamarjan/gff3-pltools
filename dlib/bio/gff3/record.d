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

    _attributes = parse_attributes(attributes_field);
  }

  string seqname;
  string source;
  string feature;
  string start;
  string end;
  string score;
  string strand;
  string phase;

  /**
   * Returns the ID attribute from record attributes.
   */
  @property string id() {
    if ("ID" in _attributes)
      return _attributes["ID"].get_first();
    else
      return null;
  }

  /**
   * Returns the Parent attribute from record attributes
   */
  @property string parent() {
    if ("Parent" in _attributes)
      return _attributes["Parent"].get_first();
    else
      return null;
  }

  /**
   * Returns all values in the Parent attribute
   */
  @property string[] parents() {
    if ("Parent" in _attributes)
      return _attributes["Parent"].get_all();
    else
      return null;
  }


  /**
   * Returns true if the attribute Is_circular is true for
   * this record.
   */
  @property bool is_circular() {
    if ("Is_circular" in _attributes)
      return _attributes["Is_circular"] == "true";
    else
      return false;
  }

  /**
   * Converts this object to a GFF3 line.
   */
  string toString() {
    auto result = appender!(char[])();

    void append_and_escape_chars(string field_value, InvalidCharProc is_invalid) {
      if ((is_invalid is null) || (!replace_esc_chars)) {
        result.put(field_value);
      } else {
        foreach(character; field_value) {
          if (is_invalid(character) || (character == '%')) {
            result.put('%');
            result.put(upper_4bits_to_hex(character));
            result.put(lower_4bits_to_hex(character));
          } else {
            result.put(character);
          }
        }
      }
    }

    void append_field(string field_value, InvalidCharProc is_char_invalid) {
      if (field_value.length == 0) {
        result.put(".");
      } else {
        append_and_escape_chars(field_value, is_char_invalid);
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

    if (_attributes.length == 0) {
      result.put('.');
    } else {
      bool first_attr = true;
      foreach(attr_name, attr_value; _attributes) {
        if (first_attr)
          first_attr = false;
        else
          result.put(';');
        append_and_escape_chars(attr_name, is_invalid_in_attribute);
        result.put('=');
        append_and_escape_chars(attr_value, is_invalid_in_attribute);
      }
    }

    return cast(string)(result.data);
  }

  private {
    struct AttributeValue {
      this(string raw_attr_value) {
        this.raw_attr_value = raw_attr_value;
        value_count = raw_attr_value.count(',');
        if (value_count == 1) {
          if (this.raw_attr_value.indexOf('%') != -1) {
            this.raw_attr_value = replace_url_escaped_chars(cast(char[]) this.raw_attr_value);
          }
        }
      }

      bool is_multi() { value_count > 1; }

      string get_first(string attr_name) {
        if (is_multi()) {
          return get_all[0];
        } else {
          return raw_attr_value;
        }
      }

      string[] get_all() {
        if (parsed_attr_values is null) {
          if (value_count == 1) {
            parsed_attr_values = [raw_attr_value];
          } else {
            foreach(i; 0..value_count) {
              parsed_attr_values ~= replace_url_escaped_chars(cast(char[]) get_and_skip_next_field(raw_attr_value, ','))
            }
          }
        }
        return parsed_attr_values;
      }

      private {
        int value_count;
        string raw_attr_value;
        string[] parsed_attr_values;
      }
    }

    bool replace_esc_chars;
    AttributeValue[string] _attributes;

    static string[string] parse_attributes(string attributes_field) {
      string[string] attributes;
      if (attributes_field[0] != '.') {
        string attribute = attributes_field; // Required for the next while loop to start
        while(attributes_field.length != 0) {
          attribute = get_and_skip_next_field(attributes_field, ';');
          if (attribute == "") continue;
          auto attribute_name = get_and_skip_next_field( attribute, '=');
          auto attribute_value = attribute;
          attributes[attribute_name] = attribute_value;
        }
      }
      return attributes;
    }

    static string[string] parse_attributes(char[] attributes_field) {
      string[string] attributes;
      if (attributes_field[0] != '.') {
        char[] attribute = attributes_field; // Required for the next while loop to start
        while(attributes_field.length != 0) {
          attribute = get_and_skip_next_field(attributes_field, ';');
          if (attribute == "") continue;
          auto attribute_name = cast(string) replace_url_escaped_chars( get_and_skip_next_field( attribute, '=') );
          auto attribute_value = cast(string) replace_url_escaped_chars( attribute );
          attributes[attribute_name] = attribute_value;
        }
      }
      return attributes;
    }
  }
}

unittest {
  writeln("Testing parseAttributes...");

  // Minimal test
  auto record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1");
  assert(record.attributes == [ "ID" : "1" ]);
  // Test splitting multiple attributes
  record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=45");
  assert(record.attributes == [ "ID" : "1", "Parent" : "45" ]);
  // Test if first splitting and then replacing escaped chars
  record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tID%3D=1");
  assert(record.attributes == [ "ID=" : "1"]);
  // Test if parser survives trailing semicolon
  record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=45;");
  assert(record.attributes == [ "ID" : "1", "Parent" : "45" ]);
  // Test for an attribute with the value of a single space
  record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tID= ;");
  assert(record.attributes == [ "ID" : " " ]);
  // Test for an attribute with no value
  record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=;");
  assert(record.attributes == [ "ID" : "" ]);
}

unittest {
  writeln("Testing GFF3 Record...");
  // Test line parsing with a normal line
  auto record = new Record("ENSRNOG00000019422\tEnsembl\tgene\t27333567\t27357352\t1.0\t+\t2\tID=ENSRNOG00000019422;Dbxref=taxon:10116;organism=Rattus norvegicus;chromosome=18;name=EGR1_RAT;source=UniProtKB/Swiss-Prot;Is_circular=true");
  with (record) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["ENSRNOG00000019422", "Ensembl", "gene", "27333567", "27357352", "1.0", "+", "2"]);
    assert(attributes == [ "ID" : "ENSRNOG00000019422", "Dbxref" : "taxon:10116", "organism" : "Rattus norvegicus", "chromosome" : "18", "name" : "EGR1_RAT", "source" : "UniProtKB/Swiss-Prot", "Is_circular" : "true"]);
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
    assert(attributes == ["ID" : "EXON=00000131935", "Parent" : "TRAN;000000=17239"]);
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

