# encoding: utf-8

require 'rake/clean'

ENV["PATH"] = File.join(File.dirname(__FILE__), "bin") + ":" + ENV["PATH"]
puts ENV["PATH"]

directory "bin"
CLEAN.include("bin")

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
          "dlib/bio/exceptions.d"].join(" ")

desc "Compile and run D unit tests"
task :unittests do
  sh "dmd -g -unittest dlib/unittests.d #{DFILES} -Idlib -ofunittests"
  sh "./unittests"
end
CLEAN.include("unittests")
CLEAN.include("unittests.o")

desc "Compile utilities"
task :utilities => :bin do
  sh "dmd -O -release dlib/bin/benchmark_gff3.d #{DFILES} -Idlib -ofbin/benchmark-gff3"
  sh "dmd -O -release dlib/bin/validate_gff3.d #{DFILES} -Idlib -ofbin/validate-gff3"
  sh "dmd -O -release dlib/bin/count_features.d #{DFILES} -Idlib -ofbin/count-features"
  sh "dmd -O -release dlib/bin/gff3_ffetch.d #{DFILES} -Idlib -ofbin/gff3-ffetch"
  rm_f Dir.glob("bin/*.o")
end
CLEAN.include("bin/*.o")
CLEAN.include("bin/benchmark-gff3")
CLEAN.include("bin/validate-gff3")
CLEAN.include("bin/count-features")
CLEAN.include("bin/gff3-ffetch")

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "bio-gff3-pltools"
  gem.homepage = "http://github.com/mamarjan/gff3-pltools"
  gem.license = "MIT"
  gem.summary = %Q{Fast parallized GFF3 tools}
  gem.description = %Q{}
  gem.email = "marian.povolny@gmail.com"
  gem.authors = ["Marjan Povolni"]
  gem.executables = ["gff3-ffetch", "benchmark-gff3", "validate-gff3", "count-features"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

task :build => :utilities

require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:features)

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new

