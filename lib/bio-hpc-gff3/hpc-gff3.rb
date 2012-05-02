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
        @open = true
        #@file_pointer = biohpc_gff3_open @filename
      end

      def lines
        if closed?
          raise RuntimeError, "File closed, operation is not allowed"
        end
        LineIterator.new @filename
      end

      def close
        @open = false
      end

      def closed?
        @open == false
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

