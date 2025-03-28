# frozen_string_literal: true

require "rbconfig"

module Chromedriver
  module Binary
    module Platform
      def platform
        case RbConfig::CONFIG["host_os"].downcase
        when /linux/ then "linux"
        when /darwin/ then "mac"
        when /mswin|msys|mingw|cygwin|bccwin|wince|emc/ then "win"
        else
          raise NotImplementedError, "Your OS is not supported by this gem."
        end
      end

      def platform_id
        case platform
        when /mac/
          "mac64"
        when /linux/
          if File.exist?("/proc/version") && File.read("/proc/version").include?("Microsoft")
            "win32"
          else
            "linux64"
          end
        when /win/
          "win32"
        end
      end

      def file_name
        platform_id == "win32" ? "chromedriver.exe" : "chromedriver"
      end

      def driver_filename
        platform = platform_id
        case platform
        when "win32"
          "win32"
        when "linux"
          "linux64"
        when "mac64"
          # If you're on an Apple Silicon Mac, check Ruby platform for arm details.
          if RUBY_PLATFORM.include?("arm64-darwin")
            "mac-arm64"
          else
            "mac-x64"
          end
        else
          raise "Failed to determine driver filename to download for your OS."
        end
      end
    end
  end
end
