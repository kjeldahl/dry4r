# frozen_string_literal: true

RSpec.describe Dry4r::Normalizer do
  def def_node_for(source)
    program = Prism.parse(source).value
    program.statements.body.first
  end

  it "normalizes identifiers and literal kinds" do
    normalizer = described_class.new
    node = def_node_for(<<~RUBY)
      def example
        x = 1
        y = "two"
        :three
      end
    RUBY

    serialized = normalizer.normalize(node).serialize

    expect(serialized).to include("literal/int")
    expect(serialized).to include("literal/string")
    expect(serialized).to include("literal/symbol")
    expect(serialized).to include("(assign")
    expect(serialized).not_to include("\"two\"")
  end

  it "produces equal fingerprint sets for structurally identical methods" do
    normalizer = described_class.new
    alpha = normalizer.normalize(def_node_for(<<~RUBY))
      def alpha(xs)
        ys = []
        xs.each do |x|
          ys << x + 1 if x.odd?
        end
        ys
      end
    RUBY
    beta = normalizer.normalize(def_node_for(<<~RUBY))
      def beta(items)
        kept = []
        items.each do |item|
          kept << item + 1 if item.odd?
        end
        kept
      end
    RUBY

    expect(alpha.fingerprints.keys.sort).to eq(beta.fingerprints.keys.sort)
  end

  it "counts every node in the normalized tree" do
    normalizer = described_class.new
    node = normalizer.normalize(def_node_for("def empty; end"))

    expect(node.node_count).to be > 1
  end

  it "normalizes a wide variety of Ruby constructs without crashing" do
    normalizer = described_class.new
    source = <<~RUBY
      class Sample < Object
        CONST = 1
        @@class_var = 2

        def self.singleton_method(*args, **opts, &block)
          @ivar = $global = CONST
          @ivar += 1
          @ivar &&= 1
          @ivar ||= nil
          a, b = [1, 2]
          unless args.empty?
            args.each_with_index do |arg, i|
              next if arg.nil?
              break if i > 10
              yield arg if block_given?
            end
          end
          while @ivar < 100
            @ivar += 1
          end
          until @ivar.zero?
            @ivar -= 1
          end
          for x in (1..10)
            puts x
          end
          case args.first
          when Integer, Float then "number"
          when /regex/ then :symbol
          else "other"
          end
          [1, 2.0, 3r, 4i, "five", :six, nil, true, false].map { |x| -x }
          { a: 1, **opts }
          return self if args.empty?
          begin
            raise "oops"
          rescue StandardError => e
            puts e
          else
            "ok"
          ensure
            "always"
          end
          -> (n) { n * 2 }
        end

        def instance_method
          a && b or c
        end
      end

      module Nested
        class << self
          def singleton; end
        end
      end
    RUBY
    program = Prism.parse(source).value

    expect { normalizer.normalize(program) }.not_to raise_error
  end
end
