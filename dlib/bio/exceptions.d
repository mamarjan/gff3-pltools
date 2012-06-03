module bio.exceptions;

class ParsingException : Exception {
  this(string message) { super(message); }
}

class AttributeException : ParsingException {
  this(string message, string attributes_field) {
    super(message ~ ": " ~ attributes_field);
  }
}

class RecordException : ParsingException {
  this(string message, string record) {
    super(message ~ ": " ~ record);
  }
}

