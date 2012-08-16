module bio.gff3.conv.fasta;

import std.stdio, std.conv, std.array, std.algorithm, std.string, std.ascii,
       core.exception;
import bio.gff3.record_range, bio.fasta;
import util.split_into_lines;

void to_fasta(GenericRecordRange records, string feature_type, string parent_feature_type, string raw_fasta_data, File output) {
  auto all_records = collect_data(records, [feature_type, parent_feature_type]);
  FeatureData[] features;
  if (parent_feature_type is null) {
    features = collect_features(all_records);
  } else {
    features = collect_features(all_records, feature_type, parent_feature_type);
  }
  auto fasta_data = parse_fasta(raw_fasta_data);
  foreach(feature; features) {
    if (feature.records.length > 0) {
      output.writeln(feature.fasta_id);
      output.writeln(feature.to_fasta(fasta_data));
    }
  }
}

RecordData[] collect_data(GenericRecordRange records, string[] feature_types) {
  Appender!(RecordData[]) all_records;
  foreach(rec; records) {
    bool is_requested_feature(string a) { return equals_ci(a, rec.feature); }
    //if (equals_ci(feature_type, rec.feature)) {
    if (reduce!("a || b")(false, map!(is_requested_feature)(feature_types))) {
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

bool equals_ci(string a, string b) {
  if (a.length != b.length)
    return false;
  foreach(i, c; a)
    if (toLower(c) != toLower(b[i]))
      return false;
  return true;
}

class FeatureData {
  RecordData[] records;

  void sort() {
    bool rec_cmp(RecordData a, RecordData b) { return a.start < b.start; }
    std.algorithm.sort!(rec_cmp)(records);
  }

  @property string fasta_id() {
    Appender!(string) new_id;
    new_id.put('>');
    if (records[0].id.length == 0) {
      if (records[0].seqname.length == 0) {
        new_id.put("unknown");
        // TODO: report error
      } else {
        new_id.put(records[0].seqname);
        new_id.put(' ');
        new_id.put(to!string(records[0].start));
        new_id.put(' ');
        new_id.put(to!string(records[0].end));
      }
    } else {
      new_id.put(records[0].id);
    }
    new_id.put(" Sequence:");
    new_id.put(records[0].seqname);
    sort();
    new_id.put('_');
    new_id.put(to!string(records[0].start));
    new_id.put(':');
    new_id.put(to!string(records[$-1].end));
    new_id.put(" (");
    bool first_record = true;
    foreach(rec; records) {
      if (first_record)
        first_record = false;
      else
        new_id.put(", ");
      new_id.put(to!string(rec.start));
      new_id.put(':');
      new_id.put(to!string(rec.end));
    }
    new_id.put(')');
    return new_id.data;
  }

  string to_fasta(string[string] fasta_data) {
    string fasta_sequence;
    string seqname = records[0].seqname;
    if (seqname.length == 0) {
      // TODO: report error
      fasta_sequence = null;
    } else {
      if (seqname in fasta_data) {
        if (records[0].strand == '-') {
          auto copy = records.dup;
          reverse(copy);
          foreach(rec; copy) {
            auto sequence = fasta_data[seqname];
            auto sequence_part = sequence[rec.start-1..rec.end].dup;
            if (sequence_part.length == 0) {
              // TODO: report sequence length 0, e.g. start == end is true
            } else {
              reverse(sequence_part);
              reverse_strand(sequence_part);
              if (sequence_part.length < rec.phase) {
                // TODO: report error
              }  else {
                sequence_part = sequence_part[rec.phase..$];
                int[3] frameshift;
                if (sequence_part.length > 5) {
                  frameshift[0] = count_stop_codons(sequence_part[0..$-3]);
                  frameshift[1] = count_stop_codons(sequence_part[1..$-3]);
                  frameshift[2] = count_stop_codons(sequence_part[2..$-3]);
                  sequence_part = sequence_part[min_pos(frameshift)..$];
                }
                fasta_sequence ~= sequence_part[0..$-(sequence_part.length % 3)];
              }
            }
          }
        } else {
          foreach(rec; records) {
            auto sequence_part = fasta_data[seqname][rec.start-1..rec.end];
            if (sequence_part.length < rec.phase) {
              // TODO: report error
            }  else {
              sequence_part = sequence_part[rec.phase..$];
              int[3] frameshift;
              if (sequence_part.length > 5) {
                frameshift[0] = count_stop_codons(sequence_part[0..$-3]);
                frameshift[1] = count_stop_codons(sequence_part[1..$-3]);
                frameshift[2] = count_stop_codons(sequence_part[2..$-3]);
                sequence_part = sequence_part[min_pos(frameshift)..$];
              }
              fasta_sequence ~= sequence_part[0..$-(sequence_part.length % 3)];
            }
          }
        }
      } else {
        // TODO: report error
        fasta_sequence = null;
      }
    }
    return fasta_sequence;
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
        // TODO: report error
      }
    }
  }

  return features.data;
}

string[string] parse_fasta(string raw_fasta_data) {
  auto records = new FastaRange!SplitIntoLines(new SplitIntoLines(raw_fasta_data));

  string[string] fasta_data;
  foreach(rec; records)
    fasta_data[rec.header] = rec.sequence;

  return fasta_data;
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

