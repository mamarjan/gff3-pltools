module bio.gff3.validation;

import std.conv, std.stdio, std.array, std.string, std.exception;
import std.ascii;
import bio.exceptions, util.split_line;

string replace_url_escaped_chars(string original) {
  auto index = indexOf(original, '%');
  if (index < 0) {
    return original;
  } else {
    return original[0..index] ~
           convert_url_escaped_char(original[index+1..index+3]) ~
           replace_url_escaped_chars(original[index+3..$]);
  }
}

char convert_url_escaped_char(string code) {
   // First check if code valid
  if (code.length != 2)
    throw new ConvException("Invalid URL escaped code: " ~ code);
  foreach(character; code)
    if (std.ascii.fullHexDigits.indexOf(character) == -1)
      throw new ConvException("Invalid URL escaped code: " ~ code);

  uint numeric = to!int(code, 16);
  return cast(char) numeric;
}

/**
 * A validator function. It should accept a line in a string value,
 * and return a boolean value. In case the value is true, the parser
 * continues parsing the line, but if it's false, the parser returns
 * a Record object with the default values.
 */
alias bool function(string filename, int line_number, string line) RecordValidator;

/**
 * This function will perform validation, and in case there is a problem,
 * it will print the error message to stderr and return false, but there
 * will be no exceptions raised.
 */
auto WARNINGS_ON_ERROR = function bool(string filename, int line_number, string line) {
  auto error_msg = validate_gff3_line(line);
  if (error_msg !is null)
    stderr.writeln(addFilenameAndLine(filename, line_number, error_msg));
  return error_msg is null;
};

/**
 * This function will perform validation, and in case there is a problem,
 * an exception will be thrown. Otherwise true is returned.
 */
auto EXCEPTIONS_ON_ERROR = function bool(string filename, int line_number, string line) {
  auto error_msg = validate_gff3_line(line);
  if (!(error_msg is null))
    throw new ParsingException(addFilenameAndLine(filename, line_number, error_msg));
  return true;
};

/**
 * This function will perform no validation, and will always return true.
 */
auto NO_VALIDATION = function bool(string filename, int line_number, string line) {
  return true;
};

private:

string addFilenameAndLine(string filename, int line_number, string error_msg) {
  return filename ~ "(" ~ to!string(line_number) ~ "): " ~ error_msg;
}

string validate_gff3_line(string line) {
  auto error_msg = check_if_nine_columns_present(line);

  if (error_msg is null) error_msg = validate_seqname(get_and_skip_next_field(line));
  if (error_msg is null) error_msg = validate_source(get_and_skip_next_field(line));
  if (error_msg is null) error_msg = validate_feature(get_and_skip_next_field(line));
  if (error_msg is null) error_msg = validate_coordinates(get_and_skip_next_field(line), get_and_skip_next_field(line));
  if (error_msg is null) error_msg = validate_score(get_and_skip_next_field(line));
  if (error_msg is null) error_msg = validate_strand(get_and_skip_next_field(line));
  if (error_msg is null) error_msg = validate_phase(get_and_skip_next_field(line));

  if (error_msg is null) error_msg = validate_attributes(get_and_skip_next_field(line));

  return error_msg;
}

// Validation of seqname

string valid_seqname_chars = cast(string)(std.ascii.letters ~ std.ascii.digits ~ ".:^*$@!+_?-|%");

string validate_seqname(string seqname) {
  auto error_msg = check_if_empty_field("seqname", seqname);
  if (error_msg is null) {
    foreach(character; seqname) {
      if (valid_seqname_chars.indexOf(character) < 0) {
        error_msg = "Invalid characters in seqname field";
        break;
      }
    }
  }
  return error_msg;
}

// Validation of source

string validate_source(string source) {
  auto error_msg = check_if_empty_field("source", source);
  if (error_msg is null) 
    error_msg = check_for_characters_invalid_in_any_field("source", source);
  return error_msg;
}

// Validation of feature

string validate_feature(string feature) {
  auto error_msg = check_if_empty_field("feature", feature);
  if (error_msg is null)
    error_msg = check_for_characters_invalid_in_any_field("feature", feature);
  return error_msg;
}

// Validation of start and end fields (coordinates)

string validate_coordinates(string start, string end) {
  auto error_msg = check_if_empty_field("start", start);
  if (!(error_msg is null)) return error_msg;

  error_msg = check_if_empty_field("end", end);
  if (!(error_msg is null)) return error_msg;

  if (start != ".") {
    foreach(character; start) {
      if (!(character.isDigit()))
        return "Only a dot or digits are allowed in field start";
    }
    if (to!long(start) < 1)
      return "Start field can't be a number less then 1";
  }
  if (end != ".") {
    foreach(character; start) {
      if (!(character.isDigit()))
        return "Only a dot or digits are allowed in field end";
    }
    if (to!long(end) < 1)
      return "End field can't be a number less then 1";
  }
  if ((start != ".") && (end != ".")) {
    auto start_value = to!long(start);
    auto end_value = to!long(end);
    if (start_value > end_value)
      return "End can't be less then start field";
  }
  return null;
}


// Validation of score

string validate_score(string score) {
  string error_msg = check_if_empty_field("score", score);
  if (!(error_msg is null)) return error_msg;

  error_msg = check_for_characters_invalid_in_any_field("score", score);
  if (error_msg is null) {
    if (score != ".") {
      try {
        to!double(score);
      } catch (ConvException e) {
        error_msg = "Score field should contain a float value";
      }
    }
  }
  return error_msg;
}

// Validation of strand

string validate_strand(string strand) {
  string error_msg = check_if_empty_field("strand", strand);
  if (error_msg is null) {
    switch(strand) {
      case "+", "-", "?", ".":
        break; // Strand value valid
      default:
        error_msg = "Invalid strand field";
        break;
    }
  }
  return error_msg;
}

// Validation of phase

string validate_phase(string phase) {
  auto error_msg = check_if_empty_field("phase", phase);
  if (error_msg is null) {
    switch(phase) {
      case "0", "1", "2", ".":
        break; // Phase value valid
      default:
        error_msg = "Invalid phase field";
        break;
    }
  }
  return error_msg;
}

// Validate attributes

string validate_attributes(string attributes_field) {
  string error_msg = check_if_empty_field("attributes", attributes_field);
  if (!(error_msg is null)) return error_msg;

  if (attributes_field != ".") {
    string[string] attributes;
    string attribute = attributes_field;
    while(attributes_field.length != 0) {
      attribute = get_and_skip_next_field(attributes_field, ';');
      if (attribute == "") continue;
      error_msg = check_if_attribute_has_two_parts(attribute);
      if (!(error_msg is null)) return error_msg;
      auto attribute_name = replace_url_escaped_chars( get_and_skip_next_field(attribute, '=') );
      auto attribute_value = replace_url_escaped_chars(attribute);
      error_msg = validate_attribute_name(attribute_name);
      if (!(error_msg is null)) return error_msg;
      attributes[attribute_name] = attribute_value;
    }
    error_msg = check_for_invalid_is_circular_value(attributes);
    if (!(error_msg is null)) return error_msg;
  }
  return null;
}

string validate_attribute_name(string attribute_name) {
  if (attribute_name.length == 0) // attribute name missing
    return "An attribute value without an attribute name";
  else
    return null;
}

string check_if_attribute_has_two_parts(string attribute) {
  if (attribute.count('=') != 1)
    return "Invalid attribute format";
  else
    return null;
}

string check_for_invalid_is_circular_value(string[string] attributes) {
  if ("Is_circular" in attributes) {
    switch (attributes["Is_circular"]) {
      case "true", "false":
      break; // Value valid
    default:
      return "Ivalid value for Is_circular attribute";
    }
  }
  return null;
}


// Helper functions

string check_if_nine_columns_present(string line) {
  if (line.count('\t') < 8)
    return "A record with invalid number of columns";
  else
    return null;
}

string check_if_empty_field(string field_name, string field) {
  if (field.length < 1)
    return "Found an empty " ~ field_name ~ " field";
  else
    return null;
}

string check_for_characters_invalid_in_any_field(string field_name, string field) {
  foreach(character; field) {
    if (std.ascii.isControl(character))
      return "Control characters not allowed in field " ~ field_name;
  }
  return null;
}


unittest {
  writeln("Testing validate_gff3_line...");

  // Minimal test
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1") is null);
  // Test splitting multiple attributes
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=45") is null);
  // Test if parser survives trailing semicolon
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=45;") is null);
  // Test if first splitting and then replacing escaped chars
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID%3D=1") is null);
  // Test for an attribute with the value of a single space
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID= ;") is null);
  // Test for an attribute with no value
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID=;") is null);
  // Test parsing lines with dots - undefined values
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\t.") is null);
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID=") is null);
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tIs_circular=false") is null);
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tIs_circular=true") is null);
  // Test line parsing with a normal line
  assert(validate_gff3_line("ENSRNOG00000019422\tEnsembl\tgene\t27333567\t27357352\t1.0\t+\t2\tID=ENSRNOG00000019422;Dbxref=taxon:10116;organism=Rattus norvegicus;chromosome=18;name=EGR1_RAT;source=UniProtKB/Swiss-Prot;Is_circular=true") is null);
  // Test parsing lines with escaped characters
  assert(validate_gff3_line("EXON%3D00000131935\tASTD%25\texon%26\t27344088\t27344141\t.\t+\t.\tID=EXON%3D00000131935;Parent=TRAN%3B000000%3D17239") is null);
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tParent=test") is null);
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=test;") is null);

  // Testing for invalid values
  // Test for an attribute without a name; should raise an error
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\t=123") !is null);
  // Test for invalid attribute field
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\t123") !is null);
  // Test when one attribute ok and a second is invalid
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1;123") !is null);
  // Test if two = characters in one attribute
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1;1=2=3") !is null);
  // Test with empty string instead of attributes field
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\t") !is null);
  // Test for one column missing
  assert(validate_gff3_line(".\t..\t.\t.\t.\t.\t.\t.") !is null);
  // Test for random text
  assert(validate_gff3_line("Test123") !is null);
  // Test for empty columns
  assert(validate_gff3_line("\t.\t.\t.\t.\t.\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t\t.\t.\t.\t.\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t\t.\t.\t.\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t\t.\t.\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t.\t\t.\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t.\t.\t\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t\t.") !is null);
  // Test for invalid characters in all fields
  assert(validate_gff3_line("\0\t.\t.\t.\t.\t.\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t\0\t.\t.\t.\t.\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t\0\t.\t.\t.\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t\0\t.\t.\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t.\t\0\t.\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t.\t.\t\0\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t\0\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t\0\t.") !is null);
  // Test for invalid characters in seqname
  assert(validate_gff3_line(">\t.\t.\t.\t.\t.\t.\t.\t.") !is null);
  // Test for start and end fields with invalid values
  assert(validate_gff3_line(".\t.\t.\t-5\t.\t.\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t0\t.\t.\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t.\t-4\t.\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t.\t0\t.\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t5\t4\t.\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\ta\t.\t.\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t.\tb\t.\t.\t.\t.") !is null);
  // Test for score field with invalid values
  assert(validate_gff3_line(".\t.\t.\t.\t.\tabc\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t.\t.\t1.0abc\t.\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t.\t.\tabc1.0\t.\t.\t.") !is null);
  // Test for strand field with invalid values
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t+-\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\ta\t.\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t+\0\t.\t.") !is null);
  // Test for phase field with invalid values
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\ta\t.") !is null);
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t12\t.") !is null);
  // Test for invalid values in Is_circular
  assert(validate_gff3_line(".\t.\t.\t.\t.\t.\t.\t.\tIs_circular=invalid") !is null);
}

