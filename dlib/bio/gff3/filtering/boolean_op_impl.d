module bio.gff3.filtering.delegates.boolean;

import std.string;
import bio.gff3.filtering.common, bio.gff3.filtering.node_tree.node,
       bio.gff3.filtering.delegates.string, bio.gff3.filtering.delegates.floating,
       bio.gff3.filtering.delegates.integer, bio.gff3.record;

RecordToBoolean get_bool_delegate(Node node) {
  RecordToBoolean filter;

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
      filter = get_cmp_delegate(node);
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

RecordToBoolean get_and_or_delegate(Node node) {
  RecordToBoolean filter;

  if (node.children.length != 2)
    throw new Exception(node.text ~ " requires two operands");

  auto left = get_bool_delegate(node.children[0]);
  auto right = get_bool_delegate(node.children[1]);
  if ((left is null) || (right is null))
    throw new Exception(node.text ~ " requires two boolean operands");

  switch(node.type) {
    case NodeType.AND_OPERATOR:
      filter = (record) { return left(record) && right(record); }; break;
    case NodeType.OR_OPERATOR:
      filter = (record) { return left(record) || right(record); };
    default:
      throw new Exception("This should never happen.");
      break;
  }

  return filter;
}

RecordToBoolean get_not_delegate(Node node) {
  if (node.children.length != 1)
    throw new Exception("not requires one operand");

  auto right = get_bool_delegate(node.children[0]);
  if (right is null)
    throw new Exception(node.text ~ " requires one boolean operand");

  return (record) { return !right(record); };
}

RecordToBoolean get_str_delegate(Node node) {
  RecordToBoolean filter;

  if (node.children.length != 2)
    throw new Exception(node.text ~ " requires two operands");

  auto left = get_string_delegate(node.children[0]);
  auto right = get_string_delegate(node.children[1]);
  if ((left is null) || (right is null))
    throw new Exception(node.text ~ " requires two boolean operands");

  switch(node.type) {
    case NodeType.CONTAINS_OPERATOR:
      filter = (record) { return std.string.indexOf(left(record), right(record)) > -1; };
      break;
    case NodeType.STARTS_WITH_OPERATOR:
      filter = (record) { return left(record).startsWith(right(record)); };
      break;
    default:
      throw new Exception("This should never happen.");
      break;
  }

  return filter;
}

RecordToBoolean get_cmp_delegate(Node node) {
  if (node.children.length != 2)
    throw new Exception(node.text ~ " requires two operands");

  RecordToBoolean filter;

  filter = get_cmp_float_delegate(node);
  if (filter !is null) return filter;
  filter = get_cmp_int_delegate(node);
  if (filter !is null) return filter;
  filter = get_cmp_bool_delegate(node);
  if (filter !is null) return filter;
  filter = get_cmp_string_delegate(node);
  if (filter !is null) return filter;

  throw new Exception(node.text ~ " requires two comparable operands");

  return null;
}

RecordToBoolean get_cmp_float_delegate(Node node) {
  RecordToBoolean filter;

  auto left = get_floating_delegate(node.children[0]);
  auto right = get_floating_delegate(node.children[1]);

  if ((left !is null) && (right !is null)) {
    switch(node.type) {
      case NodeType.EQUALS_OPERATOR:
        filter = (record) { return left(record) == right(record); }; break;
      case NodeType.NOT_EQUALS_OPERATOR:
        filter = (record) { return left(record) != right(record); }; break;
      case NodeType.GREATER_THAN_OPERATOR:
        filter = (record) { return left(record) > right(record); }; break;
      case NodeType.LOWER_THAN_OPERATOR:
        filter = (record) { return left(record) < right(record); }; break;
      case NodeType.GREATER_THAN_OR_EQUALS_OPERATOR:
        filter = (record) { return left(record) >= right(record); }; break;
      case NodeType.LOWER_THAN_OR_EQUALS_OPERATOR:
        filter = (record) { return left(record) <= right(record); }; break;
      default:
        throw new Exception("This should never happen.");
        break;
    }
  }

  return filter;
}

RecordToBoolean get_cmp_int_delegate(Node node) {
  RecordToBoolean filter;

  auto left = get_integer_delegate(node.children[0]);
  auto right = get_integer_delegate(node.children[1]);

  if ((left !is null) && (right !is null)) {
    switch(node.type) {
      case NodeType.EQUALS_OPERATOR:
        filter = (record) { return left(record) == right(record); }; break;
      case NodeType.NOT_EQUALS_OPERATOR:
        filter = (record) { return left(record) != right(record); }; break;
      case NodeType.GREATER_THAN_OPERATOR:
        filter = (record) { return left(record) > right(record); }; break;
      case NodeType.LOWER_THAN_OPERATOR:
        filter = (record) { return left(record) < right(record); }; break;
      case NodeType.GREATER_THAN_OR_EQUALS_OPERATOR:
        filter = (record) { return left(record) >= right(record); }; break;
      case NodeType.LOWER_THAN_OR_EQUALS_OPERATOR:
        filter = (record) { return left(record) <= right(record); }; break;
      default:
        throw new Exception("This should never happen.");
        break;
    }
  }

  return filter;
}

RecordToBoolean get_cmp_bool_delegate(Node node) {
  RecordToBoolean filter;

  auto left = get_bool_delegate(node.children[0]);
  auto right = get_bool_delegate(node.children[1]);

  if ((left !is null) && (right !is null)) {
    switch(node.type) {
      case NodeType.EQUALS_OPERATOR:
        filter = (record) { return left(record) == right(record); }; break;
      case NodeType.NOT_EQUALS_OPERATOR:
        filter = (record) { return left(record) != right(record); }; break;
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

RecordToBoolean get_cmp_string_delegate(Node node) {
  RecordToBoolean filter;

  auto left = get_string_delegate(node.children[0]);
  auto right = get_string_delegate(node.children[1]);

  if ((left !is null) && (right !is null)) {
    switch(node.type) {
      case NodeType.EQUALS_OPERATOR:
        filter = (record) { return left(record) == right(record); }; break;
      case NodeType.NOT_EQUALS_OPERATOR:
        filter = (record) { return left(record) != right(record); }; break;
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

