module bio.gff3.conv.fasta;

import std.stdio, std.conv, std.array;
import bio.gff3.record_range, bio.fasta;

void to_fasta(GenericRecordRange records, string feature_type, string fasta_data, File output) {
  auto all_records = collect_data(records);

  auto all_cdss = collect_CDSs(all_records);
  auto all_mrnas = collect_mRNAs(all_records);
}

RecordData[] collect_data(GenericRecordRange records) {
  Appender!(RecordData[]) all_records;
  foreach(rec; records) {
    RecordData current;

    current.seqname = rec.seqname;
    current.id = rec.id;
    current.parent = rec.parent;
    current.feature = rec.feature;

    if (rec.start.length != 0)
      current.start = to!long(rec.start);
    if (rec.end.length != 0)
      current.end = to!long(rec.end);
    if (rec.phase.length != 0)
      current.phase = to!byte(rec.phase);

    all_records.put(current);
  }

  return all_records.data;
}

RecordData[] collect_CDSs(RecordData[] all_records) {
  Appender!(RecordData[]) cds_records;

  foreach(current; all_records) {
    if (current.feature == "CDS") {
      cds_records.put(current);
    }
  }

  return cds_records.data;
}

RecordData[] collect_mRNAs(RecordData[] all_records) {
  Appender!(RecordData[]) mrna_records;

  foreach(current; all_records) {
    if (current.feature == "mRNA") {
      mrna_records.put(current);
    }
  }

  return mrna_records.data;
}

// Collect only relevant feature data
struct RecordData {
  string seqname;
  string feature;
  string id;
  string parent;
  long start;
  long end;
  byte phase;
}

