module bio.gff3.filtering.generate_tree;

import bio.gff3.filtering.node;

/*******************************************************************************
 * The following part if about generating a tree structure from a list
 * of tokens.
 ******************************************************************************/

package:

Node generate_tree(string[] tokens) {
  Node root;

  if (tokens.length == 0)
    root = new Node(NodeType.NONE);
  else
    while (tokens.length != 0)
      root = parse_next_token(root, tokens);

  return root;
}

unittest {
  assert(generate_tree([]) !is null);
  assert(generate_tree(null) !is null);
  assert(generate_tree(null).type == NodeType.NONE);

  auto tree_root = generate_tree(["field", "feature"]);
  assert(tree_root.type == NodeType.FIELD_OPERATOR);
  assert(tree_root.children.length == 0);

  tree_root = generate_tree(["field", "feature", "==", "CDS"]);
  assert(tree_root.type == NodeType.EQUALS_OPERATOR);
  assert(tree_root.parent is null);
  assert(tree_root.children.length == 2);
  assert(tree_root.children[0].type == NodeType.FIELD_OPERATOR);
  assert(tree_root.children[0].children.length == 0);
  assert(tree_root.children[1].type == NodeType.VALUE);
  assert(tree_root.children[1].children.length == 0);
}

Node parse_next_token(Node left, ref string[] tokens) {
  Node node;

  string token = tokens[0];
  tokens = tokens[1..$];
  switch(token) {
    case "field":
      node = parse_field_token(left, tokens);
      break;
    case "attr", "attrib", "attribute":
      node = parse_attr_token(left, tokens);
      break;
    case "not":
      node = parse_not_token(left, tokens);
      break;
    case "==", "!=", ">=", "<=", ">", "<", "and", "or", "+", "-", "*", "/", "contains", "starts_with":
      node = parse_binary_token(left, token, tokens);
      break;
    case "(":
      node = parse_brackets_token(left, tokens);
      break;
    case ")":
      throw new Exception("Unexpected )");
      break;
    default:
      if (left !is null)
        throw new Exception("Unknown operator: " ~ token);
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

Node parse_field_token(Node left, ref string[] tokens) {
  // Check if everything ok
  if (left !is null)
    throw new Exception("field operator doesn't accept a value on the left");
  if (tokens.length == 0)
    throw new Exception("field operator needs a field name to the right of it");

  // Setup a new node
  auto node = new Node(NodeType.FIELD_OPERATOR);
  node.text = "field";
  node.parameter = tokens[0];
  tokens = tokens[1..$];

  return node;
}

version(unittest) {
  import std.exception;
}

unittest {
  auto tokens = ["feature"];
  auto node = parse_field_token(null, tokens);
  assert(node.type == NodeType.FIELD_OPERATOR);
  assert(node.parameter == "feature");
  assert(tokens.length == 0);

  tokens = ["feature", "==", "field"];
  node = parse_field_token(null, tokens);
  assert(node.type == NodeType.FIELD_OPERATOR);
  assert(node.parameter == "feature");
  assert(tokens.length == 2);
  assert(tokens[0] == "==");
  assert(tokens[1] == "field");

  tokens = ["feature"];
  assertThrown(parse_field_token(new Node(NodeType.VALUE), tokens));

  tokens = null;
  assertThrown(parse_field_token(null, tokens));
}

Node parse_attr_token(Node left, ref string[] tokens) {
  if (left !is null)
    throw new Exception("attr operator doesn't accept a value on the left");
  if (tokens.length == 0)
    throw new Exception("attr operator needs an attribute name to the right of it");

  auto node = new Node(NodeType.ATTR_OPERATOR);
  node.text = "attr";
  node.parameter = tokens[0];
  tokens = tokens[1..$];

  return node;
}

unittest {
  auto tokens = ["ID"];
  auto node = parse_attr_token(null, tokens);
  assert(node.type == NodeType.ATTR_OPERATOR);
  assert(node.parameter == "ID");
  assert(tokens.length == 0);

  tokens = ["ID", "==", "field"];
  node = parse_attr_token(null, tokens);
  assert(node.type == NodeType.ATTR_OPERATOR);
  assert(node.parameter == "ID");
  assert(tokens.length == 2);
  assert(tokens[0] == "==");
  assert(tokens[1] == "field");

  tokens = ["ID"];
  assertThrown(parse_attr_token(new Node(NodeType.VALUE), tokens));

  tokens = null;
  assertThrown(parse_attr_token(null, tokens));
}

Node parse_not_token(Node left, ref string[] tokens) {
  if (left !is null)
    throw new Exception("not operator doesn't accept a value on the left");
  if (tokens.length == 0)
    throw new Exception("not operator requires a boolean value to to the right of it");

  auto node = new Node(NodeType.NOT_OPERATOR);
  node.text = "not";

  auto right = parse_next_token(null, tokens);
  node.children = [right];
  right.parent = node;

  return node;
}

unittest {
  auto tokens = ["field", "feature"];
  auto node = parse_not_token(null, tokens);
  assert(node.type == NodeType.NOT_OPERATOR);
  assert(tokens.length == 0);
  assert(node.children.length == 1);
  assert(node.children[0].type == NodeType.FIELD_OPERATOR);

  tokens = ["field", "feature", "==", "CDS"];
  node = parse_not_token(null, tokens);
  assert(node.type == NodeType.NOT_OPERATOR);
  assert(node.children.length == 1);
  assert(node.children[0].type == NodeType.FIELD_OPERATOR);
  assert(tokens.length == 2);
  assert(tokens[0] == "==");
  assert(tokens[1] == "CDS");

  tokens = ["field", "feature"];
  assertThrown(parse_not_token(new Node(NodeType.VALUE), tokens));

  tokens = null;
  assertThrown(parse_not_token(null, tokens));
}

Node parse_binary_token(Node left, string token, ref string[] tokens) {
  if (left is null)
    throw new Exception(token ~ " operator requires a value on the left");
  if (tokens.length == 0)
    throw new Exception(token ~ " operator requires a value on the right");

  NodeType node_type = map_binary_operator(token);
  if (node_type == NodeType.NONE)
    throw new Exception("Error in the code, please report to the maintainer");

  auto node = new Node(node_type);
  node.text = token;

  auto right = parse_next_token(null, tokens);
  node.children = [left, right];
  left.parent = node;
  right.parent = node;

  return node;
}

unittest {
  auto left = new Node(NodeType.FIELD_OPERATOR);
  auto tokens = ["attr", "feature"];
  auto node = parse_binary_token(left, "==", tokens);
  assert(node.type == NodeType.EQUALS_OPERATOR);
  assert(tokens.length == 0);
  assert(node.children.length == 2);
  assert(node.children[0].type == NodeType.FIELD_OPERATOR);
  assert(node.children[1].type == NodeType.ATTR_OPERATOR);

  tokens = ["attr", "feature", "==", "true"];
  node = parse_binary_token(left, "==", tokens);
  assert(node.type == NodeType.EQUALS_OPERATOR);
  assert(node.children.length == 2);
  assert(node.children[0].type == NodeType.FIELD_OPERATOR);
  assert(node.children[1].type == NodeType.ATTR_OPERATOR);
  assert(tokens.length == 2);
  assert(tokens[0] == "==");
  assert(tokens[1] == "true");

  tokens = ["field", "feature"];
  assertThrown(parse_binary_token(null, "==", tokens));

  tokens = null;
  assertThrown(parse_binary_token(new Node(NodeType.FIELD_OPERATOR), "==", tokens));
}

NodeType map_binary_operator(string op) {
  NodeType node_type;
  switch(op) {
    case "=="  : node_type = NodeType.EQUALS_OPERATOR; break;
    case "!="  : node_type = NodeType.NOT_EQUALS_OPERATOR; break;
    case "<="  : node_type = NodeType.LOWER_THAN_OR_EQUALS_OPERATOR; break;
    case ">="  : node_type = NodeType.GREATER_THAN_OR_EQUALS_OPERATOR; break;
    case ">"   : node_type = NodeType.GREATER_THAN_OPERATOR; break;
    case "<"   : node_type = NodeType.LOWER_THAN_OPERATOR; break;
    case "and" : node_type = NodeType.AND_OPERATOR; break;
    case "or"  : node_type = NodeType.OR_OPERATOR; break;
    case "+"   : node_type = NodeType.PLUS_OPERATOR; break;
    case "-"   : node_type = NodeType.MINUS_OPERATOR; break;
    case "*"   : node_type = NodeType.MULTIPLICATION_OPERATOR; break;
    case "/"   : node_type = NodeType.DIVISION_OPERATOR; break;
    case "contains" : node_type = NodeType.CONTAINS_OPERATOR; break;
    case "starts_with" : node_type = NodeType.STARTS_WITH_OPERATOR; break;
    default: node_type = NodeType.NONE; break;
  }
  return node_type;
}

unittest {
  assert(map_binary_operator("==") == NodeType.EQUALS_OPERATOR);
  assert(map_binary_operator("/") == NodeType.DIVISION_OPERATOR);
  assert(map_binary_operator("contains") == NodeType.CONTAINS_OPERATOR);
  assert(map_binary_operator("") == NodeType.NONE);
  assert(map_binary_operator("&&") == NodeType.NONE);
}

Node parse_brackets_token(Node left, ref string[] tokens) {
  if (left !is null)
    throw new Exception("brackets can't have a value on the left");
  if (tokens.length == 0)
    throw new Exception("no closing bracket");
  if (tokens[0] == ")")
    throw new Exception("brackets can't work without a value being devised inside them");

  auto node = new Node(NodeType.BRACKETS);
  node.text = "(";

  Node right;
  while ((tokens.length != 0) && (tokens[0] != ")")) {
    right = parse_next_token(right, tokens);
  }

  if (tokens.length == 0)
    throw new Exception("no closing bracket");
  else
    tokens = tokens[1..$];

  node.children = [right];
  right.parent = node;

  return node;
}

unittest {
  auto tokens = ["field", "feature", ")"];
  auto node = parse_brackets_token(null, tokens);
  assert(node.type == NodeType.BRACKETS);
  assert(tokens.length == 0);
  assert(node.children.length == 1);
  assert(node.children[0].type == NodeType.FIELD_OPERATOR);

  tokens = ["field", "feature", "==", "CDS", ")"];
  node = parse_brackets_token(null, tokens);
  assert(node.type == NodeType.BRACKETS);
  assert(node.children.length == 1);
  assert(node.children[0].type == NodeType.EQUALS_OPERATOR);
  assert(tokens.length == 0);

  tokens = ["field", "feature", "==", "CDS", ")", "and", "true"];
  node = parse_brackets_token(null, tokens);
  assert(node.type == NodeType.BRACKETS);
  assert(node.children.length == 1);
  assert(node.children[0].type == NodeType.EQUALS_OPERATOR);
  assert(tokens.length == 2);
  assert(tokens[0] == "and");
  assert(tokens[1] == "true");

  // Test with missing closing bracket
  tokens = ["field", "feature"];
  assertThrown(parse_brackets_token(null, tokens));

  // Test with left value not null
  tokens = ["field", "feature", ")"];
  assertThrown(parse_brackets_token(new Node(NodeType.VALUE), tokens));

  // Test with no value inside brackets
  tokens = [")"];
  assertThrown(parse_brackets_token(null, tokens));

  // Test with no tokens left
  tokens = null;
  assertThrown(parse_brackets_token(null, tokens));
}


