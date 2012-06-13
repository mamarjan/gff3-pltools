module bio.gff3_feature;

import std.array;
import bio.gff3_record;

class Feature {
  this(Record first_record = null) {
    if (first_record !is null)
      add_record(first_record);
  }

  void add_record(Record record) {
    records ~= record;
  }

  /**
   * Returns the ID of this feature, which is equal to the ID attribute
   * of its records.
   */
  @property string id() {
    return (records.length > 0) ? records[0].id : null;
  }

  /**
   * All records which are part of this feature.
   */
  Record[] records;
}

import std.stdio;

unittest {
  writeln("Testing Feature...");

  auto feature = new Feature(new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  assert(feature.records.length == 1);
  feature.add_record(new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  assert(feature.records.length == 2);

  feature = new Feature();
  assert(feature.records.length == 0);
  assert(feature.id is null);
  feature.add_record(new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  assert(feature.records.length == 1);
}

