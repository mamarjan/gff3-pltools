module bio.gff3_record_range;

import std.conv, std.stdio, std.array, std.string, std.range, std.exception;
import std.ascii;
import bio.fasta, bio.exceptions, bio.gff3_record, bio.gff3_validation;
import util.join_lines, util.split_into_lines, util.read_file;
import util.range_with_cache, util.split_file;

/**
 * Represents a range of GFF3 records derived from a range of lines.
 * The class takes a type parameter, which is the class or the struct
 * which is used as a data source. It's enough for the data source to
 * support front, popFront() and empty methods to be used by this
 * class.
 */
class RecordRange(SourceRangeType) : RangeWithCache!Record {
  /**
   * Creates a record range with data as the _data source. data can
   * be any range of lines without newlines and with front, popFront()
   * and empty defined.
   */
  this(SourceRangeType data, RecordValidator validator = EXCEPTIONS_ON_ERROR,
       bool replace_esc_chars = true) {
    this.data = data;
    this.validate = validator;
    this.replace_esc_chars = replace_esc_chars;
  }

  /**
   * Set filename which is used in validation reports
   */
  void set_filename(string filename) {
    this.filename = filename;
  }

  alias typeof(SourceRangeType.front()) Array;

  /**
   * Retrieve a range of FASTA sequences appended to
   * GFF3 data.
   */
  auto get_fasta_range() {
    scroll_until_fasta();
    if (empty && fasta_mode)
      return new FastaRange!(SourceRangeType)(data);
    else
      return null;
  }

  /**
   * Retrieves the FASTA data at the end of file
   * in a string.
   */
  string get_fasta_data() {
    scroll_until_fasta();
    if (empty && fasta_mode) {
      return join_lines(data);
    } else {
      return null;
    }
  }

  /**
   * Retrieve the next record, or Record.init if is there
   * is no such record anymore in the data source. Cache
   * the record in cache, and remove the line from the
   * data source, except if the line is part of FASTA data.
   */
  protected Record next_item() {
    if (fasta_mode)
      return null;
    Array line = null;
    while (!data.empty) {
      line = data.front;
      if (is_comment(line)) { dataPopFront(); continue; }
      if (is_empty_line(line)) { dataPopFront(); continue; }
      if (is_start_of_fasta(line)) {
        fasta_mode = true;
        if (!is_fasta_header(line))
          dataPopFront(); // Remove ##FASTA line from data source
        break;
      }
      if (validate(filename, line_number, line))
        // Found line with a valid record
        break;
      else
        dataPopFront();
    }
    Record result;
    if (!(data.empty || fasta_mode)) {
      static if (is(Array == string)) {
        result = new Record(line, replace_esc_chars);
      } else {
        result = new Record(to!string(line), replace_esc_chars);
      }
      dataPopFront();
    }
    return result;
  }

  private {
    RecordValidator validate;
    SourceRangeType data;
    bool fasta_mode = false;
    bool replace_esc_chars;

    string filename;
    int line_number = 1;

    /**
     * Skips all the GFF3 records until it gets to the start of
     * the FASTA section or end of file
     */
    void scroll_until_fasta() {
      auto line = data.front;
      while ((!data.empty) && (!is_start_of_fasta(line))) {
        dataPopFront();
        if (!data.empty)
          line = data.front;
      }

      if (is_start_of_fasta(line)) {
        fasta_mode = true;
        if (!is_fasta_header(line))
          //Remove ##FASTA line from data source
          dataPopFront();
      }
    }

    /**
     * Helper method for line counting
     */
    void dataPopFront() {
      data.popFront();
      line_number++;
    }
  }
}

private {

  bool is_empty_line(T)(T[] line) {
    return line.strip() == "";
  }

  bool is_comment(T)(T[] line) {
    return indexOf(line, '#') != -1;
  }

  bool is_start_of_fasta(T)(T[] line) {
    return (line.length >= 1) ? (line.startsWith("##FASTA") || is_fasta_header(line)) : false;
  }
}

unittest {
  writeln("Testing is_comment...");
  assert(is_comment("# test") == true);
  assert(is_comment("     # test") == true);
  assert(is_comment("# test\n") == true);

  writeln("Testing is_empty_line...");
  assert(is_empty_line("") == true);
  assert(is_empty_line("    ") == true);
  assert(is_empty_line("\n") == true);

  writeln("Testing is_start_of_fasta...");
  assert(is_start_of_fasta("##FASTA") == true);
  assert(is_start_of_fasta(">ctg123") == true);
  assert(is_start_of_fasta("Test 123") == false);
}

