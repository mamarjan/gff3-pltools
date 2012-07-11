# encoding: utf-8

require 'rake/clean'

ENV["PATH"] = File.join(File.dirname(__FILE__), "bin") + ":" + ENV["PATH"]

directory "bin"
CLEAN.include("bin/")

DFILES = ["dlib/bio/gff3/file.d",
          "dlib/bio/gff3/data.d",
          "dlib/bio/gff3/record.d",
          "dlib/bio/gff3/record_range.d",
          "dlib/bio/gff3/validation.d",
          "dlib/bio/fasta.d",
          "dlib/bio/gff3/feature.d",
          "dlib/bio/gff3/feature_range.d",
          "dlib/bio/gff3/filtering.d",
          "dlib/util/esc_char_conv.d",
          "dlib/util/join_lines.d",
          "dlib/util/read_file.d",
          "dlib/util/split_into_lines.d",
          "dlib/util/range_with_cache.d",
          "dlib/util/split_file.d",
          "dlib/util/split_line.d",
          "dlib/util/dlist.d",
          "dlib/util/string_hash.d",
          "dlib/util/version_helper.d",
          "dlib/bio/exceptions.d"].join(" ")

desc "Compile and run D unit tests"
task :unittests do
  sh "dmd -g -unittest dlib/unittests.d #{DFILES} -Idlib -J. -ofunittests"
  sh "./unittests"
end
CLEAN.include("unittests")
CLEAN.include("unittests.o")

desc "Compile GFF3 utilities"
task :utilities => :bin do
  sh "dmd -O -release dlib/bin/gff3_benchmark.d #{DFILES} -Idlib -J. -ofbin/gff3-benchmark"
  sh "dmd -O -release dlib/bin/gff3_validate.d #{DFILES} -Idlib -J. -ofbin/gff3-validate"
  sh "dmd -O -release dlib/bin/gff3_count_features.d #{DFILES} -Idlib -J. -ofbin/gff3-count-features"
  sh "dmd -O -release dlib/bin/gff3_ffetch.d #{DFILES} -Idlib -J. -ofbin/gff3-ffetch"
  rm_f Dir.glob("bin/*.o")
end

task :default => :unittests

