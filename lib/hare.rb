module Hare
  ROOT = File.expand_path(File.dirname(__FILE__))

  autoload :Runner,             "#{ROOT}/hare/runner"
end

require "#{Hare::ROOT}/hare/version"
