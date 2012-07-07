Feature: Rataining FASTA data in the output of gff3-ffetch tool

  The goal of this feature is to let the user keep the FASTA data
  in the file after it has been filtered.

  Scenario: retaining FASTA data while filtering a file
    Given I have a GFF3 file with FASTA data in it
    When I set up the filter to leave only records with a particular ID
    And set the output to be a string
    And set the pass_through_fasta option to true
    And run the filter
    Then I should find a line with "##FASTA" in the output
    And there should be more lines after that

  Scenario: retaining FASTA data while filtering a string
    Given I have some GFF3 data
      """
      chr17	UCSC	mRNA	62467934	62469545	.	-	.	ID=A00469;Dbxref=AFFX-U133:205840_x_at,Locuslink:2688,Genbank-mRNA:A00469,Swissprot:P01241,PFAM:PF00103,AFFX-U95:1332_f_at,Swissprot:SOMA_HUMAN;Note=growth%20hormone%201;Alias=GH1
      chr17	UCSC	CDS	62468039	62468236	.	-	1	Parent=A00469
      chr17	UCSC	CDS	62468490	62468654	.	-	2	Parent=A00469
      chr17	UCSC	CDS	62468747	62468866	.	-	1	Parent=A00469
      chr17	UCSC	CDS	62469076	62469236	.	-	1	Parent=A00469
      chr17	UCSC	CDS	62469497	62469506	.	-	0	Parent=A00469
      >A00469
      GATTACA
      GATTACA
      """
    When I set up the filter to leave only records with a particular ID
    And set the output to be a string
    And set the pass_through_fasta option to true
    And run the function for filtering data
    Then I should find a line with "##FASTA" in the output
    And there should be more lines after that

