module util.split_file;

import std.stdio, std.string;
import util.range_with_cache;

class SplitFile : RangeWithCache!string {
  this(File input_file, size_t chunk_size = 65536) {
    this.input_file = input_file;
    this.chunk_size = chunk_size;
  }

  protected string next_item() {
    string line;
    if (current_chunk.length == 0)
      if (eof_reached)
        return null;
    auto newline_index = current_chunk.indexOf('\n');
    if (newline_index != -1) {
      line = current_chunk[0..newline_index];
      current_chunk = current_chunk[newline_index+1..$];
    } else {
      line = current_chunk;
      auto tmp = new char[chunk_size];
      tmp = input_file.rawRead(tmp);
      current_chunk = cast(immutable)tmp;
      if (current_chunk.length < chunk_size)
        eof_reached = true;
      if (current_chunk.length != 0) {
        newline_index = current_chunk.indexOf('\n');
        if (newline_index != -1) {
          line ~= current_chunk[0..newline_index];
          current_chunk = current_chunk[newline_index+1..$];
        } else {
          line ~= current_chunk;
          current_chunk = null;
        }
      }
    }
    return line;
  }

  private {
    File input_file;
    bool eof_reached = false;
    size_t chunk_size;
    string current_chunk;
  }
}

