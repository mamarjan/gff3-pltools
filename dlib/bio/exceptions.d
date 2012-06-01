module bio.exceptions;

class ParsingException : Exception {
  this(string message) { super(message); }
}

class AttributeException : ParsingException {
  this(string message) { super(message); }
}

