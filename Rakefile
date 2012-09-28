# encoding: utf-8

require 'rake/clean'

ENV["PATH"] = File.join(File.dirname(__FILE__), "bin") + ":" + ENV["PATH"]
PREFIX=ENV["PREFIX"]

DMD_RELEASE_FLAGS = "-O -release -Idlib -J."
DMD_DEBUG_FLAGS = "-g -Idlib -J."

GDC_RELEASE_FLAGS = "-O3 -finline -funroll-all-loops -finline-limit=8192 -frelease -lpthread -fno-assert -J."
GDC_DEBUG_FLAGS = "-O0 -lpthread -fdebug -fversion=serial -J."

DFILES = (Dir.glob("dlib/bio/**/*.d") +
          Dir.glob("dlib/util/**/*.d")).join(" ")

ALL_UTILITIES = [ "gff3-select", "gff3-ffetch", "gff3-benchmark",
    "gff3-validate", "gff3-count-features", "gff3-filter", "gff3-to-gtf",
    "gtf-to-gff3", "gff3-to-json", "gff3-sort" ]

ALL_SYMLINKS = [
  # "----target----", "----link_name---"
  [ "gff3-benchmark", "gtf-benchmark"],
  [ "gff3-filter", "gtf-filter"],
  [ "gff3-select", "gtf-select"],
  [ "gff3-to-json", "gtf-to-json"] ]

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

def build_lib compiler, flags
  if compiler == :dmd
    sh "dmd #{flags} #{DFILES} -lib -oflibgff3pl.a"
  elsif compiler == :gdc
  end
end

def build_all_utilities compiler, flags
  ALL_UTILITIES.each do |utility|
    build_utility compiler, bin_main_path(utility), bin_output_path(utility), flags
  end
  rm_f Dir.glob("bin/*.o")
  create_symlinks
end

def bin_main_path util_name
  "dlib/bin/" + hyphens_to_underscores(util_name) + ".d"
end

def hyphens_to_underscores text
  text.gsub("-", "_")
end

def bin_output_path util_name
  "bin/" + util_name
end

def build_utility compiler, main_file_path, output_path, flags
  if compiler == :dmd
    sh "dmd #{flags} libgff3pl.a -of#{output_path} #{main_file_path}"
  elsif compiler == :gdc
    sh "gdc #{flags} #{DFILES} -o #{output_path} #{main_file_path}"
  end
end

def create_symlinks
  ALL_SYMLINKS.each { |symlink| create_symlink symlink[0], "bin/" + symlink[1] }
end

def create_symlink target, link_path
  sh "ln -s #{target} #{link_path}"
end

CLEAN.include("libgff3pl.a")

namespace :libs do
  namespace :release do
    desc "Build library with DMD with release flags"
    task :dmd do
      build_lib :dmd, DMD_RELEASE_FLAGS
    end
  end

  desc "Shorthand for libs:release:dmd"
  task :release => "libs:release:dmd"

  namespace :debug do
    desc "Build library with DMD with debug flags"
    task :dmd do
      build_lib :dmd, DMD_DEBUG_FLAGS
    end
  end
end

desc "Shorthand for libs:release:dmd"
task :libs => "libs:release:dmd"

directory "bin"
CLEAN.include("bin/")

namespace :utilities do

  namespace :release do
    desc "Compile GFF3 utilities with DMD with release flags"
    task :dmd => [:bin, "libs:release:dmd"] do
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
    task :dmd => [:bin, "libs:debug:dmd"] do
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

# Per-utility tasks for building:
ALL_UTILITIES.each do |utility|
  desc "Build the #{utility} utility with dmd"
  task utility => [:bin, "libs:debug:dmd"] do |t|
    build_utility :dmd, bin_main_path(t.name), bin_output_path(t.name), DMD_DEBUG_FLAGS
  end

  namespace :gdc do
    desc "Build the #{utility} utility with gdc"
    task utility => :bin do |t|
      build_utility :gdc, bin_main_path(t.name), bin_output_path(t.name), GDC_DEBUG_FLAGS
    end
  end
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

ALL_TOOLS = [
    "combine-fasta",
    "fasta-rewrite",
    "compare-fasta",
    "fasta-stats",
    "make-fasta-comparable" ]

directory "dev_bin"
CLEAN.include("dev_bin/")

def build_dev_tools compiler, flags
  ALL_TOOLS.each do |tool|
    build_utility compiler, tool_main_file(tool), tool_output_path(tool), flags
  end
  rm_f Dir.glob("dev_bin/*.o")
end

def tool_main_file tool_name
  "dlib/dev_tools/" + hyphens_to_underscores(tool_name) + ".d"
end

def tool_output_path tool_name
  "dev_bin/" + tool_name
end

task :dev_tools => ["dev_tools:dmd"]

namespace :dev_tools do
  task :dmd => [:dev_bin, "libs:debug:dmd"] do
    build_dev_tools :dmd, DMD_DEBUG_FLAGS
  end

  task :gdc => :dev_bin do
    build_dev_tools :gdc, GDC_DEBUG_FLAGS
  end
end


