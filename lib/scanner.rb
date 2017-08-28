module AHACompiler
  #This Class, handles the tokenization of source code
  class Scanner
    attr_accessor :cv, :stp, :cvt, :declaration_mode, :current_st, :global_st, :main_st, :state, :current_token
    def initialize(fileAddress, errorHandler, global_st, main_st)
      @current_token = "" #for debug purpose only
      @current_st = global_st
      @main_st = main_st
      @global_st = global_st

      @declaration_mode = false
      @cvt = nil      
      @state = :normal
      @errors = errorHandler.errors
      @MaximumErrorTolerance = 4
      @line = ""
      @lineCount = 1
      @columnCount = 0
      @struct_dec_mode = false
      if (File.exist?(fileAddress))
        @file = File.new(fileAddress, "r");
        @c = next_char
      else
        raise IOError , "AHAScanner says: \"File not found! Check the source file address\""
      end
      fill_main_symbol_table
    end


    #This method generates the next token for the Parser
    def next_token
      #dputs "@line: " + @line
      if @state == :normal
        while true
          temp = _next_token
          unless temp == "#white_space"  || temp == "#comment"
            break
          end
        end
        #dputs "token: " + temp
        @current_token = temp
        return temp
      else
        return :Terminate
      end
      
    end

    private
    def fill_main_symbol_table
      @main_st.entries.push(SymbolTableEntry.new("$temp0", :sid, SimpleDSCP.new(0, nil)))
      @main_st.entries.push(SymbolTableEntry.new("$temp1", :sid, SimpleDSCP.new(1, nil)))
      @main_st.entries.push(SymbolTableEntry.new("$temp2", :sid, SimpleDSCP.new(2, nil)))
      @main_st.entries.push(SymbolTableEntry.new("$temp3", :sid, SimpleDSCP.new(3, nil)))
      @main_st.entries.push(SymbolTableEntry.new("$returnValue1", :sid, SimpleDSCP.new(4, nil)))
      @main_st.entries.push(SymbolTableEntry.new("$returnValue2", :sid, SimpleDSCP.new(5, nil)))
      

      keywords = %w{break continue else for if readfloat
           readint return struct writetext writefloat writeint}
      keywords.each {|keyword| @main_st.entries.push(SymbolTableEntry.new(keyword, :kw))}

      @main_st.entries.push(SymbolTableEntry.new("false", :bool_literal))
      @main_st.entries.push(SymbolTableEntry.new("true", :bool_literal))
      @main_st.entries.push(SymbolTableEntry.new("float", :st, SimpleDSCP.new(nil,:float)))
      @main_st.entries.push(SymbolTableEntry.new("int", :st, SimpleDSCP.new(nil,:int)))
      @main_st.entries.push(SymbolTableEntry.new("string", :st, SimpleDSCP.new(nil,:string)))
      @main_st.entries.push(SymbolTableEntry.new("boolean", :st, SimpleDSCP.new(nil,:bool)))
      @main_st.entries.push(SymbolTableEntry.new("void", :st, SimpleDSCP.new(nil,:void)))
    end

    def find_keyword(value)
      @stp = @main_st.entries.detect {|entry| entry.name == value}
      if @stp
        return @stp.name if (@stp.idKind == :kw || @stp.idKind == :st)

        if @stp.idKind == :bool_literal
          @cvt = :bool
          if @stp.name == "true"
            @cv = "true"
          else
            @cv = "false"
          end
          return "bool_literal"
        elsif @stp.idKind == :strt
            return "id"
        end
      end

      if @declaration_mode
        @stp = @current_st.entries.detect {|entry| entry.name == value}

        unless @stp
          @current_st.entries.push(SymbolTableEntry.new(value))
          @stp = @current_st.entries.last
          return "id"
        else
          if @stp.idKind == :strt
            create_error(:error_double_struct_declare, true)
            return "id"
          else
            create_error(:error_double_id_declare, true)
            return "id"
          end

        end
      end
      #else
      p = @current_st
      while p
        #dputs "ST in findKeyword looking for " + value
        #dputs p
       @stp = p.entries.detect {|entry| entry.name == value}
#       dputs p

        if @stp
          return "id"
        else
          p = p.parent
        end
      end
''
      create_error(:error_undeclared_identifier, true)
      return "id"
    end

    #This method reads the next character from the source file and handles exceptions
    def next_char
      temp = @file.eof? ? '^' : @file.getc
      @line += temp;
      @columnCount+=1
      return temp
    end
    
    def _next_token      
      #handles id & keywords
      case @c
      when /[a-z]|[A-Z]|[_]/
        x = @c
        while (@c = next_char) =~ /[a-zA-Z_0-9]/ #test nashod
          x += @c
          #dputs @c + '**' + x
        end
        return find_keyword(x)

      #handles int_literal & float_literal
      when /[0-9]|[.]/
        float_type = @c=='.' ? true : false
        temp_char = @c
        @c = next_char
        if float_type && !(@c =~ /[0-9]/)
          return '.'
        end

        @cv = temp_char        

        #hexaDecimal
        if (@cv=='0' && (@c=='x' || @c == 'X'))
            @cv = "";
            #dputs "0X detected"
            while (@c = next_char) =~ /[0-9a-fA-F]/
              @cv += @c
              #puts "*****" + @cv
            end
            @cvt = :hex
            return "int_literalh"
        else
          while @c =~ /[0-9.]/
            @cv += @c
            if @c=='.'
              unless float_type
                float_type=true
              else
                create_error(:error_extra_dot, false)
                @cv.chop
              end
            end
            @c = next_char
            #dputs @c + '**' + @cv
          end
          if @cv[@cv.size-1] == '.'
            @cv.chop
            #return "#int_literal" farz kardam 123. ro float_literal barmigardoonim
          end
          if float_type
            @cvt = :float
            #@cv = "ª"+@cv #170
            return "float_literal"
          else
            @cvt = :int
            #@cv = "¾" + @cv #190
            return "int_literal"
          end
        end

      #handles string_literals
      when "\""
        @cv = ""
        while (@c = next_char) != "\""
          @cv += @c
        end
        @c = next_char
  #      @cv = "$"+@cv + "$"
#        dputs "Scanner CV: #{@cv}"
       # @cv = "§"+@cv #167
        @cvt = :string
        return "string_literal"

      when "'"
        @cv = ""
        while (@c = next_char) != "'"
          @cv += @c
        end
        @c = next_char
        if @cv.length > 1
          create_error(:error_char_literal, false)
          @cv = @cv[0]
        end
       # @cv = "§"+@cv
   #     @cv = "$"+@cv + "$"
        @cvt = :string #revised to solve type mismatch error
        return "char_literal"

      #handles comments
      when "\/"        
        @c = next_char
        if @c == '*'
          loop do
            @c = next_char
            if @c == "*"
              @c = next_char
              if @c == "\/"
                break;
              end
            elsif @c == "\n"
              @lineCount+=1
              @columnCount = 0
              @line = ""
            end
          end
        elsif @c == "\/"
          while (@c = next_char) != "\n"
          end
          @lineCount+=1
          @columnCount = 0
          @line = ""
        else
          return "\/"
        end
        @c = next_char
        return "#comment"

      #handles single symbols
     # when /[+-*%{}\(\);\[]/
        when /[+-\/*%{}\(\);\[]/ #Cmon!!! laanat be to ruby!
        tempc = @c
        @c = next_char
        return tempc;

      #handles double symbols
      when /[=!|&;\]<>]/
        tempc = @c
        @c = next_char
        if tempc=='='
          if @c == '='
            @c = next_char
            #return :equ
            return "=="
          else
            #return :asg
            return "="
          end
        elsif tempc == '!'
          if @c == '='
            @c = next_char
            #return :neq
            return "!="
          else            
            #create_error(:error_unknown_symbol, false)
            #return :neq
            return "!"
          end
        elsif tempc == '|'
          if @c == '|'
            @c = next_char
            #return :or
            return "||"
          else
            create_error(:error_unknown_symbol, false)
            #return :or
            return "||"
          end
        elsif tempc == '&'
          if @c == '&'
            @c = next_char
            #return :and
            return "&&"
          else
            create_error(:error_unknown_symbol, false)
            #return :and
            return "&&"
          end
        elsif tempc == '<'
          if @c == '='
            @c = next_char
            #return :leq
            return "<="
          else
            #return :les
            return "<"
          end
        elsif tempc == '>'
          if @c == '='
            @c = next_char
            #return :geq
            dputs "scanner returned >="
            return ">="
          else
            #return :gre
            dputs "scanner returned >"
            return ">"
          end
        elsif tempc == ']'
          if @c == '['
            @c = next_char
            return "]["
          else
            return ']'
          end
        end

      #handles line No. and column No.
      when "\n"
        @lineCount+=1
        @columnCount = 0
        @line = ""
        @c = next_char
        return "#white_space"

      when "\t"
        @columnCount += 8
        @c = next_char
        return "#white_space"

      #handles whiteSpace characters
      when /\s/
        @c = next_char        
        return "#white_space"

      #handles end of source file
      when '^'
        #dputs @current_st
        return "$"

      

      end #end of case
    end #end of _next_token

    public
    def create_error (e, fatal)
      if @errors.size < @MaximumErrorTolerance
        #dputs "error added to queue"
        tempi = @file.pos
        #dputs "create error: miniline: " + @line
        templine = @line
        #dputs "@line: " + @line
        #dputs "@c: "  + @c
        unless @file.eof?
          templine+= @file.gets unless (@c == "\n")
        else          
          templine = templine.chop
          templine += "\n"
        end

        @errors.push(Error.new(templine, @lineCount, e, @columnCount-1))
        #-1 kardam ke mahal ro dorost neshoon bede too != || &&        

        @file.pos = tempi
        @state = :fatal_error if fatal
      else
        @state = :max_errors_reached
      end
      dputs @errors.size
    end
  end #end of class

end #end of module