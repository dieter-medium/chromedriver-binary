# frozen_string_literal: true

require_relative "platform"
require_relative "system_helper"

module Chromedriver
  module Binary
    class Finder
      include Platform
      include SystemHelper

      def version
        version = send("#{platform}_version", location)
        raise VersionError, "Failed to determine Chrome version." if version.nil? || version.empty?

        Chromedriver::Binary.logger.debug "Browser version: #{version}"
        version[/\d+\.\d+\.\d+\.\d+/]
      end

      def location
        if chrome_bin_from_env
          Chromedriver::Binary.logger.debug "CHROMEDRIVER_CHROME_PATH: #{chrome_bin_from_env}"

          return chrome_bin_from_env
        end

        send("#{platform}_location").tap do |chrome_bin|
          raise Chromedriver::Binary::BrowserNotFound, "Failed to determine Chrome binary location." unless chrome_bin
        end
      end

      private

      def chrome_bin_from_env
        ENV["CHROMEDRIVER_CHROME_PATH"]
      end

      def find_in_paths(directories, files)
        directories.each do |dir|
          files.each do |file|
            path = File.join(dir, file)
            return path if file_exists?(path)
          end
        end
        nil
      end

      def file_exists?(path)
        File.exist?(path)
      end

      def win_location
        find_in_paths(%w[LOCALAPPDATA PROGRAMFILES PROGRAMFILES(X86)],
                      ['\\Google\\Chrome\\Application\\chrome.exe', '\\Chromium\\Application\\chrome.exe'])
      end

      def mac_location
        find_in_paths(["", File.expand_path("~")],
                      ["/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
                       "/Applications/Chromium.app/Contents/MacOS/Chromium"])
      end

      def linux_location
        find_in_paths(
          %w[/usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /snap/bin /opt/google/chrome
             /opt/chromium.org/chromium], %w[google-chrome chrome chromium chromium-browser]
        )
      end

      def win_version(location)
        call("powershell.exe \"(Get-ItemProperty '#{location}').VersionInfo.ProductVersion\"")&.strip
      end

      def linux_version(location)
        call(location, "--product-version")&.strip
      end

      def mac_version(location)
        call(location, "--version")&.strip
      end
    end
  end
end
