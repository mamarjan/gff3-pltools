import std.conv, std.stdio, std.algorithm;

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
  return file.get_line();
}

extern (C) GFF3Record * biohpc_gff3_get_record(FileID fileID) {
  auto file = openFiles[fileID];
  return file.get_record();
}

class GFF3File {
  static int lastFileID;
  static int getNewID() {
    return lastFileID++;
  }

  string filename;
  File file;
  char * last_line;
  GFF3Record last_record;

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

  GFF3Record * get_record() {
    char[] buf = [];
    char delim = '\t';
    if (file.readln(buf) > 0) {
      if (buf[$-1] == '\n')
        buf = buf[0..$-1];
      auto parts = splitter(buf, delim);
      last_record = GFF3Record();
      if (parts.front[0] == '.')
        last_record.seqname = "\0".ptr;
      else
        last_record.seqname = cast(immutable(char)*)(parts.front ~ '\0').ptr;
      parts.popFront();
      if (parts.front[0] == '.')
        last_record.source = "\0".ptr;
      else
        last_record.source = cast(immutable(char)*)(parts.front ~ '\0').ptr;
      parts.popFront();
      if (parts.front[0] == '.')
        last_record.feature = "\0".ptr;
      else
        last_record.feature = cast(immutable(char)*)(parts.front ~ '\0').ptr;
      parts.popFront();
      if (parts.front[0] == '.')
        last_record.start = 0;
      else
        last_record.start = to!ulong(parts.front);
      parts.popFront();
      if (parts.front[0] == '.')
        last_record.end = 0;
      else
        last_record.end = to!ulong(parts.front);
      parts.popFront();
      if (parts.front[0] == '.')
        last_record.score = 0;
      else
        last_record.score = to!double(parts.front);
      parts.popFront();
      switch (parts.front[0]) {
        default:
          throw new Exception("invalid strand value");
        case '.':
          last_record.strand = 0;
          break;
        case '+':
          last_record.strand = 1;
          break;
        case '-':
          last_record.strand = 2;
          break;
        case '?':
          last_record.strand = 3;
          break;
      }
      parts.popFront();
      if (parts.front[0] == '.')
        last_record.phase = -1;
      else
        last_record.phase = to!int(parts.front);
      parts.popFront;
      last_record.parseAttributes(parts.front.idup);
      if ("Is_circular" in last_record.attributes) {
        if (last_record.attributes["Is_circular"] == "true")
          last_record.is_circular = true;
        else
          last_record.is_circular = false;
      } else
        last_record.is_circular = false;
      if ("ID" in last_record.attributes)
        last_record.id = (last_record.attributes["ID"] ~ '\0').ptr;
      else
        last_record.id = "\0";
      return &last_record;
    } else {
      return null;
    }
  }

  void close() {
    file.close();
  }
}

struct GFF3Record {
  void parseAttributes(string attributes_field) {
    immutable(char)*[] local_cattributes;
    if (attributes_field[0] != '.') {
      auto raw_attributes = splitter(attributes_field, ';');
      foreach(attribute; raw_attributes) {
        auto attribute_parts = splitter(attribute, '=');
        auto attribute_name = attribute_parts.front;
        attribute_parts.popFront();
        auto attribute_value = attribute_parts.front;
        attributes[attribute_name] = attribute_value;
        local_cattributes ~= (attribute_name ~ '\0').ptr;
        local_cattributes ~= (attribute_value ~ '\0').ptr;
      }
    }
    local_cattributes ~= null;
    cattributes = local_cattributes.ptr;
  }
  immutable(char) * seqname;
  immutable(char) * source;
  immutable(char) * feature;
  ulong  start;
  ulong  end;
  double score;
  int    strand;
  int    phase;
  int    is_circular;
  immutable(char) * id;
  immutable(char)** cattributes;
  string[string] attributes;
}

