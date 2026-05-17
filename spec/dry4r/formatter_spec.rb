# frozen_string_literal: true

RSpec.describe Dry4r::Formatter do
  let(:candidate) do
    Dry4r::Candidate.new(
      score: 0.875,
      left: Dry4r::Location.new(file: "a.rb", start_line: 10, end_line: 14),
      right: Dry4r::Location.new(file: "b.rb", start_line: 20, end_line: 24),
      left_nodes: 30,
      right_nodes: 31
    )
  end

  describe ".text" do
    it "formats a candidate with rounded score and line ranges" do
      output = described_class.text([candidate])

      expect(output).to eq("DUPLICATE score=0.88\n  a.rb:10-14\n  b.rb:20-24\n")
    end

    it "reports when no duplicates are found" do
      expect(described_class.text([])).to eq("No duplicate candidates found.\n")
    end
  end

  describe ".json" do
    it "produces parseable JSON containing the candidates array" do
      payload = JSON.parse(described_class.json([candidate]))

      expect(payload["candidates"].length).to eq(1)
      expect(payload["candidates"].first).to include("score" => 0.875, "left_nodes" => 30)
    end

    it "produces an empty array when there are no candidates" do
      payload = JSON.parse(described_class.json([]))

      expect(payload).to eq("candidates" => [])
    end
  end
end
