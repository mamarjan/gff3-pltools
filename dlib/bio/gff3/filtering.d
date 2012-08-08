module bio.gff3.filtering;

import std.algorithm, std.string, std.conv, std.array, std.ascii;
import bio.gff3.record;
import util.split_line;

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
    if (attribute_name in r.attributes) {
      auto attribute_value = r.attributes[attribute_name];
      if (attribute_value.is_multi) {
        foreach(value; attribute_value.all) {
          if (p(value))
            return true;
        }
        return false;
      } else {
        return p(attribute_value.first);
      }
    } else {
      return p("");
    }
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

RecordPredicate string_to_filter(string filter_string) {
  auto parts = split_filter_string(filter_string);
  string parameter;
  StringPredicate last_string_predicate;
  RecordPredicate last_record_predicate = NO_AFTER_FILTER;
  foreach(value; parts.reverse) {
    switch(value) {
      case "equals":
        last_string_predicate = EQUALS(parameter);
        parameter = null;
        break;
      case "contains":
        last_string_predicate = CONTAINS(parameter);
        parameter = null;
        break;
      case "starts_with":
        last_string_predicate = STARTS_WITH(parameter);
        parameter = null;
        break;
      case "attribute":
        last_record_predicate = ATTRIBUTE(parameter, last_string_predicate);
        last_string_predicate = null;
        parameter = null;
        break;
      case "field":
        last_record_predicate = FIELD(parameter, last_string_predicate);
        last_string_predicate = null;
        parameter = null;
        break;
      case "not":
        if (last_string_predicate !is null)
          last_string_predicate = NOT(last_string_predicate);
        else
          last_record_predicate = NOT(last_record_predicate);
        break;
      default:
        parameter = value;
    }
  }
  return last_record_predicate;
}


private:

string[] split_filter_string(string filter_string) {
  string[] parts;
  while(filter_string.length > 0) {
    string current = get_and_skip_next_field(filter_string, ':');
    while(current[$-1] == '\\')
      current = current[0..$-1] ~ ':' ~ get_and_skip_next_field(filter_string, ':');
    parts ~= current;
  }
  return parts;
}

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
  assert(FIELD(FIELD_SOURCE, EQUALS(""))(test_record) == true);
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

unittest {
  writeln("Testing split_filter_string()...");
  auto parts = split_filter_string("attribute:ID:equals:1");
  assert(parts.length == 4);
  assert(parts[0] == "attribute");
  assert(parts[1] == "ID");
  assert(parts[2] == "equals");
  assert(parts[3] == "1");

  parts = split_filter_string("attribute:ID\\:1:equals\\:1");
  assert(parts.length == 3);
  assert(parts[0] == "attribute");
  assert(parts[1] == "ID:1");
  assert(parts[2] == "equals:1");

  parts = split_filter_string("attribute\\:ID\\:1:equals\\:1");
  assert(parts.length == 2);
  assert(parts[0] == "attribute:ID:1");
  assert(parts[1] == "equals:1");
}

unittest {
  writeln("Testing string_to_filter()...");
  
  assert(string_to_filter("field:seqname:equals:1")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field:seqname:equals:1bad")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("field:source:equals:2")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field:source:equals:2bad")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("field:feature:equals:3")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field:feature:equals:3bad")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("field:start:equals:4")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field:start:equals:4bad")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("field:end:equals:5")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field:end:equals:5bad")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("field:score:equals:6")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field:score:equals:6bad")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("field:strand:equals:7")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field:strand:equals:7bad")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("field:phase:equals:8")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field:phase:equals:8bad")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("attribute:ID:equals:9")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("attribute:ID:equals:9bad")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);

  assert(string_to_filter("attribute:ID:starts_with:ab")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=abc")) == true);
  assert(string_to_filter("attribute:ID:starts_with:b")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=abc")) == false);
  assert(string_to_filter("field:seqname:starts_with:ab")(new Record("abc\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field:seqname:starts_with:c")(new Record("abc\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("field:seqname:contains:01")(new Record("012\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field:seqname:contains:12")(new Record("012\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field:seqname:contains:1")(new Record("012\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field:seqname:contains:55")(new Record("012\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("not:attribute:ID:equals:9")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=1")) == true);
  assert(string_to_filter("not:attribute:ID:equals:9")(new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
}

alias bool delegate(Record r) RecordFilter;
alias string delegate(Record r) StringFilter;
alias long delegate(Record r) LongFilter;
alias double delegate(Record r) DoubleFilter;

RecordFilter new_string_to_filter(string filtering_expression) {
  if (filtering_expression.strip().length == 0)
    return NO_AFTER_FILTER;
  else {
    string[] tokens = extract_tokens(filtering_expression);
    return NO_AFTER_FILTER;
  }
}

string[] extract_tokens(string expression) {
  Appender!(string[]) tokens;

  expression = reduce_double_whitespace(expression);

  while(expression.length != 0) {
    if ((expression[0] == '(') || (expression[0] == ')')) {
      tokens.put(expression[0..1]);
      expression = expression[1..$].stripLeft();
    } else if (expression[0] == '"') {
      expression = expression[1..$];
      size_t end_index = std.string.indexOf(expression[0..$], '\"');
      if (end_index == -1)
        throw new Exception("Could not find second \"");
      else {
        tokens.put(expression[0..end_index]);
        expression = expression[(end_index+1)..$].stripLeft();
      }
    } else {
      size_t next_delim_index = expression.first_of("() ");
      if (next_delim_index == -1) {
        tokens.put(expression);
        expression = null;
      } else {
        tokens.put(expression[0..next_delim_index]);
        expression = expression[next_delim_index..$].stripLeft();
      }
    }
  }

  return tokens.data;
}

unittest {
  writeln("Testing extract_tokens()...");

  assert(extract_tokens("").length == 0);
  assert(extract_tokens("field seqname == test") == ["field", "seqname", "==", "test"] );
  assert(extract_tokens("(field seqname) == test") == ["(", "field", "seqname", ")", "==", "test"] );
  assert(extract_tokens("  (  field \tseqname  )  == \n test") == ["(", "field", "seqname", ")", "==", "test"] );
  assert(extract_tokens("((field seqname) == test) and (attrib ID == test2)") ==
           ["(", "(", "field", "seqname", ")", "==", "test", ")", "and", "(", "attrib", "ID", "==", "test2", ")"] );
  assert(extract_tokens("field seqname == \"test\"") == ["field", "seqname", "==", "test"] );
  assert(extract_tokens("field seqname == \"test data\"") == ["field", "seqname", "==", "test data"] );
  assert(extract_tokens("((field \" seqname\") == test) and (attrib \"ID test\" == test2)") ==
           ["(", "(", "field", " seqname", ")", "==", "test", ")", "and", "(", "attrib", "ID test", "==", "test2", ")"] );
}

string reduce_double_whitespace(string expression) {
  Appender!string app;

  foreach(i, c; expression) {
    if (c.isWhite())
      if ((i == 0) || (expression[i-1].isWhite()))
        continue;
      else
        app.put(' ');
    else
      app.put(c);
  }

  return app.data.stripRight();
}

unittest {
  writeln("Testing reduce_double_whitespace()...");

  assert(reduce_double_whitespace("  aa  bb\t  c   ") == "aa bb c");
  assert(reduce_double_whitespace("  (aa  bb  )   c   ") == "(aa bb ) c");
}

size_t first_of(string data, string what) {
  size_t current_index = -1;
  foreach(c; what) {
    auto index = std.string.indexOf(data, c);
    if (index != -1)
      current_index = min(index, current_index);
  }
  
  return current_index;
}

unittest {
  writeln("Testing fist_of()...");

  assert(first_of("abc", "bc") == 1);
  assert(first_of("abc", "bd") == 1);
  assert(first_of("abc", "cb") == 1);
  assert(first_of("abc", "cd") == 2);
  assert(first_of("abc", "abc") == 0);
  assert(first_of("abc", "abcd") == 0);
  assert(first_of("abc", "cdb") == 1);
}

class Node {
  string text;
  Node parent;
  Node[] children;
}

unittest {
  auto record = new Record("test\t.\t.\t.\t.\t.\t.\t.\t.");
  //assert(new_string_to_filter("")(record) == true);
  //assert(new_string_to_filter("field seqname == test")(record) == true);
  //assert(new_string_to_filter("field seqname == bad")(record) == false);
  //assert(new_string_to_filter("field seqname == tes")(record) == false);
}

