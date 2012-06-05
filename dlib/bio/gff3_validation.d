module bio.gff3_validation;

import std.conv, std.stdio, std.array, std.string, std.exception;
import std.ascii;
import bio.exceptions, util.esc_char_conv;

alias bool function(string) RecordValidator;

auto WARNINGS_ON_ERROR = function bool(string line) {
  try {
    validate_gff3_line(line);
  } catch (ParsingException e) {
    stderr.writeln(e.msg);
  }
  return true;
};

auto EXCEPTIONS_ON_ERROR = function bool(string line) {
  validate_gff3_line(line);
  return true;
};

auto NO_VALIDATION = function bool(string line) {
  return true;
};


void validate_gff3_line(string line) {
  check_if_nine_columns_present(line);
  auto parts = split(line, "\t");

  check_for_empty_fields(parts);
  check_if_valid_seqname(parts[0]);
  check_for_characters_invalid_in_any_field("source", parts[1]);
  check_for_characters_invalid_in_any_field("feature", parts[2]);
  check_if_coordinates_valid(parts[3], parts[4]);
  check_if_score_valid(parts[5]);
  check_if_strand_valid(parts[6]);
  check_if_phase_valid(parts[7]);

  validate_attributes(parts[8]);
}

void validate_attributes(string attributes_field) {
  if (attributes_field[0] != '.') {
    string[string] attributes;
    foreach(attribute; split(attributes_field, ";")) {
      if (attribute == "") continue;
      check_if_attribute_has_two_parts(attribute);
      check_if_attribute_name_valid(attribute);
      auto attribute_parts = split(attribute, "=");
      auto attribute_name = replace_url_escaped_chars(attribute_parts[0]);
      auto attribute_value = replace_url_escaped_chars(attribute_parts[1]);
      attributes[attribute_name] = attribute_value;
    }
    check_for_invalid_is_circular_values(attributes);
  }
}

void check_if_attribute_has_two_parts(string attribute) {
  if (attribute.count('=') != 1)
    throw new AttributeException("Invalid attribute format", attribute);
}

void check_if_attribute_name_valid(string attribute) {
  if (attribute.indexOf("=") == 0) // attribute name missing
    throw new AttributeException("An attribute value without an attribute name", attribute);
}

void check_for_invalid_is_circular_values(string[string] attributes) {
  if ("Is_circular" in attributes) {
    switch (attributes["Is_circular"]) {
      case "true", "false":
      break; // Value valid
    default:
      throw new AttributeException("Ivalid value for Is_circular attribute", attributes["Is_circular"]);
    }
  }
}

void check_if_nine_columns_present(string line) {
  if (line.count("\t") < 8)
    throw new RecordException("A record with invalid number of columns", line);
}

void check_for_empty_fields(string[] fields) {
  foreach(i; 0..9) {
    if (fields[i].length < 1)
      throw new RecordException("Found an empty field in record", fields.join("\t"));
  }
}

void check_if_valid_seqname(string seqname) {
  string valid_seqname_chars = cast(immutable(char)[])(std.ascii.letters ~ std.ascii.digits ~ ".:^*$@!+_?-|%");
  foreach(character; seqname) {
    if (valid_seqname_chars.indexOf(character) < 0)
      throw new RecordException("Invalid characters in seqname field", seqname);
  }
}

void check_for_characters_invalid_in_any_field(string field_name, string field) {
  foreach(character; field) {
    if (std.ascii.isControl(character))
      throw new RecordException("Control characters not allowed in field " ~ field_name, field);
  }
}

void check_if_coordinates_valid(string start, string end) {
  if (start != ".") {
    foreach(character; start) {
      if (!(character.isDigit()))
        throw new RecordException("Only a dot or digits are allowed in field start", start);
    }
    if (to!long(start) < 1)
      throw new RecordException("Start field can't be a number less then 1", start);
  }
  if (end != ".") {
    foreach(character; start) {
      if (!(character.isDigit()))
        throw new RecordException("Only a dot or digits are allowed in field end", end);
    }
    if (to!long(end) < 1)
      throw new RecordException("End field can't be a number less then 1", start);
  }
  if ((start != ".") && (end != ".")) {
    auto start_value = to!long(start);
    auto end_value = to!long(end);
    if (start_value > end_value)
      throw new RecordException("End can't be less then start field", "start=" ~ start ~ ", end=" ~ end);
  }
}

void check_if_score_valid(string score) {
  check_for_characters_invalid_in_any_field("score", score);
  if (score != ".") {
    try {
      to!double(score);
    } catch (ConvException e) {
      throw new RecordException("Score field should contain a float value", score);
    }
  }
}

void check_if_strand_valid(string strand) {
  switch(strand) {
    case "+", "-", "?", ".":
      break; // Strand value valid
    default:
      throw new RecordException("Invalid strand field", strand);
      break;
  }
}

void check_if_phase_valid(string phase) {
  switch(phase) {
    case "0", "1", "2", ".":
      break; // Phase value valid
    default:
      throw new RecordException("Invalid phase field", phase);
      break;
  }
}

unittest {
  writeln("Testing validate_gff3_line...");

  // Minimal test
  assertNotThrown(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  // Test splitting multiple attributes
  assertNotThrown(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=45"));
  // Test if parser survives trailing semicolon
  assertNotThrown(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=45;"));
  // Test if first splitting and then replacing escaped chars
  assertNotThrown(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID%3D=1"));
  // Test for an attribute with the value of a single space
  assertNotThrown(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID= ;"));
  // Test for an attribute with no value
  assertNotThrown(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID=;"));
  // Test parsing lines with dots - undefined values
  assertNotThrown(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\t."));
  assertNotThrown(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID="));
  assertNotThrown(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tIs_circular=false"));
  assertNotThrown(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tIs_circular=true"));
  // Test line parsing with a normal line
  assertNotThrown(validate_gff3_line("ENSRNOG00000019422\tEnsembl\tgene\t27333567\t27357352\t1.0\t+\t2\tID=ENSRNOG00000019422;Dbxref=taxon:10116;organism=Rattus norvegicus;chromosome=18;name=EGR1_RAT;source=UniProtKB/Swiss-Prot;Is_circular=true"));
  // Test parsing lines with escaped characters
  assertNotThrown(validate_gff3_line("EXON%3D00000131935\tASTD%25\texon%26\t27344088\t27344141\t.\t+\t.\tID=EXON%3D00000131935;Parent=TRAN%3B000000%3D17239"));
  assertNotThrown(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tParent=test"));
  assertNotThrown(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=test;"));

  // Testing for invalid values
  // Test for an attribute without a name; should raise an error
  assertThrown!AttributeException(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\t=123"));
  // Test for invalid attribute field
  assertThrown!AttributeException(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\t123"));
  // Test when one attribute ok and a second is invalid
  assertThrown!AttributeException(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1;123"));
  // Test if two = characters in one attribute
  assertThrown!AttributeException(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1;1=2=3"));
  // Test with empty string instead of attributes field
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\t"));
  // Test for one column missing
  assertThrown!RecordException(validate_gff3_line(".\t..\t.\t.\t.\t.\t.\t."));
  // Test for random text
  assertThrown!RecordException(validate_gff3_line("Test123"));
  // Test for empty columns
  assertThrown!RecordException(validate_gff3_line("\t.\t.\t.\t.\t.\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t\t.\t.\t.\t.\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t\t.\t.\t.\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t\t.\t.\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t\t.\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t.\t\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t.\t.\t\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t\t."));
  // Test for invalid characters in all fields
  assertThrown!RecordException(validate_gff3_line("\0\t.\t.\t.\t.\t.\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t\0\t.\t.\t.\t.\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t\0\t.\t.\t.\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t\0\t.\t.\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t\0\t.\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t.\t\0\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t.\t.\t\0\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t\0\t."));
  // Test for invalid characters in seqname
  assertThrown!RecordException(validate_gff3_line(">\t.\t.\t.\t.\t.\t.\t.\t."));
  // Test for start and end fields with invalid values
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t-5\t.\t.\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t0\t.\t.\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t-4\t.\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t0\t.\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t5\t4\t.\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\ta\t.\t.\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\tb\t.\t.\t.\t."));
  // Test for score field with invalid values
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t.\tabc\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t.\t1.0abc\t.\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t.\tabc1.0\t.\t.\t."));
  // Test for strand field with invalid values
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t.\t.\t+-\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t.\t.\ta\t.\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t.\t.\t+\0\t.\t."));
  // Test for phase field with invalid values
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\ta\t."));
  assertThrown!RecordException(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t12\t."));
  // Test for invalid values in Is_circular
  assertThrown!AttributeException(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tIs_circular=invalid"));
}

