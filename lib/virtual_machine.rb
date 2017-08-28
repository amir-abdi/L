module AHACompiler
  class VirtualMachine
    def initialize
      @rts = []
      @mem = []
      @pc = 0
      @rts = []
      @rts.push(-1) #give the handler back to OS
    end

    def run(fileAddress)
       if (File.exist?(fileAddress))
        @file = File.new(fileAddress, "r");
      else
        raise IOError , "AHAScanner says: \"File not found! Check the source file address\""
      end
      

      db = @file.readline.split(' ')[0].to_i
      @mem = Array.new(db)
      @pc = @file.readline.split(' ')[2].to_i

      db.times {|i| @mem[i] = MemCell.new(:i, 0)}
      lines = []
      loop do
        break if (@file.eof?)
        lines = @file.readlines
      end

      @code = []
      i = 0;
      while i<lines.size
        dputs lines[i]
        @code.push(parse(lines[i]))
#        p @code[i]
        i+=1
      end


      #dputs lines.size
      while @pc != -1
#        dputs "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$"
        dputs "pc" + (@pc).to_s + ' '
     #   p @code[@pc]

         #tokens = lines[@pc].split(' ')
         tokens = @code[@pc]
         @pc +=1
         act(tokens)
      end      
    end
    
    def parse(line)
      n = 0
      op = line.split(' ')[0]
    #  dputs "op: #{op}"
      n+=1
      n+=op.size
      mode1 = nil
      op1 = nil
      op2 = nil
      mode2 = nil
      op3 = nil
      mode3 = nil
      
      inst =[]
      case op
      when /[+*\/%<>-]|<=|>=|==|!=|&&|\|\||om/
      #  dputs "no3"
        mode1 = line.split(' ')[1]
        n+=mode1.size+1
        op1 =  line.split(' ')[2]
        n+=op1.size+1
        mode2 = line.split(' ')[3]
        n+=mode2.size+1
        op2 = line.split(' ')[4]
        n+=op2.size+1
        mode3 = line.split(' ')[5]
        n+=mode3.size+1
        op3 = line[-(line.size-n)..-1].chomp
        inst.push(op)
        inst.push(mode1)
        inst.push(op1)
        inst.push(mode2)
        inst.push(op2)
        inst.push(mode3)
        inst.push(op3)
        #op3 = line.index(line.split(' '))
      when /=|jz|pm|!/
     #   dputs "no2"
        mode1 = line.split(' ')[1]
        n+=mode1.size+1
        op1 =  line.split(' ')[2]
        n+=op1.size+1
        mode2 = line.split(' ')[3]
        n+=mode2.size+1
        op2 = line[-(line.size-n)..-1].chomp
        inst.push(op)
        inst.push(mode1)
        inst.push(op1)
        inst.push(mode2)
        inst.push(op2)
        
      when /$-|jp|rf|ri|wf|wi|wt|op|sp|push|pop/
      #  dputs "no1"
        mode1 = line.split(' ')[1]
        n+=mode1.size+1
        op1 = line[-(line.size-n)..-1].chomp
        inst.push(op)
        inst.push(mode1)
        inst.push(op1)
      when /pp1/
       # dputs "no0"
        inst.push(op)
      end
    end

   
    def act(inst)
#      i = inst[1..inst.size-1]
#      puts inst[0]
      i = inst[1...inst.size]
      case inst[0]
      when "+"
        add(i)
      when "="
        assign(i)
      when "-"
        sub(i)
      when "*"
        mult(i)
      when "/"
        div(i)
      when "%"
        mod(i)
      when "=="
        equal(i)
      when "!="
        nequal(i)
      when "&&"
        aNd(i)
      when "||"
        oR(i)
      when "<"
        less(i)
      when ">"
        great(i)
      when "<="
        lessEqual(i)
      when ">="
        greatEqual(i)
      when "$-"
        uminus(i)
      when "jz"
        jz(i)
      when "jp"
        jp(i)
      when "ri"
        readint(i)
      when "wi"
        writeint(i)
      when "rf"
        readfloat(i)
      when "wf"
        writefloat(i)
      when "wt"
        writetext(i)
      when "pp"
        pushPC(i)
      when "pp1"
        pushPC1(i)
      when "op"
        popPC(i)
      when "pm"
        pushMem(i)
      when "om"
        popMem(i)
      when "sp"
        setPC(i)
      when "push"
        pushh(i)
      when "pop"
        popp(i)
      when "!"
        nOt(i)

      end
    end

 def resolveAdd(mode, value)
      return case mode
      when "#"
        MemCell.new(:i,value.to_i)
      when "b"
        MemCell.new(:i,value.to_i)
      when "f"
        MemCell.new(:f,value.to_f)
      when "s"
#        if (rest)
#          value+=rest.join(' ')
#        end
        MemCell.new(:s,value)
      when "c"
        MemCell.new(:s,value)
      when "h"
        MemCell.new(:i,value.hex)

      when "*"
        #dputs value
        @mem[value.to_i].mode = value.to_i
        @mem[value.to_i]

      when "@"
        @mem[@mem[value.to_i].v]
      end
    end
    
    def getOperands(inst, count)
      return resolveAdd(inst[0],inst[1]) if count==1
      
      adds = []
      0.step(count*2-1, 2) do |i|       
       t = resolveAdd(inst[i],inst[i+1])
       unless t
#         dputs "null reuturned in getopreands"
       end
        adds.push(t)
      end
      return adds
    end

    def mult(inst)
      a,b,c = getOperands(inst, 3)      
      c.v = a.v*b.v      
      c.t = getType(a.t, b.t)
#      dputs "multmm: #{a.mode} * #{b.mode} = #{c.mode}"
#      dputs "mult: #{a.v} * #{b.v} = #{c.v}"
    end

    def getType(x,y)
      if x==:i && y==:i
        return :i
      elsif x==:f || y==:f
        return :f
      end
    end

    def assign(inst)
#      dputs "assing"
#      dputs @mem[1]
      a,b= getOperands(inst, 2)
      unless a
        dputs "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
#        dputs a
#        dputs b
#        dputs @pc
        dputs @mem[1]
        dputs @mem[9]
      end
      unless b
        dputs "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
      end
      a.v = b.v
      a.t = b.t
#      dputs "assgmm: #{a.mode} = #{b.mode}"
#      dputs "assign: #{a.v} = #{b.v}"
    end

    def sub(inst)
      a,b,c = getOperands(inst, 3)
      c.v = a.v-b.v
      c.t = getType(a.t, b.t)
    end

    def add(inst)
      x = 0
      a,b,c = getOperands(inst, 3)
      if (a.object_id == c.object_id)
        x = (a.v + b.v)
        c = MemCell.new(a.t, x, a.mode)
        @mem[a.mode] = c
      else
        c.v =  a.v + b.v
      end
      #c.v += a.v
      c.t = getType(a.t, b.t)
    #  c.v = x
#      dputs "addmm: #{a.mode} + #{b.mode} = #{c.mode}"
#      dputs "add: #{a.v} + #{b.v} = #{c.v}"
      if (c.v == 11)
#        dputs a.object_id
#        dputs b.object_id
#        dputs c.object_id
#        dputs @mem[1]
      end
#      dputs @mem
    end

    def div(inst)
      a,b,c = getOperands(inst, 3)
      c.v = a.v/b.v
      c.t = getType(a.t, b.t)
    end

    def mod(inst)
      a,b,c = getOperands(inst, 3)
      c.v = a.v%b.v
      c.t = getType(a.t, b.t)
    end

    def equal(inst)
      a,b,c = getOperands(inst, 3)
      c.v = a.v == b.v ? 1 : 0
#      dputs @mem[1].object_id
#      dputs c.object_id
#      dputs "EQUAL @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ " + c.v.to_s
#      dputs "EQUAL @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ " + @mem[1].v.to_s

      c.t = :i
    end

    def nequal(inst)
      a,b,c = getOperands(inst, 3)
      c.v = a.v!=b.v ? 1 : 0
      c.t = :i
    end

    def less(inst)
      a,b,c = getOperands(inst, 3)
      #********************
      dputs "less"
      dputs a
      dputs b
      dputs c
      #********************
      c.v = a.v < b.v ? 1 : 0

#      dputs "***<"
#      dputs c.v
      c.t = :i
    end

    def great(inst)
      a,b,c = getOperands(inst, 3)
      c.v = a.v > b.v ? 1 : 0
      c.t = :i
    end

    def lessEqual(inst)
      a,b,c = getOperands(inst, 3)
      c.v = a.v <= b.v ? 1 : 0
      c.t = :i
    end

    def greatEqual(inst)
      a,b,c = getOperands(inst, 3)
      c.v = a.v >= b.v ? 1 : 0
      c.t = :i
    end

    def aNd(inst)
      a,b,c = getOperands(inst, 3)
      tempa = (a.v==0) ? false : true
      tempb = (b.v == 0) ? false : true
      tempc = tempa && tempb
      c.v = tempc == false ? 0 : 1
      #c.v = a.v && b.v
      c.t = getType(a.t, b.t)
    end

    def oR(inst)
      a,b,c = getOperands(inst, 3)
      tempa = (a.v==0) ? false : true
      tempb = (b.v == 0) ? false : true
      tempc = tempa || tempb
      c.v = tempc == false ? 0 : 1
      c.t = getType(a.t, b.t)

    end

    def nOt(inst)
      a,c = getOperands(inst, 2)
      dputs "nOt"
      dputs a
      tempa = (a.v==0) ? false : true
      tempc = !tempa
      c.v = tempc == false ? 0 : 1
      c.t = a.t
    end

    def uminus(inst)
      a = getOperands(inst, 1)
      a.v = -a.v
    end

    def jz(inst)
      a,b = getOperands(inst, 2)
#      dputs "jz"
#      dputs a
#      dputs @mem
      if (a.v == 0)
        
        @pc = b.v
      end
#      dputs "jz pc"
#      dputs @pc
    end

    def jp(inst)
      a = getOperands(inst, 1)
      @pc = a.v
    end

    def writeint(inst)
      a = getOperands(inst, 1)
      print a.v
    end

    def readint(inst)
      a = getOperands(inst, 1)
      #puts "readline"
      #a.v = gets.to_i #error for spaces!!!
      a.v = STDIN.gets.to_i
    end

    def writefloat(inst)
      a = getOperands(inst, 1)      
      print a.v
    end

    def readfloat(inst)
      a = getOperands(inst, 1)
      #a.v = gets.to_f #error for spaces!!!
      a.v = STDIN.gets.to_f
    end

    def writetext(inst)
      a = getOperands(inst, 1)
#      unless a.v
#        a.v = " "
#      end
      a.v = a.v.gsub('\n', "\n")
      a.v = a.v.gsub('\\\\', "\\")
      print  a.v
    end


    def pushPC(inst)
      @rts.push(@pc)
    end
    def pushPC1(inst)
      @rts.push(@pc+1)
    end

    def popPC(inst)
#      dputs "popPC"
#      dputs @pc
#      dputs @rts.size
#      dputs @rts.last
      a = getOperands(inst, 1)
      if a.v == 0
        @pc = @rts.pop
      else
        ss = []
        a.v.times {ss.push(@rts.pop)}
        @pc = @rts.pop
        a.v.times {@rts.push(ss.pop)}
      end
      
#      dputs @pc
#      dputs "******"
    end
    def setPC(inst)
        
      a = getOperands(inst, 1)

      @pc = a.v
#      dputs "setPC"
#      dputs @pc
    end

    def pushMem(inst)
#      dputs "*******************pushMem*******************"
      start,size = getOperands(inst, 2)

      if size.v != 0
        size.v.times do |i|
#          dputs start.v+i
          @rts.push(@mem[start.v+i].clone)
        end
      end
#      dputs "tempPush"
      6.times do |i|
#        dputs i
        @rts.push(@mem[i].clone)
      end
    end

    def popMem(inst)
#      dputs "******************popMem*****************"
      start,size,pass = getOperands(inst, 3)
      if size.v != 0
        ss = nil
        if pass.v == 1
          ss = @rts.pop
        end

#        dputs "tempPop"
        6.times do |i|
#          dputs 5-i
          @mem[5-i] = @rts.pop.clone
        end
        [0..5].each do |i|
    #      dputs @mem[i]
        end

        size.v.times do |i|
#          dputs start.v + size.v - i -1
          @mem[start.v + size.v - i -1] = @rts.pop.clone
        end

        if pass.v == 1
          @rts.push(ss)
        end

      end
    end

    def pushh(inst)
      a = getOperands(inst, 1)
#      dputs "!push"
#      dputs a
#      dputs inst
      @rts.push(a.clone)
#      dputs @rts.last
    end
    def popp(inst)    
      a = getOperands(inst, 1)
      @mem[a.v] = @rts.pop.clone
#      dputs "!pop" + a.v.to_s
#      dputs @mem[a.v]

      
    end




  end
end