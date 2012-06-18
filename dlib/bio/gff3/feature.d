module bio.gff3.feature;

import std.array;
import bio.gff3.record;

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
   * Returns the Parent attribute of this feature, which is equal to the
   * Parent attribute of its records. Return null if the parent attribute
   * for this feature is not defined.
   */
  @property string parent() {
    return (records.length > 0) ? records[0].parent : null;
  }

  /**
   * Returns the parent feature of this feature, or null if there is no parent.
   */
  @property Feature parent_feature() {
    return _parent_feature;
  }

  /**
   * Returns a dynamic list of children of this feature.
   */
  @property Feature[] children() {
    return _children;
  }

  /**
   * Sets the parent feature of this feature.
   */
  void set_parent_feature(Feature parent) {
    _parent_feature = parent;
  }

  /**
   * Adds a new feature to this features list of children.
   */
  void add_child(Feature new_child) {
    _children ~= new_child;
  }

  /**
   * All records which are part of this feature.
   */
  Record[] records;
  private {
    Feature _parent_feature = null;
    Feature[] _children;
  }
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

  feature = new Feature();
  feature.add_record(new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=2"));
  assert(feature.parent == "2");
  feature.add_child(new Feature(new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=3;Parent=1")));
  feature.add_child(new Feature(new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=4;Parent=1")));
  assert(feature.children.length == 2);
}

