module bio.gff3;

import std.conv, std.stdio, std.array, std.string, std.range, std.exception;
import std.ascii;
import bio.fasta, bio.exceptions, bio.gff3_record, bio.gff3_validation;
import util.join_lines, util.split_into_lines, util.read_file;

/**
 * Parses a string of GFF3 data.
 * Returns: a range of records.
 */
auto parse(string data) {
  return new RecordRange!(SplitIntoLines)(new SplitIntoLines(data));
}

/**
 * Parses a file with GFF3 data.
 * Returns: a range of records.
 */
auto open(string filename) {
  return new RecordRange!(typeof(File.byLine()))(File(filename, "r").byLine());
}

/**
 * Represents a range of GFF3 records derived from a range of lines.
 * The class takes a type parameter, which is the class or the struct
 * which is used as a data source. It's enough for the data source to
 * support front, popFront() and empty methods to be used by this
 * class.
 */
class RecordRange(SourceRangeType) {
  /**
   * Creates a record range with data as the _data source. data can
   * be any range of lines without newlines and with front, popFront()
   * and empty defined.
   */
  this(SourceRangeType data, RecordValidator validator = EXCEPTIONS_ON_ERROR) {
    this.data = data;
    this.validator = validator;
  }

  alias typeof(SourceRangeType.front()) Array;

  /**
   * Return the next record in range.
   * Ignores comments, pragmas and empty lines in the data source
   */
  @property Record front() {
    return next_record();
  }

  /**
   * Pops the next record in range.
   */
  void popFront() {
    cache = null;
  }

  /**
   * Return true if no more records left in the range.
   */
  @property bool empty() { 
    return next_record() is null;
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

  private {
    RecordValidator validator;
    SourceRangeType data;
    bool fasta_mode = false;

    Record cache;

    /**
     * Retrieve the next record, or Record.init if is there
     * is no such record anymore in the data source. Cache
     * the record in cache, and remove the line from the
     * data source, except if the line is part of FASTA data.
     */
    Record next_record() {
      if (!(cache is null))
        return cache;
      if (fasta_mode)
        return cache; // Which is null
      Array line = null;
      while (!data.empty) {
        line = data.front;
        if (is_comment(line)) { data.popFront(); continue; }
        if (is_empty_line(line)) { data.popFront(); continue; }
        if (is_start_of_fasta(line)) {
          fasta_mode = true;
          if (!is_fasta_header(line))
            data.popFront(); // Remove ##FASTA line from data source
          break;
        }
        // Found line with a valid record
        break;
      }
      if (!(data.empty || fasta_mode)) {
        static if (is(Array == string)) {
          cache = new Record(line, validator);
        } else {
          cache = new Record(to!string(line), validator);
        }
        data.popFront();
      }
      return cache;
    }

    /**
     * Skips all the GFF3 records until it gets to the start of
     * the FASTA section or end of file
     */
    void scroll_until_fasta() {
      auto line = data.front;
      while ((!data.empty) && (!is_start_of_fasta(line))) {
        data.popFront();
        if (!data.empty)
          line = data.front;
      }

      if (is_start_of_fasta(line)) {
        fasta_mode = true;
        if (!is_fasta_header(line))
          //Remove ##FASTA line from data source
          data.popFront();
      }
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

unittest {
  writeln("Testing parsing strings with parse function and RecordRange...");

  // Retrieve test file into a string
  File gff3_file;
  gff3_file.open("./test/data/records.gff3", "r");
  auto data = gff3_file.read();

  // Parse data
  auto records = parse(data);
  auto record1 = records.front; records.popFront();
  auto record2 = records.front; records.popFront();
  auto record3 = records.front; records.popFront();
  assert(records.empty == true);

  // Check the results
  with(record1) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["ENSRNOG00000019422", "Ensembl", "gene", "27333567", "27357352", "1.0", "+", "2"]);
    assert(attributes == [ "ID" : "ENSRNOG00000019422", "Dbxref" : "taxon:10116", "organism" : "Rattus norvegicus", "chromosome" : "18", "name" : "EGR1_RAT", "source" : "UniProtKB/Swiss-Prot", "Is_circular" : "true"]);
  }
  with(record2) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           [".", ".", ".", ".", ".", ".", ".", "."]);
    assert(attributes.length == 0);
  }
  with(record3) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["EXON=00000131935", "ASTD%", "exon&", "27344088", "27344141", ".", "+", "."]);
    assert(attributes == ["ID" : "EXON=00000131935", "Parent" : "TRAN;00000017239"]);
  }

  // Test scrolling to FASTA data
  records = parse(data);
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
      "tcaaacagcggctgtaaaaatttgtgattatggttaaagg\n\n\n");
}

unittest {
  writeln("Testing parsing strings with open function and RecordRange...");

  // Parse file
  auto records = open("./test/data/records.gff3");
  auto record1 = records.front; records.popFront();
  auto record2 = records.front; records.popFront();
  auto record3 = records.front; records.popFront();
  assert(records.empty == true);

  // Check the results
  with(record1) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["ENSRNOG00000019422", "Ensembl", "gene", "27333567", "27357352", "1.0", "+", "2"]);
    assert(attributes == [ "ID" : "ENSRNOG00000019422", "Dbxref" : "taxon:10116", "organism" : "Rattus norvegicus", "chromosome" : "18", "name" : "EGR1_RAT", "source" : "UniProtKB/Swiss-Prot", "Is_circular" : "true"]);
  }
  with(record2) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           [".", ".", ".", ".", ".", ".", ".", "."]);
    assert(attributes.length == 0);
  }
  with(record3) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["EXON=00000131935", "ASTD%", "exon&", "27344088", "27344141", ".", "+", "."]);
    assert(attributes == ["ID" : "EXON=00000131935", "Parent" : "TRAN;00000017239"]);
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
    writeln("  Parsing file ./test/data/" ~ filename ~ "...");
    uint counter = 0;
    foreach(rec; open("./test/data/" ~ filename))
      counter++;
    assert(counter == records_n);
  }
}

