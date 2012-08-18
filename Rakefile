# encoding: utf-8

require 'rake/clean'

ENV["PATH"] = File.join(File.dirname(__FILE__), "bin") + ":" + ENV["PATH"]

dc = ENV["DC"]
dc = "dmd" if dc.nil?

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
          "dlib/bio/gff3/data_formats.d",
          "dlib/bio/gff3/selection.d",
          "dlib/bio/gff3/conv/json.d",
          "dlib/bio/gff3/conv/table.d",
          "dlib/bio/gff3/conv/gff3.d",
          "dlib/bio/gff3/conv/gtf.d",
          "dlib/bio/gff3/conv/fasta.d",
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
          "dlib/util/is_float.d",
          "dlib/util/array_includes.d",
          "dlib/util/equals.d",
          "dlib/bio/exceptions.d"].join(" ")

desc "Compile and run D unit tests"
task :unittests do
  if dc == "dmd"
    sh "dmd -g -unittest dlib/unittests.d #{DFILES} -Idlib -J. -ofunittests"
  elsif dc == "gdc"
    sh "gdc #{DFILES} -O0 -funittest -o unittests -lpthread -fdebug -fversion=serial -J. dlib/unittests.d"
  end
  sh "./unittests"
end
CLEAN.include("unittests")
CLEAN.include("unittests.o")

desc "Compile GFF3 utilities"
task :utilities => :bin do
  if dc == "dmd"
    sh "dmd -O -release dlib/bin/gff3_ffetch.d #{DFILES} -Idlib -J. -ofbin/gff3-ffetch"
    sh "dmd -O -release dlib/bin/gff3_benchmark.d #{DFILES} -Idlib -J. -ofbin/gff3-benchmark"
    sh "dmd -O -release dlib/bin/gff3_validate.d #{DFILES} -Idlib -J. -ofbin/gff3-validate"
    sh "dmd -O -release dlib/bin/gff3_count_features.d #{DFILES} -Idlib -J. -ofbin/gff3-count-features"
    sh "dmd -O -release dlib/bin/gff3_filter.d #{DFILES} -Idlib -J. -ofbin/gff3-filter"
    sh "dmd -O -release dlib/bin/gff3_to_gtf.d #{DFILES} -Idlib -J. -ofbin/gff3-to-gtf"
    sh "dmd -O -release dlib/bin/gtf_to_gff3.d #{DFILES} -Idlib -J. -ofbin/gtf-to-gff3"
    sh "dmd -O -release dlib/bin/gff3_to_json.d #{DFILES} -Idlib -J. -ofbin/gff3-to-json"
    sh "dmd -O -release dlib/bin/gff3_sort.d #{DFILES} -Idlib -J. -ofbin/gff3-sort"
  elsif dc == "gdc"
    sh "gdc -O3 -finline -funroll-all-loops -finline-limit=8192 -frelease dlib/bin/gff3_ffetch.d #{DFILES} -lpthread -fno-assert -J. -o bin/gff3-ffetch"
    sh "gdc -O3 -finline -funroll-all-loops -finline-limit=8192 -frelease dlib/bin/gff3_benchmark.d #{DFILES} -lpthread -fno-assert -J. -o bin/gff3-benchmark"
    sh "gdc -O3 -finline -funroll-all-loops -finline-limit=8192 -frelease dlib/bin/gff3_validate.d #{DFILES} -lpthread -fno-assert -J. -o bin/gff3-validate"
    sh "gdc -O3 -finline -funroll-all-loops -finline-limit=8192 -frelease dlib/bin/gff3_count_features.d #{DFILES} -lpthread -fno-assert -J. -o bin/gff3-count-features"
    sh "gdc -O3 -finline -funroll-all-loops -finline-limit=8192 -frelease dlib/bin/gff3_filter.d #{DFILES} -lpthread -fno-assert -J. -o bin/gff3-filter"
    sh "gdc -O3 -finline -funroll-all-loops -finline-limit=8192 -frelease dlib/bin/gff3_to_gtf.d #{DFILES} -lpthread -fno-assert -J. -o bin/gff3-to-gtf"
    sh "gdc -O3 -finline -funroll-all-loops -finline-limit=8192 -frelease dlib/bin/gtf_to_gff3.d #{DFILES} -lpthread -fno-assert -J. -o bin/gtf-to-gff3"
    sh "gdc -O3 -finline -funroll-all-loops -finline-limit=8192 -frelease dlib/bin/gff3_to_json.d #{DFILES} -lpthread -fno-assert -J. -o bin/gff3-to-json"
    sh "gdc -O3 -finline -funroll-all-loops -finline-limit=8192 -frelease dlib/bin/gff3_sort.d #{DFILES} -lpthread -fno-assert -J. -o bin/gff3-sort"
  end
  rm_f Dir.glob("bin/*.o")
  sh "ln -s gff3-benchmark bin/gtf-benchmark"
  sh "ln -s gff3-filter bin/gtf-filter"
  sh "ln -s gff3-to-json bin/gtf-to-json"
end

directory "dev_bin"
CLEAN.include("dev_bin/")

desc "Compile development utilities"
task :dev_tools => :dev_bin do
  if dc == "dmd"
    sh "dmd -g dlib/dev_tools/combine_fasta.d #{DFILES} -Idlib -J. -ofdev_bin/combine-fasta"
    sh "dmd -g dlib/dev_tools/fasta_rewrite.d #{DFILES} -Idlib -J. -ofdev_bin/fasta-rewrite"
    sh "dmd -g dlib/dev_tools/compare_fasta.d #{DFILES} -Idlib -J. -ofdev_bin/compare-fasta"
    sh "dmd -g dlib/dev_tools/fasta_stats.d #{DFILES} -Idlib -J. -ofdev_bin/fasta-stats"
    sh "dmd -g dlib/dev_tools/make_fasta_comparable.d #{DFILES} -Idlib -J. -ofdev_bin/make-fasta-comparable"
  elsif dc == "gdc"
    sh "gdc -fdebug dlib/dev_tools/combine_fasta.d #{DFILES} -lpthread -J. -o dev_bin/combine-fasta"
    sh "gdc -fdebug dlib/dev_tools/compare_fasta.d #{DFILES} -lpthread -J. -o dev_bin/compare-fasta"
    sh "gdc -fdebug dlib/dev_tools/fasta_stats.d #{DFILES} -lpthread -J. -o dev_bin/fasta-stats"
    sh "gdc -fdebug dlib/dev_tools/make_fasta_comparable.d #{DFILES} -lpthread -J. -o dev_bin/make-fasta-comparable"
  end
  rm_f Dir.glob("dev_bin/*.o")
end

task :default => :unittests

