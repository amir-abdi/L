module AHACompiler
    class Error
      def initialize (line, line_number, error, column_number)
        @lineNumber = line_number
        @line = line
        @error = error
        @columnNumber = column_number<=0 ? 1 : column_number
        #dputs "line: " + @line
      end

      def say
        puts ("AHAScanner: \"Error in line #{@lineNumber}: #{error_text(@error)} at position marked with ^\n#{@line}" +
            " "*(@columnNumber-1) +
            "^\n")
      end

      def error_text(e)
        case e
        when :error_unknown_symbol
          "There's an unknown symbol"
        when :error_extra_dot
          "There're 2 dots in the floating point"
        when :error_char_literal
          "There's more than 1 character in the char_literal"
        when :error_double_struct_declare
          "The Struct has been declared before"
        when :parser_error
          "Parser realized a syntactic error"
        when :error_undeclared_identifier
          "The id was not declared"
        when :error_double_id_declare
          "The identifier has been declared before"
        when :scanner_terminated
          "Parser stopped working since scanner sent a terminate token"
        when :error_id_not_array
          "The identifier is not an Array, so you can't use [ ] with it"
        when :error_int_index_required
          "The index in the brackets, gotta be int type"
        when :error_array_dimention_mismatch
          "There's a mismatch in the Array Dimention"
        when :error_type_mismatch
          "Types don't match!"
        when :error_array_boundary
          "Array index out of range"
        when :error_arg_no_mismatch
          "Number of arguments doesn't match"
          
        else
          "There's an unkown error"
        end

      end
    end
end