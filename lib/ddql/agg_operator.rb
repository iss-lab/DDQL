module DDQL
  # +AggOperators+ return a Hash structure describing the type of aggregation, an optional
  # expression (filter) to apply, an optional factor (field) against which the aggregation
  # is applied, and the entity type for which the aggregation is applicable.
  #
  # ==== Examples
  #    +SUM {type: IssuerPerson, fields: [SomeFactor], expression: [OtherFactor] == 'Value'}+
  #
  #      {
  #        agg: {op_sum: 'SUM'},
  #        sub_query_expression: "[OtherFactor] == 'Value'",
  #        sub_query_fields: 'SomeFactor',
  #        sub_query_type: 'IssuerPerson',
  #      }
  #
  #    +CNT{type:Issuer, expression: [SomeFactor]} / CNT{type:Issuer, expression: [OtherFactor]}+
  #
  #      {
  #        left: {
  #           agg: {op_cnt: 'CNT'},
  #           sub_query_fields: 'SomeFactor',
  #           sub_query_type: 'Issuer',
  #        },
  #        op: {op_divide: '/'},
  #        right: {
  #           agg: {op_cnt: 'CNT'},
  #           sub_query_fields: 'OtherFactor',
  #           sub_query_type: 'Issuer',
  #        },
  #      }
  #
  #    +MAX{type:Case, expression: [SomeFactor]} > 5+
  #
  #      {
  #        left: {
  #           agg: {op_max: 'MAX'},
  #           sub_query_fields: 'SomeFactor',
  #           sub_query_type: 'Case',
  #        },
  #        op: {op_gt: '>'},
  #        right: {int: 5},
  #      }
  class AggOperator < Operator
    def initialize(symbol, name, return_type:, type: :prefix, precedence: 8, right: false)
      super(symbol, name, type, precedence, right, return_type)
    end

    def parse(parser, token, expression: nil)
      new_expression = parser.parse(precedence: precedence)
      if expression
        expression = expression.merge(new_expression)
      else
        expression = new_expression
      end
      expression.merge!(agg: {:"op_#{symbol.downcase}" => symbol})

      if expression.key?(:op) && expression.key?(:right)
        if expression[:left]&.empty?
          expression.delete :left
        end
        op = expression.delete :op
        right = expression.delete :right
        {
          left: expression,
          op: op,
          right: right,
        }
      elsif expression.key?(:yes_no_op)
        yes_no = expression.delete :yes_no_op
        {
          left: expression,
          yes_no_op: yes_no,
        }
      else
        expression
      end
    end
  end
end
