module bio.gff3.filtering.delegates.boolean;

import std.string;
import bio.gff3.filtering.common, bio.gff3.filtering.node_tree.node,
       bio.gff3.filtering.delegates.string, bio.gff3.filtering.delegates.floating,
       bio.gff3.filtering.delegates.integer;

BooleanDelegate get_bool_delegate(Node node) {
  BooleanDelegate filter;

  final switch(node.type) {
    case NodeType.NONE:
      filter = (record) { return true; };
      break;
    case NodeType.AND_OPERATOR:
    case NodeType.OR_OPERATOR:
      filter = get_and_or_delegate(node);
      break;
    case NodeType.NOT_OPERATOR:
      filter = get_not_delegate(node);
      break;
    case NodeType.CONTAINS_OPERATOR:
    case NodeType.STARTS_WITH_OPERATOR:
      filter = get_str_delegate(node);
      break;
    case NodeType.EQUALS_OPERATOR:
    case NodeType.NOT_EQUALS_OPERATOR:
    case NodeType.GREATER_THAN_OPERATOR:
    case NodeType.LOWER_THAN_OPERATOR:
    case NodeType.GREATER_THAN_OR_EQUALS_OPERATOR:
    case NodeType.LOWER_THAN_OR_EQUALS_OPERATOR:
      if (node.children.length != 2)
        throw new Exception(node.text ~ " requires two operands");
      filter = get_cmp_double_delegate(node);
      if (filter !is null) break;
      filter = get_cmp_long_delegate(node);
      if (filter !is null) break;
      filter = get_cmp_bool_delegate(node);
      if (filter !is null) break;
      filter = get_cmp_string_delegate(node);
      if (filter !is null) break;
      throw new Exception(node.text ~ " requires two operands");
      break;
    case NodeType.BRACKETS:
      filter = get_bool_delegate(node.children[0]);
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

private:

BooleanDelegate get_and_or_delegate(Node node) {
  BooleanDelegate filter;

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

  return filter;
}

BooleanDelegate get_not_delegate(Node node) {
  if (node.children.length != 1)
    throw new Exception("not requires one operand");

  auto NOT_right = get_bool_delegate(node.children[0]);
  if (NOT_right is null)
    throw new Exception(node.text ~ " requires one boolean operand");

  return (record) { return !NOT_right(record); };
}

BooleanDelegate get_str_delegate(Node node) {
  BooleanDelegate filter;

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

  return filter;
}

BooleanDelegate get_cmp_double_delegate(Node node) {
  BooleanDelegate filter;

  auto left = get_double_delegate(node.children[0]);
  auto right = get_double_delegate(node.children[1]);

  if ((left !is null) && (right !is null)) {
    if (node.type == NodeType.EQUALS_OPERATOR)
      filter = (record) { return left(record) == right(record); };
    if (node.type == NodeType.NOT_EQUALS_OPERATOR)
      filter = (record) { return left(record) != right(record); };
    if (node.type == NodeType.GREATER_THAN_OPERATOR)
      filter = (record) { return left(record) > right(record); };
    if (node.type == NodeType.LOWER_THAN_OPERATOR)
      filter = (record) { return left(record) < right(record); };
    if (node.type == NodeType.GREATER_THAN_OR_EQUALS_OPERATOR)
      filter = (record) { return left(record) >= right(record); };
    if (node.type == NodeType.LOWER_THAN_OR_EQUALS_OPERATOR)
      filter = (record) { return left(record) <= right(record); };
  }

  return filter;
}

BooleanDelegate get_cmp_long_delegate(Node node) {
  BooleanDelegate filter;

  auto left = get_long_delegate(node.children[0]);
  auto right = get_long_delegate(node.children[1]);

  if ((left !is null) && (right !is null)) {
    if (node.type == NodeType.EQUALS_OPERATOR)
        filter = (record) { return left(record) == right(record); };
    if (node.type == NodeType.NOT_EQUALS_OPERATOR)
      filter = (record) { return left(record) != right(record); };
    if (node.type == NodeType.GREATER_THAN_OPERATOR)
      filter = (record) { return left(record) > right(record); };
    if (node.type == NodeType.LOWER_THAN_OPERATOR)
      filter = (record) { return left(record) < right(record); };
    if (node.type == NodeType.GREATER_THAN_OR_EQUALS_OPERATOR)
      filter = (record) { return left(record) >= right(record); };
    if (node.type == NodeType.LOWER_THAN_OR_EQUALS_OPERATOR)
      filter = (record) { return left(record) <= right(record); };
  }

  return filter;
}

BooleanDelegate get_cmp_bool_delegate(Node node) {
  BooleanDelegate filter;

  auto left = get_bool_delegate(node.children[0]);
  auto right = get_bool_delegate(node.children[1]);

  if ((left !is null) && (right !is null)) {
    if (node.type == NodeType.EQUALS_OPERATOR)
      filter = (record) { return left(record) == right(record); };
    if (node.type == NodeType.NOT_EQUALS_OPERATOR)
      filter = (record) { return left(record) != right(record); };
    if (node.type == NodeType.GREATER_THAN_OPERATOR)
        filter = null;
    if (node.type == NodeType.LOWER_THAN_OPERATOR)
        filter = null;
    if (node.type == NodeType.GREATER_THAN_OR_EQUALS_OPERATOR)
        filter = null;
    if (node.type == NodeType.LOWER_THAN_OR_EQUALS_OPERATOR)
        filter = null;
  }

  return filter;
}

BooleanDelegate get_cmp_string_delegate(Node node) {
  BooleanDelegate filter;

  auto left = get_string_delegate(node.children[0]);
  auto right = get_string_delegate(node.children[1]);

  if ((left !is null) && (right !is null)) {
    if (node.type == NodeType.EQUALS_OPERATOR)
      filter = (record) { return left(record) == right(record); };
    if (node.type == NodeType.NOT_EQUALS_OPERATOR)
      filter = (record) { return left(record) != right(record); };
    if (node.type == NodeType.GREATER_THAN_OPERATOR)
      filter = null;
    if (node.type == NodeType.LOWER_THAN_OPERATOR)
      filter = null;
    if (node.type == NodeType.GREATER_THAN_OR_EQUALS_OPERATOR)
      filter = null;
    if (node.type == NodeType.LOWER_THAN_OR_EQUALS_OPERATOR)
      filter = null;
  }

  return filter;
}

