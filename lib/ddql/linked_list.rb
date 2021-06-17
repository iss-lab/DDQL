module DDQL
  class LinkedList
    include Enumerable

    class NavigationError < StandardError
    end

    class Node
      attr_accessor :next, :previous
      attr_reader   :value

      def initialize(value, next_node: nil, previous_node: nil)
        @next     = next_node
        @previous = previous_node
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
      @size          = head.nil? ? 0 : 1
      @tail          = @head
    end

    def append(value)
      if @head
        tail = find_tail
        if Node === value
          value.previous = tail if @doubly_linked
          tail.next = value
        else
          tail.next = Node.new(value)
          tail.next.previous = tail if @doubly_linked
        end
        @tail = tail.next
      else
        @head = @tail = Node === value ? value : Node.new(value)
      end
      @size += 1
    end
    alias :<< :append

    # Insert the +value+ after the +target+
    #
    # @return [Node|NilClass] nil if +target+ is not found, otherwise the inserted node for +value+
    def append_after(target, value)
      node = find(target)
      return unless node
      old_next = node.next
      if @doubly_linked
        if Node === value
          value.previous = node
          value.next     = old_next
          node.next      = value
        else
          node.next = Node.new(value, previous_node: node, next_node: old_next)
        end
      elsif Node === value
        value.next = old_next
        node.next  = value
      else
        node.next = Node.new(value, next_node: old_next)
      end
      @tail = node.next if old_next.nil?
      node.next
    end
    alias :insert :append_after

    def at(index)
      return nil if index < 0 || index >= size
      return @head if index == 0
      return @tail if index == size - 1

      current_index = 0
      current_node  = head
      while current_node = current_node.next
        current_index += 1
        return current_node if current_index == index
      end
    end
    alias :[] :at

    def delete(value)
      if value.is_a?(Node) && @head == value
        @head = @head.next
        value.next = value.previous = nil
        @tail = @head if @head.nil? || @head.next.nil?
      elsif @head.value == value
        node = @head.next
        @head.next = @head.previous = nil
        value = @head
        @head = node
        @tail = @head if @head.next.nil?
      else
        node = find_before(value)

        if node && node.next == tail
          @tail = node
          node.next = nil
        end

        node.next = node.next.next if node && node.next
        node.next.previous = node if doubly_linked! && node.next
      end
      @size -= 1
      value
    end

    def doubly_linked!
      return self if doubly_linked?

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

    def each
      return to_enum unless block_given?
      node = @head
      while node
        yield node.value
        node = node.next
      end
    end

    def empty?
      @size == 0
    end

    def find(value=nil, &blk)
      node = @head
      is_node = value.is_a?(Node)
      return false if !node.next && (!blk || (blk && !yield(node)))
      return node  if (is_node && node == value) || node.value == value || (blk && yield(node))
      while (node = node.next)
        return node if (is_node && node == value) || node.value == value || (blk && yield(node))
      end
    end

    def find_from_tail(value=nil, &blk)
      raise NavigationError, "singly-linked lists don't support finding nodes from the tail" unless doubly_linked?
      node = @tail
      is_node = value.is_a?(Node)
      return false if !node.previous && (!blk || (blk && !yield(node)))
      return node  if (is_node && node == value) || node.value == value || (blk && yield(node))
      while (node = node.previous)
        return node if (is_node && node == value) || node.value == value || (blk && yield(node))
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
      if @tail.nil?
        node = @head
        return @tail = node if !node.next
        return @tail = node if !node.next while (node = node.next)
      end
      @tail
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

    # Replace a range of nodes from +from+ to +to+, inclusive,
    # with the given +with+. +from+, +to+, and +with+ can all
    # be values or nodes.
    #
    # @return self
    def replace!(from:, to:, with:)
      first_node = find(from)
      last_node  = find(to)
      tail       = find_tail
      raise 'cannot find appropriate range for replacement' if first_node.nil? || last_node.nil?

      replacement = Node === with ? with : Node.new(with)
      if first_node == head
        @head = replacement
        unless last_node == tail
          new_tail          = last_node.next
          replacement.next  = new_tail
          new_tail.previous = replacement if doubly_linked?
        end
        return self
      end

      if doubly_linked?
        replacement.previous      = first_node.previous
        replacement.previous.next = replacement
        last_node.next.previous   = replacement
      elsif first_node != head
        previous = find_before(first_node)
        previous.next = replacement
      end
      replacement.next = last_node.next
      self
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
