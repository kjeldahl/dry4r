# frozen_string_literal: true

require "json"

module Dry4r
  class Formatter
    def self.text(candidates)
      return "No duplicate candidates found.\n" if candidates.empty?

      blocks = candidates.map do |candidate|
        score = format("%.2f", candidate.score)
        "DUPLICATE score=#{score}\n  #{line_range(candidate.left)}\n  #{line_range(candidate.right)}"
      end
      blocks.join("\n\n") + "\n"
    end

    def self.json(candidates)
      JSON.pretty_generate(candidates: candidates.map(&:to_h)) + "\n"
    end

    def self.line_range(location)
      "#{location.file}:#{location.start_line}-#{location.end_line}"
    end
  end
end
