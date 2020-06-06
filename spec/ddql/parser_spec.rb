require 'parslet/convenience'

RSpec.describe DDQL::Parser do
  array_operators = {
    'ALL'  => :op_all,
    'ANY'  => :op_any,
    'IN'   => :op_in,
    'NONE' => :op_none,
  }
  date_relational_operators = {
    'PRE'  => :op_date_before,
    'PST'  => :op_date_after,
  }
  relational_operators = {
    '>'  => :op_gt,
    '>=' => :op_ge,
    '<'  => :op_lt,
    '<=' => :op_le,
    '='  => :op_eq,
    '!=' => :op_ne,
  }
  string_relational_operators = {
    'CTN'  => :op_ctn,
    'LCTN' => :op_ctn,
    'STW'  => :op_stw,
  }
  null_types = %w[
    NO_INFORMATION
    NOT_APPLICABLE
    NOT_COLLECTED
    NOT_DISCLOSED
    NOT_MEANINGFUL
  ]

  let(:parser) { described_class.new }

  # it 'should parse long expressions without error' do
  #   expression = File.read spec_resource 'support/long-expr.txt'
  #   expect  {parser.parse_with_debug expression }.not_to raise_error
  # end

  context 'special marker' do
    %w[CURRENT_YEAR CURRENT_DATE].each do |marker|
      sym = marker.downcase.to_sym

      context 'in math expressions' do
        it { expect(parser.parse_with_debug("($#{marker} - [BirthYear])")[:left][:special_marker].keys).to eq [sym] }
        it { expect(parser.parse_with_debug("([BirthYear] - $#{marker})")[:right][:special_marker].keys).to eq [sym] }
        it { expect(parser.parse_with_debug("[a] == (5 + $#{marker})")[:rstatement][:right][:special_marker].keys).to eq [sym] }
        it { expect(parser.parse_with_debug("[a] < ($#{marker} * 2)")[:rstatement][:left][:special_marker].keys).to eq [sym] }
        it { expect(parser.parse_with_debug("(5 + $#{marker}) > [b]")[:lstatement][:right][:special_marker].keys).to eq [sym] }
        it { expect(parser.parse_with_debug("($#{marker} * 2) != [c]")[:lstatement][:left][:special_marker].keys).to eq [sym] }
        it { expect(parser.parse_with_debug("($#{marker} * 2) / $#{marker}")[:lstatement][:left][:special_marker].keys).to eq [sym] }
        it { expect(parser.parse_with_debug("($#{marker} * 2) / $#{marker}")[:rstatement][:special_marker].keys).to eq [sym] }
      end

      context 'in left position comparison' do
        it { expect(parser.parse_with_debug("$#{marker} == [foo]")[:left][:special_marker].keys).to eq [sym] }
      end

      context 'in right position comparison' do
        it { expect(parser.parse_with_debug("[a] > $#{marker}")[:right][:special_marker].keys).to eq [sym] }
      end

      context 'by itself' do
        it { expect(parser.parse_with_debug("$#{marker}")[:special_marker].keys).to eq [sym] }
        it { expect(parser.parse_with_debug("(((((((($#{marker}))))))))")[:special_marker].keys).to eq [sym] }
      end
    end
  end

  context 'edge cases' do
    context 'regression: recursion errors' do

      context 'single YES/NO factor' do
        let(:expr) { '[YesOrNo] NO' }

        it { expect { parser.parse expr }.not_to raise_error }
        it { expect(parser.parse(expr)).to have_key :left }
        it { expect(parser.parse(expr)[:left]).to have_key :factor }
        it { expect(parser.parse(expr)[:left][:factor].to_s).to eq 'YesOrNo' }
      end

      context 'boolean expression of YES/NO factors' do
        let(:expr) { '[ServesAsChairman] YES AND [ServesAsCEO] YES' }

        it { expect { parser.parse expr }.not_to raise_error }
        it { expect(parser.parse expr).to have_key :boolean_operator }
        it { expect(parser.parse expr).to have_key :lstatement }
        it { expect(parser.parse expr).to have_key :rstatement }

        {
          lstatement: 'ServesAsChairman',
          rstatement: 'ServesAsCEO',
        }.each do |parse_tree_root, factor_name|
          it { expect(parser.parse(expr)[parse_tree_root]).to have_key :left }
          it { expect(parser.parse(expr)[parse_tree_root][:left]).to have_key :factor }
          it { expect(parser.parse(expr)[parse_tree_root][:left][:factor].to_s).to eq factor_name }
          it { expect(parser.parse(expr)[parse_tree_root]).to have_key :yes_no_op }
          it { expect(parser.parse(expr)[parse_tree_root][:yes_no_op]).to have_key :op_yes }
          it { expect(parser.parse(expr)[parse_tree_root][:yes_no_op][:op_yes].to_s).to eq 'YES' }
        end
      end
    end
  end

  context 'math' do
    context "aggregations as math operands" do
      context 'where left is an aggregation' do
        let(:left) { "CNT{type:IssuerPerson, expression: [DirClassificationPAS] == 'Exec'}" }
        let(:right) { "[BoardSize]" }

        it { expect(parser.math_operand.parse_with_debug(left)).to be_a Hash }
        it { expect(parser.math_operand.parse_with_debug(left)[:agg].to_s).to eq '{:op_cnt=>"CNT"@0}' }
        it { expect(parser.math_operand.parse_with_debug(left)[:sub_query_info].to_s).to eq %{type:IssuerPerson, expression: [DirClassificationPAS] == 'Exec'} }
        it { expect(parser.math_operand.parse_with_debug(right)).to be_a Hash }
        it { expect(parser.math_operand.parse_with_debug(right).values.first.to_s).to eq unfactorized[right] }
      end

      context 'where right is an aggregation' do
        let(:left) { "[BoardSize]" }
        let(:right) { "CNT{type:IssuerPerson, expression: [DirClassificationPAS] == 'Exec'}" }

        it { expect(parser.math_operand.parse_with_debug(left)).to be_a Hash }
        it { expect(parser.math_operand.parse_with_debug(left).values.first.to_s).to eq unfactorized[left] }
        it { expect(parser.math_operand.parse_with_debug(right)).to be_a Hash }
        it { expect(parser.math_operand.parse_with_debug(right)[:agg].to_s).to eq '{:op_cnt=>"CNT"@0}' }
        it { expect(parser.math_operand.parse_with_debug(right)[:sub_query_info].to_s).to eq %{type:IssuerPerson, expression: [DirClassificationPAS] == 'Exec'} }
      end

      context 'where both sides are aggregations' do
        let(:left) { "CNT{type:IssuerPerson, expression: [DirClassificationCO] == 'IO'}" }
        let(:right) { "CNT{type:IssuerPerson, expression: [DirClassificationPAS] == 'Exec'}" }

        it { expect(parser.math_operand.parse_with_debug(left)).to be_a Hash }
        it { expect(parser.math_operand.parse_with_debug(left)[:agg].to_s).to eq '{:op_cnt=>"CNT"@0}' }
        it { expect(parser.math_operand.parse_with_debug(left)[:sub_query_info].to_s).to eq %{type:IssuerPerson, expression: [DirClassificationCO] == 'IO'} }
        it { expect(parser.math_operand.parse_with_debug(right)).to be_a Hash }
        it { expect(parser.math_operand.parse_with_debug(right)[:agg].to_s).to eq '{:op_cnt=>"CNT"@0}' }
        it { expect(parser.math_operand.parse_with_debug(right)[:sub_query_info].to_s).to eq %{type:IssuerPerson, expression: [DirClassificationPAS] == 'Exec'} }
      end
    end

    operands = {
      '1234'      => '7.0',
      '[factor1]' => '[factor2]',
      '[factor2]' => '[factor2]',
      '[factor3]' => '4',
      '2.9'       => '[factor]',
      '[factor4]' => %{AVG { type: Issuer, expression: [Foo] == 'bar' }},
      '3.14'      => %{AVG { type: Issuer, expression: [Foo] == 'bar' }},
    }
    operators = {
      '+' => :op_add,
      '-' => :op_subtract,
      '*' => :op_multiply,
      '/' => :op_divide,
      '%' => :op_mod,
      '^' => :op_power,
    }
    let(:unfactorized) { lambda { |e| e.gsub(/[\[\]]/, '') } }

    context 'math operands' do
      operands.each do |left, right|
        it { expect(parser.math_operand.parse_with_debug(left)).to be_a Hash }
        it { expect(parser.math_operand.parse_with_debug(right)).to be_a Hash }
        it { expect(parser.math_operand.parse_with_debug(left).values.first.to_s).to eq unfactorized[left] }

        if left == '[factor4]' || left == '3.14'
          it { expect(parser.math_operand.parse_with_debug(right)).to be_a Hash }
          it { expect(parser.math_operand.parse_with_debug(right)[:sub_query_info].to_s).to eq %{type: Issuer, expression: [Foo] == 'bar'} }
        else
          it { expect(parser.math_operand.parse_with_debug(right).values.first.to_s).to eq unfactorized[right] }
        end
      end
    end

    context 'math operation' do
      operators.each do |op, op_name|
        it { expect(parser.math_operation.parse_with_debug(op)).to be_a Hash }
        it { expect(parser.math_operation.parse_with_debug(op)[op_name].to_s).to eq op }
      end
    end

    operands.each do |left, right|
      operators.each do |op, op_name|
        it "left should be #{left}" do
          expect(parser.equation.parse_with_debug("#{left} #{op} #{right}")[:left].values.first.to_s).to eq unfactorized[left]
        end

        if left == '[factor4]' || left == '3.14'
          it "knows the right is a hash in #{left} #{op} #{right}" do
            expect(parser.parse_with_debug("#{left} #{op} #{right}")[:right]).to be_a Hash
          end
          it "parses the aggregation from #{left} #{op} #{right}" do
            expect(parser.parse_with_debug("#{left} #{op} #{right}")[:right][:agg][:op_avg].to_s).to eq 'AVG'
          end
          it "parses the right from #{left} #{op} #{right}" do
            expect(
              parser.equation.parse_with_debug("#{left} #{op} #{right}")[:right][:sub_query_info].to_s
            ).to eq %{type: Issuer, expression: [Foo] == 'bar'}
          end
        else
          it "right should be #{right}" do
            expect(parser.equation.parse_with_debug("#{left} #{op} #{right}")[:right].values.first.to_s).to eq unfactorized[right]
          end
        end

        it "op_name should be #{op_name}" do
          expect(parser.equation.parse_with_debug("#{left} #{op} #{right}")[op_name].to_s).to eq op
        end

        context 'parenthesized' do
          it "left should be #{left}" do
            expect(parser.parse_with_debug("(#{left} #{op} #{right})")[:left].values.first.to_s).to eq unfactorized[left]
          end

          if left == '[factor4]' || left == '3.14'
            it "knows the right is a hash in (#{left} #{op} #{right})" do
              expect(parser.parse_with_debug("(#{left} #{op} #{right})")[:right]).to be_a Hash
            end
            it "parses the aggregation from (#{left} #{op} #{right})" do
              expect(parser.parse_with_debug("(#{left} #{op} #{right})")[:right][:agg][:op_avg].to_s).to eq 'AVG'
            end
            it "parses the right from (#{left} #{op} #{right})" do
              expect(
                parser.parse_with_debug("(#{left} #{op} #{right})")[:right][:sub_query_info].to_s
              ).to eq %{type: Issuer, expression: [Foo] == 'bar'}
            end
          else
            it "right should be #{right}" do
              expect(parser.equation.parse_with_debug("#{left} #{op} #{right}")[:right].values.first.to_s).to eq unfactorized[right]
            end
          end

          it "op_name should be #{op_name}" do
            expect(parser.parse_with_debug("(#{left} #{op} #{right})")[op_name].to_s).to eq op
          end
        end
      end
    end
  end

  context 'factor' do
    it { expect(parser.parse_with_debug('[abc]')[:value_of][:factor].to_s).to eq 'abc' }

    it { expect(parser.factor.parse_with_debug('[abc]')[:factor].to_s).to eq 'abc' }
    it { expect { parser.factor.parse('[]') }.to raise_error Parslet::ParseFailed }
    it { expect { parser.factor.parse(' [AB cd] ') }.to raise_error Parslet::ParseFailed }

    it { expect(parser.value.parse_with_debug('[abc]  ')[:factor].to_s).to eq 'abc' }
    it { expect(parser.value.parse_with_debug('  [ZyXwVuT]')[:factor]).to eq 'ZyXwVuT' }
    it { expect(parser.value.parse_with_debug(' [AB_cd] ')[:factor].to_s).to eq 'AB_cd' }
  end

  context 'IS NULL' do
    it { expect(parser.statement.parse_with_debug('[foo] IS NULL')[:left][:factor].to_s).to eq 'foo' }
    it { expect(parser.statement.parse_with_debug('[foo] IS NULL')[:op][:op_is_null].to_s).to eq 'IS NULL' }
    it { expect(parser.statement.parse_with_debug('[end_date] IS NULL')[:left][:factor].to_s).to eq 'end_date' }
    it { expect(parser.statement.parse_with_debug('[end_date] IS NULL')[:op][:op_is_null].to_s).to eq 'IS NULL' }
  end

  context 'IS NOT NULL' do
    it { expect(parser.statement.parse_with_debug('[foo] IS NOT NULL')[:left][:factor].to_s).to eq 'foo' }
    it { expect(parser.statement.parse_with_debug('[foo] IS NOT NULL')[:op][:op_is_not_null].to_s).to eq 'IS NOT NULL' }
    it { expect(parser.statement.parse_with_debug('[end_date] IS NOT NULL')[:left][:factor].to_s).to eq 'end_date' }
    it { expect(parser.statement.parse_with_debug('[end_date] IS NOT NULL').tap{|e| pp e}[:op][:op_is_not_null].to_s).to eq 'IS NOT NULL' }
  end

  context 'currency' do
    {
      USD: '0.0',
      FOO: '-100.0',
      BAR: '2.34',
      GBP: '1.0e7',
      AUD: '1.23e-3',
      CHF: '9.01e+4',
    }.each do |curr, str|
      full_str = "#{curr}:#{str}"

      [:currency, :value].each do |rule|
        it "parses [#{full_str}] as a currency using rule[#{rule}]" do
          expect(parser.send(rule).parse_with_debug(full_str)[:currency_value][:float].to_s).to eq str
          expect(parser.send(rule).parse_with_debug(full_str)[:currency_code].to_s).to eq curr.to_s
        end

        it "parses ['#{full_str}'] as a currency using rule[#{rule}]" do
          expect(parser.send(rule).parse_with_debug("'#{full_str}'")[:currency_value][:float].to_s).to eq str
          expect(parser.send(rule).parse_with_debug("'#{full_str}'")[:currency_code].to_s).to eq curr.to_s
        end
      end

      it "parses [    #{full_str}] as a currency using rule[value]" do
        expect(parser.value.parse_with_debug("    #{full_str}")[:currency_value][:float].to_s).to eq str
        expect(parser.value.parse_with_debug("    #{full_str}")[:currency_code].to_s).to eq curr.to_s
      end

      it "parses [#{full_str}   ] as a currency using rule[value]" do
        expect(parser.value.parse_with_debug("#{full_str}   ")[:currency_value][:float].to_s).to eq str
        expect(parser.value.parse_with_debug("#{full_str}   ")[:currency_code].to_s).to eq curr.to_s
      end

      it "parses [    '#{full_str}'] as a currency using rule[value]" do
        expect(parser.value.parse_with_debug("    '#{full_str}'")[:currency_value][:float].to_s).to eq str
        expect(parser.value.parse_with_debug("    '#{full_str}'")[:currency_code].to_s).to eq curr.to_s
      end

      it "parses ['#{full_str}'   ] as a currency using rule[value]" do
        expect(parser.value.parse_with_debug("'#{full_str}'   ")[:currency_value][:float].to_s).to eq str
        expect(parser.value.parse_with_debug("'#{full_str}'   ")[:currency_code].to_s).to eq curr.to_s
      end

      it "parses [ '#{full_str}'   ] as a currency using rule[value]" do
        expect(parser.value.parse_with_debug(" '#{full_str}'   ")[:currency_value][:float].to_s).to eq str
        expect(parser.value.parse_with_debug(" '#{full_str}'   ")[:currency_code].to_s).to eq curr.to_s
      end
    end
  end

  context 'date relational operators' do
    date_relational_operators.each do |op, op_name|
      context op do
        [
          {expr: "[foo] #{op} '05/01/2009'", left: 'foo', right: '05/01/2009'},
          {expr: "[blat] #{op} '2001-03-24'", left: 'blat', right: '2001-03-24'},
        ].each do |struct|
          it { expect(parser.statement.parse_with_debug(struct[:expr])[:left][:factor].to_s).to eq struct[:left] }
          it { expect(parser.statement.parse_with_debug(struct[:expr])[:op][op_name].to_s).to eq op }
          it { expect(parser.statement.parse_with_debug(struct[:expr])[:right][:string]).to eq struct[:right] }
        end
      end
    end
  end

  context 'string relational operators' do
    string_relational_operators.each do |op, op_name|
      context op do
        [
          {expr: "[foo] #{op} 'bar'", left: 'foo', right: 'bar'},
          {expr: "[blat] #{op} 'bar  baz'", left: 'blat', right: 'bar  baz'},
        ].each do |struct|
          it { expect(parser.statement.parse_with_debug(struct[:expr])[:left][:factor].to_s).to eq struct[:left] }
          it { expect(parser.statement.parse_with_debug(struct[:expr])[:op][op_name].to_s).to eq op }
          it { expect(parser.statement.parse_with_debug(struct[:expr])[:right][:string]).to eq struct[:right] }
        end
      end
    end
  end

  context 'string' do
    it do
      expect(parser.string.parse_with_debug("'The quick brown fox jumps over the lazy dog.'")[:string].to_s).to(
        eq('The quick brown fox jumps over the lazy dog.'),
      )
    end
    it do
      expect(parser.value.parse_with_debug("'The quick brown fox jumps over the lazy dog.'")[:string].to_s).to(
        eq('The quick brown fox jumps over the lazy dog.'),
      )
    end
    it { expect(parser.string.parse_with_debug("'a'")[:string].to_s).to eq 'a' }
    it { expect(parser.string.parse_with_debug("'1a'")[:string].to_s).to eq '1a' }
    it { expect(parser.value.parse_with_debug("'a'")[:string].to_s).to eq 'a' }
    it { expect(parser.value.parse_with_debug("'1a'")[:string].to_s).to eq '1a' }

    it { expect(parser.string.parse_with_debug("''")[:string]).to be_empty }
    it { expect(parser.string.parse_with_debug("'a'")[:string].to_s).to eq 'a' }
    it { expect(parser.string.parse_with_debug("' AB cd '")[:string].to_s).to eq ' AB cd ' }

    it { expect(parser.value.parse_with_debug("''")[:string]).to be_empty }
    it { expect(parser.value.parse_with_debug("'a'")[:string].to_s).to eq 'a' }
    it { expect(parser.value.parse_with_debug("' AB cd '")[:string].to_s).to eq ' AB cd ' }
  end

  context 'float' do
    [
      '0.0',
      '-100.0',
      '2.34',
      '-1.912398',
      '1.0e7',
      '1.23e-3',
      '9.01e+4',
      '2.0E3',
      '16.23E-3',
      '329.01E+4',
    ].each do |str|
      it "parses [#{str}] as a float" do
        expect(parser.float.parse_with_debug(str)[:float].to_s).to eq str
      end

      it "parses ['#{str}'] as a float" do
        expect(parser.float.parse_with_debug("'#{str}'")[:float].to_s).to eq str
      end

      it "parses [#{str}] as a float from value" do
        expect(parser.value.parse_with_debug(str)[:float].to_s).to eq str
      end

      it "parses [    #{str}] as a float from value" do
        expect(parser.value.parse_with_debug("    #{str}")[:float].to_s).to eq str
      end

      it "parses [#{str}   ] as a float from value" do
        expect(parser.value.parse_with_debug("#{str}   ")[:float].to_s).to eq str
      end

      it "parses ['#{str}'] as a float from value" do
        expect(parser.value.parse_with_debug("'#{str}'")[:float].to_s).to eq str
      end

      it "parses [    '#{str}'] as a float from value" do
        expect(parser.value.parse_with_debug("    '#{str}'")[:float].to_s).to eq str
      end

      it "parses ['#{str}'   ] as a float from value" do
        expect(parser.value.parse_with_debug("'#{str}'   ")[:float].to_s).to eq str
      end

      it "parses [ '#{str}'   ] as a float from value" do
        expect(parser.value.parse_with_debug(" '#{str}'   ")[:float].to_s).to eq str
      end
    end

    it { expect { parser.float.parse('0') }.to raise_error Parslet::ParseFailed }
  end

  context 'int' do
    ['0', '-100', '234', '-1912398', '2345252345'].each do |str|
      it "parses [#{str}] as a int" do
        expect(parser.int.parse_with_debug(str)[:int].to_s).to eq str
      end

      it "parses ['#{str}'] as a int" do
        expect(parser.int.parse_with_debug("'#{str}'")[:int].to_s).to eq str
      end

      it "parses [#{str}] as an int from value" do
        expect(parser.value.parse_with_debug(str)[:int].to_s).to eq str
      end

      it "parses [    #{str}] as an int from value" do
        expect(parser.value.parse_with_debug("    #{str}")[:int].to_s).to eq str
      end

      it "parses [#{str}   ] as an int from value" do
        expect(parser.value.parse_with_debug("#{str}   ")[:int].to_s).to eq str
      end

      it "parses ['#{str}'] as an int from value" do
        expect(parser.value.parse_with_debug("'#{str}'")[:int].to_s).to eq str
      end

      it "parses [    '#{str}'] as an int from value" do
        expect(parser.value.parse_with_debug("    '#{str}'")[:int].to_s).to eq str
      end

      it "parses ['#{str}'   ] as an int from value" do
        expect(parser.value.parse_with_debug("'#{str}'   ")[:int].to_s).to eq str
      end

      it "parses [ '#{str}'   ] as an int from value" do
        expect(parser.value.parse_with_debug(" '#{str}'   ")[:int].to_s).to eq str
      end
    end

    it { expect { parser.int.parse('0.0') }.to raise_error Parslet::ParseFailed }
  end

  context 'statement =>' do
    context 'array operators =>' do
      array_operators.each do |str, op_name|
        expression_structs = [
          {expr: "[ABCDEF_GHIJK] #{str} '1|2|3|4'",                   right: '1|2|3|4'},
          {expr: "  [ABCDEF_GHIJK]     #{str}   '5|6|7|8'      ",     right: '5|6|7|8'},
          {expr: "([ABCDEF_GHIJK] #{str} '2|4|6')",                   right: '2|4|6'},
          {expr: "  ([ABCDEF_GHIJK]   #{str} 'a10' )    ",            right: 'a10'},
          {expr: "((([ABCDEF_GHIJK] #{str} 'Production|Services')))", right: 'Production|Services'},
        ]

        expression_structs.each do |struct|
          context %{{#{struct[:expr]}}} do
            let(:parsed_statement) do
              stmt = parser.statement.parse_with_debug(struct[:expr])
              stmt[:lstatement] || stmt
            end

            context 'op =>' do
              it { expect(parsed_statement[:op][op_name]).not_to be_nil }
            end

            context 'left =>' do
              it { expect(parsed_statement[:left][:factor].to_s).to eq 'ABCDEF_GHIJK' }
            end

            context 'right =>' do
              it { expect(parsed_statement[:right][:string].to_s).to eq struct[:right] }
            end
          end
        end
      end
    end

    context 'relational operators =>' do
      relational_operators.each do |str, op_name|
        expression_structs = [
          {expr: "1 #{str} 2",                    left: [:int, '1'],      right: [:int, '2']},
          {expr: "  1     #{str}   2      ",      left: [:int, '1'],      right: [:int, '2']},
          {expr: "(1 #{str} 2.9)",                left: [:int, '1'],      right: [:float, '2.9']},
          {expr: "  ([foo]   #{str} '2.0' )    ", left: [:factor, 'foo'], right: [:float, '2.0']},
          {expr: "  ([foo] #{str} 'a2.0' )    ",  left: [:factor, 'foo'], right: [:string, 'a2.0']},
        ]

        expression_structs.each do |struct|
          context %{{#{struct[:expr]}}} do
            let(:parsed_statement) { parser.statement.parse_with_debug(struct[:expr]) }

            context 'op =>' do
              it { expect(parsed_statement[:op][op_name]).not_to be_nil }
            end

            context 'left =>' do
              let(:left) { struct[:left] }
              it { expect(parsed_statement[:left][left.first].to_s).to eq left.last }
            end

            context 'right =>' do
              let(:right) { struct[:right] }
              it { expect(parsed_statement[:right][right.first].to_s).to eq right.last }
            end
          end
        end
      end
    end

    context 'IS operator =>' do
      null_types.each do |null_type|
        [
          "[bar] IS #{null_type}",
          "  [bar]  IS  #{null_type}  ",
          "([bar] IS #{null_type})",
          "   ([bar]    IS  #{null_type})  ",
        ].each do |expr|
          context %{{#{expr}}} do
            let(:parsed_statement) do
              statement = parser.statement.parse_with_debug(expr)
              statement[:lstatement] || statement
            end

            context 'op =>' do
              it { expect(parsed_statement[:op][:op_is].to_s).to eq 'IS' }
            end

            context 'left =>' do
              it { expect(parsed_statement[:left][:factor].to_s).to eq 'bar' }
            end

            context 'right =>' do
              it { expect(parsed_statement[:right][:null_value_type].to_s).to eq null_type }
            end
          end
        end
      end
    end
  end

  context 'CNT' do
    let(:expr) { "CNT {#{sub_expression}}  >= '0'" }
    let(:filter) { "([CaseFlag] == 'Amber' AND [CaseFlag] == 'RED' AND [CaseFlag] == 'Green')" }
    let(:parsed) { parser.aggregation_operator.parse expr }
    let(:sub_expression) { "type: IssuerCase, fields: [], expression: #{filter}" }

    it 'has the sub-expression' do
      expect(parsed[:sub_query_info].to_s).to eq sub_expression
    end

    it 'has the relational operator' do
      expect(parsed[:op][:op_ge]).not_to be_nil
    end

    it 'has the right-hand comparison value' do
      expect(parsed[:right][:int].to_s).to eq '0'
    end
  end

  context 'MAX' do
    let(:expr) { "MAX {#{sub_expression}} GROUP BY [#{grouping_factor}]" }
    let(:field) { 'oekomCarbonRiskRating' }
    let(:grouping_factor) { 'oekomIndustry' }
    let(:parsed) { parser.parse expr }
    let(:sub_expr_parsed) { parser.sub_query_info_parsing.parse sub_query_info }
    let(:sub_expression) { "type: Issuer, fields: [#{field}]" }
    let(:sub_query_info) { parsed[:sub_query_info].to_s }

    it 'has the sub-expression' do
      expect(sub_query_info).to eq sub_expression
    end

    it 'has the grouping factor' do
      expect(parsed[:group_by][:factor].to_s).to eq grouping_factor
    end

    it 'has the field in the subexpression' do
      expect(sub_expr_parsed[:fields][:factor].to_s).to eq field
    end
  end

  context 'top' do
    context 'boolean expressions' do
      let(:nested_not_expr)   { '([foo] = 1) AND NOT ([bar] = 2 OR [baz] = 3)' }
      let(:nested_paren_expr) { '([foo] = 1) AND [bar] != 2' }
      let(:paren_expr)        { '((( [foo] = 1 AND [bar] != 2 ) ) )' }
      let(:simple_expr)       { '[foo] = 1 AND [bar] != 2' }
      let(:simple_not_expr)   { '([foo] = 1) AND NOT [bar] = 2' }

      let(:nested_not)   { parser.top.parse nested_not_expr }
      let(:nested_paren) { parser.top.parse nested_paren_expr }
      let(:paren)        { parser.top.parse paren_expr }
      let(:simpl_not)    { parser.top.parse simple_not_expr }
      let(:simple)       { parser.top.parse simple_expr }

      shared_examples_for 'parsed expression' do
        context 'boolean operator' do
          it { expect(parsed_expr[:boolean_operator]).not_to be_nil }

          context 'op_and' do
            it { expect(parsed_expr[:boolean_operator][:op_and]).not_to be_nil }
          end
        end

        context 'lstatement' do
          it { expect(parsed_expr[:lstatement]).not_to be_nil }

          context 'left' do
            it { expect(parsed_expr[:lstatement][:left]).not_to be_nil }

            context 'factor' do
              it { expect(parsed_expr[:lstatement][:left][:factor]).not_to be_nil }
            end
          end

          context 'op' do
            it { expect(parsed_expr[:lstatement][:op]).not_to be_nil }

            context 'op_eq' do
              it { expect(parsed_expr[:lstatement][:op][:op_eq]).not_to be_nil }
            end
          end

          context 'right' do
            it { expect(parsed_expr[:lstatement][:right]).not_to be_nil }

            context 'int' do
              it { expect(parsed_expr[:lstatement][:right][:int]).not_to be_nil }
            end
          end
        end

        context 'rstatement' do
          it { expect(parsed_expr[:rstatement]).not_to be_nil }

          context 'left' do
            it { expect(parsed_expr[:rstatement][:left]).not_to be_nil }

            context 'factor' do
              it { expect(parsed_expr[:rstatement][:left][:factor]).not_to be_nil }
            end
          end

          context 'op' do
            it { expect(parsed_expr[:rstatement][:op]).not_to be_nil }

            context 'op_ne' do
              it { expect(parsed_expr[:rstatement][:op][:op_ne]).not_to be_nil }
            end
          end

          context 'right' do
            it { expect(parsed_expr[:rstatement][:right]).not_to be_nil }

            context 'int' do
              it { expect(parsed_expr[:rstatement][:right][:int]).not_to be_nil }
            end
          end
        end
      end

      context 'simple expr' do
        let(:parsed_expr) { simple }
        it_behaves_like 'parsed expression'
      end

      context 'parenthetical expr' do
        let(:parsed_expr) { paren }
        it_behaves_like 'parsed expression'
      end

      context 'nested parenthetical expr' do
        let(:parsed_expr) { nested_paren }
        it_behaves_like 'parsed expression'
      end
    end
  end
end
