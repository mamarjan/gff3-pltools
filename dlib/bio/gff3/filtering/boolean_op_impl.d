module bio.gff3.filtering.boolean_op_impl;

import std.string;
import bio.gff3.filtering.common, bio.gff3.filtering.node,
       bio.gff3.filtering.string_op_impl, bio.gff3.filtering.floating_op_impl,
       bio.gff3.filtering.integer_op_impl, bio.gff3.record,
       bio.gff3.field_accessor;

package:

RecordToBooleanWV get_bool_delegate(Node node) {
  RecordToBooleanWV filter;

  final switch(node.type) {
    case NodeType.NONE:
      filter = (ref valid, record) { return true; };
      break;
    case NodeType.VALUE:
      filter = get_value_delegate(node);
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
      filter = get_cmp_delegate(node);
      break;
    case NodeType.BRACKETS:
      filter = get_bool_delegate(node.children[0]);
      break;
    case NodeType.FIELD_OPERATOR:
      filter = get_field_delegate(node);
      break;
    case NodeType.ATTR_OPERATOR:
      filter = get_attr_delegate(node);
      break;
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

RecordToBooleanWV get_and_or_delegate(Node node) {
  RecordToBooleanWV filter;

  if (node.children.length != 2)
    throw new Exception(node.text ~ " requires two operands");

  auto left = get_bool_delegate(node.children[0]);
  auto right = get_bool_delegate(node.children[1]);
  if ((left is null) || (right is null))
    throw new Exception(node.text ~ " requires two boolean operands");

  switch(node.type) {
    case NodeType.AND_OPERATOR:
      filter = (ref valid, record) { return left(valid, record) && right(valid, record); }; break;
    case NodeType.OR_OPERATOR:
      filter = (ref valid, record) { return left(valid, record) || right(valid, record); }; break;
    default:
      throw new Exception("This should never happen.");
      break;
  }

  return filter;
}

RecordToBooleanWV get_not_delegate(Node node) {
  if (node.children.length != 1)
    throw new Exception("not requires one operand");

  auto right = get_bool_delegate(node.children[0]);
  if (right is null)
    throw new Exception(node.text ~ " requires one boolean operand");

  return (ref valid, record) { return !right(valid, record); };
}

RecordToBooleanWV get_str_delegate(Node node) {
  RecordToBooleanWV filter;

  if (node.children.length != 2)
    throw new Exception(node.text ~ " requires two operands");

  auto left = get_string_delegate(node.children[0]);
  auto right = get_string_delegate(node.children[1]);
  if ((left is null) || (right is null))
    throw new Exception(node.text ~ " requires two boolean operands");

  switch(node.type) {
    case NodeType.CONTAINS_OPERATOR:
      filter = (ref valid, record) { return std.string.indexOf(left(valid, record), right(valid, record)) > -1; };
      break;
    case NodeType.STARTS_WITH_OPERATOR:
      filter = (ref valid, record) { return left(valid, record).startsWith(right(valid, record)); };
      break;
    default:
      throw new Exception("This should never happen.");
      break;
  }

  return filter;
}

RecordToBooleanWV get_cmp_delegate(Node node) {
  if (node.children.length != 2)
    throw new Exception(node.text ~ " requires two operands");

  RecordToBooleanWV filter;

  filter = get_cmp_int_delegate(node);
  if (filter !is null) return filter;
  filter = get_cmp_float_delegate(node);
  if (filter !is null) return filter;
  filter = get_cmp_bool_delegate(node);
  if (filter !is null) return filter;
  filter = get_cmp_string_delegate(node);
  if (filter !is null) return filter;

  throw new Exception(node.text ~ " requires two comparable operands");

  return null;
}

RecordToBooleanWV get_cmp_float_delegate(Node node) {
  RecordToBooleanWV filter;

  auto left = get_floating_delegate(node.children[0]);
  auto right = get_floating_delegate(node.children[1]);

  if ((left !is null) && (right !is null)) {
    switch(node.type) {
      case NodeType.EQUALS_OPERATOR:
        filter = (ref valid, record) { return left(valid, record) == right(valid, record); }; break;
      case NodeType.NOT_EQUALS_OPERATOR:
        filter = (ref valid, record) { return left(valid, record) != right(valid, record); }; break;
      case NodeType.GREATER_THAN_OPERATOR:
        filter = (ref valid, record) { return left(valid, record) > right(valid, record); }; break;
      case NodeType.LOWER_THAN_OPERATOR:
        filter = (ref valid, record) { return left(valid, record) < right(valid, record); }; break;
      case NodeType.GREATER_THAN_OR_EQUALS_OPERATOR:
        filter = (ref valid, record) { return left(valid, record) >= right(valid, record); }; break;
      case NodeType.LOWER_THAN_OR_EQUALS_OPERATOR:
        filter = (ref valid, record) { return left(valid, record) <= right(valid, record); }; break;
      default:
        throw new Exception("This should never happen.");
        break;
    }
  }

  return filter;
}

RecordToBooleanWV get_cmp_int_delegate(Node node) {
  RecordToBooleanWV filter;

  auto left = get_integer_delegate(node.children[0]);
  auto right = get_integer_delegate(node.children[1]);

  if ((left !is null) && (right !is null)) {
    switch(node.type) {
      case NodeType.EQUALS_OPERATOR:
        filter = (ref valid, record) { return left(valid, record) == right(valid, record); }; break;
      case NodeType.NOT_EQUALS_OPERATOR:
        filter = (ref valid, record) { return left(valid, record) != right(valid, record); }; break;
      case NodeType.GREATER_THAN_OPERATOR:
        filter = (ref valid, record) { return left(valid, record) > right(valid, record); }; break;
      case NodeType.LOWER_THAN_OPERATOR:
        filter = (ref valid, record) { return left(valid, record) < right(valid, record); }; break;
      case NodeType.GREATER_THAN_OR_EQUALS_OPERATOR:
        filter = (ref valid, record) { return left(valid, record) >= right(valid, record); }; break;
      case NodeType.LOWER_THAN_OR_EQUALS_OPERATOR:
        filter = (ref valid, record) { return left(valid, record) <= right(valid, record); }; break;
      default:
        throw new Exception("This should never happen.");
        break;
    }
  }

  return filter;
}

RecordToBooleanWV get_cmp_bool_delegate(Node node) {
  RecordToBooleanWV filter;

  auto left = get_bool_delegate(node.children[0]);
  auto right = get_bool_delegate(node.children[1]);

  if ((left !is null) && (right !is null)) {
    switch(node.type) {
      case NodeType.EQUALS_OPERATOR:
        filter = (ref valid, record) { return left(valid, record) == right(valid, record); }; break;
      case NodeType.NOT_EQUALS_OPERATOR:
        filter = (ref valid, record) { return left(valid, record) != right(valid, record); }; break;
      case NodeType.GREATER_THAN_OPERATOR:
        filter = null; break;
      case NodeType.LOWER_THAN_OPERATOR:
        filter = null; break;
      case NodeType.GREATER_THAN_OR_EQUALS_OPERATOR:
        filter = null; break;
      case NodeType.LOWER_THAN_OR_EQUALS_OPERATOR:
        filter = null; break;
      default:
        throw new Exception("This should never happen.");
        break;
    }
  }

  return filter;
}

RecordToBooleanWV get_cmp_string_delegate(Node node) {
  RecordToBooleanWV filter;

  auto left = get_string_delegate(node.children[0]);
  auto right = get_string_delegate(node.children[1]);

  if ((left !is null) && (right !is null)) {
    switch(node.type) {
      case NodeType.EQUALS_OPERATOR:
        filter = (ref valid, record) { return left(valid, record) == right(valid, record); }; break;
      case NodeType.NOT_EQUALS_OPERATOR:
        filter = (ref valid, record) { return left(valid, record) != right(valid, record); }; break;
      case NodeType.GREATER_THAN_OPERATOR:
        filter = null; break;
      case NodeType.LOWER_THAN_OPERATOR:
        filter = null; break;
      case NodeType.GREATER_THAN_OR_EQUALS_OPERATOR:
        filter = null; break;
      case NodeType.LOWER_THAN_OR_EQUALS_OPERATOR:
        filter = null; break;
      default:
        throw new Exception("This should never happen.");
        break;
    }
  }

  return filter;
}

RecordToBooleanWV get_field_delegate(Node node) {
  auto field_accessor = get_field_accessor(node.parameter);
  return (ref valid, record) {
    if (field_accessor(record) == "true")
      return true;
    else if (field_accessor(record) == "false")
      return false;
    else {
      valid = false;
      return false;
    }
  };
}

RecordToBooleanWV get_attr_delegate(Node node) {
  return (ref valid, record) {
    if (node.parameter in record.attributes) {
      if (record.attributes[node.parameter].first == "true")
        return true;
      else if (record.attributes[node.parameter].first == "false")
        return false;
      else {
        valid = false;
        return false;
      }
    } else {
      valid = false;
      return false;
    }
  };
}

RecordToBooleanWV get_value_delegate(Node node) {
  if (node.text == "true")
    return (ref valid, record) { return true; };
  else if (node.text == "false")
    return (ref valid, record) { return false; };
  else
    return null;
}

version(unittest) {
  import std.exception;
  import bio.gff3.attribute;
}

unittest {
  auto node = new Node(NodeType.NONE);
  bool valid = true;
  auto op = get_bool_delegate(node);
  assert(op(valid, new Record()) == true);
  assert(valid);

  node = new Node(NodeType.VALUE);
  node.text = "true";
  valid = true;
  op = get_bool_delegate(node);
  assert(op(valid, new Record()) == true);
  assert(valid);

  node = new Node(NodeType.VALUE);
  node.text = "false";
  valid = true;
  op = get_bool_delegate(node);
  assert(op(valid, new Record()) == false);
  assert(valid);

  node = new Node(NodeType.VALUE);
  node.text = "invalid";
  valid = true;
  assert(get_bool_delegate(node) is null);

  node = new Node(NodeType.AND_OPERATOR);
  node.text = "and";
  auto left_node = new Node(NodeType.VALUE);
  left_node.text = "true";
  auto right_node = new Node(NodeType.VALUE);
  right_node.text = "true";
  node.children = [left_node, right_node];
  valid = true;
  op = get_bool_delegate(node);
  assert(op(valid, new Record()) == true);
  assert(valid);
  right_node.text = "false";
  valid = true;
  op = get_bool_delegate(node);
  assert(op(valid, new Record()) == false);
  assert(valid);

  node = new Node(NodeType.OR_OPERATOR);
  node.text = "or";
  left_node = new Node(NodeType.VALUE);
  left_node.text = "false";
  right_node = new Node(NodeType.VALUE);
  right_node.text = "false";
  node.children = [left_node, right_node];
  valid = true;
  op = get_bool_delegate(node);
  assert(op(valid, new Record()) == false);
  assert(valid);
  right_node.text = "true";
  valid = true;
  op = get_bool_delegate(node);
  assert(op(valid, new Record()) == true);
  assert(valid);

  node = new Node(NodeType.CONTAINS_OPERATOR);
  node.text = "contains";
  left_node = new Node(NodeType.VALUE);
  left_node.text = "example";
  right_node = new Node(NodeType.VALUE);
  right_node.text = "amp";
  node.children = [left_node, right_node];
  valid = true;
  op = get_bool_delegate(node);
  assert(op(valid, new Record()) == true);
  assert(valid);
  right_node.text = "abc";
  valid = true;
  op = get_bool_delegate(node);
  assert(op(valid, new Record()) == false);
  assert(valid);

  node = new Node(NodeType.STARTS_WITH_OPERATOR);
  node.text = "starts_with";
  left_node = new Node(NodeType.VALUE);
  left_node.text = "example";
  right_node = new Node(NodeType.VALUE);
  right_node.text = "exam";
  node.children = [left_node, right_node];
  valid = true;
  op = get_bool_delegate(node);
  assert(op(valid, new Record()) == true);
  assert(valid);
  right_node.text = "abc";
  valid = true;
  op = get_bool_delegate(node);
  assert(op(valid, new Record()) == false);
  assert(valid);

  node = new Node(NodeType.EQUALS_OPERATOR);
  node.text = "==";
  left_node = new Node(NodeType.VALUE);
  left_node.text = "123";
  right_node = new Node(NodeType.VALUE);
  right_node.text = "123";
  node.children = [left_node, right_node];
  valid = true;
  op = get_bool_delegate(node);
  assert(op(valid, new Record()) == true);
  assert(valid);
  right_node.text = "321";
  valid = true;
  op = get_bool_delegate(node);
  assert(op(valid, new Record()) == false);
  assert(valid);

  node = new Node(NodeType.BRACKETS);
  node.text = "(";
  left_node = new Node(NodeType.VALUE);
  left_node.text = "true";
  node.children = [left_node];
  valid = true;
  op = get_bool_delegate(node);
  assert(op(valid, new Record()) == true);
  assert(valid);
  left_node.text = "false";
  valid = true;
  op = get_bool_delegate(node);
  assert(op(valid, new Record()) == false);
  assert(valid);

  node = new Node(NodeType.FIELD_OPERATOR);
  node.text = "field";
  node.parameter = "feature";
  valid = true;
  op = get_bool_delegate(node);
  auto record = new Record();
  record.feature = "true";
  assert(op(valid, record) == true);
  assert(valid);
  valid = true;
  record.feature = "false";
  assert(op(valid, record) == false);
  assert(valid);
  valid = true;
  record.feature = "invalid";
  op(valid, record);
  assert(!valid);

  node = new Node(NodeType.FIELD_OPERATOR);
  node.text = "field";
  node.parameter = "invalid";
  assertThrown(get_bool_delegate(node));

  node = new Node(NodeType.ATTR_OPERATOR);
  node.text = "attr";
  node.parameter = "ID";
  valid = true;
  op = get_bool_delegate(node);
  record = new Record();
  record.attributes["ID"] = AttributeValue(["true"]);
  assert(op(valid, record) == true);
  assert(valid);
  valid = true;
  record.attributes["ID"] = AttributeValue(["false"]);
  assert(op(valid, record) == false);
  assert(valid);
  valid = true;
  record.attributes["ID"] = AttributeValue(["invalid"]);
  op(valid, record);
  assert(!valid);
}

