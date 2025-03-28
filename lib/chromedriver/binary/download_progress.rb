# frozen_string_literal: true

module Chromedriver
  module Binary
    class DownloadProgress
      def initialize(logger:, step_bytes: 1 * 1024 * 1024)
        # Default: 1 MB
        @logger = logger
        @step_bytes = step_bytes
        @total_bytes = 0
        @next_log_at = step_bytes
      end

      def track(chunk_size)
        @total_bytes += chunk_size

        return unless @total_bytes >= @next_log_at

        mb = (@total_bytes.to_f / (1024 * 1024)).round(2)
        @logger.debug("Downloaded ~#{mb} MB 📦")
        @next_log_at += @step_bytes
      end

      def finish
        mb = (@total_bytes.to_f / (1024 * 1024)).round(2)
        @logger.info("Download complete! ✅ Total: #{mb} MB")
      end
    end
  end
end
