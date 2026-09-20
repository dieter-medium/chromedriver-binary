# frozen_string_literal: true

module Chromedriver
  module Binary
    # Locates a chromedriver binary already installed on the system - used on Linux ARM64, where
    # Google's own Chrome for Testing distribution has never published a chromedriver build at all
    # (a long-standing upstream gap, not a bug in this gem - see ChromedriverDownloader#update's own
    # comment). Debian/Ubuntu's `chromium-driver` package ships a matching native-arch binary
    # instead; this lets it be found and linked automatically rather than only ever printing
    # instructions for a human to run by hand.
    module SystemDriverLocator
      SEARCH_DIRECTORIES = %w[/usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /snap/bin].freeze
      SEARCH_FILENAMES = %w[chromedriver].freeze

      # @return [String, nil] path to an existing chromedriver binary, or nil if none was found.
      def system_driver_path
        driver_from_env || find_driver_on_disk
      end

      private

      # Same override shape as Finder#chrome_bin_from_env's CHROMEDRIVER_CHROME_PATH, for the driver
      # instead of the browser - an explicit escape hatch for a system driver outside
      # SEARCH_DIRECTORIES.
      def driver_from_env
        path = ENV.fetch("CHROMEDRIVER_PATH", nil)
        path if path && File.exist?(path)
      end

      def find_driver_on_disk
        SEARCH_DIRECTORIES.each do |dir|
          SEARCH_FILENAMES.each do |file|
            path = File.join(dir, file)
            return path if File.exist?(path)
          end
        end

        nil
      end
    end
  end
end
