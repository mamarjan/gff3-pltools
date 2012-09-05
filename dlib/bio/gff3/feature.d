module bio.gff3.feature;

import std.array;
import bio.gff3.record;

class Feature {
  this(Record first_record = null) {
    if (first_record !is null)
      add_record(first_record);
  }

  void add_record(Record record) {
    _records ~= record;
  }

  /**
   * Returns the ID of this feature, which is equal to the ID attribute
   * of its records.
   */
  @property string id() {
    return (_records.length > 0) ? _records[0].id : null;
  }

  /**
   * Returns the Parent attribute of this feature, which is equal to the
   * Parent attribute of its records. Return null if the parent attribute
   * for this feature is not defined.
   */
  @property string parent() {
    return (_records.length > 0) ? _records[0].parent : null;
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
  @property Record[] records() {
    return _records;
  }

  /**
   * Appends the feature to an Appender object.
   */
  void append_to(Appender!(char[]) app, bool add_newline = false) {
    foreach(i, rec; _records) {
      if (i != (_records.length - 1))
        rec.append_to(app, true);
      else
        // don't add newline to last line
        rec.append_to(app, false);
    }

    if (add_newline)
      app.put('\n');
  }

  /**
   * Converts this object to one or more GFF3 lines.
   */
  string toString() {
    auto result = appender!(char[])();
    append_to(result);
    return cast(string)(result.data);
  }

  void recursive_append_to(Appender!(char[]) app, bool add_newline = false) {
    append_to(app, true);
    foreach(child; _children) {
      child.recursive_append_to(app, true);
    }

    if (!add_newline) {
      // remove the trailing newline char
      app.shrinkTo(app.data.length-1);
    }
  }

  /**
   * Returns a string with the current feature and all child-features
   * of the current feature in a format ready for output to a GFF3
   * file.
   */
  string recursive_to_string() {
    auto result = appender!(char[])();
    recursive_append_to(result);
    return cast(string)(result.data);
  }

  private {
    Feature _parent_feature = null;
    Record[] _records;
    Feature[] _children;
  }
}

import std.stdio;
import bio.gff3.line;

unittest {
  writeln("Testing Feature...");

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
  assert(feature.parent == "2");
  feature.add_child(new Feature(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=3;Parent=1")));
  feature.add_child(new Feature(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=4;Parent=1")));
  assert(feature.children.length == 2);
  feature.set_parent_feature(new Feature(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1")));
  assert(feature.parent_feature !is null);
  assert(feature.parent_feature.id == "1");

  // Testing to String()
  feature = new Feature();
  feature.add_record(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  assert(feature.toString() == ".\t.\t.\t.\t.\t.\t.\t.\tID=1");

  // Testing to append_to() with newline
  feature = new Feature();
  feature.add_record(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  auto app = appender!(char[])();
  feature.append_to(app, true);
  assert(app.data == ".\t.\t.\t.\t.\t.\t.\t.\tID=1\n");

  // Testing toString() with a feature with multiple records
  feature = new Feature();
  feature.add_record(parse_line("1\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  feature.add_record(parse_line("2\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  feature.add_record(parse_line("3\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  assert(feature.toString() == ("1\t.\t.\t.\t.\t.\t.\t.\tID=1\n" ~
                                "2\t.\t.\t.\t.\t.\t.\t.\tID=1\n" ~
                                "3\t.\t.\t.\t.\t.\t.\t.\tID=1"));

  // Testing recursive_to_string()
  feature = new Feature();
  feature.add_record(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1"));
  feature.add_record(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=2"));
  feature.add_child(new Feature(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=3")));
  feature.add_child(new Feature(parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=4")));
  assert(feature.recursive_to_string() == (".\t.\t.\t.\t.\t.\t.\t.\tID=1\n" ~
                                           ".\t.\t.\t.\t.\t.\t.\t.\tID=2\n" ~
                                           ".\t.\t.\t.\t.\t.\t.\t.\tID=3\n" ~
                                           ".\t.\t.\t.\t.\t.\t.\t.\tID=4"));
}

