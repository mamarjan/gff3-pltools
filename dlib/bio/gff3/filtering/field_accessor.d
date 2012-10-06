module bio.gff3.filtering.field_accessor;

import bio.gff3.filtering.common, bio.gff3.field;

/**
 * Returns a delegate which when given a Record object returns
 * the field which was specified when calling this function.
 * It supports only lower case field names, and allowed field
 * names can be found in bio.gff3.field module.
 */
StringDelegate get_field_accessor(string field_name) {
  StringDelegate field_accessor;
  switch(field_name) {
    case FIELD_SEQNAME:
      field_accessor = (record) { return record.seqname; };
      break;
    case FIELD_SOURCE:
      field_accessor = (record) { return record.source; };
      break;
    case FIELD_FEATURE:
      field_accessor = (record) { return record.feature; };
      break;
    case FIELD_START:
      field_accessor = (record) { return record.start; };
      break;
    case FIELD_END:
      field_accessor = (record) { return record.end; };
      break;
    case FIELD_SCORE:
      field_accessor = (record) { return record.score; };
      break;
    case FIELD_STRAND:
      field_accessor = (record) { return record.strand; };
      break;
    case FIELD_PHASE:
      field_accessor = (record) { return record.phase; };
      break;
    default:
      throw new Exception("Invalid field name: " ~ field_name);
      break;
  }

  return field_accessor;
}

import std.exception;
import bio.gff3.record;

unittest {
  auto record = new Record();
  with (record) {
    seqname = "1";
    source = "2";
    feature = "3";
    start = "4";
    end = "5";
    score = "6";
    strand = "7";
    phase = "8";
  }

  assert(get_field_accessor(FIELD_SEQNAME)(record) == "1");
  assert(get_field_accessor(FIELD_SOURCE)(record) == "2");
  assert(get_field_accessor(FIELD_FEATURE)(record) == "3");
  assert(get_field_accessor(FIELD_START)(record) == "4");
  assert(get_field_accessor(FIELD_END)(record) == "5");
  assert(get_field_accessor(FIELD_SCORE)(record) == "6");
  assert(get_field_accessor(FIELD_STRAND)(record) == "7");
  assert(get_field_accessor(FIELD_PHASE)(record) == "8");

  // No support for upper or mixed case field names
  assertThrown(get_field_accessor("Seqname"));
  assertThrown(get_field_accessor("SEQNAME"));

  // Also, any other word should result in an exception
  assertThrown(get_field_accessor("badfieldname"));
}

