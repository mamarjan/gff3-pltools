require 'tmpdir'

Given /^I have a GFF3 file$/ do
  @filename = "./test/data/knownGene.gff3"
  File.exists?(@filename).should be_true
end

When /^I set up the filter to leave only records with a particular ID$/ do
  @filter_string = "attribute:ID:equals:AB000114"
end

When /^set the output to be a string$/ do
  @output_filename = nil
end

When /^run the filter$/ do
  @result = Bio::PL::GFF3.filter_file @filename, @filter_string,
                                      output: @output_filename,
                                      at_most: @at_most,
                                      pass_fasta_through: @pass_fasta_through
end

Then /^I should receive a string with lines which have that ID$/ do
  lines = @result.lines
  lines.next.should match(/ID=AB000114/)
  lambda { lines.next }.should raise_error(StopIteration)
end

When /^set the output to be a file$/ do
  @tmpdir = Dir.mktmpdir("gff3")
  @output_filename = File.join(@tmpdir, "test_file.gff3")
end

Then /^that file should be filled with lines which have that ID$/ do
  lines = File.open(@output_filename, "r").lines
  lines.next.should match(/ID=AB000114/)
  lambda { lines.next }.should raise_error(StopIteration)
  FileUtils.remove_entry_secure @tmpdir
end

