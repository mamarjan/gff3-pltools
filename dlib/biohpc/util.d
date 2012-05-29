import std.range, std.string;
/**
 * General utilities useful for more then one project
 */


/**
 * A lazy string splitter. The constructor takes a string,
 * detects what the line terminator is and then returs lines
 * one by one. There is no copying involved, only slicing.
 */
class LazySplitLines : InputRange!(string) {
  this(string data) {
    this.data = data;
    this.data_left = data;
    this.delim = detectNewLineDelim(data);
  }
  string front() {
    string result = null;
    auto nl_index = indexOf(data_left, delim);
    if (nl_index == -1) {
      result = data_left;
    } else {
      result = data_left[0..nl_index];
    }
    return result;
  }
  string moveFront() { return ""; }
  void popFront() { }
  bool empty() { return data_left.length == 0; }
  int opApply(int delegate(string)) { return 0; }
  int opApply(int delegate(size_t, string)) { return 0; }
  
  private {
    string delim;
    string data;
    string data_left;
  }
}

/**
 * Detects the character or a character sequence which is used in the string
 * for line termination.
 */
string detectNewLineDelim(string data) {
  // TODO: Implement a better line termination detection strategy
  return "\n";
}

void main() {}

