import std.conv, std.stdio;

GFF3File[int] openFiles;

alias int FileID;

extern (C) FileID biohpc_gff3_open(char * c_filename) {
  auto file = new GFF3File(to!string(c_filename));
  auto fileID = GFF3File.getNewID();
  openFiles[fileID] = file;
  return fileID;
}

extern (C) void biohpc_gff3_close(FileID fileID) {
  auto file = openFiles[fileID];
  if (file !is null)
    file.close();
}

extern (C) void biohpc_gff3_rewind(FileID fileID) {
  auto file = openFiles[fileID];
  file.rewind();
}

extern (C) ulong biohpc_gff3_lines_count(FileID fileID) {
  auto file = openFiles[fileID];
  return file.lines_count();
}

extern (C) char * biohpc_gff3_get_line(FileID fileID) {
  auto file = openFiles[fileID];
  auto line = file.get_line();
  return line;
}

class GFF3File {
  static int lastFileID;
  static int getNewID() {
    return lastFileID++;
  }

  string filename;
  File file;
  char * last_line;
  this(string fn) {
    filename = fn;
    file.open(filename, "r");
  }

  void rewind() {
    file.rewind();
  }

  ulong lines_count() {
    rewind();
    ulong count = 0;
    foreach(ubyte[] line; lines(file)) {
      count++;
    }
    return count;
  }

  char * get_line() {
    char[] buf = [];
    if (file.readln(buf) > 0) {
      if (buf[$-1] == '\n') {
        buf[$-1] = '\0';
      } else {
        buf ~='\0';
      }
      last_line = cast(char*) buf;
      return last_line;
    } else {
      return null;
    }
  }

  void close() {
    file.close();
  }
}

