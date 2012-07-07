module Bio
  module PL
    module GFF3
      # Runs the gff3-ffetch utility with the specified parameters on
      # an external file. Options include :output, :at_most and
      # :pass_fasta_through
      def self.filter_file filename, filter_string, options = {}
        if !File.exists?(filename)
          raise Exception.new("No such file - #{filename}")
        end

        output_option = nil
        output = nil
        if !options[:output].nil?
          output_option = "--output #{options[:output]}"
        end
        if !options[:at_most].nil?
          at_most_option = "--at-most #{options[:at_most]}"
        end
        if options[:pass_fasta_through]
          fasta_option = "--pass-fasta-through"
        end
        gff3_ffetch = IO.popen("gff3-ffetch --filter #{filter_string} #{filename} #{output_option} #{at_most_option} #{fasta_option}")
        if output_option.nil?
          output = gff3_ffetch.read
        end
        gff3_ffetch.close
        output
      end

      # Runs the gff3-ffetch utility with the specified parameters while
      # passing data to its stdin. Options include :output and :at_most.
      def self.filter_data data, filter_string, options = {}
        output_option = nil
        output = nil
        if !options[:output].nil?
          output_option = "--output #{options[:output]}"
        end
        if !options[:at_most].nil?
          at_most_option = "--at-most #{options[:at_most]}"
        end
        if options[:pass_fasta_through]
          fasta_option = "--pass-fasta-through"
        end
        gff3_ffetch = IO.popen("gff3-ffetch --filter #{filter_string} - #{output_option} #{at_most_option} #{fasta_option}", "r+")
        gff3_ffetch.write data
        gff3_ffetch.close_write
        if output_option.nil?
          output = gff3_ffetch.read
        end
        gff3_ffetch.close
        output
      end
    end
  end
end

