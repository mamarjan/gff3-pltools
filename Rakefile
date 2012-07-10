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

desc "Compile D utilities for standalone usage"
task :utilities => :bin do
  sh "dmd -O -release dlib/bin/gff3_benchmark.d #{DFILES} -Idlib -J. -ofbin/gff3-benchmark"
  sh "dmd -O -release dlib/bin/gff3_validate.d #{DFILES} -Idlib -J. -ofbin/gff3-validate"
  sh "dmd -O -release dlib/bin/gff3_count_features.d #{DFILES} -Idlib -J. -ofbin/gff3-count-features"
  sh "dmd -O -release dlib/bin/gff3_ffetch.d #{DFILES} -Idlib -J. -ofbin/gff3-ffetch"
  rm_f Dir.glob("bin/*.o")
end

desc "Compile D utilities and generate wrappers for inclusion in gems"
task :utilities_and_wrappers => :bin do
  sh "dmd -O -release dlib/bin/gff3_benchmark.d #{DFILES} -Idlib -J. -ofbin/_gff3-benchmark"
  cp "scripts/wrapper-script.rb", "bin/gff3-benchmark"
  sh "dmd -O -release dlib/bin/gff3_validate.d #{DFILES} -Idlib -J. -ofbin/_gff3-validate"
  cp "scripts/wrapper-script.rb", "bin/gff3-validate"
  sh "dmd -O -release dlib/bin/gff3_count_features.d #{DFILES} -Idlib -J. -ofbin/_gff3-count-features"
  cp "scripts/wrapper-script.rb", "bin/gff3-count-features"
  sh "dmd -O -release dlib/bin/gff3_ffetch.d #{DFILES} -Idlib -J. -ofbin/_gff3-ffetch"
  cp "scripts/wrapper-script.rb", "bin/gff3-ffetch"
  rm_f Dir.glob("bin/*.o")
end

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
  gem.homepage = "http://mamarjan.github.com/gff3-pltools/"
  gem.license = "MIT"
  gem.summary = %Q{Ruby wrapper for the gff3-pltools.}
  gem.description = %Q{Ruby wrapper for the gff3-pltools.}
  gem.email = "marian.povolny@gmail.com"
  gem.authors = ["Marjan Povolni"]
#  gem.executables = ["gff3-ffetch", "gff3-benchmark", "gff3-validate", "gff3-count-features"]
  gem.files.clear
#  gem.files.include 'bin/_*'
  gem.files.include 'lib/**/**.rb'
  gem.files.include 'VERSION'
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

task :build => :utilities_and_wrappers

require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:features)

task :default => :unittests

require 'yard'
YARD::Rake::YardocTask.new
CLEAN.include("doc")
CLEAN.include(".yardoc")

