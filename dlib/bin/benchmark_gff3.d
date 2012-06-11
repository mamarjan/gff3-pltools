import std.stdio, std.file, std.conv, std.string;

void main(string[] args) {
  auto data = new SplitFile(File(args[1], "r"));
  while(true) {
    data.next_item();
    try_and_catch();
  }
}

void try_and_catch() {
  try {
    throw new Exception("A record with invalid number of columns");
  } catch (Exception e) {
  }
}

class SplitFile {
  /**
   * The constructor receives the file struct as a parameter and
   * a chunk_size parameter, which is the size of the block which
   * is retrieved from the file at once.
   */
  this(File input_file) {
    this.input_file = input_file;
  }

  void next_item() {
    char[] line;
    bool line_complete = false;
    while (!line_complete) {
      if (current_chunk.length == 0) {
        current_chunk = new char[65536];
        current_chunk = input_file.rawRead(current_chunk);
      } else {
        auto newline_index = current_chunk.indexOf('\n');
        if (newline_index != -1) {
          line ~= current_chunk[0..newline_index];
          current_chunk = current_chunk[newline_index+1..$];
          line_complete = true;
        } else {
          line = current_chunk;
          current_chunk = null;
        }
      }
    }
  }

  private {
    File input_file;
    char[] current_chunk;
  }
}

