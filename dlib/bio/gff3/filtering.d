module bio.gff3.filtering;

class FilterPredicate {
  bool is_after() {
    return false;
  }

  bool is_before() {
    return false;
  }
}

/*
set_filter(AFTER(FIELD("score",
                       EQUAL("tralala"))
set_filter(BEFORE(OR(ATTRIBUTE("ID",
                               EQUALS("hello")),
                     ATTRIBUTE("Parent",
                               EQUALS("blah"))));
*/

class RecordPredicate : FilterPredicate {
  abstract bool keep(Record record);
}

class LinePredicate : FilterPredicate {
  abstract bool keep(string line);
}

FilterPredicate AFTER(RecordPredicate p) {
  return new AfterPredicate(p);
}

class AfterPredicate : RecordPredicate {
  this(RecordPredicate p) {
    this.p = p;
  }

  override bool is_after() {
    return true;
  }

  bool keep(Record record) {
    return p.keep(record);
  }

  RecordPredicate p;
}

FilterPredicate BEFORE(FilterPredicate p) {
  return new BeforePredicate(p);
}

class BeforePredicate : LinePredicate {
  this(FilterPredicate p) {
    this.p = p;
  }

  override bool is_before() {
    return true;
  }

  bool keep(string line) {
    p.keep(line);
  }

  LinePredicate p;
}
