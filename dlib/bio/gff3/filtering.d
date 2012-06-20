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

FilterPredicate NO_FILTER;

auto FIELD(string field_name, FilterPredicate p) { return new FieldPredicate(field_name, p); }
auto ATTRIBUTE(string attribute_name, FilterPredicate p) { return new AttributePredicate(attribute_name, p); }

auto EQUALS(string value) { return new EqualsPredicate(value); }
auto STARTS_WITH(string value) { return new StartsWithPredicate(value); }
auto CONTAINS(string value) { return new ContainsPredicate(value); }

auto NOT(FilterPredicate p) { return new NotPredicate(p); }
auto AND(FilterPredicate[] predicates...) { return new AndPredicate(predicates); }
auto OR(FilterPredicate[] predicates...) { return new OrPredicate(predicates); }

class FilterPredicate {
  bool keep(string value) { return true; }
  bool keep(Record value) { return true; }
}

static this() {
  NO_FILTER = new FilterPredicate;
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

private:

class FieldPredicate : FilterPredicate {
  this(string field_name, FilterPredicate p) {
    this.p = p;
    switch(field_name) {
      case FIELD_SEQNAME:
        this.field_accessor = function string(Record r) { return r.seqname; };
        break;
      case FIELD_SOURCE:
        this.field_accessor = function string(Record r) { return r.source; };
        break;
      case FIELD_FEATURE:
        this.field_accessor = function string(Record r) { return r.feature; };
        break;
      case FIELD_START:
        this.field_accessor = function string(Record r) { return r.start; };
        break;
      case FIELD_END:
        this.field_accessor = function string(Record r) { return r.end; };
        break;
      case FIELD_SCORE:
        this.field_accessor = function string(Record r) { return r.score; };
        break;
      case FIELD_STRAND:
        this.field_accessor = function string(Record r) { return r.strand; };
        break;
      case FIELD_PHASE:
        this.field_accessor = function string(Record r) { return r.phase; };
        break;
      default:
        throw new Exception("Invalid field name: " ~ field_name);
        break;
    }
  }

  override bool keep(Record r) { return p.keep(field_accessor(r)); }

  FilterPredicate p;
  string function(Record r) field_accessor;
}

class AttributePredicate : FilterPredicate {
  this(string attribute_name, FilterPredicate p) {
    this.p = p;
    this.attribute_name = attribute_name;
  }

  override bool keep(Record r) {
    string attribute_value;
    if (attribute_name in r.attributes)
      attribute_value = r.attributes[attribute_name];
    else
      attribute_value = "";
    return p.keep(attribute_value);
  }

  FilterPredicate p;
  string attribute_name;
}

class EqualsPredicate : FilterPredicate {
  this(string value) { this.value = value; }
  override bool keep(string s) { return s == value; }

  string value; } 
class StartsWithPredicate : FilterPredicate {
  this(string value) { this.value = value; }
  override bool keep(string s) { return s.startsWith(value); }

  string value;
}

class ContainsPredicate : FilterPredicate {
  this(string value) { this.value = value; }
  override bool keep(string s) { return std.string.indexOf(s, value) > -1; }

  string value;
}

class NotPredicate : FilterPredicate {
  this(FilterPredicate p) { this.p = p; }
  override bool keep(string s) { return !(p.keep(s)); }

  FilterPredicate p;
}

class AndPredicate : FilterPredicate {
  this(FilterPredicate[] predicates...) {
    if (predicates.length < 2)
      throw new Exception("Invalid number of members in an AND predicate: " ~ to!string(predicates.length));
    this.predicates = new FilterPredicate[predicates.length];
    foreach(i, predicate; predicates) {
      this.predicates[i] = predicate;
    }
  }
  
  override bool keep(string s) {
    bool result = true;
    foreach(predicate; predicates) {
      result = result && predicate.keep(s);
      if (result == false)
        break;
    }
    return result;
  }

  override bool keep(Record r) {
    bool result = true;
    foreach(predicate; predicates) {
      result = result && predicate.keep(r);
      if (result == false)
        break;
    }
    return result;
  }

  FilterPredicate[] predicates;
}

class OrPredicate : FilterPredicate {
  this(FilterPredicate[] predicates...) {
    if (predicates.length < 2)
      throw new Exception("Invalid number of members in an OR predicate: " ~ to!string(predicates.length));
    this.predicates = new FilterPredicate[predicates.length];
    foreach(i, predicate; predicates) {
      this.predicates[i] = predicate;
    }
  }
  
  override bool keep(string s) {
    bool result = false;
    foreach(predicate; predicates) {
      result = result || predicate.keep(s);
      if (result == true)
        break;
    }
    return result;
  }

  override bool keep(Record r) {
    bool result = false;
    foreach(predicate; predicates) {
      result = result || predicate.keep(r);
      if (result == true)
        break;
    }
    return result;
  }

  FilterPredicate[] predicates;
}

