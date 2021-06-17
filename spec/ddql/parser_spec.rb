describe DDQL::Parser do
  using ::DDQL::StringRefinements

  let(:parser) { described_class.from_tokens DDQL::Lexer.lex expr }

  context 'Regressions' do
    context 'Aggregation with multi-part boolean expression' do
      context 'with wrapping' do
        let(:expr)     { "CNT {type: IssuerPerson, fields: [], expression: ([PowGenRevShareMax] >= '0.5')} > '0' AND (([ipAssociationType] == 'Director') AND ([issuer_id] == '15'))" }
        let(:expected) {{
          lstatement: {
            left: {
              agg: { op_cnt: 'CNT' },
              sub_query_expression: "([PowGenRevShareMax] >= '0.5')",
              sub_query_type: 'IssuerPerson',
            },
            op: { op_gt: '>' },
            right: { int: 0 },
          },
          boolean_operator: {op_and: 'AND'},
          rstatement: {
            lstatement: {
              left: { factor: 'ipAssociationType' },
              op: { op_eq: '==' },
              right: { string: 'Director' },
            },
            boolean_operator: {op_and: 'AND'},
            rstatement: {
              left: { factor: 'issuer_id' },
              op: { op_eq: '==' },
              right: { int: 15 },
            },
          },
        }}
        it { expect(parser.parse).to eq expected }
      end

      context 'without wrapping' do
        let(:expr) { "CNT {type: IssuerPerson, fields: [], expression: ([PowGenRevShareMax] >= '0.5')} > '0' AND ([ipAssociationType] == 'Director') AND ([issuer_id] == '15')" }
        let(:expected) {{
          lstatement: {
            lstatement: {
              left: {
                agg: { op_cnt: 'CNT' },
                sub_query_expression: "([PowGenRevShareMax] >= '0.5')",
                sub_query_type: 'IssuerPerson',
              },
              op: { op_gt: '>' },
              right: { int: 0 },
            },
            boolean_operator: {op_and: 'AND'},
            rstatement: {
              left: { factor: 'ipAssociationType' },
              op: { op_eq: '==' },
              right: { string: 'Director' },
            },
          },
          boolean_operator: {op_and: 'AND'},
          rstatement: {
            left: { factor: 'issuer_id' },
            op: { op_eq: '==' },
            right: { int: 15 },
          },
        }}
        it { expect(parser.parse).to eq expected }
      end
    end

    context 'DD-6806' do
      let(:expr) {
        "(
           [ClimateScienceBasedTargets] != 'Committed'
           AND [ClimateScienceBasedTargets] != 'Concrete Target'
           AND [CarbonRRGHGTargetPlansGrade] < '1.5'
           AND [CarbonRRRiskClass] < '2'
           AND [CarbonRRPerformanceScore] < '1.5'
           AND (
             [ClimateTotalEmissionsIntUSD] / [ClimateAvePeerEmissionsIntUSD] > '1.2'
           )
         )"
      }
      let(:expected) {{
        :boolean_operator=>{:op_and=>"AND"},
        :lstatement=>{
          :boolean_operator=>{:op_and=>"AND"},
          :lstatement=>{
            :boolean_operator=>{:op_and=>"AND"},
            :lstatement=>{
              :boolean_operator=>{:op_and=>"AND"},
              :lstatement=>{
                :boolean_operator=>{:op_and=>"AND"},
                :lstatement=>{
                  :left=>{:factor=>"ClimateScienceBasedTargets"},
                  :op=>{:op_ne=>"!="},
                  :right=>{:string=>"Committed"},
                },
                :rstatement=>{
                  :left=>{:factor=>"ClimateScienceBasedTargets"},
                  :op=>{:op_ne=>"!="},
                  :right=>{:string=>"Concrete Target"},
                },
              },
              :rstatement=>{
                :left=>{:factor=>"CarbonRRGHGTargetPlansGrade"},
                :op=>{:op_lt=>"<"},
                :right=>{:float=>1.5},
              },
            },
            :rstatement=>{
              :left=>{:factor=>"CarbonRRRiskClass"},
              :op=>{:op_lt=>"<"},
              :right=>{:int=>2},
            },
          },
          :rstatement=>{
            :left=>{:factor=>"CarbonRRPerformanceScore"},
            :op=>{:op_lt=>"<"},
            :right=>{:float=>1.5},
          },
        },
        :rstatement=>{
          :left=>{
            :left=>{:factor=>"ClimateTotalEmissionsIntUSD"},
            :op=>{:op_divide=>"/"},
            :right=>{:factor=>"ClimateAvePeerEmissionsIntUSD"},
          },
          :op=>{:op_gt=>">"},
          :right=>{:float=>1.2}
        }
      }}
      it { expect(parser.parse).to eq expected }
    end
  end

  context 'COALESCE' do
    let(:a_factor) { 'ViolentVideoGamesInvolvementFund' }
    let(:b_factor) { 'ViolentVideoGamesInvolvement' }
    let(:sub_expr) { "COALESCE '#{a_factor}|#{b_factor}'" }

    context 'with comparison' do
      let(:expr)     { "#{sub_expr} ANY 'Production'" }
      let(:expected) {{
        left: {
          op_coalesce: [
            {factor: a_factor},
            {factor: b_factor},
          ],
        },
        op: {op_any: 'ANY'},
        right: {string: 'Production'},
      }}
      it { expect(parser.parse).to eq expected }
    end

    context 'without comparison' do
      let(:expr)     { sub_expr }
      let(:expected) {{
        op_coalesce: [
          {factor: a_factor},
          {factor: b_factor},
        ],
      }}
      it { expect(parser.parse).to eq expected }
    end
  end

  context 'LOOKUP BY' do
    let(:key_factor) { 'ESGRatingParentEntityID' }
    let(:str_factor) { 'IssuerName' }
    let(:sub_expr)   { "[#{str_factor}] LOOKUP BY [#{key_factor}]" }

    context 'with comparison' do
      let(:expr)     { "#{sub_expr} = 'Acme Corp.'" }
      let(:expected) {{
        left: {
          op_lookup_by: {
            foreign_key: {factor: key_factor},
            foreign_value: {factor: str_factor},
          }
        },
        op: {
          op_eq: '=',
        },
        right: {
          string: 'Acme Corp.',
        },
      }}
      it { expect(parser.parse).to eq expected }
    end

    context 'without comparison' do
      let(:expr)     { sub_expr }
      let(:expected) {{
        op_lookup_by: {
          foreign_key: {factor: key_factor},
          foreign_value: {factor: str_factor},
        }
      }}
      it { expect(parser.parse).to eq expected }
    end
  end

  context 'boolean expressions' do
    context 'simple AND' do
      let(:expr)     { "[foo] = '1' AND [bar] != '2'" }
      let(:parsed)   { described_class.parse(expr) }
      let(:expected) {{
        boolean_operator: {op_and: "AND"},
        lstatement: {
          left: {factor: "foo"},
          op: {op_eq: "="},
          right: {int: 1},
        },
        rstatement: {
          left: {factor: "bar"},
          op: {op_ne: "!="},
          right: {int: 2},
        },
      }}
      it { expect(parsed).to eq expected }
    end

    context 'simple OR' do
      let(:expr)     { "[foo] = '1' OR [bar] != '2'" }
      let(:parsed)   { described_class.parse(expr) }
      let(:expected) {{
        boolean_operator: {op_or: "OR"},
        lstatement: {
          left: {factor: "foo"},
          op: {op_eq: "="},
          right: {int: 1},
        },
        rstatement: {
          left: {factor: "bar"},
          op: {op_ne: "!="},
          right: {int: 2},
        },
      }}
      it { expect(parsed).to eq expected }

      context 'case insensitive' do
        let(:expr) { "[foo] = '1' or [bar] != '2'" }
        it 'should be case-insensitive' do
          pending 'Unsupported operation'
          expect(parsed).to eq expected
        end
      end
    end

    context 'nested negates' do
      context 'even' do
        let(:expr) { "NOT NOT NOT NOT [foo] = '1'" }
        let(:parsed) { described_class.parse(expr) }
        let(:expected) {{
          left: {factor: 'foo'},
          op: {op_eq: '='},
          right: {int: 1},
        }}
        it { expect(parsed).to eq expected }
      end
      context 'odd' do
        let(:expr) { "NOT NOT NOT NOT NOT [foo] = '1'" }
        let(:parsed) { described_class.parse(expr) }
        let(:expected) {{
          op_not: 'NOT',
          left: {factor: 'foo'},
          op: {op_eq: '='},
          right: {int: 1},
        }}
        it { expect(parsed).to eq expected }
      end
      context 'yes/no even' do
        let(:expr) { "NOT NOT NOT NOT NOT NOT [foo] NO" }
        let(:parsed) { described_class.parse(expr) }
        let(:expected) {{
          left: {factor: 'foo'},
          yes_no_op: {op_no: 'NO'},
        }}
        it { expect(parsed).to eq expected }
      end
      context 'yes/no odd' do
        let(:expr) { "NOT NOT NOT NOT NOT [foo] YES" }
        let(:parsed) { described_class.parse(expr) }
        let(:expected) {{
          op_not: 'NOT',
          left: {factor: 'foo'},
          yes_no_op: {op_yes: 'YES'},
        }}
        it { expect(parsed).to eq expected }
      end
    end

    context 'negated left comparison with parens' do
      let(:expr)     { "NOT([foo] = '1') AND [bar] = '2'" }
      let(:parsed)   { described_class.parse(expr) }
      let(:expected) {{
        lstatement: {
          op_not: 'NOT',
          left: {factor: 'foo'},
          op: {op_eq: '='},
          right: {int: 1},
        },
        boolean_operator: {op_and: 'AND'},
        rstatement: {
          left: {factor: 'bar'},
          op: {op_eq: '='},
          right: {int: 2},
        },
      }}

      it { expect(parsed).to eq expected }
    end

    context 'negated parenthetical expression' do
      let(:expr)     { "NOT([foo] = '1' AND [bar] = '2')" }
      let(:parsed)   { described_class.parse(expr) }
      let(:expected) {{
        op_not: 'NOT',
        lstatement: {
          left: {factor: 'foo'},
          op: {op_eq: '='},
          right: {int: 1},
        },
        boolean_operator: {op_and: 'AND'},
        rstatement: {
          left: {factor: 'bar'},
          op: {op_eq: '='},
          right: {int: 2},
        },
      }}

      it { expect(parsed).to eq expected }
    end

    context 'negated right comparison' do
      let(:expr)     { "([foo] = '1') AND NOT ([bar] = '2')" }
      let(:parsed)   { described_class.parse(expr) }
      let(:expected) {{
        lstatement: {
          left: {factor: 'foo'},
          op: {op_eq: '='},
          right: {int: 1},
        },
        boolean_operator: {op_and: 'AND'},
        rstatement: {
          op_not: 'NOT',
          left: {factor: 'bar'},
          op: {op_eq: '='},
          right: {int: 2},
        },
      }}
      it { expect(parsed).to eq expected }
    end

    context 'negated phrase' do
      let(:expr)     { "([foo] = '1') AND NOT ([bar] = '2' OR [baz] = '3')" }
      let(:parsed)   { described_class.parse(expr) }
      let(:expected) {{
        lstatement: {
          left: {factor: 'foo'},
          op: {op_eq: '='},
          right: {int: 1},
        },
        boolean_operator: {op_and: 'AND'},
        rstatement: {
          op_not: 'NOT',
          lstatement: {
            left: {factor: 'bar'},
            op: {op_eq: '='},
            right: {int: 2},
          },
          boolean_operator: {op_or: 'OR'},
          rstatement: {
            left: {factor: 'baz'},
            op: {op_eq: '='},
            right: {int: 3},
          },
        },
      }}
      it { expect(parsed).to eq expected }
    end

    context 'single paren clause' do
      let(:expr)     { "([foo] = '1') AND [bar] != '2'" }
      let(:parsed)   { described_class.parse(expr) }
      let(:expected) {{
        boolean_operator: {op_and: "AND"},
        lstatement: {
          left: {factor: "foo"},
          op: {op_eq: "="},
          right: {int: 1},
        },
        rstatement: {
          left: {factor: "bar"},
          op: {op_ne: "!="},
          right: {int: 2},
        }
      }}
      it { expect(parsed).to eq expected }
    end

    context 'extraneous parens' do
      let(:expr)     { "((( [foo] = '1.7' AND [bar] != '3.5' ) ) )" }
      let(:parsed)   { described_class.parse(expr) }
      let(:expected) {{
        boolean_operator: {op_and: "AND"},
        lstatement: {
          left: {factor: "foo"},
          op: {op_eq: "="},
          right: {float: 1.7},
        },
        rstatement: {
          left: {factor: "bar"},
          op: {op_ne: "!="},
          right: {float: 3.5},
        },
      }}
      it { expect(parsed).to eq expected }
    end

    context 'array operators =>' do
      {
        'ALL'   => :op_all,
        'ANY'   => :op_any,
        'EMPTY' => :op_empty,
        'IN'    => :op_in,
        'NONE'  => :op_none,
      }.each do |op, op_name|
        expression_structs = [
          {expr: "[ABCDEF_GHIJK] #{op}#{op_name == :op_empty ? '' : " '1|2|3|4'"}",                   right: '1|2|3|4'},
          {expr: "  [ABCDEF_GHIJK]     #{op}#{op_name == :op_empty ? '' : "   '5|6|7|8'      "}",     right: '5|6|7|8'},
          {expr: "([ABCDEF_GHIJK] #{op}#{op_name == :op_empty ? '' : " '2|4|6'"})",                   right: '2|4|6'},
          {expr: "  ([ABCDEF_GHIJK]   #{op}#{op_name == :op_empty ? '' : " 'a10'"} )    ",            right: 'a10'},
          {expr: "((([ABCDEF_GHIJK] #{op}#{op_name == :op_empty ? '' : " 'Production|Services'"})))", right: 'Production|Services'},
        ]

        expression_structs.each do |struct|
          example struct[:expr] do
            expected = {
              left: {factor: 'ABCDEF_GHIJK'},
              op: {op_name => op},
              right: {string: struct[:right]},
            }
            expected.delete(:right) if op_name == :op_empty # this is a postfix operation
            expect(described_class.parse(struct[:expr])).to eq expected
          end
        end
      end
    end

    context 'relational operators =>' do
      {
        '>'  => :op_gt,
        '>=' => :op_ge,
        '<'  => :op_lt,
        '<=' => :op_le,
        '='  => :op_eq,
        '!=' => :op_ne,
      }.each do |op, op_name|
        expression_structs = [
          {expr: "  ([foo]   #{op} '2.0' )    ", left:  {factor: 'foo'}, right: {float: 2.0}},
          {expr: "  ([foo] #{op} 'a2.0' )    ",  left:  {factor: 'foo'}, right: {string: 'a2.0'}},
          {expr: "  ('2.0'   #{op} [foo])    ",  right: {factor: 'foo'}, left:  {float: 2.0}},
          {expr: "  ('a2.0' #{op} [foo])    ",   right: {factor: 'foo'}, left:  {string: 'a2.0'}},
        ]

        expression_structs.each do |struct|
          example struct[:expr] do
            expected = {
              left: struct[:left],
              op: {op_name => op},
              right: struct[:right],
            }
            expect(described_class.parse(struct[:expr])).to eq expected
          end
        end
      end
    end

    context 'IS operator =>' do
      %w[NO_INFORMATION NOT_APPLICABLE NOT_COLLECTED NOT_DISCLOSED NOT_MEANINGFUL].each do |null_type|
        [
          "[bar] IS #{null_type}",
          "  [bar]  IS  #{null_type}  ",
          "([bar] IS #{null_type})",
          "   ([bar]    IS  #{null_type})  ",
        ].each do |expr|
          example expr do
            expected = {
              left: {factor: 'bar'},
              op: {op_is: 'IS'},
              right: {null_value_type: null_type},
            }
            expect(described_class.parse(expr)).to eq expected
          end
        end
      end
    end

    context 'IS NULL' do
      let(:expected) {{
        left: {factor: 'end_date'},
        op: {op_is_null: 'IS NULL'},
      }}
      it { expect(described_class.parse('[end_date] IS NULL')).to eq expected }
    end

    context 'IS NOT NULL' do
      let(:expected) {{
        left: {factor: 'baz'},
        op: {op_is_not_null: 'IS NOT NULL'},
      }}
      it { expect(described_class.parse('[baz] IS NOT NULL')).to eq expected }
    end

    context 'string relational operators' do
      {
        'CTN'  => :op_ctn,
        'LCTN' => :op_ctn,
        'STW'  => :op_stw,
      }.each do |op, op_name|
        context op do
          [
            {expr: "[foo] #{op} 'bar'", left: 'foo', right: 'bar'},
            {expr: "[blat] #{op} 'bar  baz'", left: 'blat', right: 'bar  baz'},
          ].each do |struct|
            example struct[:expr] do
              expected = {
                left: {factor: struct[:left]},
                op: {op_name => op},
                right: {string: struct[:right]}
              }
              expect(described_class.parse(struct[:expr])).to eq expected
            end
          end
        end
      end
    end

    context 'float map operators' do
      {
        'ANY_GREATER_THAN_FLOAT_MAP'           => :op_float_map_any_gt,
        'ALL_GREATER_THAN_FLOAT_MAP'           => :op_float_map_all_gt,
        'NONE_GREATER_THAN_FLOAT_MAP'          => :op_float_map_none_gt,
        'ANY_GREATER_THAN_OR_EQUAL_FLOAT_MAP'  => :op_float_map_any_ge,
        'ALL_GREATER_THAN_OR_EQUAL_FLOAT_MAP'  => :op_float_map_all_ge,
        'NONE_GREATER_THAN_OR_EQUAL_FLOAT_MAP' => :op_float_map_none_ge,
        'ANY_LESS_THAN_FLOAT_MAP'              => :op_float_map_any_lt,
        'ALL_LESS_THAN_FLOAT_MAP'              => :op_float_map_all_lt,
        'NONE_LESS_THAN_FLOAT_MAP'             => :op_float_map_none_lt,
        'ANY_LESS_THAN_OR_EQUAL_FLOAT_MAP'     => :op_float_map_any_le,
        'ALL_LESS_THAN_OR_EQUAL_FLOAT_MAP'     => :op_float_map_all_le,
        'NONE_LESS_THAN_OR_EQUAL_FLOAT_MAP'    => :op_float_map_none_le,
        'ANY_EQUAL_FLOAT_MAP'                  => :op_float_map_any_eq,
        'ALL_EQUAL_FLOAT_MAP'                  => :op_float_map_all_eq,
        'NONE_EQUAL_FLOAT_MAP'                 => :op_float_map_none_eq,
      }.each do |op, op_name|
        context op do
          [
            {expr: "[foo] #{op} 'key:1.0'", left: 'foo', right: 'key:1.0'},
            {expr: "[blat] #{op} 'key:0.4|key with space:0.1'", left: 'blat', right: 'key:0.4|key with space:0.1'},
          ].each do |struct|
            example struct[:expr] do
              expected = {
                left: {factor: struct[:left]},
                op: {op_name => op},
                right: {string: struct[:right]}
              }
              expect(described_class.parse(struct[:expr])).to eq expected
            end
          end
        end
      end
    end

    context 'string map operators' do
      {
        'ALL_MAP'  => :op_all_map,
        'ANY_MAP'  => :op_any_map,
        'NONE_MAP' => :op_none_map,
      }.each do |op, op_name|
        # [GSCaseIranRevShares] ANY_MAP 'Mineral Extraction Country:(10-100%]|Mineral Extraction Total:(10-100%]|Oil and Gas Country:(10-100%]|Oil and Gas Total:(10-100%]|Power Production Country:(10-100%]|Power Production Total:(10-100%]
        context op do
          [
            {expr: "[foo] #{op} 'key:val'", left: 'foo', right: 'key:val'},
            {expr: "[blat] #{op} 'key:val|key with space:val with space'", left: 'blat', right: 'key:val|key with space:val with space'},
          ].each do |struct|
            example struct[:expr] do
              expected = {
                left: {factor: struct[:left]},
                op: {op_name => op},
                right: {string: struct[:right]}
              }
              expect(described_class.parse(struct[:expr])).to eq expected
            end
          end
        end
      end
    end
  end

  context '#parse' do
    context 'complex queries' do
      let(:expr) { %{(( ( ([Bar] = 'USD:100.0') OR ([Foo] IS NOT NULL) ) AND ([Dead] IS NOT_APPLICABLE) AND [Age] > '1'))} }
      let(:expected) {{
        lstatement: {
          lstatement: {
            lstatement:  {
              left: {factor: "Bar"},
              op: {op_eq: "="},
              right: {currency_code: "USD", currency_value: {float: 100.0}},
            },
            boolean_operator: {op_or: "OR"},
            rstatement: {
              left: {factor: "Foo"},
              op: {op_is_not_null: "IS NOT NULL"},
            }
          },
          boolean_operator: {op_and: "AND"},
          rstatement: {
            left: {factor: "Dead"},
            op: {op_is: "IS"},
            right: {null_value_type: "NOT_APPLICABLE"},
          }
        },
        boolean_operator: {op_and: "AND"},
        rstatement: {
          left: {factor: "Age"},
          op: {op_gt: ">"},
          right: {int: 1},
        },
      }}

      example 'parens' do
        expect(parser.parse).to eq expected
      end

      context 'very long query' do
        let(:expr)     { File.read resource 'support/long-expr.txt' }
        let(:expected) { YAML.load_file resource 'support/long-expr.yml' }

        example 'parens' do
          expect(parser.parse).to eq(expected), 'generated parse tree was wrong'
        end
      end
    end

    context 'int currencies' do
      let(:expr) { %{[CashBonus] > 'AUD:1000'} }
        let(:expected) {{
          left: {factor: 'CashBonus'},
          op: {op_gt: '>'},
          right: {currency_code: 'AUD', currency_value: {float: 1000.0}},
        }}

        it { expect(parser.parse).to eq expected }
    end

    context 'float currencies' do
      let(:expr) { %{[AnotherBonus] < 'GBP:10.1'} }
        let(:expected) {{
          left: {factor: 'AnotherBonus'},
          op: {op_lt: '<'},
          right: {currency_code: 'GBP', currency_value: {float: 10.1}},
        }}

        it { expect(parser.parse).to eq expected }
    end

    context 'zero currencies' do
      let(:expr) { %{[CashBonus] > 'FOO:0'} }
        let(:expected) {{
          left: {factor: 'CashBonus'},
          op: {op_gt: '>'},
          right: {currency_code: 'FOO', currency_value: {float: 0.0}},
        }}

        it { expect(parser.parse).to eq expected }
    end

    context 'special markers' do
      context 'quoted markers do not get expanded' do
        context 'current year' do
          let(:expr) { %{[Foo] > '$CURRENT_YEAR'} }
          let(:expected) {{
            left: {factor: 'Foo'},
            op: {op_gt: '>'},
            right: {string: '$CURRENT_YEAR'},
          }}

          it { expect(parser.parse).to eq expected }
        end

        context 'current date' do
          let(:expr) { %{[Foo] > '$CURRENT_DATE'} }
          let(:expected) {{
            left: {factor: 'Foo'},
            op: {op_gt: '>'},
            right: {string: '$CURRENT_DATE'},
          }}

          it { expect(parser.parse).to eq expected }
        end
      end

      context '$CURRENT_YEAR' do
        let(:expr) { %{[Foo] > $CURRENT_YEAR} }
        let(:expected) {{
          left: {factor: 'Foo'},
          op: {op_gt: '>'},
          right: {special_marker: {current_year: '$CURRENT_YEAR'}},
        }}

        it { expect(parser.parse).to eq expected }
      end

      context '$CURRENT_DATE' do
        let(:expr) { %{[Bar] = $CURRENT_DATE} }
        let(:expected) {{
          left: {factor: 'Bar'},
          op: {op_eq: '='},
          right: {special_marker: {current_date: '$CURRENT_DATE'}},
        }}

        it { expect(parser.parse).to eq expected }
      end
    end

    context 'on date' do
      let(:expr) { %{[Foo] ON '2011-01-01'} }
      let(:expected) {{
        left: {factor: 'Foo'},
        op: {op_date_on: 'ON'},
        right: {string: '2011-01-01'},
      }}

      it { expect(parser.parse).to eq expected }
    end

    context 'on or after date' do
      let(:expr) { %{[Foo] EPST '2013-01-02'} }
      let(:expected) {{
        left: {factor: 'Foo'},
        op: {op_date_after_or_on: 'EPST'},
        right: {string: '2013-01-02'},
      }}

      it { expect(parser.parse).to eq expected }
    end

    context 'after date' do
      let(:expr) { %{[Foo] PST '2017-10-13'} }
      let(:expected) {{
        left: {factor: 'Foo'},
        op: {op_date_after: 'PST'},
        right: {string: '2017-10-13'},
      }}

      it { expect(parser.parse).to eq expected }
    end

    context 'on or before date' do
      let(:expr) { %{[Foo] EPRE '2013-01-02'} }
      let(:expected) {{
        left: {factor: 'Foo'},
        op: {op_date_before_or_on: 'EPRE'},
        right: {string: '2013-01-02'},
      }}

      it { expect(parser.parse).to eq expected }
    end

    context 'before date' do
      let(:expr) { %{[Foo] PRE '2020-02-02'} }
      let(:expected) {{
        left: {factor: 'Foo'},
        op: {op_date_before: 'PRE'},
        right: {string: '2020-02-02'},
      }}

      it { expect(parser.parse).to eq expected }
    end

    context 'single string comparison' do
      let(:expr) { %{[Foo] = 'Abc'} }
      let(:expected) {{
        left: {factor: 'Foo'},
        op: {op_eq: '='},
        right: {string: 'Abc'},
      }}

      it { expect(parser.parse).to eq expected }
    end

    context 'single integer comparison' do
      let(:expr) { %{[Bar] != '11'} }
      let(:expected) {{
        left: {factor: 'Bar'},
        op: {op_ne: '!='},
        right: {int: 11},
      }}

      it { expect(parser.parse).to eq expected }
    end

    context 'single negative integer comparison' do
      let(:expr) { %{[Bar] / '-5'} }
      let(:expected) {{
        left: {factor: 'Bar'},
        op: {op_divide: '/'},
        right: {int: -5},
      }}

      it { expect(parser.parse).to eq expected }
    end

    context 'single postive integer comparison' do
      let(:expr) { %{[Mod] % '+3'} }
      let(:expected) {{
        left: {factor: 'Mod'},
        op: {op_mod: '%'},
        right: {int: 3},
      }}

      it { expect(parser.parse).to eq expected }
    end

    context 'single float comparison' do
      let(:expr) { %{[Bar] < '29.17'} }
      let(:expected) {{
        left: {factor: 'Bar'},
        op: {op_lt: '<'},
        right: {float: 29.17},
      }}

      it { expect(parser.parse).to eq expected }
    end

    context 'single negative float comparison' do
      let(:expr) { %{[Bar] + '-131711.0705'} }
      let(:expected) {{
        left: {factor: 'Bar'},
        op: {op_add: '+'},
        right: {float: -131711.0705},
      }}

      it { expect(parser.parse).to eq expected }
    end

    context 'single positive float comparison' do
      let(:expr) { %{[Pow] ^ '+1.5'} }
      let(:expected) {{
        left: {factor: 'Pow'},
        op: {op_power: '^'},
        right: {float: 1.5},
      }}

      it { expect(parser.parse).to eq expected }
    end

    context 'single scientific number comparison (E)' do
      let(:expr) { %{[Bar] == '1.23E56'} }
      let(:expected) {{
        left: {factor: 'Bar'},
        op: {op_eq: '=='},
        right: {float: 1.23E56},
      }}

      it { expect(parser.parse).to eq expected }
    end

    context 'single scientific number comparison (e)' do
      let(:expr) { %{[Bar] = '1.3e-57'} }
      let(:expected) {{
        left: {factor: 'Bar'},
        op: {op_eq: '='},
        right: {float: 1.3e-57},
      }}

      it { expect(parser.parse).to eq expected }
    end

    context 'single negative scientific number comparison (e)' do
      let(:expr) { %{[Bar] = '-1.5e-7'} }
      let(:expected) {{
        left: {factor: 'Bar'},
        op: {op_eq: '='},
        right: {float: -1.5e-7},
      }}

      it { expect(parser.parse).to eq expected }
    end
  end

  context 'subqueries' do
    context 'aliasing' do
      let(:nested_close) { DDQL::TokenType::NESTED_CLOSE_PATTERN }
      let(:nested_expr)  { "#{nested_open} #{inner_expr} #{nested_close}" }
      let(:nested_open)  { DDQL::TokenType::NESTED_OPEN_PATTERN }

      context 'factor comparison with implicit description' do
        let(:expr)     { "ALIAS {type: Issuer, expression: [foo] == '1'} AS [Jason]" }
        let(:expected) {{
          agg: {op_alias: 'ALIAS'},
          sub_query_type: 'Issuer',
          sub_query: {
            left: {factor: 'foo'},
            op: {op_eq: '=='},
            right: {int: 1},
          },
          sub_query_alias: {factor: 'Jason', desc: 'Jason'},
        }}

        it { expect(parser.parse).to eq expected }
      end

      context 'factor comparison with explicit description' do
        let(:expr)     { "ALIAS {type: Issuer, expression: [bar] > '2'} AS [BarComparison:Bar > 2]" }
        let(:expected) {{
          agg: {op_alias: 'ALIAS'},
          sub_query_type: 'Issuer',
          sub_query: {
            left: {factor: 'bar'},
            op: {op_gt: '>'},
            right: {int: 2},
          },
          sub_query_alias: {factor: 'BarComparison', desc: 'Bar > 2'},
        }}

        it { expect(parser.parse).to eq expected }
      end

      context 'factor extraction with explicit description' do
        let(:expr)     { "ALIAS {type: Issuer, expression: [bar]} AS [BarExtraction:Bar]" }
        let(:expected) {{
          agg: {op_alias: 'ALIAS'},
          sub_query_type: 'Issuer',
          sub_query: {factor: 'bar'},
          sub_query_alias: {factor: 'BarExtraction', desc: 'Bar'},
        }}

        it { expect(parser.parse).to eq expected }
      end

      context 'factor extraction with implicit description' do
        let(:expr)     { "ALIAS {type: Issuer, expression: [meh]} AS [Foo]" }
        let(:expected) {{
          agg: {op_alias: 'ALIAS'},
          sub_query_type: 'Issuer',
          sub_query: {factor: 'meh'},
          sub_query_alias: {factor: 'Foo', desc: 'Foo'},
        }}

        it { expect(parser.parse).to eq expected }
      end

      context 'factor math with explicit description' do
        let(:expr)     { "ALIAS {type: Issuer, expression: [foo] * '2'} AS [BarMath:Bar]" }
        let(:expected) {{
          agg: {op_alias: 'ALIAS'},
          sub_query_type: 'Issuer',
          sub_query: {
            left: {factor: 'foo'},
            op: {op_multiply: '*'},
            right: {int: 2},
          },
          sub_query_alias: {factor: 'BarMath', desc: 'Bar'},
        }}

        it { expect(parser.parse).to eq expected }
      end

      context 'factor math with implicit description' do
        let(:expr)       { "ALIAS {type: Issuer, expression: #{inner_expr}} AS [1/7thOfNah]" }
        let(:inner_expr) { "[nah] / '7.0'" }
        let(:expected)   {{
          agg: {op_alias: 'ALIAS'},
          sub_query_type: 'Issuer',
          sub_query: {
            left: {factor: 'nah'},
            op: { op_divide: '/'},
            right: {float: 7.0},
          },
          sub_query_alias: {factor: '1/7thOfNah', desc: '1/7thOfNah'},
        }}

        it { expect(parser.parse).to eq expected }
      end

      context 'simple sub-expression as nested expressions' do
        let(:expr)       { "ALIAS {type: Issuer, expression: #{nested_expr}} AS [1/7thOfNah]" }
        let(:inner_expr) { "[nah] / '7.0'" }
        let(:expected)   {{
          agg: {op_alias: 'ALIAS'},
          sub_query_type: 'Issuer',
          sub_query: {
            left: {factor: 'nah'},
            op: { op_divide: '/'},
            right: {float: 7.0},
          },
          sub_query_alias: {factor: '1/7thOfNah', desc: '1/7thOfNah'},
        }}

        it { expect(parser.parse).to eq expected }
      end

      context 'another sub-expression with explicit description' do
        let(:expr)       { "ALIAS {type: Issuer, expression: #{nested_expr} } AS [SubExpr:Has More Than One Foo]" }
        let(:inner_expr) { "CNT { type: Person, expression: [foo] } > '1'" }
        let(:expected)   {{
          agg: {op_alias: 'ALIAS'},
          sub_query_type: 'Issuer',
          sub_query: {
            left: {
              agg: {op_cnt: 'CNT'},
              sub_query_expression: '[foo]',
              sub_query_type: 'Person',
            },
            op: {op_gt: '>'},
            right: {int: 1},
          },
          sub_query_alias: {factor: 'SubExpr', desc: 'Has More Than One Foo'},
        }}

        it { expect(parser.parse).to eq expected }
      end

      context 'another sub-expression with implicit description' do
        let(:expr)       { "ALIAS {type: Issuer, expression: #{nested_expr} } AS [SubExpression]" }
        let(:inner_expr) { "EXISTS { type: Person, expression: [foo] } > '2'" }
        let(:expected)   {{
          agg: {op_alias: 'ALIAS'},
          sub_query_type: 'Issuer',
          sub_query: {
            left: {
              agg: {op_exists: 'EXISTS'},
              sub_query_expression: '[foo]',
              sub_query_type: 'Person',
            },
            op: {op_gt: '>'},
            right: {int: 2},
          },
          sub_query_alias: {factor: 'SubExpression', desc: 'SubExpression'},
        }}

        it { expect(parser.parse).to eq expected }
      end

      context 'a non-grouped sub-expression' do
        let(:expr)       { "ALIAS {type: Issuer, expression: #{nested_expr} } AS [MaxExpression]" }
        let(:inner_expr) { "MAX { type: Person, expression: [foo] }" }
        let(:expected)   {{
          agg: {op_alias: 'ALIAS'},
          sub_query_type: 'Issuer',
          sub_query: {
            agg: {op_max: 'MAX'},
            sub_query_expression: '[foo]',
            sub_query_type: 'Person',
          },
          sub_query_alias: {factor: 'MaxExpression', desc: 'MaxExpression'},
        }}

        it { expect(parser.parse).to eq expected }
      end

      context 'a grouped sub-expression' do
        let(:expr)       { "ALIAS {type: Issuer, expression: #{nested_expr} } AS [MinFooByBar:Minnie Mouse]" }
        let(:inner_expr) { "MIN { type: Case, expression: [foo] != '19' } GROUP BY [bar]" }
        let(:expected)   {{
          agg: {op_alias: 'ALIAS'},
          sub_query_type: 'Issuer',
          sub_query: {
            agg: {op_min: 'MIN'},
            sub_query_expression: "[foo] != '19'",
            sub_query_type: 'Case',
            sub_query_grouping: {factor: 'bar'},
          },
          sub_query_alias: {factor: 'MinFooByBar', desc: 'Minnie Mouse'},
        }}

        it { expect(parser.parse).to eq expected }
      end
    end

    context 'with grouping' do
      let(:expr) { "MIN {type: Issuer, fields: [oekomCarbonRiskRating]} GROUP BY [oekomIndustry]" }
      let(:expected) {{
        agg: {op_min: 'MIN'},
        sub_query_fields: {factor: 'oekomCarbonRiskRating'},
        sub_query_type: 'Issuer',
        sub_query_grouping: {factor: 'oekomIndustry'},
      }}

      it { expect(parser.parse).to eq expected }
    end

    context 'with multiple subqueries' do
      let(:a)        { "CNT{type:IssuerPerson, expression: #{a_expr}}" }
      let(:a_expr)   { "[DirClassificationCO] IN 'IO|I-NED'" }
      let(:b)        { "CNT{type:IssuerPerson, expression: #{b_expr}}" }
      let(:b_expr)   { "[DirClassificationCO] != 'ND' AND [DirClassificationCO] IS NOT NULL" }
      let(:expr)     { "#{a} / #{b}" }
      let(:expected) {{
        left: {
          agg: {op_cnt: 'CNT'},
          sub_query_type: 'IssuerPerson',
          sub_query_expression: a_expr,
        },
        op: {op_divide: '/'},
        right: {
          agg: {op_cnt: 'CNT'},
          sub_query_type: 'IssuerPerson',
          sub_query_expression: b_expr,
        }
      }}

      it { expect(parser.parse).to eq expected }
    end

    context 'AVG' do
      let(:field)    { 'Tenure' }
      let(:filter)   { "[Tenure] IS NOT NULL" }
      let(:sub_expr) { "type: IssuerPerson, fields: [#{field}], expression: #{filter}" }

      context 'with comparison' do
        let(:expr)     { "AVG {#{sub_expr}}  >= '10.01'" }
        let(:expected) {{
          left: {
            agg: {op_avg: 'AVG'},
            sub_query_type: 'IssuerPerson',
            sub_query_fields: {factor: field},
            sub_query_expression: filter,
          },
          op: {op_ge: '>='},
          right: {float: 10.01},
        }}
        it { expect(parser.parse).to eq expected }
      end

      context 'without comparison' do
        let(:expr)     { "AVG {#{sub_expr}}" }
        let(:expected) {{
          agg: {op_avg: 'AVG'},
          sub_query_type: 'IssuerPerson',
          sub_query_fields: {factor: field},
          sub_query_expression: filter,
        }}
        it { expect(parser.parse).to eq expected }
      end
    end

    context 'CNT' do
      let(:filter)   { "([CaseFlag] == 'Amber' AND [CaseFlag] == 'RED' AND [CaseFlag] == 'Green')" }
      let(:sub_expr) { "type: IssuerCase, fields: [], expression: #{filter}" }

      context 'with comparison' do
        let(:expr)     { "CNT {#{sub_expr}}  >= '0'" }
        let(:expected) {{
          left: {
            agg: {op_cnt: 'CNT'},
            sub_query_type: 'IssuerCase',
            sub_query_expression: filter,
          },
          op: {op_ge: '>='},
          right: {int: 0},
        }}
        it { expect(parser.parse).to eq expected }
      end

      context 'without comparison' do
        let(:expr)     { "CNT {#{sub_expr}}" }
        let(:expected) {{
          agg: {op_cnt: 'CNT'},
          sub_query_type: 'IssuerCase',
          sub_query_expression: filter,
        }}
        it { expect(parser.parse).to eq expected }
      end
    end

    context 'EXISTS' do
      let(:filter)   { "[ServesAsChairman] YES AND [ServesAsCEO] YES" }
      let(:sub_expr) { "type:IssuerPerson, expression: #{filter}" }

      context 'with comparison' do
        let(:expr)     { "EXISTS {#{sub_expr}} YES" }
        let(:expected) {{
          left: {
            agg: {op_exists: 'EXISTS'},
            sub_query_type: 'IssuerPerson',
            sub_query_expression: filter,
          },
          yes_no_op: {op_yes: 'YES'},
        }}
        it { expect(parser.parse).to eq expected }
      end

      context 'without comparison' do
        let(:expr)     { "EXISTS{#{sub_expr}}" }
        let(:expected) {{
          agg: {op_exists: 'EXISTS'},
          sub_query_type: 'IssuerPerson',
          sub_query_expression: filter,
        }}
        it { expect(parser.parse).to eq expected }
      end
    end

    context 'MAX' do
      let(:field)    { 'oekomRating' }
      let(:filter)   { "[oekomIndustry] IS NOT NULL" }
      let(:sub_expr) { "type: Issuer, fields: [#{field}], expression: #{filter}" }

      context 'with comparison' do
        let(:expr)     { "MAX {#{sub_expr}}= '1.3'" }
        let(:expected) {{
          left: {
            agg: {op_max: 'MAX'},
            sub_query_type: 'Issuer',
            sub_query_fields: {factor: field},
            sub_query_expression: filter,
          },
          op: {op_eq: '='},
          right: {float: 1.3},
        }}
        it { expect(parser.parse).to eq expected }
      end

      context 'without comparison' do
        let(:expr)     { "MAX {#{sub_expr}}" }
        let(:expected) {{
          agg: {op_max: 'MAX'},
          sub_query_type: 'Issuer',
          sub_query_fields: {factor: field},
          sub_query_expression: filter,
        }}
        it { expect(parser.parse).to eq expected }
      end
    end

    context 'MED' do
      let(:field)    { 'Age' }
      let(:filter)   { "[LastName] IS NOT NULL" }
      let(:sub_expr) { "type: Person, fields: [#{field}], expression: #{filter}" }

      context 'with comparison' do
        let(:expr)     { "MED {#{sub_expr}}== '52'" }
        let(:expected) {{
          left: {
            agg: {op_med: 'MED'},
            sub_query_type: 'Person',
            sub_query_fields: {factor: field},
            sub_query_expression: filter,
          },
          op: {op_eq: '=='},
          right: {int: 52},
        }}
        it { expect(parser.parse).to eq expected }
      end

      context 'without comparison' do
        let(:expr)     { "MED {#{sub_expr}}" }
        let(:expected) {{
          agg: {op_med: 'MED'},
          sub_query_type: 'Person',
          sub_query_fields: {factor: field},
          sub_query_expression: filter,
        }}
        it { expect(parser.parse).to eq expected }
      end
    end

    context 'MERGE' do
      let(:sub_expr) { %{type: IssuerPerson, fields: [#{field}]} }
      let(:field)    { 'IssuerDisclosedPersonSkills' }

      context 'with comparison' do
        let(:expr)     { "MERGE{#{sub_expr}} = 'Base Jumping|Rock Climbing'" }
        let(:expected) {{
          left: {
            agg: {op_merge: 'MERGE'},
            sub_query_type: 'IssuerPerson',
            sub_query_fields: {factor: field},
          },
          op: {op_eq: '='},
          right: {string: 'Base Jumping|Rock Climbing'},
        }}
        it { expect(parser.parse).to eq expected }
      end

      context 'without comparison' do
        let(:expr)     { "MERGE { #{sub_expr}}" }
        let(:expected) {{
          agg: {op_merge: 'MERGE'},
          sub_query_type: 'IssuerPerson',
          sub_query_fields: {factor: field},
        }}
        it { expect(parser.parse).to eq expected }
      end
    end

    context 'MIN' do
      let(:field)    { 'Age' }
      let(:filter)   { "[LastName] IS NOT NULL" }
      let(:sub_expr) { "type: Person, fields: [#{field}], expression: #{filter}" }

      context 'with comparison' do
        let(:expr)     { "MIN {#{sub_expr}}<= '49'" }
        let(:expected) {{
          left: {
            agg: {op_min: 'MIN'},
            sub_query_type: 'Person',
            sub_query_fields: {factor: field},
            sub_query_expression: filter,
          },
          op: {op_le: '<='},
          right: {int: 49},
        }}
        it { expect(parser.parse).to eq expected }
      end

      context 'without comparison' do
        let(:expr)     { "MIN {#{sub_expr}}" }
        let(:expected) {{
          agg: {op_min: 'MIN'},
          sub_query_type: 'Person',
          sub_query_fields: {factor: field},
          sub_query_expression: filter,
        }}
        it { expect(parser.parse).to eq expected }
      end
    end

    context 'SUM' do
      let(:sub_expr) { "type: IssuerPerson, fields: [DollarValueDirMatTransactions], expression: #{filter}" }
      let(:filter)   { %{[ipAssociationType] == 'Executive'} }

      context 'with comparison' do
        let(:expr)     { "SUM {#{sub_expr}} != '135711.13719'" }
        let(:expected) {{
          left: {
            agg: {op_sum: 'SUM'},
            sub_query_fields: {factor: 'DollarValueDirMatTransactions'},
            sub_query_type: 'IssuerPerson',
            sub_query_expression: filter,
          },
          op: {op_ne: '!='},
          right: {float: 135711.13719},
        }}

        it { expect(parser.parse).to eq expected }
      end

      context 'without comparison' do
        let(:expr)     { "SUM { #{sub_expr} }" }
        let(:expected) {{
          agg: {op_sum: 'SUM'},
          sub_query_fields: {factor: 'DollarValueDirMatTransactions'},
          sub_query_type: 'IssuerPerson',
          sub_query_expression: filter,
        }}

        it { expect(parser.parse).to eq expected }
      end
    end

    context 'inline query' do
      context 'math operation' do
        let(:expr) { '{[A] / [B]}' }
        let(:expected) {{
          left: {factor: 'A'},
          op: {op_divide: '/'},
          right: {factor: 'B'},
        }}

        it { expect(parser.parse).to eq expected }
      end

      context 'math operation with comparison' do
        let(:expr) { "{[B] * [C]} > '0'" }
        let(:expected) {{
          left: {
            left: {factor: 'B'},
            op: {op_multiply: '*'},
            right: {factor: 'C'},
          },
          op: {op_gt: '>'},
          right: {int: 0},
        }}

        it { expect(parser.parse).to eq expected }
      end

      context 'comparison as boolean statement' do
        let(:expr) { "{[C] < [A]} YES" }
        let(:expected) {{
          left: {factor: 'C'},
          op: {op_lt: '<'},
          right: {factor: 'A'},
          yes_no_op: {op_yes: 'YES'},
        }}

        it { expect(parser.parse).to eq expected }
      end

      context 'negated comparison' do
        let(:expr) { "NOT {[C] != [D]}" }
        let(:expected) {{
          op_not: 'NOT',
          left: {factor: 'C'},
          op: {op_ne: '!='},
          right: {factor: 'D'},
        }}

        it { expect(parser.parse).to eq expected }
      end

      context 'deeply nested statements' do
        let(:expr) { "{{[Foo] + [Bar]} = '0'} YES AND {{[Baz] ^ [Blat]} >= '25.0'} YES" }
        let(:expected) {{
          lstatement: {
            left: {
              left: {factor: 'Foo'},
              op: {op_add: '+'},
              right: {factor: 'Bar'},
            },
            op: {op_eq: '='},
            right: {int: 0},
            yes_no_op: {op_yes: 'YES'},
          },
          boolean_operator: {op_and: 'AND'},
          rstatement: {
            left: {
              left: {factor: 'Baz'},
              op: {op_power: '^'},
              right: {factor: 'Blat'},
            },
            op: {op_ge: '>='},
            right: {float: 25.0},
            yes_no_op: {op_yes: 'YES'},
          },
        }}

        it { expect(parser.parse).to eq expected }
      end

      context 'negated nested statements' do
        let(:expr) { "NOT {{{[Foo] + [Bar]} = '0'} YES}" }
        let(:expected) {{
          op_not: 'NOT',
          left: {
            left: {factor: 'Foo'},
            op: {op_add: '+'},
            right: {factor: 'Bar'},
          },
          op: {op_eq: '='},
          right: {int: 0},
          yes_no_op: {op_yes: 'YES'},
        }}

        it { expect(parser.parse).to eq expected }
      end
    end

    context 'as lstatement' do
      let(:expr) do
        %{
          CNT {
            type: IssuerPerson,
            fields: [],
            expression: (
              [ThreeYearTSRCumulative] < '0'
              OR [ipAssociationType] == 'Director'
              OR [AttendedLessThan75PctOfMeetings] YES
              OR [IsDisclosedAsFinancialExpert] NO
            )
          } >= '2' AND ([NoOfPublicBoards] >= '4')
        }.squish
      end

      let(:expected) do
        {
          lstatement: {
            left: {
              agg: {op_cnt: "CNT"},
              sub_query_type: "IssuerPerson",
              sub_query_expression:  %{(
                [ThreeYearTSRCumulative] < '0'
                  OR [ipAssociationType] == 'Director'
                  OR [AttendedLessThan75PctOfMeetings] YES
                  OR [IsDisclosedAsFinancialExpert] NO
              )}.squish,
            },
            op: {op_ge: ">="},
            right: {int: 2},
          },
          boolean_operator: {op_and: "AND"},
          rstatement: {
            left: {factor: "NoOfPublicBoards"},
            op: {op_ge: ">="},
            right: {int: 4},
          },
        }
      end

      it { expect(parser.parse).to eq expected }
    end

    context 'as rstatement' do
      let(:expr) do
        %{
          ([NoOfPublicBoards] >= '4') OR
          CNT {
            type: IssuerPerson,
            fields: [],
            expression: [ThreeYearTSRCumulative] > '0'
          } >= '2'
        }.squish
      end

      let(:expected) do
        {
          rstatement: {
            left: {
              agg: {op_cnt: "CNT"},
              sub_query_type: "IssuerPerson",
              sub_query_expression: %{[ThreeYearTSRCumulative] > '0'},
            },
            op: {op_ge: ">="},
            right: {int: 2},
          },
          boolean_operator: {op_or: "OR"},
          lstatement: {
            left: {factor: "NoOfPublicBoards"},
            op: {op_ge: ">="},
            right: {int: 4},
          },
        }
      end

      it { expect(parser.parse).to eq expected }
    end
  end

  context 'special marker' do
    %w[CURRENT_YEAR CURRENT_DATE].each do |marker|
      sym = marker.downcase.to_sym

      context 'in math expressions' do
        let(:parser) { described_class.new expression: expr }
        let(:parsed) { parser.parse }

        context "($#{marker} - [BirthYear])" do
          let(:expr)     { "($#{marker} - [BirthYear])" }
          let(:expected) {{
            left: {special_marker: {sym => "$#{marker}"}},
            op: {op_subtract: '-'},
            right: {factor: 'BirthYear'},
          }}
          it { expect(parsed).to eq expected }
        end

        context "([BirthYear] - $#{marker})" do
          let(:expr)     { "([BirthYear] - $#{marker})" }
          let(:expected) {{
            left: {factor: 'BirthYear'},
            op: {op_subtract: '-'},
            right: {special_marker: {sym => "$#{marker}"}},
          }}
          it { expect(parsed).to eq expected }
        end

        context "[a] == ('5' + $#{marker})" do
          let(:expr)     { "[a] == ('5' + $#{marker})" }
          let(:expected) {{
            left: {factor: 'a'},
            op: {op_eq: '=='},
            right: {
              left: {int: 5},
              op: {op_add: '+'},
              right: {special_marker: {sym => "$#{marker}"}},
            },
          }}
          it { expect(parsed).to eq expected }
        end

        context "[a] < ($#{marker} * '2')" do
          let(:expr)     { "[a] < ($#{marker} * '2')" }
          let(:expected) {{
            left: {factor: 'a'},
            op: {op_lt: '<'},
            right: {
              left: {special_marker: {sym => "$#{marker}"}},
              op: {op_multiply: '*'},
              right: {int: 2},
            },
          }}
          it { expect(parsed).to eq expected }
        end

        context "('5' * $#{marker}) > [b]" do
          let(:expr)     { "('5' * $#{marker}) > [b]" }
          let(:expected) {{
            left: {
              left: {int: 5},
              op: {op_multiply: '*'},
              right: {special_marker: {sym => "$#{marker}"}},
            },
            op: {op_gt: '>'},
            right: {factor: 'b'},
          }}
          it { expect(parsed).to eq expected }
        end

        context "($#{marker} * '2') / $#{marker}" do
          let(:expr)     { "($#{marker} * '2') / $#{marker}" }
          let(:expected) {{
            left: {
              left: {special_marker: {sym => "$#{marker}"}},
              op: {op_multiply: '*'},
              right: {int: 2},
            },
            op: {op_divide: '/'},
            right: {special_marker: {sym => "$#{marker}"}},
          }}
          it { expect(parsed).to eq expected }
        end
      end

      context 'in left position comparison' do
        it { expect(described_class.parse("$#{marker} == [foo]")[:left][:special_marker].keys).to eq [sym] }
      end

      context 'in right position comparison' do
        it { expect(described_class.parse("[a] > $#{marker}")[:right][:special_marker].keys).to eq [sym] }
      end

      context 'by itself' do
        it { expect(described_class.parse("$#{marker}")[:special_marker].keys).to eq [sym] }
        it { expect(described_class.parse("(((((((($#{marker}))))))))")[:special_marker].keys).to eq [sym] }
      end
    end
  end

  context 'single YES/NO factor' do
    let(:parser)   { described_class.new expression: expr }
    let(:parsed)   { parser.parse }
    let(:expr)     { '[YesOrNo] NO' }
    let(:expected) {{
      left: {factor: 'YesOrNo'},
      yes_no_op: {op_no: 'NO'},
    }}

    it { expect(parsed).to eq expected }
  end

  context 'boolean expression of YES/NO factors' do
    let(:parser)   { described_class.new expression: expr }
    let(:parsed)   { parser.parse }
    let(:expr)     { '[ServesAsChairman] YES AND [ServesAsCEO] YES' }
    let(:expected) {{
      lstatement: {
        left: {factor: 'ServesAsChairman'},
        yes_no_op: {op_yes: 'YES'},
      },
      boolean_operator: {op_and: 'AND'},
      rstatement: {
        left: {factor: 'ServesAsCEO'},
        yes_no_op: {op_yes: 'YES'},
      },
    }}

    it { expect(parsed).to eq expected }
  end

  context 'various math operations' do
    operands = {
      '[factor1]' => '[factor2]',
      '[factor2]' => '[factor2]',
      '[factor3]' => "'4'",
      "'2.9'"     => '[factor]',
      '[factor4]' => %{AVG { type: Issuer, expression: [Foo] == 'bar' }},
      "'3.14'"    => %{AVG { type: Issuer, expression: [Foo] == 'bar' }},
    }
    operators = {
      '+' => :op_add,
      '-' => :op_subtract,
      '*' => :op_multiply,
      '/' => :op_divide,
      '%' => :op_mod,
      '^' => :op_power,
    }
    operands.each do |left, right|
      operators.each do |op, op_sym|
        expr   = %{#{left} #{op} #{right}}
        it %{parses <#{expr}>} do
          expect { described_class.parse(expr) }.not_to raise_error
        end
      end
    end
  end

  context 'screens' do
    let(:sub_expr) { %{[screen##{screen_id}]} }

    context 'with comparison' do
      let(:expr)      { "#{sub_expr} YES" }
      let(:screen_id) { 1 }
      let(:expected)  {{
        left: {
          screen: screen_id,
        },
        yes_no_op: {op_yes: 'YES'},
      }}
      it { expect(parser.parse).to eq expected }
    end

    context 'without comparison' do
      let(:expr)      { sub_expr }
      let(:expected)  { {screen: screen_id,} }
      let(:screen_id) { 14 }
      it { expect(parser.parse).to eq expected }
    end
  end

  context 'various aggregation compositions' do
    context 'agg bool stmt bool agg' do
      let(:expression) do
        "EXISTS {type: IssuerPerson, fields: [], expression: " \
              "([CountryOfIncorporation] == 'USA' AND [YrDirectorBeganServingOnBoard] < '1997')" \
              " OR ([CountryOfIncorporation] == 'United Kingdom' AND [YrDirectorBeganServingOnBoard] < '1987')}" \
          " AND ([Gender] == 'M')" \
          " AND EXISTS {type: IssuerCase, fields: [], expression: [CaseAreas] ANY 'Norms-Based Screening>Corruption'} "
      end
      let(:expected) {{
        boolean_operator: {op_and: "AND"},
        lstatement: {
          boolean_operator: {op_and: "AND"},
          lstatement: {
            agg: {op_exists: "EXISTS"},
            sub_query_expression:  "([CountryOfIncorporation] == 'USA' AND [YrDirectorBeganServingOnBoard] < '1997') OR ([CountryOfIncorporation] == 'United Kingdom' AND [YrDirectorBeganServingOnBoard] < '1987')",
            sub_query_type: "IssuerPerson",
          },
          rstatement: {
            left: {factor: "Gender"},
            op: {op_eq: "=="},
            right: {string: "M"},
          },
        },
        rstatement: {
          sub_query_type: "IssuerCase",
          sub_query_expression: "[CaseAreas] ANY 'Norms-Based Screening>Corruption'",
          agg: {op_exists: "EXISTS"},
        },
      }}

      it 'should parse' do
        expect(DDQL::Parser.parse(expression)).to eq expected
      end
    end

    context 'stmt bool agg bool agg' do
      let(:expression) do
        "(([MarketCap] > '5000000000' AND [OverallQualityScoreDec] == '9'))" \
          " AND EXISTS {type: IssuerPerson, fields: [], expression: [Age] == '33'} " \
          " AND EXISTS {type: IssuerCase, fields: [], expression: [CaseAreas] ANY 'Norms-Based Screening>Corruption'} "
      end
      let(:expected) {{
        lstatement: {
          lstatement: {
            left: {factor: 'MarketCap'},
            op: {op_gt: '>'},
            right: {int: 5000000000},
          },
          boolean_operator: {op_and: 'AND'},
          rstatement: {
            left: {factor: 'OverallQualityScoreDec'},
            op: {op_eq: '=='},
            right: {int: 9},
          },
        },
        boolean_operator: {op_and: 'AND'},
        rstatement: {
          lstatement: {
            agg: {op_exists: 'EXISTS'},
            sub_query_type: 'IssuerPerson',
            sub_query_expression: "[Age] == '33'",
          },
          boolean_operator: {op_and: 'AND'},
          rstatement: {
            agg: {op_exists: 'EXISTS'},
            sub_query_type: 'IssuerCase',
            sub_query_expression: "[CaseAreas] ANY 'Norms-Based Screening>Corruption'",
          },
        },
      }}

      it 'should parse' do
        expect(DDQL::Parser.parse(expression)).to eq expected
      end
    end

    context 'agg bool agg bool stmt' do
      let(:expression) do
        "EXISTS {type: IssuerPerson, fields: [], expression: [Age] == '33'} " \
          " AND EXISTS {type: IssuerCase, fields: [], expression: [CaseAreas] ANY 'Norms-Based Screening>Corruption'} " \
          " AND (([MarketCap] > '5000000000' AND [OverallQualityScoreDec] == '9'))"
      end
      let(:expected) {{
        boolean_operator: {op_and: 'AND'},
        lstatement: {
          agg: {op_exists: 'EXISTS'},
          sub_query_type: 'IssuerPerson',
          sub_query_expression: "[Age] == '33'",
        },
        rstatement: {
          boolean_operator: {op_and: 'AND'},
          lstatement: {
            agg: {op_exists: 'EXISTS'},
            sub_query_type: 'IssuerCase',
            sub_query_expression: "[CaseAreas] ANY 'Norms-Based Screening>Corruption'",
          },
          rstatement: {
            lstatement: {
              left: {factor: 'MarketCap'},
              op: {op_gt: '>'},
              right: {int: 5000000000},
            },
            boolean_operator: {op_and: 'AND'},
            rstatement: {
              left: {factor: 'OverallQualityScoreDec'},
              op: {op_eq: '=='},
              right: {int: 9},
            },
          },
        },
      }}

      it 'should parse' do
        expect(DDQL::Parser.parse(expression)).to eq expected
      end
    end

    context 'agg bool agg' do
      let(:expression) do
        "EXISTS {type: IssuerPerson, fields: [], expression: [Age] == '33'} " \
        "AND EXISTS {type: IssuerCase, fields: [], expression: [CaseAreas] ANY 'Norms-Based Screening>Corruption'} "
      end
      let(:expected) {{
        lstatement: {
          agg: {op_exists: 'EXISTS'},
          sub_query_type: 'IssuerPerson',
          sub_query_expression: "[Age] == '33'",
        },
        boolean_operator: {op_and: 'AND'},
        rstatement: {
          agg: {op_exists: 'EXISTS'},
          sub_query_type: 'IssuerCase',
          sub_query_expression: "[CaseAreas] ANY 'Norms-Based Screening>Corruption'",
        },
      }}

      it 'should parse' do
        expect(DDQL::Parser.parse(expression)).to eq expected
      end
    end

  end
end
