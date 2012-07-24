module bio.gff3.record_range;

import std.conv, std.stdio, std.array, std.string, std.range, std.exception;
import std.ascii;
import bio.fasta, bio.gff3.record, bio.gff3.validation;
import bio.gff3.filtering;
import util.join_lines, util.split_into_lines, util.read_file;
import util.range_with_cache, util.split_file;

public import bio.gff3.data_formats;

class GenericRecordRange : RangeWithCache!Record {
  this() {
    this.validate = EXCEPTIONS_ON_ERROR;
    this.before_filter = NO_BEFORE_FILTER;
    this.after_filter = NO_AFTER_FILTER;
  }

  /**
   * Set filename which is used in validation reports
   */
  void set_filename(string filename) {
    this.filename = filename;
  }

  auto set_validate(RecordValidator validate) {
    this.validate = validate; return this;
  }

  auto set_replace_esc_chars(bool replace) {
    this.replace_esc_chars = replace; return this;
  }

  auto set_before_filter(StringPredicate before_filter) {
    this.before_filter = before_filter; return this;
  }

  auto set_after_filter(RecordPredicate after_filter) {
    this.after_filter = after_filter; return this;
  }

  /**
   * The range will include records which represent comments in the original
   * GFF3 file, if set to true.
   */
  auto set_keep_comments(bool keep = true) {
    this.keep_comments = keep; return this;
  }

  /**
   * The range will include records which represent pragmas in the original
   * GFF3 file, if set to true.
   */
  auto set_keep_pragmas(bool keep = true) {
    this.keep_pragmas = keep; return this;
  }

  auto set_data_format(DataFormat format) {
    this.data_format = format; return this;
  }

  private {
    RecordValidator validate;
    bool replace_esc_chars = true;

    StringPredicate before_filter;
    RecordPredicate after_filter;
    string filename;

    bool keep_comments = false;
    bool keep_pragmas = false;

    DataFormat data_format = DataFormat.GFF3;
  }
}

/**
 * Represents a range of GFF3 records derived from a range of lines.
 * The class takes a type parameter, which is the class or the struct
 * which is used as a data source. It's enough for the data source to
 * support front, popFront() and empty methods to be used by this
 * class.
 */
class RecordRange(SourceRangeType) : GenericRecordRange {
  /**
   * Creates a record range with data as the _data source. data can
   * be any range of lines without newlines and with front, popFront()
   * and empty defined.
   */
  this(SourceRangeType data) {
    this.data = data;
  }

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
   * Retrieve the next record, or null if is there
   * is no such record anymore in the data source.
   * The line is removed form the data source, except
   * when the line is part of FASTA data.
   */
  protected Record next_item() {
    if (fasta_mode)
      return null;
    string line = null;
    Record result;
    while (!data.empty) {
      line = data.front;
      if (line_is_empty(line)) {
        // skip line
      } else if (is_start_of_fasta(line)) {
        fasta_mode = true;
        if (!is_fasta_header(line))
          dataPopFront(); // Remove ##FASTA line from data source
        break;
      } else if (line_is_pragma(line)) {
        if (keep_pragmas) {
          result = new Record(line);
          dataPopFront();
          break;
        }
      } else if (line_is_comment(line)) {
        if (keep_comments) {
          result = new Record(line);
          dataPopFront();
          break;
        }
      } else if (validate(filename, line_number, line)) {
        // Found line with a valid record
        if (before_filter(line)) {
          result = new Record(line, replace_esc_chars, data_format);
          if (after_filter(result)) {
            // Record passed all filters
            dataPopFront();
            break;
          } else {
            result = null;
          }
        }
      }
      dataPopFront();
    }
    return result;
  }

  private {
    SourceRangeType data;
    bool fasta_mode = false;

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
  bool line_is_empty(T)(T[] line) {
    return (line.length == 0) || (line[0] == ' ') || (line[0] == '\t');
  }

  bool is_start_of_fasta(T)(T[] line) {
    return (((line.length >= 7) && (line[0..7] == "##FASTA")) ||
            ((line.length >= 1) && is_fasta_header(line)));
  }
}

unittest {
  writeln("Testing line_is_empty...");
  assert(line_is_empty("") == true);
  assert(line_is_empty("    ") == true);

  writeln("Testing is_start_of_fasta...");
  assert(is_start_of_fasta("##FASTA") == true);
  assert(is_start_of_fasta(">ctg123") == true);
  assert(is_start_of_fasta("Test 123") == false);
}

unittest {
  writeln("Testing RecordRange...");
  string test_data = q"EOS
# example data set
##gff-version 3
chr17	UCSC	mRNA	62467934	62469545	.	-	.	ID=A00469;Dbxref=AFFX-U133:205840_x_at,Locuslink:2688,Genbank-mRNA:A00469,Swissprot:P01241,PFAM:PF00103,AFFX-U95:1332_f_at,Swissprot:SOMA_HUMAN;Note=growth%20hormone%201;Alias=GH1
chr17	UCSC	CDS	62468039	62468236	.	-	1	Parent=A00469
# This is the first comment
chr17	UCSC	CDS	62468490	62468654	.	-	2	Parent=A00469
chr17	UCSC	CDS	62468747	62468866	.	-	1	Parent=A00469
## A pragma
chr17	UCSC	CDS	62469497	62469506	.	-	0	Parent=A00469
##FASTA
>A00469
GATTACA
GATTACA
EOS";

  // Test with comments
  auto range = new RecordRange!SplitIntoLines(new SplitIntoLines(test_data));
  range.set_keep_comments();
  assert(range.front.is_comment == true);
  assert(range.front.is_pragma == false);
  assert(range.front.is_regular == false);
  assert(range.front.toString == "# example data set");
  range.popFront();
  assert(range.front.is_comment == false);
  assert(range.front.is_pragma == false);
  assert(range.front.is_regular == true);
  assert(range.front.toString.startsWith("chr17"));
  range.popFront();
  assert(range.front.is_comment == false);
  assert(range.front.is_pragma == false);
  assert(range.front.is_regular == true);
  assert(range.front.toString.startsWith("chr17"));
  range.popFront();
  assert(range.front.is_comment == true);
  assert(range.front.is_pragma == false);
  assert(range.front.is_regular == false);
  assert(range.front.toString == "# This is the first comment");
  range.popFront();
  assert(range.front.is_comment == false);
  assert(range.front.is_pragma == false);
  assert(range.front.is_regular == true);
  assert(range.front.toString.startsWith("chr17"));
  range.popFront();
  assert(range.front.is_comment == false);
  assert(range.front.is_pragma == false);
  assert(range.front.is_regular == true);
  assert(range.front.toString.startsWith("chr17"));
  range.popFront();
  assert(range.front.is_comment == false);
  assert(range.front.is_pragma == false);
  assert(range.front.is_regular == true);
  assert(range.front.toString.startsWith("chr17"));
  range.popFront();
  assert(range.empty == true);

  // Test with both comments and pragmas
  range = new RecordRange!SplitIntoLines(new SplitIntoLines(test_data));
  range.set_keep_comments();
  range.set_keep_pragmas();
  assert(range.front.is_comment == true);
  assert(range.front.is_pragma == false);
  assert(range.front.is_regular == false);
  assert(range.front.toString == "# example data set");
  range.popFront();
  assert(range.front.is_comment == false);
  assert(range.front.is_pragma == true);
  assert(range.front.is_regular == false);
  assert(range.front.toString == "##gff-version 3");
  range.popFront();
  assert(range.front.is_comment == false);
  assert(range.front.is_pragma == false);
  assert(range.front.is_regular == true);
  assert(range.front.toString.startsWith("chr17"));
  range.popFront();
  assert(range.front.is_comment == false);
  assert(range.front.is_pragma == false);
  assert(range.front.is_regular == true);
  assert(range.front.toString.startsWith("chr17"));
  range.popFront();
  assert(range.front.is_comment == true);
  assert(range.front.is_pragma == false);
  assert(range.front.is_regular == false);
  assert(range.front.toString == "# This is the first comment");
  range.popFront();
  assert(range.front.is_comment == false);
  assert(range.front.is_pragma == false);
  assert(range.front.is_regular == true);
  assert(range.front.toString.startsWith("chr17"));
  range.popFront();
  assert(range.front.is_comment == false);
  assert(range.front.is_pragma == false);
  assert(range.front.is_regular == true);
  assert(range.front.toString.startsWith("chr17"));
  range.popFront();
  assert(range.front.is_comment == false);
  assert(range.front.is_pragma == true);
  assert(range.front.is_regular == false);
  assert(range.front.toString == "## A pragma");
  range.popFront();
  assert(range.front.is_comment == false);
  assert(range.front.is_pragma == false);
  assert(range.front.is_regular == true);
  assert(range.front.toString.startsWith("chr17"));
  range.popFront();
  assert(range.empty == true);

}

