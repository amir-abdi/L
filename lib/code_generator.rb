module AHACompiler
  class CodeGenerator
    def initialize(scanner, eh)
      @errors = eh.errors
      #@symbol_table = st
      #@st_stack = st_stack

      @scanner = scanner
      @ss = []
      @adc = 4 #0-3 for getTemp.
      @adc += 2 #4-5 for return value
      @sadc = []

      @structCounter = 0
      @structSize = []
      @struct_declaration = false
      @struct_

      @pc = 0;
      @code = []
      @structSTStack = nil
      @tempFlag = [false,false,false,false,false,false]
      @tempFlagIndex = 0;

      @tempFlagIndexr = 4;

      @st_stack = []
      #@gotoStruct = false;
      @currentMethodARStart = 0;
    end

    def makeOutputFile (fileAddress)
        File.delete(fileAddress) if (File.exist?(fileAddress))
        @file = File.new(fileAddress, "w");

      @file.write(@adc)
      @file.write(" DB\n")


      @file.write("sp # #{@mainAdd}\n")

      @code.each do |ce|
        @file.write(ce.op)
        ce.adds.size.times do |i|
          @file.write(" " + ce.addModes[i] + " ")
          @file.write(ce.adds[i])
        end
        @file.write("\n")
      end
      @file.close
    end

    def generate(action)
#      dputs "CGaction: " + action

      #if @gotoStruct && action != "@gotoStruct" && action!=@push
      if @structSTStack && action != "@gotoStruct" &&  action !="@push"
        @scanner.current_st = @structSTStack#.first
        @structSTStack = nil#.clear
        #@gotoStruct = false
      end

      case action
      when "@push"
        @ss.push(@scanner.stp)
        #puts "pushed:"
        #puts @scanner.stp
      when "@ptNDec"
        #dputs "cg: declaration mode changed to false"
        @ss.pop
        @scanner.declaration_mode=false
      when "@pushDec"
        #dputs "cg: declaration mode changed to true"
        @ss.push(@scanner.stp)
        @scanner.declaration_mode = true
      when "@NDec"
        @scanner.declaration_mode = false

      when "@dec"
        #dputs "cg: declaration mode changed to true"
        @scanner.declaration_mode = true
      when "@stDSCPkt" #simple type DSC , keep type in ss
        stDSCPkt

      when "@stDSCPptNDec" #simple type DSC , pop type in ss
        stDSCPkt
        @ss.pop
        @scanner.declaration_mode=false

      when "@stDSCPpt"
        stDSCPkt
        @ss.pop



        #***************************************************************Array***********************************************
      when "@initArray"
        dputs "initArray"
        id = @ss.pop
        type = @ss.last

        id.dscp = makeAdscp (type.dscp.type)
        unless type.dscp.type.class == Fixnum
          id.idKind = :aid
        else
          ##::::::::::::::::::::::
          id.idKind = :ast
          dputs type
#          id.dscp.dscp = type.dscp
          
        end

        @ss.push(id.dscp)
        @ss.push(id.dscp.lub)
        @ss.push(1)

      when "@allocateLUB"
        lub, i = @ss.pop(2)
        lub.lub = LUB.new
        @ss.push(lub)
        @ss.push(lub.lub)
        @ss.push(i+1)

      when "@setDimention"
        x, i = @ss.pop(2)
        x.ub = trueCV.value
        #x.D = trueCV
        x.D = x.ub #ino taaze avaz kardam. omidvaram bug nadashte bashe
        @ss.push(x)
        @ss.push(i)

      when "@endArray"
        i = @ss.pop
        d = 1
        #p i
        i.times do
          x = @ss.pop
          x.D = d
          d *= x.ub
        end

        #inja ma amir hossein abdi, nesbat be implement kardane array of struct bikhial mishavim
        #code haye mark shode ba #:::::::::::::::::::::: neshaneye in amaliat ast
        #dahanam service!
        dscp = @ss.pop
        allocateMem(d * dscp.elemSize)
        #dputs "elemSize: " + dscp.elemSize.to_s
        #dputs @adc

        #***************************************************************CalcArray***********************************************888
      when "@initCalcArray"
        initCalcArray

      when "@subCalcArray"
        lub,  x = @ss.pop(2)

        @scanner.create_error(:error_int_index_required, false) if x.dscp.type != :int
        @scanner.create_error(:error_array_dimention_mismatch, true) if lub == nil
        @scanner.create_error(:error_array_boundary, false) if x.class == CV && (x.value > lub.ub || x.value < 0)
        if (lub)
          #sum += x.value * lub.D
          @ss.push(lub.D)
          @ss.push(x)

          create2OperandCE("*")
          create2OperandCE("+")
          #@ss.push(0)
          #dputs "nill pushing"
          #dputs @ss.size
          @ss.push(lub.lub)
          #dputs @ss.size
          #dputs @ss.pop
        end

      when "@endCalcArray"
        dputs @ss.size
        dscp, sum, lub = @ss.pop(3)
        @scanner.create_error(:error_array_dimention_mismatch, false) if lub != nil
        #dscp = @ss.pop
        @ss.push(sum)
        #dputs dscp
        @ss.push(dscp.elemSize)
        create2OperandCE("*")
        @ss.push(dscp.add)
        create2OperandCE("+")
        #final = sum + dscp.add
        final = @ss.pop

        @ss.push(IndirectAddress.new(SimpleDSCP.new(nil, dscp.type),final.dscp.add))
        if dscp.type.class != Fixnum
          @ss.pop
        end
        dputs "endcalcarray"
        dputs @ss
        dputs "/endcalcarray"

      when "@NDecInitCalcArray"
        initCalcArray
        @scanner.declaration_mode = false

        #***************************************************************Struct***********************************************888
      when "@decStrDec"
        @scanner.declaration_mode = true
        @struct_declaration = true
        @scanner.current_st = @scanner.main_st #???????????????

      when "@structDSCP"
        #dputs @scanner.main_st
        #@scanner.struct_dec_mode = true
        #@struct_declaration = true
        stp = @ss.pop
        stp.idKind = :strt
        stp.dscp = StructDSCP.new(nil, @structCounter,nil, nil)
        @structCounter+=1
        stp.dscp.st = SymbolTable.new(nil,[]) #struct doesn't have parent ST
        #stp.dscp.st.parent = @scanner.current_st
        @ss.push(stp)
        @sadc.push(0)
        @scanner.current_st = stp.dscp.st
        @scanner.declaration_mode = false

      when "@endStruct"
        #@st_stack.pop
        #@scanner.current_st = @scanner.current_st.parent
        stp = @ss.pop

        stp.dscp.size = @sadc.pop
        @structSize.push(stp.dscp.size)
        @scanner.current_st = @scanner.global_st #pasokhe ???????????????????
        @struct_declaration = false
        #dputs "endStruct:"
        #dputs stp.dscp.size
        #dputs stp

      when "@initGotoStruct"
        #@gotoStruct = true
       # dputs "**************************"
        id = @ss.pop
        @structSTStack = @scanner.current_st #.push(@scanner.current_st)
        @scanner.current_st = id.dscp.st
       # dputs "**************************"
      when "@gotoStruct"
        dputs "gotoStruct"
        
        id = @ss.pop
        ##::::::::::::::::::::::
        if (id.class == IndirectAddress)
          t = @ss.pop
          @ss.push(id)
          @scanner.current_st = t.dscp.dscp.st
        else
          @scanner.current_st = id.dscp.st
        end
        dputs @ss
        dputs "/gotoStruct"

      when "@NDecInitGotoStruct"
        @scanner.declaration_mode = false;
       # dputs "**************************"
        id = @ss.pop
        #dputs id
        @structSTStack = @scanner.current_st #.push(@scanner.current_st)
        @scanner.current_st = id.dscp.st
        #dputs "**************************"


        #***************************************************************Method***********************************************888
      when "@methodDSCP"
        @currentMethodARStart = @adc
        t, id = @ss.pop(2)
        @mainAdd = @pc if (id.name == "main")

        id.idKind = :method
        id.dscp = MethodDSCP.new(@pc, t.dscp.type, nil, SymbolTable.new(@scanner.global_st,[]), allocateMem(0))
 
        @st_stack.push(@scanner.current_st)
        @scanner.current_st = id.dscp.st
        @ss.push(id)

      when "@endMethod"
        endMethod

      when "@stDSCPptEndMethod"
        stDSCPkt
        @ss.pop
        endMethod

      when "@returnFromMethod"        

        @scanner.current_st = @st_stack.pop #not sure!!!
        @ss.push(0)

        create1OperandCEWithoutResult("op")
      when "@return"
        @ss.push(0)
        create1OperandCEWithoutResult("op")

      when "@returnWithValue"
        @ss.push(1)
        create1OperandCEWithoutResult("op")

      when "@setReturnValue"
        value = @ss.pop
        @ss.push(value)
       create1OperandCEWithoutResult("push", true)

      when "@push0"        
        pushAR

        @ss.push(0)

      when "@NDec_push0"
        pushAR
        
        @ss.push(0)
        @scanner.declaration_mode = false;

      when "@methodCall"
        #check num args
        i = @ss.pop #i
        id = @ss.pop
        @scanner.create_error(:error_arg_no_mismatch, false) if i != id.dscp.noArgs             

        #push pc
        create0OperandCE("pp1")

        #set pc to new method
        pc = id.dscp.pcAddr
        @ss.push(pc)

        create1OperandCEWithoutResult("sp")

        #pop AR
        @ss.push(@currentMethodARStart)#id.dscp.ARStart)
        @ss.push(@adc-@currentMethodARStart)#id.dscp.ARStart)
        if (id.dscp.retType != :void)
          @ss.push(1)
          create3OperandCEWithoutResult("om")
        else
          @ss.push(0)
          create3OperandCEWithoutResult("om")
        end

        if (id.dscp.retType != :void)

          c = @scanner.current_st.entries.last#.push(c)
          @ss.push(c.dscp.add)
          create1OperandCEWithoutResult("pop",true)

          @ss.push(c)
        end

      when "@sendArg"
        #send each argument
        id, i, a = @ss.pop(3)
        @ss.push(id.dscp.st.entries[i])
        @ss.push(a)
        i+=1
         if i > id.dscp.noArgs
           @scanner.create_error(:error_arg_no_mismatch, true)
           return
         end
        create2OperandCEWithoutResult("=")
        
        @ss.push(id)
        @ss.push(i)

        #***************************************************************Block***********************************************888
      when "@subST"
        st = SymbolTable.new(@scanner.current_st, [])
        @scanner.current_st = st

      when "@superST"
        @scanner.current_st = @scanner.current_st.parent

      #***************************************************************Expression Evaluation***********************************************888
      when "@assg_wr"
        create2OperandCEWithoutResult("=")
      when "@assg"
        #dputs "**@assg 1"
        create2OperandCEWithoutResult("=")
        #dputs "**@assg 2"
      when "@cond_or"
        create2OperandCE("||")
      when "@cond_and"
        create2OperandCE("&&")
      when "@equal?"
        create2OperandCE("==")
      when "nequal?"
        create2OperandCE("!=")
      when "@l"
        create2OperandCE("<")
      when "@g"
        create2OperandCE(">")
      when "@le"
        create2OperandCE("<=")
      when "@ge"
        create2OperandCE(">=")
      when "@add"
        create2OperandCE("+")
      when "@sub"
        create2OperandCE("-")
      when "@mod"
        create2OperandCE("%")
      when "@div"
        create2OperandCE("/")
      when "@mul"
        create2OperandCE("*")
      when "@not"
        create1OperandCE("!")
      when "@uminus"
        create1OperandCE("$-")
      #***************************************************************if else***********************************************888
      when "@jz"
        create1OperandCEWithoutResult("jz")
        @ss.push(@pc-1)

      when "@jpxcjz"
        @ss.push(@pc+1)
        create1OperandCEWithoutResult("jp")
        #dputs "jpxcjz"
        #dputs @ss
#        dputs "jpxcjz"
#        dputs @ss.last
        insertAddress(@code[@ss.pop], @pc, true)
      when "@pushjpx"
        @ss.push(@pc-1)
      when "@cjpx"
        ce = @code[@ss.pop]
        ce.adds[ce.adds.size-1] = @pc
      #***************************************************************for loop***********************************************888
      when "@pop_pushpc"
        #***************************************
        #@ss.pop #Assg result
        #***************************************
        @ss.push("$$$")
        @ss.push(@pc)
        #dputs 1
      when "@jzjp"
        create1OperandCEWithoutResult("jz")
        @ss.push(@pc-1)

        create0OperandCE("jp")
        @ss.push(@pc-1)
        #dputs 2
      when "@pushpc"
        @ss.push(@pc)
        #dputs 3
      when "@pop_jpcheck_cjp"
        #***************************************
        #@ss.pop #Assg result
        #***************************************
        jz,jp,semi = @ss.pop(3)
        create1OperandCEWithoutResult("jp")
        insertAddress(@code[jp],@pc, true)
        @ss.push(jz)
        #@ss.push("CCC")
        @ss.push(semi)
        #dputs 4
      when "@jpSecondSemi_cjz"
        #dputs 51
        create1OperandCEWithoutResult("jp")
        insertAddress(@code[@ss.pop],@pc, true) while (@ss.last != "$$$")
        @ss.pop
        
      when "@break"
        create0OperandCE("jp")
        t=[]        
        t.push(@ss.pop) while (@ss.last != "$$$")
        @ss.push(@pc-1)
        @ss.push(t.pop) while (t.empty? == false)
        #dputs 6
      when "@continue"
        semi2 = @ss.pop
        @ss.push(semi2)
        @ss.push(semi2)
        create1OperandCEWithoutResult("jp")
      #***************************************************************write/read***********************************************888
      when "@ri"
        create1OperandCEWithoutResult("ri")
      when "@rf"
        create1OperandCEWithoutResult("rf")
      when "@wi"
        create1OperandCEWithoutResult("wi")
      when "@wf"
        create1OperandCEWithoutResult("wf")
      when "@wt"
        create1OperandCEWithoutResult("wt")
      #***************************************************************others***********************************************888
      when "@pushCV"        
        @ss.push(trueCV)
        #dputs "@pushCV: #{@ss.last}"

      when "@pop"
        @ss.pop

      when "NoSem"
      else
        puts "Code Generator Error: There's an error in one of the Sems (mistype I guess!): " + action
      end
    end

    private
    def initCalcArray
        id = @ss.pop
        ##::::::::::::::::::::::
        if id.idKind != :aid && id.idKind != :ast
          @scanner.create_error(:error_id_not_array, true)
        else
          ##::::::::::::::::::::::
          @ss.push(id)

          @ss.push(id.dscp)
          @ss.push(0)
          @ss.push(id.dscp.lub)
        end
    end

    def getTemp
      while @tempFlag[@tempFlagIndex]
        @tempFlagIndex += 1
        @tempFlagIndex = 0 if @tempFlagIndex >=4
      end
      @tempFlag[@tempFlagIndex] = true
      #dputs "***********getTemp: " + @tempFlagIndex.to_s
      #dputs @tempFlag
      return @scanner.main_st.entries[@tempFlagIndex]
    end

    def getTempReturnValue
      while @tempFlag[@tempFlagIndexr]
        @tempFlagIndexr += 1
        @tempFlagIndexr = 4 if @tempFlagIndexr >=6
      end
      @tempFlag[@tempFlagIndexr] = true

      return @scanner.main_st.entries[@tempFlagIndexr]
    end

    def checkType(a,b)
#      dputs "checktype"
#      dputs a
#      dputs b
      #1
      if (a.class == Fixnum)
        if b.class == Fixnum
          return :int
        elsif b.dscp.type == :int
          return :int
        else
          @scanner.create_error(:error_type_mismatch, false)
          return :int
        end
      end
      #2
      if (b.class == Fixnum)
        if a.dscp.type == :int
          return :int
        else
          @scanner.create_error(:error_type_mismatch, false)
          return :int
        end
      end
      #3
      return :float if (a.dscp.type == :int && b.dscp.type == :float) || (a.dscp.type == :float && b.dscp.type == :int)

      #4
      @scanner.create_error(:error_type_mismatch, false) if (a.dscp.type !=  b.dscp.type)
      return a.dscp.type

    end
    def pushAR
        #push this AR
        

        id = @ss.pop

        #**********
        c = SymbolTableEntry.new("$temp", :sid, SimpleDSCP.new(allocateMem, id.dscp.retType))
        @scanner.current_st.entries.push(c)
        #**********

        @ss.push(@currentMethodARStart) #id.dscp.ARStart)
        @ss.push(@adc-@currentMethodARStart)#id.dscp.ARStart)
        create2OperandCEWithoutResult("pm")
        @ss.push(id)
    end

    def create0OperandCE(x)
      ce = CodeEntry.new(x,[],[])
      @code.push(ce)
      @pc+=1
    end
    def create1OperandCEWithoutResult(x, resoreTemp = true)
      a = @ss.pop
      ce = CodeEntry.new(x,[],[])
      insertAddress(ce, a, resoreTemp)
      @code.push(ce)

      @pc+=1
    end

    def create2OperandCEWithoutResult(x, resoreTemp = true)
      #dputs "create2Operands 1"
      a,b = @ss.pop(2)

      ce = CodeEntry.new(x,[],[])
      insertAddress(ce, a, resoreTemp)
      insertAddress(ce, b, resoreTemp)

        checkType(a,b)

      @code.push(ce)
      @pc+=1
    end

    def create3OperandCEWithoutResult(x, resoreTemp=true)
      a,b,c = @ss.pop(3)

      ce = CodeEntry.new(x,[],[])
      insertAddress(ce, a, resoreTemp)
      insertAddress(ce, b, resoreTemp)
      insertAddress(ce, c, resoreTemp)

        #checkType(a,b)

      @code.push(ce)
      @pc+=1
    end

    def create2OperandCE(x, resoreTemp = true)
#      dputs "create2Operands 1"
      a,b = @ss.pop(2)

      ce = CodeEntry.new(x,[],[])
      insertAddress(ce, a, resoreTemp)
      insertAddress(ce, b, resoreTemp)

      c = prepareResult(ce, checkType(a,b))
#  dputs "create2Operands 2"
    @ss.push(c)

      unless (x == "%")
        checkType(a,b)
      else
        if a.dscp.type!= :int || b.dscp.type != :int
          @scanner.create_error(:error_type_mismatch, false)
        end
      end

      @code.push(ce)
      @pc+=1
      
    end
    def create1OperandCE(x, resoreTemp = true)
      a = @ss.pop
      ce = CodeEntry.new(x,[],[])
      insertAddress(ce, a, resoreTemp)
      c = prepareResult(ce,a.dscp.type)
      @ss.push(c)
      @code.push(ce)
      @pc+=1
    end
    def prepareResult(ce, type)
#      dputs "prepareResult 1"
#      dputs @tempFlag
#      if (@tempFlag == [false, true, false, false])
#        dputs @scanner.current_token
#      end
#      dputs "***************"
      c = getTemp
      #dputs "prepareResult 2"
      c.dscp.type = type

      insertAddress(ce,c,false)

      return c
    end
    def insertAddress(ce, add, restoreTemp=true)
     # dputs "****Class" + add.class.to_s

      if add.class == CV
        case add.dscp.type
        when :bool
          ce.addModes.push('b')
        when :float
          ce.addModes.push('f')
        when :string
          ce.addModes.push('s')
        when :int
          ce.addModes.push('#')
        when :char
          ce.addModes.push('c')
        when :hex
          ce.addModes.push('h')
        end
        
        ce.adds.push(add.value)
      elsif add.class == SymbolTableEntry
        ce.addModes.push('*')
        ce.adds.push(add.dscp.add)
        @tempFlag[add.dscp.add] = false if restoreTemp && add.dscp.add <=5
        if (add.dscp.add >=4)
          #dputs "************************************************************************************"
        end
      elsif add.class == IndirectAddress
        ce.addModes.push('@')
        ce.adds.push(add.value)
        @tempFlag[add.value] = false if restoreTemp && add.value <=5
        if (add.value >=4)
          #dputs "************************************************************************************"
        end
      elsif add.class == Fixnum
        ce.addModes.push('#')
        ce.adds.push(add)
      end

    end
    def endMethod
      id = @ss.pop
      id.dscp.noArgs = id.dscp.st.entries.size
      @scanner.declaration_mode = false
#      @ss.push(id)
    end
    def trueCV
      value  = case @scanner.cvt
      when :int
        @scanner.cv.to_i
      when :float
        @scanner.cv.to_f
      when :string
#        dputs "trueCV    : #{@scanner.cv}"
        @scanner.cv
      when :char
        @scanner.cv
      when :bool
        @scanner.cv == "true" ? 1 : 0
      when :hex
        @scanner.cvt = :int
        @scanner.cv.to_s.hex
      end

      return CV.new(SimpleDSCP.new(nil, @scanner.cvt), value)
    end
    def makeAdscp (type)
      t = ArrayDSCP.new(allocateMem(0), type, sizeof(type), LUB.new)
        #dputs "*************size of array element:"
        #dputs sizeof(type)
        return t
    end
    def sizeof(type)
      unless type.class == Fixnum
        return 1
      else
        return @structSize[type]
      end
    end
    def stDSCPkt
       id = @ss.pop
       type = @ss.last
       case type.idKind
       when :st
         id.idKind = :sid
         id.dscp = makeSdscp(type.dscp.type)
       when :strt
         id.idKind = :strid
         id.dscp = makeStrdscp(type)
       end
    end
    def makeStrdscp(type)
      dscp = StructDSCP.new(allocateMem(type.dscp.size), type.dscp.type, type.dscp.size, SymbolTable.new(nil,[])) #struct ST doesn't have parent
      type.dscp.st.entries.each do |entry|
        dscp.st.entries.push(entry.clone)
      end

      dscp.st.entries.each  {|entry| entry.dscp.add += dscp.add}
      return dscp

    end
    def makeSdscp (type)
      SimpleDSCP.new(allocateMem, type)
    end
    def allocateMem(size = 1)
      #dputs "allocateMem>size: " + size.to_s
      unless @struct_declaration
        x = @adc
        @adc+=size
      return x
      else
        y = @sadc.pop
        @sadc.push(y+size)
        return y
      end
    end
  end
end