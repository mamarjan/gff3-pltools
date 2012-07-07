Given /^I have some GFF(\d+) data$/ do |arg1, gff3_data|
  @gff3_data = gff3_data
end

When /^run the function for filtering data$/ do
  @result = Bio::PL::GFF3::filter_data @gff3_data, @filter_string,
                                       output: @output_filename,
                                       at_most: @at_most,
                                       pass_fasta_through: @pass_fasta_through
end

