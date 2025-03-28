# frozen_string_literal: true

require "spec_helper"

RSpec.describe Chromedriver::Binary::Finder do
  subject(:finder) { described_class.new }

  describe "#version" do
    it "returns the Chrome version" do
      allow(finder).to receive_messages(location: "/path/to/chrome", call: "Chrome 108.0.5359.124")

      expect(finder.version).to eq("108.0.5359.124")
    end

    it "raises error when version is empty" do
      allow(finder).to receive_messages(location: "/path/to/chrome", call: "")

      expect do
        finder.version
      end.to raise_error(Chromedriver::Binary::VersionError, "Failed to determine Chrome version.")
    end

    it "raises error when version is nil" do
      allow(finder).to receive_messages(location: "/path/to/chrome", call: nil)

      expect do
        finder.version
      end.to raise_error(Chromedriver::Binary::VersionError, "Failed to determine Chrome version.")
    end
  end

  describe "#location" do
    before do
      allow(finder).to receive(:chrome_bin_from_env).and_return(nil)
    end

    it "returns path from environment variable" do
      allow(finder).to receive(:chrome_bin_from_env).and_return("/custom/chrome/path")

      expect(finder.location).to eq("/custom/chrome/path")
    end

    it "raises error when Chrome is not found" do
      allow(finder).to receive(:find_in_paths).and_return(nil)

      expect do
        finder.location
      end.to raise_error(Chromedriver::Binary::BrowserNotFound, "Failed to determine Chrome binary location.")
    end
  end

  describe "#find_in_paths" do
    it "returns first matching path" do
      directories = ["/dir1", "/dir2"]
      files = %w[file1 file2]

      allow(finder).to receive(:file_exists?).and_return(false)
      allow(finder).to receive(:file_exists?).with("/dir1/file2").and_return(true)

      expect(finder.send(:find_in_paths, directories, files)).to eq("/dir1/file2")
    end

    it "returns nil when no matching path exists" do
      allow(finder).to receive(:file_exists?).and_return(false)

      expect(finder.send(:find_in_paths, ["/dir"], ["file"])).to be_nil
    end
  end
end
