Feature: Iteration over records

  A GFF3 record corresponds to a line in GFF3. There are nine fields in one
  line and the last one actually corresponds to multiple fields/attributes.
  Some characters are special and have to be escaped in a GFF3 file. The parser
  should split the different fields in a line and replace the escaped
  characters with real characters.

  Scenario: iterating over records
    Given I have an example file for iterating over records
    When I open it
    And call the records method
    Then I should receive a RecordIterator object
    And I should be able to use each to iterate over records

  Scenario: splitting the fields
    Given I have an example file for iterating over records
    When I open it
    And retrieve a record with all fields defined
    Then I should be able to read all the fields using methods of that object

  Scenario: some fields need to be converted to ints and floats
    Given I have an example file for iterating over records
    When I open it
    And retrieve a record with all fields defined
    When I call the "seqname" method on it
    Then I should receive a string value
    When I call the "source" method on it
    Then I should receive a string value
    When I call the "feature" method on it
    Then I should receive a string value
    When I call the "start" method on it
    Then I should receive an integer value
    When I call the "end" method on it
    Then I should receive an integer value
    When I call the "score" method on it
    Then I should receive a float value
    When I call the "strand" method on it
    Then I should receive an integer value
    When I call the "phase" method on it
    Then I should receive an integer value
    When I call the "is_circular" method on it
    Then I should receive a boolean value
    When I call the "id" method on it
    Then I should receive a string value

  Scenario: reading attributes
    Given I have an example file for iterating over records
    When I open it
    And retrieve a record with a few attributes defined
    When I call the "attributes" method on it
    Then I should receive a dictionary of all the attributes in that record

  Scenario: default values for fields that are undefined
    Given I have an example file for iterating over records
    When I open it
    And retrieve a record with all fields as dots
    Then I should receive default values for every field

  Scenario: escaped characters
    Given I have an example file for iterating over records
    When I open it
    And call next_record on it
    When I call the method for a field that has %XX in it
    Then the result should be without %XX and with the equivalent char instead

  Scenario: comments in a file
    Given I have an example file for iterating over records
    When I open it
    And iterate over records using records.each
    Then the rows starting with # and empty rows should be skipped

  Scenario: counting records in a file
    Given I have an example file for iterating over records
    When I open it
    Then I should be able to call records.count to get the number of records in that file

