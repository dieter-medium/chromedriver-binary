# frozen_string_literal: true

require "webrick"
require "fileutils"
require "stringio"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
RSpec.describe Chromedriver::Binary::DownloaderHelper do
  subject(:download_helper) { Object.new.tap { |sub| sub.extend(described_class) } }

  let(:tmp_dir) { File.expand_path("../tmp", __dir__) }
  let(:download_file_path) { File.join(tmp_dir, "test_download.txt") }
  let(:test_file_content) { "This is a test file.\nWith multiple lines.\n🚀" }

  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }

  before do
    FileUtils.mkdir_p(tmp_dir)

    Chromedriver::Binary.configure do |config|
      config.logger = logger

      config.proxy_port = nil
      config.proxy_user = nil
      config.proxy_pass = nil
    end
  end

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  context "when downloading a file from a local test server" do
    let(:port) { @server.config[:Port] }

    before(:all) do
      root = File.expand_path("../fixtures", __dir__)
      FileUtils.mkdir_p(root)
      File.write(File.join(root, "test_file.txt"), "This is a test file.\nWith multiple lines.\n🚀")

      @server = WEBrick::HTTPServer.new(
        Port: 0,
        DocumentRoot: root,
        AccessLog: [],
        Logger: WEBrick::Log.new(File::NULL)
      )

      @server_thread = Thread.new { @server.start }

      # Wait for server to boot
      sleep 0.5
    end

    after(:all) do
      @server&.shutdown
      @server_thread.kill
    end

    describe "#download_file" do
      let(:url) { "http://localhost:#{port}/test_file.txt" }
      let(:logs) { log_output.read }

      before do
        download_helper.download_file(url, download_file_path)
        log_output.rewind
      end

      it "creates the downloaded file" do
        expect(File).to exist(download_file_path)
      end

      it "writes the correct file contents" do
        expect(File.read(download_file_path)).to eq(test_file_content)
      end

      it "logs the start of the download" do
        expect(logs).to include("Starting download from")
      end

      it "logs successful download completion" do
        expect(logs).to include("Download complete!")
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll
