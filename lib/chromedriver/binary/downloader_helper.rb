# frozen_string_literal: true

require "net/http"
require "uri"
require "zip"
require "fileutils"

require_relative "download_progress"

module Chromedriver
  module Binary
    module DownloaderHelper
      def download_file(url, destination)
        uri = URI.parse(url)
        logger = Chromedriver::Binary.logger
        http = create_http(uri)

        logger.debug("Saving to: #{destination}")

        exec_get_request(http, uri) do |response|
          handle_unsuccessful_response(response)
          write_response_to_file(response, destination, logger)
        end
      rescue StandardError => e
        logger.debug("Error: #{e.message}")
        raise "Error downloading file: #{e.message}"
      end

      def exec_get_request(http, uri, &block)
        request = Net::HTTP::Get.new(uri)
        Chromedriver::Binary.logger.debug("Sending HTTP GET request...")

        http.request(request, &block)
      end

      def extract_zip(zip_file, destination)
        Zip::File.open(zip_file) do |zip|
          zip.each do |entry|
            # Extract all files as top-level (ignoring any folder structure)
            destination_file = File.join(destination, File.basename(entry.name))
            entry.extract(destination_file) { true }
          end
        end
      rescue StandardError => e
        raise "Error extracting ZIP file: #{e.message}"
      end

      private

      def handle_unsuccessful_response(response)
        return if response.is_a?(Net::HTTPSuccess)

        raise "Download failed: #{response.code} #{response.message}"
      end

      def write_response_to_file(response, destination, logger)
        progress = DownloadProgress.new(logger: logger)

        File.open(destination, "wb") do |file|
          response.read_body do |chunk|
            file.write(chunk)
            progress.track(chunk.bytesize)
          end
        end

        progress.finish
      end

      def create_http(uri)
        logger = Chromedriver::Binary.logger

        logger.debug("Starting download from: #{uri}")

        Net::HTTP.new(
          uri.host,
          uri.port,
          Chromedriver::Binary.proxy_addr,
          Chromedriver::Binary.proxy_port,
          Chromedriver::Binary.proxy_user,
          Chromedriver::Binary.proxy_pass
        ).tap do |http|
          http.use_ssl = uri.scheme == "https"

          log_proxy_info(http, logger)
        end
      end

      def log_proxy_info(http, logger)
        if http.proxy?
          source = http.proxy_from_env? ? "environment" : "Chromedriver::Binary"
          logger.debug("Using proxy from #{source}:")
          logger.debug("Proxy address: #{http.proxy_address}")
          logger.debug("Proxy port: #{http.proxy_port}")

          return
        end

        logger.debug("No proxy is being used.")
      end
    end
  end
end
