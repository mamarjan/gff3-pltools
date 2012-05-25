TEST_FILENAME_LINES = "features/data/iterate-over-lines.gff3"

Given /^I have an example file for iterating over lines$/ do
  @test_filename = TEST_FILENAME_LINES
  File.exists?(@test_filename).should be_true
end

When /^I open the file for reading$/ do
  @test_file = BioHPC::GFF3::open(@test_filename)
  @test_file.should_not be_nil
end

Then /^I should be able to use lines\.each to iterate over lines$/ do
  tmp_list = []
  @test_file.lines.each do |line|
    tmp_list.push line
  end
  File.open(@test_filename).readlines.map { |line| line.chomp }.should == tmp_list
  @test_file.close
end

Then /^I should be able to use lines\.count to get the number of lines$/ do
  @test_file.lines.count.should == 3
  @test_file.close
end

When /^close it by calling the close method$/ do
  @test_file.close
end

When /^I try to read from it$/ do
  begin
    @test_file.lines
  rescue RuntimeError => e
    @message = e.message
  end
end

Then /^I should be informed that the operation is not allowed$/ do
  @message.should =~ /is not allowed/
end

