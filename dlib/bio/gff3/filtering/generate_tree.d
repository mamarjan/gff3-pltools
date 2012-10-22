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



