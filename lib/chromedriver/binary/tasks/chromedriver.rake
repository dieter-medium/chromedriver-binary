# frozen_string_literal: true

namespace :chromedriver do
  namespace :binary do
    require "chromedriver/binary"

    Chromedriver::Binary.logger.level = :info

    desc "Print current chromedriver version"
    task :version do
      gem_ver = Chromedriver::Binary::ChromedriverDownloader.current_installed_version
      if gem_ver
        Chromedriver::Binary.logger.info "chromedriver #{gem_ver.version}"
      else
        Chromedriver::Binary.logger.warn "No existing chromedriver found."
      end
    end

    desc "Remove and download updated chromedriver if necessary"
    task :update do
      Chromedriver::Binary::ChromedriverDownloader.update force: true
      # rubocop:disable Layout/LineLength
      Chromedriver::Binary.logger.info "Updated to chromedriver #{Chromedriver::Binary::ChromedriverDownloader.current_installed_version}"
      # rubocop:enable Layout/LineLength
    end
  end
end
