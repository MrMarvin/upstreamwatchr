# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'upstreamwatchr/version'

Gem::Specification.new do |spec|
  spec.name          = "upstreamwatchr"
  spec.version       = UpstreamWatchr::VERSION
  spec.authors       = ["Marvin Frick"]
  spec.email         = ["marvin.frick@sinnerschrader.com"]
  spec.summary       = %q{watches "upstream" repositories for changes}
  spec.description   = %q{upstreamwatchr makes it easy to keep track of changes in the upstream repositories of your forks by comparing two git remotes and creating an issue on your fork if it is out of sync.}
  spec.homepage      = "https://github.com/MrMarvin/upstreamwatchr"
  spec.license       = "BSD"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.add_development_dependency 'pry', '0.10.1'
  spec.add_runtime_dependency 'rugged', '0.22.2'
  spec.add_runtime_dependency 'gitlab', '3.4.0'
  spec.add_runtime_dependency 'rainbow', '2.0.0'
end
