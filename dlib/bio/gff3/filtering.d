module bio.gff3.filtering;

import std.algorithm, std.string, std.conv, std.array, std.ascii;
import bio.gff3.record;
import util.split_line, util.is_float, util.is_integer, util.reduce_whitespace;

alias bool delegate(Record r) RecordFilter;
alias bool delegate(string s) StringFilter;

StringFilter NO_BEFORE_FILTER;
RecordFilter NO_AFTER_FILTER;

enum
   FIELD_SEQNAME = "seqname",
   FIELD_SOURCE  = "source",
   FIELD_FEATURE = "feature",
   FIELD_START   = "start",
   FIELD_END     = "end",
   FIELD_SCORE   = "score",
   FIELD_STRAND  = "strand",
   FIELD_PHASE   = "phase";

static this() {
  NO_BEFORE_FILTER = get_NO_BEFORE_FILTER();
  NO_AFTER_FILTER = get_NO_AFTER_FILTER();
}

StringFilter get_NO_BEFORE_FILTER() {
 return delegate bool(string s) { return true; };
}

RecordFilter get_NO_AFTER_FILTER() {
 return delegate bool(Record r) { return true; };
}

alias RecordFilter BooleanDelegate;
alias string delegate(Record r) StringDelegate;
alias long delegate(Record r) LongDelegate;
alias double delegate(Record r) DoubleDelegate;

RecordFilter string_to_filter(string filtering_expression) {
  RecordFilter filter;
  if (filtering_expression.strip().length == 0)
    filter = NO_AFTER_FILTER;
  else {
    string[] tokens = extract_tokens(filtering_expression);
    Node root = generate_tree(tokens);
    filter = get_bool_delegate(root);
    if (filter is null) {
      throw new Exception("Result of filtering expression should be boolean");
    }
  }

  return filter;
}

private:

BooleanDelegate get_bool_delegate(Node node) {
  BooleanDelegate filter;

  final switch(node.type) {
    case NodeType.NONE:
      filter = delegate bool(Record record) { return true; };
      break;
    case NodeType.AND_OPERATOR:
    case NodeType.OR_OPERATOR:
      if (node.children.length != 2)
        throw new Exception(node.text ~ " requires two operands");
      auto and_or_left = get_bool_delegate(node.children[0]);
      auto and_or_right = get_bool_delegate(node.children[1]);
      if ((and_or_left is null) || (and_or_right is null))
        throw new Exception(node.text ~ " requires two boolean operands");
      switch(node.type) {
        case NodeType.AND_OPERATOR:
          filter = delegate bool(Record record) { return and_or_left(record) && and_or_right(record); };
          break;
        case NodeType.OR_OPERATOR:
          filter = delegate bool(Record record) { return and_or_left(record) || and_or_right(record); };
          break;
        default:
          throw new Exception("Error in the code, please report to the maintainer");
          break;
      }
      break;
    case NodeType.NOT_OPERATOR:
      if (node.children.length != 1)
        throw new Exception("not requires one operand");
      auto not_right = get_bool_delegate(node.children[0]);
      if (not_right is null)
        throw new Exception(node.text ~ " requires one boolean operand");
      filter = delegate bool(Record record) { return !not_right(record); };
      break;
    case NodeType.CONTAINS_OPERATOR:
    case NodeType.STARTS_WITH_OPERATOR:
      if (node.children.length != 2)
        throw new Exception("contains requires two operands");
      auto contains_left = get_string_delegate(node.children[0]);
      auto contains_right = get_string_delegate(node.children[1]);
      if ((contains_left is null) || (contains_right is null))
        throw new Exception(node.text ~ " requires two boolean operands");
      switch(node.type) {
        case NodeType.CONTAINS_OPERATOR:
          filter = delegate bool(Record record) { return std.string.indexOf(contains_left(record), contains_right(record)) > -1; };
          break;
        case NodeType.STARTS_WITH_OPERATOR:
          filter = delegate bool(Record record) { return contains_left(record).startsWith(contains_right(record)); };
          break;
        default:
          throw new Exception("Error in the code, please report to the maintainer");
          break;
      }
      break;
    case NodeType.EQUALS_OPERATOR:
    case NodeType.NOT_EQUALS_OPERATOR:
    case NodeType.GREATER_THAN_OPERATOR:
    case NodeType.LOWER_THAN_OPERATOR:
    case NodeType.GREATER_THAN_OR_EQUALS_OPERATOR:
    case NodeType.LOWER_THAN_OR_EQUALS_OPERATOR:
      if (node.children.length != 2)
        throw new Exception(node.text ~ " requires two operands");
      auto double_left = get_double_delegate(node.children[0]);
      auto double_right = get_double_delegate(node.children[1]);
      if ((double_left !is null) && (double_right !is null)) {
        switch(node.type) {
          case NodeType.EQUALS_OPERATOR:
            filter = delegate bool(Record record) { return double_left(record) == double_right(record); };
            break;
          case NodeType.NOT_EQUALS_OPERATOR:
            filter = delegate bool(Record record) { return double_left(record) != double_right(record); };
            break;
          case NodeType.GREATER_THAN_OPERATOR:
            filter = delegate bool(Record record) { return double_left(record) > double_right(record); };
            break;
          case NodeType.LOWER_THAN_OPERATOR:
            filter = delegate bool(Record record) { return double_left(record) < double_right(record); };
            break;
          case NodeType.GREATER_THAN_OR_EQUALS_OPERATOR:
            filter = delegate bool(Record record) { return double_left(record) >= double_right(record); };
            break;
          case NodeType.LOWER_THAN_OR_EQUALS_OPERATOR:
            filter = delegate bool(Record record) { return double_left(record) <= double_right(record); };
            break;
          default:
            throw new Exception("Error in the code, please report to the maintainer");
            break;
        }
        break;
      }
      auto long_left = get_long_delegate(node.children[0]);
      auto long_right = get_long_delegate(node.children[1]);
      if ((long_left !is null) && (long_right !is null)) {
        switch(node.type) {
          case NodeType.EQUALS_OPERATOR:
            filter = delegate bool(Record record) { return long_left(record) == long_right(record); };
            break;
          case NodeType.NOT_EQUALS_OPERATOR:
            filter = delegate bool(Record record) { return long_left(record) != long_right(record); };
            break;
          case NodeType.GREATER_THAN_OPERATOR:
            filter = delegate bool(Record record) { return long_left(record) > long_right(record); };
            break;
          case NodeType.LOWER_THAN_OPERATOR:
            filter = delegate bool(Record record) { return long_left(record) < long_right(record); };
            break;
          case NodeType.GREATER_THAN_OR_EQUALS_OPERATOR:
            filter = delegate bool(Record record) { return long_left(record) >= long_right(record); };
            break;
          case NodeType.LOWER_THAN_OR_EQUALS_OPERATOR:
            filter = delegate bool(Record record) { return long_left(record) <= long_right(record); };
            break;
          default:
            throw new Exception("Error in the code, please report to the maintainer");
            break;
        }
        break;
      }
      auto bool_left = get_bool_delegate(node.children[0]);
      auto bool_right = get_bool_delegate(node.children[1]);
      if ((bool_left !is null) && (bool_right !is null)) {
        switch(node.type) {
          case NodeType.EQUALS_OPERATOR:
            filter = delegate bool(Record record) { return bool_left(record) == bool_right(record); };
            break;
          case NodeType.NOT_EQUALS_OPERATOR:
            filter = delegate bool(Record record) { return bool_left(record) != bool_right(record); };
            break;
          case NodeType.GREATER_THAN_OPERATOR:
            filter = null;
            break;
          case NodeType.LOWER_THAN_OPERATOR:
            filter = null;
            break;
          case NodeType.GREATER_THAN_OR_EQUALS_OPERATOR:
            filter = null;
            break;
          case NodeType.LOWER_THAN_OR_EQUALS_OPERATOR:
            filter = null;
            break;
          default:
            throw new Exception("Error in the code, please report to the maintainer");
            break;
        }
        break;
      }
      auto string_left = get_string_delegate(node.children[0]);
      auto string_right = get_string_delegate(node.children[1]);
      if ((string_left !is null) && (string_right !is null)) {
        switch(node.type) {
          case NodeType.EQUALS_OPERATOR:
            filter = delegate bool(Record record) { return string_left(record) == string_right(record); };
            break;
          case NodeType.NOT_EQUALS_OPERATOR:
            filter = delegate bool(Record record) { return string_left(record) != string_right(record); };
            break;
          case NodeType.GREATER_THAN_OPERATOR:
            filter = null;
            break;
          case NodeType.LOWER_THAN_OPERATOR:
            filter = null;
            break;
          case NodeType.GREATER_THAN_OR_EQUALS_OPERATOR:
            filter = null;
            break;
          case NodeType.LOWER_THAN_OR_EQUALS_OPERATOR:
            filter = null;
            break;
          default:
            throw new Exception("Error in the code, please report to the maintainer");
            break;
        }
        break;
      }
      throw new Exception("contains requires two operands");
      break;
    case NodeType.BRACKETS:
      auto brackets_right = get_bool_delegate(node.children[0]);
      if (brackets_right is null)
        filter = null;
      else
        filter = delegate bool(Record record) { return brackets_right(record); };
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
      filter = delegate string(Record record) { return node.text; };
      break;
    case NodeType.FIELD_OPERATOR:
      filter = get_field_accessor(node.parameter);
      break;
    case NodeType.ATTR_OPERATOR:
      filter = delegate string(Record record) {
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
        double  double_value = to!double(node.text);
        filter = delegate double(Record record) { return double_value; };
      } else {
        filter = null;
      }
      break;
    case NodeType.FIELD_OPERATOR:
      auto field_accessor = get_field_accessor(node.parameter);
      filter = delegate double(Record record) { return to!double(field_accessor(record)); };
      break;
    case NodeType.ATTR_OPERATOR:
      filter = delegate double(Record record) { return (node.parameter in record.attributes) ? to!double(record.attributes[node.parameter].first) : 0.0; };
      break;
    case NodeType.BRACKETS:
      filter = get_double_delegate(node.children[0]);
      break;
    case NodeType.PLUS_OPERATOR:
    case NodeType.MINUS_OPERATOR:
    case NodeType.MULTIPLICATION_OPERATOR:
    case NodeType.DIVISION_OPERATOR:
      auto left_operand = get_double_delegate(node.children[0]);
      auto right_operand = get_double_delegate(node.children[1]);
      if ((left_operand is null) || (right_operand is null)) {
        filter = null;
      } else {
        switch(node.type) {
          case NodeType.PLUS_OPERATOR:
            filter = delegate double(Record record) { return left_operand(record) + right_operand(record); };
            break;
          case NodeType.MINUS_OPERATOR:
            filter = delegate double(Record record) { return left_operand(record) - right_operand(record); };
            break;
          case NodeType.MULTIPLICATION_OPERATOR:
            filter = delegate double(Record record) { return left_operand(record) * right_operand(record); };
            break;
          case NodeType.DIVISION_OPERATOR:
            filter = delegate double(Record record) { return left_operand(record) / right_operand(record); };
            break;
          default:
            throw new Exception("Error in the code, please report to the maintainer");
            break;
        }
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
        filter = delegate long(Record record) { return integer_value; };
      } else {
        filter = null;
      }
      break;
    case NodeType.FIELD_OPERATOR:
      auto field_accessor = get_field_accessor(node.parameter);
      filter = delegate long(Record record) { return to!long(field_accessor(record)); };
      break;
    case NodeType.ATTR_OPERATOR:
      filter = delegate long(Record record) { return (node.parameter in record.attributes) ? to!long(node.parameter) : 0; };
      break;
    case NodeType.BRACKETS:
      filter = get_long_delegate(node.children[0]);
      break;
    case NodeType.PLUS_OPERATOR:
    case NodeType.MINUS_OPERATOR:
    case NodeType.MULTIPLICATION_OPERATOR:
    case NodeType.DIVISION_OPERATOR:
      auto left_operand = get_long_delegate(node.children[0]);
      auto right_operand = get_long_delegate(node.children[1]);
      if ((left_operand is null) || (right_operand is null)) {
        filter = null;
      } else {
        switch(node.type) {
          case NodeType.PLUS_OPERATOR:
            filter = delegate long(Record record) { return left_operand(record) + right_operand(record); };
            break;
          case NodeType.MINUS_OPERATOR:
            filter = delegate long(Record record) { return left_operand(record) - right_operand(record); };
            break;
          case NodeType.MULTIPLICATION_OPERATOR:
            filter = delegate long(Record record) { return left_operand(record) * right_operand(record); };
            break;
          case NodeType.DIVISION_OPERATOR:
            filter = delegate long(Record record) { return left_operand(record) / right_operand(record); };
            break;
          default:
            throw new Exception("Error in the code, please report to the maintainer");
            break;
        }
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

enum NodeType {
  NONE,
  VALUE,
  FIELD_OPERATOR,
  ATTR_OPERATOR,
  AND_OPERATOR,
  OR_OPERATOR,
  NOT_OPERATOR,
  CONTAINS_OPERATOR,
  STARTS_WITH_OPERATOR,
  EQUALS_OPERATOR,
  NOT_EQUALS_OPERATOR,
  GREATER_THAN_OPERATOR,
  LOWER_THAN_OPERATOR,
  GREATER_THAN_OR_EQUALS_OPERATOR,
  LOWER_THAN_OR_EQUALS_OPERATOR,
  BRACKETS,
  PLUS_OPERATOR,
  MINUS_OPERATOR,
  MULTIPLICATION_OPERATOR,
  DIVISION_OPERATOR
}

StringDelegate get_field_accessor(string field_name) {
  StringDelegate field_accessor;
  switch(field_name) {
    case FIELD_SEQNAME:
      field_accessor = delegate string(Record r) { return r.seqname; };
      break;
    case FIELD_SOURCE:
      field_accessor = delegate string(Record r) { return r.source; };
      break;
    case FIELD_FEATURE:
      field_accessor = delegate string(Record r) { return r.feature; };
      break;
    case FIELD_START:
      field_accessor = delegate string(Record r) { return r.start; };
      break;
    case FIELD_END:
      field_accessor = delegate string(Record r) { return r.end; };
      break;
    case FIELD_SCORE:
      field_accessor = delegate string(Record r) { return r.score; };
      break;
    case FIELD_STRAND:
      field_accessor = delegate string(Record r) { return r.strand; };
      break;
    case FIELD_PHASE:
      field_accessor = delegate string(Record r) { return r.phase; };
      break;
    default:
      throw new Exception("Invalid field name: " ~ field_name);
      break;
  }

  return field_accessor;
}

Node generate_tree(string[] tokens) {
  Node root;

  if (tokens.length == 0) {
    root = new Node(NodeType.NONE);
  } else {
    while (tokens.length != 0) {
      root = parse_next_token(root, tokens);
    }
  }

  return root;
}

unittest {
  assert(generate_tree(extract_tokens("")) !is null);
}

Node parse_next_token(Node left, ref string[] tokens) {
  Node node;

  string token = tokens[0];
  tokens = tokens[1..$];
  switch(token) {
    case "field":
      node = new Node(NodeType.FIELD_OPERATOR);
      node.text = token;
      if (left !is null) {
        throw new Exception(token ~ "operator doesn't accept a value on the left");
      } else if (tokens.length == 0) {
        throw new Exception(token ~ " operator needs a field name to the right of it");
      } else {
        node.parameter = tokens[0];
        tokens = tokens[1..$];
      }
      break;
    case "attr", "attrib", "attribute":
      node = new Node(NodeType.ATTR_OPERATOR);
      node.text = token;
      if (left !is null) {
        throw new Exception(token ~ "operator doesn't accept a value on the left");
      } else if (tokens.length == 0) {
        throw new Exception(token ~ " operator needs an attribute name to the right of it");
      } else {
        node.parameter = tokens[0];
        tokens = tokens[1..$];
      }
      break;
    case "not":
      node = new Node(NodeType.NOT_OPERATOR);
      node.text = token;
      if (left !is null) {
        throw new Exception(token ~ "operator doesn't accept a value on the left");
      } else if (tokens.length == 0) {
        throw new Exception(token ~ " operator requires a boolean value to to the right of it");
      } else {
        auto right = parse_next_token(null, tokens);
        node.children = [right];
        right.parent = node;
      }
      break;
    case "==", "!=", ">=", "<=", ">", "<", "and", "or", "+", "-", "*", "/", "contains", "starts_with":
      switch(token) {
        case "=="  : node = new Node(NodeType.EQUALS_OPERATOR); break;
        case "!="  : node = new Node(NodeType.NOT_EQUALS_OPERATOR); break;
        case "<="  : node = new Node(NodeType.LOWER_THAN_OR_EQUALS_OPERATOR); break;
        case ">="  : node = new Node(NodeType.GREATER_THAN_OR_EQUALS_OPERATOR); break;
        case ">"   : node = new Node(NodeType.GREATER_THAN_OPERATOR); break;
        case "<"   : node = new Node(NodeType.LOWER_THAN_OPERATOR); break;
        case "and" : node = new Node(NodeType.AND_OPERATOR); break;
        case "or"  : node = new Node(NodeType.OR_OPERATOR); break;
        case "+"   : node = new Node(NodeType.PLUS_OPERATOR); break;
        case "-"   : node = new Node(NodeType.MINUS_OPERATOR); break;
        case "*"   : node = new Node(NodeType.MULTIPLICATION_OPERATOR); break;
        case "/"   : node = new Node(NodeType.DIVISION_OPERATOR); break;
        case "contains"    : node = new Node(NodeType.CONTAINS_OPERATOR); break;
        case "starts_with" : node = new Node(NodeType.STARTS_WITH_OPERATOR); break;
        default:
          throw new Exception("Error in the code, please report to the maintainer");
          break;
      }
      node.text = token;
      if (left is null) {
        throw new Exception(token ~ " operator requires a value on the left");
      } else if (tokens.length == 0) {
        throw new Exception(token ~ " operator requires a value on the right");
      } else {
        auto right = parse_next_token(null, tokens);
        node.children = [left, right];
        left.parent = node;
        right.parent = node;
      }
      break;
    case "(":
      node = new Node(NodeType.BRACKETS);
      node.text = token;
      if (left !is null) {
        throw new Exception("brackets can't have a value on the left");
      } else if (tokens.length == 0) {
        throw new Exception("no closing bracket");
      } else if (tokens[0] == ")") {
        throw new Exception("brackets can't work without a value being devised inside them");
      } else {
        Node right;
        while ((tokens.length != 0) && (tokens[0] != ")")) {
          right = parse_next_token(right, tokens);
        }
        if (tokens.length == 0)
          throw new Exception("no closing bracket");
        tokens = tokens[1..$];
        node.children = [right];
        right.parent = node;
      }
      break;
    case ")":
      throw new Exception("Unexpected )");
      break;
    default:
      node = new Node(NodeType.VALUE);
      node.text = token;
      break;
  }

  return node;
}

unittest {
  string[] tokens;
  tokens = ["field", "test"];
  Node node = parse_next_token(null, tokens);
  assert(node !is null);
  assert(node.type == NodeType.FIELD_OPERATOR);
  assert(node.parameter == "test");
  assert(node.parent is null);
  assert(node.children.length == 0);

  tokens = ["attr", "test"];
  node = parse_next_token(null, tokens);
  assert(node !is null);
  assert(node.type == NodeType.ATTR_OPERATOR);
  assert(node.parameter == "test");
  assert(node.parent is null);
  assert(node.children.length == 0);
}

string[] extract_tokens(string expression) {
  Appender!(string[]) tokens;

  expression = reduce_whitespace(expression);

  while(expression.length != 0) {
    if ((expression[0] == '(') || (expression[0] == ')')) {
      tokens.put(expression[0..1]);
      expression = expression[1..$].stripLeft();
    } else if (expression[0] == '"') {
      expression = expression[1..$];
      size_t end_index = std.string.indexOf(expression[0..$], '\"');
      if (end_index == -1)
        throw new Exception("Could not find second \"");
      else {
        tokens.put(expression[0..end_index]);
        expression = expression[(end_index+1)..$].stripLeft();
      }
    } else {
      size_t next_delim_index = expression.first_of("() ");
      if (next_delim_index == -1) {
        tokens.put(expression);
        expression = null;
      } else {
        tokens.put(expression[0..next_delim_index]);
        expression = expression[next_delim_index..$].stripLeft();
      }
    }
  }

  return tokens.data;
}

unittest {
  assert(extract_tokens("").length == 0);
  assert(extract_tokens("field seqname == test") == ["field", "seqname", "==", "test"] );
  assert(extract_tokens("(field seqname) == test") == ["(", "field", "seqname", ")", "==", "test"] );
  assert(extract_tokens("  (  field \tseqname  )  == \n test") == ["(", "field", "seqname", ")", "==", "test"] );
  assert(extract_tokens("((field seqname) == test) and (attrib ID == test2)") ==
           ["(", "(", "field", "seqname", ")", "==", "test", ")", "and", "(", "attrib", "ID", "==", "test2", ")"] );
  assert(extract_tokens("field seqname == \"test\"") == ["field", "seqname", "==", "test"] );
  assert(extract_tokens("field seqname == \"test data\"") == ["field", "seqname", "==", "test data"] );
  assert(extract_tokens("((field \" seqname\") == test) and (attrib \"ID test\" == test2)") ==
           ["(", "(", "field", " seqname", ")", "==", "test", ")", "and", "(", "attrib", "ID test", "==", "test2", ")"] );
}

size_t first_of(string data, string what) {
  size_t current_index = -1;
  foreach(c; what) {
    auto index = std.string.indexOf(data, c);
    if (index != -1)
      current_index = min(index, current_index);
  }
  
  return current_index;
}

unittest {
  assert(first_of("abc", "bc") == 1);
  assert(first_of("abc", "bd") == 1);
  assert(first_of("abc", "cb") == 1);
  assert(first_of("abc", "cd") == 2);
  assert(first_of("abc", "abc") == 0);
  assert(first_of("abc", "abcd") == 0);
  assert(first_of("abc", "cdb") == 1);
}

class Node {
  this(NodeType type) {
    this.type = type;
  }

  NodeType type;
  string text;
  string parameter;
  Node parent;
  Node[] children;
}

import bio.gff3.line;

unittest {
  auto record = parse_line("test\t.\t.\t.\t.\t.\t.\t.\t.");
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
}

