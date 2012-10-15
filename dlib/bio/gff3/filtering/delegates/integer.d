module bio.gff3.filtering.delegates.integer;

import std.conv;
import bio.gff3.filtering.common, bio.gff3.filtering.node_tree.node,
       bio.gff3.filtering.field_accessor;
import util.is_integer;

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


