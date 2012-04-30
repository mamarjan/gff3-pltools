TEST_FILENAME="features/data/iterate-over-lines.gff3"

TEST_LINES = <<-eos
ENSRNOG00000019422  Ensembl gene  27333567  27357352  . + . ID=ENSRNOG00000019422;Dbxref=taxon:10116;organism=Rattus norvegicus;chromosome=18;name=EGR1_RAT;source=UniProtKB/Swiss-Prot
TRAN00000017239 ASTD  transcript  27344088  27346461  . + . ID=TRAN00000017239;Parent=ENSRNOG00000019422
EXON00000131935 ASTD  exon  27344088  27344141  . + . ID=EXON00000131935;Parent=TRAN00000017239
eos

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
  TEST_LINES.lines.map { |line| line.chomp }.should == tmp_list
end

Then /^I should be able to use lines\.count so get the number of lines$/ do
  @test_file.lines.count.should == 3
end

