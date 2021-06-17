module DDQL
  using StringRefinements

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
  #    +CNT{type:Issuer, fields: [SomeFactor]} / CNT{type:Issuer, fields: [OtherFactor]}+
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
  #    +MAX{type:Case, fields: [SomeFactor]} > 5+
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
  #
  #    +ALIAS{type:Issuer, expression: [SomeFactor] > 5} AS [ThatFactor:That Factor]+
  #
  #      {
  #         agg: {op_max: 'ALIAS'},
  #         sub_query_type: 'Issuer',
  #         sub_query_expression: '[SomeFactor] > 5',
  #         sub_query_alias: {factor: 'ThatFactor', desc: 'That Factor'},
  #      }
  class AggOperator < Operator
    using BlankRefinements

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
      if parser.peek&.supports_post_processing?
        token, expression = parser.peek.post_process(parser: parser, expression: expression)
      end
      as_agg(expression)
    end

    def as_left_op_right(expression)
      new_expression = {
        agg: expression.delete(:agg),
        sub_query_type: expression.delete(:sub_query_type),
        sub_query_fields: expression.delete(:sub_query_fields),
        sub_query_expression: expression.delete(:sub_query_expression),
      }.compact

      if expression[:lstatement].key?(:op) && expression[:lstatement][:left].blank?
        {
          left: new_expression,
          op: expression[:lstatement][:op],
          right: expression[:lstatement][:right],
        }
      elsif expression[:lstatement].key?(:lstatement)
        if expression[:lstatement][:lstatement].empty?
          expression[:lstatement][:lstatement] = new_expression
          expression[:lstatement]
        else
          final_expression = expression[:lstatement]
          final_expression[:lstatement][:left] = new_expression
          final_expression
        end
      else
        new_expression
      end
    end

    def as_agg(expr)
      expression = expr.dup
      if expression.key?(:yes_no_op)
        # AGG Y/N
        yes_no_op = expression.delete(:yes_no_op)
        {
          left: expression,
          yes_no_op: yes_no_op,
        }
      elsif expression.key?(:op)
        # AGG COMP LIT
        expression.delete(:left)
        op = expression.delete(:op)
        right = expression.delete(:right)
        {
          left: expression,
          op: op,
          right: right,
        }
      elsif expression.key?(:boolean_operator)
        # AGG BOOL STMT
        bool_op = expression.delete(:boolean_operator)
        rstatement = expression.delete(:rstatement)
        {
          lstatement: as_left_op_right(expression),
          boolean_operator: bool_op,
          rstatement: rstatement,
        }
      else
        expression
      end
    end
  end
end
