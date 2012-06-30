module BioHPC
  module GFF3
    # Runs the gff3-ffetch utility with the specified parameters.
    # Options include :output and :at_most.
    def self.filter_file filename, filter_string, options = {}
      output_option = nil
      output = nil
      if !options[:output].nil?
        output_option = "--output #{options[:output]}"
      end
      f = IO.popen("./gff3-ffetch --filter #{filter_string} #{filename} #{output_option}")
      if output.nil?
        output = f.read
      end
      f.close
      output
    end
  end
end

