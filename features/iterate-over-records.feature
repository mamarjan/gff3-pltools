Feature: Iteration over records

  A GFF3 record corresponds to a line in GFF3. There are nine fields in one
  line and the last one actually corresponds to multiple fields/attributes.
  Some characters are special and have to be escaped in a GFF3 file. The parser
  should split the different fields in a line and replace the escaped
  characters with real characters.

  Scenario: splitting the fields
    Given I have an example file
    When I open it
    And call next_record on it
    Then I should receive a record object
    And I should be able to read all the fields using methods of that object

  Scenario: reading attibutes
    Given I have an example file
    When I open it
    And call next_record on it
    When I call the attributes method on the record object
    Then I should receive a dictionary of all the attributes of the first line

  Scenario: some fields need to be converted to ints and floats
    Given I have an example file
    When I open it
    And call next_record on it
    When I call the start and end methods on it
    Then I should receive integer values for those fields
    When I call the score method on it
    Then I should receive a float value
    When I call the phase method on it
    Then I should receive an integer value
    When I call the strand method on it
    Then I should receive an integer value
    When I call the is_circular method on it
    Then I should receive a boolean value

  Scenario: null for fields that are undefined
    Given I have an example file
    When I open it
    And call next_record on it
    When I call the method for a field that is not defined on the first line
    Then I should receive the nil object

  Scenario: escaped characters
    Given I have and example file with escaped chars
    When I open it
    And call next_record on it
    When I call the method for a field that has %XX in it
    Then the result should be without %XX and with the equivalent char instead

