module bio.gff3.file;

import bio.gff3.validation, bio.gff3.record_range, bio.gff3.feature_range;
import bio.gff3.filtering;
import util.split_file;

class GFF3File {
  /**
   * Parses a file with GFF3 data.
   * Returns: a range of records.
   */
  static RecordRange!SplitFile parse_by_records(T)(T filename) {
    RecordRange!SplitFile records;
    static if (is(T == string)) {
      records = new RecordRange!(SplitFile)(new SplitFile(File(filename, "r")));
      records.set_filename(filename);
    } else if (is(T == File)) {
      records = new RecordRange!(SplitFile)(new SplitFile(filename));
    }
    return records;
  }

  /**
   * Parses a file with GFF3 data.
   * Returns: a range of features.
   */
  static FeatureRange parse_by_features(T)(T filename,
          size_t feature_cache_size = 1000,
          bool link_features = false) {
    auto records = parse_by_records(filename);
    return new FeatureRange(records, feature_cache_size, link_features);
  }
}

class GTFFile {
  /**
   * Parses a file with GTF data.
   * Returns: a range of records.
   */
  static RecordRange!SplitFile parse_by_records(T)(T filename) {
    auto records = GFF3File.parse_by_records(filename);
    records.set_data_format(DataFormat.GTF);
    return records;
  }
}

import std.stdio;

unittest {
  writeln("Testing parsing strings with open function and RecordRange...");

  // Parse file
  auto records = GFF3File.parse_by_records("./test/data/records.gff3");
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
    writeln("  Parsing file ./test/data/" ~ filename ~ "...");
    uint counter = 0;
    foreach(rec; GFF3File.parse_by_records("./test/data/" ~ filename))
      counter++;
    assert(counter == records_n);
  }
}

