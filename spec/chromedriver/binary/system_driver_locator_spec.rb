# frozen_string_literal: true

require "spec_helper"

RSpec.describe Chromedriver::Binary::SystemDriverLocator do
  subject(:locator) { Class.new { include Chromedriver::Binary::SystemDriverLocator }.new }

  around do |example|
    original = ENV.fetch("CHROMEDRIVER_PATH", nil)
    example.run
  ensure
    ENV["CHROMEDRIVER_PATH"] = original
  end

  describe "#system_driver_path" do
    it "returns CHROMEDRIVER_PATH when it points at a real file" do
      ENV["CHROMEDRIVER_PATH"] = "/custom/chromedriver"
      allow(File).to receive(:exist?).with("/custom/chromedriver").and_return(true)

      expect(locator.system_driver_path).to eq("/custom/chromedriver")
    end

    it "ignores CHROMEDRIVER_PATH when it points at nothing, and falls back to the search list" do
      ENV["CHROMEDRIVER_PATH"] = "/custom/chromedriver"
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:exist?).with("/usr/bin/chromedriver").and_return(true)

      expect(locator.system_driver_path).to eq("/usr/bin/chromedriver")
    end

    it "returns the first match from the search directories in order" do
      ENV.delete("CHROMEDRIVER_PATH")
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:exist?).with("/usr/local/bin/chromedriver").and_return(true)
      allow(File).to receive(:exist?).with("/usr/bin/chromedriver").and_return(true)

      expect(locator.system_driver_path).to eq("/usr/local/bin/chromedriver")
    end

    it "returns nil when nothing is found anywhere" do
      ENV.delete("CHROMEDRIVER_PATH")
      allow(File).to receive(:exist?).and_return(false)

      expect(locator.system_driver_path).to be_nil
    end
  end
end
