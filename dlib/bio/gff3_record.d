module bio.gff3_record;

import std.conv, std.stdio, std.array, std.string, std.exception;
import std.ascii;
import bio.util, bio.exceptions, bio.gff3_validation;

/**
 * Represents a parsed line in a GFF3 file.
 */
struct Record {
  this(string line, RecordValidator validator = EXCEPTIONS_ON_ERROR) {
    parse_line(line, validator);
  }

  /**
   * Parse a line from a GFF3 file and set object values.
   * The line is first split into its parts and then escaped
   * characters are replaced in those fields.
   */
  void parse_line(string line, RecordValidator validator = EXCEPTIONS_ON_ERROR) {
    if (!validator(line))
      return;

    auto parts = split(line, "\t");

    seqname = replace_url_escaped_chars(parts[0]);
    source  = replace_url_escaped_chars(parts[1]);
    feature = replace_url_escaped_chars(parts[2]);
    start   = parts[3];
    end     = parts[4];
    score   = parts[5];
    strand  = parts[6];
    phase   = parts[7];
    parse_attributes(parts[8]);
  }

  string seqname;
  string source;
  string feature;
  string start;
  string end;
  string score;
  string strand;
  string phase;
  string[string] attributes;

  /**
   * Returns the ID attribute from record attributes.
   */
  @property string id() {
    if ("ID" in attributes)
      return attributes["ID"];
    else
      return null;
  }

  /**
   * Returns the Parent attribute from record attributes
   */
  @property string parent() {
    if ("Parent" in attributes)
      return attributes["Parent"];
    else
      return null;
  }

  /**
   * Returns true if the attribute Is_circular is true for
   * this record.
   */
  @property bool is_circular() {
    if ("Is_circular" in attributes)
      return attributes["Is_circular"] == "true";
    else
      return false;
  }

  private {

    void parse_attributes(string attributes_field) {
      if (attributes_field[0] != '.') {
        foreach(attribute; split(attributes_field, ";")) {
          if (attribute == "") continue;
          auto attribute_parts = split(attribute, "=");
          auto attribute_name = replace_url_escaped_chars(attribute_parts[0]);
          auto attribute_value = replace_url_escaped_chars(attribute_parts[1]);
          attributes[attribute_name] = attribute_value;
        }
      }
    }
  }
}

unittest {
  writeln("Testing parseAttributes...");

  // Minimal test
  auto record = Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1");
  assert(record.attributes == [ "ID" : "1" ]);
  // Test splitting multiple attributes
  record = Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=45");
  assert(record.attributes == [ "ID" : "1", "Parent" : "45" ]);
  // Test if first splitting and then replacing escaped chars
  record = Record(".\t.\t.\t.\t.\t.\t.\t.\tID%3D=1");
  assert(record.attributes == [ "ID=" : "1"]);
  // Test if parser survives trailing semicolon
  record = Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=45;");
  assert(record.attributes == [ "ID" : "1", "Parent" : "45" ]);
  // Test for an attribute with the value of a single space
  record = Record(".\t.\t.\t.\t.\t.\t.\t.\tID= ;");
  assert(record.attributes == [ "ID" : " " ]);
  // Test for an attribute with no value
  record = Record(".\t.\t.\t.\t.\t.\t.\t.\tID=;");
  assert(record.attributes == [ "ID" : "" ]);
  // Test for an attribute without a name; should raise an error
  assertThrown!AttributeException(Record(".\t.\t.\t.\t.\t.\t.\t.\t=123"));
  // Test for invalid attribute field
  assertThrown!AttributeException(Record(".\t.\t.\t.\t.\t.\t.\t.\t123"));
  // Test when one attribute ok and a second is invalid
  assertThrown!AttributeException(Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1;123"));
  // Test if two = characters in one attribute
  assertThrown!AttributeException(Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1;1=2=3"));
  // Test with empty string instead of attributes field
  assertThrown!AttributeException(Record(".\t.\t.\t.\t.\t.\t.\t.\t"));
}

unittest {
  writeln("Testing GFF3 Record...");
  // Test line parsing with a normal line
  auto record = Record("ENSRNOG00000019422\tEnsembl\tgene\t27333567\t27357352\t1.0\t+\t2\tID=ENSRNOG00000019422;Dbxref=taxon:10116;organism=Rattus norvegicus;chromosome=18;name=EGR1_RAT;source=UniProtKB/Swiss-Prot;Is_circular=true");
  with (record) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["ENSRNOG00000019422", "Ensembl", "gene", "27333567", "27357352", "1.0", "+", "2"]);
    assert(attributes == [ "ID" : "ENSRNOG00000019422", "Dbxref" : "taxon:10116", "organism" : "Rattus norvegicus", "chromosome" : "18", "name" : "EGR1_RAT", "source" : "UniProtKB/Swiss-Prot", "Is_circular" : "true"]);
  }

  // Test parsing lines with dots - undefined values
  record = Record(".\t.\t.\t.\t.\t.\t.\t.\t.");
  with (record) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           [".", ".", ".", ".", ".", ".", ".", "."]);
    assert(attributes.length == 0);
  }

  // Test parsing lines with escaped characters
  record = Record("EXON%3D00000131935\tASTD%25\texon%26\t27344088\t27344141\t.\t+\t.\tID=EXON%3D00000131935;Parent=TRAN%3B000000%3D17239");
  with (record) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["EXON=00000131935", "ASTD%", "exon&", "27344088", "27344141", ".", "+", "."]);
    assert(attributes == ["ID" : "EXON=00000131935", "Parent" : "TRAN;000000=17239"]);
  }

  // Test id() method/property
  assert(Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1").id == "1");
  assert(Record(".\t.\t.\t.\t.\t.\t.\t.\tID=").id == "");
  assert(Record(".\t.\t.\t.\t.\t.\t.\t.\t.").id is null);

  // Test isCircular() method/property
  assert(Record(".\t.\t.\t.\t.\t.\t.\t.\t.").is_circular == false);
  assert(Record(".\t.\t.\t.\t.\t.\t.\t.\tIs_circular=false").is_circular == false);
  assert(Record(".\t.\t.\t.\t.\t.\t.\t.\tIs_circular=true").is_circular == true);

  // Test the Parent() method/property
  assert(Record(".\t.\t.\t.\t.\t.\t.\t.\t.").parent is null);
  assert(Record(".\t.\t.\t.\t.\t.\t.\t.\tParent=test").parent == "test");
  assert(Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=test;").parent == "test");

  // Testing for invalid values
  // Test for one column missing
  assertThrown!RecordException(Record(".\t..\t.\t.\t.\t.\t.\t."));
  // Test for random text
  assertThrown!RecordException(Record("Test123"));
  // Test for empty columns
  assertThrown!RecordException(Record("\t.\t.\t.\t.\t.\t.\t.\t."));
  assertThrown!RecordException(Record(".\t\t.\t.\t.\t.\t.\t.\t."));
  assertThrown!RecordException(Record(".\t.\t\t.\t.\t.\t.\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t\t.\t.\t.\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t.\t\t.\t.\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t.\t.\t\t.\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t.\t.\t.\t\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t.\t.\t.\t.\t\t."));
  // Test for invalid characters in all fields
  assertThrown!RecordException(Record("\0\t.\t.\t.\t.\t.\t.\t.\t."));
  assertThrown!RecordException(Record(".\t\0\t.\t.\t.\t.\t.\t.\t."));
  assertThrown!RecordException(Record(".\t.\t\0\t.\t.\t.\t.\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t\0\t.\t.\t.\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t.\t\0\t.\t.\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t.\t.\t\0\t.\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t.\t.\t.\t\0\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t.\t.\t.\t.\t\0\t."));
  // Test for invalid characters in seqname
  assertThrown!RecordException(Record(">\t.\t.\t.\t.\t.\t.\t.\t."));
  // Test for start and end fields with invalid values
  assertThrown!RecordException(Record(".\t.\t.\t-5\t.\t.\t.\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t0\t.\t.\t.\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t.\t-4\t.\t.\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t.\t0\t.\t.\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t5\t4\t.\t.\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\ta\t.\t.\t.\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t.\tb\t.\t.\t.\t."));
  // Test for score field with invalid values
  assertThrown!RecordException(Record(".\t.\t.\t.\t.\tabc\t.\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t.\t.\t1.0abc\t.\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t.\t.\tabc1.0\t.\t.\t."));
  // Test for strand field with invalid values
  assertThrown!RecordException(Record(".\t.\t.\t.\t.\t.\t+-\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t.\t.\t.\ta\t.\t."));
  assertThrown!RecordException(Record(".\t.\t.\t.\t.\t.\t+\0\t.\t."));
  // Test for phase field with invalid values
  assertThrown!RecordException(Record(".\t.\t.\t.\t.\t.\t.\ta\t."));
  assertThrown!RecordException(Record(".\t.\t.\t.\t.\t.\t.\t12\t."));
  // Test for invalid values in Is_circular
  assertThrown!AttributeException(Record(".\t.\t.\t.\t.\t.\t.\t.\tIs_circular=invalid"));
}

