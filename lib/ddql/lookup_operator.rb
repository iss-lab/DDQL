require_relative 'agg_operator'

module DDQL
  class LookupOperator < AggOperator
    def initialize
      super("LOOKUP BY", "Lookup", type: :infix, return_type: :string)
    end

    def parse(parser, token, expression: nil)
      precedence      = self.precedence
      precedence     -= 1 if right?
      next_expression = parser.parse(precedence: precedence)
      op_expression   = token.as_hash
      
      {
        left: expression,
        op: op_expression[:op],
        right: next_expression.delete(:left) || next_expression,
      }
    end
  end
end
