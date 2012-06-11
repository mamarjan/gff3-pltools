import std.stdio, std.file, std.conv, std.string;

void main(string[] args) {
  foreach(rec; new RecordRange!(SplitFile)(new SplitFile(File(args[1], "r")))) {}
}

class RecordRange(SourceRangeType) {
  this(SourceRangeType data) {
    this.data = data;
  }

  @property string front() {
    if (cache is null)
      cache = next_item();
    return cache;
  }

  void popFront() {
    cache = null;
  }

  @property bool empty() {
    if (cache is null)
      cache = next_item();
    return cache is null;
  }

  private string cache;

  protected string next_item() {
    data.next_item();
    try {
      throw new Exception("A record with invalid number of columns");
    } catch (Exception e) {
    }
    return "";
  }

  private {
    SourceRangeType data;
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

  string next_item() {
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
        auto tmp = new char[65536];
        tmp = input_file.rawRead(tmp);
        current_chunk = cast(immutable)tmp;
      }
    }

    return line;
  }

  private {
    File input_file;
    string current_chunk;
  }
}

