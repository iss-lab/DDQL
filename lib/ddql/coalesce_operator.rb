module DDQL
  class CoalesceOperator < AggOperator
    def initialize
      super("COALESCE", "Coalesce", return_type: :match)
    end

    def parse(parser, token, expression: nil)
      new_expression = parser.parse(precedence: precedence)
      if expression
        expression = expression.merge(new_expression)
      else
        expression = new_expression
      end

      left_factor, right_factor = expression[:string].split('|', 2)

      {
        op_coalesce: [
          {factor: left_factor},
          {factor: right_factor},
        ]
      }
    end
  end
end
