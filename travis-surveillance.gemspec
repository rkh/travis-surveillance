# -*- encoding: utf-8 -*-
require File.expand_path('../lib/travis/surveillance/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Dylan Egan"]
  gem.email         = ["dylanegan@gmail.com"]
  gem.description   = %q{Veille sur un projet.}
  gem.summary       = %q{Veille sur un projet.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "travis-surveillance"
  gem.require_paths = ["lib"]
  gem.version       = Travis::Surveillance::VERSION

  gem.add_dependency "clamp", "~> 0.4"
  gem.add_dependency "json", "~> 1.7" if RUBY_PLATFORM == "java"
  gem.add_dependency "pusher-client-merman", "~> 0.2"
  gem.add_dependency "rake", "~> 0.9.0"
  gem.add_dependency "scrolls", "~> 0.2.1"
  gem.add_dependency "simplecov", "~> 0.6"
  gem.add_dependency "terminal-table", "~> 1.4"
end
