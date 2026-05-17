# frozen_string_literal: true

require "prism"

module Dry4r
  Entry = Struct.new(:file, :start_line, :end_line, :nodes, :fingerprints, keyword_init: true)

  class Scanner
    SKIP_DIRECTORIES = %w[.git vendor target node_modules tmp coverage].freeze
    SOURCE_SUFFIXES = %w[.rb .rake].freeze

    def initialize(options, normalizer: Normalizer.new)
      @options = options
      @normalizer = normalizer
    end

    def scan
      files_for(@options.paths).flat_map { |path| scan_file(path) }
    end

    def scan_file(path)
      source = File.read(path)
      parse_result = Prism.parse(source)
      return [] if parse_result.failure?

      entries = []
      collect_defs(parse_result.value) do |def_node|
        start_line = def_node.location.start_line
        end_line = def_node.location.end_line
        next if end_line - start_line + 1 < @options.min_lines

        normalized = @normalizer.normalize(def_node)
        nodes = normalized.node_count
        next if nodes < @options.min_nodes

        entries << Entry.new(
          file: path,
          start_line: start_line,
          end_line: end_line,
          nodes: nodes,
          fingerprints: normalized.fingerprints
        )
      end
      entries
    end

    private

    def collect_defs(node, &block)
      return if node.nil?

      yield node if node.is_a?(Prism::DefNode)
      node.compact_child_nodes.each { |child| collect_defs(child, &block) }
    end

    def files_for(paths)
      seen = {}
      collected = []
      paths.each do |path|
        next unless File.exist?(path)

        if File.directory?(path)
          walk_directory(path, seen, collected)
        elsif source_file?(path) && !seen[path]
          seen[path] = true
          collected << path
        end
      end
      collected.sort
    end

    def walk_directory(root, seen, collected)
      Dir.glob(File.join(root, "**", "*")).each do |entry|
        next if File.directory?(entry)
        next if skipped_path?(entry, root)
        next unless source_file?(entry)
        next if seen[entry]

        seen[entry] = true
        collected << entry
      end
    end

    def skipped_path?(path, root)
      relative = path.sub(%r{\A#{Regexp.escape(root)}/?}, "")
      relative.split(File::SEPARATOR).any? { |part| SKIP_DIRECTORIES.include?(part) }
    end

    def source_file?(path)
      SOURCE_SUFFIXES.any? { |suffix| path.end_with?(suffix) }
    end
  end
end
