module bio.gff3.record_range;

import std.array, std.string, std.stdio;
import bio.fasta, bio.gff3.record, bio.gff3.validation,
       bio.gff3.filtering.filtering, bio.gff3.line;
import util.join_lines, util.range_with_cache, util.lines_range, util.split_file,
       util.split_into_lines;

public import bio.gff3.data_formats;

/**
 * Represents a range of GFF3 or GTF records derived from a range of lines.
 */
class RecordRange : RangeWithCache!Record {
  /**
   * Creates an empty record range.
   */
  this() {
    this.validate = EXCEPTIONS_ON_ERROR;
    this.before_filter = NO_BEFORE_FILTER;
    this.after_filter = NO_AFTER_FILTER;
  }

  auto set_input_data(string data) {
    this.data = new SplitIntoLines(data); return this;
  }

  auto set_input_file(File input_file) {
    this.data = new SplitFile(input_file); return this;
  }

  auto set_input_file(string filename) {
    this._filename = filename;
    return set_input_file(File(filename, "r"));
  }

  /**
   * Set filename which is used in validation reports
   */
  auto set_filename(string filename) {
    this._filename = filename; return this;
  }

  /**
   * Return the filename which is the source of this data. Returns null
   * if something else was used as the source of this data.
   */
  @property string filename() {
    return this._filename;
  }

  /**
   * Set the validation delegate which will be used for validation. Or
   * NO_VALIDATION if no validation should be done.
   */
  auto set_validate(RecordValidator validate) {
    this.validate = validate; return this;
  }

  /**
   * Call this with true if escaped characters are to be replaced by
   * their real value after basic parsing of records. Otherwise the
   * escaped characters will be left as they are.
   */
  auto set_replace_esc_chars(bool replace) {
    this.replace_esc_chars = replace; return this;
  }

  /**
   * This filter will be invoked with a raw line before it is parsed.
   * The current line will be parsed only if it passes this filter.
   */
  auto set_before_filter(StringFilter before_filter) {
    this.before_filter = before_filter; return this;
  }

  /**
   * This filter will be invoked with a Record object of the last parsed
   * line. If it passes the filter, the record will be the next record to
   * be returned.
   */
  auto set_after_filter(RecordFilter after_filter) {
    this.after_filter = after_filter; return this;
  }

  /**
   * The range will include records which represent comments in the original
   * GFF3 or GTF file, if set to true.
   */
  auto set_keep_comments(bool keep = true) {
    this.keep_comments = keep; return this;
  }

  /**
   * The range will include records which represent pragmas in the original
   * GFF3 or GTF file, if set to true.
   */
  auto set_keep_pragmas(bool keep = true) {
    this.keep_pragmas = keep; return this;
  }

  /**
   * Use this to set the input format of the data. DataFormat.GFF3 and GTF are currently
   * supported.
   */
  auto set_data_format(DataFormat format) {
    this.data_format = format; return this;
  }

  /**
   * Retrieve a range of FASTA sequences appended to
   * GFF3 data.
   */
  FastaRange get_fasta_range() {
    scroll_until_fasta();
    if (fasta_mode)
      return new FastaRange(data);
    else
      return null;
  }

  /**
   * Retrieves the FASTA data at the end of file
   * in a string.
   */
  string get_fasta_data() {
    scroll_until_fasta();
    if (fasta_mode)
      return join_lines(data);
    else
      return null;
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
      } else if (line.is_pragma()) {
        if (keep_pragmas) {
          result = parse_line(line);
          dataPopFront();
          break;
        }
      } else if (bio.gff3.line.is_comment(line)) {
        if (keep_comments) {
          result = parse_line(line);
          dataPopFront();
          break;
        }
      } else if (validate(filename, line_number, line)) {
        // Found line with a valid record
        if (before_filter(line)) {
          result = parse_line(line, replace_esc_chars, data_format);
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
    LinesRange data;
    bool fasta_mode = false;

    int line_number = 1;

    RecordValidator validate;
    bool replace_esc_chars = true;

    StringFilter before_filter;
    RecordFilter after_filter;
    string _filename;

    bool keep_comments = false;
    bool keep_pragmas = false;

    auto data_format = DataFormat.GFF3;

    /**
     * Skips all the GFF3 records until it gets to the start of
     * the FASTA section or end of file
     */
    void scroll_until_fasta() {
      while(!empty) popFront();
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

version (unittest) {
  import std.stdio;
  import util.split_into_lines, util.split_file, util.read_file;
}

unittest {
  assert(line_is_empty("") == true);
  assert(line_is_empty("    ") == true);

  assert(is_start_of_fasta("##FASTA") == true);
  assert(is_start_of_fasta(">ctg123") == true);
  assert(is_start_of_fasta("Test 123") == false);
}

unittest {
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
  auto range = (new RecordRange).set_input_data(test_data);
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
  range = (new RecordRange).set_input_data(test_data);
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

  /* TODO: refactor following tests */

  // Parse file
  auto records = (new RecordRange).set_input_file("./test/data/records.gff3");
  auto record1 = records.front; records.popFront();
  auto record2 = records.front; records.popFront();
  auto record3 = records.front; records.popFront();
  assert(records.empty == true);

  // Check the results
  with(record1) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["ENSRNOG00000019422", "Ensembl", "gene", "27333567", "27357352", "1.0", "+", "2"]);
    assert(attributes.length == 7);
    assert(attributes["ID"].all == ["ENSRNOG00000019422"]);
    assert(attributes["Dbxref"].all == ["taxon:10116"]);
    assert(attributes["organism"].all == ["Rattus norvegicus"]);
    assert(attributes["chromosome"].all == ["18"]);
    assert(attributes["name"].all == ["EGR1_RAT"]);
    assert(attributes["source"].all == ["UniProtKB/Swiss-Prot"]);
    assert(attributes["Is_circular"].all == ["true"]);
  }
  with(record2) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["", "", "", "", "", "", "", ""]);
    assert(attributes.length == 0);
  }
  with(record3) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["EXON=00000131935", "ASTD%", "exon&", "27344088", "27344141", "", "+", ""]);
    assert(attributes.length == 2); 
    assert(attributes["ID"].all == ["EXON=00000131935"]);
    assert(attributes["Parent"].all == ["TRAN;00000017239"]);
  }

  // Testing with various files
  uint[string] file_records_n = [
      "messy_protein_domains.gff3" : 1009,
      "gff3_with_syncs.gff3" : 19,
      "au9_scaffold_subset.gff3" : 1005,
      "tomato_chr4_head.gff3" : 87,
      "directives.gff3" : 0,
      "hybrid1.gff3" : 6,
      "hybrid2.gff3" : 6,
      "knownGene.gff3" : 15,
      "knownGene2.gff3" : 15,
      "mm9_sample_ensembl.gff3" : 190,
      "tomato_test.gff3" : 249,
      "spec_eden.gff3" : 23,
      "spec_match.gff3" : 3 ];
  foreach(filename, records_n; file_records_n) {
    uint counter = 0;
    foreach(rec; (new RecordRange).set_input_file("./test/data/" ~ filename))
      counter++;
    assert(counter == records_n);
  }

  // Retrieve test file into a string
  File gff3_file;
  gff3_file.open("./test/data/records.gff3", "r");
  auto data = gff3_file.read();

  // Parse data
  records = (new RecordRange).set_input_data(data);
  record1 = records.front; records.popFront();
  record2 = records.front; records.popFront();
  record3 = records.front; records.popFront();
  assert(records.empty == true);

  // Check the results
  with(record1) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["ENSRNOG00000019422", "Ensembl", "gene", "27333567", "27357352", "1.0", "+", "2"]);
    assert(attributes.length == 7);
    assert(attributes["ID"].all == ["ENSRNOG00000019422"]);
    assert(attributes["Dbxref"].all == ["taxon:10116"]);
    assert(attributes["organism"].all == ["Rattus norvegicus"]);
    assert(attributes["chromosome"].all == ["18"]);
    assert(attributes["name"].all == ["EGR1_RAT"]);
    assert(attributes["source"].all == ["UniProtKB/Swiss-Prot"]);
    assert(attributes["Is_circular"].all == ["true"]);
  }
  with(record2) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["", "", "", "", "", "", "", ""]);
    assert(attributes.length == 0);
  }
  with(record3) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["EXON=00000131935", "ASTD%", "exon&", "27344088", "27344141", "", "+", ""]);
    assert(attributes["ID"].all == ["EXON=00000131935"]);
    assert(attributes["Parent"].all == ["TRAN;00000017239"]);
  }

  // Test scrolling to FASTA data
  records = (new RecordRange).set_input_data(data);
  assert(records.get_fasta_data() ==
      ">ctg123\n" ~
      "cttctgggcgtacccgattctcggagaacttgccgcaccattccgccttg\n" ~
      "tgttcattgctgcctgcatgttcattgtctacctcggctacgtgtggcta\n" ~
      "tctttcctcggtgccctcgtgcacggagtcgagaaaccaaagaacaaaaa\n" ~
      "aagaaattaaaatatttattttgctgtggtttttgatgtgtgttttttat\n" ~
      "aatgatttttgatgtgaccaattgtacttttcctttaaatgaaatgtaat\n" ~
      "cttaaatgtatttccgacgaattcgaggcctgaaaagtgtgacgccattc\n" ~
      "gtatttgatttgggtttactatcgaataatgagaattttcaggcttaggc\n" ~
      "ttaggcttaggcttaggcttaggcttaggcttaggcttaggcttaggctt\n" ~
      "aggcttaggcttaggcttaggcttaggcttaggcttaggcttaggcttag\n" ~
      "aatctagctagctatccgaaattcgaggcctgaaaagtgtgacgccattc\n" ~
      ">cnda0123\n" ~
      "ttcaagtgctcagtcaatgtgattcacagtatgtcaccaaatattttggc\n" ~
      "agctttctcaagggatcaaaattatggatcattatggaatacctcggtgg\n" ~
      "aggctcagcgctcgatttaactaaaagtggaaagctggacgaaagtcata\n" ~
      "tcgctgtgattcttcgcgaaattttgaaaggtctcgagtatctgcatagt\n" ~
      "gaaagaaaaatccacagagatattaaaggagccaacgttttgttggaccg\n" ~
      "tcaaacagcggctgtaaaaatttgtgattatggttaaagg\n\n");

}

