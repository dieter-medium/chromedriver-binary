# frozen_string_literal: true

require_relative "binary/version"
require_relative "binary/chromedriver_downloader"
require_relative "binary/railtie" if defined?(Rails)
require "logger"

module Chromedriver
  module Binary
    class Error < StandardError; end

    class VersionError < Error; end

    class BrowserNotFound < Error; end

    DEFAULT_INSTALL_DIR = File.expand_path("~/.webdrivers")

    @logger = Logger.new($stdout)
    @logger.level = Logger::DEBUG

    class << self
      attr_accessor :logger, :proxy_addr, :proxy_port, :proxy_user, :proxy_pass
      attr_writer :install_dir

      #
      # Returns the install (download) directory path for the drivers.
      #
      # @return [String]
      def install_dir
        @install_dir ||= ENV["CHROMEDRIVER_INSTALL_DIR"] || DEFAULT_INSTALL_DIR
      end

      #
      # Provides a convenient way to configure the gem.
      #
      # @example Configure proxy and cache_time
      #   Chromedriver::Binary.configure do |config|
      #     config.proxy_addr = 'myproxy_address.com'
      #     config.proxy_port = '8080'
      #     config.proxy_user = 'username'
      #     config.proxy_pass = 'password'
      #   end
      #
      def configure
        yield self if block_given?
      end
    end
  end
end
