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

  auto left = get_floating_delegate(node.children[0]);
  auto right = get_floating_delegate(node.children[1]);

  if ((left is null) || (right is null)) {
    filter = null;
  } else {
    if (node.type == NodeType.PLUS_OPERATOR)
      filter = (ref valid, record) { return left(valid, record) + right(valid, record); };
    if (node.type == NodeType.MINUS_OPERATOR)
      filter = (ref valid, record) { return left(valid, record) - right(valid, record); };
    if (node.type == NodeType.MULTIPLICATION_OPERATOR)
      filter = (ref valid, record) { return left(valid, record) * right(valid, record); };
    if (node.type == NodeType.DIVISION_OPERATOR)
      filter = (ref valid, record) { return left(valid, record) / right(valid, record); };
  }

  return filter;
}

version(unittest) {
  import std.exception;
  import bio.gff3.attribute;
}

unittest {
  auto node = new Node(NodeType.VALUE);
  node.text = "1.1";
  bool valid = true;
  auto op = get_floating_delegate(node);
  assert(op(valid, new Record()) == 1.1);

  node = new Node(NodeType.VALUE);
  node.text = "invalid";
  assert(get_floating_delegate(node) is null);

  node = new Node(NodeType.FIELD_OPERATOR);
  node.text = "field";
  node.parameter = "feature";
  op = get_floating_delegate(node);
  valid = true;
  auto record = new Record();
  record.feature = "2.2";
  assert(op(valid, record) == 2.2);

  node = new Node(NodeType.FIELD_OPERATOR);
  node.text = "field";
  node.parameter = "feature";
  op = get_floating_delegate(node);
  valid = true;
  record = new Record();
  record.feature = "invalid";
  op(valid, record);
  assert(!valid);

  node = new Node(NodeType.ATTR_OPERATOR);
  node.text = "attr";
  node.parameter = "ID";
  op = get_floating_delegate(node);
  valid = true;
  record = new Record();
  record.attributes["ID"] = AttributeValue(["3.3"]);
  assert(op(valid, record) == 3.3);

  node = new Node(NodeType.ATTR_OPERATOR);
  node.text = "attr";
  node.parameter = "ID";
  op = get_floating_delegate(node);
  valid = true;
  record = new Record();
  record.attributes["ID"] = AttributeValue(["invalid"]);
  op(valid, record);
  assert(!valid);

  auto brackets_node = new Node(NodeType.BRACKETS);
  brackets_node.text = "(";
  node = new Node(NodeType.FIELD_OPERATOR);
  node.text = "field";
  node.parameter = "feature";
  brackets_node.children = [node];
  op = get_floating_delegate(brackets_node);
  valid = true;
  record = new Record();
  record.feature = "4.4";
  assert(op(valid, record) == 4.4);

  brackets_node = new Node(NodeType.BRACKETS);
  brackets_node.text = "(";
  node = new Node(NodeType.FIELD_OPERATOR);
  node.text = "field";
  node.parameter = "feature";
  brackets_node.children = [node];
  op = get_floating_delegate(brackets_node);
  valid = true;
  record = new Record();
  record.feature = "invalid";
  op(valid, record);
  assert(!valid);

  node = new Node(NodeType.PLUS_OPERATOR);
  auto left_node = new Node(NodeType.VALUE);
  left_node.text = "1.5";
  auto right_node = new Node(NodeType.VALUE);
  right_node.text = "2.0";
  node.children = [left_node, right_node];
  op = get_floating_delegate(node);
  valid = true;
  assert(op(valid, new Record()) == 3.5);

  node = new Node(NodeType.MINUS_OPERATOR);
  left_node = new Node(NodeType.VALUE);
  left_node.text = "2.0";
  right_node = new Node(NodeType.VALUE);
  right_node.text = "1.5";
  node.children = [left_node, right_node];
  op = get_floating_delegate(node);
  valid = true;
  assert(op(valid, new Record()) == 0.5);

  node = new Node(NodeType.MULTIPLICATION_OPERATOR);
  left_node = new Node(NodeType.VALUE);
  left_node.text = "2.0";
  right_node = new Node(NodeType.VALUE);
  right_node.text = "0.5";
  node.children = [left_node, right_node];
  op = get_floating_delegate(node);
  valid = true;
  assert(op(valid, new Record()) == 1.0);

  node = new Node(NodeType.DIVISION_OPERATOR);
  left_node = new Node(NodeType.VALUE);
  left_node.text = "4.0";
  right_node = new Node(NodeType.VALUE);
  right_node.text = "0.5";
  node.children = [left_node, right_node];
  op = get_floating_delegate(node);
  valid = true;
  assert(op(valid, new Record()) == 8.0);

  node = new Node(NodeType.DIVISION_OPERATOR);
  assertThrown(get_floating_delegate(node));

  node = new Node(NodeType.DIVISION_OPERATOR);
  left_node = new Node(NodeType.VALUE);
  left_node.text = "2.0";
  node.children = [left_node];
  assertThrown(get_floating_delegate(node));

  node = new Node(NodeType.DIVISION_OPERATOR);
  left_node = new Node(NodeType.VALUE);
  left_node.text = "1.0";
  right_node = new Node(NodeType.VALUE);
  right_node.text = "abc";
  node.children = [left_node, right_node];
  assert(get_floating_delegate(node) is null);

  node = new Node(NodeType.AND_OPERATOR);
  assert(get_floating_delegate(node) is null);
}

