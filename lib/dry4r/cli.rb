# frozen_string_literal: true

module Dry4r
  class CLI
    def initialize(stdout: $stdout, stderr: $stderr)
      @stdout = stdout
      @stderr = stderr
    end

    def run(argv)
      options = Options.parse(argv)
      if options.help
        @stdout.puts Options::USAGE
        return 0
      end

      candidates = Dry4r.find_duplicates(options)
      case options.format
      when "text" then @stdout.print Formatter.text(candidates)
      when "json" then @stdout.print Formatter.json(candidates)
      end
      0
    rescue ArgumentError => e
      @stderr.puts e.message
      @stderr.puts
      @stderr.puts Options::USAGE
      2
    end
  end
end
