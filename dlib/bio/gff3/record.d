module bio.gff3.record;

import bio.gff3.conv.gff3, bio.gff3.attribute;

public import bio.gff3.data_formats;

enum RecordType {
  REGULAR,
  COMMENT,
  PRAGMA
}

// Aliases for conversion delegates
alias bool delegate(Record) RecordToBoolean;
alias string delegate(Record) RecordToString;

/**
 * Represents a parsed line in a GFF3 file.
 */
class Record {

  RecordType record_type = RecordType.REGULAR;
  string pragma_text;
  string comment_text;

  string seqname;
  string source;
  string feature;
  string start;
  string end;
  string score;
  string strand;
  string phase;
  AttributeValue[string] attributes;

  /**
   * Accessor methods for most important GFF3 attributes:
   */
  @property string   id()             { return ("ID" in attributes)            ? attributes["ID"].first                      : null;  }
  @property string   name()           { return ("Name" in attributes)          ? attributes["Name"].first                    : null;  }
  @property string   alias_attr()     { return ("Alias" in attributes)         ? attributes["Alias"].first                   : null;  }
  @property string[] aliases()        { return ("Alias" in attributes)         ? attributes["Alias"].all                     : null;  }
  @property string   parent()         { return ("Parent" in attributes)        ? attributes["Parent"].first                  : null;  }
  @property string[] parents()        { return ("Parent" in attributes)        ? attributes["Parent"].all                    : null;  }
  @property string   target()         { return ("Target" in attributes)        ? attributes["Target"].first                  : null;  }
  @property string   gap()            { return ("Gap" in attributes)           ? attributes["Gap"].first                     : null;  }
  @property string   derives_from()   { return ("Derives_from" in attributes)  ? attributes["Derives_from"].first            : null;  }
  @property string   note()           { return ("Note" in attributes)          ? attributes["Note"].first                    : null;  }
  @property string[] notes()          { return ("Note" in attributes)          ? attributes["Note"].all                      : null;  }
  @property string   dbxref()         { return ("Dbxref" in attributes)        ? attributes["Dbxref"].first                  : null;  }
  @property string[] dbxrefs()        { return ("Dbxref" in attributes)        ? attributes["Dbxref"].all                    : null;  }
  @property string   ontology_term()  { return ("Ontology_term" in attributes) ? attributes["Ontology_term"].first           : null;  }
  @property string[] ontology_terms() { return ("Ontology_term" in attributes) ? attributes["Ontology_term"].all             : null;  }
  @property bool     is_circular()    { return ("Is_circular" in attributes)   ? (attributes["Is_circular"].first == "true") : false; }

  /**
   * Accessor methods for GTF attributes:
   */
  @property string   gene_id()        { return ("gene_id" in attributes)       ? attributes["gene_id"].first                 : null;  }
  @property string   transcript_id()  { return ("transcript_id" in attributes) ? attributes["transcript_id"].first           : null;  }

  /**
   * A record can be a comment, a pragma, or a regular record. Use these
   * functions to test for the type of a record.
   */
  @property bool is_regular() { return record_type == RecordType.REGULAR; }
  @property bool is_comment() { return record_type == RecordType.COMMENT; }
  @property bool is_pragma() { return record_type == RecordType.PRAGMA; }

  /**
   * toString() converts the record to a GFF3 line by default.
   */
  string toString() {
    return to_gff3(this);
  }

  /**
   * This field should be true if the escaped characters in the source file
   * have been converted to their original form. If false, the fields in this
   * record still have chars escaped in the URL format.
   */
  bool esc_chars;
}

import bio.gff3.line;

unittest {
  // Test id() method/property
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1")).id == "1");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=")).id == "");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t.")).id is null);

  // Test name() method/property
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tName=my_name")).name == "my_name");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tName=")).name == "");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t.")).name is null);

  // Test isCircular() method/property
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t.")).is_circular == false);
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tIs_circular=false")).is_circular == false);
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tIs_circular=true")).is_circular == true);

  // Test the Parent() method/property
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t.")).parent is null);
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tParent=test")).parent == "test");
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\tID=1;Parent=test;")).parent == "test");

  // Test is_comment
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C")).is_comment == false);
  assert((parse_line("# test")).is_comment == true);
  assert((parse_line("## test")).is_comment == false);
  assert((parse_line("# test")).toString == "# test");

  // Test is_pragma
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C")).is_pragma == false);
  assert((parse_line("# test")).is_pragma == false);
  assert((parse_line("## test")).is_pragma == true);
  assert((parse_line("## test")).toString == "## test");

  // Test is_regular
  assert((parse_line(".\t.\t.\t.\t.\t.\t.\t.\t%2C=%2C")).is_regular == true);
  assert((parse_line("# test")).is_regular == false);
  assert((parse_line("## test")).is_regular == false);
}

