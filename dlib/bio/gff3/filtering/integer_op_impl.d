module bio.gff3.filtering.integer_op_impl;

import std.conv;
import bio.gff3.filtering.common, bio.gff3.filtering.node,
       bio.gff3.field_accessor, bio.gff3.record;
import util.is_integer;

package:

RecordToIntegerWV get_integer_delegate(Node node) {
  RecordToIntegerWV filter;

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
      filter = get_integer_delegate(node.children[0]);
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

RecordToIntegerWV get_value_delegate(Node node) {
  if (is_integer(node.text)) {
    long integer_value = to!long(node.text);
    return (ref valid, record) { return integer_value; };
  } else {
    return null;
  }
}

RecordToIntegerWV get_field_delegate(Node node) {
  auto field_accessor = get_field_accessor(node.parameter);
  return (ref valid, record) {
    if (is_integer(field_accessor(record))) {
      return to!long(field_accessor(record));
    } else {
      valid = false;
      return 0;
    }
  };
}

RecordToIntegerWV get_attr_delegate(Node node) {
  return (ref valid, record) {
    if (node.parameter in record.attributes) {
      if (is_integer(record.attributes[node.parameter].first))
        return to!long(record.attributes[node.parameter].first);
      else
        valid = false;
        return 0;
    } else {
      valid = false;
      return 0;
    }
  };
}

RecordToIntegerWV get_binary_delegate(Node node) {
  RecordToIntegerWV filter;

  if (node.children.length != 2)
    throw new Exception(node.text ~ " requires two operands");

  auto left_operand = get_integer_delegate(node.children[0]);
  auto right_operand = get_integer_delegate(node.children[1]);

  if ((left_operand is null) || (right_operand is null)) {
    filter = null;
  } else {
    switch(node.type) {
      case NodeType.PLUS_OPERATOR:
        filter = (ref valid, record) { return left_operand(valid, record) + right_operand(valid, record); };
        break;
      case NodeType.MINUS_OPERATOR:
        filter = (ref valid, record) { return left_operand(valid, record) - right_operand(valid, record); };
        break;
      case NodeType.MULTIPLICATION_OPERATOR:
        filter = (ref valid, record) { return left_operand(valid, record) * right_operand(valid, record); };
        break;
      case NodeType.DIVISION_OPERATOR:
        filter = (ref valid, record) { return left_operand(valid, record) / right_operand(valid, record); };
        break;
      default:
        throw new Exception("This should never happen.");
        break;
    }
  }

  return filter;
}

unittest {
  auto node = new Node(NodeType.VALUE);
  node.text = "123";
  bool valid = true;
  auto op = get_integer_delegate(node);
  assert(op(valid, new Record()) == 123);

  node = new Node(NodeType.VALUE);
  node.text = "invalid";
  assert(get_integer_delegate(node) is null);
}

