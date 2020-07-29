module DDQL
  class TokenType
    using StringRefinements

    attr_reader :label, :name, :pattern

    FACTOR_PATTERN = /\[[^\]]+\]/

    def self.all_types_pattern
      Regexp.compile(ALL.map { |tt| "(?<#{tt.name}>#{tt.pattern})" }.join('|'))
    end

    def initialize(name:, pattern:, &block)
      @label             = name.to_s
      @name              = name
      @pattern           = pattern
      @skipping          = false
      @data_range        = 0..-1
      @value_transformer = block
    end

    def as_hash(data)
      # case name
      # when :string_literal; {right: {string: data}}
      # when :integer_literal; {right: {int: data}}
      # when :numeric_literal, :sci_num_literal; {right: {float: data}}
      # # when :lparen; {lstatement: data}
      # when :rparen; Hash.new
      # else
        raise "subclass responsibility name[#{name}] data[#{data}]"
      # end
    end

    def comparison?(data)
      false
    end

    def data_from(match_data:)
      match_data.named_captures[label]
    end

    def expression?
      false
    end

    def factor?
      false
    end

    def group?
      false
    end

    def infix?
      false
    end

    def interpret(data)
      return nil if data.nil?
      return data[@data_range] if @value_transformer.nil?
      @value_transformer.call(data[@data_range])
    end

    def interpreted_data_from(match_data:)
      data = data_from match_data: match_data
      return nil if data.nil?
      interpret data
    end

    def literal?
      false
    end

    def match?(match_data:)
      data_from(match_data: match_data).nil? || @skipping ? false : true
    end

    def parse(parser, token, expression: nil)
      as_hash(token.data)
    end

    def postfix?
      false
    end

    def prefix?
      false
    end

    def screen?
      false
    end

    def skipping!
      @skipping = true
      self
    end

    def trimming!(range=(1..-2))
      @data_range = range
      self
    end

    ### Literals

    class Literal < TokenType
      def initialize(name:, pattern:)
        super(name: name, pattern: pattern)
        trimming!
      end

      def as_hash(data)
        # {right: {data_type => data}}
        {data_type => data}
      end

      def data_type
        raise "subclass responsibility for [#{self.class}]"
      end

      def literal?
        true
      end
    end

    class Currency < Literal
      def initialize
        super(name: :currency, pattern: /'(?!')(?<code>[A-Z]{3}):(\d+\.?\d+)'/)
        @value_transformer = lambda do |s|
          s = s.split(':', 2)
          {currency_code: s.first, currency_value: {float: s.last.to_f}}
        end
      end

      def as_hash(data)
        # {right: data}
        data
      end
    end

    class Integer < Literal
      def initialize
        super(name: :integer, pattern: /'(?!')(?>[+-]?)(\d+)'/)
        @value_transformer = -> (s) { s.to_i }
      end

      def data_type
        :int
      end
    end

    class Numeric < Literal
      def initialize
        super(name: :numeric, pattern: /'(?!')((?>[+-]?)(?>(?>\d+)(?>\.?)(?>\d*)|(?>\d*)(?>\.?)(?>\d+)))'/)
        @value_transformer = -> (s) { s.to_f }
      end

      def data_type
        :float
      end
    end

    class ScientificNumeric < Literal
      def initialize
        super(name: :sci_num, pattern: /'(?!')([+-]?\d(\.\d+)?[Ee][+-]?[^0]\d+)'/)
        @value_transformer = -> (s) { s.to_f }
      end

      def data_type
        :float
      end
    end

    class SpecialMarker < Literal
      def initialize
        super(name: :special_marker, pattern: /\$[a-zA-Z_]+/)
        trimming!(1..-1)
      end

      def as_hash(data)
        super({data.downcase.to_sym => "$#{data}"})
      end

      def data_type
        name
      end
    end

    class String < Literal
      def initialize
        super(name: :string, pattern: /'(?:[^'\\]|\\.)*?'/)
        @value_transformer = -> (s) { s.gsub('\\', '') }
      end

      def data_type
        name
      end
    end

    ### /Literals

    class Factor < TokenType
      def initialize
        super(name: :factor, pattern: FACTOR_PATTERN)
        trimming!
      end

      def as_hash(data)
        # {left: {name => data}}
        {name => data}
      end

      def factor?
        true
      end

      def parse(parser, token, expression: nil)
        h = as_hash(token.data)
        parser.peek&.comparison? ? {left: h} : h
      end
    end

    class Group < TokenType
      def initialize
        super(name: :lparen, pattern: /\((?=[^%])/)
      end

      def group?
        true
      end

      def parse(parser, token, expression: nil)
        new_expression = parser.parse
        parser.consume TokenType::RPAREN #if parser.peek&.data == ')'

        if expression.nil?
          next_token = parser.peek
          if next_token && (next_token.and? || next_token.or?)
            {
              lstatement: new_expression,
            }
          else
            new_expression
          end
        else
          expression.merge(new_expression)
        end
      end
    end

    class NullOperators
      include Singleton
      def as_hash(data)
        {op: {op_is: 'IS'}, right: {null_value_type: data.squish.split(' ').last}}
      end

      def comparison?
        true
      end
    end

    class Operator < TokenType
      NULL_TYPES = /IS\s+(NO_INFORMATION|NOT_(APPLICABLE|COLLECTED|DISCLOSED|MEANINGFUL))/
      def as_hash(data)
        return NullOperators.instance.as_hash(data) if data =~ NULL_TYPES
        {op: {op_symbol(data) => data}}
      end

      def comparison?(data)
        Operators.instance.cache[data]&.comparison?
      end

      def complex_comparison?(data)
        Operators.instance.cache[data]&.complex_comparison?
      end

      def math?(data)
        Operators.instance.cache[data]&.math?
      end

      def parse(parser, token, expression: nil)
        operator = Operators.instance.cache[token.op_data]
        if expression.nil? && !operator.prefix?
          raise "expected op[#{operator&.name}] to be part of an expression"
        end
        operator.parse(parser, token, expression: expression)
      end

      def simple_comparison?(data)
        Operators.instance.cache[data]&.simple_comparison?
      end

      protected
      def op_symbol(data)
        float_map_ops = Operators.float_map_ops

        case data
        when '==', '='; :op_eq
        when '!='; :op_ne
        when '>'; :op_gt
        when '>='; :op_ge
        when '<'; :op_lt
        when '<='; :op_le
        when '+'; :op_add
        when '-'; :op_subtract
        when '*'; :op_multiply
        when '/'; :op_divide
        when '%'; :op_mod
        when '^'; :op_power
        when 'ON'; :op_date_on
        when 'EPST'; :op_date_after_or_on
        when 'EPRE'; :op_date_before_or_on
        when 'PST'; :op_date_after
        when 'PRE'; :op_date_before
        when 'EXISTS'; :op_exist
        when 'LCTN'; :op_ctn
        when *float_map_ops.keys; float_map_ops[data].op_symbol
        else
          :"op_#{data.downcase.gsub(' ', '_')}"
        end
      end
    end

    class InfixOperator < Operator
      def initialize
        super(name: :infixoperator, pattern: Operators.operator_regex(:infix))
      end

      def infix?
        true
      end
    end

    class PrefixOperator < Operator
      def initialize
        super(name: :prefixoperator, pattern: Operators.operator_regex(:prefix))
      end

      def prefix?
        true
      end
    end

    class PostfixOperator < Operator
      def initialize
        super(name: :postfixoperator, pattern: Operators.operator_regex(:postfix))
      end

      def as_hash(data)
        if data == 'YES' || data == 'NO'
          {yes_no_op: {op_symbol(data) => data}}
        else
          super
        end
      end

      def postfix?
        true
      end
    end

    class Query < Operator
      def initialize
        super(name: :query, pattern: /(?<=\{)(?<subquery>[^{}]+)(?=\{|\})/)
      end

      def as_hash(data)
        _initialize if @sub_query_pattern.nil?
        tokens = Lexer.lex(data, pattern: @sub_query_pattern, available_types: @parts)
        {agg: {op_is: 'IS'}, right: {null_value_type: data.split(' ').last}}
      end

      def expression?
        true
      end

      private
      def _initialize
        @sub_query_fields     = SubQueryFields.new
        @sub_query_type       = SubQueryType.new
        @sub_query_expression = SubQueryExpression.new
        @parts                = [@sub_query_fields, @sub_query_type, @sub_query_expression]
        @sub_query_pattern    = Regexp.compile(@parts.map do |tt|
          "(?<#{tt.name}>#{tt.pattern})"
        end.join('|'))
      end
    end

    class Screen < TokenType
      def initialize
        super(name: :screen, pattern: /\[(screen)(#)(\d+)\]+/)
        trimming!
      end

      def expression?
        true
      end

      def screen?
        true
      end
    end

    class SubQuery < TokenType
      def initialize
        super(name: :lbrace, pattern: /\{/)
      end

      def expression?
        true
      end

      def parse(parser, token, expression: nil)
        new_expression = parser.parse
        if parser.peek&.type == TokenType::SUB_Q_GROUP
          token = parser.consume TokenType::SUB_Q_GROUP
          new_expression.merge!(token.parse(parser, expression: new_expression))
        end

        parser.consume TokenType::RBRACE if parser.peek&.type == TokenType::RBRACE

        if expression.nil?
          next_token = parser.peek
          if next_token && (next_token.and? || next_token.or?)
            {
              lstatement: new_expression,
            }
          else
            new_expression
          end
        else
          expression.merge(new_expression)
        end
      end
    end

    class SubQueryExpression < TokenType
      def initialize
        super(name: :sub_query_expression, pattern: /expression:\s*(?<sub_query_expression>[^\{\}]{5,})\s*,?\s*/)
      end

      def as_hash(data)
        {name => data}
      end

      def parse(parser, token, expression: nil)
        if expression.nil? || expression.keys != %i[agg sub_query_fields sub_query_type]
          as_hash(token.data.strip).merge parser.parse
        else
          expression.merge(as_hash(token.data.strip))
        end
      end
    end

    class SubQueryFields < TokenType
      def initialize
        super(name: :sub_query_fields, pattern: /fields:\s*(?<sub_query_fields>#{FACTOR_PATTERN})\s*,?\s*/)
        trimming!
      end

      def as_hash(data)
        {name => {factor: data}}
      end

      def parse(parser, token, expression: nil)
        if expression.nil? || expression.keys != %i[agg sub_query_expression sub_query_type]
          as_hash(token.data).merge parser.parse
        else
          expression.merge(as_hash(token.data))
        end
      end
    end

    class SubQueryGrouping < TokenType
      def initialize
        super(name: :sub_query_grouping, pattern: /GROUP BY\s+(?<sub_query_grouping>#{FACTOR_PATTERN})/)
        trimming!
      end

      def as_hash(data)
        {name => {factor: data}}
      end

      def parse(parser, token, expression: nil)
        if expression.nil?
          raise "expected GROUP BY to be part of an expression"
        end
        expression.merge(as_hash(token.data))
      end
    end

    class SubQueryType < TokenType
      def initialize
        super(name: :sub_query_type, pattern: /type:\s*(?<sub_query_type>IssuerCase|IssuerPerson|Issuer|Case|Person)\s*,?\s*/)
      end

      def as_hash(data)
        {name => data}
      end

      def parse(parser, token, expression: nil)
        if expression.nil? || expression.keys != %i[agg sub_query_expression sub_query_fields]
          as_hash(token.data).merge parser.parse
        else
          expression.merge(as_hash(token.data))
        end
      end
    end

    class SubQueryCloser < TokenType
      def initialize
        super(name: :rbrace, pattern: /\}/)
      end

      def as_hash(_data)
        Hash.new
      end
    end

    LPAREN           = Group.new
    RPAREN           = new(name: :rparen, pattern: /(?=[^%])\)/)
    LBRACE           = SubQuery.new #new(name: :lbrace, pattern: /\{/)
    RBRACE           = SubQueryCloser.new #(name: :rbrace, pattern: /\}/)
    # TODO: Not used in DataDesk due to some bug. Should we implement and fix?
    # LCAPTURE         = new(name: :lcapture, pattern: /\(%/)
    # RCAPTURE         = new(name: :rcapture, pattern: /%\)/)
    CURRENCY_LITERAL = Currency.new
    INTEGER_LITERAL  = Integer.new
    SCI_NUM_LITERAL  = ScientificNumeric.new
    NUMERIC_LITERAL  = Numeric.new
    STRING_LITERAL   = String.new
    SCREEN           = Screen.new
    FACTOR           = Factor.new
    SPECIAL_MARKER   = SpecialMarker.new
    PREFIXOPERATOR   = PrefixOperator.new
    INFIXOPERATOR    = InfixOperator.new
    POSTFIXOPERATOR  = PostfixOperator.new
    # QUERY            = Query.new
    SUB_Q_EXPR       = SubQueryExpression.new
    SUB_Q_FIELDS     = SubQueryFields.new
    SUB_Q_GROUP      = SubQueryGrouping.new
    SUB_Q_TYPE       = SubQueryType.new
    WHITESPACE       = new(name: :whitespace, pattern: /[\s]/).skipping!

    ALL = [
      LPAREN,
      RPAREN,
      # LCAPTURE,
      # RCAPTURE,
      LBRACE,
      RBRACE,
      SUB_Q_EXPR,
      SUB_Q_FIELDS,
      SUB_Q_TYPE,
      SUB_Q_GROUP,
      CURRENCY_LITERAL,
      SCI_NUM_LITERAL,
      INTEGER_LITERAL,
      NUMERIC_LITERAL,
      STRING_LITERAL,
      SCREEN,
      FACTOR,
      SPECIAL_MARKER,
      PREFIXOPERATOR,
      INFIXOPERATOR,
      POSTFIXOPERATOR,
      # QUERY, # TODO: do we need this?
      WHITESPACE,
    ]
  end
end
