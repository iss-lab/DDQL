module DDQL
  class LinkedList
    include Enumerable

    class Node
      attr_accessor :next, :previous
      attr_reader   :value

      def initialize(value)
        @next     = nil
        @previous = nil
        @value    = value
      end

      def to_s
        "Node[#{@value}]"
      end
    end

    attr_reader :head, :size

    def initialize(head=nil)
      @doubly_linked = false
      @head          = head
      @size          = 0
    end

    def append(value)
      if @head
        tail = find_tail
        tail.next = Node.new(value)
        tail.next.previous = tail if @doubly_linked
      else
        @head = Node.new(value)
      end
      @size += 1
    end
    alias :<< :append

    def append_after(target, value)
      node           = find(target)
      return unless node
      old_next       = node.next
      node.next      = Node.new(value)
      node.next.next = old_next
    end

    def doubly_linked!
      current = nil
      each_node do |node|
        node.previous = current
        current = node
      end
      @doubly_linked = true
      self
    end

    def doubly_linked?
      @doubly_linked
    end

    def delete(value)
      if value.is_a?(Node) && @head == value
        @head = @head.next
        value.next = value.previous = nil
      elsif @head.value == value
        node = @head.next
        @head.next = @head.previous = nil
        value = @head
        @head = node
      else
        node = find_before(value)
        node.next = node.next.next if node && node.next
        node.next = node.previous = nil if node
      end
      @size -= 1
      value
    end

    def each
      return to_enum unless block_given?
      node = @head
      while node
        yield node.value
        node = node.next
      end
    end

    def find(value)
      node = @head
      is_node = value.is_a?(Node)
      return false if !node.next
      return node  if (is_node && node == value) || node.value == value
      while (node = node.next)
        return node if (is_node && node == value) || node.value == value
      end
    end

    def find_before(value)
      node = @head
      return false if !node.next

      is_node = value.is_a?(Node)
      if (is_node && node.next == value) || node.next.value == value
        return node
      end

      while (node = node.next)
        if (is_node && node.next == value) || node.next.value == value
          return node
        end
      end
    end

    def find_tail
      node = @head
      return node if !node.next
      return node if !node.next while (node = node.next)
    end
    alias :tail :find_tail

    def peek
      return nil unless @head
      @head.value
    end

    def poll
      return nil unless @head
      previous_head = @head
      @head = previous_head.next
      @size -= 1
      @head.previous = nil if @head
      previous_head.next = nil
      previous_head.value
    end

    def print(stream=STDOUT)
      node = @head
      prefix = ''
      postfix = ''
      stream.print "(size: #{size}) "
      while node
        postfix = "\n⨂" unless node.next
        stream.print prefix
        stream.print node
        stream.print postfix
        stream.print "\n"
        node = node.next
        prefix = '  ⤿  ' if node
      end
    end

    def singly_linked!
      each_node do |node|
        node.previous = nil
      end
      @doubly_linked = false
      self
    end

    private
    def each_node
      raise 'requires a block' unless block_given?
      node = @head
      while node
        yield node
        node = node.next
      end
    end
  end
end
