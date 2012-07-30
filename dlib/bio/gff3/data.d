module bio.gff3.data;

import bio.gff3.validation, bio.gff3.record_range, bio.gff3.feature_range;
import bio.gff3.filtering;
import util.split_into_lines;

class GFF3Data {
  /**
   * Parses a string of GFF3 data.
   * Returns: a range of records.
   */
  static RecordRange!SplitIntoLines parse_by_records(string data) {
    auto records = new RecordRange!SplitIntoLines(new SplitIntoLines(data));
    return records;
  }

  /**
   * Parses a string of GFF3 data.
   * Returns: a range of features.
   */
  static FeatureRange parse_by_features(string data,
          size_t features_cache_size = 1000,
          bool link_features = false) {
    auto records = parse_by_records(data);
    return new FeatureRange(records, features_cache_size, link_features);
  }
}

class GTFData {
}

import std.stdio;
import util.read_file;

unittest {
  writeln("Testing parsing strings with parse function and RecordRange...");

  // Retrieve test file into a string
  File gff3_file;
  gff3_file.open("./test/data/records.gff3", "r");
  auto data = gff3_file.read();

  // Parse data
  auto records = GFF3Data.parse_by_records(data);
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
    assert(attributes["ID"].all == ["EXON=00000131935"]);
    assert(attributes["Parent"].all == ["TRAN;00000017239"]);
  }

  // Test scrolling to FASTA data
  records = GFF3Data.parse_by_records(data);
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

