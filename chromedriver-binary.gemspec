# frozen_string_literal: true

require_relative "lib/chromedriver/binary/version"

Gem::Specification.new do |spec|
  spec.name = "chromedriver-binary"
  spec.version = Chromedriver::Binary::VERSION
  spec.authors = ["Dieter S."]
  spec.email = ["101627195+dieter-medium@users.noreply.github.com"]

  spec.summary = "Automatically downloads and installs ChromeDriver binaries."
  spec.description = <<~DESCRIPTION
    A Ruby gem that automatically downloads and installs ChromeDriver binaries that match your installed
    Chrome browser version.
  DESCRIPTION
  spec.homepage = "https://github.com/dieter-medium/chromedriver-binary"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rubyzip", "~> 2.4"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "rubocop-rake", "~> 0.7"
  spec.add_development_dependency "rubocop-rspec", "~> 3.5"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "webrick", "~> 1.9"
end
