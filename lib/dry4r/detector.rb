# frozen_string_literal: true

module Dry4r
  class Detector
    def initialize(options, scanner: Scanner.new(options))
      @options = options
      @scanner = scanner
    end

    def find
      entries = @scanner.scan
      candidates = []
      entries.each_with_index do |left, i|
        ((i + 1)...entries.length).each do |j|
          right = entries[j]
          score = similarity(left.fingerprints, right.fingerprints)
          next if score < @options.threshold

          candidates << Candidate.new(
            score: score,
            left: location(left),
            right: location(right),
            left_nodes: left.nodes,
            right_nodes: right.nodes
          )
        end
      end
      sort_candidates(candidates)
    end

    def self.similarity(left, right)
      new(Options.new).similarity(left, right)
    end

    def similarity(left, right)
      intersection = 0
      left.each_key { |fp| intersection += 1 if right[fp] }
      union = left.size
      right.each_key { |fp| union += 1 unless left[fp] }
      return 0.0 if union.zero?

      intersection.to_f / union
    end

    private

    def location(entry)
      Location.new(file: entry.file, start_line: entry.start_line, end_line: entry.end_line)
    end

    def sort_candidates(candidates)
      candidates.sort_by.with_index do |candidate, index|
        [
          -candidate.score,
          candidate.left.file,
          candidate.left.start_line,
          candidate.right.file,
          candidate.right.start_line,
          index
        ]
      end
    end
  end
end
