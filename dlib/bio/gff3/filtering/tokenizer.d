module bio.gff3.filtering.tokenizer;

import std.array, std.string;
import util.reduce_whitespace, util.first_of;

/**
 * Generates a list of tokens from a filtering expression.
 */
string[] extract_tokens(string expression) {
  Appender!(string[]) tokens;

  // First remove double whitespace
  expression = reduce_whitespace(expression);

  while(expression.length != 0) {
    size_t next_token_length = 0;
    if ((expression[0] == '(') || (expression[0] == ')')) {
      tokens.put(expression[0..1]);
      expression = expression[1..$].stripLeft();
    } else if (expression[0] == '"') {
      expression = expression[1..$];
      auto end_index = std.string.indexOf(expression[0..$], '\"');
      if (end_index == -1)
        throw new Exception("Could not find second \"");
      else {
        tokens.put(expression[0..end_index]);
        expression = expression[(end_index+1)..$].stripLeft();
      }
    } else {
      auto next_delim_index = expression.first_of("() ");
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

version (unittest) {
  import std.stdio;
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
