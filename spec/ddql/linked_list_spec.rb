describe DDQL::LinkedList do
  let(:list) { described_class.new }

  context 'initialization' do
    it { expect(list.head).to be nil }
    it { expect(list.size).to be 0 }
    it { expect(list.doubly_linked?).to be false }
  end

  context '#poll' do
    before :each do
      (1..5).each { |e| list << e }
    end

    example 'removes the node from the list' do
      nodes = []
      nodes << list.poll
      expect(list.size).to eq 4
      nodes << list.poll
      expect(list.size).to eq 3
      nodes << list.poll
      expect(list.size).to eq 2
      nodes << list.poll
      expect(list.size).to eq 1
      nodes << list.poll
      expect(list.size).to eq 0
      expect(nodes).to eq [1, 2, 3, 4, 5]
    end

    example 'nodes should no longer be connected' do
      nodes = []
      list.poll do |node|
        nodes << node
      end
      nodes.each do |node|
        expect(node.next).to be nil
        expect(node.previous).to be nil
      end
    end
  end

  context 'finding nodes' do
    let(:list) { described_class.new.tap { |l| (1..5).each { |e| l << e } } }

    context '#find' do
      context 'with block' do
        shared_examples_for 'moving forward' do
          it { expect(list.find {|n, v| n.value == 1 }).to be list.head }
          it { expect(list.find {|n, v| n.value == 1 }.value).to eq 1 }
          it { expect(list.find {|n, v| n.value == 2 }.value).to eq 2 }
          it { expect(list.find {|n, v| n.value == 3 }.value).to eq 3 }
          it { expect(list.find {|n, v| n.value == 4 }.value).to eq 4 }
          it { expect(list.find {|n, v| n.value == 5 }.value).to eq 5 }
          it { expect(list.find {|n, v| n.value == 5 }).to be list.tail }

          it { expect(list.find {|n, v| n.value == 1 }.next.value).to eq 2 }
          it { expect(list.find {|n, v| n.value == 2 }.next.value).to eq 3 }
          it { expect(list.find {|n, v| n.value == 3 }.next.value).to eq 4 }
          it { expect(list.find {|n, v| n.value == 4 }.next.value).to eq 5 }
          it { expect(list.find {|n, v| n.value == 5 }.next).to be nil }
        end

        context 'doubly-linked' do
          before :each do
            list.doubly_linked!
          end
          it_behaves_like 'moving forward'

          it { expect(list.find {|n| n.value == 1 }.previous).to be nil  }
          it { expect(list.find {|n| n.value == 2 }.previous.value).to eq 1 }
          it { expect(list.find {|n| n.value == 3 }.previous.value).to eq 2 }
          it { expect(list.find {|n| n.value == 4 }.previous.value).to eq 3 }
          it { expect(list.find {|n| n.value == 5 }.previous.value).to eq 4 }
          it { expect(list.find {|n| n.value == 6 }).to be nil }
        end

        context 'singly-linked' do
          it_behaves_like 'moving forward'
        end
      end

      context 'with value' do
        shared_examples_for 'moving forward' do
          it { expect(list.find(1)).to be list.head }
          it { expect(list.find(1).value).to eq 1 }
          it { expect(list.find(2).value).to eq 2 }
          it { expect(list.find(3).value).to eq 3 }
          it { expect(list.find(4).value).to eq 4 }
          it { expect(list.find(5).value).to eq 5 }
          it { expect(list.find(5)).to be list.tail }

          it { expect(list.find(1).next.value).to eq 2 }
          it { expect(list.find(2).next.value).to eq 3 }
          it { expect(list.find(3).next.value).to eq 4 }
          it { expect(list.find(4).next.value).to eq 5 }
          it { expect(list.find(5).next).to be nil }
        end

        context 'doubly-linked' do
          before :each do
            list.doubly_linked!
          end
          it_behaves_like 'moving forward'

          it { expect(list.find(1).previous).to be nil  }
          it { expect(list.find(2).previous.value).to eq 1 }
          it { expect(list.find(3).previous.value).to eq 2 }
          it { expect(list.find(4).previous.value).to eq 3 }
          it { expect(list.find(5).previous.value).to eq 4 }
        end

        context 'singly-linked' do
          it_behaves_like 'moving forward'
        end
      end
    end

    context '#find_from_tail' do
      context 'with block' do
        shared_examples_for 'moving backward' do
          it { expect(list.find_from_tail {|n, v| n.value == 1 }).to be list.head }
          it { expect(list.find_from_tail {|n, v| n.value == 1 }.value).to eq 1 }
          it { expect(list.find_from_tail {|n, v| n.value == 2 }.value).to eq 2 }
          it { expect(list.find_from_tail {|n, v| n.value == 3 }.value).to eq 3 }
          it { expect(list.find_from_tail {|n, v| n.value == 4 }.value).to eq 4 }
          it { expect(list.find_from_tail {|n, v| n.value == 5 }.value).to eq 5 }
          it { expect(list.find_from_tail {|n, v| n.value == 5 }).to be list.tail }

          it { expect(list.find_from_tail {|n, v| n.value == 1 }.next.value).to eq 2 }
          it { expect(list.find_from_tail {|n, v| n.value == 2 }.next.value).to eq 3 }
          it { expect(list.find_from_tail {|n, v| n.value == 3 }.next.value).to eq 4 }
          it { expect(list.find_from_tail {|n, v| n.value == 4 }.next.value).to eq 5 }
          it { expect(list.find_from_tail {|n, v| n.value == 5 }.next).to be nil }
        end

        context 'doubly-linked' do
          before :each do
            list.doubly_linked!
          end
          it_behaves_like 'moving backward'

          it { expect(list.find_from_tail {|n| n.value == 1 }.previous).to be nil  }
          it { expect(list.find_from_tail {|n| n.value == 2 }.previous.value).to eq 1 }
          it { expect(list.find_from_tail {|n| n.value == 3 }.previous.value).to eq 2 }
          it { expect(list.find_from_tail {|n| n.value == 4 }.previous.value).to eq 3 }
          it { expect(list.find_from_tail {|n| n.value == 5 }.previous.value).to eq 4 }
          it { expect(list.find_from_tail {|n| n.value == 6 }).to be nil }
        end

        context 'singly-linked' do
          it { expect { list.find_from_tail {|n| true } }.to raise_error described_class::NavigationError }
        end
      end

      context 'with value' do
        context 'doubly-linked' do
          before :each do
            list.doubly_linked!
          end

          it { expect(list.find_from_tail(1)).to be list.head }
          it { expect(list.find_from_tail(1).value).to eq 1 }
          it { expect(list.find_from_tail(2).value).to eq 2 }
          it { expect(list.find_from_tail(3).value).to eq 3 }
          it { expect(list.find_from_tail(4).value).to eq 4 }
          it { expect(list.find_from_tail(5).value).to eq 5 }
          it { expect(list.find_from_tail(5)).to be list.tail }

          it { expect(list.find_from_tail(1).next.value).to eq 2 }
          it { expect(list.find_from_tail(2).next.value).to eq 3 }
          it { expect(list.find_from_tail(3).next.value).to eq 4 }
          it { expect(list.find_from_tail(4).next.value).to eq 5 }
          it { expect(list.find_from_tail(5).next).to be nil }

          it { expect(list.find_from_tail(1).previous).to be nil  }
          it { expect(list.find_from_tail(2).previous.value).to eq 1 }
          it { expect(list.find_from_tail(3).previous.value).to eq 2 }
          it { expect(list.find_from_tail(4).previous.value).to eq 3 }
          it { expect(list.find_from_tail(5).previous.value).to eq 4 }
        end

        context 'singly-linked' do
          it { expect { list.find_from_tail(1) }.to raise_error described_class::NavigationError }
        end
      end
    end
  end

  context '#size' do
    example 'increases' do
      (1..10).each do |n|
        list << n
        expect(list.size).to be n
      end
    end

    example 'decreases' do
      (1..4).each { |n| list << n }
      (-3..0).each do |n|
        list.delete(list.tail)
        expect(list.size).to eq(-n)
      end
    end
  end

  context '#delete' do
    let(:nums) { (2..10).to_a.shuffle + (2..7).to_a.shuffle }

    before :each do
      list << 1
      nums.each { |n| list << n }
      list << 1
    end

    example 'deleting head by value' do
      list.delete 1
      expect(list.head.value).to eq nums.first
      expect(list.tail.value).to eq 1
    end

    example 'deleting head by reference' do
      list.delete list.head
      expect(list.head.value).to eq nums.first
      expect(list.tail.value).to eq 1
    end

    example 'deleting tail by reference' do
      list.delete list.tail
      expect(list.head.value).to eq 1
      expect(list.tail.value).to eq nums.last
    end

    example 'deleting everything from the head' do
      list.size.times { list.delete list.head }
      expect(list.head).to be nil
      expect(list.size).to eq 0
    end

    example 'deleting everything from the tail' do
      list.size.times { list.delete list.tail }
      expect(list.head).to be nil
      expect(list.size).to eq 0
    end

    example "deleting preserves previous links" do
      list.doubly_linked!.delete list.tail
      expect(list.tail.previous).not_to be nil
      remaining_nums = [1] + nums
      remaining_nums.each.with_index do |num, index|
        node = list.head
        index.times { |_| node = node.next }
        expect(node.value).to eq num
        if index == 0
          expect(node.previous).to be nil
        else
          expect(node.previous.value).to eq remaining_nums[index - 1]
        end
      end
    end

    example "deleting middle updates all links" do
      list = described_class.new.doubly_linked!
      (1..4).each { |e| list << e }
      list.delete(list.at(2))
      expect(list.at(2)).to eq list.tail
      expect(list.at(2).next).to be nil
      expect(list.at(2).previous).to be list.at(1)
    end
  end

  context '#append' do
    example 'head should be first item' do
      list.append 1
      expect(list.head.value).to eq 1
    end

    example 'tail should be head' do
      list.append 1
      expect(list.tail).to be list.head
    end

    example 'appends multiple values' do
      [1,2,3,4].each { |e| list << e }
      expect(list.head.value).to eq 1
      expect(list.head.next.value).to eq 2
      expect(list.head.next.next.value).to eq 3
      expect(list.tail.value).to eq 4
    end
  end

  context '#append_after' do
    before :each do
      [1,2,4].each { |e| list << e }
    end

    example 'inserts new value' do
      list.append_after(2, 3)
      expect(list.head.value).to eq 1
      expect(list.head.next.value).to eq 2
      expect(list.head.next.next.value).to eq 3
      expect(list.tail.value).to eq 4
    end

    example 'returns the inserted node in a singly-linked list' do
      node = list.append_after(2, 3)
      expect(node.value).to eq 3
      expect(node.previous).to be nil
      expect(node.next.value).to eq 4
    end

    example 'returns the inserted node in a doubly-linked list' do
      node = list.doubly_linked!.append_after(2, 3)
      expect(node.value).to eq 3
      expect(node.previous.value).to eq 2
      expect(node.next.value).to eq 4
    end
  end

  context '#at' do
    let(:list) { described_class.new }

    before :each do
      (1..4).each { |e| list << e }
    end

    example 'finds head' do
      expect(list.at(0)).to be list.head
    end

    example 'finds tail' do
      expect(list.at(list.size - 1)).to be list.tail
    end

    example 'finds node in middle' do
      expect(list.at(1).value).to eq 2
      expect(list.at(2).value).to eq 3
    end

    example 'returns nil' do
      expect(list.at(-1)).to be nil
      expect(list.at(list.size)).to be nil
    end
  end

  context '#replace' do
    before :each do
      [1,2,3,4,5,6].each { |e| list << e }
    end

    shared_examples_for 'values and/or nodes' do
      example 'are properly replaced' do
        expect(list.replace!(from: from, to: to, with: with).map.to_a).to eq expected
      end
    end

    example 'sets previous link for each node' do
      list.doubly_linked!.replace!(from: 2, to: 4, with: 3)
      expect(list.find(3).previous).to eq list.head
      expect(list.find(5).previous).to be list.find(3)
      expect(list.find(6).previous).to be list.find(5)
    end

    context 'with all nodes' do
      let(:from)     { list.head.next }                # 2
      let(:to)       { list.head.next.next.next.next } # 5
      let(:with)     { described_class::Node.new('a') }
      let(:expected) { [1, with.value, 6 ] }
      it_behaves_like 'values and/or nodes'
    end

    context 'with all values' do
      let(:from)     { 3 }
      let(:to)       { 6 }
      let(:with)     { 'hee hee' }
      let(:expected) { [1, 2, with] }
      it_behaves_like 'values and/or nodes'
    end

    context 'with nodes and values' do
      let(:from)     { list.head }
      let(:to)       { 4 }
      let(:with)     { :foobar }
      let(:expected) { [with, 5, 6] }
      it_behaves_like 'values and/or nodes'
    end

    context 'handles head replacement' do
      let(:from)     { list.head }
      let(:to)       { list.head }
      let(:with)     { 10 }
      let(:expected) { [with, 2, 3, 4, 5, 6] }
    end

    context 'handles tail replacement' do
      let(:from)     { list.tail }
      let(:to)       { list.tail }
      let(:with)     { 5.5 }
      let(:expected) { [1, 2, 3, 4, 5, with] }
    end

    context 'handles full list replacement' do
      let(:from)     { list.head }
      let(:to)       { list.tail }
      let(:with)     { 5.5 }
      let(:expected) { [5.5] }
    end

    context 'handles single node replacement' do
      let(:from)     { list.find(5) }
      let(:to)       { list.find(5) }
      let(:with)     { 5.5 }
      let(:expected) { [1, 2, 3, 4, with, 6] }
    end
  end

  context 'becoming doubly linked' do
    before :each do
      (1..10).each { |n| list << n }
      list.doubly_linked!
    end

    it 'thinks it is doubly linked' do
      expect(list.doubly_linked?).to be true
    end

    it 'behaves as a doubly linked list' do
      expect(list.head.previous).to be nil
      expect(list.head.next.previous).to be list.head
      node = list.tail
      (1..9).to_a.reverse.each do |n|
        expect(node.previous.value).to be n
        node = node.previous
      end
      expect(node.previous).to be nil
    end

    context 'becoming singly linked' do
      before :each do
        list.doubly_linked!.singly_linked!
      end

      it 'thinks it is singly linked' do
        expect(list.doubly_linked?).to be false
      end
    end
  end
end
