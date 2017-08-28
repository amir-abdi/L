module AHACompiler
  class ErrorHandler
    attr_accessor :errors
    def initialize
      
      @errors = []
      @warnings = []
    end

    def sayAll
      puts "\n*****************************Errors********************************\n"
      @errors.each {|error| error.say}
      print "Errors:#{@errors.size}  Warnings:#{@warnings.size}  "
      if (@errors.size == 0)
        print "Compile Successfull.\n"
      else
        print "Compile Failed.\n"
      end

      puts "\n"
    end
  end
end