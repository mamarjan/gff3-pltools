TEST_FILENAME="features/data/iterate-over-lines.gff3"

Given /^I have a GFF3 file on the disk$/ do
  File.exists?(TEST_FILENAME).should be_true
end

When /^I open the file for reading$/ do
  @test_file = BioHPC::GFF3::open(TEST_FILENAME)
end

Then /^I should be able to use lines\.each to iterate over lines$/ do
  tmp_list = []
  @test_file.lines.each do |line|
    tmp_list.push line
  end
  File.open(TEST_FILENAME).readlines.map { |line| line.chomp }.should == tmp_list
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

