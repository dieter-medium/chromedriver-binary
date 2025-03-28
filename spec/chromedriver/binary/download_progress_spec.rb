# frozen_string_literal: true

require "stringio"
require "logger"
require "spec_helper"

RSpec.describe Chromedriver::Binary::DownloadProgress do
  subject(:progress) { described_class.new(logger: logger, step_bytes: step_bytes) }

  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }
  let(:step_bytes) { 1024 * 1024 } # 1 MB step

  it "logs progress after reaching the step threshold" do
    progress.track(500_000)
    progress.track(600_000) # total: 1.1 MB → should trigger a log

    log_output.rewind
    log_lines = log_output.read.lines

    expect(log_lines).to include(a_string_including("Downloaded ~1.05 MB"))
  end

  it "logs multiple progress updates if thresholds are crossed" do
    progress.track(step_bytes + 1)
    progress.track(step_bytes + 1)

    log_output.rewind
    log_lines = log_output.read.lines

    expect(log_lines).to have_attributes(size: 2)
  end

  it "logs final size when finish is called" do
    progress.track(2_500_000)
    progress.finish

    log_output.rewind
    final_log = log_output.read

    expect(final_log).to include("Download complete! ✅ Total: 2.38 MB")
  end
end
