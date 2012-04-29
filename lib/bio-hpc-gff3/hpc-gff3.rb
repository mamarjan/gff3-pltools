require 'ffi'

module BioHPC
  module GFF3
    extend FFI::Library
    ffi_lib './bio-hpc-dlib.so'
    attach_function :foo, [], :void
  end
end

