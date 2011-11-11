# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "hare/version"

Gem::Specification.new do |s|
  s.name        = "hare"
  s.version     = Hare::VERSION
  s.authors     = ["Brian L. Troutwine"]
  s.email       = ["brian@troutwine.us"]
  s.homepage    = ""
  s.summary     = %q{A small command-line tool for publishing to and consuming from AMQP queues.}
  s.description = %q{The one pain-point I have had with AMQP is the lack of a series of command line tools for smoke-testing components or sending my own messages through a queue. Hare can be toggled either to produce messages, or to sit and listen/report for them.}

  s.rubyforge_project = "hare"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_runtime_dependency "bunny", "~> 0.7.8"
end
