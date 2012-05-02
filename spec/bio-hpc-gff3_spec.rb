require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

TEST_FILENAME="features/data/iterate-over-lines.gff3"

describe "BioHPC::GFF3" do
  describe "open method" do
    it "should accept one argument with the file path" do
      tmp = BioHPC::GFF3::open(TEST_FILENAME)
      tmp.close
    end

    it "should return a BioHPC::GFF3::File object" do
      tmp = BioHPC::GFF3::open(TEST_FILENAME)
      tmp.is_a?(BioHPC::GFF3::File).should be_true
      tmp.close
    end
  end

  describe "File class" do
    describe "initialize" do
      it "should accept one argument with the file path" do
        tmp = BioHPC::GFF3::File.new(TEST_FILENAME)
        tmp.close
      end
    end

    describe "lines method" do
      it "should return an LineIterator object" do
        tmp = BioHPC::GFF3::File.new(TEST_FILENAME)
        tmp.lines.is_a?(BioHPC::GFF3::File::LineIterator).should be_true
        tmp.close
      end
    end

    describe "closed? method" do
      it "should be false if file is still open" do
        tmp = BioHPC::GFF3::File.new(TEST_FILENAME)
        tmp.closed?.should be_false
        tmp.close
      end

      it "should be true if file is closed" do
        tmp = BioHPC::GFF3::File.new(TEST_FILENAME)
        tmp.close
        tmp.closed?.should be_true
      end
    end

    describe "close method" do
      it "should close the file making it unavailable for further reading" do
        tmp = BioHPC::GFF3::File.new(TEST_FILENAME)
        tmp.close
        tmp.closed?.should be_true
      end
    end

    describe "LineIterator class" do
      it "should have an each method for iterating over the file" do
        tmp = BioHPC::GFF3::File.new(TEST_FILENAME)
        tmp_list = []
        tmp.lines.each { |line| tmp_list.push line }
        File.open(TEST_FILENAME).readlines.map { |line| line.chomp }.should == tmp_list
        tmp.close
      end

      it "should have an count method which returns the number of lines" do
        tmp = BioHPC::GFF3::File.new(TEST_FILENAME)
        tmp.lines.count.should == File.open(TEST_FILENAME).readlines.length
        tmp.close
      end
    end
  end
end

