module biohpc.gff3;

import std.conv, std.stdio, std.array, std.string, std.range, biohpc.util;

/**
 * Parses a string of GFF3 data. Returns a range of records.
 */
RecordRange parse(string data) {
  return new RecordRange(data);
}

/**
 * Represents a lazy range of GFF3 records from a string.
 * The string which is the source of data is never copied in the process of
 * parsing. All operations are done using slicing.
 */
class RecordRange {
  this(string data) {
    this.data = new LazySplitLines(data);
  }

  /**
   * Return the next record in range.
   * Ignores comments, pragmas and empty lines in the data source
   */
  Record front() {
    // TODO: Think about adding a record cache instead of recreating the front
    //       record every time
    auto next_line = data.front;
    while ((isComment(next_line) || isEmptyLine(next_line)) && !data.empty) {
      data.popFront();
      next_line = data.front;
    }
    return Record(next_line);
  }

  /**
   * Pops the next record in range.
   */
  void popFront() { data.popFront(); }

  /**
   * Return true if no more records left in the range.
   */
  bool empty() { return data.empty; }
  
  private {
    LazySplitLines data;
  }
}

/**
 * Represents a parsed line in a GFF3 file.
 */
struct Record {
  this(string line) {
    parseLine(line);
  }

  /**
   * Parse a line from a GFF3 file and set object values.
   * The line is first split into its parts and then escaped
   * characters are replaced in those fields.
   */
  void parseLine(string line) {
    auto parts = split(line, "\t");
    seqname = replaceEscapedChars(parts[0]);
    source  = replaceEscapedChars(parts[1]);
    feature = replaceEscapedChars(parts[2]);
    start   = parts[3];
    end     = parts[4];
    score   = parts[5];
    strand  = parts[6];
    phase   = parts[7];
    parseAttributes(parts[8]);
  }

  string seqname;
  string source;
  string feature;
  string start;
  string end;
  string score;
  string strand;
  string phase;
  string[string] attributes;

  @property string id() {
    return attributes["ID"];
  }

  @property bool isCircular() {
    return attributes["Is_circular"] == "true";
  }

  private {

    void parseAttributes(string attributes_field) {
      if (attributes_field[0] != '.') {
        auto raw_attributes = split(attributes_field, ";");
        foreach(attribute; raw_attributes) {
          auto attribute_parts = split(attribute, "=");
          auto attribute_name = replaceEscapedChars(attribute_parts[0]);
          auto attribute_value = replaceEscapedChars(attribute_parts[1]);
          attributes[attribute_name] = attribute_value;
        }
      }
    }

  }
}

private {

  /**
   * Converts the characters escaped with the URL escaping convention (%XX)
   * in a string to their real char values.
   */
  string replaceEscapedChars(string original) {
    auto index = indexOf(original, '%');
    if (index < 0) {
      return original;
    } else {
      return original[0..index] ~
             convertEscapedChar(original[index+1..index+3]) ~
             replaceEscapedChars(original[index+3..$]);
    }
  }

  /**
    * Converts characters in hexadecimal format to their real char value.
    */
  char convertEscapedChar(string code) {
    uint numeric = to!int(code, 16);
    return cast(char) numeric;
  }


  private bool isEmptyLine(string line) {
    return line.strip() == "";
  }

  private bool isComment(string line) {
    return indexOf(line, '#') != -1;
  }
}


unittest {
  writeln("Testing convertEscapedChar...");
  assert(convertEscapedChar("3D") == '=');
  assert(convertEscapedChar("00") == '\0');
}

unittest {
  assert(replaceEscapedChars("%3D") == "=");
  assert(replaceEscapedChars("Testing %3D") == "Testing =");
  assert(replaceEscapedChars("Multiple %3B replacements %00 and some %25 more") == "Multiple ; replacements \0 and some % more");
  assert(replaceEscapedChars("One after another %3D%3B%25") == "One after another =;%");
}

unittest {
  writeln("Testing GFF3 Record...");
  // Test line parsing with a normal line
  auto record = Record("ENSRNOG00000019422\tEnsembl\tgene\t27333567\t27357352\t1.0\t+\t2\tID=ENSRNOG00000019422;Dbxref=taxon:10116;organism=Rattus norvegicus;chromosome=18;name=EGR1_RAT;source=UniProtKB/Swiss-Prot;Is_circular=true");
  assert([record.seqname, record.source, record.feature, record.start, record.end, record.score, record.strand, record.phase] ==
         ["ENSRNOG00000019422", "Ensembl", "gene", "27333567", "27357352", "1.0", "+", "2"]);
  assert(record.attributes == [ "ID" : "ENSRNOG00000019422", "Dbxref" : "taxon:10116", "organism" : "Rattus norvegicus", "chromosome" : "18", "name" : "EGR1_RAT", "source" : "UniProtKB/Swiss-Prot", "Is_circular" : "true"]);

  // Test parsing lines with dots - undefined values
  record = Record(".\t.\t.\t.\t.\t.\t.\t.\t.");
  assert([record.seqname, record.source, record.feature, record.start, record.end, record.score, record.strand, record.phase] ==
         [".", ".", ".", ".", ".", ".", ".", "."]);
  assert(record.attributes.length == 0);

  // Test parsing lines with escaped characters
  record = Record("EXON%3D00000131935\tASTD%25\texon%26\t27344088\t27344141\t.\t+\t.\tID=EXON%3D00000131935;Parent=TRAN%3B000000%3D17239");
  assert([record.seqname, record.source, record.feature, record.start, record.end, record.score, record.strand, record.phase] ==
         ["EXON=00000131935", "ASTD%", "exon&", "27344088", "27344141", ".", "+", "."]);
  assert(record.attributes == ["ID" : "EXON=00000131935", "Parent" : "TRAN;000000=17239"]);
}

unittest {
  writeln("Testing isComment...");
  assert(isComment("# test") == true);
  assert(isComment("     # test") == true);
  assert(isComment("# test\n") == true);

  writeln("Testing isEmptyLine...");
  assert(isEmptyLine("") == true);
  assert(isEmptyLine("    ") == true);
  assert(isEmptyLine("\n") == true);
}

unittest {
  writeln("Testing RecordRange...");
  File file;
  file.open("../test/data/records.gff3", "r");
  writeln(file.size);
  char[] buf = new char[cast(uint)(file.size)];
}

