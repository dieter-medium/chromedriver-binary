# frozen_string_literal: true

require "spec_helper"

RSpec.describe Chromedriver::Binary::SystemHelper do
  subject(:system_helper) { Object.new.tap { |sub| sub.extend(described_class) } }

  describe "#call" do
    it "executes command with argument" do
      allow(system_helper).to receive(:capture).with("ls", "-la")
                                               .and_return(["output", instance_double(Process::Status, success?: true)])

      expect(system_helper.call("ls", "-la")).to eq("output")
    end

    it "executes command without argument" do
      allow(system_helper).to receive(:capture).with("ls")
                                               .and_return([
                                                             "output",
                                                             instance_double(Process::Status, success?: true)
                                                           ])

      expect(system_helper.call("ls")).to eq("output")
    end

    it "raises error when command fails" do
      allow(system_helper).to receive(:capture)
                                .with("ls")
                                .and_return(["output", instance_double(Process::Status, success?: false)])

      expect { system_helper.call("ls") }.to raise_error(RuntimeError, "Failed to make system call: ls")
    end
  end
end
