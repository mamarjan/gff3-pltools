# encoding: utf-8

require 'rake/clean'

ENV["PATH"] = File.join(File.dirname(__FILE__), "bin") + ":" + ENV["PATH"]
PREFIX=ENV["PREFIX"]

DMD_RELEASE_FLAGS = "-O -release -Idlib -J."
DMD_DEBUG_FLAGS = "-g -Idlib -J."

GDC_RELEASE_FLAGS = "-O3 -finline -funroll-all-loops -finline-limit=8192 -frelease -lpthread -fno-assert -J."
GDC_DEBUG_FLAGS = "-O0 -lpthread -fdebug -fversion=serial -J."

directory "bin"
CLEAN.include("bin/")

DFILES = (Dir.glob("dlib/bio/**/*.d") +
          Dir.glob("dlib/util/**/*.d")).join(" ")

desc "Shorthand for test:dmd"
task :test => ["test:dmd"]

namespace :test do
  desc "Compile and run unit tests with DMD compiler"
  task :dmd do
    sh "dmd #{DMD_DEBUG_FLAGS} #{DFILES} -unittest -ofunittests dlib/unittests.d"
    sh "./unittests"
  end

  desc "Compile and run unit tests with GDC compiler"
  task :gdc do
    sh "gdc #{GDC_DEBUG_FLAGS} #{DFILES} -funittest -o unittests dlib/unittests.d"
    sh "./unittests"
  end
end
CLEAN.include("unittests")
CLEAN.include("unittests.o")

def build_utility compiler, main_file_path, output_path, flags
  if compiler == :dmd
    sh "dmd #{flags} #{DFILES} -of#{output_path} #{main_file_path}"
  elsif compiler == :gdc
    sh "gdc #{flags} #{DFILES} -o #{output_path} #{main_file_path}"
  end
end

def create_symlinks
  create_symlink "gff3-benchmark", "bin/gtf-benchmark"
  create_symlink "gff3-filter", "bin/gtf-filter"
  create_symlink "gff3-select", "bin/gtf-select"
  create_symlink "gff3-to-json", "bin/gtf-to-json"
end

def create_symlink target, link_path
  sh "ln -s #{target} #{link_path}"
end

def build_all_utilities compiler, flags
  all_utilities = [ "gff3-select", "gff3-ffetch", "gff3-benchmark",
    "gff3-validate", "gff3-count-features", "gff3-filter", "gff3-to-gtf",
    "gtf-to-gff3", "gff3-to-json", "gff3-sort" ]
  all_utilities.each do |utility|
    build_utility compiler, bin_main_path(utility), bin_output_path(utility), flags
  end
  rm_f Dir.glob("bin/*.o")
  create_symlinks
end

def bin_main_path util_name
  "dlib/bin/" + hyphens_to_underscores(util_name) + ".d"
end

def bin_output_path util_name
  "bin/" + util_name
end

def hyphens_to_underscores text
  text.gsub("-", "_")
end

namespace :utilities do
  namespace :release do
    desc "Compile GFF3 utilities with DMD with release flags"
    task :dmd => :bin do
      build_all_utilities :dmd, DMD_RELEASE_FLAGS
    end

    desc "Compile GFF3 utilities with GDC with release flags"
    task :gdc => :bin do
      build_all_utilities :gdc, GDC_RELEASE_FLAGS
    end
  end

  desc "Shorthand for utilities:release:dmd"
  task :dmd => ["utilities:release:dmd"]

  desc "Shorthand for utilities:release:gdc"
  task :gdc => ["utilities:release:gdc"]

  namespace :debug do
    desc "Compile GFF3 utilities with DMD with debug flags"
    task :dmd => :bin do
      build_all_utilities :dmd, DMD_DEBUG_FLAGS
    end

    desc "Compile GFF3 utilities with GDC with debug flags"
    task :gdc => :bin do
      build_all_utilities :gdc, GDC_DEBUG_FLAGS
    end
  end

  desc "Shorthand for utilities:debug:dmd"
  task :debug => ["utilities:debug:dmd"]
end

desc "Shorthand for test and utilities:release:dmd"
task :default => [:test, :utilities]

desc "Shorthand for utilities:release:dmd"
task :utilities => ["utilities:release:dmd"]

desc "Shorthand for utilities:debug:dmd"
task :debug => ["utilities:debug:dmd"]

desc "Shorthand for utilities:release:dmd"
task :release => ["utilities:release:dmd"]

desc "Shorthand for test and utilities:release:dmd"
task :dmd => ["test", "utilities:release:dmd"]

desc "Shorthand for test and utilities:release:gdc"
task :gdc => ["test", "utilities:release:gdc"]

namespace :debug do
  desc "Shorthand for utilities:debug:dmd"
  task :dmd => ["utilities:debug:dmd"]

  desc "Shorthand for utilities:debug:gdc"
  task :gdc => ["utilities:debug:gdc"]
end

namespace :release do
  desc "Shorthand for utilities:release:dmd"
  task :dmd => ["utilities:release:dmd"]

  desc "Shorthand for utilities:release:gdc"
  task :gdc => ["utilities:release:gdc"]
end

#### Man pages
# (borrowed from csw/bioruby-maf,
#  who borrowed it from matthewtodd/shoe)
ronn_avail = begin
               require 'ronn'
               true
             rescue LoadError
               false
             end

if ronn_avail
  RONN_FILES = Rake::FileList["man/*.?.ronn"]

  desc "Generate man pages"
  task :man do
    file_spec = RONN_FILES.join(' ')
    sh "ronn --roff --html --style toc --markdown --date #{Time.now.strftime('%Y-%m-%d')} --manual='gff3-pltools Manual' --organization='OpenBio' #{file_spec}"
  end

end # if ronn_avail

desc "Install binaries. Use PREFIX env variable to change the target path."
task :install do
  mkdir_p "#{PREFIX || "/usr/local"}/bin"
  sh "cp -d bin/* #{PREFIX || "/usr/local"}/bin"
  mkdir_p "#{PREFIX || "/usr/local"}/share/man/man1"
  sh "cp man/*.1 #{PREFIX || "/usr/local"}/share/man/man1"
  mkdir_p "#{PREFIX || "/usr/local"}/share/doc/gff3-pltools"
  sh "cp LICENSE.txt README.md #{PREFIX || "/usr/local"}/share/doc/gff3-pltools"
end

def create_dir path
end

directory "dev_bin"
CLEAN.include("dev_bin/")

def build_dev_tools compiler, flags
  all_tools = [
    { :main_file => "dlib/dev_tools/combine_fasta.d", :output_path => "dev_bin/combine-fasta" },
    { :main_file => "dlib/dev_tools/fasta_rewrite.d", :output_path => "dev_bin/fasta-rewrite" },
    { :main_file => "dlib/dev_tools/compare_fasta.d", :output_path => "dev_bin/compare-fasta" },
    { :main_file => "dlib/dev_tools/fasta_stats.d", :output_path => "dev_bin/fasta-stats" },
    { :main_file => "dlib/dev_tools/make_fasta_comparable.d", :output_path => "dev_bin/make-fasta-comparable" } ]
  all_tools.each do |tool|
    build_utility compiler, tool[:main_file], tool[:output_path], flags
  end
  rm_f Dir.glob("dev_bin/*.o")
end

task :dev_tools => ["dev_tools:dmd"]

namespace :dev_tools do
  task :dmd => :dev_bin do
    build_dev_tools :dmd, DMD_DEBUG_FLAGS
  end

  task :gdc do
    build_dev_tools :gdc, GDC_DEBUG_FLAGS
  end
end


