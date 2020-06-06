module DDQL
  class Parser < Parslet::Parser
    # comparison constants
    rule(:eq)   { (str('==') | str('=')) }
    rule(:ge)   { str('>=') }
    rule(:gt)   { str('>') }
    rule(:is)   { str('IS') }
    rule(:isnt) { str('IS NOT') }
    rule(:le)   { str('<=') }
    rule(:lt)   { str('<') }
    rule(:ne)   { str('!=') }
    rule(:no)   { str('NO') }
    rule(:null) { str('NULL') }
    rule(:yes)  { str('YES') }

    # constants
    rule(:comma)    { str(',') }
    rule(:digit)    { match('[0-9]') }
    rule(:group_by) { str('GROUP BY') }
    rule(:spaces)   { match('\s').repeat(1) }
    rule(:spaces?)  { spaces.maybe }
    rule(:tick)     { str("'") }
    rule(:string)   { (tick >> (tick.absent? >> any).repeat.as(:string) >> tick) }

    # brackets
    rule(:lbracket)  { str('[') }
    rule(:lparen)    { spaces? >> str('(') >> spaces? }
    rule(:lsquiggly) { spaces? >> str('{') >> spaces? }
    rule(:rbracket)  { str(']') }
    rule(:rparen)    { spaces? >> str(')') >> spaces? }
    rule(:rsquiggly) { spaces? >> str('}') >> spaces? }

    # math ops
    rule(:math_add)      { str('+').as(:op_add) }
    rule(:math_subtract) { str('-').as(:op_subtract) }
    rule(:math_multiply) { str('*').as(:op_multiply) }
    rule(:math_divide)   { str('/').as(:op_divide) }
    rule(:math_mod)      { str('%').as(:op_mod) }
    rule(:math_power)    { str('^').as(:op_power) }
    rule(:math_operation) do
      math_add | math_subtract | math_multiply | math_divide | math_mod | math_power
    end

    # boolean operators
    rule(:bool_not)     { spaces? >> str('NOT').as(:op_not) >> spaces? }
    rule(:or_operator)  { spaces? >> str('OR').as(:op_or) >> spaces? }
    rule(:and_operator) { spaces? >> str('AND').as(:op_and) >> spaces? }

    # string operators
    rule(:ctn_operator) { spaces? >> (str('CTN') | str('LCTN')).as(:op_ctn) >> spaces? }
    rule(:stw_operator) { spaces? >> str('STW').as(:op_stw) >> spaces? }

    # date operators
    rule(:date_on_operator)           { spaces? >> str('ON').as(:op_date_on) >> spaces? }
    rule(:date_after_operator)        { spaces? >> str('PST').as(:op_date_after) >> spaces? }
    rule(:date_after_operator_or_on)  { spaces? >> str('EPST').as(:op_date_after_or_on) >> spaces? }
    rule(:date_before_operator)       { spaces? >> str('PRE').as(:op_date_before) >> spaces? }
    rule(:date_before_operator_or_on) { spaces? >> str('EPRE').as(:op_date_before_or_on) >> spaces? }

    # currency support
    rule(:currency_code) { match('[A-Z]').repeat(3) }
    rule(:currency) do
      tick.maybe >>
        (
          tick.absent? >>
          currency_code.as(:currency_code) >>
          str(':') >>
          (float_numeric | int_numeric).as(:currency_value)
        ) >>
        tick.maybe
    end

    # numbers
    rule(:float_numeric) do
      (str('-').maybe >> (
              str('0') | (match('[1-9]') >> digit.repeat)
            ) >> (
              str('.') >> digit.repeat(1)
            ) >> (
              match('[eE]') >> (str('+') | str('-')).maybe >> digit.repeat(1)
            ).maybe
      ).as(:float)
    end
    rule(:float) do
      (tick.maybe >> (tick.absent? >> float_numeric >> tick)) | float_numeric
    end
    rule(:int_numeric) { (str('-').maybe >> digit.repeat(1)).as(:int) }
    rule(:int) do
      (tick.maybe >> (tick.absent? >> int_numeric >> tick)) | int_numeric
    end

    # special markers
    rule(:current_date)           { str('$CURRENT_DATE').as(:current_date) }
    rule(:current_quarter)        { str('$CURRENT_QUARTER').as(:current_quarter) }
    rule(:current_year)           { str('$CURRENT_YEAR').as(:current_year) }
    rule(:relative_end_date)      { str('$END_DATE').as(:relative_end_date) }
    rule(:relative_end_quarter)   { str('$END_QUARTER').as(:relative_end_quarter) }
    rule(:relative_end_year)      { str('$END_YEAR').as(:relative_end_year) }
    rule(:relative_start_date)    { str('$START_DATE').as(:relative_start_date) }
    rule(:relative_start_quarter) { str('$START_QUARTER').as(:relative_start_quarter) }
    rule(:relative_start_year)    { str('$START_YEAR').as(:relative_start_year) }
    rule(:special_marker)  do
      (
        current_year | current_date | current_quarter |
        relative_end_date | relative_end_quarter | relative_end_year |
        relative_start_date | relative_start_quarter | relative_start_year
      ).as(:special_marker)
    end

    # nulls
    rule(:null_no_information) { str('NO_INFORMATION') }
    rule(:null_not_applicable) { str('NOT_APPLICABLE') }
    rule(:null_not_collected)  { str('NOT_COLLECTED') }
    rule(:null_not_disclosed)  { str('NOT_DISCLOSED') }
    rule(:null_not_meaningful) { str('NOT_MEANINGFUL') }
    rule(:null_value_type) do
      (
        null_no_information |
        null_not_applicable |
        null_not_collected  |
        null_not_disclosed  |
        null_not_meaningful
      ).as(:null_value_type)
    end

    # array operators
    rule(:arrays_all_operator)  { str('ALL').as(:op_all) }
    rule(:arrays_any_operator)  { str('ANY').as(:op_any) }
    rule(:arrays_in_operator)   { str('IN').as(:op_in) }
    rule(:arrays_none_operator) { str('NONE').as(:op_none) }
    rule(:arrays_operator) do
      arrays_all_operator | arrays_any_operator | arrays_in_operator | arrays_none_operator
    end

    # comparison operators
    rule(:boolean_operator)     { or_operator | and_operator }
    rule(:date_rel_operator)    { date_on_operator | date_after_operator | date_after_operator_or_on | date_before_operator | date_before_operator_or_on }
    rule(:eq_operator)          { eq.as(:op_eq) }
    rule(:ge_operator)          { ge.as(:op_ge) }
    rule(:gt_operator)          { gt.as(:op_gt) }
    rule(:is_not_null_operator) { (isnt >> spaces >> null).as(:op_is_not_null) }
    rule(:is_null_operator)     { (is >> spaces >> null).as(:op_is_null) }
    rule(:is_operator)          { is.as(:op_is) }
    rule(:le_operator)          { le.as(:op_le) }
    rule(:lt_operator)          { lt.as(:op_lt) }
    rule(:ne_operator)          { ne.as(:op_ne) }
    rule(:no_operator)          { no.as(:op_no) }
    rule(:relational_operator)  { eq_operator | le_operator | ge_operator | lt_operator | gt_operator | ne_operator }
    rule(:string_rel_operator)  { ctn_operator | stw_operator }
    rule(:yes_operator)         { yes.as(:op_yes) }

    # aggregations
    rule(:avg_operator) { str('AVG').as(:op_avg) }
    rule(:cnt_operator) { str('CNT').as(:op_cnt) }
    rule(:ext_operator) { str('EXISTS').as(:op_exist) }
    rule(:max_operator) { str('MAX').as(:op_max) }
    rule(:med_operator) { str('MED').as(:op_med) }
    rule(:min_operator) { str('MIN').as(:op_min) }
    rule(:sum_operator) { str('SUM').as(:op_sum) }
    rule(:grouping_operator) { (max_operator | min_operator).as(:agg) }
    rule(:agg_operator) do
      (avg_operator | cnt_operator | ext_operator | med_operator | sum_operator).as(:agg)
    end
    rule(:aggregation_operator) do
      # Examples:
      #   CNT {type: IssuerCase, fields: [], expression: ([CaseFlag] == 'Amber' AND [CaseFlag] == 'RED' AND [CaseFlag] == 'Green')} >= '0'
      #   CNT {type: IssuerPerson, expression: [ipAssociationType] == 'Director'}
      (agg_operator >>
        lsquiggly >>
        (rsquiggly.absent? >> any).repeat(1).as(:sub_query_info) >>
        rsquiggly >>
        relational_operator.as(:op) >>
        value.as(:right)
      ) | (agg_operator >>
        lsquiggly >>
        (rsquiggly.absent? >> any).repeat(1).as(:sub_query_info) >>
        rsquiggly
      ) | (grouping_operator >>
        lsquiggly >>
        (rsquiggly.absent? >> any).repeat(1).as(:sub_query_info) >>
        rsquiggly >>
        spaces? >>
        group_by >>
        spaces? >>
        factor.as(:group_by)
      )
    end

    # sub-queries
    rule(:sub_query_type) do
      spaces? >> str('type:') >> spaces? >> (str('IssuerCase') | str('IssuerPerson') | str('Issuer')).as(:type) >> spaces?
    end
    rule(:sub_query_fields) do
      spaces? >> str('fields:') >> spaces? >> (factor | (lbracket >> spaces?.as(:factor) >> rbracket)).as(:fields) >> spaces?
    end
    rule(:sub_query_qualifier) do
      spaces? >> str('qualifier:') >> spaces? >> string.as(:assoc_qualifier)
    end
    rule(:sub_query_expression) do
      spaces? >> str('expression:') >> spaces? >> top.as(:expression)
    end
    rule(:sub_query_info_parsing) do
      (sub_query_type >> (comma >> sub_query_qualifier).maybe >> comma >> sub_query_expression >> comma >> sub_query_fields) |
        (sub_query_type >> (comma >> sub_query_qualifier).maybe >> comma >> sub_query_expression >> comma.absent?) |
        (sub_query_type >> (comma >> sub_query_qualifier).maybe >> comma >> (sub_query_fields >> comma).maybe >> sub_query_expression) |
        (sub_query_fields >> comma >> sub_query_type >> (comma >> sub_query_qualifier).maybe >> comma >> sub_query_expression) |
        (sub_query_fields >> comma >> sub_query_expression >> comma >> sub_query_type >> (comma >> sub_query_qualifier).maybe) |
        (sub_query_expression >> comma >> sub_query_type >> (comma >> sub_query_qualifier).maybe >> (comma >> sub_query_fields).maybe) |
        (sub_query_expression >> comma >> (sub_query_fields >> comma).maybe >> sub_query_type >> (comma >> sub_query_qualifier).maybe) |
        (sub_query_type >> comma >> sub_query_fields) | # for MIN/MAX {...} GROUP BY [...]
        (sub_query_fields >> comma >> sub_query_type)   # for MIN/MAX {...} GROUP BY [...]
    end

    # higher-level definitions
    rule(:operator) do
      (relational_operator | arrays_operator).as(:op)
    end

    rule(:factor) do
      lbracket >> (
        match('[_0-9a-zA-Z&]').repeat(1).as(:factor)
      ) >> rbracket
    end

    rule(:val) do
      (currency | float | int | special_marker | string)
    end

    rule(:value) do
      spaces? >> (val | factor) >> spaces?
    end

    rule(:math_operand) do
      spaces? >> (special_marker | float | int | factor | aggregation_operator) >> spaces?
    end

    rule(:equation) do
      (math_operand.as(:left) >> spaces? >> math_operation >> spaces? >> math_operand.as(:right)) |
        (math_operand.as(:left) >> spaces? >> math_operation >> spaces? >> equation.as(:right)) #|
    end

    rule(:factor_comparison) do
      (factor.as(:left) >> spaces >> is_not_null_operator.as(:op)) |
        (factor.as(:left) >> spaces >> is_null_operator.as(:op)) |
        (factor.as(:left) >> spaces >> is_operator.as(:op) >> spaces >> null_value_type.as(:right)) |
        (value.as(:left) >> operator >> value.as(:right)) |
        (factor.as(:left) >> (string_rel_operator | date_rel_operator).as(:op) >> string.as(:right)) |
        (factor.as(:left) >> spaces? >> (no_operator | yes_operator).as(:yes_no_op))
    end

    rule(:entity) do
      equation |
      sub_query_info_parsing |
      (
        bool_not.maybe >> (
          (lparen >> entity >> rparen) |
            aggregation_operator |
            (factor_comparison) |
            factor.as(:value_of) |
            special_marker |
            top
        )
      )
    end

    rule(:statement) do
      spaces? >> (
        (lparen >> spaces? >> (top | entity | factor) >> spaces? >> rparen) |
          entity
      ) >> spaces?
    end

    rule(:top) do
      (statement.as(:lstatement) >> (boolean_operator.as(:boolean_operator) >> top.as(:rstatement))) |
        (statement.as(:lstatement) >> (math_operation.as(:math_operation) >> top.as(:rstatement))) |
        (statement.as(:lstatement) >> (operator.as(:operator) >> top.as(:rstatement))) |
        statement
    end

    root(:top)
  end
end