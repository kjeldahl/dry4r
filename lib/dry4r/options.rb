# frozen_string_literal: true

module Dry4r
  class Options
    DEFAULTS = {
      paths: ["."],
      threshold: 0.82,
      min_lines: 4,
      min_nodes: 20,
      format: "text",
      help: false
    }.freeze

    USAGE = <<~USAGE
      Usage: dry4r [options] [file-or-directory ...]

      Options:
        --threshold N   Minimum structural similarity score, default 0.82
        --min-lines N   Minimum source lines in a candidate method, default 4
        --min-nodes N   Minimum normalized syntax nodes, default 20
        --format F      text or json, default text
        --json          Same as --format json
        --text          Same as --format text
        --help, -h      Show this message
    USAGE

    attr_accessor :paths, :threshold, :min_lines, :min_nodes, :format, :help

    def initialize(**overrides)
      DEFAULTS.merge(overrides).each { |key, value| public_send("#{key}=", value) }
    end

    def self.parse(args)
      options = new(paths: [])
      i = 0
      while i < args.length
        arg = args[i]
        case arg
        when "--help", "-h"
          options.help = true
          return options
        when "--threshold", "--min-lines", "--min-nodes", "--format"
          raise ArgumentError, "missing value for #{arg}" if i + 1 >= args.length

          i += 1
          options.apply_value(arg, args[i])
        when "--json"
          options.format = "json"
        when "--text"
          options.format = "text"
        else
          raise ArgumentError, "unknown option: #{arg}" if arg.start_with?("--")

          options.paths << arg
        end
        i += 1
      end
      options.paths = DEFAULTS[:paths].dup if options.paths.empty?
      options
    end

    def apply_value(flag, value)
      case flag
      when "--threshold"
        self.threshold = Float(value)
      when "--min-lines"
        self.min_lines = Integer(value)
      when "--min-nodes"
        self.min_nodes = Integer(value)
      when "--format"
        raise ArgumentError, "unknown format: #{value}" unless %w[text json].include?(value)

        self.format = value
      end
    end
  end
end
