load 'error_handler.rb'
load 'error.rb'
load 'scanner.rb'
load 'parser.rb'
load 'structs.rb'
load 'code_generator.rb'
load 'virtual_machine.rb'
module Kernel
  def dputs(str)
    #puts str
  end
end

module AHACompiler

  
  def init_compiler
    st_stack = []
    main_symbol_table = SymbolTable.new(nil,[])
    global_symbol_table = SymbolTable.new(nil,[])
    st_stack.push(main_symbol_table)
    st_stack.push(global_symbol_table)

    errorHandler = ErrorHandler.new
    sourceFile = ARGV[0].to_s#"fibo.l"
   # puts sourceFile
    outputFile = sourceFile[0..sourceFile.length-4]+"output"
    scanner = Scanner.new(sourceFile, errorHandler, global_symbol_table, main_symbol_table)
    code_generator = CodeGenerator.new(scanner, errorHandler)
    parser = Parser.new(scanner, errorHandler, code_generator)
    parser.parse

    errorHandler.sayAll
    if (errorHandler.errors.size==0)
      code_generator.makeOutputFile(outputFile)
      virtualMachine = VirtualMachine.new
      dputs "Virtual Machine Started working"
      virtualMachine.run(outputFile)
    end
    
  end
end