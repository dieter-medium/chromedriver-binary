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
      log_output.rewind
      @logs = log_output.read
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
end
