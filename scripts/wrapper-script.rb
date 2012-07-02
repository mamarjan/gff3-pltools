#!/usr/bin/env ruby

args = ARGV.join(" ")
executable = File.join(File.dirname(__FILE__), "_" + File.basename(__FILE__))
system("#{executable} #{args}")

