# frozen_string_literal: true

RSpec.describe Chromedriver::Binary do
  it "has a version number" do
    expect(Chromedriver::Binary::VERSION).not_to be_nil
  end
end
