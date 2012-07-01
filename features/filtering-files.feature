Feature: Filtering GFF3 files using gff3-ffetch tool

  The average size of a GFF3 file is growing, and even the
  current files around 1GB in size are too much for most
  parsers. The gff3-ffetch tool has the --filter option
  which makes it possible to select only part of the
  lines in a GFF3 file using a filter expression.

  The goal of this feature is to make this functionality
  available to Ruby, so that the programmer can filter an
  external file and then parse the result using his parser
  of choice.

  Scenario: filtering a GFF3 file to a string
    Given I have a GFF3 file
    When I set up the filter to leave only records with a particular ID
    And set the output to be a string
    And run the filter
    Then I should receive a string with lines which have that ID

  Scenario: filtering a GFF3 file to a file
    Given I have a GFF3 file
    When I set up the filter to leave only records with a particular ID
    And set the output to be a file
    And run the filter
    Then that file should be filled with lines which have that ID

