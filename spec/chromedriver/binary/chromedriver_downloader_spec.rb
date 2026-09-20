# frozen_string_literal: true

require "stringio"

require "spec_helper"

RSpec.describe Chromedriver::Binary::ChromedriverDownloader do
  let(:tmp_dir) { File.expand_path("../tmp/chromedriver", __dir__) }
  let(:zip_path) { File.join(tmp_dir, "chromedriver_linux64.zip") }
  let(:extracted_driver_path) { File.join(tmp_dir, "chromedriver") }

  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }

  before do
    FileUtils.mkdir_p(tmp_dir)

    Chromedriver::Binary.configure do |config|
      config.logger = logger
      config.install_dir = tmp_dir
      config.proxy_addr = nil
      config.proxy_port = nil
      config.proxy_user = nil
      config.proxy_pass = nil
    end

    allow(described_class).to receive(:download_file) do |_, destination|
      # Create a fake zip with a dummy 'chromedriver' binary inside
      Zip::File.open(destination, Zip::File::CREATE) do |zipfile|
        zipfile.get_output_stream("chromedriver") { |f| f.write("dummy binary") }
      end
    end

    allow(described_class).to receive(:extract_zip).and_call_original
    allow(described_class).to receive_messages(platform_id: "linux64",
                                               driver_filename: "chromedriver",
                                               latest_patch_version_for_build: "123.0.1",
                                               direct_url_from_api: "https://example.com/chromedriver.zip",
                                               sufficient_binary?: true,
                                               current_installed_version: nil)
  end

  after do
    RSpec::Mocks.space.reset_all
    FileUtils.rm_rf(tmp_dir)
  end

  describe ".update" do
    before do
      described_class.update(force: true)
    end

    it "creates the driver file" do
      expect(File).to exist(extracted_driver_path)
    end

    it "makes the driver executable" do
      mode = File.stat(extracted_driver_path).mode
      expect(mode & 0o111).not_to eq(0) # at least one exec bit
    end

    it "cleans up the zip file" do
      expect(File).not_to exist(zip_path)
    end
  end

  context "when os is linux and arch arm64" do
    before do
      allow(described_class).to receive(:linux_arm64?).and_return(true)
    end

    context "when no system driver is found" do
      before do
        allow(described_class).to receive_messages(system_driver_path: nil, correct_binary?: false)
        described_class.update(force: true)
        log_output.rewind
        @logs = log_output.read
      end

      it "warns that the architecture is not officially supported" do
        expect(@logs).to include("The Linux ARM64 version of ChromeDriver is not officially supported by Google")
      end

      it "still falls back to the official (arm64-incompatible) download" do
        expect(File).to exist(extracted_driver_path)
      end
    end

    context "when a matching system driver is found" do
      let(:system_driver) { "/usr/bin/chromedriver" }

      before do
        allow(described_class).to receive_messages(system_driver_path: system_driver, correct_binary?: false)
        allow(described_class).to receive(:correct_binary?).and_return(false, true)
        described_class.update(force: true)
      end

      it "links it to driver_path" do
        expect(File.symlink?(extracted_driver_path)).to be(true)
      end

      it "points the link at the system driver" do
        expect(File.readlink(extracted_driver_path)).to eq(system_driver)
      end

      it "does not attempt a download" do
        expect(described_class).not_to have_received(:download_file)
      end

      it "does not log the unsupported-architecture warning" do
        log_output.rewind

        expect(log_output.read).not_to include("not officially supported by Google")
      end
    end

    context "when a system driver is found but its version does not match the browser" do
      let(:system_driver) { "/usr/bin/chromedriver" }

      before do
        allow(described_class).to receive_messages(system_driver_path: system_driver, correct_binary?: false)
        described_class.update(force: true)
      end

      it "removes the mismatched link" do
        expect(File.symlink?(extracted_driver_path)).to be(false)
      end

      it "falls back to the official download" do
        expect(File).to exist(extracted_driver_path)
      end
    end
  end
end
