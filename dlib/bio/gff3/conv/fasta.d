module bio.gff3.conv.fasta;

import std.stdio, std.conv, std.array, std.algorithm, std.format;
import bio.gff3.record_range, bio.fasta;
import util.split_into_lines, util.array_includes, util.equals, util.logger;

/**
 * Converts the passed records range to one fasta sequence per feature.
 * Params:
 *     records =       the records for the features to be converted
 *     feature_type =  only features of this type will be converted
 *     parent_feature_type =  when null, the attribute ID of GFF3 records will be
 *                            be used for grouping records into features. When something
 *                            else, that feature type will be used as parent for the
 *                            features to be converted to fasta.
 *     fasta_data =           an associative array mapping fasta headers to fasta sequences.
 *                            If null, the function will attempt to extract fasta data from
 *                            the passed record range
 *     no_assemble =          if true, records will not be grouped into features, but
 *                            converted to one fasta sequence per GFF3 record
 *     phase =                each sequence part will be adjusted per it's own phase field
 *                            if true
 *     frame =                each sequence part will be adjusted as to yield the least
 *                            number of stop codons
 *     trim_end =             trim the end of each sequence part to get modulo 3 length
 *     output =               File object where the fasta data will be written
 */
void to_fasta(GenericRecordRange records, string feature_type, string parent_feature_type,
              string[string] fasta_data, bool no_assemble, bool phase, bool frame,
              bool trim_end, bool translate, File output) {
  RecordData[] all_records;
  FeatureData[] features;

  // Fetch required features
  if (no_assemble) {
    all_records = collect_data(records, [feature_type]);
    features = convert_to_features(all_records);
  } else if (parent_feature_type is null) {
    all_records = collect_data(records, [feature_type]);
    features = collect_features(all_records);
  } else {
    all_records = collect_data(records, [feature_type, parent_feature_type]);
    features = collect_features(all_records, feature_type, parent_feature_type);
  }

  // Fetch fasta from end of GFF3 file if no fasta data provided
  if (fasta_data is null)
    fasta_data = records.get_fasta_range().all;

  // Output features in fasta format
  foreach(feature; features) {
    if (feature.records.length > 0) {
      output.writeln(feature.fasta_id);
      if (translate)
        output.writeln(translate_sequence(feature.to_fasta(fasta_data, phase, frame, trim_end)));
      else
        output.writeln(feature.to_fasta(fasta_data, phase, frame, trim_end));
    }
  }
}

private:

/**
 * Collect all records whose type is in the feature_types array.
 */
RecordData[] collect_data(GenericRecordRange records, string[] feature_types) {
  Appender!(RecordData[]) all_records;
  foreach(rec; records) {
    if (feature_types.includes_ci(rec.feature)) {
      RecordData current = new RecordData;

      current.seqname = rec.seqname;
      current.id = rec.id;
      current.feature = rec.feature;
      current.strand = rec.strand[0];
      current.parent = rec.parent;

      if (rec.start.length != 0)
        current.start = to!long(rec.start);
      if (rec.end.length != 0)
        current.end = to!long(rec.end);
      if (rec.phase.length != 0)
        current.phase = to!byte(rec.phase);

      all_records.put(current);
    }
  }

  return all_records.data;
}

class FeatureData {
  RecordData[] records;

  /**
   * Sort records in this feature by the start coordinate.
   */
  void sort() {
    bool rec_cmp(RecordData a, RecordData b) {
      return a.start < b.start;
    }

    std.algorithm.sort!(rec_cmp)(records);
  }

  /**
   * Return an fasta ID string for this feature.
   */
  @property string fasta_id() {
    sort();
    Appender!(string) new_id;

    // The following statement is required because formattedWrite() cannot
    // initialize the Appender object
    new_id.put('>');

    // ID attribute or seqname is the first part
    auto rec0 = records[0];
    if (rec0.id.length == 0) {
      if (rec0.seqname.length == 0) {
        new_id.put("unknown");
        warn("A records without a sequence name and ID attribute: " ~
             to!string(rec0.feature) ~ ", start: " ~ to!string(rec0.start) ~
             ", end: " ~ to!string(rec0.end));
      } else {
        new_id.formattedWrite("%s %d %d", rec0.seqname, rec0.start, rec0.end);
      }
    } else {
      new_id.formattedWrite("%s", rec0.id);
    }

    // Original fasta sequence and start and stop come next
    formattedWrite(new_id, " Sequence:%s_%d:%d (", rec0.seqname, rec0.start, records[$-1].end);

    // Comma-separated coordinates of CDS records finish the fasta ID
    foreach(i, rec; records) {
      if (i == 0)
        new_id.formattedWrite("%d:%d", rec.start, rec.end);
      else
        new_id.formattedWrite(", %d:%d", rec.start, rec.end);
    }
    new_id.put(')');

    return new_id.data;
  }

  string to_fasta(string[string] fasta_data, bool phase, bool frame, bool trim_end) {
    string fasta_sequence;
    string seqname = records[0].seqname;
    if (seqname.length == 0) {
      fasta_sequence = null;
    } else {
      if (seqname in fasta_data) {
        if (records[0].strand == '-')
          fasta_sequence = to_fasta_negative_strand(fasta_data, phase, frame, trim_end);
        else
          fasta_sequence = to_fasta_positive_strand(fasta_data, phase, frame, trim_end);
      } else {
        warn("A record was reffering to a FASTA sequence that could not be found: " ~
             seqname);
        fasta_sequence = null;
      }
    }

    return fasta_sequence;
  }

  string to_fasta_negative_strand(string[string] fasta_data, bool phase, bool frame, bool trim_end) {
    string fasta_sequence;
    string seqname = records[0].seqname;
    auto sequence = fasta_data[seqname];

    auto copy = records.dup;
    reverse(copy);
    foreach(rec; copy) {
      auto sequence_part = sequence[rec.start-1..rec.end].dup;
      if (sequence_part.length == 0) {
        continue;
      } else {
        reverse(sequence_part);
        reverse_strand(sequence_part);
        if (phase)
          sequence_part = adjust_for_phase(sequence_part, rec);
        if (frame)
          sequence_part = adjust_for_frame(sequence_part);
        if (trim_end)
          sequence_part = trim_sequence_end(sequence_part);
        fasta_sequence ~= sequence_part;
      }
    }

    return fasta_sequence;
  }

  string to_fasta_positive_strand(string[string] fasta_data, bool phase, bool frame, bool trim_end) {
    string fasta_sequence;
    string seqname = records[0].seqname;
    auto sequence = fasta_data[seqname];

    foreach(rec; records) {
      auto sequence_part = sequence[rec.start-1..rec.end];
      if (phase)
        sequence_part = adjust_for_phase(sequence_part, rec);
      if (frame)
        sequence_part = adjust_for_frame(sequence_part);
      if (trim_end)
        sequence_part = trim_sequence_end(sequence_part);
      fasta_sequence ~= sequence_part;
    }

    return fasta_sequence;
  }

  T[] adjust_for_phase(T)(T[] sequence, RecordData rec) {
    if (sequence.length < rec.phase) {
      warn("Sequence shorter than phase shift size for the following record: " ~
           rec.feature ~ ", ID attr: " ~ rec.id ~ ", start: " ~ to!string(rec.start) ~
           ", end:" ~ to!string(rec.end));
    }  else {
      sequence = sequence[rec.phase..$];
    }
    return sequence;
  }

  T[] adjust_for_frame(T)(T[] sequence) {
    int[3] frameshift;
    if (sequence.length > 5) {
      frameshift[0] = count_stop_codons(sequence[0..$-3]);
      frameshift[1] = count_stop_codons(sequence[1..$-3]);
      frameshift[2] = count_stop_codons(sequence[2..$-3]);
      sequence = sequence[min_pos(frameshift)..$];
    } else {
      warn(cast(string) ("Sequence not long enough for calculating frameshift: " ~ sequence));
    }
    return sequence;
  }

  T[] trim_sequence_end(T)(T[] sequence) {
    return sequence[0..$-(sequence.length % 3)];
  }
}

// Collect only relevant data
class RecordData {
  string seqname;
  string feature;
  string id;
  string parent;
  char strand;
  long start;
  long end;
  byte phase;
}

FeatureData[] convert_to_features(RecordData[] all_records) {
  Appender!(FeatureData[]) features;

  foreach(rec; all_records) {
    auto new_feature = new FeatureData;
    new_feature.records = [rec];
    features.put(new_feature);
  }

  return features.data;
}

FeatureData[] collect_features(RecordData[] all_records) {
  FeatureData[string] lookup_table;
  Appender!(FeatureData[]) features;

  foreach(rec; all_records) {
    if (rec.id.length == 0) {
      auto new_feature = new FeatureData;
      new_feature.records = [rec];
      features.put(new_feature);
    } else {
      if (rec.id in lookup_table) {
        lookup_table[rec.id].records ~= rec;
      } else {
        auto new_feature = new FeatureData;
        new_feature.records = [rec];
        lookup_table[rec.id] = new_feature;
        features.put(new_feature);
      }
    }
  }

  return features.data;
}

FeatureData[] collect_features(RecordData[] all_records, string child_feature_type, string parent_feature_type) {
  FeatureData[string] lookup_table;
  Appender!(FeatureData[]) features;

  // Collect all ID's of parents
  foreach(rec; all_records) {
    if (equals_ci(rec.feature, parent_feature_type)) {
      if (rec.id !in lookup_table) {
        auto new_feature = new FeatureData;
        lookup_table[rec.id] = new_feature;
        features.put(new_feature);
      }
    }
  }

  foreach(rec; all_records) {
    if (equals_ci(rec.feature, child_feature_type)) {
      if (rec.parent in lookup_table) {
        rec.id = rec.parent;
        lookup_table[rec.parent].records ~= rec;
      } else {
        warn("Could not find parent record: ID: " ~ rec.parent ~ ", type: " ~
             parent_feature_type);
      }
    }
  }

  return features.data;
}

void reverse_strand(char[] sequence) {
  foreach(ref c; sequence) {
    switch(c) {
      case 'A': c = 'T'; break;
      case 'T': c = 'A'; break;
      case 'C': c = 'G'; break;
      case 'G': c = 'C'; break;
      case 'a': c = 't'; break;
      case 't': c = 'a'; break;
      case 'c': c = 'g'; break;
      case 'g': c = 'c'; break;
      default: break;
    }
  }
}

int count_stop_codons(T)(T[] sequence) {
  int stop_codons = 0;
  while(sequence.length >= 3) {
    switch(sequence[0..3]) {
      case "TAA", "taa", "TGA", "tga", "TAG", "tag":
        stop_codons += 1;
        break;
      default:
        break;
    }
    sequence = sequence[3..$];
  }

  return stop_codons;
}

int min_pos(int[] values) {
  int current_min = values[0];
  int current_index = 0;
  foreach(int i, int value; values) {
    if (value < current_min) {
      current_min = value;
      current_index = i;
    }
  }

  return current_index;
}

unittest {
  writeln("Testing min_pos()...");

  assert(min_pos([1, 2, 3]) == 0);
  assert(min_pos([2, 1, 3]) == 1);
  assert(min_pos([6, 5, 4]) == 2);
}

/**
 * Translation using the DNA codon table from this wikipedia
 * page:
 *
 * https://en.wikipedia.org/wiki/DNA_codon_table
 */
string translate_sequence(string sequence) {
  Appender!string app;
  while(sequence.length >= 3) {
    string codon = sequence[0..3];
    char aa;
    switch(codon) {
      case "TTT":
      case "TTC":
        aa = 'F';
        break;
      case "TTA":
      case "TTG":
      case "CTT":
      case "CTC":
      case "CTA":
      case "CTG":
        aa = 'L';
        break;
      case "ATT":
      case "ATC":
      case "ATA":
        aa = 'I';
        break;
      case "ATG":
        aa = 'M';
        break;
      case "GTT":
      case "GTC":
      case "GTA":
      case "GTG":
        aa = 'V';
        break;
      case "TCT":
      case "TCC":
      case "TCA":
      case "TCG":
        aa = 'S';
        break;
      case "CCT":
      case "CCC":
      case "CCA":
      case "CCG":
        aa = 'P';
        break;
      case "ACT":
      case "ACC":
      case "ACA":
      case "ACG":
        aa = 'T';
        break;
      case "GCT":
      case "GCC":
      case "GCA":
      case "GCG":
        aa = 'A';
        break;
      case "TAT":
      case "TAC":
        aa = 'Y';
        break;
      case "TAA":
      case "TAG":
        aa = '*';
        break;
      case "CAT":
      case "CAC":
        aa = 'H';
        break;
      case "CAA":
      case "CAG":
        aa = 'Q';
        break;
      case "AAT":
      case "AAC":
        aa = 'N';
        break;
      case "AAA":
      case "AAG":
        aa = 'K';
        break;
      case "GAT":
      case "GAC":
        aa = 'D';
        break;
      case "GAA":
      case "GAG":
        aa = 'E';
        break;
      case "TGT":
      case "TGC":
        aa = 'C';
        break;
      case "TGA":
        aa = '*';
        break;
      case "TGG":
        aa = 'W';
        break;
      case "CGT":
      case "CGC":
      case "CGA":
      case "CGG":
        aa = 'R';
        break;
      case "AGT":
      case "AGC":
        aa = 'S';
        break;
      case "AGA":
      case "AGG":
        aa = 'R';
        break;
      case "GGT":
      case "GGC":
      case "GGA":
      case "GGG":
        aa = 'G';
        break;
      default:
        warn("Found invalid nucleotide sequence: " ~ sequence[0..3]);
        aa = 'X';
        break;
    }
    app.put(aa);
    sequence = sequence[3..$];
  }

  return app.data;
}

