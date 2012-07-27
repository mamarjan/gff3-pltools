module bio.gff3.selection;

alias string[] function(Record record) ColumnSelector;

ColumnSelector create_selector_from_string(string columns_spec) {
  parse_columns_spec(columns_spec);
  return delegate string[](Record record) {
  };
}

auto SEQNAME_SELECTOR = function string(Record record) {
  return record.seqname;
};

auto SOURCE_SELECTOR = function string(Record record) {
  return record.source;
};

auto FEATURE_SELECTOR = function string(Record record) {
  return record.feature;
};

auto START_SELECTOR = function string(Record record) {
  return record.start;
};

auto END_SELECTOR = function string(Record record) {
  return record.end;
};

auto SCORE_SELECTOR = function string(Record record) {
  return record.score;
};

auto STRAND_SELECTOR = function string(Record record) {
  return record.strand;
};

auto PHASE_SELECTOR = function string(Record record) {
  return record.phase;
};

auto create_attribute_selector(string attr_name) {
  return delegate string(Record record) {
    return record.attributes[attr_name].toString();
  };
}

