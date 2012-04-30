# encoding: utf-8

task :build do
  mkdir "build"
  sh "gcc -c -m32 -g dlib/lib_init_c.c -o build/lib_init_c.o -fPIC"
  sh "dmd -c -m32 -g dlib/lib_init_d.d -ofbuild/lib_init_d.o -fPIC"
  sh "gcc -g -m32 build/lib_init_d.o build/lib_init_c.o -o bio-hpc-dlib.so -shared -lphobos2 -lrt -lpthread -fPIC"
end

task :clean do
  sh "rm -R build"
  sh "rm bio-hpc-dlib.so"
end

task :rspec do
  sh "LD_LIBRARY_PATH=\"./\" rspec spec"
end

task :cucumber do
  sh "LD_LIBRARY_PATH=\"./\" cucumber"
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
  gem.name = "bio-hpc-gff3"
  gem.homepage = "http://github.com/mamarjan/bioruby-hpc-gff3"
  gem.license = "MIT"
  gem.summary = %Q{Fast parallized GFF3 parser}
  gem.description = %Q{TODO: longer description of your gem}
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

