# frozen_string_literal: true

require "rails"

module Chromedriver
  module Binary
    class Railtie < Rails::Railtie
      railtie_name :chromedriver_binary

      rake_tasks do
        path = File.expand_path(__dir__)
        Dir.glob("#{path}/tasks/*.rake").each { |f| load f }
      end
    end
  end
end
