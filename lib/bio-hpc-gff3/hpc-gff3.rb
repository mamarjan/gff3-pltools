require 'ffi'

module BioHPC
  module Backend
    extend FFI::Library
    ffi_lib 'lib/bio-hpc-dlib.so'
    class GFF3RecordStruct < FFI::Struct
      layout :seqname, :string,
        :source, :string,
        :feature, :string,
        :start, :uint64,
        :end, :uint64,
        :score, :double,
        :strand, :int32,
        :phase, :int32,
        :is_circular, :int32,
        :id, :string,
        :attributes, :pointer # a NULL terminated list of zero terminated strings

      def get_all_attributes
        result = {}
        current_pointer = self[:attributes]
        while !current_pointer.read_pointer.null?
          attr_name = current_pointer.read_pointer.read_string_to_null
          current_pointer += FFI::Pointer.size
          attr_value = current_pointer.read_pointer.read_string_to_null
          current_pointer += FFI::Pointer.size
          result[attr_name] = attr_value
        end
        result
      end
    end
    attach_function :lib_init, [], :void
    attach_function :biohpc_gff3_open, [:string], :int32
    attach_function :biohpc_gff3_close, [:int32], :void
    attach_function :biohpc_gff3_rewind, [:int32], :void
    attach_function :biohpc_gff3_lines_count, [:int32], :uint64
    attach_function :biohpc_gff3_get_line, [:int32], :string
    attach_function :biohpc_gff3_get_record, [:int32], :pointer
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
        LineIterator.new @file_pointer
      end

      def records
        RecordIterator.new @file_pointer
      end

      def close
        Backend::biohpc_gff3_close @file_pointer
        @open = false
      end

      def closed?
        @open == false
      end

      class LineIterator
        def initialize file_pointer
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

      class RecordIterator
        def initialize file_pointer
          @file_pointer = file_pointer
        end

        def each
          Backend::biohpc_gff3_rewind @file_pointer
          while(!(record_pointer = Backend::biohpc_gff3_get_record(@file_pointer)).null?)
            yield Record.new(record_pointer)
          end
        end
      end
    end

    class Record
      STRAND_NO = 0
      STRAND_POSITIVE = 1
      STRAND_NEGATIVE = 2
      STRAND_UNKNOWN = 3

      def initialize record_pointer
        @struct = Backend::GFF3RecordStruct.new(record_pointer)
      end

      def seqname
        @seqname ||= @struct[:seqname]
      end

      def source
        @source ||= @struct[:source]
      end

      def feature
        @feature ||= @struct[:feature]
      end

      def start
        @start ||= @struct[:start]
      end

      def end
        @end ||= @struct[:end]
      end
      
      def score
        @score ||= @struct[:score]
      end

      def strand
        @strand ||= @struct[:strand]
      end

      def phase
        @phase ||= @struct[:phase]
      end

      def is_circular
        @is_circular ||= @struct[:is_circular] == 1
      end

      def id
        @id ||= @struct[:id]
      end

      def attributes
        @attributes ||= @struct.get_all_attributes
      end
    end
  end
end

