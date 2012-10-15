module bio.gff3.filtering.delegates.string;

import bio.gff3.filtering.common, bio.gff3.filtering.node_tree.node,
       bio.gff3.filtering.field_accessor;

package:

StringDelegate get_string_delegate(Node node) {
  StringDelegate filter;

  final switch(node.type) {
    case NodeType.VALUE:
      filter = (record) { return node.text; };
      break;
    case NodeType.FIELD_OPERATOR:
      filter = get_field_accessor(node.parameter);
      break;
    case NodeType.ATTR_OPERATOR:
      filter = (record) {
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

