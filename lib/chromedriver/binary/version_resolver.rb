# frozen_string_literal: true

require "open-uri"
require "json"
require_relative "finder"
require_relative "system_helper"
require_relative "downloader_helper"

module Chromedriver
  module Binary
    module VersionResolver
      include SystemHelper
      include DownloaderHelper

      BASE_URL = "https://chromedriver.storage.googleapis.com"
      CHROME_FOR_TESTING_BASE_URL = "https://googlechromelabs.github.io/chrome-for-testing/"

      def normalize_version(version)
        Gem::Version.new(version.to_s)
      end

      def browser_build_version
        normalize_version(browser_version.segments[0..2].join("."))
      end

      def latest_patch_version_for_build
        data = fetch_data("latest-patch-versions-per-build.json")
        patch_version = data.dig(:builds, browser_build_version.to_s.to_sym, :version)
        raise "No patch version found for build #{browser_build_version}" unless patch_version

        patch_version
      rescue StandardError => e
        raise "Error fetching latest patch version: #{e.message}"
      end

      # @param [_ToS] driver_version
      def direct_url_from_api(driver_version, driver_filename)
        data = fetch_data("known-good-versions-with-downloads.json")
        version_data = data[:versions].find { |e| e[:version] == driver_version.to_s }
        platform = version_data.dig(:downloads, :chromedriver).find { |e| e[:platform] == driver_filename }
        platform[:url]
      end

      #
      # Returns current chromedriver version.
      #
      # @return [Gem::Version]
      def current_installed_version
        Chromedriver::Binary.logger.debug "Checking current version"
        return nil unless exists?(driver_path)

        version = query_binary_version
        return nil if version.nil?

        # Matches 2.46, 2.46.628411 and 73.0.3683.75
        normalize_version version[/\d+\.\d+(\.\d+)?(\.\d+)?/]
      end

      def driver_path
        raise "driver_path not defined"
      end

      def query_binary_version
        version = call(driver_path, "--version")
        Chromedriver::Binary.logger.debug "Current version of #{driver_path} is #{version}"
        version
      rescue Errno::ENOENT
        Chromedriver::Binary.logger.debug "No Such File or Directory: #{driver_path}"
        nil
      end

      private

      def fetch_data(json_file)
        uri = URI.join(CHROME_FOR_TESTING_BASE_URL, json_file)
        http = create_http(uri)
        response = nil

        exec_get_request(http, uri) do |resp|
          response = resp.body
        end

        JSON.parse(response, symbolize_names: true)
      end

      def browser_version
        normalize_version Chromedriver::Binary::Finder.new.version
      end
    end
  end
end
