# frozen_string_literal: true

require_relative "dry4r/version"
require_relative "dry4r/options"
require_relative "dry4r/normalizer"
require_relative "dry4r/scanner"
require_relative "dry4r/detector"
require_relative "dry4r/formatter"
require_relative "dry4r/cli"

module Dry4r
  Location = Struct.new(:file, :start_line, :end_line, keyword_init: true) do
    def to_h
      { file: file, start_line: start_line, end_line: end_line }
    end
  end

  Candidate = Struct.new(:score, :left, :right, :left_nodes, :right_nodes, keyword_init: true) do
    def to_h
      {
        score: score,
        left: left.to_h,
        right: right.to_h,
        left_nodes: left_nodes,
        right_nodes: right_nodes
      }
    end
  end

  def self.find_duplicates(options)
    Detector.new(options).find
  end
end
