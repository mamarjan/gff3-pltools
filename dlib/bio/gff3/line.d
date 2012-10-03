module bio.gff3.line;

import std.string;
import bio.gff3.record, bio.gff3.attribute;
import util.split_line, util.esc_char_conv;

public import bio.gff3.data_formats;

/**
 * Parses a single line of text from GFF3 or GTF file or data.
 */
Record parse_line(string line, bool replace_esc_chars = true, DataFormat format = DataFormat.GFF3) {
  Record record;

  if (line_is_pragma(line))
    record = parse_pragma_line(line);
  else if (line_is_comment(line))
    record = parse_comment_line(line);
  else
    record = parse_regular_line(line, replace_esc_chars, format);

  return record;
}

/**
 * Pragmas in GFF3 are lines which start with two # characters. Returns
 * a pragma record object which has it's pragma_text attribute set to the
 * whole line contents, including ##.
 */
Record parse_pragma_line(string line) {
  auto record = new Record;
  with(record) {
    record_type = RecordType.PRAGMA;
    pragma_text = line;
  }
  return record;
}

/**
 * Comments in GFF3 are lines which start with one # character. Returns
 * a comment record object which has it's comment_text attribute set to the
 * whole line contents, including #.
 */
Record parse_comment_line(string line) {
  auto record = new Record;
  with(record) {
    record_type = RecordType.COMMENT;
    comment_text = line;
  }
  return record;
}

Record parse_regular_line(string line, bool replace_esc_chars, DataFormat format = DataFormat.GFF3) {
  string original_line = line;
  auto record = new Record;
  record.record_type = RecordType.REGULAR;

  // Split into fields
  string fields[9];
  foreach(ref field; fields) {
    field = get_and_skip_next_field(line, '\t');
    if ((field.length == 1) && (field[0] == '.'))
      field = null;
  }

  // Replace escaped chars if necessary for all fields except attributes field
  if (replace_esc_chars && (std.string.indexOf(original_line, '%') != -1)) {
    record.esc_chars = true;
    foreach(ref field; fields[0..8])
      if (std.string.indexOf(field, '%') != -1)
        field = cast(string) replace_url_escaped_chars(field.dup);
  }

  with (record) {
    seqname = fields[0];
    source  = fields[1];
    feature = fields[2];
    start   = fields[3];
    end     = fields[4];
    score   = fields[5];
    strand  = fields[6];
    phase   = fields[7];

    attributes = parse_attributes(fields[8], replace_esc_chars, format);
  }

  if (format == DataFormat.GTF) {
    auto comment_start = std.string.indexOf(fields[8], '#');
    if (comment_start != -1)
      record.comment_text = fields[8][comment_start..$];
  }

  return record;
}

auto parse_attributes(string attr_field, bool replace_esc_chars = true, DataFormat format = DataFormat.GFF3) {
  // check for a comment at the end of line, which is allowed in GTF
  auto comment_start = std.string.indexOf(attr_field, '#');
  if (comment_start != -1)
    attr_field = strip(attr_field[0..comment_start]);

  // parse attributes
  AttributeValue[string] attributes;

  while(attr_field.length != 0) {
    auto attribute = get_and_skip_next_field(attr_field, ';');
    if (format == DataFormat.GTF)
      attribute = strip(attribute);
    if (attribute.length == 0) {
      continue;
    } else {
      auto attribute_name = get_and_skip_next_field(attribute,
                                                    (format == DataFormat.GFF3) ? '=' : ' ');
      if (replace_esc_chars && (std.string.indexOf(attribute_name, '%') != -1))
        attribute_name = cast(string) replace_url_escaped_chars(attribute_name.dup);
      if ((format == DataFormat.GTF) && (attribute.length > 0) && (attribute[0] == '"'))
        attribute = attribute[1..$];
      if ((format == DataFormat.GTF) && (attribute.length > 0) && (attribute[$-1] == '"'))
        attribute = attribute[0..$-1];
      attributes[attribute_name] = parse_attr_value(attribute, replace_esc_chars);
    }
  }

  return attributes;
}

auto parse_attr_value(string attr_value, bool replace_esc_chars = true) {
  bool esc_chars = replace_esc_chars && (std.string.indexOf(attr_value, '%') != -1);
  auto value_count = attr_value.count(',') + 1;
  auto values = new string[value_count];
  foreach(i; 0..value_count)
    values[i] = get_and_skip_next_field(attr_value, ',');
  if (replace_esc_chars)
    foreach(ref value; values)
      if (std.string.indexOf(value, '%') != -1)
        value = cast(string) replace_url_escaped_chars(value.dup);
  return AttributeValue(values, esc_chars);
}



package {
  /**
   * By definition a line is a pragma if the first two characters
   * are ##.
   */
  bool line_is_pragma(T)(T[] line) {
    return (line.length >= 2) && (line[0..2] == "##");
  }

  /**
   * By definition a line is a comment if the first character is #
   * and the second character is not a #.
   */
  bool line_is_comment(T)(T[] line) {
    return (line.length >= 1) && (line[0] == '#') &&
           ((line.length == 1) || (line[1] != '#'));
  }
}

import std.array;
import bio.gff3.conv.gtf;

unittest {
  assert(line_is_comment("# test") == true);
  assert(line_is_comment("## test") == false);
  assert(line_is_comment("### test") == false);
  assert(line_is_comment("test") == false);
  assert(line_is_comment(" # test") == false);
  assert(line_is_comment("# test\n") == true);

  assert(line_is_pragma("# test") == false);
  assert(line_is_pragma("## test") == true);
  assert(line_is_pragma(" ## test") == false);
  assert(line_is_pragma("## test\n") == true);
  assert(line_is_pragma("test") == false);
  assert(line_is_pragma("### test") == true);
}

unittest {
  auto value = parse_attr_value("abc");
  assert(value.is_multi == false);
  assert(value.first == "abc");
  assert(value.all == ["abc"]);

  value = parse_attr_value("abc%3Df", true);
  assert(value.is_multi == false);
  assert(value.first == "abc=f");
  assert(value.all == ["abc=f"]);

  value = parse_attr_value("abc%3Df", false);
  assert(value.is_multi == false);
  assert(value.first == "abc%3Df");
  assert(value.all == ["abc%3Df"]);

  value = parse_attr_value("ab,cd,e");
  assert(value.is_multi == true);
  assert(value.first == "ab");
  assert(value.all == ["ab", "cd", "e"]);

  value = parse_attr_value("a%3Db,c%3Bd,e%2Cf,g%26h,ij", true);
  assert(value.is_multi == true);
  assert(value.first == "a=b");
  assert(value.all == ["a=b", "c;d", "e,f", "g&h", "ij"]);

  value = parse_attr_value("a%3Db,c%3Bd,e%2Cf,g%26h,ij", false);
  assert(value.is_multi == true);
  assert(value.first == "a%3Db");
  assert(value.all == ["a%3Db", "c%3Bd", "e%2Cf", "g%26h", "ij"]);
}

unittest {
  // Minimal test
  auto record = parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1");
  assert(record.attributes.length == 1);
  assert(record.attributes["ID"].all == ["1"]);
  // Test splitting multiple attributes
  record = parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=45");
  assert(record.attributes.length == 2);
  assert(record.attributes["ID"].all == ["1"]);
  assert(record.attributes["Parent"].all == ["45" ]);
  // Test if first splitting and then replacing escaped chars
  record = parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID%3D=1");
  assert(record.attributes.length == 1);
  assert(record.attributes["ID="].all == ["1"]);
  // Test if parser survives trailing semicolon
  record = parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=45;");
  assert(record.attributes.length == 2);
  assert(record.attributes["ID"].all == ["1"]);
  assert(record.attributes["Parent"].all == ["45"]);
  // Test for an attribute with the value of a single space
  record = parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID= ;");
  assert(record.attributes.length == 1);
  assert(record.attributes["ID"].all == [" " ]);
  // Test for an attribute with no value
  record = parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=;");
  assert(record.attributes.length == 1);
  assert(record.attributes["ID"].all == [""]);
  // Test for comments on the end of a feature in GTF data
  record = parse_line(".\t.\t.\t.\t.\t.\t.\t.\tgene_id \"abc\"; transcript_id \"def\";# test comment", true, DataFormat.GTF);
  assert(record.to_gtf() == ".\t.\t.\t.\t.\t.\t.\t.\tgene_id \"abc\"; transcript_id \"def\";# test comment");
  assert(record.attributes.length == 2);
  assert(record.attributes["gene_id"].first == "abc");
  assert(record.attributes["transcript_id"].first == "def");

  record = parse_line(".\t.\t.\t.\t.\t.\t.\t.\tgene_id \"abc\"; transcript_id \"def\";", false, DataFormat.GTF);
  assert(record.attributes.length == 2);
  assert(record.gene_id == "abc");
  assert(record.transcript_id == "def");
}

unittest {
  // Test parsing pragmas
  assert(parse_line(".\t.\t.\t.\t.\t.\t.\t.\t.").is_pragma == false);
  assert(parse_line("# test").is_pragma == false);
  assert(parse_line("## test").is_pragma == true);
  assert(parse_line("## test").is_comment == false);
  assert(parse_line("## test").is_regular == false);
  assert(parse_line("## test").pragma_text == "## test");
  assert(parse_line("## test").toString == "## test");

  // Test parsing comments
  assert(parse_line(".\t.\t.\t.\t.\t.\t.\t.\t.").is_comment == false);
  assert(parse_line("# test").is_comment == true);
  assert(parse_line("# test").is_pragma == false);
  assert(parse_line("# test").is_regular == false);
  assert(parse_line("## test").is_comment == false);
  assert(parse_line("# test").comment_text == "# test");
  assert(parse_line("# test").toString == "# test");

  /////// Test line parsing with a normal line \\\\\\\

  // Test parsing lines with dots - undefined values
  auto record = parse_line(".\t.\t.\t.\t.\t.\t.\t.\t.");
  with (record) {
    assert(is_regular == true);
    assert(is_pragma == false);
    assert(is_comment == false);
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["", "", "", "", "", "", "", ""]);
    assert(attributes.length == 0);
  }

  // Test with an example line form real data
  record = parse_line("ENSRNOG00000019422\tEnsembl\tgene\t27333567\t27357352\t1.0\t+\t2\tID=ENSRNOG00000019422;Dbxref=taxon:10116;organism=Rattus norvegicus;chromosome=18;name=EGR1_RAT;source=UniProtKB/Swiss-Prot;Is_circular=true");
  with (record) {
    assert(is_regular == true);
    assert(is_pragma == false);
    assert(is_comment == false);
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["ENSRNOG00000019422", "Ensembl", "gene", "27333567", "27357352", "1.0", "+", "2"]);
    assert(attributes.length == 7);
    assert(attributes["ID"].all == ["ENSRNOG00000019422"]);
    assert(attributes["Dbxref"].all == ["taxon:10116"]);
    assert(attributes["organism"].all == ["Rattus norvegicus"]);
    assert(attributes["chromosome"].all == ["18"]);
    assert(attributes["name"].all == ["EGR1_RAT"]);
    assert(attributes["source"].all == ["UniProtKB/Swiss-Prot"]);
    assert(attributes["Is_circular"].all == ["true"]);
  }

  // Test parsing lines with escaped characters
  record = parse_line("EXON%3D00000131935\tASTD%25\texon%26\t27344088\t27344141\t.\t+\t.\tID=EXON%3D00000131935;Parent=TRAN%3B000000%3D17239");
  with (record) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["EXON=00000131935", "ASTD%", "exon&", "27344088", "27344141", "", "+", ""]);
    assert(attributes.length == 2); 
    assert(attributes["ID"].all == ["EXON=00000131935"]);
    assert(attributes["Parent"].all == ["TRAN;000000=17239"]);
  }
}

