#!/usr/bin/env ruby

require "enumerator"
require "rubygems"
require "facets/file/rewrite"

DIR = Dir.getwd

GIT_MODULES = DIR + "/.gitmodules"

def execute(str)
  puts "sh: #{str}"
  result = `cd #{DIR}; #{str}`
  result.strip!
  result
end

module Truncation
  def truncate(length = 7)
    self[0..length-1]
  end
end

File.read(GIT_MODULES).each_slice(3) do |name, path, url|
  lines = [name, path, url]

  path = path.gsub(/path = ([a-z]+.*)/) { $1 }
  url  = url.gsub(/url = (git.*)/) { $1 }

  path.strip!
  url.strip!

  revision = execute "git rev-list HEAD | head -n 1"
  revision.extend Truncation
  revision = revision.truncate(7)

  puts ""
  puts ""
  puts "#{name}"
  puts "Using path: #{path}"
  puts "Using url: #{url}"
  puts "Using revision: #{revision}"

  puts "* Removing submodule #{name}"
  lines.each do |line|
    File.rewrite(GIT_MODULES) { |str| str.gsub(line, "") }
  end
  execute "rm -rf #{path}"

  execute "git commit -a -m 'Remove submodule #{url}@#{revision}'"

  puts "* Replacing with braid"
  execute "braid add #{url} -r #{revision} --verbose"
end