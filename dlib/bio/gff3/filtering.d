module bio.gff3.filtering;

import std.algorithm, std.string, std.conv;
import bio.gff3.record;

/**
Sample usage:

set_filter(AFTER(FIELD("score",
                       EQUAL("1.0"))
set_filter(BEFORE(OR(ATTRIBUTE("ID",
                               EQUALS("hello")),
                     ATTRIBUTE("Parent",
                               EQUALS("test"))));
*/
alias bool delegate(Record r) RecordPredicate;
alias bool delegate(string s) StringPredicate;

StringPredicate NO_BEFORE_FILTER;
RecordPredicate NO_AFTER_FILTER;

RecordPredicate FIELD(string field_name, StringPredicate p) {
    string function(Record r) field_accessor;
    switch(field_name) {
      case FIELD_SEQNAME:
        field_accessor = function string(Record r) { return r.seqname; };
        break;
      case FIELD_SOURCE:
        field_accessor = function string(Record r) { return r.source; };
        break;
      case FIELD_FEATURE:
        field_accessor = function string(Record r) { return r.feature; };
        break;
      case FIELD_START:
        field_accessor = function string(Record r) { return r.start; };
        break;
      case FIELD_END:
        field_accessor = function string(Record r) { return r.end; };
        break;
      case FIELD_SCORE:
        field_accessor = function string(Record r) { return r.score; };
        break;
      case FIELD_STRAND:
        field_accessor = function string(Record r) { return r.strand; };
        break;
      case FIELD_PHASE:
        field_accessor = function string(Record r) { return r.phase; };
        break;
      default:
        throw new Exception("Invalid field name: " ~ field_name);
        break;
  }

  return delegate bool(Record r) { return p(field_accessor(r)); };
}

auto ATTRIBUTE(string attribute_name, StringPredicate p) {
  return delegate bool(Record r) {
    string attribute_value;
    if (attribute_name in r.attributes)
      attribute_value = r.attributes[attribute_name];
    else
      attribute_value = "";
    return p(attribute_value);
  };
}
 
auto EQUALS(string value) { return delegate bool(string s) { return s == value; }; }
auto STARTS_WITH(string value) { return delegate bool(string s) { return s.startsWith(value); }; }
auto CONTAINS(string value) { return delegate bool(string s) { return std.string.indexOf(s, value) > -1; }; }

auto NOT(StringPredicate p) { return delegate bool(string s) { return !p(s); }; }
auto NOT(RecordPredicate p) { return delegate bool(Record r) { return !p(r); }; }

auto AND(StringPredicate[] predicates...) {
  if (predicates.length < 2)
    throw new Exception("Invalid number of members in an AND predicate: " ~ to!string(predicates.length));
  return delegate bool(string s) {
    bool result = true;
    foreach(predicate; predicates) {
      result = result && predicate(s);
      if (result == false)
        break;
    }
    return result;
  };
}

auto AND(RecordPredicate[] predicates...) {
  if (predicates.length < 2)
    throw new Exception("Invalid number of members in an AND predicate: " ~ to!string(predicates.length));
  return delegate bool(Record r) {
    bool result = true;
    foreach(predicate; predicates) {
      result = result && predicate(r);
      if (result == false)
        break;
    }
    return result;
  };
}


auto OR(StringPredicate[] predicates...) {
  if (predicates.length < 2)
    throw new Exception("Invalid number of members in an OR predicate: " ~ to!string(predicates.length));
  return delegate bool(string s) {
    bool result = false;
    foreach(predicate; predicates) {
      result = result || predicate(s);
      if (result == true)
        break;
    }
    return result;
  };
}

auto OR(RecordPredicate[] predicates...) {
  if (predicates.length < 2)
    throw new Exception("Invalid number of members in an OR predicate: " ~ to!string(predicates.length));
  return delegate bool(Record r) {
    bool result = false;
    foreach(predicate; predicates) {
      result = result || predicate(r);
      if (result == true)
        break;
    }
    return result;
  };
}

enum
   FIELD_SEQNAME = "seqname",
   FIELD_SOURCE  = "source",
   FIELD_FEATURE = "feature",
   FIELD_START   = "start",
   FIELD_END     = "end",
   FIELD_SCORE   = "score",
   FIELD_STRAND  = "strand",
   FIELD_PHASE   = "phase";

static this() {
  NO_BEFORE_FILTER = get_NO_BEFORE_FILTER();
  NO_AFTER_FILTER = get_NO_AFTER_FILTER();
}


private:

StringPredicate get_NO_BEFORE_FILTER() {
 return delegate bool(string s) { return true; };
}

RecordPredicate get_NO_AFTER_FILTER() {
 return delegate bool(Record r) { return true; };
}

import std.stdio;

unittest {
  writeln("Testing filtering predicates...");

  // Testing NO_BEFORE_FILTER
  assert(NO_BEFORE_FILTER("") == true);
  assert(NO_BEFORE_FILTER("test test") == true);

  // Testing NO_AFTER_FILTER
  assert(NO_AFTER_FILTER(new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1")) == true);

  // Testing FIELD
  auto test_record = new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9");
  assert(FIELD(FIELD_SEQNAME, EQUALS("1"))(test_record) == true);
  assert(FIELD(FIELD_SOURCE, EQUALS("2"))(test_record) == true);
  assert(FIELD(FIELD_FEATURE, EQUALS("3"))(test_record) == true);
  assert(FIELD(FIELD_START, EQUALS("4"))(test_record) == true);
  assert(FIELD(FIELD_END, EQUALS("5"))(test_record) == true);
  assert(FIELD(FIELD_SCORE, EQUALS("6"))(test_record) == true);
  assert(FIELD(FIELD_STRAND, EQUALS("7"))(test_record) == true);
  assert(FIELD(FIELD_PHASE, EQUALS("8"))(test_record) == true);

  assert(FIELD(FIELD_SEQNAME, EQUALS("bad value"))(test_record) == false);
  assert(FIELD(FIELD_SOURCE, EQUALS("bad value"))(test_record) == false);
  assert(FIELD(FIELD_FEATURE, EQUALS("bad value"))(test_record) == false);
  assert(FIELD(FIELD_START, EQUALS("bad value"))(test_record) == false);
  assert(FIELD(FIELD_END, EQUALS("bad value"))(test_record) == false);
  assert(FIELD(FIELD_SCORE, EQUALS("bad value"))(test_record) == false);
  assert(FIELD(FIELD_STRAND, EQUALS("bad value"))(test_record) == false);
  assert(FIELD(FIELD_PHASE, EQUALS("bad value"))(test_record) == false);

  test_record = new Record(" \t.\ta\t123\t456\t1.0\t+\t2\tID=9");
  assert(FIELD(FIELD_SEQNAME, EQUALS(" "))(test_record) == true);
  assert(FIELD(FIELD_SOURCE, EQUALS("."))(test_record) == true);
  assert(FIELD(FIELD_FEATURE, EQUALS("a"))(test_record) == true);
  assert(FIELD(FIELD_START, EQUALS("123"))(test_record) == true);
  assert(FIELD(FIELD_END, EQUALS("456"))(test_record) == true);
  assert(FIELD(FIELD_SCORE, EQUALS("1.0"))(test_record) == true);
  assert(FIELD(FIELD_STRAND, EQUALS("+"))(test_record) == true);
  assert(FIELD(FIELD_PHASE, EQUALS("2"))(test_record) == true);

  // Testing ATTRIBUTE
  test_record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1;test=value");
  assert(ATTRIBUTE("ID", EQUALS("1"))(test_record) == true);
  assert(ATTRIBUTE("Parent", EQUALS(""))(test_record) == true);
  assert(ATTRIBUTE("Parent", EQUALS("123"))(test_record) == false);
  assert(ATTRIBUTE("test", EQUALS("value"))(test_record) == true);

  test_record = new Record(".\t.\t.\t.\t.\t.\t.\t.\t.");
  assert(ATTRIBUTE("Parent", EQUALS("123"))(test_record) == false);
  assert(ATTRIBUTE("ID", EQUALS("123"))(test_record) == false);
  assert(ATTRIBUTE("ID", EQUALS(""))(test_record) == true);

  test_record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=");
  assert(ATTRIBUTE("ID", EQUALS(""))(test_record) == true);

  // Testing EQUALS
  assert(EQUALS("abc")("abc") == true);
  assert(EQUALS("123")("123") == true);
  assert(EQUALS("abc")("def") == false);
  assert(EQUALS("abc")("a") == false);
  assert(EQUALS("abc")("") == false);
  assert(EQUALS("")("abc") == false);
  assert(EQUALS("")("") == true);

  // Testing STARTS_WITH
  assert(STARTS_WITH("abc")("abc") == true);
  assert(STARTS_WITH("abc")("abcdef") == true);
  assert(STARTS_WITH("abc")("ab") == false);
  assert(STARTS_WITH("abc")("a") == false);
  assert(STARTS_WITH("abc")("") == false);
  assert(STARTS_WITH("")("") == true);
  assert(STARTS_WITH("")("abc") == true);
  assert(STARTS_WITH("a")("abc") == true);
  assert(STARTS_WITH("a")("") == false);
  assert(STARTS_WITH("123")("1234") == true);

  // Testing CONTAINS
  assert(CONTAINS("abc")("abc") == true);
  assert(CONTAINS("abc")("0abcdef") == true);
  assert(CONTAINS("a")("0abcdef") == true);
  assert(CONTAINS("")("0abcdef") == true);
  assert(CONTAINS("abc")("") == false);
  assert(CONTAINS("abc")("a") == false);
  assert(CONTAINS("abc")("b") == false);
  assert(CONTAINS("abc")("c") == false);

  // Testing NOT
  assert(NOT(EQUALS("abc"))("abc") == false);
  assert(NOT(EQUALS("abc"))("a") == true);
  assert(NOT(CONTAINS("abc"))("c") == true);
  assert(NOT(STARTS_WITH("123"))("1234") == false);
  test_record = new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9");
  assert(NOT(FIELD(FIELD_SEQNAME, EQUALS("1")))(test_record) == false);
  assert(NOT(ATTRIBUTE("ID", EQUALS("1")))(test_record) == true);

  // Testing AND
  test_record = new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9");
  assert(AND(FIELD(FIELD_SEQNAME, EQUALS("1")), FIELD(FIELD_SOURCE, EQUALS("2")))(test_record) == true);
  assert(AND(FIELD(FIELD_SEQNAME, EQUALS("1")), FIELD(FIELD_SOURCE, EQUALS("3")))(test_record) == false);
  assert(AND(FIELD(FIELD_SEQNAME, EQUALS("3")), FIELD(FIELD_SOURCE, EQUALS("2")))(test_record) == false);
  assert(AND(FIELD(FIELD_SEQNAME, EQUALS("3")), FIELD(FIELD_SOURCE, EQUALS("3")))(test_record) == false);
  assert(AND(NOT(FIELD(FIELD_SEQNAME, EQUALS("1"))), FIELD(FIELD_SOURCE, EQUALS("2")))(test_record) == false);
  assert(AND(NOT(FIELD(FIELD_SEQNAME, EQUALS("3"))), FIELD(FIELD_SOURCE, EQUALS("2")))(test_record) == true);
  assert(AND(NOT(FIELD(FIELD_SEQNAME, EQUALS("3"))),
             FIELD(FIELD_SOURCE, EQUALS("2")),
             FIELD(FIELD_SEQNAME, EQUALS("1")))(test_record) == true);

  // Testing OR
  test_record = new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9");
  assert(OR(FIELD(FIELD_SEQNAME, EQUALS("1")), FIELD(FIELD_SOURCE, EQUALS("2")))(test_record) == true);
  assert(OR(FIELD(FIELD_SEQNAME, EQUALS("1")), FIELD(FIELD_SOURCE, EQUALS("3")))(test_record) == true);
  assert(OR(FIELD(FIELD_SEQNAME, EQUALS("3")), FIELD(FIELD_SOURCE, EQUALS("2")))(test_record) == true);
  assert(OR(FIELD(FIELD_SEQNAME, EQUALS("3")), FIELD(FIELD_SOURCE, EQUALS("3")))(test_record) == false);
  assert(OR(NOT(FIELD(FIELD_SEQNAME, EQUALS("1"))), FIELD(FIELD_SOURCE, EQUALS("2")))(test_record) == true);
  assert(OR(NOT(FIELD(FIELD_SEQNAME, EQUALS("3"))), FIELD(FIELD_SOURCE, EQUALS("2")))(test_record) == true);
  assert(OR(NOT(FIELD(FIELD_SEQNAME, EQUALS("1"))),
            FIELD(FIELD_SOURCE, EQUALS("2")),
            FIELD(FIELD_SEQNAME, EQUALS("3")))(test_record) == true);
}
