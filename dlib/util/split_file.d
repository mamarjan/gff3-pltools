module util.split_file;

import std.stdio, std.string;
import util.lines_range;

/**
 * A range for retrieving text lines from a file. The object retrieves
 * some chunk_size of bytes from the file and then a line is returned
 * by front as a slice of the bigger string.
 */
class SplitFile : LinesRange {
  /**
   * The constructor receives the file struct as a parameter and
   * a chunk_size parameter, which is the size of the block which
   * is retrieved from the file at once.
   */
  this(File input_file, size_t chunk_size = 8176) {
    this.input_file = input_file;
    this.chunk_size = chunk_size;
  }

  protected string next_item() {
    if (current_chunk.length == 0)
      if (eof_reached)
        return null;
    string line;
    bool line_complete = false;
    while (!line_complete) {
      if (current_chunk.length != 0) {
        auto newline_index = current_chunk.indexOf('\n');
        if (newline_index != -1) {
          if (line is null)
            line = current_chunk[0..newline_index];
          else
            line ~= current_chunk[0..newline_index];
          current_chunk = current_chunk[newline_index+1..$];
          line_complete = true;
        } else {
          if (line is null)
            line = current_chunk;
          else
            line ~= current_chunk;
          current_chunk = null;
        }
      } else {
        if (eof_reached) {
          line_complete = true;
        } else {
          auto tmp = new char[chunk_size];
          tmp = input_file.rawRead(tmp);
          current_chunk = cast(immutable)tmp;
          if (current_chunk.length < chunk_size)
            eof_reached = true;
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

