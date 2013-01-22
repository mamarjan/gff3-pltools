module bio.gff3.attribute;

import std.algorithm, std.array;
import bio.gff3.validation;
import util.esc_char_conv, util.join_fields;

/**
 * An attribute in a GFF3 or GTF record can have multiple values, separated by
 * commas. This struct can represent both attribute values with a single value
 * and multiple values.
 */
struct AttributeValue {
  this(string[] values, bool esc_chars = true) {
    this.values = values;
    this.esc_chars = esc_chars;
  }

  /**
   * Returns true if the attribute has multiple values.
   */
  @property bool is_multi() { return values.length > 1; }

  /**
   * Returns the first attribute value.
   */
  @property string first() { return values[0]; }

  /**
   * Returns all attribute values as a list of strings.
   */
  @property string[] all() { return values; }

  /**
   * Appends the attribute values to the Appender object app.
   */
  void to_string(ArrayType)(Appender!ArrayType app) {
    string escape_chars_l(string value) {
      return (esc_chars) ? escape_chars(value, is_invalid_in_attribute) : value;
    }

    join_fields(map!(escape_chars_l)(values), ',', app);
  }

  /**
   * Converts the attribute value to string.
   */
  string toString() {
    auto app = appender!(char[])();
    this.to_string(app);
    return cast(string)(app.data);
  }

  private {
    bool esc_chars;
    string[] values;
  }
}

unittest {
  // Testing AttributeValue to_string()/toString()
  assert(AttributeValue(["abc=f"], true).toString() == "abc%3Df");
  assert(AttributeValue(["abc%3Df"], false).toString() == "abc%3Df");
  assert(AttributeValue(["ab","cd","e"], true).toString() == "ab,cd,e");
  assert(AttributeValue(["a=b","c;d","e,f","g&h","ij"], true).toString() == "a%3Db,c%3Bd,e%2Cf,g%26h,ij");
  assert(AttributeValue(["a%3Db","c%3Bd","e%2Cf","g%26h","ij"], false).toString() == "a%3Db,c%3Bd,e%2Cf,g%26h,ij");

  // Test if to_string() also supports char[] appenders
  auto char_app = appender!(char[])();
  AttributeValue(["a%3Db","c%3Bd","e%2Cf","g%26h","ij"], false).to_string(char_app);
  assert(char_app.data == "a%3Db,c%3Bd,e%2Cf,g%26h,ij");
}

