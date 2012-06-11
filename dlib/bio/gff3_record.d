module bio.gff3_record;

import std.conv, std.stdio, std.array, std.string, std.exception;
import std.ascii;
import bio.exceptions, bio.gff3_validation, util.esc_char_conv;
import util.split_line;

/**
 * Represents a parsed line in a GFF3 file.
 */
class Record {
  /**
   * Constructor for the Record object, arguments are passed to the
   * parser_line() method.
   */
  this() {
//    WARNINGS_ON_ERROR(line);
  }

}

