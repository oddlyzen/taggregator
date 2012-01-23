# encoding: utf-8

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
  gem.name = "taggregator"
  gem.homepage = "http://github.com/oddlyzen/taggregator"
  gem.license = "MIT"
  gem.summary = %Q{Bad-ass tagging intelligence for your document tagging in MongoMapper.}
  gem.description = %Q{Adds tagging with context and aggregation of tags for MongoMapper. Adds weight and distribution convenience methods to models in which it is included. Uses MongoDB's increment/decrement ($inc/$dec) to keep real-time counts of individual tags in context with optional type. Based on 'Mongoid Taggable With Context' (https://github.com/aq1018/mongoid_taggable_with_context).}
  gem.email = "mark.coates@gmail.com"
  gem.authors = ["BitPimpin' LLC"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
  test.rcov_opts << '--exclude "gems/*"'
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "taggregator #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
