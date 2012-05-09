require 'ffi'

module BioHPC
  module Backend
    extend FFI::Library
    ffi_lib 'lib/bio-hpc-dlib.so'
    attach_function :lib_init, [], :void
    attach_function :biohpc_gff3_open, [:string], :int32
    attach_function :biohpc_gff3_close, [:int32], :void
    attach_function :biohpc_gff3_rewind, [:int32], :void
    attach_function :biohpc_gff3_lines_count, [:int32], :uint64
    attach_function :biohpc_gff3_get_line, [:int32], :string
    lib_init
  end

  module GFF3
    def self.open filename
      File.new filename
    end

    class File
      attr_reader :filename

      def initialize filename
        @filename = filename
        @file_pointer = Backend::biohpc_gff3_open @filename
        @open = true
      end

      def lines
        if closed?
          raise RuntimeError, "File closed, operation is not allowed"
        end
        LineIterator.new @filename, @file_pointer
      end

      def close
        Backend::biohpc_gff3_close @file_pointer
        @open = false
      end

      def closed?
        @open == false
      end

      class LineIterator
        def initialize filename, file_pointer
          @filename = filename
          @file_pointer = file_pointer
        end

        def each
          Backend::biohpc_gff3_rewind @file_pointer
          while((line = Backend::biohpc_gff3_get_line(@file_pointer)) != nil)
            yield line
          end
        end
        
        def count
          Backend::biohpc_gff3_lines_count @file_pointer
        end
      end
    end
  end
end

