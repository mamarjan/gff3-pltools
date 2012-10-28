module bio.gff3.filtering.floating_op_impl;

import std.conv;
import bio.gff3.filtering.common, bio.gff3.filtering.node,
       bio.gff3.field_accessor, bio.gff3.record;
import util.is_float;

package:

RecordToFloatingWV get_floating_delegate(Node node) {
  RecordToFloatingWV filter;

  final switch(node.type) {
    case NodeType.VALUE:
      filter = get_value_delegate(node);
      break;
    case NodeType.FIELD_OPERATOR:
      filter = get_field_delegate(node);
      break;
    case NodeType.ATTR_OPERATOR:
      filter = get_attr_delegate(node);
      break;
    case NodeType.BRACKETS:
      filter = get_floating_delegate(node.children[0]);
      break;
    case NodeType.PLUS_OPERATOR:
    case NodeType.MINUS_OPERATOR:
    case NodeType.MULTIPLICATION_OPERATOR:
    case NodeType.DIVISION_OPERATOR:
      filter = get_binary_delegate(node);
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

private:

RecordToFloatingWV get_value_delegate(Node node) {
  if (is_float(node.text)) {
    double double_value = to!double(node.text);
    return (ref valid, record) { return double_value; };
  } else {
    return null;
  }
}

RecordToFloatingWV get_field_delegate(Node node) {
  auto field_accessor = get_field_accessor(node.parameter);
  return (ref valid, record) {
    if (is_float(field_accessor(record))) {
      return to!double(field_accessor(record));
    } else {
      valid = false;
      return 0.0;
    }
  };
}

RecordToFloatingWV get_attr_delegate(Node node) {
  return (ref valid, record) {
    if (node.parameter in record.attributes) {
      if (is_float(record.attributes[node.parameter].first))
        return to!double(record.attributes[node.parameter].first);
      else
        valid = false;
        return 0.0;
    } else {
      valid = false;
      return 0.0;
    }
  };
}

RecordToFloatingWV get_binary_delegate(Node node) {
  RecordToFloatingWV filter;

  if (node.children.length != 2)
    throw new Exception(node.text ~ " requires two operands");

  auto left_operand = get_floating_delegate(node.children[0]);
  auto right_operand = get_floating_delegate(node.children[1]);

  if ((left_operand is null) || (right_operand is null)) {
    filter = null;
  } else {
    if (node.type == NodeType.PLUS_OPERATOR)
      filter = (ref valid, record) { return left_operand(valid, record) + right_operand(valid, record); };
    if (node.type == NodeType.MINUS_OPERATOR)
      filter = (ref valid, record) { return left_operand(valid, record) - right_operand(valid, record); };
    if (node.type == NodeType.MULTIPLICATION_OPERATOR)
      filter = (ref valid, record) { return left_operand(valid, record) * right_operand(valid, record); };
    if (node.type == NodeType.DIVISION_OPERATOR)
      filter = (ref valid, record) { return left_operand(valid, record) / right_operand(valid, record); };
  }

  return filter;
}

