require 'ffi'

module BioHPC
  module Backend
    extend FFI::Library
    ffi_lib 'bio-hpc-dlib.so'
    attach_function :attach, [], :void
    attach_function :detach, [], :void
    #attach_function :biohpc_gff3_open, [ :string ], :pointer
    attach
  end

  module GFF3
    def self.open filename
      File.new filename
    end

    class File
      attr_reader :filename

      def initialize filename
        @filename = filename
        #@file_pointer = biohpc_gff3_open @filename
      end

      def lines
        LineIterator.new @filename
      end

      class LineIterator
        def initialize filename
          @filename = filename
        end

        def each
          ::File.open(@filename).lines.map { |line| line.chomp }.each do |line|
            yield line
          end
        end
        
        def count
          ::File.open(@filename).readlines.length
        end
      end
    end
  end
end

