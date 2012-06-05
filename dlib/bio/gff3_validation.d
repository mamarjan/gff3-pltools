module bio.gff3_validation;

import std.conv, std.stdio, std.array, std.string, std.exception;
import std.ascii;
import bio.util, bio.exceptions;

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
  return false;
};

void validate_gff3_line(string line) {
  check_if_nine_columns_present(line);
  auto parts = split(line, "\t");

  check_record_for_empty_fields(parts);
  check_if_valid_seqname(parts[0]);
  check_for_characters_invalid_in_any_field("source", parts[1]);
  check_for_characters_invalid_in_any_field("feature", parts[2]);
  check_if_coordinates_valid(parts[3], parts[4]);
  check_if_score_valid(parts[5]);
  check_if_strand_valid(parts[6]);
  check_if_phase_valid(parts[7]);

  check_if_field_not_empty_string("attributes", parts[8]);
  auto attributes_field = parts[8];
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

void check_if_field_not_empty_string(string field, string field_value) {
  if (field_value.length == 0)
    throw new AttributeException("Empty " ~ field ~ " field. Use dot for no attributes.", field_value);
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

void check_record_for_empty_fields(string[] fields) {
  foreach(i; 0..8) {
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

