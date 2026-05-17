# frozen_string_literal: true

RSpec.describe Dry4r::Detector do
  around do |example|
    Dir.mktmpdir do |dir|
      @dir = dir
      example.run
    end
  end

  def write_source(name, content)
    path = File.join(@dir, name)
    File.write(path, content)
    path
  end

  it "reports structurally similar methods as duplicate candidates" do
    left = write_source("left.rb", <<~RUBY)
      def alpha(xs)
        ys = []
        xs.each do |x|
          ys << x + 1 if x.odd?
        end
        ys
      end
    RUBY
    right = write_source("right.rb", <<~RUBY)
      def beta(items)
        kept = []
        items.each do |item|
          kept << item + 1 if item.even?
        end
        kept
      end
    RUBY

    options = Dry4r::Options.new(paths: [@dir], threshold: 0.8, min_lines: 4, min_nodes: 8)
    candidates = Dry4r.find_duplicates(options)

    expect(candidates.length).to eq(1)
    expect(candidates.first.left.file).to eq(left)
    expect(candidates.first.right.file).to eq(right)
    expect(candidates.first.score).to be >= 0.8
  end

  it "returns an empty list when nothing exceeds the threshold" do
    write_source("a.rb", "def a\n  1\n  2\n  3\nend\n")
    write_source("b.rb", "def b\n  loop { break }\n  raise 'x'\nend\n")

    options = Dry4r::Options.new(paths: [@dir], threshold: 0.95, min_lines: 1, min_nodes: 1)

    expect(Dry4r.find_duplicates(options)).to be_empty
  end

  it "computes Jaccard similarity over fingerprint sets" do
    detector = described_class.new(Dry4r::Options.new)
    left = { "a" => true, "b" => true, "c" => true }
    right = { "b" => true, "c" => true, "d" => true }

    expect(detector.similarity(left, right)).to be_within(1e-9).of(0.5)
  end

  it "returns 0 similarity when both fingerprint sets are empty" do
    detector = described_class.new(Dry4r::Options.new)

    expect(detector.similarity({}, {})).to eq(0.0)
  end
end
