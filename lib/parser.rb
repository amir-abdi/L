module AHACompiler
  ParserAction = {0 => :error, 1 => :shift, 2=> :goto, 3=> :push_goto, 4 => :return, 5=> :acc}
  class Parser
    def initialize(scanner, errorHandler, cg)
      @scanner = scanner
      @errors = errorHandler.errors
      @ps = []
      @code_generator = cg

      fill_pt("pt.npt")
    end
    

    def start
      while (x=@scanner.next_token) != "#end_of_file"
        puts "*Token* " + x.to_s #"***" + x.class.to_s
      end
    end


    
    def parse
      cur_node = 0
      token = @scanner.next_token
      if (token==:Terminate)
        @scanner.create_error(:scanner_terminated, true)
        return
      end
     
      tokenID = @symbols.index(token)
      
      loop do
        
        #puts cur_node
        #puts tokenID.class
        
        @scanner.create_error(:parser_error, true)unless cur_node && tokenID
          
        break if @scanner.state == :fatal_error
        pt_block = @pt[cur_node][tokenID]
        #dputs "parserAction: " + ParserAction[pt_block.action.to_i].to_s + " token: " + token.to_s

        case ParserAction[pt_block.action.to_i]
        when :error
          @scanner.create_error(:parser_error, true)
#          dputs "token= " + token
#          dputs cur_node
#          dputs tokenID
          break
        when :shift
          @code_generator.generate(pt_block.sem)
          token = @scanner.next_token
          if (token==:Terminate)
            dputs "Parser stoped working due to scanner terminate token..."
            return
          end
          tokenID = @symbols.index(token)          
          cur_node = pt_block.node.to_i          
        when :goto
          cur_node = pt_block.node.to_i          
        when :push_goto
          @ps.push(cur_node)
          cur_node = pt_block.node.to_i
        when :return
          cur_node = @ps.pop
          pt_block = @pt[cur_node][pt_block.node.to_i]
          @code_generator.generate(pt_block.sem)
          cur_node = pt_block.node.to_i
        when :acc
          return
        else
          dputs "error in parse method"
        end        
      end
    end

    private
    def code_generator(sem)
      
    end

    def fill_pt(pGen_PT_File)
      f = File.open(pGen_PT_File)
      rown = f.gets(' ').to_i
      coln = f.gets("\n").to_i

     # dputs rown
     # dputs coln
      @symbols = f.gets.split(/\s/)
     # dputs tokens.length
     # dputs tokens[65]
      @pt = []#Array.new(coln * rown)
      rown.times do |i|
        x = f.gets("\n").split(/\s/)
        temparr = []
        coln.times do |j|
          temparr.push(PT_Entry.new(x[j*3], x[j*3+1], x[j*3+2]))
        end
        @pt.push(temparr)
      end

    #dputs @pt[52][0].node
    end
      


  end
end