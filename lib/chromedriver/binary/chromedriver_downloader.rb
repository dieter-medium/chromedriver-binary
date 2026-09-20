# frozen_string_literal: true

require "fileutils"
require_relative "version_resolver"
require_relative "platform"
require_relative "downloader_helper"
require_relative "system_helper"
require_relative "system_driver_locator"

module Chromedriver
  module Binary
    class ChromedriverDownloader
      class << self
        include VersionResolver
        include Platform
        include DownloaderHelper
        include SystemHelper
        include SystemDriverLocator

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

          return driver_path if linux_arm64? && link_system_driver?

          Chromedriver::Binary.logger.warn(<<-EOF_WARNING) if linux_arm64?

             WARNING: The Linux ARM64 version of ChromeDriver is not officially supported by Google,
             and no working chromedriver was found automatically (checked CHROMEDRIVER_PATH and
             #{SystemDriverLocator::SEARCH_DIRECTORIES.join(", ")}).
             Please install the OS version of ChromeDriver instead.
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
        rescue VersionError
          false
        end

        private

        # Symlinks a system-installed chromedriver into driver_path and verifies it actually
        # matches the installed browser before trusting it - a found binary that's the wrong
        # version is no better than none, so it's unlinked again rather than left in place for
        # #update to fall through to the (still doomed, but at least unambiguous) download.
        def link_system_driver?
          source = system_driver_path
          return false unless source

          prepare_install_dir
          FileUtils.ln_sf(source, driver_path)

          if correct_binary?
            Chromedriver::Binary.logger.info "Linked system chromedriver #{source} to #{driver_path} (Linux ARM64 has no official Google build)"
            true
          else
            Chromedriver::Binary.logger.debug "#{source} exists but its version doesn't match the browser - removing the link and falling back to the official download"
            FileUtils.rm_f(driver_path)
            false
          end
        end

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
