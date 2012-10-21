module bio.gff3.filtering.node;

package:

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


