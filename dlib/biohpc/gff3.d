module biohpc.gff3;

import std.conv, std.stdio, std.array, std.string, std.range, biohpc.util;

/**
 * Parses a string of GFF3 data.
 * Returns: a range of records.
 */
auto parse(string data) {
  return new RecordRange!(LazySplitLines)(new LazySplitLines(data));
}

/**
 * Parses a file with GFF3 data.
 * Returns: a range of records.
 */
auto open(string filename) {
  return new RecordRange!(typeof(File("", "r").byLine()))(File(filename, "r").byLine());
}

/**
 * Represents a lazy range of GFF3 records from a range of lines.
 */
class RecordRange(SourceRangeType) {
  this(SourceRangeType data) {
    this.data = data;
  }

  /**
   * Return the next record in range.
   * Ignores comments, pragmas and empty lines in the data source
   */
  @property Record front() {
    // TODO: Think about adding a record cache instead of recreating the front
    //       record every time
    static if (is(typeof(data) == LazySplitLines)) {
      return Record(nextLine());
    } else {
      return Record(to!string(nextLine()));
    }
  }

  /**
   * Pops the next record in range.
   */
  void popFront() {
    // First get to a line that has a valid record in it
    nextLine();
    data.popFront();
  }

  /**
   * Return true if no more records left in the range.
   */
  @property bool empty() { 
    return nextLine() is null;
  }

  auto getFastaRange() {
    if (empty && fastaMode)
      return new FastaRange!(SourceRangeType)();
    else
      return null;
  }

  /**
   * Fasta range for sequences contained in a GFF3 file.
   */
  class FastaRange(SourceRangeType) {
    @property FastaRecord front() {
      if (cache is null) {
        cache = getNextRecord();
      }
      return cache;
    }

    void popFront() {
      cache = null;
    }

    @property bool empty() {
      return getNextRecord() is null;
    }

    private {
      alias typeof(SourceRangeType.front()) Char;

      FastaRecord cache;

      FastaRecord getNextRecord() {
        auto header = nextFastaLine();
        this.outer.data.popFront();
        auto sequence = [nextFastaLine()];
        this.outer.data.popFront();
        auto currentFastaLine = nextFastaLine();
        while ((currentFastaLine != null) && (currentFastaLine[0] != '>')) {
          sequence ~= currentFastaLine;
          this.outer.data.popFront();
          currentFastaLine = nextFastaLine();
        }
        auto fastaSequence = join(sequence);
        FastaRecord result = new FastaRecord();
        static if (is(typeof(this.outer.data) == LazySplitLines)) {
          result.header = header;
          result.sequence = fastaSequence;
        } else {
          result.header = to!string(header);
          result.sequence = to!string(fastaSequence);
        }
        return result;
      }

      Char nextFastaLine() {
        auto line = this.outer.data.front;
        while ((isComment(line) || isEmptyLine(line)) && !this.outer.data.empty) {
          this.outer.data.popFront();
          if (!this.outer.data.empty)
            line = this.outer.data.front;
        }
        if (this.outer.data.empty)
          return null;
        else
          return line;
      }
    }
  }

  class FastaRecord {
    string header;
    string sequence;
  }
  
  private {
    // This is required to support string and char[] sources
    alias typeof(SourceRangeType.front()) Char;

    SourceRangeType data;
    bool fastaMode = false;

    Char nextLine() {
      auto line = data.front;
      while ((isComment(line) || isEmptyLine(line)) && !data.empty && !startOfFASTA(line)) {
        data.popFront();
        if (!data.empty)
          line = data.front;
      }
      if (startOfFASTA(line))
        fastaMode = true;
      if (data.empty || fastaMode)
        return null;
      else
        return line;
    }

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
    seqname = replaceURLEscapedChars(parts[0]);
    source  = replaceURLEscapedChars(parts[1]);
    feature = replaceURLEscapedChars(parts[2]);
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
          auto attribute_name = replaceURLEscapedChars(attribute_parts[0]);
          auto attribute_value = replaceURLEscapedChars(attribute_parts[1]);
          attributes[attribute_name] = attribute_value;
        }
      }
    }

  }
}

private {

  bool isEmptyLine(T)(T[] line) {
    return line.strip() == "";
  }

  bool isComment(T)(T[] line) {
    return indexOf(line, '#') != -1;
  }

  bool startOfFASTA(T)(T[] line) {
    return (line.length >= 1) ? (line.startsWith("##FASTA") || (line[0] == '>')) : false;
  }
}

unittest {
  writeln("Testing GFF3 Record...");
  // Test line parsing with a normal line
  auto record = Record("ENSRNOG00000019422\tEnsembl\tgene\t27333567\t27357352\t1.0\t+\t2\tID=ENSRNOG00000019422;Dbxref=taxon:10116;organism=Rattus norvegicus;chromosome=18;name=EGR1_RAT;source=UniProtKB/Swiss-Prot;Is_circular=true");
  with (record) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["ENSRNOG00000019422", "Ensembl", "gene", "27333567", "27357352", "1.0", "+", "2"]);
    assert(attributes == [ "ID" : "ENSRNOG00000019422", "Dbxref" : "taxon:10116", "organism" : "Rattus norvegicus", "chromosome" : "18", "name" : "EGR1_RAT", "source" : "UniProtKB/Swiss-Prot", "Is_circular" : "true"]);
  }

  // Test parsing lines with dots - undefined values
  record = Record(".\t.\t.\t.\t.\t.\t.\t.\t.");
  with (record) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           [".", ".", ".", ".", ".", ".", ".", "."]);
    assert(attributes.length == 0);
  }

  // Test parsing lines with escaped characters
  record = Record("EXON%3D00000131935\tASTD%25\texon%26\t27344088\t27344141\t.\t+\t.\tID=EXON%3D00000131935;Parent=TRAN%3B000000%3D17239");
  with (record) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["EXON=00000131935", "ASTD%", "exon&", "27344088", "27344141", ".", "+", "."]);
    assert(attributes == ["ID" : "EXON=00000131935", "Parent" : "TRAN;000000=17239"]);
  }
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

  writeln("Testing startOfFASTA...");
  assert(startOfFASTA("##FASTA") == true);
  assert(startOfFASTA(">ctg123") == true);
  assert(startOfFASTA("Test 123") == false);
}

unittest {
  writeln("Testing parsing strings with parse function and RecordRange...");

  // Retrieve test file into a string
  File gff3File;
  gff3File.open("./test/data/records.gff3", "r");
  char[] buf = new char[cast(uint)(gff3File.size)];
  auto data = to!string(gff3File.rawRead(buf));

  // Parse data
  auto records = parse(data);
  auto record1 = records.front; records.popFront();
  auto record2 = records.front; records.popFront();
  auto record3 = records.front; records.popFront();
  assert(records.empty == true);

  // Check the results
  with(record1) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["ENSRNOG00000019422", "Ensembl", "gene", "27333567", "27357352", "1.0", "+", "2"]);
    assert(attributes == [ "ID" : "ENSRNOG00000019422", "Dbxref" : "taxon:10116", "organism" : "Rattus norvegicus", "chromosome" : "18", "name" : "EGR1_RAT", "source" : "UniProtKB/Swiss-Prot", "Is_circular" : "true"]);
  }
  with(record2) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           [".", ".", ".", ".", ".", ".", ".", "."]);
    assert(attributes.length == 0);
  }
  with(record3) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["EXON=00000131935", "ASTD%", "exon&", "27344088", "27344141", ".", "+", "."]);
    assert(attributes == ["ID" : "EXON=00000131935", "Parent" : "TRAN;00000017239"]);
  }
}

unittest {
  writeln("Testing parsing strings with open function and RecordRange...");

  // Parse file
  auto records = open("./test/data/records.gff3");
  auto record1 = records.front; records.popFront();
  auto record2 = records.front; records.popFront();
  auto record3 = records.front; records.popFront();
  assert(records.empty == true);

  // Check the results
  with(record1) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["ENSRNOG00000019422", "Ensembl", "gene", "27333567", "27357352", "1.0", "+", "2"]);
    assert(attributes == [ "ID" : "ENSRNOG00000019422", "Dbxref" : "taxon:10116", "organism" : "Rattus norvegicus", "chromosome" : "18", "name" : "EGR1_RAT", "source" : "UniProtKB/Swiss-Prot", "Is_circular" : "true"]);
  }
  with(record2) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           [".", ".", ".", ".", ".", ".", ".", "."]);
    assert(attributes.length == 0);
  }
  with(record3) {
    assert([seqname, source, feature, start, end, score, strand, phase] ==
           ["EXON=00000131935", "ASTD%", "exon&", "27344088", "27344141", ".", "+", "."]);
    assert(attributes == ["ID" : "EXON=00000131935", "Parent" : "TRAN;00000017239"]);
  }
}

