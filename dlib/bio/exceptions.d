module bio.exceptions;

class ParsingException : Exception {
  this(string message) { super(message); }
}

class AttributeException : ParsingException {
  this(string message, string attributesField) {
    super(message ~ ": " ~ attributesField);
  }
}

class RecordException : ParsingException {
  this(string message, string record) {
    super(message ~ ": " ~ record);
  }
}

