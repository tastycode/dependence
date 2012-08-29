# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "dependence/version"

Gem::Specification.new do |s|
  s.name        = "dependence"
  s.version     = Dependence::VERSION
  s.authors     = ["Thomas Devol"]
  s.email       = ["thomas.devol@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Dependency injection framework}
  s.description = %q{Explicitly declares class dependencies and allows replacement for testing}

  s.rubyforge_project = "dependence"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  %w(pry pry-nav minitest turn mocha guard-minitest).each do |lib|
    s.add_development_dependency lib
  end
end
