import std.stdio, std.file, std.conv, std.string;

File input_file;

void main(string[] args) {
  input_file = File(args[1], "r");
  while(true) {
    next_item();
    try_and_catch();
  }
}

void try_and_catch() {
  try {
    throw new Exception("A record with invalid number of columns");
  } catch (Exception e) {
  }
}

char[] current_chunk;

void next_item() {
  char[] line;
  bool line_complete = false;
  while (!line_complete) {
    if (current_chunk.length == 0) {
      current_chunk = new char[8177];
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

