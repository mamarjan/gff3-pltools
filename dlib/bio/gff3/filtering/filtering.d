module bio.gff3.filtering.filtering;

import bio.gff3.filtering.tokenizer, bio.gff3.filtering.generate_tree,
       bio.gff3.filtering.boolean_op_impl;

public import bio.gff3.filtering.common;

/**
 * Converts a filtering expression to a RecordFilter delegate, which
 * is a delegate which takes one Record object and returns true or
 * false, which is equivalent to whether the objects fulfills the
 * criteria stated in the filtering expression.
 *
 * An example of a filtering expression would be "field feature == CDS".
 *
 * See manual page for gff3-filter for more information on the syntax
 * of the filtering language used here.
 */
RecordFilter to_filter(string filtering_expression) {
  auto filter = extract_tokens(filtering_expression)
                        .generate_tree()
                        .get_bool_delegate();

  if (filter is null)
    throw new Exception("result of the filtering expression has to be a boolean value");

  return filter;
}

version(unittest) {
  import std.exception;
  import bio.gff3.line;
}

unittest {
  auto record = parse_line("test\t.\t.\t.\t.\t.\t.\t.\t.");
  assert(to_filter(null)(record) == true);
  assert(to_filter("")(record) == true);
  assert(to_filter(" \t\n\r")(record) == true);
  assert(to_filter("field seqname == test")(record) == true);
  assert(to_filter("field seqname == bad")(record) == false);
  assert(to_filter("field seqname == tes")(record) == false);

  assert(to_filter("field seqname == 1")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(to_filter("field seqname == 1bad")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(to_filter("field source == 2")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(to_filter("field source == 2bad")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(to_filter("field feature == 3")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(to_filter("field feature == 3bad")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(to_filter("field start == 4")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(to_filter("field start == 4bad")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(to_filter("field end == 5")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(to_filter("field end == 5bad")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(to_filter("field score == 6")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(to_filter("field score == 6bad")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(to_filter("field strand == 7")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(to_filter("field strand == 7bad")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(to_filter("field phase == 8")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(to_filter("field phase == 8bad")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(to_filter("attr ID == 9")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(to_filter("attr ID == 9bad")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);

  assert(to_filter("attr ID starts_with ab")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=abc")) == true);
  assert(to_filter("attr ID starts_with b")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=abc")) == false);
  assert(to_filter("field seqname starts_with ab")(parse_line("abc\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(to_filter("field seqname starts_with c")(parse_line("abc\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(to_filter("field seqname contains 01")(parse_line("012\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(to_filter("field seqname contains 12")(parse_line("012\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(to_filter("field seqname contains 1")(parse_line("012\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(to_filter("field seqname contains 55")(parse_line("012\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(to_filter("not (attr ID == 9)")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=1")) == true);
  assert(to_filter("not (attr ID == 9)")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);

  // Test with invalid operators
  assertThrown(to_filter("(field source == 2) bad (field feature == 3)"));
  assertThrown(to_filter("(field source == 2 bad) and (field feature == 3)"));
  assertThrown(to_filter("(field source bad == 2) and (field feature == 3)"));
  assertThrown(to_filter("bad (field source == 2) and (field feature == 3)"));
  assertThrown(to_filter("bad (field source == 2) and (field feature == 3) bad"));

  // Test with an expression not evaluating to a boolean
  assertThrown(to_filter("field feature"));
  assertThrown(to_filter("attr ID"));
  assertThrown(to_filter("field score + 5"));
}

