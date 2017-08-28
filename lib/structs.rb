module AHACompiler
  SymbolTableEntry = Struct.new(:name, :idKind, :dscp)
  SymbolTable = Struct.new(:parent, :entries)
  PT_Entry = Struct.new(:action, :node, :sem)

  SimpleDSCP = Struct.new(:add, :type)
  ArrayDSCP = Struct.new(:add, :type, :elemSize, :lub, :dscp)
  LUB = Struct.new(:ub, :D, :lub)
  StructDSCP = Struct.new(:add, :type, :size , :st)
  MethodDSCP = Struct.new(:pcAddr, :retType, :noArgs, :st, :ARStart)#, :ARSize)
  CodeEntry = Struct.new(:op, :adds, :addModes)

  CV = Struct.new(:dscp, :value)
  IndirectAddress = Struct.new(:dscp, :value)

  MemCell = Struct.new(:t, :v, :mode)

  class MemCell
    def clone
      MemCell.new(self.t, self.v)
    end
  end
  class SymbolTable
    def clone
      SymbolTable.new(self.parent , self.entries.clone)
    end
  end

  class SymbolTableEntry
    def clone
      SymbolTableEntry.new(self.name, self.idKind, self.dscp.clone)
    end
  end
end