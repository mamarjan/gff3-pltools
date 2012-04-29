require 'ffi'

module BioHPC
  module GFF3
    extend FFI::Library
    ffi_lib 'bio-hpc-dlib.so'
    attach_function :attach, [], :void
    attach_function :detach, [], :void
    attach_function :foo, [], :void
    attach
  end
end

