
Given /^I have a GFF3 file with FASTA data in it$/ do
  @filename = "./test/data/knownGene.gff3"
  File.exists?(@filename).should be_true
end

When /^set the pass_through_fasta option to true$/ do
  @pass_fasta_through = true
end

Then /^I should find a line with "(.*?)" in the output$/ do |fasta_header|
  @parsed_result = @result.lines.map { |row| row.index(fasta_header) }
  @fasta_start = @parsed_result.index { |x| !x.nil? }
  @fasta_start.should_not be_nil
end

Then /^there should be more lines after that$/ do
  @parsed_result.size.should > (@fasta_start+1)
end

