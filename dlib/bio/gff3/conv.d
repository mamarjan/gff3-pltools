module bio.gff3.conv;

alias string function(Record record) RecordToStringFunc;

RecordToStringFunc create_to_table(ColumnSelector select) {
  return delegate string(Record record) {
    return select(record).join('\t');
  };
}

RecordToStringFunc create_to_csv(ColumnSelector select) {
  return delegate string(Record record) {
    return select(record).join(',');
  };
}

