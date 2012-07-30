module bio.gff3.selection;

import std.string;
import bio.gff3.record, bio.gff3.filtering;
import util.split_line;

alias string[] delegate(Record record) ColumnsSelector;
alias string delegate(Record record) ColumnExtractor;


ColumnsSelector to_selector(string column_list) {
  auto extractors = parse_columns_spec(column_list);
  return delegate string[](Record record) {
    auto result = new string[extractors.length];
    foreach(i, func; extractors) {
      result[i] = func(record);
    }
    return result;
  };
}

ColumnExtractor[] parse_columns_spec(string column_list) {
  ColumnExtractor[] result;
  while (column_list.length != 0) {
    auto next_column_name = get_and_skip_next_field(column_list, ',');
    if (next_column_name.startsWith("attr ")) {
      get_and_skip_next_field(next_column_name, ' ');
      result ~= create_attribute_extractor(next_column_name);
    } else {
      switch(next_column_name) {
        case FIELD_SEQNAME:
          result ~= delegate string(Record record) { return record.seqname; };
          break;
        case FIELD_SOURCE:
          result ~= delegate string(Record record) { return record.source; };
          break;
        case FIELD_FEATURE:
          result ~= delegate string(Record record) { return record.feature; };
          break;
        case FIELD_START:
          result ~= delegate string(Record record) { return record.start; };
          break;
        case FIELD_END:
          result ~= delegate string(Record record) { return record.end; };
          break;
        case FIELD_SCORE:
          result ~= delegate string(Record record) { return record.score; };
          break;
        case FIELD_STRAND:
          result ~= delegate string(Record record) { return record.strand; };
          break;
        case FIELD_PHASE:
          result ~= delegate string(Record record) { return record.phase; };
          break;
        default:
          throw new Exception("Invalid field name: " ~ next_column_name);
          break;
      }
    }
  }

  return result;
}

auto create_attribute_extractor(string attr_name) {
  return delegate string(Record record) {
    return attr_name in record.attributes
           ? record.attributes[attr_name].toString()
           : null;
  };
}

import std.stdio;

unittest {
  writeln("Testing ColumnSelector...");

  auto record = new Record("a\tb\tc\td\te\tf\tg\th\ti=j");
  assert(to_selector("seqname,source")(record) == ["a", "b"]);
  assert(to_selector("feature")(record) == ["c",]);
  assert(to_selector("start,end")(record) == ["d", "e"]);
  assert(to_selector("start,end,score")(record) == ["d", "e", "f"]);
  assert(to_selector("score,strand,phase,source")(record) == ["f", "g", "h","b"]);
  assert(to_selector("score,strand,attr i")(record) == ["f", "g", "j"]);
  assert(to_selector("score,strand,attr i,attr k")(record) == ["f", "g", "j", ""]);

  record = new Record("a\t.\tc\td\te\tf\tg\th\t.");
  assert(to_selector("seqname,source,attr test")(record) == ["a", "", ""]);
}

