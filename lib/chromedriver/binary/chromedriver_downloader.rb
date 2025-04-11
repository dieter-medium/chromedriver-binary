# frozen_string_literal: true

require "fileutils"
require_relative "version_resolver"
require_relative "platform"
require_relative "downloader_helper"
require_relative "system_helper"

module Chromedriver
  module Binary
    class ChromedriverDownloader
      class << self
        include VersionResolver
        include Platform
        include DownloaderHelper
        include SystemHelper

        # Define where to install ChromeDriver.
        def install_dir
          Chromedriver::Binary.install_dir
        end

        # Returns the absolute path to the driver_path ChromeDriver binary.
        def driver_path
          File.absolute_path File.join(install_dir, file_name)
        end

        # Downloads and extracts the latest ChromeDriver.
        #
        # @return [String] the full path to the downloaded executable.
        # rubocop:disable Metrics/AbcSize
        def update(force: false)
          return driver_path if up_to_date_binary?(force)

          Chromedriver::Binary.logger.warn(<<-EOF_WARNING) if linux_arm64?

             WARNING: The Linux ARM64 version of ChromeDriver is not officially supported by Google.
             Please use the OS version of ChromeDriver instead.
             For instance on Ubuntu, use the `chromium-driver` package and link it to #{driver_path}.
             `apt-get update && apt-get install chromium-driver`
             `mkdir -p #{install_dir} && ln -s /usr/bin/chromedriver #{driver_path}`
          EOF_WARNING

          version = latest_patch_version_for_build
          zip_filename = "chromedriver_#{platform_id}.zip"
          zip_path = File.join(install_dir, zip_filename)
          download_url = direct_url_from_api(version, driver_filename)

          prepare_install_dir
          log_download_start(version, download_url)

          download_file(download_url, zip_path)
          extract_zip(zip_path, install_dir)
          make_executable(driver_path)
          cleanup_zip(zip_path)

          Chromedriver::Binary.logger.debug "ChromeDriver downloaded and extracted to #{install_dir}"

          driver_path
        end

        # rubocop:enable Metrics/AbcSize

        def correct_binary?
          current_installed_version == browser_version || current_installed_version == latest_patch_version_for_build
        rescue ConnectionError, VersionError
          false
        end

        private

        def up_to_date_binary?(force)
          if correct_binary? && !force
            Chromedriver::Binary.logger.debug "A working webdriver version is already on the system"
            true
          else
            false
          end
        end

        def prepare_install_dir
          FileUtils.mkdir_p(install_dir)
        end

        def log_download_start(version, url)
          Chromedriver::Binary.logger.debug(
            "Downloading ChromeDriver version #{version} for #{platform_id} from #{url}..."
          )
        end

        def make_executable(path)
          FileUtils.chmod "ugo+rx", path
          Chromedriver::Binary.logger.debug "Completed download and processing of #{path}"
        end

        def cleanup_zip(zip_path)
          File.delete(zip_path)
        end
      end
    end
  end
end
