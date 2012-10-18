module bio.gff3.filtering.common;

import bio.gff3.record;

alias RecordToBoolean RecordFilter;
alias bool delegate(string s) StringFilter;

StringFilter NO_BEFORE_FILTER;
RecordFilter NO_AFTER_FILTER;


package:

static this() {
  NO_BEFORE_FILTER = get_NO_BEFORE_FILTER();
  NO_AFTER_FILTER = get_NO_AFTER_FILTER();
}

StringFilter get_NO_BEFORE_FILTER() {
 return (s) { return true; };
}

RecordFilter get_NO_AFTER_FILTER() {
 return (r) { return true; };
}

