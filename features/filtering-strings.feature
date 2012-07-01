Feature: Filtering GFF3 data in string using gff3-ffetch tool

  The average size of a GFF3 file is growing, and even the
  current files around 1GB in size are too much for most
  parsers. The gff3-ffetch tool has the --filter option
  which makes it possible to select only part of the
  lines in a GFF3 file or from stdin using a filter
  expression.

  The goal of this feature is to make this functionality
  available to Ruby, and let the programmer filter raw GFF3
  data before parsing the results using his parser of chice.

  Scenario: filtering a string with GFF3 data to a string
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
    When I set up the filter to leave only records with a particular ID
    And set the output to be a string
    And run the function for filtering data
    Then I should receive a string with lines which have that ID

  Scenario: filtering a string with GFF3 data to a file
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
    When I set up the filter to leave only records with a particular ID
    And set the output to be a file
    And run the function for filtering data
    Then that file should be filled with lines which have that ID

