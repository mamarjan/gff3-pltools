module bio.gff3.feature;

import std.array;
import bio.gff3.record, bio.gff3.conv.gff3, bio.gff3.attribute;

class Feature {
  this(Record first_record = null) {
    add_record(first_record);
  }

  void add_record(Record record) {
    if (record !is null)
      _records ~= record;
  }

  @property string id()  { return (_records.length > 0) ? _records[0].id : null; }
  @property string parent_id()  { return (_records.length > 0) ? _records[0].parent : null; }
  @property Feature parent()  { return _parent_feature; }

  /**
   * Returns a list of all children of this feature.
   */
  @property Feature[] children() { return _children; }

  /**
   * Sets the parent feature of this feature.
   */
  void set_parent(Feature parent) {
    _parent_feature = parent;
    if (_records.length > 0)
      if (_records[0].parent == parent.id)
        foreach(record; _records)
          record.attributes["Parent"] = AttributeValue([parent.id]);
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
  @property Record[] records() {
    return _records;
  }

  /**
   * Converts this object to one or more GFF3 lines.
   */
  string toString() {
    return to_gff3(this);
  }

  /**
   * Returns a string with the current feature and all child-features
   * of the current feature in a format ready for output to a GFF3
   * file.
   */
  string to_string(bool recursive = false) {
    return to_gff3(this, recursive);
  }

  private {
    Feature _parent_feature = null;
    string _parent = null;
    Record[] _records;
    Feature[] _children;
  }
}

import bio.gff3.line;

unittest {
  auto feature = new Feature(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  assert(feature.records.length == 1);
  feature.add_record(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  assert(feature.records.length == 2);

  feature = new Feature();
  assert(feature.records.length == 0);
  assert(feature.id is null);
  feature.add_record(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  assert(feature.records.length == 1);

  feature = new Feature();
  feature.add_record(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=2"));
  assert(feature.parent_id == "2");
  feature.add_child(new Feature(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=3;Parent=1")));
  feature.add_child(new Feature(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=4;Parent=1")));
  assert(feature.children.length == 2);
  feature.set_parent(new Feature(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1")));
  assert(feature.parent !is null);
  assert(feature.parent .id == "1");

  // Testing to String()
  feature = new Feature();
  feature.add_record(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  assert(feature.toString() == ".\t.\t.\t.\t.\t.\t.\t.\tID=1");

  // Testing to append_to() with newline
  feature = new Feature();
  feature.add_record(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  auto app = appender!(string)();
  feature.to_gff3(true, app);
  assert(app.data == ".\t.\t.\t.\t.\t.\t.\t.\tID=1\n");

  // Testing toString() with a feature with multiple records
  feature = new Feature();
  feature.add_record(parse_line("1\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  feature.add_record(parse_line("2\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  feature.add_record(parse_line("3\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  assert(feature.toString() == ("1\t.\t.\t.\t.\t.\t.\t.\tID=1\n" ~
                                "2\t.\t.\t.\t.\t.\t.\t.\tID=1\n" ~
                                "3\t.\t.\t.\t.\t.\t.\t.\tID=1"));

  // Testing to_string(recursive = true)
  feature = new Feature();
  feature.add_record(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  feature.add_record(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=2"));
  feature.add_child(new Feature(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=3")));
  feature.add_child(new Feature(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=4")));
  assert(feature.to_string(true) == (".\t.\t.\t.\t.\t.\t.\t.\tID=1\n" ~
                                     ".\t.\t.\t.\t.\t.\t.\t.\tID=2\n" ~
                                     ".\t.\t.\t.\t.\t.\t.\t.\tID=3\n" ~
                                     ".\t.\t.\t.\t.\t.\t.\t.\tID=4"));
}

