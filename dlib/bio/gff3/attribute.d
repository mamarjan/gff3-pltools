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
  @property string first() {
    return values[0];
  }

  /**
   * Returns all attribute values as a list of strings.
   */
  @property string[] all() {
    return values;
  }

  /**
   * Appends the attribute values to the Appender object app.
   */
  void to_string(ArrayType)(Appender!ArrayType app) {
    string helper(string value) {
      return escape_chars(value, is_invalid_in_attribute);
    }

    if (esc_chars)
      join_fields(map!(helper)(values), ',', app);
    else
      join_fields(values, ',', app);
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
  AttributeValue value = AttributeValue(["abc=f"], true);
  auto app = appender!string();
  value.to_string(app);
  assert(app.data == "abc%3Df");

  value = AttributeValue(["abc%3Df"], false);
  assert(value.toString() == "abc%3Df");

  value = AttributeValue(["ab","cd","e"], true);
  app = appender!string();
  value.to_string(app);
  assert(app.data == "ab,cd,e");

  value = AttributeValue(["a=b","c;d","e,f","g&h","ij"], true);
  app = appender!string();
  value.to_string(app);
  assert(app.data == "a%3Db,c%3Bd,e%2Cf,g%26h,ij");

  value = AttributeValue(["a%3Db","c%3Bd","e%2Cf","g%26h","ij"], false);
  app = appender!string();
  value.to_string(app);
  assert(app.data == "a%3Db,c%3Bd,e%2Cf,g%26h,ij");
}

