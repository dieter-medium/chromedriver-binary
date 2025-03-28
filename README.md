# chromedriver-binary

A Ruby gem that automatically downloads and installs ChromeDriver binaries that match your installed Chrome browser
version.

> Inspired by [webdrivers](https://github.com/titusfortner/webdrivers/tree/main)

## Features

- Automatically detects Chrome browser version
- Downloads the matching ChromeDriver version
- Works across Windows, macOS, and Linux platforms
- Supports environment variable configuration
- Minimal dependencies

## Installation

Add this to your application's Gemfile:

```ruby
gem 'chromedriver-binary'
```

And then execute:

```shell
$ bundle install
```

Or install it yourself:

```shell
$ gem install chromedriver-binary
```

## Usage

Simply require the gem in your code:

```ruby
require 'chromedriver/binary'

Chromedriver::Binary.configure do |config|
  # default STDOUT logger
  config.logger = logger

  # Proxy default nil
  config.proxy_addr = 'myproxy_address.com'
  config.proxy_port = '8080'
  config.proxy_user = 'username'
  config.proxy_pass = 'password'

  # install dir
  config.install_dir = "/tmp" # default "~/.webdrivers"
end

Chromedriver::Binary::ChromedriverDownloader.update force: true

Chromedriver::Binary::ChromedriverDownloader.driver_path

```

### Rake Tasks

```ruby

require "chromedriver/binary"

load 'chromedriver/Rakefile'
```

The gem will:

1. Detect your installed Chrome version
2. Download the matching ChromeDriver binary if needed
3. Make it available in your PATH

### Configuration

Use environment variables to customize behavior:

- `CHROMEDRIVER_CHROME_PATH`: Specify the Chrome binary location
- `CHROMEDRIVER_BINARY_PATH`: Override where ChromeDriver is installed

## Development

After checking out the repo:

```shell
$ bin/setup               # Install dependencies
$ rake spec               # Run the tests
$ bundle exec rake install # Install the gem locally
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).