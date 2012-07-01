# encoding: utf-8

require 'rake/clean'

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
  sh "dmd -g -m32 -unittest dlib/unittests.d #{DFILES} -Idlib -ofunittests"
  sh "./unittests"
end
CLEAN.include("unittests")
CLEAN.include("unittests.o")

desc "Compile utilities"
task :utilities do
  sh "dmd -O -release -m32 dlib/bin/benchmark_gff3.d #{DFILES} -Idlib -ofbenchmark-gff3"
  sh "dmd -O -release -m32 dlib/bin/validate_gff3.d #{DFILES} -Idlib -ofvalidate-gff3"
  sh "dmd -O -release -m32 dlib/bin/count_features.d #{DFILES} -Idlib -ofcount-features"
  sh "dmd -O -release -m32 dlib/bin/gff3_ffetch.d #{DFILES} -Idlib -ofgff3-ffetch"
  rm_f Dir.glob("*.o")
end
CLEAN.include("*.o")
CLEAN.include("benchmark-gff3")
CLEAN.include("validate-gff3")
CLEAN.include("count-features")
CLEAN.include("gff3-ffetch")

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
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:features)

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new

