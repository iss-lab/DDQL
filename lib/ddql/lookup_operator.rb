require_relative 'agg_operator'

module DDQL
  class LookupOperator < AggOperator
    def initialize
      super("LOOKUP BY", "Lookup", type: :infix, return_type: :string)
    end

    def parse(parser, _token, expression: nil)
      precedence      = self.precedence
      precedence     -= 1 if right?
      next_expression = parser.parse(precedence: precedence)

      foreign_value_factor = expression[:factor]
      foreign_key_factor = (next_expression.delete(:left) || next_expression)[:factor]
      {
        op_lookup_by: {
          foreign_key: {factor: foreign_key_factor},
          foreign_value: {factor: foreign_value_factor},
        },
      }
    end
  end
end
