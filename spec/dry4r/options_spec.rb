# frozen_string_literal: true

RSpec.describe Dry4r::Options do
  describe ".parse" do
    it "applies overrides and collects paths" do
      options = described_class.parse(%w[--threshold 0.9 --min-lines 5 --min-nodes 30 --json lib spec])

      expect(options.threshold).to eq(0.9)
      expect(options.min_lines).to eq(5)
      expect(options.min_nodes).to eq(30)
      expect(options.format).to eq("json")
      expect(options.paths).to eq(%w[lib spec])
    end

    it "defaults to the current directory when no paths are given" do
      options = described_class.parse([])

      expect(options.paths).to eq(["."])
    end

    it "accepts --text and --format text" do
      expect(described_class.parse(%w[--text]).format).to eq("text")
      expect(described_class.parse(%w[--format text]).format).to eq("text")
    end

    it "raises on unknown flags" do
      expect { described_class.parse(%w[--bogus]) }.to raise_error(ArgumentError, /unknown option/)
    end

    it "raises when a value-bearing flag has no argument" do
      expect { described_class.parse(%w[--threshold]) }.to raise_error(ArgumentError, /missing value/)
    end

    it "raises on an unknown format" do
      expect { described_class.parse(%w[--format yaml]) }.to raise_error(ArgumentError, /unknown format/)
    end

    it "returns immediately when --help is requested" do
      options = described_class.parse(%w[--help --threshold 0.5])

      expect(options.help).to be(true)
    end
  end
end
