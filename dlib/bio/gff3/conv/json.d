module bio.gff3.conv.json;

import std.array;
import bio.gff3.record, bio.gff3.record_range;

/**
 * Converts a Record object to a string in JSON format. The
 * result is in the following form, but without spaces:
 * {
 *   "seqname" : "value of seqname",
 *   "source"  : "value of source",
 *   "feature" : "value of feature",
 *   "start"   : "value of start",
 *   "end"     : "value of end",
 *   "score"   : "value of score",
 *   "strand"  : "value of strand",
 *   "phase"   : "value of phase",
 *   "attributes"   : {
 *        "attr name 1" : "attr value 1",
 *        "attr name 2" : "attr value 2",
 *                     . . .
 *        "attr name n" : "attr value n",
 *   }
 * }
 */
void to_json(Record record, ref Appender!string app) {
  app.put("{\"seqname\":\"");
  app.put(record.seqname);
  app.put("\",\"source\":\"");
  app.put(record.source);
  app.put("\",\"feature\":\"");
  app.put(record.feature);
  app.put("\",\"start\":\"");
  app.put(record.start);
  app.put("\",\"end\":\"");
  app.put(record.end);
  app.put("\",\"score\":\"");
  app.put(record.score);
  app.put("\",\"strand\":\"");
  app.put(record.strand);
  app.put("\",\"phase\":\"");
  app.put(record.phase);
  app.put("\",\"attributes\":[");

  bool first_attr = true;
  foreach(attr_name, attr_value; record.attributes) {
    if (!first_attr)
      app.put(',');
    else
      first_attr = false;
    app.put("\"");
    app.put(attr_name);
    app.put("\":\"");
    app.put(attr_value.toString());
    app.put('\"');
  }
  app.put("]}");
}

string to_json(Record record) {
  Appender!string app;
  record.to_json(app);
  return app.data;
}

void to_json(Record record, File output) {
  output.write(record.to_json());
}

void to_json(GenericRecordRange records, ref Appender!string app) {
  app.put('[');

  bool first_attr = true;
  foreach(rec; records) {
    if (!first_attr)
      app.put(',');
    else
      first_attr = false;
    rec.to_json(app);
  }

  app.put(']');
}

string to_json(GenericRecordRange records) {
  Appender!string app;
  to_json(records, app);
  return app.data;
}

void to_json(GenericRecordRange records, File output) {
  output.write('[');

  bool first_attr = true;
  foreach(rec; records) {
    if (!first_attr)
      output.write(',');
    else
      first_attr = false;
    output.write(rec.to_json());
  }

  output.write(']');
}


import std.stdio;

unittest {
  writeln("Testing to_json(Record)...");

  auto record = new Record(".\t.\t.\t.\t.\t.\t.\t.\t.");
  assert(record.to_json() == "{\"seqname\":\"\",\"source\":\"\",\"feature\":\"\",\"start\":\"\",\"end\":\"\",\"score\":\"\",\"strand\":\"\",\"phase\":\"\",\"attributes\":[]}");

  record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=testing");
  assert(record.to_json() == "{\"seqname\":\"\",\"source\":\"\",\"feature\":\"\",\"start\":\"\",\"end\":\"\",\"score\":\"\",\"strand\":\"\",\"phase\":\"\",\"attributes\":[\"ID\":\"testing\"]}");

  record = new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=testing");
  assert(record.to_json() == "{\"seqname\":\"1\",\"source\":\"2\",\"feature\":\"3\",\"start\":\"4\",\"end\":\"5\",\"score\":\"6\",\"strand\":\"7\",\"phase\":\"8\",\"attributes\":[\"ID\":\"testing\"]}");
}

