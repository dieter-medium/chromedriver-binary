# frozen_string_literal: true

require "open3"

module Chromedriver
  module Binary
    module SystemHelper
      def call(process, arg = nil)
        cmd = arg ? [process, arg] : process
        Chromedriver::Binary.logger.debug "making System call: #{cmd}"

        output, status = capture(*cmd)

        raise "Failed to make system call: #{cmd}" unless status.success?

        Chromedriver::Binary.logger.debug "System call returned: #{output}"
        output
      end

      def exists?(file)
        File.exist?(file).tap do |result|
          Chromedriver::Binary.logger.debug "#{file} is#{" not" unless result} already downloaded"
        end
      end

      private

      def capture(*cmd)
        Open3.capture2(*cmd)
      end
    end
  end
end
