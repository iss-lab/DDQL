module DDQL
  class Operator
    attr_reader :associativity, :symbol, :name, :type, :precedence, :return_type, :ordinal

    def initialize(symbol, name, type, precedence, right, return_type, ordinal=0)
      @symbol        = symbol
      @name          = name
      @type          = type
      @precedence    = precedence
      @associativity = right ? :right : :left
      @return_type   = return_type
      @ordinal       = ordinal
    end

    def boolean?
      return_type == :boolean
    end

    def comparison?
      (infix? || postfix?) && boolean?
    end

    def complex_comparison?
      comparison? && !simple_comparison?
    end

    def infix?
      @name == :infixoperator || @type == :infix
    end

    def left?
      !right?
    end

    def math?
      math_op?(symbol)
    end

    def parse(parser, token, expression: nil)
      case type
      when :infix; parse_infix(parser, token, expression)
      when :prefix; parse_prefix(parser, token, expression)
      when :postfix; parse_postfix(parser, token, expression)
      else
        raise "unsupported operator type[#{type}]"
      end
    end

    def pattern
      symbol
    end

    def postfix?
      @name == :postfixoperator || @type == :postfix
    end

    def prefix?
      @name == :prefixoperator || @type == :prefix
    end

    def register(hash)
      hash[symbol] = self
      hash
    end

    def right?
      @associativity == :right
    end

    def simple_comparison?
      case symbol
      when "==", "=", "!=", "<=", "<", ">=", ">"
        true
      else
        false
      end
    end

    def type?(incoming)
      type == incoming
    end

    private

    def boolean_stmt(left, op, right)
      # the following avoids unnecessarily deeply nested statements
      while left.key?(:lstatement) && !left.key?(:rstatement)
        left = left[:lstatement]
      end
      while right.key?(:lstatement) && !right.key?(:rstatement)
        right = right[:lstatement]
      end
      {
        lstatement: left,
        boolean_operator: op[:op],
        rstatement: right,
      }
    end

    def math_op?(str)
      case str
      when '+', '-', '*', '/', '%', '^'
        true
      else
        false
      end
    end

    def merged_negation(left, right, op)
      needs_statement_wrapper = lambda do |expr|
        (expr.key?(:lstatement) && expr.key?(:op_not)) || !expr.key?(:lstatement)
      end

      left = {lstatement: left} if needs_statement_wrapper[left]
      right = {rstatement: right} if needs_statement_wrapper[right]
      left.merge(boolean_operator: op[:op]).merge(right)
    end

    def parse_infix(parser, token, expression)
      precedence      = self.precedence
      precedence     -= 1 if right?
      next_expression = parser.parse(precedence: precedence)
      op_expression   = token.as_hash

      if token.and? || token.or?
        return boolean_stmt(expression, op_expression, next_expression)
      end

      if expression.key?(:op_not) || next_expression.key?(:op_not)
        return merged_negation(expression, next_expression, op_expression)
      end

      if next_expression&.key?(:lstatement) && expression&.key?(:lstatement)
        left = expression.merge(boolean_operator: op_expression[:op], rstatement: next_expression[:lstatement])
        return next_expression.key?(:rstatement) ?
          left.merge(
            boolean_operator: next_expression[:boolean_operator][:op],
            rstatement: next_expression[:rstatement]
          ) :
          left
      end

      expression = {left: expression} unless redundant?(expression, :left)
      next_expression = {right: next_expression} unless redundant?(next_expression, :right)
      expression.merge(op_expression).merge(next_expression)
    end

    def parse_postfix(parser, token, expression)
      op_expression = token.as_hash
      if expression && !expression.empty?
        expression = {left: expression} unless expression.key?(:left)
        expression.merge(op_expression)
      else
        op_expression
      end
    end

    def parse_prefix(parser, token, _expression)
      op_expression   = token.type.as_hash(token.data)
      next_expression = parser.parse(precedence: precedence)
      if next_expression.key?(:lstatement) && !next_expression.key?(:rstatement)
        next_expression = next_expression[:lstatement]
      elsif next_expression.key?(:rstatement) && !next_expression.key?(:lstatement)
        next_expression = next_expression[:rstatement]
      end
      op_expression[:op].merge(next_expression)
    end

    def redundant?(expression, *keys)
      expression.keys == keys
    end
  end
end
