Feature: Limiting the result of gff3-ffetch tool to a certain number of lines

  The goal of this feature is to let the users
  limit the number of lines in the output of gff3-ffetch.

  Scenario: limiting output while filtering a file
    Given I have a GFF3 file
    When I set up the filter to leave most records after filtering
    And set the output to be a string
    And set the at_most option to 3 lines
    And run the filter
    Then I should receive a string with 4 lines
    And the last line should contain "..."

  Scenario: limiting output while filtering a string
    Given I have some GFF3 data
      """
      ##gff-version 3
      chr17	UCSC	mRNA	62467934	62469545	.	-	.	ID=A00469;Dbxref=AFFX-U133:205840_x_at,Locuslink:2688,Genbank-mRNA:A00469,Swissprot:P01241,PFAM:PF00103,AFFX-U95:1332_f_at,Swissprot:SOMA_HUMAN;Note=growth%20hormone%201;Alias=GH1
      chr17	UCSC	three_prime_UTR	62467934	62468038	.	-	.	Parent=A00469
      chr17	UCSC	CDS	62468039	62468236	.	-	1	Parent=A00469
      chr9	UCSC	mRNA	90517946	90527968	.	-	.	ID=AB000114;Ontology_term=GO:0007155,GO:0005194;Ontology_term=GO:0005578;Dbxref=AFFX-U95:41031_at,Genbank-protein:BAA19055,Unigene:Hs.94070,AFFX-U133:205907_s_at,Genbank-mRNA:AB000114,Locuslink:4958,Swissprot:Q99983,Swissprot:OMD_HUMAN,Refseq-mRNA:NM_005014,Refseq-protein:NP_005005,PFAM:PF01462,PFAM:00560;Note=osteomodulin;Alias=OMD;
      #.	UCSC	protein	.	.	.	.	.	ID=BAA19055;Parent=AB000114
      chr9	UCSC	three_prime_UTR	90517946	90518841	.	-	.	Parent=AB000114
      chr9	UCSC	CDS	90518842	90519167	.	-	1	Parent=AB000114
      chr9	UCSC	CDS	90520309	90521248	.	-	0	Parent=AB000114
      """
    When I set up the filter to leave most records after filtering
    And set the output to be a string
    And set the at_most option to 3 lines
    And run the function for filtering data
    Then I should receive a string with 4 lines
    And the last line should contain "..."

