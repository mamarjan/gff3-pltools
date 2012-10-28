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
    case NodeType.VALUE:
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

