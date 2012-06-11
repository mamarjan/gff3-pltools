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

private:

void validate_gff3_line(string line) {
  check_if_nine_columns_present(line);
  return;
}

void check_if_nine_columns_present(string line) {
  if (line.count('\t') < 8)
    throw new RecordException("A record with invalid number of columns", line);
}

