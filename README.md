The L programming language is a fully functional C-like language. The implementation consists of an
- LR parser, 
- code generator, 
- optimizer, and 
- virtual machine capable of executing the generated semi-assembly codes of the L language. 

The project is implemented in **Ruby language** (Ruby 1.9) using the Netbeans IDE, in 2011.

# L Grammar #
    PROGRAM 	→  	(MODULE;)<sup>+</sup>
    MODULE   →  	module   id  [childof    id] { (MEMBER)* }
    MEMBER 	→   	[virtual]   id ( [id : TYPE [,id : TYPE]*]) : TYPE { ST }
                  | id[[constint]]  : TYPE ;
    TYPE 	→  	 id | int | bool | string | void
    ST 		→  	{(ST)*}
              |  id[[constint]]   : TYPE ;   
              | EXPR ;
              | if    EXPR    then   ST   [else ST]   endif
              | while   EXPR    loop    ST   endloop
              | break;  |  continue;  | read   id; |  write  EXPR ;
              | id   :=  EXPR ;  | return EXPR ;
    EXPR 	→	create   id
            | (EXPR )
            | EXPR  +  EXPR    |  EXPR  - EXPR  |  EXPR  / EXPR   |  EXPR *EXPR  | -EXPR 
            | EXPR  > EXPR |  EXPR  < EXPR  |  EXPR  >= EXPR  |  EXPR  <= EXPR
            | EXPR  != EXPR |  EXPR  =  EXPR  | EXPR  and EXPR | EXPR  or EXPR | not EXPR 
            | constint | constbool | conststr
            | id[([EXPR  [, EXPR ]*])]    |   EXPR .id[([EXPR  [, EXPR ]*])] 
            | id [EXPR]   |   EXPR.id [EXPR]

# Sample L code #
	module student childof mankind
    {	
	      %%member variables…
	      student_number : int;
	      is_talented[10]: bool;
	      virtual get_identity() : int{
	              return student_number;
	      }
	      %% member methods…
	      set_is_talented(Is_Talented: bool):void{
	             is_talented := Is_Talented[3]+123;
	      }
	      set_student_number(SN: int): void{
	               student_number := SN/12+3;
	      }
    };


Disclaimer: this project has nothing to do with the L programming languages introduced by neither Larry McVoy, HP labs, and Rodney Brooks.
