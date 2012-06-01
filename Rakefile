# encoding: utf-8

# To be able to load the D library in our tests,
# we need to add it's path to this env var:

require 'rake/clean'

ENV["LD_LIBRARY_PATH"] = File.dirname(__FILE__)

rule ".o" => [".d"] do |t|
  sh "dmd -c -m32 -g #{t.source} -of#{t.name} -fPIC"
end

directory "builddir"
CLEAN.include("builddir")

task :compiledebug => ["builddir"] do
  sh "dmd -c -m32 -g dlib/lib_init.d -ofbuilddir/lib_init.o -fPIC"
  sh "dmd -c -m32 -g dlib/bio/gff3.d -ofbuilddir/gff3.o -fPIC"
  sh "dmd -g -m32 builddir/*.o -ofbio-hpc-dlib.so -shared -fPIC"
  sh "mv bio-hpc-dlib.so lib/"
end

task :compile => ["builddir"] do
  sh "dmd -c -m32 -g dlib/lib_init.d -ofbuilddir/lib_init.o -fPIC"
  sh "dmd -c -m32 -g dlib/bio/gff3.d -ofbuilddir/gff3.o -fPIC"
  sh "dmd -g -m32 builddir/*.o -ofbio-hpc-dlib.so -shared -fPIC"
  sh "mv bio-hpc-dlib.so lib/"
end

CLEAN.include("lib/*.so")

DFILES = ["dlib/bio/gff3.d",
          "dlib/bio/fasta.d",
          "dlib/bio/util.d",
          "dlib/bio/exceptions.d"].join(" ")

task :unittests => ["builddir"] do
  sh "dmd -g -m32 -unittest dlib/unittests.d #{DFILES} -Idlib -ofunittests"
  sh "./unittests"
end

CLEAN.include("unittests")
CLEAN.include("unittests.o")

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
  gem.name = "bio-hpc-gff3"
  gem.homepage = "http://github.com/mamarjan/bioruby-hpc-gff3"
  gem.license = "MIT"
  gem.summary = %Q{Fast parallized GFF3 parser}
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

