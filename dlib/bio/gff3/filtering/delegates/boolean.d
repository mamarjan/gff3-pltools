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


