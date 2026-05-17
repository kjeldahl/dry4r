# frozen_string_literal: true

RSpec.describe Dry4r::Scanner do
  around do |example|
    Dir.mktmpdir do |dir|
      @dir = dir
      example.run
    end
  end

  def write_source(name, content)
    path = File.join(@dir, name)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  it "returns one entry per qualifying method" do
    write_source("a.rb", <<~RUBY)
      def alpha(xs)
        ys = []
        xs.each { |x| ys << x + 1 }
        ys
      end
    RUBY
    scanner = described_class.new(Dry4r::Options.new(paths: [@dir], min_lines: 3, min_nodes: 5))

    entries = scanner.scan

    expect(entries.length).to eq(1)
    expect(entries.first.start_line).to eq(1)
    expect(entries.first.nodes).to be > 5
  end

  it "skips methods shorter than min_lines" do
    write_source("a.rb", "def a; 1; end\n")
    scanner = described_class.new(Dry4r::Options.new(paths: [@dir], min_lines: 3, min_nodes: 1))

    expect(scanner.scan).to be_empty
  end

  it "skips methods with too few nodes" do
    write_source("a.rb", "def a\n  1\nend\n")
    scanner = described_class.new(Dry4r::Options.new(paths: [@dir], min_lines: 1, min_nodes: 100))

    expect(scanner.scan).to be_empty
  end

  it "ignores files in skipped directories" do
    write_source("vendor/lib.rb", "def a\n  1\n  2\n  3\nend\n")
    scanner = described_class.new(Dry4r::Options.new(paths: [@dir], min_lines: 1, min_nodes: 1))

    expect(scanner.scan).to be_empty
  end

  it "skips files that cannot be parsed" do
    write_source("broken.rb", "def\n  this is not ruby")
    scanner = described_class.new(Dry4r::Options.new(paths: [@dir], min_lines: 1, min_nodes: 1))

    expect(scanner.scan).to be_empty
  end

  it "accepts a file path directly" do
    path = write_source("a.rb", "def a\n  1\n  2\n  3\nend\n")
    scanner = described_class.new(Dry4r::Options.new(paths: [path], min_lines: 1, min_nodes: 1))

    expect(scanner.scan.map(&:file)).to eq([path])
  end
end
