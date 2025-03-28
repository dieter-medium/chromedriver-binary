# frozen_string_literal: true

require "spec_helper"

RSpec.describe Chromedriver::Binary::VersionResolver do
  subject(:resolver) { Object.new.tap { |sub| sub.extend(described_class) } }

  describe "#normalize_version" do
    it "converts string to Gem::Version" do
      expect(resolver.normalize_version("1.2.3")).to eq(Gem::Version.new("1.2.3"))
    end

    it "handles version as number" do
      expect(resolver.normalize_version(1.23)).to eq(Gem::Version.new("1.23"))
    end
  end

  describe "#browser_build_version" do
    it "returns major.minor.build segments of browser version" do
      allow(resolver).to receive(:browser_version).and_return(Gem::Version.new("99.0.4844.51"))

      expect(resolver.browser_build_version).to eq(Gem::Version.new("99.0.4844"))
    end
  end

  describe "#latest_patch_version_for_build" do
    it "fetches and returns the latest patch version for current build" do
      allow(resolver).to receive(:browser_version).and_return(Gem::Version.new("99.0.4844"))

      allow(resolver).to receive(:fetch_data).with("latest-patch-versions-per-build.json").and_return(
        { builds: { '99.0.4844': { version: "99.0.4844.51" } } }
      )

      expect(resolver.latest_patch_version_for_build).to eq("99.0.4844.51")
    end

    it "raises error when patch version not found" do
      allow(resolver).to receive(:browser_version).and_return(Gem::Version.new("99.0.9999"))
      allow(resolver).to receive(:fetch_data).with("latest-patch-versions-per-build.json").and_return({ builds: {} })

      expect { resolver.latest_patch_version_for_build }.to raise_error(RuntimeError, /No patch version found/)
    end

    it "raises error when fetch fails" do
      allow(resolver).to receive(:browser_version).and_return(Gem::Version.new("99.0.4844"))
      allow(resolver).to receive(:fetch_data).and_raise(StandardError.new("Network error"))

      expect do
        resolver.latest_patch_version_for_build
      end.to raise_error(RuntimeError, /Error fetching latest patch version/)
    end
  end

  describe "#direct_url_from_api" do
    it "returns download URL for given driver version and filename" do
      data = {
        versions: [
          {
            version: "99.0.4844.51",
            downloads: {
              chromedriver: [
                { platform: "mac-x64", url: "https://example.com/mac-x64.zip" },
                { platform: "win32", url: "https://example.com/win32.zip" }
              ]
            }
          }
        ]
      }

      allow(resolver).to receive(:fetch_data).with("known-good-versions-with-downloads.json").and_return(data)

      expect(resolver.direct_url_from_api("99.0.4844.51", "mac-x64")).to eq("https://example.com/mac-x64.zip")
    end
  end

  describe "#current_installed_version" do
    before do
      def resolver.driver_path
        "/path/to/chromedriver"
      end
    end

    it "returns nil when driver does not exist" do
      allow(resolver).to receive(:exists?).with("/path/to/chromedriver").and_return(false)
      expect(resolver.current_installed_version).to be_nil
    end

    it "returns nil when version query fails" do
      allow(resolver).to receive(:exists?).with("/path/to/chromedriver").and_return(true)
      allow(resolver).to receive(:call).and_return(nil)

      expect(resolver.current_installed_version).to be_nil
    end

    it "returns parsed version when driver exists" do
      allow(resolver).to receive(:exists?).with("/path/to/chromedriver").and_return(true)
      allow(resolver).to receive(:call).and_return("ChromeDriver 99.0.4844.51")

      expect(resolver.current_installed_version).to eq(Gem::Version.new("99.0.4844.51"))
    end
  end

  describe "#query_binary_version" do
    before do
      def resolver.driver_path
        "/path/to/chromedriver"
      end
    end

    it "returns version from call to driver" do
      version_output = "ChromeDriver 99.0.4844.51"
      allow(resolver).to receive(:call).with("/path/to/chromedriver", "--version").and_return(version_output)

      expect(resolver.query_binary_version).to eq(version_output)
    end

    it "returns nil when call raises ENOENT" do
      allow(resolver).to receive(:call).and_raise(Errno::ENOENT)

      expect(resolver.query_binary_version).to be_nil
    end
  end
end
