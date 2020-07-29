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
