# Autogenerated from a Treetop grammar. Edits may be lost.


module SQL
  include Treetop::Runtime

  def root
    @root || :string
  end

  module String0
    def query
      elements[1]
    end
  end

  module String1
    def root
      elements.last
    end
  end

  def _nt_string
    start_index = index
    if node_cache[:string].has_key?(index)
      cached = node_cache[:string][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    r2 = _nt_delimiter
    if r2
      r1 = r2
    else
      r1 = instantiate_node(SyntaxNode,input, index...index)
    end
    s0 << r1
    if r1
      r3 = _nt_query
      s0 << r3
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(String0)
      r0.extend(String1)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:string][start_index] = r0

    r0
  end

  module Query0
    def delim
      elements[0]
    end

    def query
      elements[1]
    end
  end

  module Query1
    def term
      elements[0]
    end

    def query
      elements[1]
    end
  end

  def _nt_query
    start_index = index
    if node_cache[:query].has_key?(index)
      cached = node_cache[:query][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_expression
    s0 << r1
    if r1
      i3, s3 = index, []
      r4 = _nt_delimiter
      s3 << r4
      if r4
        r5 = _nt_query
        s3 << r5
      end
      if s3.last
        r3 = instantiate_node(SyntaxNode,input, i3...index, s3)
        r3.extend(Query0)
      else
        @index = i3
        r3 = nil
      end
      if r3
        r2 = r3
      else
        r2 = instantiate_node(SyntaxNode,input, index...index)
      end
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(QueryString,input, i0...index, s0)
      r0.extend(Query1)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:query][start_index] = r0

    r0
  end

  def _nt_expression
    start_index = index
    if node_cache[:expression].has_key?(index)
      cached = node_cache[:expression][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0 = index
    r1 = _nt_binary_expression
    if r1
      r0 = r1
    else
      r2 = _nt_parenthesized_expression
      if r2
        r0 = r2
      else
        r3 = _nt_unary_expression
        if r3
          r0 = r3
        else
          r4 = _nt_literal
          if r4
            r0 = r4
          else
            @index = i0
            r0 = nil
          end
        end
      end
    end

    node_cache[:expression][start_index] = r0

    r0
  end

  module ParenthesizedExpression0
    def expression
      elements[2]
    end

  end

  module ParenthesizedExpression1
    def expression
      elements[2]
    end
  end

  module ParenthesizedExpression2
    def eval(env={})
      respond_to?(:expression) ? expression.eval( env ) : ""
    end
  end

  def _nt_parenthesized_expression
    start_index = index
    if node_cache[:parenthesized_expression].has_key?(index)
      cached = node_cache[:parenthesized_expression][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0 = index
    i1, s1 = index, []
    if has_terminal?("(", false, index)
      r2 = instantiate_node(SyntaxNode,input, index...(index + 1))
      @index += 1
    else
      terminal_parse_failure("(")
      r2 = nil
    end
    s1 << r2
    if r2
      r4 = _nt_whitespace
      if r4
        r3 = r4
      else
        r3 = instantiate_node(SyntaxNode,input, index...index)
      end
      s1 << r3
      if r3
        r6 = _nt_expression
        if r6
          r5 = r6
        else
          r5 = instantiate_node(SyntaxNode,input, index...index)
        end
        s1 << r5
        if r5
          r8 = _nt_whitespace
          if r8
            r7 = r8
          else
            r7 = instantiate_node(SyntaxNode,input, index...index)
          end
          s1 << r7
          if r7
            if has_terminal?(")", false, index)
              r9 = instantiate_node(SyntaxNode,input, index...(index + 1))
              @index += 1
            else
              terminal_parse_failure(")")
              r9 = nil
            end
            s1 << r9
          end
        end
      end
    end
    if s1.last
      r1 = instantiate_node(SyntaxNode,input, i1...index, s1)
      r1.extend(ParenthesizedExpression0)
    else
      @index = i1
      r1 = nil
    end
    if r1
      r0 = r1
      r0.extend(ParenthesizedExpression2)
    else
      i10, s10 = index, []
      if has_terminal?("(", false, index)
        r11 = instantiate_node(SyntaxNode,input, index...(index + 1))
        @index += 1
      else
        terminal_parse_failure("(")
        r11 = nil
      end
      s10 << r11
      if r11
        r13 = _nt_whitespace
        if r13
          r12 = r13
        else
          r12 = instantiate_node(SyntaxNode,input, index...index)
        end
        s10 << r12
        if r12
          r14 = _nt_expression
          s10 << r14
        end
      end
      if s10.last
        r10 = instantiate_node(SyntaxNode,input, i10...index, s10)
        r10.extend(ParenthesizedExpression1)
      else
        @index = i10
        r10 = nil
      end
      if r10
        r0 = r10
        r0.extend(ParenthesizedExpression2)
      else
        if has_terminal?("(", false, index)
          r15 = instantiate_node(SyntaxNode,input, index...(index + 1))
          @index += 1
        else
          terminal_parse_failure("(")
          r15 = nil
        end
        if r15
          r0 = r15
          r0.extend(ParenthesizedExpression2)
        else
          if has_terminal?(")", false, index)
            r16 = instantiate_node(SyntaxNode,input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure(")")
            r16 = nil
          end
          if r16
            r0 = r16
            r0.extend(ParenthesizedExpression2)
          else
            @index = i0
            r0 = nil
          end
        end
      end
    end

    node_cache[:parenthesized_expression][start_index] = r0

    r0
  end

  def _nt_binary_expression
    start_index = index
    if node_cache[:binary_expression].has_key?(index)
      cached = node_cache[:binary_expression][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0 = index
    r1 = _nt_or_expression
    if r1
      r0 = r1
    else
      r2 = _nt_and_expression
      if r2
        r0 = r2
      else
        @index = i0
        r0 = nil
      end
    end

    node_cache[:binary_expression][start_index] = r0

    r0
  end

  module OrExpression0
    def operand_1
      elements[0]
    end

    def operator
      elements[1]
    end

    def operand_2
      elements[2]
    end
  end

  def _nt_or_expression
    start_index = index
    if node_cache[:or_expression].has_key?(index)
      cached = node_cache[:or_expression][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_or_left_operand
    s0 << r1
    if r1
      r2 = _nt_or_op
      s0 << r2
      if r2
        r3 = _nt_expression
        s0 << r3
      end
    end
    if s0.last
      r0 = instantiate_node(BinaryOperation,input, i0...index, s0)
      r0.extend(OrExpression0)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:or_expression][start_index] = r0

    r0
  end

  module AndExpression0
    def operand_1
      elements[0]
    end

    def operator
      elements[1]
    end

    def operand_2
      elements[2]
    end
  end

  def _nt_and_expression
    start_index = index
    if node_cache[:and_expression].has_key?(index)
      cached = node_cache[:and_expression][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_left_operand
    s0 << r1
    if r1
      r2 = _nt_and_op
      s0 << r2
      if r2
        r3 = _nt_and_right_operand
        s0 << r3
      end
    end
    if s0.last
      r0 = instantiate_node(BinaryOperation,input, i0...index, s0)
      r0.extend(AndExpression0)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:and_expression][start_index] = r0

    r0
  end

  def _nt_left_operand
    start_index = index
    if node_cache[:left_operand].has_key?(index)
      cached = node_cache[:left_operand][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0 = index
    r1 = _nt_parenthesized_expression
    if r1
      r0 = r1
    else
      r2 = _nt_unary_expression
      if r2
        r0 = r2
      else
        r3 = _nt_literal
        if r3
          r0 = r3
        else
          @index = i0
          r0 = nil
        end
      end
    end

    node_cache[:left_operand][start_index] = r0

    r0
  end

  def _nt_right_operand
    start_index = index
    if node_cache[:right_operand].has_key?(index)
      cached = node_cache[:right_operand][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0 = index
    r1 = _nt_parenthesized_expression
    if r1
      r0 = r1
    else
      r2 = _nt_binary_expression
      if r2
        r0 = r2
      else
        r3 = _nt_unary_expression
        if r3
          r0 = r3
        else
          r4 = _nt_literal
          if r4
            r0 = r4
          else
            @index = i0
            r0 = nil
          end
        end
      end
    end

    node_cache[:right_operand][start_index] = r0

    r0
  end

  def _nt_or_left_operand
    start_index = index
    if node_cache[:or_left_operand].has_key?(index)
      cached = node_cache[:or_left_operand][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0 = index
    r1 = _nt_and_expression
    if r1
      r0 = r1
    else
      r2 = _nt_parenthesized_expression
      if r2
        r0 = r2
      else
        r3 = _nt_unary_expression
        if r3
          r0 = r3
        else
          r4 = _nt_literal
          if r4
            r0 = r4
          else
            @index = i0
            r0 = nil
          end
        end
      end
    end

    node_cache[:or_left_operand][start_index] = r0

    r0
  end

  def _nt_and_right_operand
    start_index = index
    if node_cache[:and_right_operand].has_key?(index)
      cached = node_cache[:and_right_operand][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0 = index
    r1 = _nt_parenthesized_expression
    if r1
      r0 = r1
    else
      r2 = _nt_and_expression
      if r2
        r0 = r2
      else
        r3 = _nt_unary_expression
        if r3
          r0 = r3
        else
          r4 = _nt_literal
          if r4
            r0 = r4
          else
            @index = i0
            r0 = nil
          end
        end
      end
    end

    node_cache[:and_right_operand][start_index] = r0

    r0
  end

  module UnaryExpression0
    def operator
      elements[0]
    end

    def operand
      elements[1]
    end
  end

  def _nt_unary_expression
    start_index = index
    if node_cache[:unary_expression].has_key?(index)
      cached = node_cache[:unary_expression][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_not_op
    s0 << r1
    if r1
      i2 = index
      r3 = _nt_parenthesized_expression
      if r3
        r2 = r3
      else
        r4 = _nt_unary_expression
        if r4
          r2 = r4
        else
          r5 = _nt_literal
          if r5
            r2 = r5
          else
            @index = i2
            r2 = nil
          end
        end
      end
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(UnaryOperation,input, i0...index, s0)
      r0.extend(UnaryExpression0)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:unary_expression][start_index] = r0

    r0
  end

  def _nt_literal
    start_index = index
    if node_cache[:literal].has_key?(index)
      cached = node_cache[:literal][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0 = index
    r1 = _nt_single_quoted_literal
    if r1
      r0 = r1
    else
      r2 = _nt_double_quoted_literal
      if r2
        r0 = r2
      else
        r3 = _nt_unquoted_literal
        if r3
          r0 = r3
        else
          r4 = _nt_uncomplete_literal
          if r4
            r0 = r4
          else
            @index = i0
            r0 = nil
          end
        end
      end
    end

    node_cache[:literal][start_index] = r0

    r0
  end

  module SingleQuotedLiteral0
  end

  module SingleQuotedLiteral1
    def single_quote1
      elements[0]
    end

    def text
      elements[1]
    end

    def single_quote2
      elements[2]
    end
  end

  def _nt_single_quoted_literal
    start_index = index
    if node_cache[:single_quoted_literal].has_key?(index)
      cached = node_cache[:single_quoted_literal][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_single_quote
    s0 << r1
    if r1
      s2, i2 = [], index
      loop do
        i3, s3 = index, []
        i4 = index
        r5 = _nt_single_quote
        if r5
          r4 = nil
        else
          @index = i4
          r4 = instantiate_node(SyntaxNode,input, index...index)
        end
        s3 << r4
        if r4
          if index < input_length
            r6 = instantiate_node(SyntaxNode,input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure("any character")
            r6 = nil
          end
          s3 << r6
        end
        if s3.last
          r3 = instantiate_node(SyntaxNode,input, i3...index, s3)
          r3.extend(SingleQuotedLiteral0)
        else
          @index = i3
          r3 = nil
        end
        if r3
          s2 << r3
        else
          break
        end
      end
      r2 = instantiate_node(SyntaxNode,input, i2...index, s2)
      s0 << r2
      if r2
        r7 = _nt_single_quote
        s0 << r7
      end
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(SingleQuotedLiteral1)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:single_quoted_literal][start_index] = r0

    r0
  end

  module DoubleQuotedLiteral0
  end

  module DoubleQuotedLiteral1
    def double_quote1
      elements[0]
    end

    def text
      elements[1]
    end

    def double_quote2
      elements[2]
    end
  end

  def _nt_double_quoted_literal
    start_index = index
    if node_cache[:double_quoted_literal].has_key?(index)
      cached = node_cache[:double_quoted_literal][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_double_quote
    s0 << r1
    if r1
      s2, i2 = [], index
      loop do
        i3, s3 = index, []
        i4 = index
        r5 = _nt_double_quote
        if r5
          r4 = nil
        else
          @index = i4
          r4 = instantiate_node(SyntaxNode,input, index...index)
        end
        s3 << r4
        if r4
          if index < input_length
            r6 = instantiate_node(SyntaxNode,input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure("any character")
            r6 = nil
          end
          s3 << r6
        end
        if s3.last
          r3 = instantiate_node(SyntaxNode,input, i3...index, s3)
          r3.extend(DoubleQuotedLiteral0)
        else
          @index = i3
          r3 = nil
        end
        if r3
          s2 << r3
        else
          break
        end
      end
      r2 = instantiate_node(SyntaxNode,input, i2...index, s2)
      s0 << r2
      if r2
        r7 = _nt_double_quote
        s0 << r7
      end
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(DoubleQuotedLiteral1)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:double_quoted_literal][start_index] = r0

    r0
  end

  module UnquotedLiteral0
  end

  module UnquotedLiteral1
    def text
      elements[1]
    end
  end

  def _nt_unquoted_literal
    start_index = index
    if node_cache[:unquoted_literal].has_key?(index)
      cached = node_cache[:unquoted_literal][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    i1 = index
    r2 = _nt_non_word
    if r2
      r1 = nil
    else
      @index = i1
      r1 = instantiate_node(SyntaxNode,input, index...index)
    end
    s0 << r1
    if r1
      s3, i3 = [], index
      loop do
        i4, s4 = index, []
        i5 = index
        r6 = _nt_non_word
        if r6
          r5 = nil
        else
          @index = i5
          r5 = instantiate_node(SyntaxNode,input, index...index)
        end
        s4 << r5
        if r5
          if index < input_length
            r7 = instantiate_node(SyntaxNode,input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure("any character")
            r7 = nil
          end
          s4 << r7
        end
        if s4.last
          r4 = instantiate_node(SyntaxNode,input, i4...index, s4)
          r4.extend(UnquotedLiteral0)
        else
          @index = i4
          r4 = nil
        end
        if r4
          s3 << r4
        else
          break
        end
      end
      r3 = instantiate_node(SyntaxNode,input, i3...index, s3)
      s0 << r3
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(UnquotedLiteral1)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:unquoted_literal][start_index] = r0

    r0
  end

  module UncompleteLiteral0
  end

  module UncompleteLiteral1
    def quote
      elements[0]
    end

    def text
      elements[1]
    end
  end

  def _nt_uncomplete_literal
    start_index = index
    if node_cache[:uncomplete_literal].has_key?(index)
      cached = node_cache[:uncomplete_literal][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_quote
    s0 << r1
    if r1
      s2, i2 = [], index
      loop do
        i3, s3 = index, []
        i4 = index
        i5 = index
        r6 = _nt_quote
        if r6
          r5 = r6
        else
          r7 = _nt_separator
          if r7
            r5 = r7
          else
            if has_terminal?("(", false, index)
              r8 = instantiate_node(SyntaxNode,input, index...(index + 1))
              @index += 1
            else
              terminal_parse_failure("(")
              r8 = nil
            end
            if r8
              r5 = r8
            else
              if has_terminal?(")", false, index)
                r9 = instantiate_node(SyntaxNode,input, index...(index + 1))
                @index += 1
              else
                terminal_parse_failure(")")
                r9 = nil
              end
              if r9
                r5 = r9
              else
                @index = i5
                r5 = nil
              end
            end
          end
        end
        if r5
          r4 = nil
        else
          @index = i4
          r4 = instantiate_node(SyntaxNode,input, index...index)
        end
        s3 << r4
        if r4
          if index < input_length
            r10 = instantiate_node(SyntaxNode,input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure("any character")
            r10 = nil
          end
          s3 << r10
        end
        if s3.last
          r3 = instantiate_node(SyntaxNode,input, i3...index, s3)
          r3.extend(UncompleteLiteral0)
        else
          @index = i3
          r3 = nil
        end
        if r3
          s2 << r3
        else
          break
        end
      end
      r2 = instantiate_node(SyntaxNode,input, i2...index, s2)
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(UncompleteLiteral1)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:uncomplete_literal][start_index] = r0

    r0
  end

  def _nt_non_word
    start_index = index
    if node_cache[:non_word].has_key?(index)
      cached = node_cache[:non_word][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0 = index
    r1 = _nt_space
    if r1
      r0 = r1
    else
      r2 = _nt_separator
      if r2
        r0 = r2
      else
        if has_terminal?("(", false, index)
          r3 = instantiate_node(SyntaxNode,input, index...(index + 1))
          @index += 1
        else
          terminal_parse_failure("(")
          r3 = nil
        end
        if r3
          r0 = r3
        else
          if has_terminal?(")", false, index)
            r4 = instantiate_node(SyntaxNode,input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure(")")
            r4 = nil
          end
          if r4
            r0 = r4
          else
            @index = i0
            r0 = nil
          end
        end
      end
    end

    node_cache[:non_word][start_index] = r0

    r0
  end

  def _nt_quote
    start_index = index
    if node_cache[:quote].has_key?(index)
      cached = node_cache[:quote][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0 = index
    r1 = _nt_single_quote
    if r1
      r0 = r1
    else
      r2 = _nt_double_quote
      if r2
        r0 = r2
      else
        @index = i0
        r0 = nil
      end
    end

    node_cache[:quote][start_index] = r0

    r0
  end

  module NotOp0
    def whitespace
      elements[1]
    end
  end

  module NotOp1
    def apply( a )
      "( !#{a} )"
    end
  end

  def _nt_not_op
    start_index = index
    if node_cache[:not_op].has_key?(index)
      cached = node_cache[:not_op][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0 = index
    i1, s1 = index, []
    if has_terminal?("NOT", false, index)
      r2 = instantiate_node(SyntaxNode,input, index...(index + 3))
      @index += 3
    else
      terminal_parse_failure("NOT")
      r2 = nil
    end
    s1 << r2
    if r2
      r3 = _nt_whitespace
      s1 << r3
    end
    if s1.last
      r1 = instantiate_node(SyntaxNode,input, i1...index, s1)
      r1.extend(NotOp0)
    else
      @index = i1
      r1 = nil
    end
    if r1
      r0 = r1
      r0.extend(NotOp1)
    else
      if has_terminal?("!", false, index)
        r4 = instantiate_node(SyntaxNode,input, index...(index + 1))
        @index += 1
      else
        terminal_parse_failure("!")
        r4 = nil
      end
      if r4
        r0 = r4
        r0.extend(NotOp1)
      else
        if has_terminal?("~", false, index)
          r5 = instantiate_node(SyntaxNode,input, index...(index + 1))
          @index += 1
        else
          terminal_parse_failure("~")
          r5 = nil
        end
        if r5
          r0 = r5
          r0.extend(NotOp1)
        else
          @index = i0
          r0 = nil
        end
      end
    end

    node_cache[:not_op][start_index] = r0

    r0
  end

  module AndOp0
    def whitespace1
      elements[0]
    end

    def whitespace2
      elements[2]
    end
  end

  module AndOp1
  end

  module AndOp2
  end

  module AndOp3

    def apply( a, b)
      "( #{a} & #{b} )"
    end
  end

  def _nt_and_op
    start_index = index
    if node_cache[:and_op].has_key?(index)
      cached = node_cache[:and_op][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0 = index
    i1, s1 = index, []
    r2 = _nt_whitespace
    s1 << r2
    if r2
      if has_terminal?("AND", false, index)
        r3 = instantiate_node(SyntaxNode,input, index...(index + 3))
        @index += 3
      else
        terminal_parse_failure("AND")
        r3 = nil
      end
      s1 << r3
      if r3
        r4 = _nt_whitespace
        s1 << r4
      end
    end
    if s1.last
      r1 = instantiate_node(SyntaxNode,input, i1...index, s1)
      r1.extend(AndOp0)
    else
      @index = i1
      r1 = nil
    end
    if r1
      r0 = r1
      r0.extend(AndOp3)
    else
      i5, s5 = index, []
      r7 = _nt_whitespace
      if r7
        r6 = r7
      else
        r6 = instantiate_node(SyntaxNode,input, index...index)
      end
      s5 << r6
      if r6
        if has_terminal?("&&", false, index)
          r8 = instantiate_node(SyntaxNode,input, index...(index + 2))
          @index += 2
        else
          terminal_parse_failure("&&")
          r8 = nil
        end
        s5 << r8
        if r8
          r10 = _nt_whitespace
          if r10
            r9 = r10
          else
            r9 = instantiate_node(SyntaxNode,input, index...index)
          end
          s5 << r9
        end
      end
      if s5.last
        r5 = instantiate_node(SyntaxNode,input, i5...index, s5)
        r5.extend(AndOp1)
      else
        @index = i5
        r5 = nil
      end
      if r5
        r0 = r5
        r0.extend(AndOp3)
      else
        i11, s11 = index, []
        r13 = _nt_whitespace
        if r13
          r12 = r13
        else
          r12 = instantiate_node(SyntaxNode,input, index...index)
        end
        s11 << r12
        if r12
          if has_terminal?("&", false, index)
            r14 = instantiate_node(SyntaxNode,input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure("&")
            r14 = nil
          end
          s11 << r14
          if r14
            r16 = _nt_whitespace
            if r16
              r15 = r16
            else
              r15 = instantiate_node(SyntaxNode,input, index...index)
            end
            s11 << r15
          end
        end
        if s11.last
          r11 = instantiate_node(SyntaxNode,input, i11...index, s11)
          r11.extend(AndOp2)
        else
          @index = i11
          r11 = nil
        end
        if r11
          r0 = r11
          r0.extend(AndOp3)
        else
          @index = i0
          r0 = nil
        end
      end
    end

    node_cache[:and_op][start_index] = r0

    r0
  end

  module OrOp0
    def whitespace1
      elements[0]
    end

    def whitespace2
      elements[2]
    end
  end

  module OrOp1
  end

  module OrOp2
  end

  module OrOp3
    def apply( a, b )
      "( #{a} | #{b} )"
    end
  end

  def _nt_or_op
    start_index = index
    if node_cache[:or_op].has_key?(index)
      cached = node_cache[:or_op][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0 = index
    i1, s1 = index, []
    r2 = _nt_whitespace
    s1 << r2
    if r2
      if has_terminal?("OR", false, index)
        r3 = instantiate_node(SyntaxNode,input, index...(index + 2))
        @index += 2
      else
        terminal_parse_failure("OR")
        r3 = nil
      end
      s1 << r3
      if r3
        r4 = _nt_whitespace
        s1 << r4
      end
    end
    if s1.last
      r1 = instantiate_node(SyntaxNode,input, i1...index, s1)
      r1.extend(OrOp0)
    else
      @index = i1
      r1 = nil
    end
    if r1
      r0 = r1
      r0.extend(OrOp3)
    else
      i5, s5 = index, []
      r7 = _nt_whitespace
      if r7
        r6 = r7
      else
        r6 = instantiate_node(SyntaxNode,input, index...index)
      end
      s5 << r6
      if r6
        if has_terminal?("||", false, index)
          r8 = instantiate_node(SyntaxNode,input, index...(index + 2))
          @index += 2
        else
          terminal_parse_failure("||")
          r8 = nil
        end
        s5 << r8
        if r8
          r10 = _nt_whitespace
          if r10
            r9 = r10
          else
            r9 = instantiate_node(SyntaxNode,input, index...index)
          end
          s5 << r9
        end
      end
      if s5.last
        r5 = instantiate_node(SyntaxNode,input, i5...index, s5)
        r5.extend(OrOp1)
      else
        @index = i5
        r5 = nil
      end
      if r5
        r0 = r5
        r0.extend(OrOp3)
      else
        i11, s11 = index, []
        r13 = _nt_whitespace
        if r13
          r12 = r13
        else
          r12 = instantiate_node(SyntaxNode,input, index...index)
        end
        s11 << r12
        if r12
          if has_terminal?("|", false, index)
            r14 = instantiate_node(SyntaxNode,input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure("|")
            r14 = nil
          end
          s11 << r14
          if r14
            r16 = _nt_whitespace
            if r16
              r15 = r16
            else
              r15 = instantiate_node(SyntaxNode,input, index...index)
            end
            s11 << r15
          end
        end
        if s11.last
          r11 = instantiate_node(SyntaxNode,input, i11...index, s11)
          r11.extend(OrOp2)
        else
          @index = i11
          r11 = nil
        end
        if r11
          r0 = r11
          r0.extend(OrOp3)
        else
          @index = i0
          r0 = nil
        end
      end
    end

    node_cache[:or_op][start_index] = r0

    r0
  end

  def _nt_single_quote
    start_index = index
    if node_cache[:single_quote].has_key?(index)
      cached = node_cache[:single_quote][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    if has_terminal?("'", false, index)
      r0 = instantiate_node(SyntaxNode,input, index...(index + 1))
      @index += 1
    else
      terminal_parse_failure("'")
      r0 = nil
    end

    node_cache[:single_quote][start_index] = r0

    r0
  end

  def _nt_double_quote
    start_index = index
    if node_cache[:double_quote].has_key?(index)
      cached = node_cache[:double_quote][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    if has_terminal?('"', false, index)
      r0 = instantiate_node(SyntaxNode,input, index...(index + 1))
      @index += 1
    else
      terminal_parse_failure('"')
      r0 = nil
    end

    node_cache[:double_quote][start_index] = r0

    r0
  end

  def _nt_delimiter
    start_index = index
    if node_cache[:delimiter].has_key?(index)
      cached = node_cache[:delimiter][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    s0, i0 = [], index
    loop do
      i1 = index
      r2 = _nt_space
      if r2
        r1 = r2
      else
        r3 = _nt_separator
        if r3
          r1 = r3
        else
          @index = i1
          r1 = nil
        end
      end
      if r1
        s0 << r1
      else
        break
      end
    end
    if s0.empty?
      @index = i0
      r0 = nil
    else
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
    end

    node_cache[:delimiter][start_index] = r0

    r0
  end

  def _nt_whitespace
    start_index = index
    if node_cache[:whitespace].has_key?(index)
      cached = node_cache[:whitespace][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    s0, i0 = [], index
    loop do
      r1 = _nt_space
      if r1
        s0 << r1
      else
        break
      end
    end
    if s0.empty?
      @index = i0
      r0 = nil
    else
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
    end

    node_cache[:whitespace][start_index] = r0

    r0
  end

  def _nt_space
    start_index = index
    if node_cache[:space].has_key?(index)
      cached = node_cache[:space][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    if has_terminal?('\G[ \\n\\r\\t]', true, index)
      r0 = instantiate_node(SyntaxNode,input, index...(index + 1))
      @index += 1
    else
      r0 = nil
    end

    node_cache[:space][start_index] = r0

    r0
  end

  def _nt_separator
    start_index = index
    if node_cache[:separator].has_key?(index)
      cached = node_cache[:separator][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    if has_terminal?('\G[\\,]', true, index)
      r0 = instantiate_node(SyntaxNode,input, index...(index + 1))
      @index += 1
    else
      r0 = nil
    end

    node_cache[:separator][start_index] = r0

    r0
  end

end

class SQLParser < Treetop::Runtime::CompiledParser
  include SQL
end