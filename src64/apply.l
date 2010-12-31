# 12oct10abu
# (c) Software Lab. Alexander Burger

(code 'applyXYZ_E 0)
   ld C (Y)  # Get 'foo'
   do
      cnt C  # Short number?
      if nz  # Yes
         push (EnvApply)  # Build apply frame
         link
         sym S  # Align stack to cell boundary
         if nz
            push ZERO
         end
         push Nil  # Init CDR
         push C  # 'fun'
         ld E S  # 'exe in E
         do
            cmp Y Z  # Any args?
         while ne  # Yes
            sub Y I
            push (Y)  # Next arg
            push ZERO  # Dummy symbol's tail
            push Nil  # Init CDR
            lea A (S II)  # Value address
            push A  # CAR
            ld (S V) S  # Store CDR of previous cell
            cmp S (StkLimit)  # Stack check
            jlt stkErrX
         loop
         link
         ld (EnvApply) L  # Close apply frame
         call (C)  # Eval SUBR
         drop
         pop (EnvApply)
         ret
      end
      big C  # Undefined if bignum
      jnz undefinedCX
      cmp S (StkLimit)  # Stack check
      jlt stkErrX
      atom C  # Cell?
      if z  # Yes
         # Apply EXPR
         push X
         ld X (C)  # Parameter list in X
         push (EnvBind)  # Build bind frame
         link
         push (At)  # Bind At
         push At
         do
            atom X  # More parameters?
         while z  # Yes
            ld E (X)  # Get symbol
            ld X (X CDR)
            push (E)  # Save old value
            push E  # Save symbol
            cmp Y Z  # More args?
            if ne  # Yes
               sub Y I
               ld (E) (Y)  # Set new value to next arg
            else
               ld (E) Nil  # New value NIL
            end
         loop
         cmp X Nil  # NIL-terminated parameter list?
         if eq  # Yes
            link
            ld (EnvBind) L  # Close bind frame
            push 0  # Init env swap
            ld Z (C CDR)  # Body in Z
            prog Z  # Run body
            pop A  # Drop env swap
            pop L  # Get link
            do  # Unbind symbols
               pop X  # Next symbol
               pop (X)  # Restore value
               cmp S L  # More?
            until eq  # No
            pop L  # Restore link
            pop (EnvBind)  # Restore bind link
            pop X
            ret
         end
         # Non-NIL parameter
         cmp X At  # '@'?
         if ne  # No
            push (X)  # Save last parameter's old value
            push X  # and the last parameter
            ld (X) Nil  # Set new value to NIL
            link
            ld (EnvBind) L  # Close bind frame
            push 0  # Init env swap
            ld Z (C CDR)  # Body in Z
            prog Z  # Run body
            pop A  # Drop env swap
            pop L  # Get link
            do  # Unbind symbols
               pop X  # Next symbol
               pop (X)  # Restore value
               cmp S L  # More?
            until eq  # No
            pop L  # Restore link
            pop (EnvBind)  # Restore bind link
            pop X
            ret
         end
         # Evaluated argument list
         link
         ld (EnvBind) L  # Close bind frame
         push 0  # Init env swap
         push (EnvNext)   # Save current 'next'
         push (EnvArgs)  # and varArgs base
         cmp Y Z  # Any args?
         if eq  # No
            ld (EnvArgs) 0
            ld (EnvNext) 0
         else
            link  # Build varArgs frame
            do
               sub Y I
               push (Y)  # Push next argument
               cmp S (StkLimit)  # Stack check
               jlt stkErrX
               cmp Y Z   # More args?
            until eq  # No
            ld (EnvArgs) S  # Set new varArgs base
            ld (EnvNext) L  # Set new 'next'
            link  # Close varArgs frame
         end
         ld Z (C CDR)  # Body in Z
         prog Z  # Run body
         null (EnvNext)  # VarArgs?
         if nz  # Yes
            drop  # Drop varArgs
         end
         pop (EnvArgs)  # Restore varArgs base
         pop (EnvNext)   # and 'next'
         pop A  # Drop env swap
         pop L  # Get link
         do  # Unbind symbols
            pop X  # Next symbol
            pop (X)  # Restore value
            cmp S L  # More?
         until eq  # No
         pop L  # Restore link
         pop (EnvBind)  # Restore bind link
         pop X
         ret
      end
      ld A (C)  # Else symbolic, get value
      cmp A doMeth  # Method?
      if eq  # Yes
         sub Y I  # First arg
         ld E (Y)  # Get object
         num E  # Need symbol
         jnz symErrEX
         sym E
         jz symErrEX
         sym (E TAIL)  # External symbol?
         if nz  # Yes
            call dbFetchEX  # Fetch it
         end
         push X
         push Z  # Save arg pointers
         push Y
         ld Y C  # 'msg'
         ld Z 0  # No classes
         call methodEY_FCYZ  # Found?
         jne msgErrYX  # No
         ld (S I) (EnvCls)  # 'cls'
         ld (S) (EnvKey)  # 'key'
         ld (EnvCls) Z  # Set new
         ld (EnvKey) Y  # 'key'
         ld X (C)  # Parameter list in X
         push (EnvBind)  # Build bind frame
         link
         push (At)  # Bind At
         push At
         push (This)  # Bind This
         push This
         ld (This) (Y)  # to object
         do
            atom X  # More parameters?
         while z  # Yes
            ld E (X)  # Get symbol
            ld X (X CDR)
            push (E)  # Save old value
            push E  # Save symbol
            cmp Y Z  # More args?
            if ne  # Yes
               sub Y I
               ld (E) (Y)  # Set new value to next arg
            else
               ld (E) Nil  # New value NIL
            end
         loop
         cmp X Nil  # NIL-terminated parameter list?
         if eq  # Yes
            link
            ld (EnvBind) L  # Close bind frame
            push 0  # Init env swap
            ld Z (C CDR)  # Body in Z
            prog Z  # Run body
            pop A  # Drop env swap
            pop L  # Get link
            do  # Unbind symbols
               pop X  # Next symbol
               pop (X)  # Restore value
               cmp S L  # More?
            until eq  # No
            pop L  # Restore link
            pop (EnvBind)  # Restore bind link
            pop (EnvKey)  # 'key'
            pop (EnvCls)  # and 'cls'
            pop X
            ret
         end
         # Non-NIL parameter
         cmp X At  # '@'?
         if ne  # No
            push (X)  # Save last parameter's old value
            push X  # and the last parameter
            ld (X) Nil  # Set new value to NIL
            link
            ld (EnvBind) L  # Close bind frame
            push 0  # Init env swap
            ld Z (C CDR)  # Body in Z
            prog Z  # Run body
            pop A  # Drop env swap
            pop L  # Get link
            do  # Unbind symbols
               pop X  # Next symbol
               pop (X)  # Restore value
               cmp S L  # More?
            until eq  # No
            pop L  # Restore link
            pop (EnvBind)  # Restore bind link
            pop (EnvKey)  # 'key'
            pop (EnvCls)  # and 'cls'
            pop X
            ret
         end
         # Evaluated argument list
         link
         ld (EnvBind) L  # Close bind frame
         push 0  # Init env swap
         push (EnvNext)   # Save current 'next'
         push (EnvArgs)  # and varArgs base
         cmp Y Z  # Any args?
         if eq  # No
            ld (EnvArgs) 0
            ld (EnvNext) 0
         else
            link  # Build varArgs frame
            do
               sub Y I
               push (Y)  # Push next argument
               cmp S (StkLimit)  # Stack check
               jlt stkErrX
               cmp Y Z   # More args?
            until eq  # No
            ld (EnvArgs) S  # Set new varArgs base
            ld (EnvNext) L  # Set new 'next'
            link  # Close varArgs frame
         end
         ld Z (C CDR)  # Body in Z
         prog Z  # Run body
         null (EnvNext)  # VarArgs?
         if nz  # Yes
            drop  # Drop varArgs
         end
         pop (EnvArgs)  # Restore varArgs base
         pop (EnvNext)   # and 'next'
         pop A  # Drop env swap
         pop L  # Get link
         do  # Unbind symbols
            pop X  # Next symbol
            pop (X)  # Restore value
            cmp S L  # More?
         until eq  # No
         pop L  # Restore link
         pop (EnvBind)  # Restore bind link
         pop (EnvKey)  # 'key'
         pop (EnvCls)  # and 'cls'
         pop X
         ret
      end
      cmp A (A)  # Auto-symbol?
      if eq  # Yes
         call sharedLibC_FA  # Try dynamic load
         jz undefinedCX
      end
      ld C A
   loop

(code 'applyVarXYZ_E 0)
   ld C (Y)  # Get 'foo'
   do
      cnt C  # Short number?
      if nz  # Yes
         push (EnvApply)  # Build apply frame
         link
         sym S  # Align stack to cell boundary
         if nz
            push ZERO
         end
         push Nil  # Init CDR
         push C  # 'fun'
         ld E S  # 'exe in E
         do
            cmp Y Z  # Any args?
         while ne  # Yes
            sub Y I
            push ((Y))  # CAR of next arg
            push ZERO  # Dummy symbol's tail
            push Nil  # Init CDR
            lea A (S II)  # Value address
            push A  # CAR
            ld (S V) S  # Store CDR of previous cell
            cmp S (StkLimit)  # Stack check
            jlt stkErrX
         loop
         link
         ld (EnvApply) L  # Close apply frame
         call (C)  # Eval SUBR
         drop
         pop (EnvApply)
         ret
      end
      big C  # Undefined if bignum
      jnz undefinedCX
      cmp S (StkLimit)  # Stack check
      jlt stkErrX
      atom C  # Cell?
      if z  # Yes
         # Apply EXPR
         push X
         ld X (C)  # Parameter list in X
         push (EnvBind)  # Build bind frame
         link
         push (At)  # Bind At
         push At
         do
            atom X  # More parameters?
         while z  # Yes
            ld E (X)  # Get symbol
            ld X (X CDR)
            push (E)  # Save old value
            push E  # Save symbol
            cmp Y Z  # More args?
            if ne  # Yes
               sub Y I
               ld (E) ((Y))  # Set new value to CAR of next arg
            else
               ld (E) Nil  # New value NIL
            end
         loop
         cmp X Nil  # NIL-terminated parameter list?
         if eq  # Yes
            link
            ld (EnvBind) L  # Close bind frame
            push 0  # Init env swap
            ld Z (C CDR)  # Body in Z
            prog Z  # Run body
            pop A  # Drop env swap
            pop L  # Get link
            do  # Unbind symbols
               pop X  # Next symbol
               pop (X)  # Restore value
               cmp S L  # More?
            until eq  # No
            pop L  # Restore link
            pop (EnvBind)  # Restore bind link
            pop X
            ret
         end
         # Non-NIL parameter
         cmp X At  # '@'?
         if ne  # No
            push (X)  # Save last parameter's old value
            push X  # and the last parameter
            ld (X) Nil  # Set new value to NIL
            link
            ld (EnvBind) L  # Close bind frame
            push 0  # Init env swap
            ld Z (C CDR)  # Body in Z
            prog Z  # Run body
            pop A  # Drop env swap
            pop L  # Get link
            do  # Unbind symbols
               pop X  # Next symbol
               pop (X)  # Restore value
               cmp S L  # More?
            until eq  # No
            pop L  # Restore link
            pop (EnvBind)  # Restore bind link
            pop X
            ret
         end
         # Evaluated argument list
         link
         ld (EnvBind) L  # Close bind frame
         push 0  # Init env swap
         push (EnvNext)   # Save current 'next'
         push (EnvArgs)  # and varArgs base
         cmp Y Z  # Any args?
         if eq  # No
            ld (EnvArgs) 0
            ld (EnvNext) 0
         else
            link  # Build varArgs frame
            do
               sub Y I
               push ((Y))  # Push CAR of next argument
               cmp S (StkLimit)  # Stack check
               jlt stkErrX
               cmp Y Z   # More args?
            until eq  # No
            ld (EnvArgs) S  # Set new varArgs base
            ld (EnvNext) L  # Set new 'next'
            link  # Close varArgs frame
         end
         ld Z (C CDR)  # Body in Z
         prog Z  # Run body
         null (EnvNext)  # VarArgs?
         if nz  # Yes
            drop  # Drop varArgs
         end
         pop (EnvArgs)  # Restore varArgs base
         pop (EnvNext)   # and 'next'
         pop A  # Drop env swap
         pop L  # Get link
         do  # Unbind symbols
            pop X  # Next symbol
            pop (X)  # Restore value
            cmp S L  # More?
         until eq  # No
         pop L  # Restore link
         pop (EnvBind)  # Restore bind link
         pop X
         ret
      end
      ld A (C)  # Else symbolic, get value
      cmp A doMeth  # Method?
      if eq  # Yes
         sub Y I  # First arg
         ld E ((Y))  # Get object
         num E  # Need symbol
         jnz symErrEX
         sym E
         jz symErrEX
         sym (E TAIL)  # External symbol?
         if nz  # Yes
            call dbFetchEX  # Fetch it
         end
         push X
         push Z  # Save arg pointers
         push Y
         ld Y C  # 'msg'
         ld Z Nil  # No classes
         call methodEY_FCYZ  # Found?
         jne msgErrYX  # No
         ld (S I) (EnvCls)  # 'cls'
         ld (S) (EnvKey)  # 'key'
         ld (EnvCls) Z  # Set new
         ld (EnvKey) Y  # 'key'
         ld X (C)  # Parameter list in X
         push (EnvBind)  # Build bind frame
         link
         push (At)  # Bind At
         push At
         push (This)  # Bind This
         push This
         ld (This) ((Y))  # to object
         do
            atom X  # More parameters?
         while z  # Yes
            ld E (X)  # Get symbol
            ld X (X CDR)
            push (E)  # Save old value
            push E  # Save symbol
            cmp Y Z  # More args?
            if ne  # Yes
               sub Y I
               ld (E) ((Y))  # Set new value to CAR of next arg
            else
               ld (E) Nil  # New value NIL
            end
         loop
         cmp X Nil  # NIL-terminated parameter list?
         if eq  # Yes
            link
            ld (EnvBind) L  # Close bind frame
            push 0  # Init env swap
            ld Z (C CDR)  # Body in Z
            prog Z  # Run body
            pop A  # Drop env swap
            pop L  # Get link
            do  # Unbind symbols
               pop X  # Next symbol
               pop (X)  # Restore value
               cmp S L  # More?
            until eq  # No
            pop L  # Restore link
            pop (EnvBind)  # Restore bind link
            pop (EnvKey)  # 'key'
            pop (EnvCls)  # and 'cls'
            pop X
            ret
         end
         # Non-NIL parameter
         cmp X At  # '@'?
         if ne  # No
            push (X)  # Save last parameter's old value
            push X  # and the last parameter
            ld (X) Nil  # Set new value to NIL
            link
            ld (EnvBind) L  # Close bind frame
            push 0  # Init env swap
            ld Z (C CDR)  # Body in Z
            prog Z  # Run body
            pop A  # Drop env swap
            pop L  # Get link
            do  # Unbind symbols
               pop X  # Next symbol
               pop (X)  # Restore value
               cmp S L  # More?
            until eq  # No
            pop L  # Restore link
            pop (EnvBind)  # Restore bind link
            pop (EnvKey)  # 'key'
            pop (EnvCls)  # and 'cls'
            pop X
            ret
         end
         # Evaluated argument list
         link
         ld (EnvBind) L  # Close bind frame
         push 0  # Init env swap
         push (EnvNext)   # Save current 'next'
         push (EnvArgs)  # and varArgs base
         cmp Y Z  # Any args?
         if eq  # No
            ld (EnvArgs) 0
            ld (EnvNext) 0
         else
            link  # Build varArgs frame
            do
               sub Y I
               push ((Y))  # Push CAR of next argument
               cmp S (StkLimit)  # Stack check
               jlt stkErrX
               cmp Y Z   # More args?
            until eq  # No
            ld (EnvArgs) S  # Set new varArgs base
            ld (EnvNext) L  # Set new 'next'
            link  # Close varArgs frame
         end
         ld Z (C CDR)  # Body in Z
         prog Z  # Run body
         null (EnvNext)  # VarArgs?
         if nz  # Yes
            drop  # Drop varArgs
         end
         pop (EnvArgs)  # Restore varArgs base
         pop (EnvNext)   # and 'next'
         pop A  # Drop env swap
         pop L  # Get link
         do  # Unbind symbols
            pop X  # Next symbol
            pop (X)  # Restore value
            cmp S L  # More?
         until eq  # No
         pop L  # Restore link
         pop (EnvBind)  # Restore bind link
         pop (EnvKey)  # 'key'
         pop (EnvCls)  # and 'cls'
         pop X
         ret
      end
      cmp A (A)  # Auto-symbol?
      if eq  # Yes
         call sharedLibC_FA  # Try dynamic load
         jz undefinedCX
      end
      ld C A
   loop

# (apply 'fun 'lst ['any ..]) -> any
(code 'doApply 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   eval  # Eval 'fun'
   link
   push E
   ld Y S  # Pointer to 'fun' in Y
   ld Z (Z CDR)  # Second arg
   ld E (Z)
   eval+  # Eval 'lst'
   do
      ld Z (Z CDR)  # Args
      atom Z  # More?
   while z  # Yes
      push E  # Save 'lst'
      ld E (Z)
      eval+  # Eval next arg
      xchg E (S)  # Keep 'lst' in E
   loop
   do
      atom E  # Expand 'lst'
   while z
      push (E)
      cmp S (StkLimit)  # Stack check
      jlt stkErrX
      ld E (E CDR)
   loop
   ld Z S  # Z on last argument
   link  # Close frame
   call applyXYZ_E  # Apply
   drop
   pop Z
   pop Y
   pop X
   ret

# (pass 'fun ['any ..]) -> any
(code 'doPass 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   eval  # Eval 'fun'
   link
   push E  # Push 'fun'
   ld Y S  # Pointer to 'fun' in Y
   do  # 'any' args
      ld Z (Z CDR)  # Any?
      atom Z
   while z  # Yes
      ld E (Z)
      eval+  # Eval next 'lst'
      push E
   loop
   ld C (EnvNext)  # VarArgs
   do
      cmp C (EnvArgs)  # Any?
   while ne  # Yes
      sub C I
      push (C)  # Next arg
   loop
   ld Z S  # Z on last argument
   link  # Close frame
   call applyXYZ_E  # Apply
   drop
   pop Z
   pop Y
   pop X
   ret

# (maps 'fun 'sym ['lst ..]) -> any
(code 'doMaps 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   ld Z (Z CDR)
   eval  # Eval 'fun'
   link
   push E  # Save 'fun'
   ld Y S  # Pointer to 'fun' in Y
   ld E (Z)
   ld Z (Z CDR)
   eval+  # Eval 'sym'
   push E  # <Y -I> 'sym'
   do  # 'lst' args
      atom Z  # More 'lst' args?
   while z  # Yes
      ld E (Z)
      eval+  # Eval next 'lst'
      push E
      ld Z (Z CDR)
   loop
   link  # <L I> Last argument
   ld E (Y -I)  # Get 'sym'
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   sym (E TAIL)  # External symbol?
   if nz  # Yes
      call dbFetchEX  # Fetch it
   end
   ld E (E TAIL)  # Get property list
   off E SYM  # Clear 'extern' tag
   ld (Y -I) E
   ld E Nil  # Preset return value
   do
      atom (Y -I)  # First 'lst' done?
   while z  # No
      push Y
      lea Z (L I)  # Last arg
      call applyVarXYZ_E  # Apply
      pop Y
      lea Z (L I)  # Last arg
      do
         ld (Z) ((Z) CDR)  # Pop all lists
         add Z I
         cmp Z Y  # Reached 'fun'?
      until eq  # Yes
   loop
   drop
   pop Z
   pop Y
   pop X
   ret

# (map 'fun 'lst ..) -> lst
(code 'doMap 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   ld Z (Z CDR)
   eval  # Eval 'fun'
   link
   push E  # Push 'fun'
   ld Y S  # Pointer to 'fun' in Y
   do  # 'lst' args
      ld E (Z)
      eval+  # Eval next 'lst'
      push E
      ld Z (Z CDR)
      atom Z  # More 'lst' args?
   until nz  # No
   link  # <L I> Last argument
   ld E Nil  # Preset return value
   do
      atom (Y -I)  # First 'lst' done?
   while z  # No
      push Y
      lea Z (L I)  # Last arg
      call applyXYZ_E  # Apply
      pop Y
      lea Z (L I)  # Last arg
      do
         ld (Z) ((Z) CDR)  # Pop all lists
         add Z I
         cmp Z Y  # Reached 'fun'?
      until eq  # Yes
   loop
   drop
   pop Z
   pop Y
   pop X
   ret

# (mapc 'fun 'lst ..) -> lst
(code 'doMapc 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   ld Z (Z CDR)
   eval  # Eval 'fun'
   link
   push E  # Push 'fun'
   ld Y S  # Pointer to 'fun' in Y
   do  # 'lst' args
      ld E (Z)
      eval+  # Eval next 'lst'
      push E
      ld Z (Z CDR)
      atom Z  # More 'lst' args?
   until nz  # No
   link  # <L I> Last argument
   ld E Nil  # Preset return value
   do
      atom (Y -I)  # First 'lst' done?
   while z  # No
      push Y
      lea Z (L I)  # Last arg
      call applyVarXYZ_E  # Apply
      pop Y
      lea Z (L I)  # Last arg
      do
         ld (Z) ((Z) CDR)  # Pop all lists
         add Z I
         cmp Z Y  # Reached 'fun'?
      until eq  # Yes
   loop
   drop
   pop Z
   pop Y
   pop X
   ret

# (maplist 'fun 'lst ..) -> lst
(code 'doMaplist 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   ld Z (Z CDR)
   eval  # Eval 'fun'
   link
   push E  # Push 'fun'
   ld Y S  # Pointer to 'fun' in Y
   do  # 'lst' args
      ld E (Z)
      eval+  # Eval next 'lst'
      push E
      ld Z (Z CDR)
      atom Z  # More 'lst' args?
   until nz  # No
   push Nil  # <L I> Result
   link  # <L II> Last argument
   push 0  # <L -I> Result tail
   do
      atom (Y -I)  # First 'lst' done?
   while z  # No
      push Y
      lea Z (L II)  # Last arg
      call applyXYZ_E  # Apply
      pop Y
      call consE_C  # Cons with NIL
      ld (C) E
      ld (C CDR) Nil
      null (L -I)  # Result tail?
      if z  # No
         ld (L I) C  # Store result
      else
         ld ((L -I) CDR) C  # Set new CDR of result tail
      end
      ld (L -I) C  # Store result tail
      lea Z (L II)  # Last arg
      do
         ld (Z) ((Z) CDR)  # Pop all lists
         add Z I
         cmp Z Y  # Reached 'fun'?
      until eq  # Yes
   loop
   ld E (L I)  # Result
   drop
   pop Z
   pop Y
   pop X
   ret

# (mapcar 'fun 'lst ..) -> lst
(code 'doMapcar 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   ld Z (Z CDR)
   eval  # Eval 'fun'
   link
   push E  # Push 'fun'
   ld Y S  # Pointer to 'fun' in Y
   do  # 'lst' args
      ld E (Z)
      eval+  # Eval next 'lst'
      push E
      ld Z (Z CDR)
      atom Z  # More 'lst' args?
   until nz  # No
   push Nil  # <L I> Result
   link  # <L II> Last argument
   push 0  # <L -I> Result tail
   do
      atom (Y -I)  # First 'lst' done?
   while z  # No
      push Y
      lea Z (L II)  # Last arg
      call applyVarXYZ_E  # Apply
      pop Y
      call consE_C  # Cons with NIL
      ld (C) E
      ld (C CDR) Nil
      null (L -I)  # Result tail?
      if z  # No
         ld (L I) C  # Store result
      else
         ld ((L -I) CDR) C  # Set new CDR of result tail
      end
      ld (L -I) C  # Store result tail
      lea Z (L II)  # Last arg
      do
         ld (Z) ((Z) CDR)  # Pop all lists
         add Z I
         cmp Z Y  # Reached 'fun'?
      until eq  # Yes
   loop
   ld E (L I)  # Result
   drop
   pop Z
   pop Y
   pop X
   ret

# (mapcon 'fun 'lst ..) -> lst
(code 'doMapcon 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   ld Z (Z CDR)
   eval  # Eval 'fun'
   link
   push E  # Push 'fun'
   ld Y S  # Pointer to 'fun' in Y
   do  # 'lst' args
      ld E (Z)
      eval+  # Eval next 'lst'
      push E
      ld Z (Z CDR)
      atom Z  # More 'lst' args?
   until nz  # No
   push Nil  # <L I> Result
   link  # <L II> Last argument
   push 0  # <L -I> Result tail
   do
      atom (Y -I)  # First 'lst' done?
   while z  # No
      push Y
      lea Z (L II)  # Last arg
      call applyXYZ_E  # Apply
      pop Y
      atom E  # Got cell?
      if z  # Yes
         null (L -I)  # Result tail?
         if z  # No
            ld (L I) E  # Store result
         else
            ld A (L -I)  # Else get result tail
            do
               atom (A CDR)  # Find last cell
            while z
               ld A (A CDR)
            loop
            ld (A CDR) E  # Set new CDR
         end
         ld (L -I) E  # Store result tail
      end
      lea Z (L II)  # Last arg
      do
         ld (Z) ((Z) CDR)  # Pop all lists
         add Z I
         cmp Z Y  # Reached 'fun'?
      until eq  # Yes
   loop
   ld E (L I)  # Result
   drop
   pop Z
   pop Y
   pop X
   ret

# (mapcan 'fun 'lst ..) -> lst
(code 'doMapcan 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   ld Z (Z CDR)
   eval  # Eval 'fun'
   link
   push E  # Push 'fun'
   ld Y S  # Pointer to 'fun' in Y
   do  # 'lst' args
      ld E (Z)
      eval+  # Eval next 'lst'
      push E
      ld Z (Z CDR)
      atom Z  # More 'lst' args?
   until nz  # No
   push Nil  # <L I> Result
   link  # <L II> Last argument
   push 0  # <L -I> Result tail
   do
      atom (Y -I)  # First 'lst' done?
   while z  # No
      push Y
      lea Z (L II)  # Last arg
      call applyVarXYZ_E  # Apply
      pop Y
      atom E  # Got cell?
      if z  # Yes
         null (L -I)  # Result tail?
         if z  # No
            ld (L I) E  # Store result
         else
            ld A (L -I)  # Else get result tail
            do
               atom (A CDR)  # Find last cell
            while z
               ld A (A CDR)
            loop
            ld (A CDR) E  # Set new CDR
         end
         ld (L -I) E  # Store result tail
      end
      lea Z (L II)  # Last arg
      do
         ld (Z) ((Z) CDR)  # Pop all lists
         add Z I
         cmp Z Y  # Reached 'fun'?
      until eq  # Yes
   loop
   ld E (L I)  # Result
   drop
   pop Z
   pop Y
   pop X
   ret

# (filter 'fun 'lst ..) -> lst
(code 'doFilter 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   ld Z (Z CDR)
   eval  # Eval 'fun'
   link
   push E  # Push 'fun'
   ld Y S  # Pointer to 'fun' in Y
   do  # 'lst' args
      ld E (Z)
      eval+  # Eval next 'lst'
      push E
      ld Z (Z CDR)
      atom Z  # More 'lst' args?
   until nz  # No
   push Nil  # <L I> Result
   link  # <L II> Last argument
   push 0  # <L -I> Result tail
   do
      atom (Y -I)  # First 'lst' done?
   while z  # No
      push Y
      lea Z (L II)  # Last arg
      call applyVarXYZ_E  # Apply
      pop Y
      cmp E Nil  # NIL?
      if ne  # No
         call consE_C  # Cons with NIL
         ld (C) ((Y -I))  # Element of first 'lst'
         ld (C CDR) Nil
         null (L -I)  # Result tail?
         if z  # No
            ld (L I) C  # Store result
         else
            ld ((L -I) CDR) C  # Set new CDR of result tail
         end
         ld (L -I) C  # Store result tail
      end
      lea Z (L II)  # Last arg
      do
         ld (Z) ((Z) CDR)  # Pop all lists
         add Z I
         cmp Z Y  # Reached 'fun'?
      until eq  # Yes
   loop
   ld E (L I)  # Result
   drop
   pop Z
   pop Y
   pop X
   ret

# (extract 'fun 'lst ..) -> lst
(code 'doExtract 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   ld Z (Z CDR)
   eval  # Eval 'fun'
   link
   push E  # Push 'fun'
   ld Y S  # Pointer to 'fun' in Y
   do  # 'lst' args
      ld E (Z)
      eval+  # Eval next 'lst'
      push E
      ld Z (Z CDR)
      atom Z  # More 'lst' args?
   until nz  # No
   push Nil  # <L I> Result
   link  # <L II> Last argument
   push 0  # <L -I> Result tail
   do
      atom (Y -I)  # First 'lst' done?
   while z  # No
      push Y
      lea Z (L II)  # Last arg
      call applyVarXYZ_E  # Apply
      pop Y
      cmp E Nil  # NIL?
      if ne  # No
         call consE_C  # Cons with NIL
         ld (C) E
         ld (C CDR) Nil
         null (L -I)  # Result tail?
         if z  # No
            ld (L I) C  # Store result
         else
            ld ((L -I) CDR) C  # Set new CDR of result tail
         end
         ld (L -I) C  # Store result tail
      end
      lea Z (L II)  # Last arg
      do
         ld (Z) ((Z) CDR)  # Pop all lists
         add Z I
         cmp Z Y  # Reached 'fun'?
      until eq  # Yes
   loop
   ld E (L I)  # Result
   drop
   pop Z
   pop Y
   pop X
   ret

# (seek 'fun 'lst ..) -> lst
(code 'doSeek 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   ld Z (Z CDR)
   eval  # Eval 'fun'
   link
   push E  # Push 'fun'
   ld Y S  # Pointer to 'fun' in Y
   do  # 'lst' args
      ld E (Z)
      eval+  # Eval next 'lst'
      push E
      ld Z (Z CDR)
      atom Z  # More 'lst' args?
   until nz  # No
   link  # <L I> Last argument
   ld E Nil  # Preset return value
   do
      atom (Y -I)  # First 'lst' done?
   while z  # No
      push Y
      lea Z (L I)  # Last arg
      call applyXYZ_E  # Apply
      pop Y
      cmp E Nil  # NIL?
      if ne  # No
         ld E (Y -I)  # Return first 'lst'
         break T
      end
      lea Z (L I)  # Last arg
      do
         ld (Z) ((Z) CDR)  # Pop all lists
         add Z I
         cmp Z Y  # Reached 'fun'?
      until eq  # Yes
   loop
   drop
   pop Z
   pop Y
   pop X
   ret

# (find 'fun 'lst ..) -> any
(code 'doFind 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   ld Z (Z CDR)
   eval  # Eval 'fun'
   link
   push E  # Push 'fun'
   ld Y S  # Pointer to 'fun' in Y
   do  # 'lst' args
      ld E (Z)
      eval+  # Eval next 'lst'
      push E
      ld Z (Z CDR)
      atom Z  # More 'lst' args?
   until nz  # No
   link  # <L I> Last argument
   ld E Nil  # Preset return value
   do
      atom (Y -I)  # First 'lst' done?
   while z  # No
      push Y
      lea Z (L I)  # Last arg
      call applyVarXYZ_E  # Apply
      pop Y
      cmp E Nil  # NIL?
      if ne  # No
         ld E ((Y -I))  # Return CAR of first 'lst'
         break T
      end
      lea Z (L I)  # Last arg
      do
         ld (Z) ((Z) CDR)  # Pop all lists
         add Z I
         cmp Z Y  # Reached 'fun'?
      until eq  # Yes
   loop
   drop
   pop Z
   pop Y
   pop X
   ret

# (pick 'fun 'lst ..) -> any
(code 'doPick 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   ld Z (Z CDR)
   eval  # Eval 'fun'
   link
   push E  # Push 'fun'
   ld Y S  # Pointer to 'fun' in Y
   do  # 'lst' args
      ld E (Z)
      eval+  # Eval next 'lst'
      push E
      ld Z (Z CDR)
      atom Z  # More 'lst' args?
   until nz  # No
   link  # <L I> Last argument
   ld E Nil  # Preset return value
   do
      atom (Y -I)  # First 'lst' done?
   while z  # No
      push Y
      lea Z (L I)  # Last arg
      call applyVarXYZ_E  # Apply
      pop Y
      cmp E Nil  # NIL?
      break ne  # No
      lea Z (L I)  # Last arg
      do
         ld (Z) ((Z) CDR)  # Pop all lists
         add Z I
         cmp Z Y  # Reached 'fun'?
      until eq  # Yes
   loop
   drop
   pop Z
   pop Y
   pop X
   ret

# (cnt 'fun 'lst ..) -> cnt
(code 'doCnt 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   ld Z (Z CDR)
   eval  # Eval 'fun'
   link
   push E  # Push 'fun'
   ld Y S  # Pointer to 'fun' in Y
   do  # 'lst' args
      ld E (Z)
      eval+  # Eval next 'lst'
      push E
      ld Z (Z CDR)
      atom Z  # More 'lst' args?
   until nz  # No
   link  # <L I> Last argument
   push ZERO  # <L -I> Result
   do
      atom (Y -I)  # First 'lst' done?
   while z  # No
      push Y
      lea Z (L I)  # Last arg
      call applyVarXYZ_E  # Apply
      pop Y
      cmp E Nil  # NIL?
      if ne  # No
         add (S) (hex "10")  # Increment count
      end
      lea Z (L I)  # Last arg
      do
         ld (Z) ((Z) CDR)  # Pop all lists
         add Z I
         cmp Z Y  # Reached 'fun'?
      until eq  # Yes
   loop
   pop E  # Get result
   drop
   pop Z
   pop Y
   pop X
   ret

# (sum 'fun 'lst ..) -> num
(code 'doSum 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   ld Z (Z CDR)
   eval  # Eval 'fun'
   link
   push E  # Push 'fun'
   ld Y S  # Pointer to 'fun' in Y
   do  # 'lst' args
      ld E (Z)
      eval+  # Eval next 'lst'
      push E
      ld Z (Z CDR)
      atom Z  # More 'lst' args?
   until nz  # No
   push ZERO  # <L II> Safe
   push ZERO  # <L I> Result
   link  # <L III> Last argument
   do
      atom (Y -I)  # First 'lst' done?
   while z  # No
      push Y
      lea Z (L III)  # Last arg
      call applyVarXYZ_E  # Apply
      pop Y
      num E  # Number?
      if nz  # Yes
         ld (L II) E  # Save
         ld A (L I)  # Result so far
         call addAE_A  # Add
         ld (L I) A  # Result
      end
      lea Z (L III)  # Last arg
      do
         ld (Z) ((Z) CDR)  # Pop all lists
         add Z I
         cmp Z Y  # Reached 'fun'?
      until eq  # Yes
   loop
   ld E (L I)  # Result
   drop
   pop Z
   pop Y
   pop X
   ret

# (maxi 'fun 'lst ..) -> any
(code 'doMaxi 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   ld Z (Z CDR)
   eval  # Eval 'fun'
   link
   push E  # Push 'fun'
   ld Y S  # Pointer to 'fun' in Y
   do  # 'lst' args
      ld E (Z)
      eval+  # Eval next 'lst'
      push E
      ld Z (Z CDR)
      atom Z  # More 'lst' args?
   until nz  # No
   push Nil  # <L II> Value
   push Nil  # <L I> Result
   link  # <L III> Last argument
   do
      atom (Y -I)  # First 'lst' done?
   while z  # No
      push Y
      lea Z (L III)  # Last arg
      call applyVarXYZ_E  # Apply
      ld Y E  # Keep
      ld A (L II)  # Maximal value
      call compareAE_F  # Compare with current
      if lt
         ld (L I) (((S) -I))  # New result
         ld (L II) Y  # New maximum
      end
      pop Y
      lea Z (L III)  # Last arg
      do
         ld (Z) ((Z) CDR)  # Pop all lists
         add Z I
         cmp Z Y  # Reached 'fun'?
      until eq  # Yes
   loop
   ld E (L I)  # Result
   drop
   pop Z
   pop Y
   pop X
   ret

# (mini 'fun 'lst ..) -> any
(code 'doMini 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   ld Z (Z CDR)
   eval  # Eval 'fun'
   link
   push E  # Push 'fun'
   ld Y S  # Pointer to 'fun' in Y
   do  # 'lst' args
      ld E (Z)
      eval+  # Eval next 'lst'
      push E
      ld Z (Z CDR)
      atom Z  # More 'lst' args?
   until nz  # No
   push TSym  # <L II> Value
   push Nil  # <L I> Result
   link  # <L III> Last argument
   do
      atom (Y -I)  # First 'lst' done?
   while z  # No
      push Y
      lea Z (L III)  # Last arg
      call applyVarXYZ_E  # Apply
      ld Y E  # Keep
      ld A (L II)  # Minimal value
      call compareAE_F  # Compare with current
      if gt
         ld (L I) (((S) -I))  # New result
         ld (L II) Y  # New minimum
      end
      pop Y
      lea Z (L III)  # Last arg
      do
         ld (Z) ((Z) CDR)  # Pop all lists
         add Z I
         cmp Z Y  # Reached 'fun'?
      until eq  # Yes
   loop
   ld E (L I)  # Result
   drop
   pop Z
   pop Y
   pop X
   ret

# (fish 'fun 'any) -> lst
(code 'doFish 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   eval  # Eval 'fun'
   link
   push E  # Push 'fun'
   ld Y S  # Pointer to 'fun' in Y
   ld Z (Z CDR)  # Second arg
   ld E (Z)
   eval+  # Eval 'any'
   push ZERO  # <L III> Apply arg
   push E  # <L II> 'any'
   push Nil  # <L I> Result
   link  # Close frame
   ld A (L II)  # Get 'any'
   call fishAXY  # Fish for results
   ld E (L I)  # Result
   drop
   pop Z
   pop Y
   pop X
   ret

(code 'fishAXY 0)
   push A  # Save arg
   push Y
   lea Z (L III)  # Set apply arg
   ld (Z) A
   call applyXYZ_E  # Apply
   pop Y
   pop A
   cmp E Nil  # NIL?
   if ne  # No
      call cons_C  # New cell
      ld (C) A  # Cons arg
      ld (C CDR) (L I)  # into result
      ld (L I) C
      ret
   end
   atom A  # Cell?
   jnz ret  # No
   cmp (A CDR) Nil  # CDR?
   if ne  # Yes
      push A
      ld A (A CDR)
      call fishAXY  # Recurse on CDR
      pop A
   end
   ld A (A)
   jmp fishAXY  # Recurse on CAR

# (by 'fun1 'fun2 'lst ..) -> lst
(code 'doBy 2)
   push X
   push Y
   push Z
   ld X E  # Keep expression in X
   ld Z (E CDR)  # Z on args
   ld E (Z)
   ld Z (Z CDR)
   eval  # Eval 'fun1'
   link
   push E  # Push 'fun1'
   ld E (Z)
   ld Z (Z CDR)
   eval+  # Eval 'fun2'
   xchg E (S)  # Push
   push E  # Push 'fun1'
   ld Y S  # Pointer to 'fun1' in Y
   do  # 'lst' args
      ld E (Z)
      eval+  # Eval next 'lst'
      push E
      ld Z (Z CDR)
      atom Z  # More 'lst' args?
   until nz  # No
   push Nil  # <L I> Result
   link  # <L II> Last argument
   push 0  # <L -I> Result tail
   do
      atom (Y -I)  # First 'lst' done?
   while z  # No
      push Y
      lea Z (L II)  # Last arg
      call applyVarXYZ_E  # Apply
      pop Y
      call consE_C  # Cons with element from first 'lst'
      ld (C) E
      ld (C CDR) ((Y -I))
      call consC_A  # Concat to result
      ld (A) C
      ld (A CDR) Nil
      null (L -I)  # Result tail?
      if z  # No
         ld (L I) A  # Store result
      else
         ld ((L -I) CDR) A  # Set new CDR of result tail
      end
      ld (L -I) A  # Store result tail
      lea Z (L II)  # Last arg
      do
         ld (Z) ((Z) CDR)  # Pop all lists
         add Z I
         cmp Z Y  # Reached 'fun1'?
      until eq  # Yes
   loop
   ld Z Y  # Point to 'fun1'
   add Y I  # Pointer to 'fun2' in Y
   ld (Z) (L I)  # Result
   call applyXYZ_E  # Apply
   ld C E  # Remove CARs in result list
   do
      atom C  # More elements?
   while z  # Yes
      ld (C) ((C) CDR)
      ld C (C CDR)
   loop
   drop
   pop Z
   pop Y
   pop X
   ret

# vi:et:ts=3:sw=3
