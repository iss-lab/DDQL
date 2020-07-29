describe DDQL::Token do
  context '#to_h' do
    example 'creates a factor hash' do
      token = DDQL::Token.new(data: 'ABC', type: DDQL::TokenType::Factor.new)
      expect(token.to_h).to eq(factor: 'ABC')
    end

    context 'operators' do
      let(:op_token_type) { DDQL::TokenType::Operator.new(name: nil, pattern: nil) }

      {
        '-'                                    => :op_subtract,
        '!='                                   => :op_ne,
        '*'                                    => :op_multiply,
        '/'                                    => :op_divide,
        '%'                                    => :op_mod,
        '^'                                    => :op_power,
        '+'                                    => :op_add,
        '<'                                    => :op_lt,
        '<='                                   => :op_le,
        '='                                    => :op_eq,
        '=='                                   => :op_eq,
        '>'                                    => :op_gt,
        '>='                                   => :op_ge,
        'ALL_GREATER_THAN_FLOAT_MAP'           => :op_float_map_all_gt,
        'ALL_GREATER_THAN_OR_EQUAL_FLOAT_MAP'  => :op_float_map_all_ge,
        'ALL_LESS_THAN_FLOAT_MAP'              => :op_float_map_all_lt,
        'ALL_LESS_THAN_OR_EQUAL_FLOAT_MAP'     => :op_float_map_all_le,
        'ALL_EQUAL_FLOAT_MAP'                  => :op_float_map_all_eq,
        'ALL_MAP'                              => :op_all_map,
        'ALL'                                  => :op_all,
        'ANY_GREATER_THAN_FLOAT_MAP'           => :op_float_map_any_gt,
        'ANY_GREATER_THAN_OR_EQUAL_FLOAT_MAP'  => :op_float_map_any_ge,
        'ANY_LESS_THAN_FLOAT_MAP'              => :op_float_map_any_lt,
        'ANY_LESS_THAN_OR_EQUAL_FLOAT_MAP'     => :op_float_map_any_le,
        'ANY_EQUAL_FLOAT_MAP'                  => :op_float_map_any_eq,
        'ANY_MAP'                              => :op_any_map,
        'ANY'                                  => :op_any,
        'EPRE'                                 => :op_date_before_or_on,
        'EPST'                                 => :op_date_after_or_on,
        'NONE_GREATER_THAN_FLOAT_MAP'          => :op_float_map_none_gt,
        'NONE_GREATER_THAN_OR_EQUAL_FLOAT_MAP' => :op_float_map_none_ge,
        'NONE_LESS_THAN_FLOAT_MAP'             => :op_float_map_none_lt,
        'NONE_LESS_THAN_OR_EQUAL_FLOAT_MAP'    => :op_float_map_none_le,
        'NONE_EQUAL_FLOAT_MAP'                 => :op_float_map_none_eq,
        'NONE_MAP'                             => :op_none_map,
        'NONE'                                 => :op_none,
        'ON'                                   => :op_date_on,
        'PRE'                                  => :op_date_before,
        'PST'                                  => :op_date_after,
      }.each do |key, value|
        example 'creates an operator hash from an infix operation' do
          token = DDQL::Token.new(data: key, type: op_token_type)
          expect(token.to_h).to eq(op: {value => key})
        end
      end

      {
        op_avg: 'AVG',
        op_cnt: 'CNT',
        op_coalesce: 'COALESCE',
        op_exist: 'EXISTS',
        op_max: 'MAX',
        op_med: 'MED',
        op_merge: 'MERGE',
        op_min: 'MIN',
        op_not: 'NOT',
        op_pnt: 'PNT',
        op_ratio: 'RATIO',
        op_sum: 'SUM',
      }.each do |key, value|
        example 'creates an operator hash from a prefix operation' do
          token = DDQL::Token.new(data: value, type: op_token_type)
          expect(token.to_h).to eq(op: {key => value})
        end
      end

      {
        op_yes: "YES",
        op_no: "NO",
        op_is_null: "IS NULL",
        op_is_not_null: "IS NOT NULL",
        op_empty: "EMPTY",
      }.each do |key, value|
        example 'creates an operator hash from a postfix operation' do
          token = DDQL::Token.new(data: value, type: op_token_type)
          expect(token.to_h).to eq(op: {key => value})
        end
      end

      %w[NO_INFORMATION NOT_APPLICABLE NOT_COLLECTED NOT_DISCLOSED NOT_MEANINGFUL].each do |nt|
        example "creates an operator hash from #{nt}" do
          token = DDQL::Token.new(data: "IS #{nt}", type: op_token_type)
          expect(token.to_h).to eq(op: {op_is: 'IS'}, right: {null_value_type: nt})
        end
      end
    end
  end
end
