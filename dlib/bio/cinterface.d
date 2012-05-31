import bio.gff3, std.conv;

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

extern (C) ulong biohpc_gff3_records_count(FileID fileID) {
  auto file = openFiles[fileID];
  return file.records_count();
}

extern (C) GFF3Record * biohpc_gff3_get_record(FileID fileID) {
  auto file = openFiles[fileID];
  return file.get_record();
}

