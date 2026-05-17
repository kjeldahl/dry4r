# frozen_string_literal: true

require "stringio"

RSpec.describe Dry4r::CLI do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:cli) { described_class.new(stdout: stdout, stderr: stderr) }

  around do |example|
    Dir.mktmpdir do |dir|
      @dir = dir
      example.run
    end
  end

  it "prints usage when --help is given" do
    expect(cli.run(["--help"])).to eq(0)
    expect(stdout.string).to include("Usage: dry4r")
  end

  it "reports bad arguments to stderr and exits 2" do
    expect(cli.run(["--bogus"])).to eq(2)
    expect(stderr.string).to include("unknown option")
  end

  it "emits JSON when --json is requested" do
    File.write(File.join(@dir, "a.rb"), <<~RUBY)
      def alpha(xs)
        ys = []
        xs.each { |x| ys << x + 1 if x.odd? }
        ys
      end
    RUBY
    File.write(File.join(@dir, "b.rb"), <<~RUBY)
      def beta(items)
        kept = []
        items.each { |item| kept << item + 1 if item.even? }
        kept
      end
    RUBY

    expect(cli.run(["--json", "--threshold", "0.7", "--min-nodes", "5", @dir])).to eq(0)
    parsed = JSON.parse(stdout.string)
    expect(parsed["candidates"]).not_to be_empty
  end

  it "emits text by default" do
    File.write(File.join(@dir, "a.rb"), "def a\n  1\nend\n")
    expect(cli.run([@dir])).to eq(0)
    expect(stdout.string).to include("No duplicate candidates found.")
  end
end
