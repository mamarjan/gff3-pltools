module util.split_file_mt;

import std.stdio, std.string, std.concurrency;
import util.range_with_cache;

/**
 * A range for retrieving text lines from a file. The object retrieves
 * some chunk_size of bytes from the file and then a line is returned
 * by front as a slice of the bigger string.
 */
class SplitFileMT : RangeWithCache!string {
  /**
   * The constructor receives the file struct as a parameter and
   * a chunk_size parameter, which is the size of the block which
   * is retrieved from the file at once.
   */
  this(string input_file, size_t chunk_size = 65536) {
    this.input_file = input_file;
    this.chunk_size = chunk_size;
    this.reader_tid = spawn(&reader, thisTid, input_file, chunk_size);
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
          //auto tmp = new char[chunk_size];
          //tmp = input_file.rawRead(tmp);
          //current_chunk = cast(immutable)tmp;
          current_chunk = receiveOnly!string();
          if (current_chunk.length < chunk_size)
            eof_reached = true;
        }
      }
    }

    return line;
  }

  private {
    string input_file;
    bool eof_reached = false;
    size_t chunk_size;
    string current_chunk;
    Tid reader_tid;
  }
}

void reader(Tid parent, string input_file, size_t chunk_size) {
  File file = File(input_file, "r");
  char[] current_chunk = new char[chunk_size];
  current_chunk = file.rawRead(current_chunk);
  send(parent, cast(immutable) current_chunk);

  setMaxMailboxSize(parent, 16, OnCrowding.block);

  while (current_chunk.length == chunk_size) {
    current_chunk = new char[chunk_size];
    current_chunk = file.rawRead(current_chunk);
    send(parent, cast(immutable) current_chunk);
  }
}

