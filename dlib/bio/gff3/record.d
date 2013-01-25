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
   * This esc_chars field should be true if the escaped characters in the source
   * file have been converted to their original form. If false, the fields in
   * this record still have chars escaped in the URL format.
   */
  bool esc_chars;

  /**
   * Accessor methods for common GFF3 attributes:
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
   * Accessor methods for common GTF attributes:
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
  string toString() { return to_gff3(this); }
}

unittest {
  // Test id() method/property
  auto record = new Record();
  assert(record.id is null);
  record.attributes["ID"] = AttributeValue(["1"]);
  assert(record.id == "1");

  // Test name() method/property
  record = new Record();
  assert(record.name is null);
  record.attributes["Name"] = AttributeValue(["my_name"]);
  assert(record.name == "my_name");

  // Test isCircular() method/property
  record = new Record();
  assert(record.is_circular == false);
  record.attributes["Is_circular"] = AttributeValue(["false"]);
  assert(record.is_circular == false);
  record.attributes["Is_circular"] = AttributeValue(["true"]);
  assert(record.is_circular == true);

  // Test the Parent() method/property
  record = new Record();
  assert(record.parent is null);
  record.attributes["Parent"] = AttributeValue(["test"]);
  assert(record.parent == "test");

  // Test is_comment
  record = new Record();
  assert(record.is_comment == false);
  record.record_type = RecordType.REGULAR;
  assert(record.is_comment == false);
  record.record_type = RecordType.PRAGMA;
  assert(record.is_comment == false);
  record.record_type = RecordType.COMMENT;
  assert(record.is_comment == true);

  // Test is_pragma
  record = new Record();
  assert(record.is_pragma == false);
  record.record_type = RecordType.REGULAR;
  assert(record.is_pragma == false);
  record.record_type = RecordType.PRAGMA;
  assert(record.is_pragma == true);
  record.record_type = RecordType.COMMENT;
  assert(record.is_pragma == false);

  // Test is_regular
  record = new Record();
  assert(record.is_regular == true);
  record.record_type = RecordType.REGULAR;
  assert(record.is_regular == true);
  record.record_type = RecordType.PRAGMA;
  assert(record.is_regular == false);
  record.record_type = RecordType.COMMENT;
  assert(record.is_regular == false);
}

