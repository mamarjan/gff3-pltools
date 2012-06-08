module bio.gff3_validation;

import std.conv, std.stdio, std.array, std.string, std.exception;
import std.ascii;
import bio.exceptions, util.esc_char_conv, util.split_line;

/**
 * A validator function. It should accept a line in a string value,
 * and return a boolean value. In case the value is true, the parser
 * continues parsing the line, but if it's false, the parser returns
 * a Record object with the default values.
 */
alias bool function(string) RecordValidator;

/**
 * This function will perform validation, and in case there is a problem,
 * it will print the error message to stderr and return false, but there
 * will be no exceptions raised.
 */
auto WARNINGS_ON_ERROR = function bool(string line) {
  bool ok = true;
  try {
    validate_gff3_line(line);
  } catch (ParsingException e) {
    ok = false;
    stderr.writeln(e.msg);
  }
  return ok;
};

/**
 * This function will perform validation, and in case there is a problem,
 * an exception will be thrown. Otherwise true is returned.
 */
auto EXCEPTIONS_ON_ERROR = function bool(string line) {
  validate_gff3_line(line);
  return true;
};

/**
 * This function will perform no validation, and will always return true.
 */
auto NO_VALIDATION = function bool(string line) {
  return true;
};

private:

void validate_gff3_line(string line) {
  check_if_nine_columns_present(line);

  validate_seqname(get_and_skip_next_field(line));
  validate_source(get_and_skip_next_field(line));
  validate_feature(get_and_skip_next_field(line));
  validate_coordinates(get_and_skip_next_field(line), get_and_skip_next_field(line));
  validate_score(get_and_skip_next_field(line));
  validate_strand(get_and_skip_next_field(line));
  validate_phase(get_and_skip_next_field(line));

  validate_attributes(get_and_skip_next_field(line));
}

// Validation of seqname

string valid_seqname_chars = cast(string)(std.ascii.letters ~ std.ascii.digits ~ ".:^*$@!+_?-|%");

void validate_seqname(string seqname) {
  check_if_empty_field("seqname", seqname);
  foreach(character; seqname) {
    if (valid_seqname_chars.indexOf(character) < 0)
      throw new RecordException("Invalid characters in seqname field", seqname);
  }
}

// Validation of source

void validate_source(string source) {
  check_if_empty_field("source", source);
  check_for_characters_invalid_in_any_field("source", source);
}

// Validation of feature

void validate_feature(string feature) {
  check_if_empty_field("feature", feature);
  check_for_characters_invalid_in_any_field("feature", feature);
}

// Validation of start and end fields (coordinates)

void validate_coordinates(string start, string end) {
  check_if_empty_field("start", start);
  check_if_empty_field("end", end);
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


// Validation of score

void validate_score(string score) {
  check_if_empty_field("score", score);
  check_for_characters_invalid_in_any_field("score", score);
  if (score != ".") {
    try {
      to!double(score);
    } catch (ConvException e) {
      throw new RecordException("Score field should contain a float value", score);
    }
  }
}

// Validation of strand

void validate_strand(string strand) {
  check_if_empty_field("strand", strand);
  switch(strand) {
    case "+", "-", "?", ".":
      break; // Strand value valid
    default:
      throw new RecordException("Invalid strand field", strand);
      break;
  }
}

// Validation of phase

void validate_phase(string phase) {
  check_if_empty_field("phase", phase);
  switch(phase) {
    case "0", "1", "2", ".":
      break; // Phase value valid
    default:
      throw new RecordException("Invalid phase field", phase);
      break;
  }
}

// Validate attributes

void validate_attributes(string attributes_field) {
  check_if_empty_field("attributes", attributes_field);
  if (attributes_field != ".") {
    string[string] attributes;
    string attribute = attributes_field;
    while(attributes_field.length != 0) {
      attribute = get_and_skip_next_field(attributes_field, ';');
      if (attribute == "") continue;
      check_if_attribute_has_two_parts(attribute);
      auto attribute_name = replace_url_escaped_chars( get_and_skip_next_field(attribute, '=') );
      auto attribute_value = replace_url_escaped_chars(attribute);
      validate_attribute_name(attribute_name);
      attributes[attribute_name] = attribute_value;
    }
    check_for_invalid_is_circular_value(attributes);
  }
}

void validate_attribute_name(string attribute_name) {
  if (attribute_name.length == 0) // attribute name missing
    throw new AttributeException("An attribute value without an attribute name", attribute_name);
}

void check_if_attribute_has_two_parts(string attribute) {
  if (attribute.count('=') != 1)
    throw new AttributeException("Invalid attribute format", attribute);
}

void check_for_invalid_is_circular_value(string[string] attributes) {
  if ("Is_circular" in attributes) {
    switch (attributes["Is_circular"]) {
      case "true", "false":
      break; // Value valid
    default:
      throw new AttributeException("Ivalid value for Is_circular attribute", attributes["Is_circular"]);
    }
  }
}


// Helper functions

void check_if_nine_columns_present(string line) {
  if (line.count('\t') < 8)
    throw new RecordException("A record with invalid number of columns", line);
}

void check_if_empty_field(string field_name, string field) {
  if (field.length < 1)
    throw new RecordException("Found an empty " ~ field_name ~ " field", field);
}

void check_for_characters_invalid_in_any_field(string field_name, string field) {
  foreach(character; field) {
    if (std.ascii.isControl(character))
      throw new RecordException("Control characters not allowed in field " ~ field_name, field);
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

