# 24nov16abu
# (c) Software Lab. Alexander Burger

(code 'redefMsgEC)
   push (OutFile)  # Save output channel
   ld (OutFile) ((OutFiles) II)  # Set to OutFiles[2] (stderr)
   push (PutB)  # Save 'put'
   ld (PutB) putStdoutB  # Set new
   push C  # Save optional class
   ld C HashBlank  # Print comment
   call outStringC
   call printE  # Print sym
   pop E  # Class?
   null E
   if nz  # Yes
      call space
      call printE_E  # Print class
   end
   ld C Redefined  # Print message
   call outStringC
   pop (PutB)  # Restore 'put'
   pop (OutFile)  # and output channel
   ret

(code 'putSrcEC_E)
   cmp (Dbg) Nil  # Debug?
   if ne  # Yes
      sym (E TAIL)  # External symbol?
      if z  # No
         ld A (InFile)  # Current InFile
         null A  # Any?
         if nz  # Yes
            null (A VI)  # Filename?
            if nz  # Yes
               push X
               push E  # <S I> sym
               push C  # <S> key
               ld C Dbg
               call getEC_E  # Get '*Dbg' properties
               ld X E  # into X
               ld E ((InFile) VI)  # Get filename
               call mkStrE_E  # Make string
               ld A ((InFile) V)  # Get 'src'
               shl A 4  # Make short number
               or A CNT
               push E
               call consE_E  # (<src> . "filename")
               ld (E) A
               pop (E CDR)
               ld A (S)  # Get key
               null A  # Any?
               if z  # No
                  cmp X Nil  # '*Dbg' properties?
                  if eq  # No
                     push E
                     call consE_E  # Make list
                     pop (E)
                     ld (E CDR) Nil
                     ld A (S I)  # Put initial '*Dbg' properties
                     ld C Dbg
                     call putACE
                  else
                     ld (X) E  # Set first '*Dbg' property
                  end
               else
                  cmp X Nil  # '*Dbg' properties?
                  if eq  # No
                     call consE_C  # Make list
                     ld (C) E
                     ld (C CDR) Nil
                     call consC_E  # Empty first property
                     ld (E) Nil
                     ld (E CDR) C
                     ld A (S I)  # Put initial '*Dbg' properties
                     ld C Dbg
                     call putACE
                  else
                     ld C (X CDR)  # Search secondary properties
                     do
                        atom C  # Any?
                        if nz  # No
                           call consE_C
                           ld (C) (S)  # Get key
                           ld (C CDR) E  # Cons with value
                           call consC_A  # Insert into list
                           ld (A) C
                           ld (A CDR) (X CDR)
                           ld (X CDR) A
                           break T
                        end
                        cmp ((C)) (S)  # Found key?
                        if eq  # Yes
                           ld ((C) CDR) E  # Store value
                           break T
                        end
                        ld C (C CDR)
                     loop
                  end
               end
               pop C
               pop E
               pop X
            end
         end
      end
   end
   ret

(code 'redefineCE 0)
   ld A (E)  # Current value
   cmp A Nil  # NIL?
   if ne  # NO
      cmp A E  # Auto-symbol?
      if ne  # No
         push C  # Save definition
         push E  # and sym
         ld E C  # Value
         call equalAE_F  # Changing?
         if ne  # Yes
            ld E (S)  # Get sym
            ld C 0  # No class
            call redefMsgEC
         end
         pop E  # Retrieve sym
         pop C  # and definition
      end
   end
   ld (E) C  # Set definition
   ld C 0  # No key
   call putSrcEC_E  # Put source information
   ret

# (quote . any) -> any
(code 'doQuote 2)
   ld E (E CDR)  # Get CDR
   ret

# (as 'any1 . any2) -> any2 | NIL
(code 'doAs 2)
   ld E (E CDR)
   push E  # Save args
   ld E (E)  # Eval condition
   eval
   pop A  # Retrieve args
   cmp E Nil  # Result NIL?
   ldnz E (A CDR)  # No: Return 'any2'
   ret

# (lit 'any) -> any
(code 'doLit 2)
   ld E ((E CDR))  # Eval arg
   eval
   num E  # Number?
   if z  # No
      cmp E Nil  # NIL?
      if ne  # No
         cmp E TSym  # T?
         if ne  # No
            atom E  # Pair?
            jnz 10  # No
            num (E)  # CAR number?
            if z  # No
10             ld A E
               call consE_E  # Cons with 'quote'
               ld (E) Quote
               ld (E CDR) A
            end
         end
      end
   end
   ret

# (eval 'any ['cnt ['lst]]) -> any
(code 'doEval 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   num E  # 'any' is number?
   if z  # No
      link
      push E  # <L I> 'any'
      link
      ld X (X CDR)  # X on rest
      atom X  # Any?
      if nz  # No
10       sym E  # Symbolic?
         if nz  # Yes
            ld E (E)  # Get value
         else
            call evListE_E  # Else evaluate expression
         end
         drop
         pop X
         ret
      end
      null (EnvBind)  # Bindings?
      jz 10  # No
      ld E (X)  # Eval 'cnt'
      eval
      shr E 4  # Normalize
      push E  # <L -I> 'cnt'
      push 0  # <L -II> 'n'
      ld E ((X CDR))  # Last argument
      eval  # Exclusion list 'lst' in E
      push Y
      ld C (L -I)  # Get 'cnt'
      ld Y (EnvBind)  # and bindings
      do
         ld A (Y)  # End of bindings in A
         inc (L -II)  # Increment 'n'
         sub (Y -I) (L -I)  # Decrement 'eswp' by 'cnt'
         if b  # First pass
            add Y I
            do
               ld X (Y)  # Next symbol
               xchg (X) (Y I)  # Exchange symbol value with saved value
               add Y II
               cmp Y A  # More?
            until eq  # No
            cmp X At  # Lambda frame?
            if eq  # Yes
               dec C  # Decrement local 'cnt'
               break z  # Done
            end
         end
         ld Y (A I)  # Bind link
         null Y  # More bindings?
      until z  # No
      atom E  # Exclusion list?
      if nz  # No
         ld E (L I)  # Get 'any'
         eval  # Evaluate it
      else
         push (EnvBind)  # Build bind frame
         link
         do
            ld X (E)  # Next excluded symbol
            push (X)  # Save in bind frame
            push X
            ld C (L -II)  # Get 'n'
            ld Y (EnvBind)  # Bindings
            do
               ld A (Y)  # End of bindings in A
               add Y I
               do
                  cmp X (Y)  # Found excluded symbol?
                  if eq  # Yes
                     ld (X) (Y I)  # Bind to found value
                     jmp 20
                  end
                  add Y II
                  cmp Y A  # More?
               until eq  # No
               dec C  # Traversed 'n' frames?
            while nz  # No
               ld Y (A I)  # Bind link
               null Y  # More bindings?
            until z  # No
20          ld E (E CDR)
            atom E  # Exclusion list?
         until nz  # No
         ld E ((L) I)  # Get 'any'
         link
         ld (EnvBind) L  # Close bind frame
         push 0  # Init env swap
         eval  # Evaluate 'any'
         add S I  # Drop env swap
         pop L  # Get link
         do  # Unbind excluded symbols
            pop X  # Next symbol
            pop (X)  # Restore value
            cmp S L  # More?
         until eq  # No
         pop L  # Restore link
         pop (EnvBind)  # Restore bind link
      end
      ld C (L -II)  # Get 'n'
      do
         ld A C  # in A
         ld Y (EnvBind)  # Bindings
         do
            dec A  # 'n-1' times
         while nz
            ld Y ((Y) I)  # Follow link
         loop
         add (Y -I) (L -I)  # Increment 'eswp' by 'cnt'
         if z  # Last pass
            lea A ((Y) -II)  # Last binding in A
            do
               xchg ((A)) (A I)  # Exchange next symbol value with saved value
               sub A II
               cmp A Y  # More?
            until lt  # No
         end
         dec C  # Decrement 'n'
      until z  # Done
      pop Y
      drop
   end
   pop X
   ret

# (run 'any ['cnt ['lst]]) -> any
(code 'doRun 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   num E  # 'any' is number?
   if z  # No
      link
      push E  # <L I> 'any'
      link
      ld X (X CDR)  # X on rest
      atom X  # Any?
      if nz  # No
10       sym E  # Symbolic?
         if nz  # Yes
            ld E (E)  # Get value
         else
            call runE_E  # Execute
         end
         drop
         pop X
         ret
      end
      null (EnvBind)  # Bindings?
      jz 10  # No
      ld E (X)  # Eval 'cnt'
      eval
      shr E 4  # Normalize
      push E  # <L -I> 'cnt'
      push 0  # <L -II> 'n'
      ld E ((X CDR))  # Last argument
      eval  # Exclusion list 'lst' in E
      push Y
      ld C (L -I)  # Get 'cnt'
      ld Y (EnvBind)  # and bindings
      do
         ld A (Y)  # End of bindings in A
         inc (L -II)  # Increment 'n'
         sub (Y -I) (L -I)  # Decrement 'eswp' by 'cnt'
         if b  # First pass
            add Y I
            do
               ld X (Y)  # Next symbol
               xchg (X) (Y I)  # Exchange symbol value with saved value
               add Y II
               cmp Y A  # More?
            until eq  # No
            cmp X At  # Lambda frame?
            if eq  # Yes
               dec C  # Decrement local 'cnt'
               break z  # Done
            end
         end
         ld Y (A I)  # Bind link
         null Y  # More bindings?
      until z  # No
      atom E  # Exclusion list?
      if nz  # No
         ld E (L I)  # Run 'any'
         sym E  # Symbolic?
         if nz  # Yes
            ld E (E)  # Get value
         else
            call runE_E  # Execute
         end
      else
         push (EnvBind)  # Build bind frame
         link
         do
            ld X (E)  # Next excluded symbol
            push (X)  # Save in bind frame
            push X
            ld C (L -II)  # Get 'n'
            ld Y (EnvBind)  # Bindings
            do
               ld A (Y)  # End of bindings in A
               add Y I
               do
                  cmp X (Y)  # Found excluded symbol?
                  if eq  # Yes
                     ld (X) (Y I)  # Bind to found value
                     jmp 20
                  end
                  add Y II
                  cmp Y A  # More?
               until eq  # No
               dec C  # Traversed 'n' frames?
            while nz  # No
               ld Y (A I)  # Bind link
               null Y  # More bindings?
            until z  # No
20          ld E (E CDR)
            atom E  # Exclusion list?
         until nz  # No
         ld E ((L) I)  # Get 'any'
         link
         ld (EnvBind) L  # Close bind frame
         push 0  # Init env swap
         sym E  # 'any' symbolic?
         if nz  # Yes
            ld E (E)  # Get value
         else
            call runE_E  # Execute
         end
         add S I  # Drop env swap
         pop L  # Get link
         do  # Unbind excluded symbols
            pop X  # Next symbol
            pop (X)  # Restore value
            cmp S L  # More?
         until eq  # No
         pop L  # Restore link
         pop (EnvBind)  # Restore bind link
      end
      ld C (L -II)  # Get 'n'
      do
         ld A C  # in A
         ld Y (EnvBind)  # Bindings
         do
            dec A  # 'n-1' times
         while nz
            ld Y ((Y) I)  # Follow link
         loop
         add (Y -I) (L -I)  # Increment 'eswp' by 'cnt'
         if z  # Last pass
            lea A ((Y) -II)  # Last binding in A
            do
               xchg ((A)) (A I)  # Exchange next symbol value with saved value
               sub A II
               cmp A Y  # More?
            until lt  # No
         end
         dec C  # Decrement 'n'
      until z  # Done
      pop Y
      drop
   end
   pop X
   ret

# (def 'sym 'any) -> sym
# (def 'sym 'sym 'any) -> sym
(code 'doDef 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   link
   push E  # <L II/III> First symbol
   ld Y (Y CDR)  # Next arg
   ld E (Y)
   eval+  # Eval next arg
   push E  # <L I/II> Second arg
   link
   ld Y (Y CDR)  # Third arg?
   atom Y
   if nz  # No
      ld E (L II)  # First symbol
      call checkVarEX  # Check
      sym (E TAIL)  # External symbol?
      if nz  # Yes
         call dbTouchEX  # Touch it
      end
      ld A (E)  # Current value
      cmp A Nil  # NIL?
      if ne  # NO
         cmp A E  # Auto-symbol?
         if ne  # No
            ld E (L I)  # New value
            call equalAE_F  # Changing?
            if ne  # Yes
               ld E (L II)  # Get symbol
               ld C 0  # No class
               call redefMsgEC
            end
            ld E (L II)  # Get symbol again
         end
      end
      ld (E) (L I)  # Set symbol to new value
      ld C 0  # No key
      call putSrcEC_E  # Put source information
   else
      ld E (Y)
      eval  # Eval next arg
      tuck E  # <L I> Third arg
      link
      ld E (L III)  # First symbol
      ld C (L II)  # Second arg
      sym (E TAIL)  # External symbol?
      if nz  # Yes
         cmp C Nil  # Volatile property?
         if ne  # No
            call dbTouchEX  # Touch symbol
         else
            call dbFetchEX  # else fetch
         end
      end
      call getEC_E  # Current property value
      cmp E Nil  # NIL?
      if ne  # NO
         ld A (L I)  # New value
         call equalAE_F  # Changing?
         if ne  # Yes
            ld E (L III)  # First symbol
            ld C (L II)  # Property key
            call redefMsgEC
         end
      end
      ld A (L III)  # Symbol
      ld C (L II)  # Key
      ld E (L I)  # Value
      call putACE  # Put propery
      ld E (L III)  # Symbol
      ld C (L II)  # Key
      call putSrcEC_E  # Put source information
   end
   drop  # Return first symbol
   pop Y
   pop X
   ret

# (de sym . any) -> sym
(code 'doDe 2)
   push X
   ld X E
   ld E ((E CDR))  # Symbol in E
   ld C ((X CDR) CDR)  # Body in C
   call needSymEX
   call redefineCE  # Redefine
   pop X
   ret

# (dm sym . fun|cls2) -> sym
# (dm (sym . cls) . fun|cls2) -> sym
# (dm (sym sym2 [. cls]) . fun|cls2) -> sym
(code 'doDm 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Get first
   atom E  # First form?
   if nz  # Yes
      ld C (Class)  # Get 'cls' from Class
   else
      ld C (E CDR)
      atom C  # Second form?
      if z  # No
         ld E (C CDR)  # 'cls'?
         cmp E Nil
         if eq  # No
            ld E (Class)  # Default to Class
         end
         ld C (C)  # 'sym'
         call getEC_E  # Get instance object
         ld C E  # into C
         ld E (Y)  # Get first again
      end
      ld E (E)  # msg
   end
   cmp E TSym  # 'msg' is T?
   if ne  # No
      push C  # Save class
      ld C (Meth)  # Get 'meth' code pointer
      call needSymEX
      call redefineCE  # Redefine
      pop C
   end
   ld A (Y CDR)  # Explicit inheritance?
   num A
   if z  # No
      sym A
      if nz  # Yes
         ld A (A)  # Get cls2's value
         do
            atom A  # More method definitions?
            jnz msgErrAX  # No
            atom (A)
            jnz msgErrAX
            cmp E ((A))  # Found 'msg'?
            if eq  # Yes
               ld Y (A)  # Get method entry
               break T
            end
            ld A (A CDR)
         loop
      end
   end
   ld X (C)  # Get cls's value
   do
      atom X  # More method definitions?
   while z  # Yes
      atom (X)
   while z
      cmp E ((X))  # Found 'msg'?
      if eq  # Yes
         push E  # Save 'msg'
         ld E ((X) CDR)  # Old body
         ld A (Y CDR)  # New body
         call equalAE_F  # Changing?
         if ne  # Yes
            ld E (S)  # Get 'msg'
            push C  # Save 'cls'
            call redefMsgEC
            pop C
         end
         pop E
         ld ((X) CDR) (Y CDR)  # Set new body
         jmp 90
      end
      ld X (X CDR)
   loop
   atom (Y)  # First form or explict inheritance?
   if nz  # Yes
      call cons_A  # Cons into methods
      ld (A) Y
      ld (A CDR) (C)
   else
      call cons_A  # Cons 'msg'
      ld (A) E
      ld (A CDR) (Y CDR)  # With method body
      push A
      call consA_A  # Cons into methods
      pop (A)
      ld (A CDR) (C)
   end
   ld (C) A
90 xchg C E  # 'msg' <-> 'cls'
   call putSrcEC_E  # Put source information
   ld E C  # Return 'msg'
   pop Y
   pop X
   ret

# Apply METH in C to X, with object A
(code 'evMethodACEXYZ_E 0)
   cmp S (StkLimit)  # Stack check
   jlt stkErr
   push Z  # <(L) IV> 'cls'
   push Y  # <(L) III> 'key'
   ld Y (C)  # Parameter list in Y
   ld Z (C CDR)  # Body in Z
   push E  # Save 'exe'
   push (EnvBind)  # Build bind frame
   link
   push (At)  # Bind At
   push At
   push A  # Bind object in A
   push This  # to 'This'
   do
      atom Y  # More evaluating parameters?
   while z  # Yes
      ld E (X)  # Get next argument
      ld X (X CDR)
      eval+  # Evaluate and save
      push E
      push (Y)  # Save symbol
      ld Y (Y CDR)
   loop
   cmp Y Nil  # NIL-terminated parameter list?
   if eq  # Yes: Bind parameter symbols
      ld Y S  # Y on bindings
      do
         ld X (Y)  # Symbol in X
         add Y I
         ld A (X)  # Old value in A
         ld (X) (Y)  # Set new value
         ld (Y) A  # Save old value
         add Y I
         cmp Y L  # End?
      until eq  # Yes
      link
      ld (EnvBind) L  # Close bind frame
      push 0  # Init env swap
      xchg (EnvCls) ((L) IV)  # 'cls'
      xchg (EnvKey) ((L) III)  # 'key'
      prog Z  # Run body
      add S I  # Drop env swap
      pop L  # Get link
      do  # Unbind symbols
         pop X  # Next symbol
         pop (X)  # Restore value
         cmp S L  # More?
      until eq  # No
      pop L  # Restore link
      pop (EnvBind)  # Restore bind link
      add S I  # Drop 'exe'
      pop (EnvKey)  # 'key'
      pop (EnvCls)  # and 'cls'
      ret
   end
   # Non-NIL parameter
   cmp Y At  # '@'?
   if ne  # No
      push (Y)  # Save last parameter's old value
      push Y  # and the last parameter
      ld (Y) X  # Set to unevaluated argument list
      lea Y (S II)  # Y on evaluated bindings
      do
         ld X (Y)  # Symbol in X
         add Y I
         ld A (X)  # Old value in A
         ld (X) (Y)  # Set new value
         ld (Y) A  # Save old value
         add Y I
         cmp Y L  # End?
      until eq  # Yes
      link
      ld (EnvBind) L  # Close bind frame
      push 0  # Init env swap
      xchg (EnvCls) ((L) IV)  # 'cls'
      xchg (EnvKey) ((L) III)  # 'key'
      prog Z  # Run body
      add S I  # Drop env swap
      pop L  # Get link
      do  # Unbind symbols
         pop X  # Next symbol
         pop (X)  # Restore value
         cmp S L  # More?
      until eq  # No
      pop L  # Restore link
      pop (EnvBind)  # Restore bind link
      add S I  # Drop 'exe'
      pop (EnvKey)  # 'key'
      pop (EnvCls)  # and 'cls'
      ret
   end
   # Evaluated argument list
   link  # Close bind frame
   ld Y L  # Y on frame
   push 0  # Init env swap
   push (EnvArgs)  # Save varArgs base
   atom X  # Any args?
   if nz  # No
      ld (EnvArgs) 0
      push (EnvNext)   # Save current 'next'
      ld (EnvNext) 0
   else
      link  # Build varArgs frame
      do
         ld E (X)  # Get next argument
         eval+  # Evaluate and save
         push E
         ld X (X CDR)
         atom X  # More args?
      until nz  # No
      ld (EnvArgs) S  # Set new varArgs base
      link  # Close varArgs frame
      push (EnvNext)   # Save current 'next'
      ld (EnvNext) (L)  # Set new 'next'
   end
   ld (EnvBind) Y  # Close bind frame
   xchg (EnvCls) ((Y) IV)  # 'cls'
   xchg (EnvKey) ((Y) III)  # 'key'
   ld C (Y)  # End of bindings in C
   add Y I
   do
      ld X (Y)  # Symbol in X
      add Y I
      ld A (X)  # Old value in A
      ld (X) (Y)  # Set new value
      ld (Y) A  # Save old value
      add Y I
      cmp Y C  # End?
   until eq  # Yes
   prog Z  # Run body
   pop (EnvNext)   # Restore 'next'
   null (EnvArgs)  # VarArgs?
   if nz  # Yes
      drop  # Drop varArgs
   end
   pop (EnvArgs)  # Restore varArgs base
   add S I  # Drop env swap
   pop L  # Get link
   do  # Unbind symbols
      pop X  # Next symbol
      pop (X)  # Restore value
      cmp S L  # More?
   until eq  # No
   pop L  # Restore link
   pop (EnvBind)  # Restore bind link
   add S I  # Drop 'exe'
   pop (EnvKey)  # 'key'
   pop (EnvCls)  # and 'cls'
   ret

(code 'methodEY_FCYZ 0)
   ld A (E)  # Get class definition (methods and superclasses)
   atom A  # Any?
   if z  # Yes
      do
         ld C (A)  # First item
         atom C  # Method definition?
      while z  # Yes
         cmp Y (C)  # Found method definition?
         if eq  # Yes
            ld C (C CDR)  # Return method
            ret  # 'z'
         end
         ld A (A CDR)  # Next item
         atom A  # Any?
         jnz ret  # Return 'nz'
      loop
      cmp S (StkLimit)  # Stack check
      jlt stkErr
      do
         ld Z A  # Set class list
         ld E (A)  # Class symbol
         push A
         call methodEY_FCYZ  # Found method definition?
         pop A
         jeq ret  # 'z'
         ld A (A CDR)  # Next superclass
         atom A  # Any?
      until nz  # No
   end
   ret  # 'nz'

# (box 'any) -> sym
(code 'doBox 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   call consE_A  # New symbol
   ld (A) ZERO  # anonymous
   or A SYM
   ld (A) E  # Set value
   ld E A
   ret

# (new ['flg|num] ['typ ['any ..]]) -> obj
(code 'doNew 2)
   push X
   push Y
   push Z
   ld Z E  # Save 'exe' in Z
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   atom E  # 'typ' list?
   if z  # Yes
      call consE_A  # New object
      ld (A) ZERO  # anonymous
      or A SYM  # Make symbol
      ld (A) E  # Set 'typ'
      link
      push A  # <L II> 'obj'
      push Nil  # <L I> Safe
      link
   else
      cmp E Nil  # 'flg'?
      if eq  # NIL
         call cons_E  # New object
         ld (E) ZERO  # anonymous
         or E SYM  # Make symbol
         ld (E) Nil  # Init to 'NIL'
      else  # External object
         cnt E  # File number?
         ldz E ONE  # Default to '1'
         shr E 4  # Normalize
         call newIdEX_X  # Allocate new external name
         call externX_E  # Intern external symbol
         ld A (E TAIL)  # Get name again
         add A A
         setx  # Set "dirty"
         rxr A 1
         ld (E TAIL) A  # Set name
      end
      link
      push E  # <L II> 'obj'
      push Nil  # <L I> Safe
      link
      ld Y (Y CDR)  # Next arg
      ld E (Y)
      eval  # Eval 'typ'
      ld A (L II)  # Object in A
      ld (A) E  #  Set value in 'obj'
   end
   push Z  # <S> 'exe'
   ld X (Y CDR)  # Keep args in X
   ld E A  # Object
   ld Y TSym  # Search for initial method
   ld Z 0  # No classes
   call methodEY_FCYZ  # Found?
   if eq  # Yes
      ld A (L II)  # Get 'obj'
      ld E (S)  # and 'exe'
      call evMethodACEXYZ_E
   else
      do
         atom X  # More args?
      while z  # Yes
         ld E (X)  # Eval next key
         eval
         ld (L I) E  # Save it
         ld X (X CDR)
         ld E (X)  # Eval next value
         eval
         ld A (L II)  # 'obj'
         ld C (L I)  # Key
         call putACE  # Put property
         ld X (X CDR)
      loop
   end
   ld E (L II)  # Return 'obj'
   drop
   pop Z
   pop Y
   pop X
   ret

# (type 'any) -> lst
(code 'doType 2)
   push X
   ld X E
   ld E ((E CDR))  # E on arg
   eval  # Eval it
   num E  # Symbol?
   if z
      sym E
      if nz  # Yes
         sym (E TAIL)  # External symbol?
         if nz  # Yes
            call dbFetchEX  # Fetch it
         end
         pop X
         ld E (E)  # Get value
         ld C E  # Keep in C
         do
            atom E  # Class definitions?
            jnz retNil  # No
            atom (E)  # Class?
            if nz  # Yes
               ld A E
               do
                  num (A)  # Symbol?
                  jnz retNil  # No
                  ld A (A CDR)  # Next class
                  atom A  # Any?
                  if nz  # No
                     cmp A Nil  # End of classes?
                     jnz retNil  # No
                     ret  # Return E
                  end
                  cmp C A  # Circular?
                  jeq retNil  # Yes
               loop
            end
            ld E (E CDR)  # Next definition
            cmp C E  # Circular?
            jeq retNil  # Yes
         loop
      end
   end
   pop X
   ld E Nil  # Return NIL
   ret

# (isa 'cls|typ 'any) -> obj | NIL
(code 'doIsa 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   link
   push E  # <L I> 'cls|typ'
   link
   ld Y (Y CDR)  # Next arg
   ld E (Y)
   eval  # Eval 'any'
   num E  # Symbol?
   if z
      sym E
      if nz  # Yes
         sym (E TAIL)  # External symbol?
         if nz  # Yes
            call dbFetchEX  # Fetch it
         end
         ld C (L I)  # Get 'cls|typ'
         atom C  # 'cls'?
         if nz  # Yes
            call isaCE_F  # Check
            ldnz E Nil  # Return NIL if no match
         else
            ld Y C  # Get 'typ' in Y
            do
               ld C (Y)  # Next class
               call isaCE_F  # Check
               if nz
                  ld E Nil  # Return NIL if no match
                  break T
               end
               ld Y (Y CDR)  # More?
               atom Y
            until nz  # No
         end
         drop
         pop Y
         pop X
         ret
      end
   end
   ld E Nil  # Return NIL
   drop
   pop Y
   pop X
   ret

: isaCE_F  # A, X
   ld X (E)  # Get value
   ld A X  # Keep in A
   do
      atom X  # Atomic value?
      jnz ret  # Return NO
      atom (X)  # Next item atomic?
      if nz  # Yes
         cmp S (StkLimit)  # Stack check
         jlt stkErr
         do
            num (X)  # Numeric?
            jnz ret  # Return NO
            sym ((X) TAIL)  # External?
            jnz ret  # Return NO
            cmp C (X)  # Match?
            jeq ret  # Return YES
            push A  # Save list head
            push E  # object
            push X  # and list
            ld E (X)  # Recurse
            call isaCE_F  # Match?
            pop X
            pop E
            pop A
            jeq ret  # Return YES
            ld X (X CDR)  # Next class
            atom X  # Any?
            jnz ret  # Return NO
            cmp A X  # Circular?
            jeq retGt  # Return NO
            atom (X)  # Next item a list?
            jz retGt  # Return NO
         loop
      end
      ld X (X CDR)  # Next item
      cmp A X  # Circular?
      jeq retGt  # Yes
   loop

# (method 'msg 'obj) -> fun
(code 'doMethod 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval  # Eval it
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   link
   push E  # <L I> 'msg'
   link
   ld E ((Y CDR))  # Second
   eval  # 'obj'
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   sym (E TAIL)  # External symbol?
   if nz  # Yes
      call dbFetchEX  # Fetch it
   end
   ld Y (L I)  # 'msg'
   call methodEY_FCYZ  # Found?
   ld E C  # Yes
   ldnz E Nil  # No
   drop
   pop Z
   pop Y
   pop X
   ret

# (meth 'obj ['any ..]) -> any
(code 'doMeth 2)
   push X
   push Y
   push Z
   link
   push C  # <L II> Message symbol
   link
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval 'obj'
   eval
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   tuck E  # <L I> 'obj'
   link
   sym (E TAIL)  # External symbol?
   if nz  # Yes
      call dbFetchEX  # Fetch it
   end
   push (Y CDR)  # Save args
   ld Y (L II)  # Get message
   num Y  # Need symbol
   jnz msgErrYX
   ld Z 0  # No classes
   call methodEY_FCYZ  # Found?
   jne msgErrYX  # No
   ld A (L I)  # Get 'obj'
   ld E X  # 'exe'
   pop X  # and args
   call evMethodACEXYZ_E
   drop
   pop Z
   pop Y
   pop X
   ret

# (send 'msg 'obj ['any ..]) -> any
(code 'doSend 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval 'msg'
   eval
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   link
   push E  # <L II> 'msg'
   ld Y (Y CDR)  # Next arg
   ld E (Y)
   eval+  # Eval 'obj'
   push E  # <L I> 'obj'
   link
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   sym (E TAIL)  # External symbol?
   if nz  # Yes
      call dbFetchEX  # Fetch it
   end
   push (Y CDR)  # Save args
   ld Y (L II)  # Get 'msg'
   ld Z 0  # No classes
   call methodEY_FCYZ  # Found?
   jne msgErrYX  # No
   ld A (L I)  # Get 'obj'
   ld E X  # 'exe'
   pop X  # and args
   call evMethodACEXYZ_E
   drop
   pop Z
   pop Y
   pop X
   ret

# (try 'msg 'obj ['any ..]) -> any
(code 'doTry 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval 'msg'
   eval
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   link
   push E  # <L II> 'msg'
   ld Y (Y CDR)  # Next arg
   ld E (Y)
   eval+  # Eval
   push E  # <L I> 'obj'
   link
   num E  # Symbol?
   jnz 90
   sym E
   jz 90  # No
   sym (E TAIL)  # External symbol?
   if nz  # Yes
      call isLifeE_F  # Alive?
      jnz 90  # No
      call dbFetchEX  # Fetch it
   end
   push (Y CDR)  # Save args
   ld Y (L II)  # Get 'msg'
   ld Z 0  # No classes
   call methodEY_FCYZ  # Found?
   if eq  # Yes
      ld A (L I)  # Get 'obj'
      ld E X  # 'exe'
      ld X (S)  # and args
      call evMethodACEXYZ_E
   else
90    ld E Nil
   end
   drop
   pop Z
   pop Y
   pop X
   ret

# (super ['any ..]) -> any
(code 'doSuper 2)
   push X
   push Y
   push Z
   push E  # Save expression
   ld X (EnvCls)  # 'cls'
   ld Y (EnvKey)  # 'key'
   null X  # Any?
   ldnz X (X)  # Yes: First class
   ldz X (This)  # No: 'This'
   ld X (X)  # Get class definition
   do
      atom (X)  # Method?
   while z  # Yes
      ld X (X CDR)  # Skip
   loop
   do
      atom X  # Classes?
   while z  # Yes
      ld E (X)  # First class
      ld Z X  # 'cls'
      call methodEY_FCYZ  # Found?
      if eq  # Yes
         pop E  # Get expression
         push (EnvCls)  # 'cls'
         push (EnvKey)  # 'key'
         ld (EnvCls) Z  # Set new
         ld (EnvKey) Y
         call evExprCE_E  # Evaluate expression
         pop (EnvKey)
         pop (EnvCls)
         pop Z
         pop Y
         pop X
         ret
      end
      ld X (X CDR)
   loop
   ld E Y  # 'key'
   pop X  # Expression
   ld Y SuperErr
   jmp errEXYZ

# (extra ['any ..]) -> any
(code 'doExtra 2)
   push X
   push Y
   push Z
   push E  # Save expression
   ld Y (EnvKey)  # Get 'key'
   ld X (This)  # Current object
   call extraXY_FCYZ  # Locate extra method
   if eq
      pop E  # Get expression
      push (EnvCls)  # 'cls'
      push (EnvKey)  # 'key'
      ld (EnvCls) Z  # Set new
      ld (EnvKey) Y
      call evExprCE_E  # Evaluate expression
      pop (EnvKey)
      pop (EnvCls)
      pop Z
      pop Y
      pop X
      ret
   end
   ld E Y  # 'key'
   pop X  # Expression
   ld Y ExtraErr
   jmp errEXYZ

(code 'extraXY_FCYZ 0)
   ld X (X)  # Get class definition
   do
      atom (X)  # Method?
   while z  # Yes
      ld X (X CDR)  # Skip
   loop
   do
      atom X  # Classes?
   while z  # Yes
      cmp X (EnvCls)  # Hit current 'cls' list?
      if eq  # Yes
10       do
            ld X (X CDR)  # Locate method in extra classes
            atom X  # Any?
            jnz retGt  # No: Return 'gt'
            ld E (X)  # Superclass
            ld Z X  # 'cls'
            call methodEY_FCYZ  # Found?
         until eq  # Return 'eq'
         ret
      end
      cmp S (StkLimit)  # Stack check
      jlt stkErr
      push X
      ld X (X)  # Recurse on superclass
      call extraXY_FCYZ  # Found?
      pop X
      jeq ret  # Yes
      jgt 10  # Else try extra classes
      ld X (X CDR)  # Try next in 'cls' list
   loop
   lt
   ret

# (with 'sym . prg) -> any
(code 'doWith 2)
   push X
   ld X E
   ld E ((E CDR))  # Eval first Arg
   eval
   cmp E Nil  # Non-NIL?
   if ne  # Yes
      num E  # Need symbol
      jnz symErrEX
      sym E
      jz symErrEX
      push (EnvBind)  # Build bind frame
      link
      push (This)  # Save old 'This'
      push This  # and 'sym'
      link
      ld (EnvBind) L  # Close bind frame
      push 0  # Init env swap
      ld (This) E  # Set new
      ld X ((X CDR) CDR)  # Run 'prg'
      prog X
      add S III  # Drop 'eswp' + link + 'This'
      pop (This)  # Restore value
      pop L  # Restore link
      pop (EnvBind)  # Restore bind link
   end
   pop X
   ret

# (bind 'sym|lst . prg) -> any
(code 'doBind 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   num E  # Need sym|lst
   jnz argErrEX
   ld Y (Y CDR)  # Y on 'prg'
   cmp E Nil  # No bindings?
   if eq  # Yes
      prog Y  # Run 'prg'
      pop Y
      pop X
      ret
   end
   push (EnvBind)  # Build bind frame
   link
   sym E  # Single symbol?
   if nz  # Yes
      push (E)  # Save value
      push E  # and 'sym'
      link
      ld (EnvBind) L  # Close bind frame
      push 0  # Init env swap
      prog Y  # Run 'prg'
      add S I  # Drop env swap
      pop L  # Get link
      pop X  # Unbind symbol
      pop (X)  # Restore value
      pop L  # Restore link
      pop (EnvBind)  # Restore bind link
      pop Y
      pop X
      ret
   end
   do
      ld A (E)  # Next item
      num A  # Need symbol or pair
      jnz argErrAX
      ld C (A)  # Get VAL or CAR
      sym A  # Symbol?
      if nz  # Yes
         push C  # Save value
         push A  # and 'sym'
      else
         push (C)  # Save value
         push C  # and 'sym'
         ld (C) (A CDR)  # Set new value
      end
      ld E (E CDR)  # More items?
      atom E
   until nz  # No
   link
   ld (EnvBind) L  # Close bind frame
   push 0  # Init env swap
   prog Y  # Run 'prg'
   add S I  # Drop env swap
   pop L  # Get link
   do  # Unbind symbols
      pop X  # Next symbol
      pop (X)  # Restore value
      cmp S L  # More?
   until eq  # No
   pop L  # Restore link
   pop (EnvBind)  # Restore bind link
   pop Y
   pop X
   ret

# (job 'lst . prg) -> any
(code 'doJob 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   cmp E Nil  # Empty env 'lst'?
   if ne  # No
      push (EnvBind)  # Build bind frame
      link
      ld A E  # Get 'lst'
      do
         ld C (A)  # Next cell
         push ((C))  # Save value
         push (C)  # and sym
         ld ((C)) (C CDR)  # Set new value
         ld A (A CDR)
         atom A  # More cells?
      until nz  # No
      link
      ld (EnvBind) L  # Close bind frame
      push 0  # Init env swap
   end
   link
   push E  # <L I> 'lst'
   link
   ld X (X CDR)  # X on 'prg'
   prog X  # Run 'prg'
   add S I  # Drop link
   pop C  # Retrieve 'lst'
   pop L  # Unlink
   cmp C Nil  # Empty env 'lst'?
   if ne  # No
      add S I  # Drop env swap
      lea X ((L) -II)  # X on bindings
      do  # Unbind symbols
         ld A (X)  # Next symbol
         ld ((C) CDR) (A)  # Store value in env
         ld (A) (X I)  # Restore value
         ld C (C CDR)
         sub X II  # Reverse stacked order
         cmp X L  # More?
      until lt  # No
      drop  # Restore link
      pop (EnvBind)  # Restore bind link
   end
   pop X
   ret

(code 'setDestructAE 0)
   do
      atom E  # List data?
      if nz  # No
         ld E Nil  # Default to NIL
      end
      atom (A)  # Structure symbol in CAR?
      if nz  # Yes
         cmp (A) Nil  # Skip NIL
         if ne
            ld ((A)) (E)  # Set new value
         end
      else
         push A  # Recurse left
         push E
         ld A (A)
         ld E (E)
         call setDestructAE  # Recurse
         pop E
         pop A
      end
      ld E (E CDR)  # Traverse
      atom (A CDR)  # Right?
      if nz  # No
         cmp (A CDR) Nil  # Dotted structure symbol?
         if ne  # Yes
            ld ((A CDR)) E  # Set new value
         end
         ret
      end
      ld A (A CDR)  # Traverse right
   loop

# (let sym 'any . prg) -> any
# (let (sym|lst 'any ..) . prg) -> any
(code 'doLet 2)
   push X
   push Y
   ld X (E CDR)  # Args
   ld Y (X)  # First arg
   ld X (X CDR)
   sym Y  # Single symbol?
   if nz  # Yes
      push (EnvBind)  # Build bind frame
      link
      push (Y)  # Save old value
      push Y  # and 'sym'
      link
      ld (EnvBind) L  # Close bind frame
      push 0  # Init env swap
      ld E (X)  # Eval 'any'
      eval
      ld (Y) E  # Set new value
      ld X (X CDR)  # Run 'prg'
      prog X
      add S I  # Drop env swap
      pop L  # Get link
      pop X  # Unbind symbol
      pop (X)  # Restore value
      pop L  # Restore link
      pop (EnvBind)  # Restore bind link
      pop Y
      pop X
      ret
   end
   push Z
   push (EnvBind)  # Build bind frame
   link
   do
      ld A (Y)  # Next item
      sym A  # Single symbol?
      if nz  # Yes
         push (A)  # Save old value
         push A  # and sym
         link
         ld (EnvBind) L  # Close bind frame
         push 0  # Init env swap
         ld E ((Y CDR))  # Eval 'any'
         eval
         ld ((Y)) E  # Set new value
      else  # 'lst'
         ld Z 0  # Clear TOS
         do
            do
               atom (A)  # Left?
            while z  # Yes
               ld C A  # Go left
               ld A (A)  # Invert tree
               ld (C) Z  # TOS
               ld Z C
            loop
            cmp (A) Nil  # Skip NIL
            if ne
               push ((A))  # Save old value
               push (A)  # and sym
            end
            do
               atom (A CDR)  # Right?
               if nz  # No
                  cmp (A CDR) Nil  # Dotted structure symbol?
                  if ne  # Yes
                     push ((A CDR))  # Save old value
                     push (A CDR)  # and sym
                  end
               else
                  ld C A  # Go right
                  ld A (A CDR)  # Invert tree
                  ld (C CDR) Z  # TOS
                  or C SYM  # First visit
                  ld Z C
                  break T
               end
               do
                  ld C Z  # TOS
                  null C  # Empty?
                  jeq 10  # Done
                  sym C  # Second visit?
                  if z  # Yes
                     ld Z (C)  # TOS on up link
                     ld (C) A
                     ld A C
                     break T
                  end
                  off C SYM  # Set second visit
                  ld Z (C CDR)
                  ld (C CDR) A
                  ld A C
               loop
            loop
         loop
10       link
         ld (EnvBind) L  # Close bind frame
         push 0  # Init env swap
         ld E ((Y CDR))  # Eval 'any'
         eval
         ld A (Y)  # Get 'lst' again
         call setDestructAE  # Set new values
      end
      ld Y ((Y CDR) CDR)  # More items?
      atom Y
   while z  # Yes
      pop A  # Drop env swap
      pop L  # and link
   loop
   prog X  # Run 'prg'
   add S I  # Drop env swap
   pop L  # Get link
   do  # Unbind symbols
      pop X  # Next symbol
      pop (X)  # Restore value
      cmp S L  # More?
   until eq  # No
   pop L  # Restore link
   pop (EnvBind)  # Restore bind link
   pop Z
   pop Y
   pop X
   ret

# (let? sym 'any . prg) -> any
(code 'doLetQ 2)
   push X
   push Y
   ld X (E CDR)  # Args
   ld Y (X)  # Get 'sym'
   ld X (X CDR)
   ld E (X)  # Eval 'any'
   eval
   cmp E Nil  # NIL?
   if ne  # No
      push (EnvBind)  # Build bind frame
      link
      push (Y)  # Save old value
      push Y  # and 'sym'
      link
      ld (EnvBind) L  # Close bind frame
      push 0  # Init env swap
      ld (Y) E  # Set new value
      ld X (X CDR)  # Run 'prg'
      prog X
      add S I  # Drop env swap
      pop L  # Get link
      pop X  # Unbind symbol
      pop (X)  # Restore value
      pop L  # Restore link
      pop (EnvBind)  # Restore bind link
   end
   pop Y
   pop X
   ret

# (use sym . prg) -> any
# (use (sym ..) . prg) -> any
(code 'doUse 2)
   push X
   push Y
   ld X (E CDR)  # Args
   ld Y (X)  # First arg
   ld X (X CDR)
   push (EnvBind)  # Build bind frame
   link
   sym Y  # Single symbol?
   if nz  # Yes
      push (Y)  # Save old value
      push Y  # and 'sym'
      link
      ld (EnvBind) L  # Close bind frame
      push 0  # Init env swap
      prog X  # Run 'prg'
      add S I  # Drop env swap
      pop L  # Get link
      pop X  # Unbind symbol
      pop (X)  # Restore value
      pop L  # Restore link
      pop (EnvBind)  # Restore bind link
      pop Y
      pop X
      ret
   end
   do
      ld A (Y)  # Next sym
      push (A)  # Save old value
      push A  # and sym
      ld Y (Y CDR)  # More symbols?
      atom Y
   until nz  # No
   link
   ld (EnvBind) L  # Close bind frame
   push 0  # Init env swap
   prog X  # Run 'prg'
   add S I  # Drop env swap
   pop L  # Get link
   do  # Unbind symbols
      pop X  # Next symbol
      pop (X)  # Restore value
      cmp S L  # More?
   until eq  # No
   pop L  # Restore link
   pop (EnvBind)  # Restore bind link
   pop Y
   pop X
   ret

# (and 'any ..) -> any
(code 'doAnd 2)
   push X
   ld X (E CDR)  # Args
   do
      ld E (X)  # Eval next
      eval
      cmp E Nil  # NIL?
   while ne  # No
      ld (At) E
      ld X (X CDR)  # X on rest
      atom X  # Done?
   until nz  # Yes
   pop X
   ret

# (or 'any ..) -> any
(code 'doOr 2)
   push X
   ld X (E CDR)  # Args
   do
      ld E (X)  # Eval next
      eval
      cmp E Nil  # NIL?
      if ne  # No
         ld (At) E
         pop X
         ret
      end
      ld X (X CDR)  # X on rest
      atom X  # Done?
   until nz  # Yes
   pop X
   ret

# (nand 'any ..) -> flg
(code 'doNand 2)
   push X
   ld X (E CDR)  # Args
   do
      ld E (X)  # Eval next
      eval
      cmp E Nil  # NIL?
      if eq  # Yes
         ld E TSym  # Return T
         pop X
         ret
      end
      ld (At) E
      ld X (X CDR)  # X on rest
      atom X  # Done?
   until nz  # Yes
   ld E Nil  # Return NIL
   pop X
   ret

# (nor 'any ..) -> flg
(code 'doNor 2)
   push X
   ld X (E CDR)  # Args
   do
      ld E (X)  # Eval next
      eval
      cmp E Nil  # NIL?
      if ne  # No
         ld (At) E
         ld E Nil  # Return NIL
         pop X
         ret
      end
      ld X (X CDR)  # X on rest
      atom X  # Done?
   until nz  # Yes
   ld E TSym  # Return T
   pop X
   ret

# (xor 'any 'any) -> flg
(code 'doXor 2)
   ld E (E CDR)
   push (E CDR)  # Push rest
   ld E (E)  # Eval first
   eval
   cmp E Nil  # NIL?
   if eq  # Yes
      pop E  # Get rest
      ld E (E)  # Eval second
      eval
      cmp E Nil  # NIL again?
      ldnz E TSym  # No
      ret
   end
   pop E  # Get rest
   ld E (E)  # Eval second
   eval
   cmp E Nil  # NIL?
   ld E Nil
   ldz E TSym  # Yes
   ret

# (bool 'any) -> flg
(code 'doBool 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   cmp E Nil  # NIL?
   ldnz E TSym  # No
   ret

# (not 'any) -> flg
(code 'doNot 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   cmp E Nil  # NIL?
   jeq retT  # Yes
   ld (At) E
   ld E Nil
   ret

# (nil . prg) -> NIL
(code 'doNil 2)
   push X
   ld X (E CDR)  # Get 'prg'
   exec X  # Execute it
   ld E Nil  # Return NIL
   pop X
   ret

# (t . prg) -> T
(code 'doT 2)
   push X
   ld X (E CDR)  # Get 'prg'
   exec X  # Execute it
   ld E TSym  # Return T
   pop X
   ret

# (prog . prg) -> any
(code 'doProg 2)
   push X
   ld X (E CDR)  # Get 'prg'
   prog X  # Run it
   pop X
   ret

# (prog1 'any1 . prg) -> any1
(code 'doProg1 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   ld (At) E
   link
   push E  # <L I> Result
   link
   ld X (X CDR)  # Get 'prg'
   exec X  # Execute it
   ld E (L I)  # Get result
   drop
   pop X
   ret

# (prog2 'any1 'any2 . prg) -> any2
(code 'doProg2 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   ld X (X CDR)  # Eval second
   ld E (X)
   eval
   ld (At) E
   link
   push E  # <L I> Result
   link
   ld X (X CDR)  # Get 'prg'
   exec X  # Execute it
   ld E (L I)  # Get result
   drop
   pop X
   ret

# (if 'any1 any2 . prg) -> any
(code 'doIf 2)
   ld E (E CDR)
   push (E CDR)  # Push rest
   ld E (E)  # Eval condition
   eval
   cmp E Nil
   if ne  # Non-NIL
      ld (At) E
      pop E  # Get rest
      ld E (E)  # Consequent
      eval/ret
   end
   xchg X (S)  # Get rest in X
   ld X (X CDR)  # Else
   prog X
   pop X
   ret

# (if2 'any1 'any2 any3 any4 any5 . prg) -> any
(code 'doIf2 2)
   ld E (E CDR)
   push (E CDR)  # Push rest
   ld E (E)  # Eval first condition 'any1'
   eval
   cmp E Nil
   if eq  # NIL
      xchg X (S)  # Get rest in X
      ld E (X)  # Eval second condition 'any2'
      eval
      cmp E Nil
      if eq  # Also NIL
         ld X ((((X CDR) CDR) CDR) CDR)  # Run 'prg'
         prog X
         pop X
         ret
      end
      ld (At) E
      ld X (((X CDR) CDR) CDR)  # Eval 'any5'
      ld E (X)
      pop X
      eval/ret
   end
   ld (At) E  # 'any1' is non-Nil
   xchg X (S)  # Get rest in X
   ld E (X)  # Eval second condition 'any2'
   eval
   cmp E Nil
   if eq  # NIL
      ld X ((X CDR) CDR)  # Eval 'any4'
      ld E (X)
      pop X
      eval/ret
   end
   ld (At) E  # Both are non-Nil
   ld X (X CDR)  # Eval 'any3'
   ld E (X)
   pop X
   eval/ret

# (ifn 'any1 any2 . prg) -> any
(code 'doIfn 2)
   ld E (E CDR)
   push (E CDR)  # Push body
   ld E (E)  # Eval condition
   eval
   cmp E Nil
   if eq  # NIL
      pop E  # Get rest
      ld E (E)  # Consequent
      eval/ret
   end
   ld (At) E
   xchg X (S)  # Get rest in X
   ld X (X CDR)  # Else
   prog X
   pop X
   ret

# (when 'any . prg) -> any
(code 'doWhen 2)
   ld E (E CDR)
   push (E CDR)  # Push body
   ld E (E)  # Get condition
   eval  # Eval condition
   cmp E Nil
   if eq  # NIL
      add S I  # Drop rest
      ret
   end
   ld (At) E
   xchg X (S)  # Run body
   prog X
   pop X
   ret

# (unless 'any . prg) -> any
(code 'doUnless 2)
   ld E (E CDR)
   push (E CDR)  # Push body
   ld E (E)  # Get condition
   eval  # Eval condition
   cmp E Nil
   if ne  # NIL
      ld (At) E
      add S I  # Drop rest
      ld E Nil  # Return NIL
      ret
   end
   xchg X (S)  # Run body
   prog X
   pop X
   ret

# (cond ('any1 . prg1) ('any2 . prg2) ..) -> any
(code 'doCond 2)
   push X
   ld X E  # Clauses in X
   do
      ld X (X CDR)  # Next clause
      atom X  # Any?
   while z  # Yes
      ld E ((X))  # Eval CAR
      eval
      cmp E Nil
      if ne  # Non-NIL
         ld (At) E
         ld X ((X) CDR)  # Run body
         prog X
         pop X
         ret
      end
   loop
   ld E Nil  # Return NIL
   pop X
   ret

# (nond ('any1 . prg1) ('any2 . prg2) ..) -> any
(code 'doNond 2)
   push X
   ld X E  # Clauses in X
   do
      ld X (X CDR)  # Next clause
      atom X  # Any?
   while z  # Yes
      ld E ((X))  # Eval CAR
      eval
      cmp E Nil
      if eq  # NIL
         ld X ((X) CDR)  # Run body
         prog X
         pop X
         ret
      end
      ld (At) E
   loop
   ld E Nil  # Return NIL
   pop X
   ret

# (case 'any (any1 . prg1) (any2 . prg2) ..) -> any
(code 'doCase 2)
   push X
   ld X (E CDR)  # Arguments in X
   ld E (X)  # Eval argument item
   eval
   ld (At) E
   do
      ld X (X CDR)  # Next clause
      atom X  # Any?
   while z  # Yes
      ld C ((X))  # Item(s) in C
      cmp C TSym  # Catch-all?
      jeq 10  # Yes
      ld A (At)  # Equal to argument item?
      ld E C
      call equalAE_F
      if eq  # Yes
10       ld X ((X) CDR)  # Run body
         prog X
         pop X
         ret
      end
      atom C  # List of items?
      if z  # Yes
         do
            ld A (At)  # Argument item member?
            ld E (C)
            call equalAE_F
            if eq  # Yes
               ld X ((X) CDR)  # Run body
               prog X
               pop X
               ret
            end
            ld C (C CDR)  # End of list?
            atom C
         until nz  # Yes
      end
   loop
   ld E Nil  # Return NIL
   pop X
   ret

# (casq 'any (any1 . prg1) (any2 . prg2) ..) -> any
(code 'doCasq 2)
   push X
   ld X (E CDR)  # Arguments in X
   ld E (X)  # Eval argument item
   eval
   ld (At) E
   do
      ld X (X CDR)  # Next clause
      atom X  # Any?
   while z  # Yes
      ld C ((X))  # Item(s) in C
      cmp C TSym  # Catch-all?
      jeq 10  # Yes
      cmp C E  # Equal to argument item?
      if eq  # Yes
10       ld X ((X) CDR)  # Run body
         prog X
         pop X
         ret
      end
      atom C  # List of items?
      if z  # Yes
         do
            cmp (C) E  # Argument item member?
            if eq  # Yes
               ld X ((X) CDR)  # Run body
               prog X
               pop X
               ret
            end
            ld C (C CDR)  # End of list?
            atom C
         until nz  # Yes
      end
   loop
   ld E Nil  # Return NIL
   pop X
   ret

# (state 'var (sym|lst exe [. prg]) ..) -> any
(code 'doState 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval 'var'
   eval
   link
   push E  # <L I> 'var'
   link
   call needVarEX  # Need variable
   do
      ld Y (Y CDR)  # Next clause
      atom Y  # Any?
   while z  # Yes
      ld X (Y)  # Get clause in X
      ld E (X)  # Get sym|lst in E
      cmp E TSym  # T?
      jeq 10  # Yes
      ld A ((L I))  # 'var's value
      cmp A E  #  Same?
      jeq 10  # Yes
      do  # 'memq'
         atom E  # List?
      while z  # Yes
         cmp A (E)  # Member?
      while ne  # No
         ld E (E CDR)
      loop
      if eq  # Yes
10       ld X (X CDR)  # Eval 'exe'
         ld E (X)
         eval
         cmp E Nil
         if ne  # Non-NIL
            ld ((L I)) E  # Set target state
            ld (At) E
            drop
            ld X (X CDR)  # Get body in X
            pop Y
            prog X  # Run body
            pop X
            ret
         end
      end
   loop
   drop
   pop Y
   pop X
   ret

# (while 'any . prg) -> any
(code 'doWhile 2)
   push X
   push Y
   ld X (E CDR)  # X arguments
   link
   push Nil  # <L I> Result
   link
   do
      ld E (X)  # Eval condition
      eval
      cmp E Nil
   while ne  # Non-NIL
      ld (At) E
      ld Y (X CDR)  # Run body
      prog Y
      ld (L I) E  # Save result
   loop
   ld E (L I)  # Get result
   drop
   pop Y
   pop X
   ret

# (until 'any . prg) -> any
(code 'doUntil 2)
   push X
   push Y
   ld X (E CDR)  # X arguments
   link
   push Nil  # <L I> Result
   link
   do
      ld E (X)  # Eval condition
      eval
      cmp E Nil
   while eq  # NIL
      ld Y (X CDR)  # Run body
      prog Y
      ld (L I) E  # Save result
   loop
   ld (At) E
   ld E (L I)  # Get result
   drop
   pop Y
   pop X
   ret

# (at '(cnt1 . cnt2|NIL) . prg) -> any
(code 'doAt 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   atom E  # Need pair
   jnz pairErrEX
   cmp (E CDR) Nil  # CDR?
   jeq 10  # No
   ld A (E)  # Get 'cnt1'
   cnt A  # Need short
   jz cntErrAX
   ld C (E CDR)  # Get 'cnt2'
   cnt C  # Need short
   jz cntErrCX
   add A (hex "10")  # Increment
   cmp A C  # Reached count?
   if lt  # No
      ld (E) A
10    ld E Nil
   else
      ld (E) ZERO
      ld Y (Y CDR)  # Run body
      prog Y
   end
   pop Y
   pop X
   ret

# (do 'flg|cnt ['any | (NIL 'any . prg) | (T 'any . prg) ..]) -> any
(code 'doDo 2)
   push X
   push Y
   push Z
   ld X (E CDR)  # Args
   ld E (X)  # Eval 'flg|cnt'
   ld X (X CDR)  # Body
   eval
   cmp E Nil  # Ever?
   if ne  # Yes
      cnt E  # Short number?
      if z
         call loopX  # No: Non-NIL 'flg'
      else
         shr E 4  # Normalize
         if nz
            jx 10  # Greater zero
            push E  # <S> Count
            do
               ld Y X  # Loop body
               call loopY_FE
            while nz
               dec (S)  # Decrement count
            until z
            add S I  # Drop count
         else
10          ld E Nil  # Return NIL if zero
         end
      end
   end
   pop Z
   pop Y
   pop X
   ret

# (loop ['any | (NIL 'any . prg) | (T 'any . prg) ..]) -> any
(code 'doLoop 2)
   push X
   push Y
   push Z
   ld X (E CDR)  # Body
   call loopX
   pop Z
   pop Y
   pop X
   ret

(code 'loopX 0)
   do
      ld Y X  # Body in Y
      do
         ld E (Y)  # Next expression
         atom E  # Pair?
         if z  # Yes
            ld A (E)  # Get CAR
            cmp A Nil  # NIL?
            if eq  # Yes
               ld Z (E CDR)  # Sub-body in Z
               ld E (Z)
               eval  # Evaluate condition
               cmp E Nil  # NIL?
               if eq  # Yes
                  ld Y (Z CDR)  # Run sub-body
                  prog Y
                  ret
               end
               ld (At) E
            else
               cmp A TSym  # T?
               if eq  # Yes
                  ld Z (E CDR)  # Sub-body in Z
                  ld E (Z)
                  eval  # Evaluate condition
                  cmp E Nil  # NIL?
                  if ne  # No
                     ld (At) E
                     ld Y (Z CDR)  # Run sub-body
                     prog Y
                     ret
                  end
               else
                  call evListE_E  # Else evaluate expression
               end
            end
         end
         ld Y (Y CDR)
         atom Y  # Finished one pass?
      until nz  # Yes
   loop

# (for sym 'cnt ['any | (NIL 'any . prg) | (T 'any . prg) ..]) -> any
# (for sym|(sym2 . sym) 'lst ['any | (NIL 'any . prg) | (T 'any . prg) ..]) -> any
# (for (sym|(sym2 . sym) 'any1 'any2 [. prg]) ['any | (NIL 'any . prg) | (T 'any . prg) ..]) -> any
(code 'doFor 2)
   push X
   push Y
   push Z
   ld X (E CDR)  # X on args
   ld Y (X)  # Y on first arg
   ld X (X CDR)
   push (EnvBind)  # Build bind frame
   link
   atom Y  # 'sym'?
   if nz  # Yes
      # (for sym 'cnt|lst ..)
      push (Y)  # Save old value
      push Y  # <L V> and 'sym'
      link
      ld (EnvBind) L  # Close bind frame
      push 0  # Init env swap
      ld E (X)  # Eval 'cnt|lst'
      eval
      link
      push E  # <L I> 'cnt|lst'
      link
      ld X (X CDR)  # X on body
      ld A E
      ld E Nil  # Preload NIL
      num A  # Number?
      if nz  # Yes
         test A SIGN  # Negative?
         if z  # No
            ld (Y) ZERO  # Init 'sym' to zero
            do
               ld A ((L V))  # Get value of 'sym'
               add A (hex "10")  # Increment
               cmp A (L I)  # Greater than 'num'?
            while le  # No
               ld ((L V)) A  # Set incremented value of 'sym'
               ld Y X  # Loop body
               call loopY_FE
            until z
         end
      else
         do
            ld A (L I)  # Get 'lst'
            atom A  # Any?
         while z  # Yes
            ld (L I) (A CDR)
            ld ((L V)) (A)  # Set value
            ld Y X  # Loop body
            call loopY_FE
         until z
      end
      drop
      add S I  # Drop env swap
      pop L  # Get link
   else
      ld Z (Y CDR)  # CDR of first arg
      atom Z  # 'sym'?
      if nz  # Yes
         # (for (sym2 . sym) 'lst ..)
         push (Z)  # Value of 'sym'
         push Z  # <L VII> 'sym'
         ld Z (Y)
         push (Z)  # Value of 'sym2'
         push Z  # <L V> 'sym2'
         link
         ld (EnvBind) L  # Close bind frame
         push 0  # Init env swap
         ld E (X)  # Eval 'lst'
         eval
         link
         push E  # <L I> 'lst'
         link
         ld (Z) ZERO  # Init 'sym2' to zero
         ld X (X CDR)  # X on body
         do
            ld A (L I)  # Get 'lst'
            atom A  # Any?
         while z  # Yes
            ld (L I) (A CDR)
            ld ((L VII)) (A)  # Set value of 'sym'
            add ((L V)) (hex "10")  # Increment 'sym2'
            ld Y X  # Loop body
            call loopY_FE
         until z
         drop
         add S I  # Drop env swap
         pop L  # Get link
         pop X  # Unbind 'sym2'
         pop (X)  # Restore value
      else
         ld Z (Y)  # CAR of first arg
         ld Y (Y CDR)
         atom Z  # 'sym'?
         if nz  # Yes
            # (for (sym ..) ..)
            push (Z)  # Save old value
            push Z  # <L V> and 'sym'
            link
            ld (EnvBind) L  # Close bind frame
            push 0  # Init env swap
            ld E (Y)  # Eval 'any1' init-expression
            eval
            ld (Z) E  # Set new value
            link
            push Nil  # <L I> Result
            link
            push (Y CDR)  # <S> (any2 . prg)
            do
               ld E ((S))  # Evaluate condition
               eval
               cmp E Nil  # NIL?
               if eq  # Yes
                  ld E (L I)  # Get result
                  break T
               end
               ld (At) E
               ld Y X  # Loop body
               call loopY_FE
            while nz
               ld (L I) E  # Keep result
               ld Y ((S) CDR)  # 'prg' re-init?
               atom Y
               if z  # Yes
                  prog Y
                  ld ((L V)) E  # Set new value
               end
            loop
            drop
            add S I  # Drop env swap
            pop L  # Get link
         else
            # (for ((sym2 . sym) ..) ..)
            ld C (Z CDR)  # 'sym'
            push (C)  # Save old value
            push C  # <L VII> and 'sym'
            ld C (Z)  # 'sym2'
            push (C)  # Value of 'sym2'
            push C  # <L V> and 'sym2'
            link
            ld (EnvBind) L  # Close bind frame
            push 0  # Init env swap
            ld E (Y)  # Eval 'any1' init-expression
            eval
            ld ((Z CDR)) E  # Set new value of 'sym'
            ld ((Z)) ZERO  # Init 'sym2' to zero
            link
            push Nil  # <L I> Result
            link
            push (Y CDR)  # <S> (any2 . prg)
            do
               add ((L V)) (hex "10")  # Increment 'sym2'
               ld E ((S))  # Evaluate condition
               eval
               cmp E Nil  # NIL?
               if eq  # Yes
                  ld E (L I)  # Get result
                  break T
               end
               ld (At) E
               ld Y X  # Loop body
               call loopY_FE
            while nz
               ld (L I) E  # Keep result
               ld Y ((S) CDR)  # 'prg' re-init?
               atom Y
               if z  # Yes
                  prog Y
                  ld ((L VII)) E  # Set new value
               end
            loop
            drop
            add S I  # Drop env swap
            pop L  # Get link
            pop X  # Unbind 'sym2'
            pop (X)  # Restore value
         end
      end
   end
   pop X  # Unbind 'sym'
   pop (X)  # Restore value
   pop L  # Restore link
   pop (EnvBind)  # Restore bind link
   pop Z
   pop Y
   pop X
   ret

(code 'loopY_FE 0)  # Z
   do
      ld E (Y)  # Next expression
      num E  # Number?
      if z  # No
         sym E  # Symbol?
         if nz  # Yes
            ld E (E)  # Get value
         else
            ld A (E)  # Else get CAR
            cmp A Nil  # NIL?
            if eq  # Yes
               ld Z (E CDR)  # Sub-body in Z
               ld E (Z)
               eval  # Evaluate condition
               cmp E Nil  # NIL?
               if eq  # Yes
                  ld Y (Z CDR)  # Run sub-body
                  prog Y
                  eq  # Return 'z'
                  ret
               end
               ld (At) E
               ld E Nil
            else
               cmp A TSym  # T?
               if eq  # Yes
                  ld Z (E CDR)  # Sub-body in Z
                  ld E (Z)
                  eval  # Evaluate condition
                  cmp E Nil  # NIL?
                  if ne  # No
                     ld (At) E
                     ld Y (Z CDR)  # Run sub-body
                     prog Y
                     eq  # Return 'z'
                     ret
                  end
               else
                  call evListE_E  # Else evaluate expression
               end
            end
         end
      end
      ld Y (Y CDR)
      atom Y  # Done?
   until nz  #  Yes
   ret  # Return 'nz'

# (catch 'any . prg) -> any
(code 'doCatch 2)
   catch
   push X
   push Y
   push Z
   push L
   ld X (E CDR)
   ld E (X)  # Eval tag
   eval
   sub S "EnvEnd-Env"  # Build catch frame
   save (Env) (EnvEnd) (S)  # Save environment
   push ZERO  # 'fin'
   push E  # 'tag'
   push (Catch)  # Link
   ld (Catch) S  # Close catch frame
   ld X (X CDR)  # Run body
   prog X
   pop (Catch)  # Restore catch link
   add S (pack II "+(EnvEnd-Env)")  # Clean up
   pop L
   pop Z
   pop Y
   pop X
   throw

# (throw 'sym 'any)
(code 'doThrow 2)
   ld X E
   ld Y (X CDR)
   ld E (Y)  # Get sym
   ld Y (Y CDR)
   eval  # Evaluate tag
   ld Z E  # into Z
   ld E (Y)  # Get value
   eval  # Keep thrown value in E
   ld C (Catch)  # Search catch frames
   do
      null C  # Any?
      jz throwErrZX  # No
      cmp (C I) TSym  # Catch-all?
   while ne  # No
      cmp Z (C I)  # Found tag?
   while ne  # No
      ld C (C)  # Next frame
   loop
   push E  # Save thrown value
   call unwindC_Z  # Unwind environments
   pop E
   ld S Z  # Restore stack
   pop (Catch)  # Restore catch link
   add S (pack II "+(EnvEnd-Env)")  # Clean up
   pop L
   pop Z
   pop Y
   pop X
   throw

(code 'throwErrZX)
   ld E Z
   ld Y ThrowErr
   jmp errEXYZ

# (finally exe . prg) -> any
(code 'doFinally 2)
   push X
   sub S "EnvEnd-Env"  # Build catch frame
   save (Env) (EnvEnd) (S)  # Save environment
   ld X (E CDR)
   push (X)  # 'exe' -> 'fin'
   ld X (X CDR)
   push 0  # 'tag'
   push (Catch)  # Link
   ld (Catch) S  # Close catch frame
   prog X  # Run body
   link
   push E  # <L I> Result
   link
   ld E (S V)  # Get 'fin'
   eval  # Evaluate it
   ld E (L I)  # Get result
   drop
   pop (Catch)  # Restore catch link
   add S (pack II "+(EnvEnd-Env)")  # Clean up
   pop X
   ret

# (co 'sym [. prg]) -> any
(code 'doCo 2)
   catch
   push X
   ld X E
   ld E ((E CDR))  # Eval 'sym' tag
   eval
   atom ((X CDR) CDR)  # 'prg'?
   if z  # Yes
      push Y
      push Z
      push L
      sub S "EnvMid-EnvCo"  # Space for env
      ld Y (Stack1)  # Search through stack segments
      ld C (Stacks)  # Segment count
      do
         null C  # Any?
      while nz  # Yes
         null (Y -I)  # In use?
         if nz  # Yes
            cmp E (Y -I)  # Found tag?
            if eq  # Yes
               null (Y -II)  # Already active?
               jz reentErrEX  # Yes
               push Y  # Resume coroutine: Save 'seg'
               push (StkLimit)  # and 'lim'
               push (EnvCo7)  # Link
               ld (EnvCo7) S  # Close coroutine frame
               ld Z S  # Point Z to main frame
               save (EnvCo) (EnvMid) (Z III)  # Save environment
               ld E Nil  # Final 'yield's return value
: resumeCoroutine
               ld S (Y -II)  # Restore stack pointer
               ld (Y -II) 0  # Mark as active
               lea A (Y 4096)  # Set stack limit
               sub A (StkSize)
               ld (StkLimit) A
               load (EnvCo) (EnvMid) (Y (pack -II "-(EnvMid-EnvCo)"))  # Restore environment
               ld X (EnvBind)  # Reversed bindings
               ld C (Z (pack III "+(EnvBind-EnvCo)"))  # Main bindings
               do
                  null X  # More reversed bindings?
               while nz  # Yes
                  ld Y (X)  # Link address in Y
                  null (X -I)  # Env swap zero?
                  if z  # Yes
                     lea A (Y -II)  # End of bindings in A
                     do
                        xchg ((A)) (A I)  # Exchange symbol value with saved value
                        sub A II
                        cmp A X  # More?
                     until lt  # No
                  end
                  ld A (Y I)  # Get down link
                  ld (Y I) C  # Undo reversal
                  ld C X
                  ld X A
               loop
               ld (EnvBind) C  # Set local bindings
               ld X Catch  # Pointer to catch frames
               do
                  null (X)  # More locals?
               while nz  # Yes
                  ld X (X)  # Next frame pointer
               loop
               ld (X) (Z (pack III "+(Catch-EnvCo)"))  # Join
               ld X EnvInFrames  # Pointer to input frames
               null (X)  # Any locals?
               if z  # No
                  ld (Chr) (Z (pack III "+(Chr-EnvCo)"))  # Adapt In
                  ld (Get_A) (Z (pack III "+(Get_A-EnvCo)"))
                  ld (InFile) (Z (pack III "+(InFile-EnvCo)"))
               else
                  do
                     ld X (X)  # Next frame pointer
                     null (X)  # More locals?
                  until z  # No
               end
               ld (X) (Z (pack III "+(EnvInFrames-EnvCo)"))  # Join
               ld X EnvOutFrames  # Pointer to output frames
               null (X)  # Any locals?
               if z  # No
                  ld (PutB) (Z (pack III "+(PutB-EnvCo)"))  # Adapt Out
                  ld (OutFile) (Z (pack III "+(OutFile-EnvCo)"))
               else
                  do
                     ld X (X)  # Next frame pointer
                     null (X)  # More locals?
                  until z  # No
               end
               ld (X) (Z (pack III "+(EnvOutFrames-EnvCo)"))  # Join
               ld X EnvApply  # Local apply stack
               do
                  null (X)  # Any?
               while nz  # Yes
                  ld X ((X))  # Follow link
               loop
               ld (X) (Z (pack III "+(EnvApply-EnvCo)"))  # Join
               pop X  # Get saved L
               null X  # Any?
               if nz  # Yes
                  ld Y (X)  # Pointer to link
                  do
                     ld A (Y)  # Get link
                     null A  # Found end?
                  while nz  # No
                     ld Y (A)  # Next frame
                  loop
                  ld (Y) (Z (pack III "+(EnvMid-EnvCo)"))  # Link to main stack
                  ld L X
               end
               pop Z
               pop Y
               pop X
               throw
            end
            dec C  # Decrement count
         end
         sub Y (StkSize)  # Next segment
      loop
      ld Y (Stack1)  # Find unused stack segment
      ld C (Stacks)  # Segment count
      null C  # Starting first coroutine?
      if z  # Yes
         lea A (Y 4096)  # Set stack limit
         cmp S A  # Check it
         jlt stkErr
         ld (StkLimit) A
      else
         do
            null (Y -I)  # Found free segment?
         while nz  # No
            sub Y (StkSize)  # Next segment
            dec C  # Any?
         until z  # Yes
      end
      inc (Stacks)  # Increment segment count
      push Y  # Save 'seg'
      push (StkLimit)  # and 'lim'
      push (EnvCo7)  # Link
      ld (EnvCo7) S  # Close coroutine frame
      save (EnvCo) (EnvMid) (S III)  # Save environment
      ld (EnvMake) 0  # Init local 'make' env
      ld (EnvYoke) 0
      lea A (Y 4096)  # Calculate stack limit
      sub A (StkSize)
      ld (StkLimit) A
      ld S Y  # Set stack pointer
      push E  # Save 'tag'
      push 0  # Mark 'stk' as active
      sub S "EnvMid-EnvCo"  # Space for 'env'
      ld X ((X CDR) CDR)
      link
      push X  # Save 'prg'
      link
      prog X  # Run 'prg'
      ld S (EnvCo7)  # Not yielded: Restore stack pointer
      load (Env) (EnvMid) (S (pack III "+(Env-EnvCo)"))  # Restore environment
      pop (EnvCo7)  # Restore coroutine link
      pop (StkLimit)  # 'lim'
      ld (Y -I) 0  # Mark segment as unused
      dec (Stacks)  # Last coroutine?
      if z  # Yes
         ld (StkLimit) 0  # Clear stack limit
      end
      add S (pack I "+(EnvMid-EnvCo)")  # Clean up
      pop L
      pop Z
      pop Y
      pop X
      throw
   end
   ld X (Stack1)  # Search through stack segments
   ld C (Stacks)  # Segment count
   do
      null C  # Any?
   while nz  # Yes
      null (X -I)  # In use?
      if nz  # Yes
         cmp E (X -I)  # Found tag?
         if eq  # Yes
            null (X -II)  # Active?
            ldz E Nil
            if nz  # No
               ld C (X (pack -II "-(EnvMid-EnvInFrames)"))  # Open input frames
               call closeCoFilesC
               ld C (X (pack -II "-(EnvMid-EnvOutFrames)"))  # Open output frames
               call closeCoFilesC
               ld (X -I) 0  # Mark segment as unused
               dec (Stacks)  # Last coroutine?
               if z  # Yes
                  ld (StkLimit) 0  # Clear stack limit
               end
               ld E TSym  # Return T
            end
            pop X
            throw
         end
         dec C  # Decrement count
      end
      sub X (StkSize)  # Next segment
   loop
   ld E Nil  # Return NIL
   pop X
   throw

# (yield 'any ['sym]) -> any
(code 'doYield 2)
   catch
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)
   ld E (Y)  # Eval 'any'
   eval
   link
   push E  # <L I> Result
   link
   ld Y (Y CDR)  # Next arg
   ld E (Y)
   eval  # Eval optional 'sym'
   ld Y 0  # Preload "no target"
   cmp E Nil  # Any?
   if ne  # Yes
      ld Y (Stack1)  # Search for target coroutine
      ld C (Stacks)  # Segment count
      do
         null C  # Any?
         jz yieldErrEX  # No
         null (Y -I)  # In use?
         if nz  # Yes
            cmp E (Y -I)  # Found tag?
            break eq  # Yes
            dec C  # Decrement count
         end
         sub Y (StkSize)  # Next segment
      loop
      null (Y -II)  # Already active?
      jz reentErrEX  # Yes
   end
   ld E (L I)  # Get result
   drop
   ld Z (EnvCo7)  # Get main
   null Z  # Any?
   if z  # No
      null Y  # Target coroutine?
      jz yieldErrX  # No
      push L  # Else resume with argument
      sub S "EnvMid-EnvCo"  # Space for env
      push Y  # Save 'seg'
      push (StkLimit)  # and 'lim'
      push Z  # Link (NULL)
      ld (EnvCo7) S  # Close coroutine frame
      ld Z S  # Point Z to main frame
      save (EnvCo) (EnvMid) (Z III)  # Save environment
      jmp resumeCoroutine  # Resume
   end
   null L  # Stack?
   if nz  # Yes
      ld C (Z (pack III "+(EnvMid-EnvCo)"))  # Main routine's link
      cmp L C  # Local stack?
      ldz L 0
      if ne  # Yes
         ld X (L)  # Pointer to link
         do
            ld A (X)  # Get link
            null A  # Any?
            jz 10  # No
            cmp A C  # Reached main routine's link?
         while ne  # No
            ld X (A)  # Follow link
         loop
         ld (X) 0  # Clear link
      end
   end
10 push L  # End of segment
   push Y  # Save taget coroutine
   ld X EnvApply  # Pointer to apply stack
   do
      ld A (X)
      cmp A (Z (pack III "+(EnvApply-EnvCo)"))  # Local apply stack?
   while ne  # Yes
      lea X ((A) I)  # Get link
   loop
   ld (X) 0  # Cut off
   ld X EnvOutFrames  # Pointer to output frames
   do
      cmp (X) (Z (pack III "+(EnvOutFrames-EnvCo)"))  # More locals?
   while ne  # Yes
      ld X (X)  # Next frame pointer
   loop
   ld (X) 0  # Cut off
   ld X EnvInFrames  # Pointer to input frames
   do
      cmp (X) (Z (pack III "+(EnvInFrames-EnvCo)"))  # More locals?
   while ne  # Yes
      ld X (X)  # Next frame pointer
   loop
   ld (X) 0  # Cut off
   ld X Catch  # Pointer to catch frames
   do
      cmp (X) (Z (pack III "+(Catch-EnvCo)"))  # More locals?
   while ne  # Yes
      ld X (X)  # Next frame pointer
   loop
   ld (X) 0  # Cut off
   ld C 0  # Back link
   ld X (EnvBind)  # Reverse bindings
   null X  # Any?
   if nz  # Yes
      do
         cmp X (Z (pack III "+(EnvBind-EnvCo)"))  # Reached main routine's bindings?
      while ne  # No
         ld Y X  # Keep bind frame in Y
         null (X -I)  # Env swap zero?
         if z  # Yes
            add X I  # X on bindings
            do
               xchg ((X)) (X I)  # Exchange symbol value with saved value
               add X II
               cmp X (Y)  # More?
            until eq  # No
         end
         ld A (Y)  # A on bind link
         ld X (A I)  # X on next frame
         ld (A I) C  # Set back link
         ld C Y
      loop
   end
   ld (EnvBind) C  # Store back link in coroutine's env
   pop Y  # Restore taget coroutine
   ld X (Z II)  # Get 'seg'
   ld (X -II) S  # Save stack pointer
   save (EnvCo) (EnvMid) (X (pack -II "-(EnvMid-EnvCo)"))  # Save environment
   null Y  # Target coroutine?
   if z  # No
      null (EnvInFrames)  # Adapt In?
      if nz  # Yes
         ld (Chr) (Z (pack III "+(Chr-EnvCo)"))
         ld (Get_A) (Z (pack III "+(Get_A-EnvCo)"))
         ld (InFile) (Z (pack III "+(InFile-EnvCo)"))
      end
      null (EnvOutFrames)  # Adapt Out?
      if nz  # Yes
         ld (PutB) (Z (pack III "+(PutB-EnvCo)"))
         ld (OutFile) (Z (pack III "+(OutFile-EnvCo)"))
      end
      ld S Z  # Set stack pointer
      load (Env) (EnvMid) (Z (pack III "+(Env-EnvCo)"))  # Restore environment
      pop (EnvCo7)  # Restore coroutine link
      pop (StkLimit)  # 'lim'
      add S (pack I "+(EnvMid-EnvCo)")  # Clean up
      pop L
      pop Z
      pop Y
      pop X
      throw
   end
   ld (Z II) Y  # Set new 'seg'
   jmp resumeCoroutine  # Resume

(code 'closeCoFilesC 0)
   do
      null C
   while nz
      null (C II)  # 'pid'?
      if nz  # Yes
         cc close((C I))  # Close 'fd'
         call waitFileC  # Wait for pipe process if necessary
      end
      ld C (C)
   loop
   ret

# (! . exe) -> any
(code 'doBreak 2)
   ld E (E CDR)  # exe
   cmp (Dbg) Nil  # Debug?
   if ne  # Yes
      call brkLoadE_E  # Enter debug breakpoint
   end
   eval/ret

(code 'brkLoadE_E)
   null (Break)  # Already in breakpoint?
   if z  # No
      cc isatty(0)  # STDIN
      nul4  # on a tty?
      if nz  # Yes
         cc isatty(1)  # STDOUT
         nul4  # on a tty?
         if nz  # Yes
            push X
            push Y
            push (EnvBind)  # Build bind frame
            link
            push (Up)  # <L VI> Bind '^'
            push Up
            ld (Up) E  # to expression
            push (Run)  # <L IV> Bind '*Run' to NIL
            push Run
            ld (Run) Nil
            push (At)  # <L II> Save '@'
            push At
            link
            ld (EnvBind) L  # Close bind frame
            ld (Break) L  # Set break env
            push 0  # Init env swap
            sub S IV  # <L -V> OutFrame
            ld Y S
            ld (Y I) 1  # fd = stdout
            ld (Y II) 0  # pid = 0
            call pushOutFilesY
            call printE  # Print expression
            call newline
            ld B (char "!")  # Prompt
            ld E Nil  # REPL
            ld X 0  # Runtime expression
            call loadBEX_E
            call popOutFiles
            add S (+ IV III)  # Drop outFrame, env swap, bind link and '@'
            pop (At)  # Restore '@'
            pop A
            pop (Run)  # '*Run'
            pop A
            ld E (Up)  # runtime expression
            pop (Up)  # and '^'
            pop L  # Restore link
            pop (EnvBind)  # Restore bind link
            ld (Break) 0  # Leave breakpoint
            pop Y
            pop X
         end
      end
   end
   ret

# (e . prg) -> any
(code 'doE 2)
   push X
   push Y
   ld X E
   null (Break)  # Breakpoint?
   jz brkErrX  # No
   link
   push (Dbg)  # Save '*Dbg'
   push (At)  # '@'
   push (Run)  # and '*Run'
   link
   ld (Dbg) Nil  # Switch off debug mode
   ld C (Break)  # Get break env
   ld (At) (C II)  # Set '@'
   ld (Run) (C IV)  # and '*Run'
   call popOutFiles  # Leave debug I/O env
   ld Y (EnvInFrames)  # Keep InFrames
   call popInFiles
   ld X (X CDR)  # 'prg'?
   atom X
   if z  # Yes
      prog X
   else
      ld E (Up)  # Get '^'
      eval
   end
   call pushInFilesY  # Restore debug I/O env
   lea Y ((Break) -V)
   call pushOutFilesY
   pop L  # Restore debug env
   pop (Run)
   pop (At)
   pop (Dbg)
   pop L
   pop Y
   pop X
   ret

# ($ sym|lst lst . prg) -> any
(code 'doTrace 2)
   push X
   ld X (E CDR)  # Get args
   cmp (Dbg) Nil  # Debug?
   if eq  # No
      ld X ((X CDR) CDR)  # Get 'prg'
      prog X  # Run it
   else
      push Y
      push Z
      push (OutFile)  # Save output channel
      ld (OutFile) ((OutFiles) II)  # Set to OutFiles[2] (stderr)
      push (PutB)  # Save 'put'
      ld (PutB) putStdoutB  # Set new
      ld Y (X)  # Get 'sym|lst'
      ld X (X CDR)
      ld Z (X CDR)  # Get 'prg'
      inc (EnvTrace)  # Increment trace level
      ld C (EnvTrace)  # Get it
      call traceCY  # Print trace information
      ld C Trc1  # Print " :"
      call outStringC
      ld X (X)  # Get 'lst'
      do
         atom X  # List?
      while z  # Yes
         call space
         ld E (X)  # Print value of CAR
         ld E (E)
         call printE
         ld X (X CDR)
      loop
      cmp X Nil  # Last CDR is NIL?
      if ne  # No
         cmp X At  # Variable arguments?
         if ne  # No
            call space
            ld E (X)  # Print value
            call printE
         else
            ld X (EnvNext)  # VarArgs
            do
               cmp X (EnvArgs)  # Any?
            while ne  # Yes
               call space
               sub X I  # Next
               ld E (X)  # Next arg
               call printE
            loop
         end
      end
      call newline
      ld (PutB) (S)  # Restore 'put'
      ld (OutFile) (S I)  # and output channel
      prog Z  # Run 'prg'
      ld (OutFile) ((OutFiles) II)  # Set output channel again
      ld (PutB) putStdoutB
      ld C (EnvTrace)  # Get trace level
      dec (EnvTrace)  # Decrement it
      call traceCY  # Print trace information
      ld C Trc2  # Print " = "
      call outStringC
      call printE_E  # Print result
      call newline
      pop (PutB)  # Restore 'put'
      pop (OutFile)  # and output channel
      pop Z
      pop Y
   end
   pop X
   ret

(code 'traceCY)
   cmp C 64  # Limit to 64
   if gt
      ld C 64
   end
   do
      call space  # Output spaces
      dec C  # 'cnt' times
   until sz
   push E
   atom Y  # 'sym'?
   if nz  # Yes
      ld E Y  # Print symbol
      call printE
   else
      ld E (Y)  # Print method
      call printE
      call space
      ld E (Y CDR)  # Print class
      call printE
      call space
      ld E (This)  # Print 'This'
      call printE
   end
   pop E
   ret

(code 'execArgsE_SXZ)  # Y
   tos Y  # Get return entry
   ld X (E CDR)  # X on args
   push 0  # End-of-buffers marker
   call evSymX_E  # Pathname
   call pathStringE_SZ  # Write to stack buffer
   do
      ld X (X CDR)  # Arguments?
      atom X
   while z  # Yes
      push Z  # Buffer chain
      call evSymX_E  # Next argument
      call bufStringE_SZ  # Write to stack buffer
   loop
   push Z
   ld Z S  # Point to chain
   ld X Z
   push 0  # NULL terminator
   do
      lea A (X I)  # Buffer pointer
      push A  # Push to vector
      ld X (X)  # Follow chain
      null (X)  # Done?
   until z  # Yes
   call flushAll  # Flush all output channels
   jmp (Y)  # Return

# (exec 'any ..)
(code 'doExec 2)
   call execArgsE_SXZ  # Prepare arguments
   cc execvp((S) S)  # Execute program
   jmp execErrS  # Error if failed

# (call 'any ..) -> flg
(code 'doCall 2)
   push X
   push Y
   push Z
   push E  # Save expression
   call execArgsE_SXZ  # Prepare arguments
   ld X (X I)  # Retrieve expression
   cc fork()  # Fork child process
   nul4  # In child?
   if z  # Yes
      cc setpgid(0 0)  # Set process group
      cc execvp((S) S)  # Execute program
      jmp execErrS  # Error if failed
   end
   js forkErrX
   do
      ld S Z  # Clean up buffers
      pop Z  # Chain
      null Z  # End?
   until z  # Yes
   ld Z A  # Keep pid in Z
   cc setpgid(Z 0)  # Set process group
   null (Termio)  # Raw mode?
   if nz  # Yes
      cc tcsetpgrp(0 Z)  # Set terminal process group
   end
   do  # Re-use expression stack entry
      do
         cc waitpid(Z S WUNTRACED)  # Wait for child
         nul4  # OK?
      while s  # No
         call errno_A
         cmp A EINTR  # Interrupted?
         jne waitPidErrX  # No
         null (Signal)  # Signal?
         if nz  # Yes
            call sighandlerX
         end
      loop
      null (Termio)  # Raw mode?
      if nz  # Yes
         cc getpgrp()  # Set terminal process group
         cc tcsetpgrp(0 A)
      end
      call wifstoppedS_F  # WIFSTOPPED(S)?
      if ne  # No
         ld4 (S)  # Result?
         null A
         ld E TSym  # Return 'flg'
         ldnz E Nil
         shl A 4  # Make short number
         or A CNT
         ld (At2) A  # Exit status in '@@'
         add S I  # Drop expression
         pop Z
         pop Y
         pop X
         ret
      end
      ld B (char "+")  # Prompt
      ld E Nil  # REPL
      call loadBEX_E
      null (Termio)  # Raw mode?
      if nz  # Yes
         cc tcsetpgrp(0 Z)  # Set terminal process group
      end
      cc kill(Z SIGCONT)
   loop

# (tick (cnt1 . cnt2) . prg) -> any
(code 'doTick 2)
   push X
   push (TickU)  # <S III> User ticks
   push (TickS)  # <S II> System ticks
   cc times(Tms)  # Get ticks
   push (Tms TMS_UTIME)  # <S I> User time
   push (Tms TMS_STIME)  # <S> User time
   ld E (E CDR)
   push (E)  # Save pointer to count pair
   ld X (E CDR)
   prog X  # Run 'prg'
   pop X  # Get count pair
   cc times(Tms)  # Get ticks again
   ld A (Tms TMS_UTIME)  # User time
   sub A (S I)  # Subtract previous user time
   sub A (TickU)  # Subtract user ticks
   add A (S III)  # Adjust by saved ticks
   add (TickU) A  # Save new user ticks
   shl A 4  # Adjust to short number
   add (X) A  # Add to 'cnt1'
   ld A (Tms TMS_STIME)  # System time
   sub A (S)  # Subtract previous system time
   sub A (TickS)  # Subtract system ticks
   add A (S II)  # Adjust by saved ticks
   add (TickS) A  # Save new system ticks
   shl A 4  # Adjust to short number
   add (X CDR) A  # Add to 'cnt2'
   add S IV  # Drop locals
   pop X
   ret

# (ipid) -> pid | NIL
(code 'doIpid 2)
   ld C (EnvInFrames)  # OutFrames?
   null C
   if nz
      ld E (C II)  # 'pid'
      cmp E 1  # 'pid' > 1?
      if gt  # Yes
         shl E 4  # Make short number
         or E CNT
         ret
      end
   end
   ld E Nil  # Return NIL
   ret

# (opid) -> pid | NIL
(code 'doOpid 2)
   ld C (EnvOutFrames)  # OutFrames?
   null C
   if nz
      ld E (C II)  # 'pid'
      cmp E 1  # 'pid' > 1?
      if gt  # Yes
         shl E 4  # Make short number
         or E CNT
         ret
      end
   end
   ld E Nil  # Return NIL
   ret

# (kill 'pid ['cnt]) -> flg
(code 'doKill 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   call evCntXY_FE  # Eval 'pid'
   ld Y (Y CDR)  # Second arg?
   atom Y
   if nz  # No
      cc kill(E SIGTERM)  # Send TERM signal
   else
      push E  # Save signal number
      call evCntXY_FE  # Eval 'cnt'
      cc kill(pop E)  # Send signal
   end
   nul4  # OK?
   ld E TSym  # Yes
   ldnz E Nil  # No
   pop Y
   pop X
   ret

# (fork) -> pid | NIL
(code 'doFork 2)
   push X
   ld X E  # Get expression
   call forkLispX_FE  # Fork child process
   if lt
      ld E Nil  # In child
   else
      shl E 4  # In parent
      or E CNT  # Return PID
   end
   pop X
   ret

# (detach) -> pid | NIL
(code 'doDetach 2)
   ld E (PPid)  # Get parent process ID
   cmp E Nil  # Any?
   if ne  # Yes
      ld (PPid) Nil  # Clear parent process ID
      cc close((Tell))  # Close 'Tell'
      ld (Tell) 0
      cc close((Hear))  # Close 'Hear'
      ld A (Hear)
      call closeInFileA
      ld A (Hear)
      call closeOutFileA
      ld (Hear) 0
      cc close((Mic))  # Close 'Mic'
      ld (Mic) 0
      ld (Slot) 0  # Clear 'Slot'
      cc setsid()  # New session
   end
   ret

(code 'forkLispX_FE 0)
   call flushAll  # Flush all output channels
   null (Spkr)  # Not listening for children yet?
   if z  # Yes
      cc pipe(SpMiPipe)  # Open speaker/microphone pipe
      nul4  # OK?
      jnz pipeErrX
      ld4 (SpMiPipe)  # Read end
      ld (Spkr) A  # into the speaker
      call closeOnExecAX
      ld4 (SpMiPipe 4)  # Write end
      call closeOnExecAX
   end
   sub S II  # Create 'hear' and 'tell' pipes
   cc pipe(S)  # Open 'hear' pipe
   nul4  # OK?
   jnz pipeErrX
   cc pipe(&(S 8))  # Open 'tell' pipe
   nul4  # OK?
   jnz pipeErrX
   ld4 (S)  # Read end of 'hear'
   call closeOnExecAX
   ld4 (S 4)  # Write end
   call closeOnExecAX
   ld4 (S 8)  # Read end of 'tell'
   call closeOnExecAX
   ld4 (S 12)  # Write end
   call closeOnExecAX
   ld C 0  # Index
   ld A (Child)  # Find a free child slot
   do
      cmp C (Children)  # Tried all children?
   while ne  # No
      null (A)  # Found empty 'pid'?
   while nz  # No
      add A VI  # Increment by sizeof(child)
      add C VI
   loop
   cc fork()  # Fork child process
   nul4  # In child?
   js forkErrX
   if z  # Yes
      ld (Slot) C  # Set child index
      ld (Spkr) 0  # No children yet
      ld4 (SpMiPipe 4)  # Set microphone to write end
      ld (Mic) A
      ld4 (S 4)  # Close write end of 'hear'
      call closeAX
      ld4 (S 8)  # Close read end of 'tell'
      call closeAX
      ld4 (SpMiPipe)  # Close read end
      call closeAX
      ld A (Hear)  # Already hearing?
      null A
      if nz  # Yes
         call closeAX  # Close it
         ld A (Hear)
         call closeInFileA
         ld A (Hear)
         call closeOutFileA
      end
      ld4 (S)  # Read end of 'hear'
      ld (Hear) A
      call initInFileA_A  # Create input file
      ld A (Tell)  # Telling?
      null A
      if nz  # Yes
         call closeAX
      end
      ld4 (S 12)  # Write end of 'tell'
      ld (Tell) A
      ld E (Child)  # Iterate children
      ld C (Children)  # Count
      do
         sub C VI  # More?
      while ge  # Yes
         null (E)  # 'pid'?
         if nz  # Yes
            cc close((E I))  # Close 'hear'
            cc close((E II))  # Close 'tell'
            cc free((E V))  # Free buffer
         end
         add E VI  # Increment by sizeof(child)
      loop
      ld (Children) 0  # No children
      cc free((Child))
      ld (Child) 0
      ld A (EnvInFrames)  # Clear pids in InFrames
      do
         null A  # More frames?
      while nz  # Yes
         ld (A II) 0  # Clear 'pid'
         ld A (A)  # Follow link
      loop
      ld A (EnvOutFrames)  # Clear pids in OutFrames
      do
         null A  # More frames?
      while nz  # Yes
         ld (A II) 0  # Clear 'pid'
         ld A (A)  # Follow link
      loop
      ld A (Catch)  # Clear 'finally' expressions in Catch frames
      do
         null A  # More frames?
      while nz  # Yes
         ld (A II) ZERO  # Clear 'fin'
         ld A (A)  # Follow link
      loop
      cc free((Termio))  # Give up terminal control
      ld (Termio) 0
      set (PRepl) (Repl)  # Set parent REPL flag
      ld (PPid) (Pid)  # Set parent process ID
      cc getpid()  # Get new process ID
      shl A 4  # Make short number
      or A CNT
      ld (Pid) A  # Set new process ID
      ld E (Fork)  # Run '*Fork'
      call execE
      ld (Fork) Nil  # Clear '*Fork'
      add S II  # Drop 'hear' and 'tell' pipes
      lt  # Return "in child"
      ret
   end
   cmp C (Children)  # Children table full?
   ldnz E A  # No: Get 'pid' into E
   if eq  # Yes
      push A  # Save child's 'pid'
      ld A (Child)  # Get vector
      ld E C  # Children
      add E (* 8 VI)  # Eight more slots
      ld (Children) E
      call allocAE_A  # Extend vector
      ld (Child) A
      add A E  # Point A to the end
      ld E 8  # Init eight new slots
      do
         sub A VI  # Decrement pointer
         ld (A) 0  # Clear 'pid'
         dec E  # Done?
      until z  # Yes
      pop E  # Get 'pid'
   end
   add C (Child)  # Point C to free 'child' entry
   ld (C) E  # Set 'pid'
   ld4 (S)  # Close read end of 'hear'
   call closeAX
   ld4 (S 4)  # Write end of 'hear'
   ld (C II) A  # Into 'tell'
   call nonblockingA_A  # Set to non-blocking
   ld4 (S 8)  # Read end of 'tell'
   ld (C I) A  # Into 'hear'
   ld4 (S 12)  # Close write end of 'tell'
   call closeAX
   ld (C III) 0  # Init buffer offset
   ld (C IV) 0  # buffer count
   ld (C V) 0  # No buffer yet
   add S II  # Drop 'hear' and 'tell' pipes
   eq  # Return "in parent"
   ret

# (bye ['cnt])
(code 'doBye 2)
   ld X E
   ld E ((E CDR))  # Eval exit code
   eval
   cmp E Nil
   if eq
      ld E 0  # Zero if NIL
   else
      call xCntEX_FE
   end
# Exit
(code 'byeE)
   nul (InBye)  # Re-entered?
   if z  # No
      set (InBye) 1
      push E  # Save exit code
      ld C 0  # Top frame
      call unwindC_Z  # Unwind
      ld E (Bye)  # Run exit expression(s)
      call execE
      pop E  # Restore exit code
   end
   call flushAll  # Flush all output channels
(code 'finishE)
   call setCooked  # Set terminal to cooked mode
   stop  # Exit

# vi:et:ts=3:sw=3
