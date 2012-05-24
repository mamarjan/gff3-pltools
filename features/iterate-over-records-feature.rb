TEST_FILENAME = "features/data/iterate-over-records.gff3"

Given /^I have an example file$/ do
  @test_filename = TEST_FILENAME
  File.exists?(@test_filename).should be_true
end

When /^I open it$/ do
  @gff3_file = BioHPC::GFF3::open(TEST_FILENAME)
  @gff3_file.should_not be_nil
end

When /^call the records method$/ do
  lambda {
    @records = @gff3_file.records
  }.should_not raise_error
end

Then /^I should receive a RecordIterator object$/ do
  @records.should be_an_instance_of(BioHPC::GFF3::File::RecordIterator)
end

Then /^I should be able to use each to iterate over records$/ do
  tmp_list = []
  @records.each do |rec|
    tmp_list.push rec
  end
  tmp_list.size.should == 3
end

When /^retrieve a record with all fields defined$/ do
  @record = nil
  @gff3_file.records.each do |rec|
    @record = rec
    break
  end
  @record.should_not be_nil
  @record.should be_an_instance_of(BioHPC::GFF3::Record)
end

Then /^I should be able to read all the fields using methods of that object$/ do
  lambda {
    @record.seqname
    @record.source
    @record.feature
    @record.start
    @record.end
    @record.score
    @record.strand
    @record.phase
  }.should_not raise_error
  @record.seqname.should == "ENSRNOG00000019422"
  @record.source.should == "Ensembl"
  @record.feature.should == "gene"
  @record.start.to_s.should == "27333567"
  @record.end.to_s.should == "27357352"
  @record.score.to_s.should == "1.0"
  @record.strand.should == BioHPC::GFF3::Record::STRAND_POSITIVE
  @record.phase.to_s.should == "2"
end

When /^I call the "([^"]*)" method on it$/ do |method_name|
  @value = @record.send(method_name)
end

Then /^I should receive a string value$/ do
  @value.should be_an_instance_of(String)
end

Then /^I should receive an integer value$/ do
  @value.should be_a_kind_of(Integer)
end

Then /^I should receive a float value$/ do
  @value.should be_a_kind_of(Numeric)
end

Then /^I should receive a boolean value$/ do
  [true, false].should include(@value)
end

