# frozen_string_literal: true

require "prism"

module Dry4r
  Node = Struct.new(:tag, :children) do
    def serialize
      buffer = +"("
      buffer << tag
      children.each do |child|
        buffer << " "
        buffer << child.serialize
      end
      buffer << ")"
      buffer
    end

    def node_count
      1 + children.sum(&:node_count)
    end

    def fingerprints
      out = {}
      walk = lambda do |node|
        out[node.serialize] = true
        node.children.each { |child| walk.call(child) }
      end
      walk.call(self)
      out
    end
  end

  class Normalizer
    NIL_NODE = Node.new("nil", []).freeze
    IDENT = Node.new("ident", []).freeze
    METHOD_NAME = Node.new("method", []).freeze
    OPERATORS = %i[
      + - * / % ** & | ^ ~ ! << >> == != === < > <= >= <=> =~ !~ [] []= !
    ].freeze

    # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    def normalize(node)
      return NIL_NODE if node.nil?

      case node
      when Prism::DefNode then normalize_def(node)
      when Prism::CallNode then normalize_call(node)
      when Prism::StatementsNode
        Node.new("stmts", node.body.map { |child| normalize(child) })
      when Prism::IfNode
        Node.new("if", [normalize(node.predicate), normalize(node.statements), normalize(node.consequent)])
      when Prism::UnlessNode
        Node.new("unless", [normalize(node.predicate), normalize(node.statements), normalize(node.consequent)])
      when Prism::WhileNode
        Node.new("while", [normalize(node.predicate), normalize(node.statements)])
      when Prism::UntilNode
        Node.new("until", [normalize(node.predicate), normalize(node.statements)])
      when Prism::ForNode
        Node.new("for", [normalize(node.index), normalize(node.collection), normalize(node.statements)])
      when Prism::CaseNode
        Node.new("case", [normalize(node.predicate),
                          Node.new("branches", node.conditions.map { |when_clause| normalize(when_clause) }),
                          normalize(node.consequent)])
      when Prism::WhenNode
        Node.new("when", [Node.new("conditions", node.conditions.map { |c| normalize(c) }),
                          normalize(node.statements)])
      when Prism::ElseNode
        Node.new("else", [normalize(node.statements)])
      when Prism::BeginNode
        Node.new("begin", [normalize(node.statements),
                           normalize(node.rescue_clause),
                           normalize(node.else_clause),
                           normalize(node.ensure_clause)])
      when Prism::RescueNode
        Node.new("rescue", [Node.new("exceptions", node.exceptions.map { |e| normalize(e) }),
                            normalize(node.reference),
                            normalize(node.statements),
                            normalize(node.consequent)])
      when Prism::EnsureNode then Node.new("ensure", [normalize(node.statements)])
      when Prism::ReturnNode then Node.new("return", arguments_children(node.arguments))
      when Prism::BreakNode then Node.new("break", arguments_children(node.arguments))
      when Prism::NextNode then Node.new("next", arguments_children(node.arguments))
      when Prism::YieldNode then Node.new("yield", arguments_children(node.arguments))
      when Prism::BlockNode then Node.new("block", [normalize(node.parameters), normalize(node.body)])
      when Prism::BlockParametersNode then Node.new("block-params", [normalize(node.parameters)])
      when Prism::ParametersNode then normalize_parameters(node)
      when Prism::ArgumentsNode then Node.new("args", node.arguments.map { |a| normalize(a) })
      when Prism::ArrayNode then Node.new("array", node.elements.map { |e| normalize(e) })
      when Prism::HashNode then Node.new("hash", node.elements.map { |e| normalize(e) })
      when Prism::AssocNode then Node.new("pair", [normalize(node.key), normalize(node.value)])
      when Prism::AssocSplatNode then Node.new("splat-pair", [normalize(node.value)])
      when Prism::SplatNode then Node.new("splat", [normalize(node.expression)])
      when Prism::RangeNode then Node.new(node.exclude_end? ? "range-excl" : "range",
                                          [normalize(node.left), normalize(node.right)])
      when Prism::AndNode then Node.new("and", [normalize(node.left), normalize(node.right)])
      when Prism::OrNode then Node.new("or", [normalize(node.left), normalize(node.right)])
      when Prism::ParenthesesNode then Node.new("paren", [normalize(node.body)])
      when Prism::InterpolatedStringNode then Node.new("interp-string", node.parts.map { |p| normalize(p) })
      when Prism::InterpolatedSymbolNode then Node.new("interp-symbol", node.parts.map { |p| normalize(p) })
      when Prism::EmbeddedStatementsNode then Node.new("embed", [normalize(node.statements)])
      when Prism::LambdaNode then Node.new("lambda", [normalize(node.parameters), normalize(node.body)])
      when Prism::ClassNode then Node.new("class", [normalize(node.superclass), normalize(node.body)])
      when Prism::ModuleNode then Node.new("module", [normalize(node.body)])
      when Prism::SingletonClassNode then Node.new("sclass", [normalize(node.expression), normalize(node.body)])
      when Prism::ConstantPathNode then Node.new("const-path", [normalize(node.parent)])
      when *write_node_types then Node.new("assign", [normalize(node.value)])
      when *target_node_types then Node.new("target", [])
      when Prism::MultiWriteNode then Node.new("multi-assign", [normalize(node.value)])
      when *operator_write_node_types then Node.new("op-assign", [normalize(node.value)])
      when *identifier_node_types then IDENT
      when Prism::IntegerNode then literal("int")
      when Prism::FloatNode then literal("float")
      when Prism::RationalNode then literal("rational")
      when Prism::ImaginaryNode then literal("imaginary")
      when Prism::StringNode then literal("string")
      when Prism::SymbolNode then literal("symbol")
      when Prism::RegularExpressionNode then literal("regex")
      when Prism::TrueNode then literal("true")
      when Prism::FalseNode then literal("false")
      when Prism::NilNode then literal("nil")
      when Prism::SelfNode then literal("self")
      when Prism::SourceLineNode then literal("__LINE__")
      when Prism::SourceFileNode then literal("__FILE__")
      when Prism::SourceEncodingNode then literal("__ENCODING__")
      else
        Node.new(generic_tag(node), node.compact_child_nodes.map { |c| normalize(c) })
      end
    end
    # rubocop:enable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity

    private

    def normalize_def(node)
      Node.new("def",
               [normalize(node.parameters),
                normalize(node.body),
                Node.new(node.receiver ? "self-def" : "instance-def", [])])
    end

    def normalize_call(node)
      children = [normalize(node.receiver), METHOD_NAME]
      children << Node.new("op-#{node.name}", []) if operator_name?(node.name)
      children << Node.new("args", node.arguments ? node.arguments.arguments.map { |a| normalize(a) } : [])
      children << normalize(node.block) if node.block
      Node.new("call", children)
    end

    def normalize_parameters(node)
      groups = [
        ["req", node.requireds],
        ["opt", node.optionals],
        ["rest", Array(node.rest)],
        ["post", node.posts],
        ["kw", node.keywords],
        ["kwrest", Array(node.keyword_rest)],
        ["blockparam", Array(node.block)]
      ]
      children = groups.map do |tag, params|
        Node.new(tag, params.map { |_| IDENT })
      end
      Node.new("params", children)
    end

    def arguments_children(args)
      return [] if args.nil?

      args.arguments.map { |a| normalize(a) }
    end

    def literal(kind)
      Node.new("literal/#{kind}", [])
    end

    def write_node_types
      @write_node_types ||= [
        Prism::LocalVariableWriteNode,
        Prism::InstanceVariableWriteNode,
        Prism::ClassVariableWriteNode,
        Prism::GlobalVariableWriteNode,
        Prism::ConstantWriteNode,
        Prism::ConstantPathWriteNode
      ].compact.freeze
    end

    def target_node_types
      @target_node_types ||= [
        Prism::LocalVariableTargetNode,
        Prism::InstanceVariableTargetNode,
        Prism::ClassVariableTargetNode,
        Prism::GlobalVariableTargetNode,
        Prism::ConstantTargetNode,
        Prism::ConstantPathTargetNode
      ].compact.freeze
    end

    def operator_write_node_types
      @operator_write_node_types ||= [
        Prism::LocalVariableOperatorWriteNode,
        Prism::InstanceVariableOperatorWriteNode,
        Prism::ClassVariableOperatorWriteNode,
        Prism::GlobalVariableOperatorWriteNode,
        Prism::ConstantOperatorWriteNode,
        Prism::ConstantPathOperatorWriteNode,
        Prism::LocalVariableAndWriteNode,
        Prism::InstanceVariableAndWriteNode,
        Prism::ClassVariableAndWriteNode,
        Prism::GlobalVariableAndWriteNode,
        Prism::ConstantAndWriteNode,
        Prism::ConstantPathAndWriteNode,
        Prism::LocalVariableOrWriteNode,
        Prism::InstanceVariableOrWriteNode,
        Prism::ClassVariableOrWriteNode,
        Prism::GlobalVariableOrWriteNode,
        Prism::ConstantOrWriteNode,
        Prism::ConstantPathOrWriteNode
      ].compact.freeze
    end

    def identifier_node_types
      @identifier_node_types ||= [
        Prism::LocalVariableReadNode,
        Prism::InstanceVariableReadNode,
        Prism::ClassVariableReadNode,
        Prism::GlobalVariableReadNode,
        Prism::ConstantReadNode,
        Prism::BlockArgumentNode,
        Prism::RequiredParameterNode,
        Prism::OptionalParameterNode,
        Prism::RequiredKeywordParameterNode,
        Prism::OptionalKeywordParameterNode,
        Prism::RestParameterNode,
        Prism::KeywordRestParameterNode,
        Prism::BlockParameterNode
      ].compact.freeze
    end

    def operator_name?(name)
      OPERATORS.include?(name)
    end

    def generic_tag(node)
      node.class.name.split("::").last.sub(/Node\z/, "").downcase
    end
  end
end
