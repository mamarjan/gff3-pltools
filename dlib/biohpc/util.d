import std.stdio, std.conv, std.range, std.string;

/**
 * General utilities useful for more then one project
 */


/**
 * A lazy string splitter. The constructor takes a string,
 * detects what the line terminator is and then returs lines
 * one by one. There is no copying involved, only slicing.
 */
class LazySplitLines {
  this(string data) {
    this.data = data;
    this.data_left = data;
    this.newline = detectNewLineDelim(data);
  }

  /**
   * Returns the next line in range.
   */
  string front() {
    string result = null;
    auto nl_index = indexOf(data_left, newline);
    if (nl_index == -1) {
      // last line
      result = data_left;
    } else {
      result = data_left[0..nl_index];
    }
    return result;
  }

  /**
   * Pops the next line of the range.
   */
  void popFront() {
    auto nl_index = indexOf(data_left, newline);
    if (nl_index == -1) {
      // last line
      data_left = null;
    } else {
      data_left = data_left[(nl_index+newline.length)..$];
    }
  }

  /**
   * Return true if no more lines left in the range.
   */
  bool empty() {
    return data_left is null;
  }
  
  private {
    string newline;
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


unittest {
  writeln("Testing LazySplitLines...");
  auto lines = new LazySplitLines("Test\n1\n2\n3");
  assert(lines.empty == false);
  assert(lines.front == "Test"); lines.popFront();
  assert(lines.empty == false);
  assert(lines.front == "1"); lines.popFront();
  assert(lines.empty == false);
  assert(lines.front == "2"); lines.popFront();
  assert(lines.empty == false);
  assert(lines.front == "3"); lines.popFront();
  assert(lines.empty == true);
  
  // Test for correct behavior when newline at the end of the file
  lines = new LazySplitLines("Test newline at the end\n");
  assert(lines.empty == false);
  assert(lines.front == "Test newline at the end"); lines.popFront();
  assert(lines.empty == false);
  assert(lines.front == ""); lines.popFront();
  assert(lines.empty == true);

  // Test if it's working with foreach
  lines = new LazySplitLines("1\n2\n3\n4");
  int i = 1;
  foreach(value; lines) {
    assert(value == to!string(i));
    i++;
  }
}

void main() {}

