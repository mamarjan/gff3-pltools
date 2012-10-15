module bio.gff3.filtering.filtering;

import std.string, std.conv;
import bio.gff3.field, bio.gff3.filtering.field_accessor,
       bio.gff3.filtering.tokenizer, bio.gff3.filtering.node_tree.node,
       bio.gff3.filtering.node_tree.generate;
import util.split_line, util.is_float, util.is_integer;

public import bio.gff3.filtering.common;

/**
 * Converts a filtering expression to a RecordFilter delegate, which
 * is a delegate which takes one Record object and returns true or
 * false, which is equivalent to whether the objects fulfills the
 * criteria stated in the filtering expression.
 *
 * An example of a filtering expression would be "field feature == CDS".
 */
RecordFilter string_to_filter(string filtering_expression) {
  RecordFilter filter = extract_tokens(filtering_expression)
                            .generate_tree()
                            .get_bool_delegate();

  if ((filter is null) && (filtering_expression.strip().length != 0))
    throw new Exception("Result of filtering expression should be boolean");

  return filter;
}

package:

/*******************************************************************************
 * The following part is about getting a delegate out of a tree of nodes, which
 * can then be used for filtering.
 ******************************************************************************/
BooleanDelegate get_bool_delegate(Node node) {
  BooleanDelegate filter;

  final switch(node.type) {
    case NodeType.NONE:
      filter = (record) { return true; };
      break;
    case NodeType.AND_OPERATOR:
    case NodeType.OR_OPERATOR:
      if (node.children.length != 2)
        throw new Exception(node.text ~ " requires two operands");
      auto AND_OR_left = get_bool_delegate(node.children[0]);
      auto AND_OR_right = get_bool_delegate(node.children[1]);
      if ((AND_OR_left is null) || (AND_OR_right is null))
        throw new Exception(node.text ~ " requires two boolean operands");
      if (node.type == NodeType.AND_OPERATOR)
        filter = (record) { return AND_OR_left(record) && AND_OR_right(record); };
      if (node.type == NodeType.OR_OPERATOR)
        filter = (record) { return AND_OR_left(record) || AND_OR_right(record); };
      break;
    case NodeType.NOT_OPERATOR:
      if (node.children.length != 1)
        throw new Exception("not requires one operand");
      auto NOT_right = get_bool_delegate(node.children[0]);
      if (NOT_right is null)
        throw new Exception(node.text ~ " requires one boolean operand");
      filter = (record) { return !NOT_right(record); };
      break;
    case NodeType.CONTAINS_OPERATOR:
    case NodeType.STARTS_WITH_OPERATOR:
      if (node.children.length != 2)
        throw new Exception(node.text ~ " requires two operands");
      auto STRING_OP_left = get_string_delegate(node.children[0]);
      auto STRING_OP_right = get_string_delegate(node.children[1]);
      if ((STRING_OP_left is null) || (STRING_OP_right is null))
        throw new Exception(node.text ~ " requires two boolean operands");
      if (node.type == NodeType.CONTAINS_OPERATOR)
        filter = (record) { return std.string.indexOf(STRING_OP_left(record), STRING_OP_right(record)) > -1; };
      if (node.type == NodeType.STARTS_WITH_OPERATOR)
        filter = (record) { return STRING_OP_left(record).startsWith(STRING_OP_right(record)); };
      break;
    case NodeType.EQUALS_OPERATOR:
    case NodeType.NOT_EQUALS_OPERATOR:
    case NodeType.GREATER_THAN_OPERATOR:
    case NodeType.LOWER_THAN_OPERATOR:
    case NodeType.GREATER_THAN_OR_EQUALS_OPERATOR:
    case NodeType.LOWER_THAN_OR_EQUALS_OPERATOR:
      if (node.children.length != 2)
        throw new Exception(node.text ~ " requires two operands");
      auto COMP_OP_double_left = get_double_delegate(node.children[0]);
      auto COMP_OP_double_right = get_double_delegate(node.children[1]);
      if ((COMP_OP_double_left !is null) && (COMP_OP_double_right !is null)) {
        if (node.type == NodeType.EQUALS_OPERATOR)
            filter = (record) { return COMP_OP_double_left(record) == COMP_OP_double_right(record); };
        if (node.type == NodeType.NOT_EQUALS_OPERATOR)
          filter = (record) { return COMP_OP_double_left(record) != COMP_OP_double_right(record); };
        if (node.type == NodeType.GREATER_THAN_OPERATOR)
          filter = (record) { return COMP_OP_double_left(record) > COMP_OP_double_right(record); };
        if (node.type == NodeType.LOWER_THAN_OPERATOR)
          filter = (record) { return COMP_OP_double_left(record) < COMP_OP_double_right(record); };
        if (node.type == NodeType.GREATER_THAN_OR_EQUALS_OPERATOR)
          filter = (record) { return COMP_OP_double_left(record) >= COMP_OP_double_right(record); };
        if (node.type == NodeType.LOWER_THAN_OR_EQUALS_OPERATOR)
          filter = (record) { return COMP_OP_double_left(record) <= COMP_OP_double_right(record); };
        break; // Operators can be converted to double, finish
      }
      auto COMP_OP_long_left = get_long_delegate(node.children[0]);
      auto COMP_OP_long_right = get_long_delegate(node.children[1]);
      if ((COMP_OP_long_left !is null) && (COMP_OP_long_right !is null)) {
        if (node.type == NodeType.EQUALS_OPERATOR)
            filter = (record) { return COMP_OP_long_left(record) == COMP_OP_long_right(record); };
        if (node.type == NodeType.NOT_EQUALS_OPERATOR)
          filter = (record) { return COMP_OP_long_left(record) != COMP_OP_long_right(record); };
        if (node.type == NodeType.GREATER_THAN_OPERATOR)
          filter = (record) { return COMP_OP_long_left(record) > COMP_OP_long_right(record); };
        if (node.type == NodeType.LOWER_THAN_OPERATOR)
          filter = (record) { return COMP_OP_long_left(record) < COMP_OP_long_right(record); };
        if (node.type == NodeType.GREATER_THAN_OR_EQUALS_OPERATOR)
          filter = (record) { return COMP_OP_long_left(record) >= COMP_OP_long_right(record); };
        if (node.type == NodeType.LOWER_THAN_OR_EQUALS_OPERATOR)
          filter = (record) { return COMP_OP_long_left(record) <= COMP_OP_long_right(record); };
        break; // Operators can be converted to integers, finish
      }
      auto COMP_OP_bool_left = get_bool_delegate(node.children[0]);
      auto COMP_OP_bool_right = get_bool_delegate(node.children[1]);
      if ((COMP_OP_bool_left !is null) && (COMP_OP_bool_right !is null)) {
        if (node.type == NodeType.EQUALS_OPERATOR)
          filter = (record) { return COMP_OP_bool_left(record) == COMP_OP_bool_right(record); };
        if (node.type == NodeType.NOT_EQUALS_OPERATOR)
          filter = (record) { return COMP_OP_bool_left(record) != COMP_OP_bool_right(record); };
        if (node.type == NodeType.GREATER_THAN_OPERATOR)
            filter = null;
        if (node.type == NodeType.LOWER_THAN_OPERATOR)
            filter = null;
        if (node.type == NodeType.GREATER_THAN_OR_EQUALS_OPERATOR)
            filter = null;
        if (node.type == NodeType.LOWER_THAN_OR_EQUALS_OPERATOR)
            filter = null;
        break; // Operators can be converted to booleans, finish
      }
      auto string_left = get_string_delegate(node.children[0]);
      auto string_right = get_string_delegate(node.children[1]);
      if ((string_left !is null) && (string_right !is null)) {
        if (node.type == NodeType.EQUALS_OPERATOR)
          filter = (record) { return string_left(record) == string_right(record); };
        if (node.type == NodeType.NOT_EQUALS_OPERATOR)
          filter = (record) { return string_left(record) != string_right(record); };
        if (node.type == NodeType.GREATER_THAN_OPERATOR)
          filter = null;
        if (node.type == NodeType.LOWER_THAN_OPERATOR)
          filter = null;
        if (node.type == NodeType.GREATER_THAN_OR_EQUALS_OPERATOR)
          filter = null;
        if (node.type == NodeType.LOWER_THAN_OR_EQUALS_OPERATOR)
          filter = null;
        break; // Operands are valid strings
      }
      throw new Exception(node.text ~ " requires two operands");
      break;
    case NodeType.BRACKETS:
      auto BRACKETS_right = get_bool_delegate(node.children[0]);
      if (BRACKETS_right is null)
        filter = null;
      else
        filter = (record) { return BRACKETS_right(record); };
      break;
    case NodeType.VALUE:
    case NodeType.FIELD_OPERATOR:
    case NodeType.ATTR_OPERATOR:
    case NodeType.PLUS_OPERATOR:
    case NodeType.MINUS_OPERATOR:
    case NodeType.MULTIPLICATION_OPERATOR:
    case NodeType.DIVISION_OPERATOR:
      filter = null;
      break;
  }

  return filter;
}

StringDelegate get_string_delegate(Node node) {
  StringDelegate filter;

  final switch(node.type) {
    case NodeType.VALUE:
      filter = (record) { return node.text; };
      break;
    case NodeType.FIELD_OPERATOR:
      filter = get_field_accessor(node.parameter);
      break;
    case NodeType.ATTR_OPERATOR:
      filter = (record) {
        return (node.parameter in record.attributes) ? record.attributes[node.parameter].first : null;
      };
      break;
    case NodeType.BRACKETS:
      filter = get_string_delegate(node.children[0]);
      break;
    case NodeType.NONE:
    case NodeType.AND_OPERATOR:
    case NodeType.OR_OPERATOR:
    case NodeType.NOT_OPERATOR:
    case NodeType.CONTAINS_OPERATOR:
    case NodeType.STARTS_WITH_OPERATOR:
    case NodeType.EQUALS_OPERATOR:
    case NodeType.NOT_EQUALS_OPERATOR:
    case NodeType.GREATER_THAN_OPERATOR:
    case NodeType.LOWER_THAN_OPERATOR:
    case NodeType.GREATER_THAN_OR_EQUALS_OPERATOR:
    case NodeType.LOWER_THAN_OR_EQUALS_OPERATOR:
    case NodeType.PLUS_OPERATOR:
    case NodeType.MINUS_OPERATOR:
    case NodeType.MULTIPLICATION_OPERATOR:
    case NodeType.DIVISION_OPERATOR:
      filter = null;
      break;
  }

  return filter;
}

DoubleDelegate get_double_delegate(Node node) {
  DoubleDelegate filter;

  final switch(node.type) {
    case NodeType.VALUE:
      if (is_float(node.text)) {
        double double_value = to!double(node.text);
        filter = (record) { return double_value; };
      } else {
        filter = null;
      }
      break;
    case NodeType.FIELD_OPERATOR:
      auto field_accessor = get_field_accessor(node.parameter);
      filter = (record) { return to!double(field_accessor(record)); };
      break;
    case NodeType.ATTR_OPERATOR:
      filter = (record) { return (node.parameter in record.attributes) ? to!double(record.attributes[node.parameter].first) : 0.0; };
      break;
    case NodeType.BRACKETS:
      filter = get_double_delegate(node.children[0]);
      break;
    case NodeType.PLUS_OPERATOR:
    case NodeType.MINUS_OPERATOR:
    case NodeType.MULTIPLICATION_OPERATOR:
    case NodeType.DIVISION_OPERATOR:
      if (node.children.length != 2)
        throw new Exception(node.text ~ " requires two operands");
      auto left_operand = get_double_delegate(node.children[0]);
      auto right_operand = get_double_delegate(node.children[1]);
      if ((left_operand is null) || (right_operand is null)) {
        filter = null;
      } else {
        if (node.type == NodeType.PLUS_OPERATOR)
          filter = (record) { return left_operand(record) + right_operand(record); };
        if (node.type == NodeType.MINUS_OPERATOR)
          filter = (record) { return left_operand(record) - right_operand(record); };
        if (node.type == NodeType.MULTIPLICATION_OPERATOR)
          filter = (record) { return left_operand(record) * right_operand(record); };
        if (node.type == NodeType.DIVISION_OPERATOR)
          filter = (record) { return left_operand(record) / right_operand(record); };
      }
      break;
    case NodeType.NONE:
    case NodeType.AND_OPERATOR:
    case NodeType.OR_OPERATOR:
    case NodeType.NOT_OPERATOR:
    case NodeType.CONTAINS_OPERATOR:
    case NodeType.STARTS_WITH_OPERATOR:
    case NodeType.EQUALS_OPERATOR:
    case NodeType.NOT_EQUALS_OPERATOR:
    case NodeType.GREATER_THAN_OPERATOR:
    case NodeType.LOWER_THAN_OPERATOR:
    case NodeType.GREATER_THAN_OR_EQUALS_OPERATOR:
    case NodeType.LOWER_THAN_OR_EQUALS_OPERATOR:
      filter = null;
      break;
  }

  return filter;
}

LongDelegate get_long_delegate(Node node) {
  LongDelegate filter;

  final switch(node.type) {
    case NodeType.VALUE:
      if (is_integer(node.text)) {
        long integer_value = to!long(node.text);
        filter = (record) { return integer_value; };
      } else {
        filter = null;
      }
      break;
    case NodeType.FIELD_OPERATOR:
      auto field_accessor = get_field_accessor(node.parameter);
      filter = (record) { return to!long(field_accessor(record)); };
      break;
    case NodeType.ATTR_OPERATOR:
      filter = (record) { return (node.parameter in record.attributes) ? to!long(node.parameter) : 0; };
      break;
    case NodeType.BRACKETS:
      filter = get_long_delegate(node.children[0]);
      break;
    case NodeType.PLUS_OPERATOR:
    case NodeType.MINUS_OPERATOR:
    case NodeType.MULTIPLICATION_OPERATOR:
    case NodeType.DIVISION_OPERATOR:
      if (node.children.length != 2)
        throw new Exception(node.text ~ " requires two operands");
      auto left_operand = get_long_delegate(node.children[0]);
      auto right_operand = get_long_delegate(node.children[1]);
      if ((left_operand is null) || (right_operand is null)) {
        filter = null;
      } else {
        if (node.type == NodeType.PLUS_OPERATOR)
          filter = (record) { return left_operand(record) + right_operand(record); };
        if (node.type == NodeType.MINUS_OPERATOR)
          filter = (record) { return left_operand(record) - right_operand(record); };
        if (node.type == NodeType.MULTIPLICATION_OPERATOR)
          filter = (record) { return left_operand(record) * right_operand(record); };
        if (node.type == NodeType.DIVISION_OPERATOR)
          filter = (record) { return left_operand(record) / right_operand(record); };
      }
      break;
    case NodeType.NONE:
    case NodeType.AND_OPERATOR:
    case NodeType.OR_OPERATOR:
    case NodeType.NOT_OPERATOR:
    case NodeType.CONTAINS_OPERATOR:
    case NodeType.STARTS_WITH_OPERATOR:
    case NodeType.EQUALS_OPERATOR:
    case NodeType.NOT_EQUALS_OPERATOR:
    case NodeType.GREATER_THAN_OPERATOR:
    case NodeType.LOWER_THAN_OPERATOR:
    case NodeType.GREATER_THAN_OR_EQUALS_OPERATOR:
    case NodeType.LOWER_THAN_OR_EQUALS_OPERATOR:
      filter = null;
      break;
  }

  return filter;
}


import std.exception;
import bio.gff3.line;

unittest {
  auto record = parse_line("test\t.\t.\t.\t.\t.\t.\t.\t.");
  assert(string_to_filter(null)(record) == true);
  assert(string_to_filter("")(record) == true);
  assert(string_to_filter("field seqname == test")(record) == true);
  assert(string_to_filter("field seqname == bad")(record) == false);
  assert(string_to_filter("field seqname == tes")(record) == false);

  assert(string_to_filter("field seqname == 1")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field seqname == 1bad")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("field source == 2")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field source == 2bad")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("field feature == 3")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field feature == 3bad")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("field start == 4")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field start == 4bad")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("field end == 5")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field end == 5bad")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("field score == 6")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field score == 6bad")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("field strand == 7")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field strand == 7bad")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("field phase == 8")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field phase == 8bad")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("attr ID == 9")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("attr ID == 9bad")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);

  assert(string_to_filter("attr ID starts_with ab")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=abc")) == true);
  assert(string_to_filter("attr ID starts_with b")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=abc")) == false);
  assert(string_to_filter("field seqname starts_with ab")(parse_line("abc\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field seqname starts_with c")(parse_line("abc\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("field seqname contains 01")(parse_line("012\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field seqname contains 12")(parse_line("012\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field seqname contains 1")(parse_line("012\t2\t3\t4\t5\t6\t7\t8\tID=9")) == true);
  assert(string_to_filter("field seqname contains 55")(parse_line("012\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);
  assert(string_to_filter("not (attr ID == 9)")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=1")) == true);
  assert(string_to_filter("not (attr ID == 9)")(parse_line("1\t2\t3\t4\t5\t6\t7\t8\tID=9")) == false);

  // Test with invalid operators
  assertThrown(string_to_filter("(field source == 2) bad (field feature == 3)"));
  assertThrown(string_to_filter("(field source == 2 bad) and (field feature == 3)"));
  assertThrown(string_to_filter("(field source bad == 2) and (field feature == 3)"));
  assertThrown(string_to_filter("bad (field source == 2) and (field feature == 3)"));
  assertThrown(string_to_filter("bad (field source == 2) and (field feature == 3) bad"));
}

