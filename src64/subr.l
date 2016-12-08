# 24oct16abu
# (c) Software Lab. Alexander Burger

# (car 'var) -> any
(code 'doCar 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   pop X
   ret

# (cdr 'lst) -> any
(code 'doCdr 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   pop X
   ret

(code 'doCaar 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   pop X
   ret

(code 'doCadr 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   pop X
   ret

(code 'doCdar 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   pop X
   ret

(code 'doCddr 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   pop X
   ret

(code 'doCaaar 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   pop X
   ret

(code 'doCaadr 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   pop X
   ret

(code 'doCadar 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   pop X
   ret

(code 'doCaddr 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   pop X
   ret

(code 'doCdaar 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   pop X
   ret

(code 'doCdadr 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   pop X
   ret

(code 'doCddar 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   pop X
   ret

(code 'doCdddr 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   pop X
   ret

(code 'doCaaaar 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   pop X
   ret

(code 'doCaaadr 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   pop X
   ret

(code 'doCaadar 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   pop X
   ret

(code 'doCaaddr 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   pop X
   ret

(code 'doCadaar 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   pop X
   ret

(code 'doCadadr 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   pop X
   ret

(code 'doCaddar 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   pop X
   ret

(code 'doCadddr 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   pop X
   ret

(code 'doCdaaar 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   pop X
   ret

(code 'doCdaadr 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   pop X
   ret

(code 'doCdadar 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   pop X
   ret

(code 'doCdaddr 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   pop X
   ret

(code 'doCddaar 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   pop X
   ret

(code 'doCddadr 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   pop X
   ret

(code 'doCdddar 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   num E  # Need variable
   jnz varErrEX
   ld E (E)  # Take CAR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   pop X
   ret

(code 'doCddddr 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld E (E CDR)  # Take CDR
   pop X
   ret

# (nth 'lst 'cnt ..) -> lst
(code 'doNth 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval 'lst'
   eval
   link
   push E  # <L I> Safe
   link
   ld Y (Y CDR)
   do
      atom E  # End of 'lst'?
   while z  # No
      call evCntXY_FE  # Next 'cnt'
      ld C E  # into C
      dec C  # 'cnt' greater zero?
      if ns  # Yes
         ld E (L I)  # Get result
         do
            dec C  # Iterate
         while ns
            ld E (E CDR)
         loop
      else
         ld E Nil  # Return NIL
         break T
      end
      ld Y (Y CDR)  # Next arg?
      atom Y
   while z  # Yes
      ld E (E)  # Take CAR
      ld (L I) E  # Save
   loop
   drop
   pop Y
   pop X
   ret

# (con 'lst 'any) -> any
(code 'doCon 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval 'lst'
   eval
   atom E  # Need pair
   jnz pairErrEX
   link
   push E  # <L I> Safe
   link
   ld Y (Y CDR)  # Next arg
   ld E (Y)  # Eval 'any'
   eval
   ld ((L I) CDR) E  # Concatenate
   drop
   pop Y
   pop X
   ret

# (cons 'any ['any ..]) -> lst
(code 'doCons 2)
   push X
   push Y
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   call consE_C  # Cons with NIL
   ld (C) E
   ld (C CDR) Nil
   link
   push C  # <L I> Safe
   link
   do
      ld Y C  # Y on last cell
      ld X (X CDR)  # Args
      atom (X CDR)  # more than one left?
   while z  # Yes
      ld E (X)
      eval  # Eval next arg
      call consE_C  # Cons with NIL
      ld (C) E
      ld (C CDR) Nil
      ld (Y CDR) C  # Store in CDR of last cell
   loop
   ld E (X)  # Last arg
   eval  # Eval it
   ld (Y CDR) E  # Store in CDR of last cell
   ld E (L I)  # Return pair(s)
   drop
   pop Y
   pop X
   ret

# (conc 'lst ..) -> lst
(code 'doConc 2)
   push X
   push Y
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   ld Y E  # Keep in Y
   link
   push E  # <L I> Safe
   link
   do
      ld X (X CDR)  # Next arg?
      atom X
   while z  # Yes
      ld E (X)
      eval  # Eval next arg
      atom Y  # Result list?
      if nz  # No
         ld (L I) E  # Init result
         ld Y E  # Keep in Y
      else
         do
            atom (Y CDR)  # Find end of result list
         while z
            ld Y (Y CDR)
         loop
         ld (Y CDR) E
      end
   loop
   ld E (L I)  # Return list
   drop
   pop Y
   pop X
   ret

# (circ 'any ..) -> lst
(code 'doCirc 2)
   push X
   push Y
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   call consE_C  # Cons with NIL
   ld (C) E
   ld (C CDR) Nil
   link
   push C  # <L I> Safe
   link
   do
      ld Y C  # Keep in Y
      ld X (X CDR)  # Next arg?
      atom X
   while z  # Yes
      ld E (X)
      eval  # Eval next arg
      call consE_C  # Cons with NIL
      ld (C) E
      ld (C CDR) Nil
      ld (Y CDR) C  # Store in CDR of last cell
   loop
   ld E (L I)  # Return list
   ld (Y CDR) E  # Make circular
   drop
   pop Y
   pop X
   ret

# (rot 'lst ['cnt]) -> lst
(code 'doRot 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval 'lst'
   eval
   atom E  # Pair?
   if z  # Yes
      ld Y (Y CDR)
      atom Y  # Second arg?
      if nz  # No
         ld Y E  # Get 'lst' in Y
         ld X (Y)  # Keep CAR
         do
            ld Y (Y CDR)  # Next cell?
            atom Y
         while z  # Yes
            cmp Y E  # Circular?
         while ne  # No
            xchg X (Y)  # Swap
         loop
         ld (E) X  # Store new CAR
      else
         link
         push E  # <L I> 'lst'
         link
         call evCntXY_FE  # Eval 'cnt'
         if nz
            ld Y (L I)  # Retrieve 'lst'
            ld X (Y)  # Keep CAR
            do
               dec E  # Decrement count
            while nz
               ld Y (Y CDR)  # Next cell?
               atom Y
            while z  # Yes
               cmp Y (L I)  # Circular?
            while ne  # No
               xchg X (Y)  # Swap
            loop
            ld ((L I)) X  # Store new CAR
         end
         ld E (L I)
         drop
      end
   end
   pop Y
   pop X
   ret

# (list 'any ['any ..]) -> lst
(code 'doList 2)
   push X
   push Y
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   call consE_C  # Cons with NIL
   ld (C) E
   ld (C CDR) Nil
   link
   push C  # <L I> Safe
   link
   do
      ld Y C  # Keep in Y
      ld X (X CDR)  # Next arg?
      atom X
   while z  # Yes
      ld E (X)
      eval  # Eval next arg
      call consE_C  # Cons with NIL
      ld (C) E
      ld (C CDR) Nil
      ld (Y CDR) C  # Store in CDR of last cell
   loop
   ld E (L I)  # Return list
   drop
   pop Y
   pop X
   ret

# (need 'cnt ['lst ['any]]) -> lst
# (need 'cnt ['num|sym]) -> lst
(code 'doNeed 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   call evCntXY_FE  # Eval 'cnt'
   ld X E  # Keep in X
   ld Y (Y CDR)
   ld E (Y)  # Eval next
   eval
   link
   atom E  # First form?
   jz 10  # Yes
   cmp E Nil
   if eq  # Yes
10    push E  # <L II> 'lst'
      ld Y (Y CDR)
      ld E (Y)  # Eval 'any'
      eval+
      push E  # <L I> 'any'
   else
      push Nil  # <L II> 'lst'
      push E  # <L I> 'num|sym'
   end
   link
   ld E (L II)  # Get 'lst'
   null X  # 'cnt'?
   if nz  # Yes
      if ns  # > 0
         ld Y E  # 'lst' in Y
         do
            atom Y  # Find end of 'lst'
         while z
            ld Y (Y CDR)
            dec X  # Decrement 'cnt'
         loop
         do
            dec X  # 'cnt' > 0?
         while ns  # Yes
            ld C E
            call consC_E  # Cons 'any' with 'lst'
            ld (E) (L I)
            ld (E CDR) C
         loop
      else
         atom E  # 'lst' atomic?
         if nz
            call cons_E  # Cons 'any' with NIL
            ld (E) (L I)
            ld (E CDR) Nil
            ld (L II) E  # Save
         else
            do
               ld Y (E CDR)  # Find last cell
               atom Y
            while z
               inc X  # Increment 'cnt'
               ld E Y
            loop
         end
         do
            inc X  # Increment 'cnt'
         while s
            call cons_A  # Cons 'any' with NIL
            ld (A) (L I)
            ld (A CDR) Nil
            ld (E CDR) A  # Append
            ld E (E CDR)
         loop
         ld E (L II)  # Get result
      end
   end
   drop
   pop Y
   pop X
   ret

# (range 'num1 'num2 ['num3]) -> lst
(code 'doRange 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval 'num1'
   eval
   num E  # Number?
   jz numErrEX  # No
   link
   push E  # <L IV> Start value
   ld Y (Y CDR)
   ld E (Y)  # Eval 'num2'
   eval+
   num E  # Number?
   jz numErrEX  # No
   push E  # <L III> End value
   push ONE  # <L II> Increment
   ld E ((Y CDR))  # Eval 'num3'
   eval+
   cmp E Nil  # NIL?
   if ne  # No
      num E  # Number?
      jz numErrEX  # No
      cmp E ZERO  # Zero?
      jeq argErrEX  # Yes
      test E SIGN  # Negative?
      jnz argErrEX  # Yes
      ld (S) E  # Else set increment
   end
   link
   call cons_X  # Build first cell
   tuck X  # <L I> Result
   link
   ld (X) (L IV)  # Start value
   ld (X CDR) Nil
   ld A (L IV)  # Get start value
   ld E (L III)  # and end value
   call cmpNumAE_F  # Start <= end?
   ld A (L IV)  # Get start value again
   if le  # Yes
      do
         ld E (L II)  # Increment start value
         call addAE_A
         push A
         ld E (L III)  # Start <= end?
         call cmpNumAE_F
      while le  # Yes
         pop A
         call consA_Y  # Append to result
         ld (Y) A
         ld (Y CDR) Nil
         ld (X CDR) Y
         ld X Y
      loop
   else
      do
         ld E (L II)  # Decrement start value
         call subAE_A
         push A
         ld E (L III)  # Start >= end?
         call cmpNumAE_F
      while ge  # Yes
         pop A
         call consA_Y  # Append to result
         ld (Y) A
         ld (Y CDR) Nil
         ld (X CDR) Y
         ld X Y
      loop
   end
   ld E (L I)
   drop
   pop Y
   pop X
   ret

# (full 'any) -> bool
(code 'doFull 2)
   ld E ((E CDR))  # Eval arg
   eval
   do
      atom E  # Pair?
      jnz retT  # Yes
      cmp (E) Nil  # Found NIL?
      jz retNil  # Yes
      ld E (E CDR)
   loop

# (make .. [(made 'lst ..)] .. [(link 'any ..)] ..) -> any
(code 'doMake 2)
   push X
   ld X (E CDR)  # Body
   push (EnvMake)  # Save current 'make' env
   push (EnvYoke)
   link
   push Nil  # <L I> Result
   ld (EnvMake) S  # Tail address
   ld (EnvYoke) S  # Head address
   link
   exec X
   ld E (L I)  # Get result
   drop
   pop (EnvYoke)  # Restore 'make' env
   pop (EnvMake)
   pop X
   ret

# (made ['lst1 ['lst2]]) -> lst
(code 'doMade 2)
   push X
   ld X E
   null (EnvMake)  # In 'make'?
   jz makeErrX  # No
   push Y
   ld Y (E CDR)  # Y on args
   atom Y  # Any?
   if z  # Yes
      ld E (Y)  # Eval 'lst1'
      eval
      ld ((EnvYoke)) E  # Set new list
      ld Y (Y CDR)
      ld E (Y)  # Eval 'lst2'
      eval
      atom E  # Pair?
      if nz  # No
         ld E ((EnvYoke))  # Retrieve new 'lst1'
         do
            ld A (E CDR)  # Find last cell
            atom A
         while z
            ld E A
         loop
      end
      lea E (E CDR)  # Set new tail address
      ld (EnvMake) E
   end
   ld E ((EnvYoke))  # Return list
   pop Y
   pop X
   ret

# (chain 'lst ..) -> lst
(code 'doChain 2)
   push X
   ld X E
   null (EnvMake)  # In 'make'?
   jz makeErrX  # No
   push Y
   ld Y (E CDR)  # Y on args
   do
      ld E (Y)  # Eval arg
      eval
      ld ((EnvMake)) E  # Store new list
      atom E  # Got a list?
      if z  # Yes
         ld C E
         do
            ld A (C CDR)  # Find last cell
            atom A
         while z
            ld C A
         loop
         lea C (C CDR)  # Set new tail address
         ld (EnvMake) C
      end
      ld Y (Y CDR)  # More args?
      atom Y
   until nz
   pop Y
   pop X
   ret

# (link 'any ..) -> any
(code 'doLink 2)
   push X
   ld X E
   null (EnvMake)  # In 'make'?
   jz makeErrX  # No
   push Y
   ld Y (E CDR)  # Y on args
   do
      ld E (Y)  # Eval arg
      eval
      call consE_C  # Make new cell
      ld (C) E
      ld (C CDR) Nil
      ld ((EnvMake)) C  # Store new tail
      lea C (C CDR)  # Set new tail address
      ld (EnvMake) C
      ld Y (Y CDR)  # More args?
      atom Y
   until nz
   pop Y
   pop X
   ret

# (yoke 'any ..) -> any
(code 'doYoke 2)
   push X
   ld X E
   null (EnvMake)  # In 'make'?
   jz makeErrX  # No
   push Y
   ld Y (E CDR)  # Y on args
   do
      ld E (Y)  # Eval arg
      eval
      call consE_A  # Make new cell
      ld (A) E
      ld (A CDR) ((EnvYoke))  # Set head
      ld ((EnvYoke)) A
      ld Y (Y CDR)  # More args?
      atom Y
   until nz
   do
      ld C ((EnvMake))  # Adjust tail address?
      atom C
   while z  # Yes
      lea C (C CDR)  # Set new tail address
      ld (EnvMake) C
   loop
   pop Y
   pop X
   ret

# (copy 'any) -> any
(code 'doCopy 2)
   ld E ((E CDR))  # Eval arg
   eval
   atom E  # List?
   if z  # Yes
      push Z
      ld Z E  # Keep head in Z
      call consE_C  # Copy first cell
      ld (C) (E)
      ld (C CDR) (E CDR)
      link
      push C  # <L I> Result
      link
      do
         ld E (E CDR)
         atom E  # More cells?
      while z  # Yes
         cmp E Z  # Circular?
         if eq  # Yes
            ld (C CDR) (L I)  # Concat head
            break T
         end
         call consE_A  # Copy next cell
         ld (A) (E)
         ld (A CDR) (E CDR)
         ld (C CDR) A  # Concat to result
         ld C A
      loop
      ld E (L I)  # Get result
      drop
      pop Z
   end
   ret

# (mix 'lst cnt|'any ..) -> lst
(code 'doMix 2)
   push X
   ld X (E CDR)  # X on args
   ld E (X)  # Eval first
   eval
   cmp E Nil  # Empty list?
   jz 10  # Yes
   atom E  # Atomic?
   if z  # No
10    push Y
      ld X (X CDR)  # Next arg?
      atom X
      if z  # Yes
         link
         push E  # <L II> List
         link
         ld C (X)
         cnt C  # Literal second arg?
         if z  # No
            ld E C  # Eval second arg
            eval
         else
            shr C 4  # Normalize
            jz 20
            if x  # Zero or negative
20             ld E Nil
            else
               do
                  dec C  # nth
               while nz
                  ld E (E CDR)
               loop
               ld E (E)
            end
         end
         call consE_C  # Cons first result cell
         ld (C) E
         ld (C CDR) Nil
         tuck C  # <L I> Result
         link
         do
            ld Y C  # Keep in Y
            ld X (X CDR)  # Next arg?
            atom X
         while z  # Yes
            ld E (X)
            cnt E  # Literal next arg?
            if z  # No
               eval  # Eval next arg
            else
               shr E 4  # Normalize
               jz 30
               if x  # Zero or negative
30                ld E Nil
               else
                  ld C (L II)  # Get list
                  do
                     dec E  # nth
                  while nz
                     ld C (C CDR)
                  loop
                  ld E (C)
               end
            end
            call consE_C  # Cons first result cell
            ld (C) E
            ld (C CDR) Nil
            ld (Y CDR) C  # Store in CDR of last cell
         loop
         ld E (L I)  # Get result
         drop
      else
         ld E Nil  # Return NIL
      end
      pop Y
   end
   pop X
   ret

# (append 'lst ..) -> lst
(code 'doAppend 2)
   push X
   ld X (E CDR)  # Args
   do
      atom (X CDR)  # More than one left?
   while z  # Yes
      ld E (X)  # Eval first
      eval
      atom E  # Found a list?
      if z  # Yes
         ld A E
         call consE_E  # Copy first cell
         ld (E) (A)
         ld C (A CDR)
         ld (E CDR) C
         link
         push E  # <L I> Result
         link
         do
            atom C  # More cells?
         while z  # Yes
            call consC_A  # Copy next cell
            ld (A) (C)
            ld C (C CDR)
            ld (A CDR) C
            ld (E CDR) A  # Concat to result
            ld E A
         loop
         push E  # Save last cell
         do
            ld X (X CDR)  # More than one left?
            atom (X CDR)
         while z  # Yes
            ld E (X)  # Eval next argument
            eval
            do
               atom E  # Found a list?
            while z  # Yes
               call consE_A  # Copy cells
               ld (A) (E)
               ld E (E CDR)
               ld (A CDR) E
               ld ((S) CDR) A  # Concat with last cell
               ld (S) A  # New last cell
            loop
         loop
         ld E (X)  # Eval last argument
         eval
         pop A  # Get last cell
         ld (A CDR) E  # Concat last list
         ld E (L I)  # Get result
         drop
         pop X
         ret
      end
      ld X (X CDR)  # Next arg
   loop
   ld E (X)  # Eval last arg
   eval
   pop X
   ret

# (delete 'any 'lst) -> lst
(code 'doDelete 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval 'any'
   eval
   link
   push E  # <L II/III> 'any'
   ld E ((X CDR))  # Eval 'lst'
   eval+
   push E  # <L I/II> 'lst'
   link
   atom E  # Atomic?
   if z  # No
      ld X E  # Keep in X
      ld A (L II)  # 'any'
      ld E (X)  #  Equal to CAR?
      call equalAE_F
      if eq  # Yes
         ld E (X CDR)  # Return CDR
      else
         call cons_C  # Cons first item into C
         ld (C) (X)
         ld (C CDR) Nil
         tuck C  # <L I> Result
         link
         do
            ld X (X CDR)  # Next item
            atom X  # More cells?
         while z  # Yes
            ld A (L III)  # 'any'
            ld E (X)  #  Equal to CAR?
            call equalAE_F
            if eq  # Yes
               ld X (X CDR)  # Skip this item
               break T
            end
            call cons_A  # Cons next item
            ld (A) (X)
            ld (A CDR) Nil
            ld (C CDR) A  # Append
            ld C A
         loop
         ld (C CDR) X  # Set tail
         ld E (L I)  # Get result
      end
   end
   drop
   pop X
   ret

# (delq 'any 'lst) -> lst
(code 'doDelq 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval 'any'
   eval
   link
   push E  # <L II/III> 'any'
   ld E ((X CDR))  # Eval 'lst'
   eval+
   push E  # <L I/II> 'lst'
   link
   atom E  # Atomic?
   if z  # No
      ld X (L II)  # 'any'
      cmp X (E)  #  Equal to CAR?
      if eq  # Yes
         ld E (E CDR)  # Return CDR
      else
         call cons_C  # Cons first item into C
         ld (C) (E)
         ld (C CDR) Nil
         tuck C  # <L I> Result
         link
         do
            ld E (E CDR)  # Next item
            atom E  # More cells?
         while z  # Yes
            cmp X (E)  #  'any' equal to CAR?
            if eq  # Yes
               ld E (E CDR)  # Skip this item
               break T
            end
            call cons_A  # Cons next item
            ld (A) (E)
            ld (A CDR) Nil
            ld (C CDR) A  # Append
            ld C A
         loop
         ld (C CDR) E  # Set tail
         ld E (L I)  # Get result
      end
   end
   drop
   pop X
   ret

# (replace 'lst 'any1 'any2 ..) -> lst
(code 'doReplace 2)
   push X
   ld X (E CDR)  # X on args
   ld E (X)  # Eval 'lst'
   eval
   atom E  # Atomic?
   if z  # No
      push Y
      push Z
      link
      push E  # Save 'lst'
      ld Y E  # Keep in Y
      do
         ld X (X CDR)  # 'anyN' args?
         atom X
      while z  # Yes
         ld E (X)  # Eval next two args
         eval+
         push E  # Save first
         ld X (X CDR)
         ld E (X)  # Eval second
         eval+
         push E  # Save second
      loop
      ld X L  # X above 'any1'
      link
      ld C S  # C below end of 'any' items
      call cons_Z  # Build first result cell
      do
         sub X II  # Try next 'any' pair
         cmp X C  # Reached last 'any' item?
      while ne  # No
         ld A (X)  # Next item
         ld E (Y)  # Equal to CAR of 'lst'?
         call equalAE_F
         if eq  # Yes
            ld (Z) (X -I)  # First result item is 'any2'
            jmp 10
         end
      loop
      ld (Z) (Y)  # First result item is CAR of 'lst'
10    ld (Z CDR) Nil
      tuck Z  # <L I> Result
      link
      do
         ld Y (Y CDR)  # More in 'lst'?
         atom Y
      while z  # Yes
         ld X (L)  # X above 'any1'
         do
            sub X II  # Try next 'any' pair
            cmp X C  # Reached top?
         while ne  # No
            ld A (X)  # Next item
            ld E (Y)  # Equal to next item in 'lst'?
            call equalAE_F
            if eq  # Yes
               call cons_E  # Build next result cell
               ld (E) (X -I)  # Next result item
               jmp 20
            end
         loop
         call cons_E  # Build next result cell
         ld (E) (Y)  # Next result item from 'lst'
20       ld (E CDR) Nil
         ld (Z CDR) E  # Concat to result
         ld Z E
      loop
      ld E (L I)  # Get result
      drop
      pop Z
      pop Y
   end
   pop X
   ret

# (insert 'cnt 'lst 'any) -> lst
(code 'doInsert 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   call evCntXY_FE  # Eval 'cnt'
   ld Z E  # in Z
   ld Y (Y CDR)  # Second arg
   ld E (Y)
   eval  # Eval 'lst'
   link
   push E  # Save 'lst'
   link
   ld Y (Y CDR)  # Point to third arg
   atom E  # Second arg atomic?
   jnz 10  # Yes
   dec Z  # Count <= 1?
   if sz  # Yes
10    ld E (Y)  # Eval 'any'
      eval
      call consE_X  # Cons 'any'
      ld (X) E
      ld (X CDR) (L I)  # with arg
      ld E X  # Return it
   else
      call consE_X  # Cons first cell
      ld (X) (E)
      ld (X CDR) Nil
      tuck X  # <L I> Result
      link
      do
         ld E (E CDR)  # More elements?
         atom E
      while z  # Yes
         dec Z  # Count?
      while nz  # Yes
         call cons_A  # Copy next cell
         ld (A) (E)
         ld (A CDR) Nil
         ld (X CDR) A  # Append to result
         ld X (X CDR)
      loop
      ld Z E  # Rest in Z
      ld E (Y)  # Eval 'any'
      eval
      call consE_A  # Last cell
      ld (A) E  # Cons 'any'
      ld (A CDR) Z  # with rest
      ld (X CDR) A  # Append to result
      ld E (L I)  # Get result
   end
   drop
   pop Z
   pop Y
   pop X
   ret

# (remove 'cnt 'lst) -> lst
(code 'doRemove 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   call evCntXY_FE  # Eval 'cnt'
   xchg Y E  # in Y
   ld E ((E CDR))  # Second arg
   eval  # Eval 'lst'
   atom E  # Atomic?
   if z  # No
      dec Y  # Count <= 0?
      if ns  # No
         if z  # Count = 1
            ld E (E CDR)  # Return CDR
         else
            link
            push E  # Save 'lst'
            link
            call consE_X  # Cons first cell
            ld (X) (E)
            ld (X CDR) Nil
            tuck X  # <L I> Result
            link
            do
               ld E (E CDR)  # More elements?
               atom E
            while z  # Yes
               dec Y  # Count?
            while nz  # Yes
               call cons_A  # Copy next cell
               ld (A) (E)
               ld (A CDR) Nil
               ld (X CDR) A  # Append to result
               ld X (X CDR)
            loop
            ld (X CDR) (E CDR)  # Append rest
            ld E (L I)  # Get result
            drop
         end
      end
   end
   pop Y
   pop X
   ret

# (place 'cnt 'lst 'any) -> lst
(code 'doPlace 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   call evCntXY_FE  # Eval 'cnt'
   ld Z E  # in Z
   ld Y (Y CDR)  # Second arg
   ld E (Y)
   eval  # Eval 'lst'
   ld Y (Y CDR)  # Point to third arg
   atom E  # Atomic?
   if nz  # Yes
      ld E (Y)  # Return 'any'
      eval
   else
      link
      push E  # Save 'lst'
      link
      dec Z  # Count <= 1?
      if sz  # Yes
         ld E (Y)  # Eval 'any'
         eval
         call consE_X  # Cons 'any'
         ld (X) E
         ld (X CDR) ((L I) CDR)  # with CDR
         ld E X  # Return it
      else
         call consE_X  # Cons first cell
         ld (X) (E)
         ld (X CDR) Nil
         tuck X  # <L I> Result
         link
         do
            ld E (E CDR)  # More elements?
            atom E
         while z  # Yes
            dec Z  # Count?
         while nz  # Yes
            call cons_A  # Copy next cell
            ld (A) (E)
            ld (A CDR) Nil
            ld (X CDR) A  # Append to result
            ld X (X CDR)
         loop
         ld Z E  # Rest in Z
         ld E (Y)  # Eval 'any'
         eval
         call consE_A  # Last cell
         ld (A) E  # Cons 'any'
         ld (A CDR) (Z CDR)  # with rest
         ld (X CDR) A  # Append to result
         ld E (L I)  # Get result
      end
      drop
   end
   pop Z
   pop Y
   pop X
   ret

# (strip 'any) -> any
(code 'doStrip 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   do
      atom E  # List?
   while z  # Yes
      cmp (E) Quote  # CAR is 'quote'?
   while eq  # Yes
      ld A (E CDR)  # Get CDR
      cmp A E  # Circular?
   while ne  # No
      ld E A  # Go to CDR
   loop
   ret

# (split 'lst 'any ..) -> lst
(code 'doSplit 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval 'lst'
   eval
   atom E  # List?
   if z  # Yes
      push Y
      push Z
      link
      push E  # Save 'lst'
      do
         ld X (X CDR)  # Next 'any' arg?
         atom X
      while z  # Yes
         ld E (X)  # Eval next arg
         eval+
         push E  # and save it
      loop  # <L III/..> 'any' items
      lea C (L -I)  # C is top of 'any' items, and adr of 'lst'
      ld Y Nil
      push Y  # <L II> Result in Y
      ld Z Y
      push Z  # <L I> Sublist in Z
      link
      do
         lea X (L III)  # X on 'any' items
         do
            cmp X C  # Reached top?
         while ne  # No
            ld A (X)  # Next item
            ld E ((C))  # Equal to CAR of 'lst'?
            call equalAE_F
            if eq  # Yes
               atom Y  # Result?
               if nz  # No
                  call cons_Y  # Initial result cell
                  ld (Y) (L I)  # with sublist
                  ld (Y CDR) Nil
                  ld (L II) Y  # Store in result
               else
                  call cons_A  # New cell
                  ld (A) (L I)  # with sublist
                  ld (A CDR) Nil
                  ld (Y CDR) A  # Concat to result
                  ld Y A
               end
               ld Z Nil  # Clear sublist
               ld (L I) Z
               jmp 10
            end
            add X I  # Next 'any' item
         loop
         atom Z  # Sublist?
         if nz  # No
            call cons_Z  # Initial sublist cell
            ld (Z) ((C))
            ld (Z CDR) Nil
            ld (L I) Z  # Store in sublist
         else
            call cons_A  # New cell
            ld (A) ((C))
            ld (A CDR) Nil
            ld (Z CDR) A  # Concat to sublist
            ld Z A
         end
10       ld A ((C) CDR)  # Next element of 'lst'
         ld (C) A
         atom A  # Any?
      until nz  # No
      call cons_E  # Cons final sublist
      ld (E) (L I)
      ld (E CDR) Nil
      atom Y  # Result so far?
      if z  # Yes
         ld (Y CDR) E  # Concat final sublist
         ld E (L II)  # Get result
      end
      drop
      pop Z
      pop Y
   end
   pop X
   ret

# (reverse 'lst) -> lst
(code 'doReverse 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   link
   push E  # <L II> Safe
   link
   ld A Nil  # Result
   do
      atom E  # More cells?
   while z  # Yes
      call consA_C  # Cons next CAR
      ld (C) (E)
      ld (C CDR) A
      ld A C
      ld E (E CDR)
   loop
   ld E A  # Return list
   drop
   ret

# (flip 'lst ['cnt]) -> lst
(code 'doFlip 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval 'lst'
   eval
   atom E  # Pair?
   if z  # Yes
      ld Y (Y CDR)
      atom Y  # Second arg?
      if nz  # No
         ld C (E CDR)  # More than one element?
         atom C
         if z  # Yes
            ld (E CDR) Nil  # Make it the last cell
            do
               ld A (C CDR)  # Get next cell
               ld (C CDR) E  # Concat previous
               ld E C  # Set to first
               atom A  # Done?
            while z  # No
               ld C A
            loop
         end
      else
         link
         push E  # <L I> 'lst'
         link
         call evCntXY_FE  # Eval 'cnt'
         ld C (L I)  # Retrieve 'lst'
         drop
         ld X (C CDR)  # More than one element?
         atom X
         if z  # Yes
            dec E  # 'cnt' > 1?
            if nsz  # Yes
               ld (C CDR) (X CDR)  # Swap first two cells
               ld (X CDR) C
               do
                  dec E  # Done?
               while nz  # No
                  ld A (C CDR)  # More cells?
                  atom A
               while z  # Yes
                  ld (C CDR) (A CDR)  # Swap next two cells
                  ld (A CDR) X
                  ld X A
               loop
               ld C X  # Return 'lst'
            end
         end
         ld E C  # Return 'lst'
      end
   end
   pop Y
   pop X
   ret

# (trim 'lst) -> lst
(code 'doTrim 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   link
   push E  # Save
   link
   call trimE_E  # Trim
   drop
   ret

(code 'trimE_E 0)
   atom E  # List?
   if z  # Yes
      cmp S (StkLimit)  # Stack check
      jlt stkErr
      push (E)  # Save CAR
      ld E (E CDR)  # Trim CDR
      call trimE_E
      cmp E Nil  # All trimmed?
      if eq  # Yes
         ld E (S)  # Get CAR
         call isBlankE_F  # Blank?
         if eq  # Yes
            add S I  # Drop CAR
            ld E Nil  # Return NIL
            ret
         end
         call cons_E  # New tail cell
         pop (E)  # Copy CAR
         ld (E CDR) Nil
         ret
      end
      ld A E
      call consE_E  # New cell
      pop (E)  # Copy CAR
      ld (E CDR) A
   end
   ret

# (clip 'lst) -> lst
(code 'doClip 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   do
      atom E  # List?
      jnz ret  # No
      push E
      ld E (E)  # CAR blank?
      call isBlankE_F
      pop E
   while z  # Yes
      ld E (E CDR)  # Try next
   loop
   link
   push E  # Save
   link
   call trimE_E  # Trim
   drop
   ret

# (head 'cnt|lst 'lst) -> lst
(code 'doHead 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   ld Y (Y CDR)  # Y on rest
   eval
   cmp E Nil  # NIL?
   if ne  # No
      atom E  # 'lst' arg?
      if z  # Yes
         link
         push E  # <L I> First 'lst'
         link
         ld E (Y)  # Eval second
         eval
         atom E  # 'lst'?
         if z  # Yes
            ld X E  # 'lst'
            ld Y (L I)  # Head list
            do
               ld A (X)
               ld E (Y)  # Compare elements
               call equalAE_F  # Equal?
            while eq  # Yes
               ld Y (Y CDR)  # Head done?
               atom Y
               if nz  # Yes
                  ld E (L I)  # Return head
                  drop
                  pop Y
                  pop X
                  ret
               end
               ld X (X CDR)
            loop
         end
         drop
         jmp 10
      end
      call xCntEX_FE  # 'cnt' zero?
      if nz  # No
         ld X E  # 'cnt' in X
         ld E (Y)  # Eval second
         eval
         atom E  # List?
         if z  # Yes
            null X  # 'cnt' negative?
            if s  # Yes
               ld Y E
               do
                  inc X  # Increment 'cnt' by length
                  ld Y (Y CDR)
                  atom Y
               until nz
               null X  # 'cnt' still negative or zero?
               jsz 10  # Yes
            end
            link
            push E  # Save 'lst'
            link
            call cons_Y  # Build first cell
            ld (Y) (E)  # From CAR of 'lst'
            ld (Y CDR) Nil
            tuck Y  # <L I> Result
            link
            do
               dec X  # Counted down?
            while nz  # No
               ld E (E CDR)  # List done?
               atom E
            while z  # No
               call cons_A  # Build next cell
               ld (A) (E)  # From next list item
               ld (A CDR) Nil
               ld (Y CDR) A  # Concat to result
               ld Y A
            loop
            ld E (L I)  # Get result
            drop
         end
      else
10       ld E Nil  # Return NIL
      end
   end
   pop Y
   pop X
   ret

# (tail 'cnt|lst 'lst) -> lst
(code 'doTail 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   ld Y (Y CDR)  # Y on rest
   eval
   cmp E Nil  # NIL?
   if ne  # No
      atom E  # 'lst' arg?
      if z  # Yes
         link
         push E  # <L I> First 'lst'
         link
         ld E (Y)  # Eval second
         eval
         atom E  # 'lst'?
         if z  # Yes
            ld X E  # 'lst'
            ld Y (L I)  # Tail list
            do
               ld A X
               ld E Y  # Compare lists
               call equalAE_F  # Equal?
               if eq  # Yes
                  ld E (L I)  # Return tail
                  drop
                  pop Y
                  pop X
                  ret
               end
               ld X (X CDR)  # List done?
               atom X
            until nz  # Yes
         end
         drop
         jmp 10
      end
      call xCntEX_FE  # 'cnt' zero?
      if nz  # No
         ld X E  # 'cnt' in X
         ld E (Y)  # Eval second
         eval
         atom E  # List?
         if z  # Yes
            null X  # 'cnt' negative?
            if s  # Yes
               do
                  ld E (E CDR)
                  inc X  # Take -nth
               until z
            else
               ld Y (E CDR)  # Traverse CDR
               do
                  dec X  # Decrement 'cnt'
               while nz
                  atom Y  # End of list?
               while z  # No
                  ld Y (Y CDR)
               loop
               do
                  atom Y  # Traverse rest
               while z
                  ld E (E CDR)  # Step result
                  ld Y (Y CDR)  # and rest
               loop
            end
         end
      else
10       ld E Nil  # Return NIL
      end
   end
   pop Y
   pop X
   ret

# (stem 'lst 'any ..) -> lst
(code 'doStem 2)
   push X
   push Y
   ld X (E CDR)  # Args
   ld E (X)  # Eval 'lst'
   eval
   link
   push E  # Save 'lst'
   do
      ld X (X CDR)  # Next 'any' arg?
      atom X
   while z  # Yes
      ld E (X)  # Eval next arg
      eval+
      push E  # and save it
   loop  # <L I/..> 'any' items
   lea C (L -I)  # C is top of 'any' items, and adr of 'lst'
   link
   ld Y (C)  # Get 'lst'
   do
      atom Y  # End of 'lst'?
   while z  # No
      lea X (L I)  # X on 'any' items
      do
         cmp X C  # Reached top?
      while ne  # No
         ld A (X)  # Next item
         ld E (Y)  # Found in 'lst'?
         call equalAE_F
         if eq  # Yes
            ld (C) (Y CDR)  # Set result
            break T
         end
         add X I  # Next 'any' item
      loop
      ld Y (Y CDR)  # Next in 'lst'
   loop
   ld E (C)  # Get Result
   drop
   pop Y
   pop X
   ret

# (fin 'any) -> num|sym
(code 'doFin 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   do
      atom E  # Final atom?
   while z  # No
      ld E (E CDR)  # Try next
   loop
   ret

# (last 'lst) -> any
(code 'doLast 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   atom E  # List?
   if z  # Yes
      do
         atom (E CDR)  # Last cell?
      while z  # No
         ld E (E CDR)  # Try next
      loop
      ld E (E)  # Get CAR
   end
   ret

# (== 'any ..) -> flg
(code 'doEq 2)
   push X
   ld X (E CDR)  # X on args
   ld E (X)
   eval  # Eval first arg
   link
   push E  # <L I> Safe
   link
   do
      ld X (X CDR)  # More args?
      atom X
   while z  # Yes
      ld E (X)
      eval  # Eval next arg
      cmp E (L I)  # Eq to first arg?
      if ne  # No
         drop
         ld E Nil  # Return NIL
         pop X
         ret
      end
   loop
   drop
   ld E TSym  # Return T
   pop X
   ret

# (n== 'any ..) -> flg
(code 'doNEq 2)
   push X
   ld X (E CDR)  # X on args
   ld E (X)
   eval  # Eval first arg
   link
   push E  # <L I> Safe
   link
   do
      ld X (X CDR)  # More args?
      atom X
   while z  # Yes
      ld E (X)
      eval  # Eval next arg
      cmp E (L I)  # Eq to first arg?
      if ne  # No
         drop
         ld E TSym  # Return T
         pop X
         ret
      end
   loop
   drop
   ld E Nil  # Return NIL
   pop X
   ret

# (= 'any ..) -> flg
(code 'doEqual 2)
   push X
   ld X (E CDR)  # X on args
   ld E (X)
   eval  # Eval first arg
   link
   push E  # <L I> Safe
   link
   do
      ld X (X CDR)  # More args?
      atom X
   while z  # Yes
      ld E (X)
      eval  # Eval next arg
      ld A (L I)  # Get first arg
      call equalAE_F  # Equal to previous?
      if ne  # No
         drop
         ld E Nil  # Return NIL
         pop X
         ret
      end
   loop
   drop
   ld E TSym  # Return T
   pop X
   ret

# (<> 'any ..) -> flg
(code 'doNEqual 2)
   push X
   ld X (E CDR)  # X on args
   ld E (X)
   eval  # Eval first arg
   link
   push E  # <L I> Safe
   link
   do
      ld X (X CDR)  # More args?
      atom X
   while z  # Yes
      ld E (X)
      eval  # Eval next arg
      ld A (L I)  # Get first arg
      call equalAE_F  # Equal to previous?
      if ne  # No
         drop
         ld E TSym  # Return T
         pop X
         ret
      end
   loop
   drop
   ld E Nil  # Return NIL
   pop X
   ret

# (=0 'any) -> 0 | NIL
(code 'doEq0 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   cmp E ZERO  # Zero?
   jne retNil  # No
   ret

# (=1 'any) -> 1 | NIL
(code 'doEq1 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   cmp E ONE  # One?
   jne retNil  # No
   ret

# (=T 'any) -> flg
(code 'doEqT 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   cmp E TSym  # T?
   jne retNil  # No
   ret

# (n0 'any) -> flg
(code 'doNEq0 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   cmp E ZERO  # Zero?
   jne retT  # No
   ld E Nil
   ret

# (nT 'any) -> flg
(code 'doNEqT 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   cmp E TSym  # T?
   jne retT  # No
   ld E Nil
   ret

# (< 'any ..) -> flg
(code 'doLt 2)
   push X
   ld X (E CDR)  # X on args
   ld E (X)
   eval  # Eval first arg
   link
   push E  # <L I> Safe
   link
   do
      ld X (X CDR)  # More args?
      atom X
   while z  # Yes
      ld E (X)
      eval  # Eval next arg
      ld A (L I)  # Get previous arg
      ld (L I) E  # Store current
      call compareAE_F  # Compare current with previous
      if ge  # Not greater or equal
         drop
         ld E Nil  # Return NIL
         pop X
         ret
      end
   loop
   drop
   ld E TSym  # Return T
   pop X
   ret

# (<= 'any ..) -> flg
(code 'doLe 2)
   push X
   ld X (E CDR)  # X on args
   ld E (X)
   eval  # Eval first arg
   link
   push E  # <L I> Safe
   link
   do
      ld X (X CDR)  # More args?
      atom X
   while z  # Yes
      ld E (X)
      eval  # Eval next arg
      ld A (L I)  # Get previous arg
      ld (L I) E  # Store current
      call compareAE_F  # Compare current with previous
      if gt  # Not greater or equal
         drop
         ld E Nil  # Return NIL
         pop X
         ret
      end
   loop
   drop
   ld E TSym  # Return T
   pop X
   ret

# (> 'any ..) -> flg
(code 'doGt 2)
   push X
   ld X (E CDR)  # X on args
   ld E (X)
   eval  # Eval first arg
   link
   push E  # <L I> Safe
   link
   do
      ld X (X CDR)  # More args?
      atom X
   while z  # Yes
      ld E (X)
      eval  # Eval next arg
      ld A (L I)  # Get previous arg
      ld (L I) E  # Store current
      call compareAE_F  # Compare current with previous
      if le  # Not greater or equal
         drop
         ld E Nil  # Return NIL
         pop X
         ret
      end
   loop
   drop
   ld E TSym  # Return T
   pop X
   ret

# (>= 'any ..) -> flg
(code 'doGe 2)
   push X
   ld X (E CDR)  # X on args
   ld E (X)
   eval  # Eval first arg
   link
   push E  # <L I> Safe
   link
   do
      ld X (X CDR)  # More args?
      atom X
   while z  # Yes
      ld E (X)
      eval  # Eval next arg
      ld A (L I)  # Get previous arg
      ld (L I) E  # Store current
      call compareAE_F  # Compare current with previous
      if lt  # Not greater or equal
         drop
         ld E Nil  # Return NIL
         pop X
         ret
      end
   loop
   drop
   ld E TSym  # Return T
   pop X
   ret

# (max 'any ..) -> any
(code 'doMax 2)
   push X
   push Y
   ld X (E CDR)  # X on args
   ld E (X)
   eval  # Eval first arg
   link
   push E  # <L I> Result
   link
   do
      ld X (X CDR)  # More args?
      atom X
   while z  # Yes
      ld E (X)
      eval  # Eval next arg
      ld A (L I)  # Get result
      ld Y E  # Save next arg
      call compareAE_F  # Compare arg with result
      if lt  # Result is less than
         ld (L I) Y  # Set new result
      end
   loop
   ld E (L I)  # Result
   drop
   pop Y
   pop X
   ret

# (min 'any ..) -> any
(code 'doMin 2)
   push X
   push Y
   ld X (E CDR)  # X on args
   ld E (X)
   eval  # Eval first arg
   link
   push E  # <L I> Result
   link
   do
      ld X (X CDR)  # More args?
      atom X
   while z  # Yes
      ld E (X)
      eval  # Eval next arg
      ld A (L I)  # Get result
      ld Y E  # Save next arg
      call compareAE_F  # Compare arg with result
      if gt  # Result is greater
         ld (L I) Y  # Set new result
      end
   loop
   ld E (L I)  # Result
   drop
   pop Y
   pop X
   ret

# (atom 'any) -> flg
(code 'doAtom 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   atom E  # Atom?
   jnz retT  # Yes
   ld E Nil
   ret

# (pair 'any) -> any
(code 'doPair 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   atom E  # Atom?
   jnz retNil  # Yes
   ret

# (circ? 'any) -> any
(code 'doCircQ 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   call circE_EF  # Circular?
   ldnz E Nil  # No
   ret

# (lst? 'any) -> flg
(code 'doLstQ 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   atom E  # Pair?
   jz retT  # Yes
   cmp E Nil  # NIL?
   jeq retT  # Yes
   ld E Nil
   ret

# (num? 'any) -> num | NIL
(code 'doNumQ 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   num E  # Number?
   jz retNil  # No
   ret

# (sym? 'any) -> flg
(code 'doSymQ 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   num E  # Number?
   jnz retNil  # Yes
   sym E  # Symbol?
   jnz retT  # Yes
   ld E Nil
   ret

# (flg? 'any) -> flg
(code 'doFlgQ 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   cmp E Nil  # NIL?
   jeq retT  # Yes
   cmp E TSym  # T?
   jne retNil  # No
   ret

# (member 'any 'lst) -> any
(code 'doMember 2)
   push X
   push Y
   ld X (E CDR)  # Args
   ld E (X)  # Eval 'any'
   eval
   link
   push E  # <L I> 'any'
   link
   ld E ((X CDR))  # Eval 'lst'
   eval
   ld X (L I)  # Retrieve 'any'
   ld Y E  # Get 'lst
   call memberXY_FY  # Member?
   ld E Y
   ldnz E Nil  # No
   drop
   pop Y
   pop X
   ret

# (memq 'any 'lst) -> any
(code 'doMemq 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval 'any'
   eval
   link
   push E  # <L I> 'any'
   link
   ld E ((X CDR))  # Eval 'lst'
   eval
   ld A (L I)  # Retrieve 'any'
   drop  # Clean up
   pop X
   ld C E  # Keep head in C
   do
      atom E  # List?
   while z  # Yes
      cmp A (E)  # Member?
      jeq ret  # Return list
      ld E (E CDR)  # Next item
      cmp C E  # Hit head?
      jeq retNil  # Yes
   loop
   cmp A E  # Same atoms?
   jne retNil  # No
   ret

# (mmeq 'lst 'lst) -> any
(code 'doMmeq 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   link
   push E  # <L I> 'lst'
   link
   ld E ((X CDR))  # Eval second
   eval
   ld X (L I)  # Retrieve first list
   ld C E  # Keep second in C
   do
      atom X  # Done?
   while z  # No
      ld A (X)  # Next item from first
      do
         atom E  # List?
      while z  # Yes
         cmp A (E)  # Member?
         jeq 20  # Return list
         ld E (E CDR)  # Next item
         cmp C E  # Hit head?
         jz 10  # Yes
      loop
      cmp A E  # Same atoms?
      jeq 20  # Yes
      ld X (X CDR)  # Get CDR of first
      ld E C  # Get second arg again
   loop
10 ld E Nil  # Return NIL
20 drop
   pop X
   ret

# (sect 'lst 'lst) -> lst
(code 'doSect 2)
   push X
   push Y
   push Z
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   link
   push E  # <L III> First 'lst'
   ld E ((X CDR))  # Eval second arg
   eval+
   push E  # <L II> Second 'lst'
   push Nil  # <L I> Result
   link
   ld Z 0  # Empty result cell
   ld X (L III)  # Get first list
   do
      atom X  # Done?
   while z  # No
      ld X (X)  # CAR of first
      ld Y (L II)  # Second
      call memberXY_FY  # Member?
      if eq  # Yes
         null Z  # Result still empty?
         if z  # Yes
            call cons_Z  # Build first cell
            ld (Z) X
            ld (Z CDR) Nil
            ld (L I) Z  # Store in result
         else
            call cons_A  # Build next cell
            ld (A) X
            ld (A CDR) Nil
            ld (Z CDR) A  # Concat to result
            ld Z A
         end
      end
      ld X ((L III) CDR)  # Next item in first
      ld (L III) X
   loop
   ld E (L I)  # Get result
   drop
   pop Z
   pop Y
   pop X
   ret

# (diff 'lst 'lst) -> lst
(code 'doDiff 2)
   push X
   push Y
   push Z
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   link
   push E  # <L III> First 'lst'
   ld E ((X CDR))  # Eval second arg
   eval+
   push E  # <L II> Second 'lst'
   push Nil  # <L I> Result
   link
   ld Z 0  # Empty result cell
   ld X (L III)  # Get first list
   do
      atom X  # Done?
   while z  # No
      ld X (X)  # CAR of first
      ld Y (L II)  # Second
      call memberXY_FY  # Member?
      if ne  # No
         null Z  # Result still empty?
         if z  # Yes
            call cons_Z  # Build first cell
            ld (Z) X
            ld (Z CDR) Nil
            ld (L I) Z  # Store in result
         else
            call cons_A  # Build next cell
            ld (A) X
            ld (A CDR) Nil
            ld (Z CDR) A  # Concat to result
            ld Z A
         end
      end
      ld X ((L III) CDR)  # Next item in first
      ld (L III) X
   loop
   ld E (L I)  # Get result
   drop
   pop Z
   pop Y
   pop X
   ret

# (index 'any 'lst) -> cnt | NIL
(code 'doIndex 2)
   push X
   push Y
   push Z
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   link
   push E  # <L I> 'any'
   link
   ld E ((X CDR))  # Eval second
   eval
   ld X (L I)  # Get 'any'
   ld Y E  # and 'lst'
   ld Z Y  # Keep head in Z
   ld C 1  # Count in C
   do
      atom Y  # List?
   while z  # Yes
      ld A X
      ld E (Y)
      call equalAE_F  # Found item?
      if eq  # Yes
         ld E C  # Get result
         shl E 4  # Make short number
         or E CNT
         jmp 90  # Found
      end
      inc C  # Increment result
      ld Y (Y CDR)  # Next item
      cmp Z Y  # Hit head?
   until eq  # Yes
   ld E Nil  # Not found
90 drop
   pop Z
   pop Y
   pop X
   ret

# (offset 'lst1 'lst2) -> cnt | NIL
(code 'doOffset 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   link
   push E  # <L I> 'lst1'
   link
   ld E ((X CDR))  # Eval 'lst2'
   eval
   ld C 0  # Init result
   ld X (L I)  # Get 'lst1'
   do
      atom E  # Any?
   while z  # Yes
      inc C  # Increment result
      ld A X  # Get 'lst1'
      push E
      call equalAE_F  # Same rest?
      if eq  # Yes
         ld E C  # Get result
         shl E 4  # Make short number
         or E CNT
         drop
         pop X
         ret
      end
      pop E
      ld E (E CDR)
   loop
   ld E Nil
   drop
   pop X
   ret

# (prior 'lst1 'lst2) -> lst | NIL
(code 'doPrior 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   link
   push E  # <L I> 'lst1'
   link
   ld E ((X CDR))  # Eval 'lst2'
   eval
   ld C (L I)  # Get 'lst1'
   drop
   pop X
   cmp C E  # First cell?
   if ne  # No
      do
         atom E  # More?
      while z  # Yes
         ld A (E CDR)
         cmp A C  # Found prior cell?
         jeq ret  # Yes
         ld E A
      loop
   end
   ld E Nil
   ret

# (length 'any) -> cnt | T
(code 'doLength 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   num E  # Number?
   if nz  # Yes
      ld A -2  # Scale
      jmp fmtNum0AE_E  # Calculate length
   end
   sym E  # Symbol?
   if z  # No (list)
      ld C E  # Keep list in C
      ld A ONE  # Init counter
      do
         or (E) 1  # Mark
         ld E (E CDR)  # Normal list?
         atom E
         if nz  # Yes
            do
               off (C) 1  # Unmark
               ld C (C CDR)
               atom C  # Done?
            until nz  # Yes
            ld E A  # Get count
            ret  # Return length
         end
         test (E) 1  # Detected circularity?
         if nz  # Yes
            do
               cmp C E  # Skip non-circular part
            while ne
               off (C) 1  # Unmark
               ld C (C CDR)
            loop
            do
               off (C) 1  # Unmark circular part
               ld C (C CDR)
               cmp C E  # Done?
            until eq  # Yes
            ld E TSym
            ret  # Return T
         end
         add A (hex "10")  # Increment counter
      loop
   end
   # Symbol
   cmp E Nil  # NIL?
   if eq  # Yes
      ld E ZERO
      ret
   end
   push X
   ld X (E TAIL)
   ld E ZERO  # Counter
   sym X  # External symbol?
   if z  # No
      call nameX_X  # Get name
      ld C 0
      do
         call symCharCX_FACX  # Next char
      while nz
         add E (hex "10")  # Increment counter
      loop
   end
   pop X
   ret

# (size 'any) -> cnt
(code 'doSize 2)
   push X
   ld X E
   ld E ((E CDR))  # E on arg
   eval  # Eval 'any'
   num E  # Number?
   if nz  # Yes
      cnt E  # Short number?
      if nz  # Yes
         ld C ONE  # Init counter
         shr E 3  # Normalize short, keep sign bit
         do
            shr E 8  # More bytes?
         while nz  # Yes
            add C (hex "10")  # Increment count
         loop
      else  # Big number
         off E SIGN  # Make positive
         ld C (hex "82")  # Count '8' significant bytes
         do
            ld A (E DIG)  # Keep digit
            ld E (E BIG)  # More cells?
            cnt E
         while z  # Yes
            add C (hex "80")  # Increment count by '8'
         loop
         shr E 4  # Normalize short
         add A A  # Get most significant bit of last digit
         addc E E  # Any significant bits in short number?
         if nz  # Yes
            do
               add C (hex "10")  # Increment count
               shr E 8  # More bytes?
            until z  # No
         end
      end
   else
      sym E  # List?
      if z  # Yes
         ld C ZERO  # Init count
         call sizeCE_C  # Count cell structures
      else  # Symbol
         cmp E Nil  # NIL?
         if eq  # Yes
            ld C ZERO  # Return zero
         else
            sym (E TAIL)  # External symbol?
            if nz  # Yes
               push Z
               call dbFetchEX
               ld X (E)  # Get value
               call binSizeX_A  # Calculate size
               add A (+ BLK 1)  # plus block overhead
               ld Z A  # Count in Z
               ld E (E TAIL)  # Get properties
               off E SYM  # Clear 'extern' tag
               do
                  atom E  # More properties?
               while z  # Yes
                  ld X (E)  # Next property
                  ld E (E CDR)
                  atom X  # Flag?
                  if nz  # Yes
                     call binSizeX_A  # Flag's size
                     add Z A  # Add to count
                     add Z 2  # Plus 2
                  else
                     push (X)  # Save value
                     ld X (X CDR)  # Get key
                     call binSizeX_A  # Calculate size
                     add Z A  # Add to count
                     pop X  # Retrieve value
                     call binSizeX_A  # Calculate size
                     add Z A  # Add to count
                  end
               loop
               ld C Z  # Get count
               shl C 4  # Make short number
               or C CNT
               pop Z
            else
               ld E (E TAIL)
               call nameE_E  # Get name
               cmp E ZERO  # Any?
               if eq  # No
                  ld C ZERO  # Return zero
               else
                  cnt E  # Short name?
                  if nz  # Yes
                     ld C ONE  # Init counter
                     shr E 4  # Normalize
                     do
                        shr E 8  # More bytes?
                     while nz  # Yes
                        add C (hex "10")  # Increment count
                     loop
                  else  # Long name
                     ld C (hex "82")  # Count '8' significant bytes
                     do
                        ld E (E BIG)  # More cells?
                        cnt E
                     while z  # Yes
                        add C (hex "80")  # Increment count
                     loop
                     shr E 4  # Any significant bits in short name?
                     if nz  # Yes
                        do
                           add C (hex "10")  # Increment count
                           shr E 8  # More bytes?
                        until z  # No
                     end
                  end
               end
            end
         end
      end
   end
   ld E C  # Get count
   pop X
   ret

(code 'sizeCE_C 0)
   push E  # Save list
   do
      add C (hex "10")  # Increment count
      atom (E)  # Is CAR a pair?
      if z  # Yes
         cmp S (StkLimit)  # Stack check
         jlt stkErr
         push E
         ld E (E)  # Count CAR
         call sizeCE_C
         pop E
      end
      or (E) 1  # Mark
      ld E (E CDR)  # Normal list?
      atom E
      if nz  # Yes
         pop E  # Get original list
         do
            off (E) 1  # Unmark
            ld E (E CDR)
            atom E  # Done?
         until nz  # Yes
         ret
      end
      test (E) 1  # Detected circularity?
      if nz  # Yes
         pop A  # Get original list
         do
            cmp A E  # Skip non-circular part
         while ne
            off (A) 1  # Unmark
            ld A (A CDR)
         loop
         do
            off (A) 1  # Unmark circular part
            ld A (A CDR)
            cmp A E  # Done?
         until eq  # Yes
         ret
      end
   loop

# (bytes 'any) -> cnt
(code 'doBytes 2)
   push X
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   ld X E
   call binSizeX_A  # Calculate size
   ld E A
   shl E 4  # Make short number
   or E CNT
   pop X
   ret

# (assoc 'any 'lst) -> lst
(code 'doAssoc 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval 'any'
   eval
   link
   push E  # <L I> 'any'
   link
   ld E ((X CDR))  # Eval 'lst'
   eval
   ld X E  # into X
   do  # assoc
      atom X  # Done?
      if z  # No
         atom (X)  # CAR atomic?
         if z  # No
            ld A (L I)  # Retrieve 'any'
            ld E ((X))  # and CAAR
            call equalAE_F  # Found?
            break eq  # Yes
         end
         ld X (X CDR)  # Next
      else
         ld E Nil  # Return NIL
         drop
         pop X
         ret
      end
   loop
   ld E (X)  # Return CAR
   drop
   pop X
   ret

# (rassoc 'any 'lst) -> lst
(code 'doRassoc 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval 'any'
   eval
   link
   push E  # <L I> 'any'
   link
   ld E ((X CDR))  # Eval 'lst'
   eval
   ld X E  # into X
   do  # rassoc
      atom X  # Done?
      if z  # No
         atom (X)  # CAR atomic?
         if z  # No
            ld A (L I)  # Retrieve 'any'
            ld E ((X) CDR)  # and CDAR
            call equalAE_F  # Found?
            break eq  # Yes
         end
         ld X (X CDR)  # Next
      else
         ld E Nil  # Return NIL
         drop
         pop X
         ret
      end
   loop
   ld E (X)  # Return CAR
   drop
   pop X
   ret

# (asoq 'any 'lst) -> lst
(code 'doAsoq 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval 'any'
   eval
   link
   push E  # <L I> 'any'
   link
   ld E ((X CDR))  # Eval 'lst'
   eval
   ld A (L I)  # Retrieve 'any'
   drop  # Clean up
   pop X
   do  # asoq
      atom E  # Done?
      jnz retNil  # Yes
      ld C (E)  # Get CAR
      atom C  # Atomic?
      if z  # No
         cmp A (C)  # Found?
         break eq  # Yes
      end
      ld E (E CDR)  # Next
   loop
   ld E C  # Return CAR
   ret

# (rank 'any 'lst ['flg]) -> lst
(code 'doRank 2)
   push X
   push Y
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   link
   push E  # <L II> 'any'
   ld X (X CDR)
   ld E (X)  # Eval next
   eval+
   push E  # <L I> 'lst'
   link
   ld E ((X CDR))  # Eval 'flg'
   eval
   ld X Nil  # Preload result
   ld Y (L I)  # Get 'lst' in Y
   atom Y  # Empty?
   if z  # No
      cmp E Nil  # 'flg'?
      if eq  # No
         do
            ld A ((Y))  # Compare CAAR
            ld E (L II)  # with 'any'
            call compareAE_F  # Greater?
            break gt  # Yes
            ld X Y  # Result so far
            ld Y (Y CDR)
            atom Y  # More?
         until nz  # No
      else
         do
            ld A ((Y))  # Compare CAAR
            ld E (L II)  # with 'any'
            call compareAE_F  # Less?
            break lt  # Yes
            ld X Y  # Result so far
            ld Y (Y CDR)
            atom Y  # More?
         until nz  # No
      end
   end
   ld E (X)  # Return CAR
   drop
   pop Y
   pop X
   ret

# (match 'lst1 'lst2) -> flg
(code 'doMatch 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval 'lst1'
   eval
   link
   push E  # <L II> Pattern
   ld E ((X CDR))  # Eval 'lst2'
   eval+
   push E  # <L I> Data
   link
   ld C (L II)  # Pattern
   call matchCE_F  # Match with data?
   ld E TSym  # Yes
   ldnz E Nil  # No
   drop
   pop X
   ret

: matchCE_F
   do
      atom C  # Pattern atomic?
      if nz  # Yes
         num C  # Symbol?
         if z  # Yes
            ld A (C TAIL)
            call firstByteA_B  # starting with "@"?
            cmp B (char "@")
            if eq  # Yes
               ld (C) E  # Set value to matched data
               ret  # Return 'z'
            end
         end
         ld A C  # Check if equal
         jmp equalAE_F
      end
      cmp S (StkLimit)  # Stack check
      jlt stkErr
      ld X (C)  # CAR of pattern
      num X
      if z
         sym X  # Symbolic?
         if nz  # Yes
            ld A (X TAIL)
            call firstByteA_B  # starting with "@"?
            cmp B (char "@")
            if eq  # Yes
               atom E  # Data atomic?
               if nz  # Yes
                  ld A (C CDR)  # CDR of pattern equal to data?
                  call equalAE_F
                  jnz ret  # No
                  ld (X) Nil  # Else clear value
                  ret  # Return 'z'
               end
               push C  # Save pattern
               push E  # and Data
               ld C (C CDR)  # Get CDRs
               ld E (E CDR)
               call matchCE_F  # Match?
               pop E
               pop C
               if eq  # Yes
                  call cons_A  # Cons CAR of data with NIL
                  ld (A) (E)
                  ld (A CDR) Nil
                  ld ((C)) A  # Set value
                  eq
                  ret
               end
               push C  # Save pattern
               push E  # and Data
               ld C (C CDR)  # CDR of pattern
               call matchCE_F  # Match with data?
               pop E
               pop C
               if eq  # Yes
                  ld ((C)) Nil  # Set value to NIL
                  ret  # Return 'z'
               end
               push C  # Save pattern
               push E  # and Data
               ld E (E CDR)  # CDR of data
               call matchCE_F  # Match with pattern?
               pop E
               pop C
               if eq  # Yes
                  ld X (C)  # Pattern symbol
                  call cons_A  # Cons CAR of data into value
                  ld (A) (E)
                  ld (A CDR) (X)
                  ld (X) A  # Set value
                  eq
                  ret
               end
            end
         end
      end
      atom E  # Data atomic?
      jnz ret  # Yes
      push (C CDR)  # Save rests
      push (E CDR)
      ld C (C)  # Get CARs
      ld E (E)
      call matchCE_F  # Match?
      pop E
      pop C
      jnz ret  # No
   loop

# (fill 'any ['sym|lst]) -> any
(code 'doFill 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval 'any'
   eval
   link
   push E  # <L II> Pattern
   ld E ((X CDR))  # Eval 'sym|lst'
   eval+
   push E  # <L I> 'sym|lst'
   link
   ld X E  # in X
   ld E (L II)  # Fill pattern
   call fillE_FE
   drop
   pop X
   ret

: fillE_FE
   num E  # Data numeric?
   jnz ret  # Return 'nz'
   sym E  # Data symbolic?
   if nz  # Yes
      cmp E (E)  # Auto-quoting?
      jeq retGt  # Yes
      cmp X Nil  # 'sym|lst'?
      if eq  # No
         cmp E At  # '@'?
         jeq retGt  # Return 'nz'
         ld A (E TAIL)
         call firstByteA_B  # starting with "@"?
         cmp B (char "@")
         if eq  # Yes
            ld E (E)  # Return 'z'
         end
         ret  # Else 'nz'
      end
      ld C X  # 'memq'
      do
         atom C  # List?
      while z  # Yes
         cmp E (C)  # Member?
         if eq  # Yes
            ld E (E)  # Return 'z'
            ret
         end
         ld C (C CDR)  # Next element
      loop
      cmp E C  # Same?
      if eq  # Yes
         ld E (E)  # Return 'z'
      end
      ret  # Else 'nz'
   end
   cmp S (StkLimit)  # Stack check
   jlt stkErr
   push E  # <S> Save
   ld E (E)  # Recurse on CAR
   cmp E Up  # Expand expression?
   if eq  # Yes
      pop E  # Get pattern
      ld E (E CDR)  # Skip '^'
      push (E CDR)  # Save rest
      ld E (E)  # Eval expression
      eval
      atom E  # List?
      if nz  # No
         pop E  # Recurse on rest
         call fillE_FE
         eq  # Set modified
         ret
      end
      pop C  # Get pattern
      link
      push E  # <L I> Result
      link
      ld E C  # Recurse on rest
      call fillE_FE
      ld C (L I)  # Result
      do
         atom (C CDR)  # Find last cell
      while z
         ld C (C CDR)
      loop
      ld (C CDR) E  # Set rest
      ld E (L I)  # Get result
      drop
      eq  # Modified
      ret
   end
   call fillE_FE  # Modified?
   if z  # Yes
      pop C  # Get pattern
      link
      push E  # <L I> Modified CAR
      link
      ld E (C CDR)  # Recurse on CDR
      call fillE_FE
      call consE_A  # Cons result
      ld (A) (L I)
      ld (A CDR) E
      ld E A
      drop
      eq  # Modified
      ret
   end
   ld E ((S) CDR)  # Recurse on CDR
   call fillE_FE  # Modified?
   if z  # Yes
      call consE_A  # Cons result
      pop C
      ld (A) (C)  # Unmodified CAR
      ld (A CDR) E  # Modified CDR
      ld E A
      eq  # Modified
      ret
   end
   pop E  # Return 'nz'
   ret

### Declarative Programming ###
(code 'unifyCEYZ_F 0)
10 num Y  # x1 symbolic?
   if z
      sym Y
      if nz  # Yes
         ld A (Y TAIL)  # x1
         call firstByteA_B  # starting with "@"?
         cmp B (char "@")
         if eq  # Yes
            ld X ((Penv))  # Get pilog environment
            do
               ld A (X)  # car(x)
               atom A  # List?
            while z  # Yes
               ld A (A)  # caar(x)
               cmp C (A)  # n1 == caaar(x)?
               if eq  # Yes
                  cmp Y (A CDR)  # x1 == cdaar(x)?
                  if eq  # Yes
                     ld A ((X) CDR)
                     ld C (A)  # n1 = cadar(x)
                     ld Y (A CDR)  # x1 = cddar(x)
                     jmp 10
                  end
               end
               ld X (X CDR)
            loop
         end
      end
   end
20 num Z  # x2 symbolic?
   if z
      sym Z
      if nz  # Yes
         ld A (Z TAIL)  # x2
         call firstByteA_B  # starting with "@"?
         cmp B (char "@")
         if eq  # Yes
            ld X ((Penv))  # Get pilog environment
            do
               ld A (X)  # car(x)
               atom A  # List?
            while z  # Yes
               ld A (A)  # caar(x)
               cmp E (A)  # n2 == caaar(x)?
               if eq  # Yes
                  cmp Z (A CDR)  # x2 == cdaar(x)?
                  if eq  # Yes
                     ld A ((X) CDR)
                     ld E (A)  # n2 = cadar(x)
                     ld Z (A CDR)  # x2 = cddar(x)
                     jmp 20
                  end
               end
               ld X (X CDR)
            loop
         end
      end
   end
   cmp C E  # n1 == n2?
   if eq  # Yes
      ld A Y  # x1
      push E
      ld E Z  # x2
      call equalAE_F  # Equal?
      pop E
      jeq ret  # Yes
   end
   num Y  # x1 symbolic?
   if z
      sym Y
      if nz  # Yes
         ld A (Y TAIL)  # x1
         call firstByteA_B  # starting with "@"?
         cmp B (char "@")
         if eq  # Yes
            cmp Y At  # x1 == @?
            if ne  # No
               call cons_A  # (n1 . x1)
               ld (A) C
               ld (A CDR) Y
               call consA_C  # (n2 . x2)
               ld (C) E
               ld (C CDR) Z
               call consAC_E  # ((n1 . x1) . (n2 . x2))
               ld (E) A
               ld (E CDR) C
               ld X (Penv)  # Concat to pilog environment
               call consE_A
               ld (A) E
               ld (A CDR) (X)
               ld (X) A  # Store in environment
            end
            eq
            ret
         end
      end
   end
   num Z  # x2 symbolic?
   if z
      sym Z
      if nz  # Yes
         ld A (Z TAIL)  # x2
         call firstByteA_B  # starting with "@"?
         cmp B (char "@")
         if eq  # Yes
            cmp Z At  # x2 == @?
            if ne  # No
               call cons_A  # (n1 . x1)
               ld (A) C
               ld (A CDR) Y
               call consA_C  # (n2 . x2)
               ld (C) E
               ld (C CDR) Z
               call consAC_E  # ((n2 . x2) . (n1 . x1))
               ld (E CDR) A
               ld (E) C
               ld X (Penv)  # Concat to pilog environment
               call consE_A
               ld (A) E
               ld (A CDR) (X)
               ld (X) A  # Store in environment
            end
            eq
            ret
         end
      end
   end
   atom Y  # x1 atomic?
   if z  # No
      atom Z  # x2 atomic?
      if z  # No
         cmp S (StkLimit)  # Stack check
         jlt stkErr
         push ((Penv))  # Save pilog environment
         push C  # and parameters
         push E
         push Y
         push Z
         ld Y (Y)  # car(x1)
         ld Z (Z)  # car(x2)
         call unifyCEYZ_F  # Match?
         pop Z
         pop Y
         pop E
         pop C
         if eq  # Yes
            ld Y (Y CDR)  # cdr(x1)
            ld Z (Z CDR)  # cdr(x2)
            call unifyCEYZ_F  # Match?
            if eq  # Yes
               lea S (S I)  # Drop pilog environment
               ret  # 'z'
            end
         end
         pop ((Penv))  # Restore pilog environment
         ret  # nz
      end
   end
   ld A Y  # Compare x1 and x2
   ld E Z
   jmp equalAE_F

# (prove 'lst ['lst]) -> lst
(code 'doProve 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   atom E  # Atomic?
   if nz  # Yes
      pop X
      ld E Nil  # Return NIL
      ret
   end
   push Y
   push Z
   push (Penv)  # Save pilog environment pointers
   push (Pnl)
   link
   push (At)  # <L (+ IX I)> @
   push E  # <L IX> q
   ld Z E  # Keep in Z
   ld X (X CDR)  # Second arg
   ld E (X)  # Eval debug list
   eval+
   push E  # <L VIII> dbg
   ld Y ((Z))  # env = caar(q)
   push Y  # <L VII> env
   ld (Penv) S  # Set pilog environment pointer
   ld (Z) ((Z) CDR)  # car(q) = cdar(q)
   push (Y)  # <L VI> n
   ld Y (Y CDR)
   push (Y)  # <L V> nl
   ld (Pnl) S  # Set pointer
   ld Y (Y CDR)
   push (Y)  # <L IV> alt
   ld Y (Y CDR)
   push (Y)  # <L III> tp1
   ld Y (Y CDR)
   push (Y)  # <L II> tp2
   ld Y (Y CDR)
   push Nil  # <L I> e
   link
   ld (L VII) Y  # Set env
   do
      atom (L III)  # tp1?
      jz 10  # Yes
      atom (L II)  # or tp2?
   while z  # Yes
10    atom (L IV)  # alt?
      if z  # Yes
         ld (L I) (L VII)  # e = env
         ld C ((L V))  # car(nl)
         ld Y (((L III)) CDR)  # cdar(tp1)
         ld E (L VI)  # n
         ld Z (((L IV)))  # caar(alt)
         call unifyCEYZ_F  # Match?
         if ne  # No
            ld X ((L IV) CDR)  # alt = cdr(alt)
            ld (L IV) X
            atom X  # Atomic?
            if nz  # Yes
               ld X (((L IX)))  # env = caar(q)
               ld ((L IX)) (((L IX)) CDR)  # car(q) = cdar(q)
               ld (L VI) (X)  # n = car(env)
               ld X (X CDR)  # env = cdr(env)
               ld (L V) (X)  # nl = car(env)
               ld X (X CDR)  # env = cdr(env)
               ld (L IV) (X)  # alt = car(env)
               ld X (X CDR)  # env = cdr(env)
               ld (L III) (X)  # tp1 = car(env)
               ld X (X CDR)  # env = cdr(env)
               ld (L II) (X)  # tp2 = car(env)
               ld X (X CDR)  # env = cdr(env)
               ld (L VII) X  # Set env
            end
         else
            atom (L VIII)  # dbg?
            if z  # Yes
               ld A (((L III)))  # memq(caar(tp1), dbg)
               ld E (L VIII)
               do
                  cmp A (E)  # memq?
                  if eq  # Yes
                     ld C TSym  # get(caar(tp1), T)
                     ld E (((L III)))
                     call getEC_E
                     ld X E
                     ld C 0  # Index count
                     do
                        inc C  # Increment
                        ld A ((L IV))  # Found car(alt)?
                        ld E (X)
                        ld X (X CDR)
                        call equalAE_F
                     until eq  # Yes
                     ld A C
                     call outWordA  # Print level number
                     call space
                     ld E ((L III))  # car(tp1)
                     call uniFillE_E  # Fill with values
                     call printE_E  # and print
                     call newline
                     break T
                  end
                  ld E (E CDR)  # Next debug symbol
                  atom E  # Any?
               until nz  # No
            end
            atom ((L IV) CDR)  # cdr(alt)?
            if z  # Yes
               call cons_A  # cons(tp2, e)
               ld (A) (L II)
               ld (A CDR) (L I)
               call consA_C  # cons(tp1, @)
               ld (C) (L III)
               ld (C CDR) A
               call consC_A  # cons(cdr(alt), @)
               ld (A) ((L IV) CDR)
               ld (A CDR) C
               call consA_C  # cons(nl, @)
               ld (C) (L V)
               ld (C CDR) A
               call consC_A  # cons(n, @)
               ld (A) (L VI)
               ld (A CDR) C
               call consA_C  # cons(@, car(q))
               ld (C) A
               ld (C CDR) ((L IX))
               ld ((L IX)) C  # -> car(q)
            end
            ld C (L VI)  # n
            call cons_A  # cons(n, nl)
            ld (A) C
            ld (A CDR) (L V)
            ld (L V) A  # -> nl
            add C (hex "10")  # Increment
            ld (L VI) C  # -> n
            call cons_A  # cons(cdr(tp1), tp2)
            ld (A) ((L III) CDR)
            ld (A CDR) (L II)
            ld (L II) A  # -> tp2
            ld (L III) (((L IV)) CDR)  # cdar(alt) -> tp1
            ld (L IV) Nil  # alt = NIL
         end
         continue T
      end
      ld X (L III)  # tp1?
      atom X
      if nz  # No
         ld C (L II)  # tp2
         ld (L III) (C)  # tp1 = car(tp2)
         ld (L II) (C CDR)  # tp2 = cdr(tp2)
         ld (L V) ((L V) CDR)  # nl = cdr(nl)
         continue T
      end
      ld Y (X)  # car(tp1)
      cmp Y TSym  # car(tp1) == T?
      if eq
         do
            ld C ((L IX))  # car(q)
            atom C  # Any?
         while z  # Yes
            cmp ((C)) ((L V))  # caaar(q) >= car(nl)?
         while ge  # Yes
            ld ((L IX)) (C CDR)  # car(q) = cdar(q)
         loop
         ld (L III) (X CDR)  # tp1 = cdr(tp1)
         continue T
      end
      num (Y)  # caar(tp1) numeric?
      if nz  # Yes
         ld Z (Y CDR)  # Run Lisp body
         prog Z
         ld (L I) E  # -> e
         ld C (Y)  # Get count
         shr C 4  # Normalize short
         ld A (L V)  # nl
         do
            dec C  # Decrement
         while nsz
            ld A (A CDR)  # Skip
         loop
         call cons_C  # cons(car(A), nl)
         ld (C) (A)
         ld (C CDR) (L V)
         ld (L V) C  # -> nl
         call cons_C  # cons(cdr(tp1), tp2)
         ld (C) (X CDR)
         ld (C CDR) (L II)
         ld (L II) C  # -> tp2
         ld (L III) (L I)  # tp1 = e
         continue T
      end
      ld E (Y)  # caar(tp1)
      cmp E Up  # Lisp call?
      if eq  # Yes
         ld Z ((Y CDR) CDR)  # Run Lisp body
         prog Z
         ld (L I) E  # -> e
         cmp E Nil  # Any?
         jeq 20  # No
         ld C ((L V))  # car(nl)
         ld Y ((Y CDR))  # cadar(tp1)
         ld E C  # car(nl)
         ld Z (L I)  # e
         call unifyCEYZ_F  # Match?
         jne 20  # No
         ld (L III) ((L III) CDR)  # tp1 = cdr(tp1)
         continue T
      end
      ld C TSym  # get(caar(tp1), T)
      call getEC_E
      ld (L IV) E  # -> alt
      atom E  # Atomic?
      if nz  # Yes
20       ld X (((L IX)))  # env = caar(q)
         ld ((L IX)) (((L IX)) CDR)  # car(q) = cdar(q)
         ld (L VI) (X)  # n = car(env)
         ld X (X CDR)  # env = cdr(env)
         ld (L V) (X)  # nl = car(env)
         ld X (X CDR)  # env = cdr(env)
         ld (L IV) (X)  # alt = car(env)
         ld X (X CDR)  # env = cdr(env)
         ld (L III) (X)  # tp1 = car(env)
         ld X (X CDR)  # env = cdr(env)
         ld (L II) (X)  # tp2 = car(env)
         ld X (X CDR)  # env = cdr(env)
         ld (L VII) X  # Set env
      end
   loop
   ld (L I) Nil  # e = NIL
   ld X (L VII)  # env
   do
      atom (X CDR)
   while z
      ld Y ((X))  # Next binding
      cmp (Y) ZERO  # Top?
      if eq  # Yes
         ld C ZERO  # Look up
         ld E (Y CDR)
         call lookupCE_E
         call consE_A  # Cons with variable
         ld (A) (Y CDR)
         ld (A CDR) E
         call consA_E  # and e
         ld (E) A
         ld (E CDR) (L I)
         ld (L I) E  # -> e
      end
      ld X (X CDR)
   loop
   ld (At) (L (+ IX I))  # Restore '@'
   ld E (L I)  # Get e
   atom E  # Atomic?
   if nz  # Yes
      atom (L VII)  # 'env' atomic?
      ld E Nil
      ldz E TSym  # No
   end
   drop
   pop (Pnl)  # Restore pilog environment pointers
   pop (Penv)
   pop Z
   pop Y
   pop X
   ret

(code 'lupCE_E 0)  # Z
   cmp S (StkLimit)  # Stack check
   jlt stkErr
   num E  # x symbolic?
   if z
      sym E
      if nz  # Yes
         ld A (E TAIL)  # x
         call firstByteA_B  # starting with "@"?
         cmp B (char "@")
         if eq  # Yes
            ld Z ((Penv))  # Get pilog environment
            do
               ld A (Z)  # car(y)
               atom A  # List?
            while z  # Yes
               ld A (A)  # caar(y)
               cmp C (A)  # n == caaar(y)?
               if eq  # Yes
                  cmp E (A CDR)  # x == cdaar(y)?
                  if eq  # Yes
                     ld A ((Z) CDR)
                     ld C (A)  # n = cadar(y)
                     ld E (A CDR)  # x = cddar(y)
                     jmp lupCE_E
                  end
               end
               ld Z (Z CDR)
            loop
         end
      end
   end
   atom E  # Atomic?
   if z  # No
      push C  # Save parameters
      push E
      ld E (E)  # lup(n, car(x))
      call lupCE_E
      pop A
      pop C
      link
      push E  # Save
      link
      ld E (A CDR)  # lup(n, cdr(x))
      call lupCE_E
      call consE_A  # Cons
      ld (A) (L I)
      ld (A CDR) E
      ld E A
      drop
   end
   ret

(code 'lookupCE_E 0)  # Z
   call lupCE_E
   num E  # Symbolic?
   if z
      sym E
      if nz  # Yes
         ld A (E TAIL)
         call firstByteA_B  # starting with "@"?
         cmp B (char "@")
         jeq  retNil # Yes
      end
   end
   ret

(code 'uniFillE_E 0)
   num E  # Number?
   if z  # No
      sym E  # Symbol?
      if nz  # Yes
         ld C (((Pnl)))  # Get Env
         jmp lupCE_E  # Look up
      end
      cmp S (StkLimit)  # Stack check
      jlt stkErr
      push E  # Save list
      ld E (E)  # Recurse on CAR
      call uniFillE_E
      pop A  # Get list
      link
      push E  # Save result
      link
      ld E (A CDR)  # Recurse on CDR
      call uniFillE_E
      call consE_A  # Return cell
      ld (A) (L I)
      ld (A CDR) E
      ld E A
      drop
   end
   ret

# (-> any [cnt]) -> any
(code 'doArrow 2)
   push Z
   ld E (E CDR)  # E on args
   ld C ((Pnl))  # Environments
   ld A (E CDR)
   cnt (A)  # 'cnt' arg?
   if nz  # Yes
      ld A (A)  # Get count
      shr A 4  # Normalize short
      do
         dec A  # Decrement
      while nsz
         ld C (C CDR)  # Skip
      loop
   end
   ld C (C)  # Get env
   ld E (E)  # 'sym'
   call lookupCE_E
   pop Z
   ret

# (unify 'any) -> lst
(code 'doUnify 2)
   push X
   push Y
   push Z
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   link
   push E  # Save 'any'
   link
   ld A ((Pnl))  # Environments
   ld C ((A CDR))  # Second environment
   ld E (A)  # First environment
   ld Y (L I)  # 'any'
   ld Z Y  # 'any'
   call unifyCEYZ_F  # Match?
   ld E Nil
   if eq  # Yes
      ld E ((Penv))
   end
   drop
   pop Z
   pop Y
   pop X
   ret

# (group 'lst) -> lst
(code 'doGroup 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval 'lst'
   atom E  # Atomic?
   jnz retNil  # Yes
   push X
   push Y
   link
   push E  # Save 'lst'
   link
   ld X E  # in X
   call cons_A  # Build first tail cell
   ld (A) ((X) CDR)  # First value
   ld (A CDR) Nil
   call consA_C  # Link to tail cell
   ld (C) A
   ld (C CDR) A
   call consC_A  # Build first list
   ld (A) ((X))  # from first key
   ld (A CDR) C
   call consA_C  # Initial list
   ld (C) A
   ld (C CDR) Nil
   tuck C  # <L I> Result
   link
   do
      ld X (X CDR)
      atom X  # More cells?
   while z  # Yes
      call cons_C  # New cell
      ld (C) ((X) CDR)  # Value
      ld (C CDR) Nil
      ld Y (L I)  # Result so far
      do
         ld A ((Y))  # Compare keys
         ld E ((X))
         call equalAE_F  # Same?
         if eq  # Yes
            ld Y ((Y) CDR)  # Get tail link
            ld ((Y) CDR) C  # Concatenate new cell to tail
            ld (Y) C  # New tail
            break T
         end
         atom (Y CDR)  # Done?
         if nz  # Yes
            call consC_A  # Link to tail cell
            ld (A) C
            ld (A CDR) C
            call consA_C  # Build list
            ld (C) ((X))  # from key
            ld (C CDR) A
            call consC_A  # New list
            ld (A) C
            ld (A CDR) Nil
            ld (Y CDR) A  # Concatenate to result
            break T
         end
         ld Y (Y CDR)
      loop
   loop
   ld E (L I)  # Get result
   ld C E  # Remove tail links
   do
      ld A (C)
      ld (A CDR) ((A CDR) CDR)
      ld C (C CDR)  # Done?
      atom C
   until nz  # Yes
   drop
   pop Y
   pop X
   ret

## List Merge Sort: Bill McDaniel, DDJ Jun99 ###
# (sort 'lst ['fun]) -> lst
(code 'doSort 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval 'lst'
   eval
   atom E  # List?
   if z  # Yes
      push Z
      link
      push E  # Save 'lst'
      ld E ((Y CDR))  # Eval 'fun'
      eval+
      ld A Nil  # Init local elements
      cmp E Nil  # User function?
      if eq  # No
         ld Z cmpDfltA_F  # Use default sort function
         xchg E (S)  # <L VII> out[1]
      else
         ld Z cmpUserAX_F  # Use user supplied sort function
         xchg E (S)  # 'fun'
         push A
         push A  # <L VIII> Apply args
         push A  # <L VII>  out[1]
      end
      push E  # <L VI>  out[0] 'lst'
      push A  # <L V>   in[1]
      push A  # <L IV>  in[0]
      push A  # <L III> last[1]
      push A  # <L II>  last[0]
      push A  # <L I>   p
      link
      push A  # <L -I> tail[1]
      push A  # <L -II> tail[0]
      do
         ld (L IV) (L VI)  # in[0] = out[0]
         ld (L V) (L VII)  # in[1] = out[1]
         lea Y (L IV)  # &in[0]
         atom (L V)  # in[1] list?
         if z  # Yes
            ld A Y  # in
            call (Z)  # Less?
            if ge  # No
               lea Y (L V)  # &in[1]
            end
         end
         ld A (Y)  # p = in[i]
         ld (L I) A
         atom A  # List?
         if z  # Yes
            ld (Y) (A CDR)  # in[i] = cdr(in[i])
         end
         ld (L VI) A  # out[0] = p
         lea (L -II) (A CDR)  # tail[0] = &cdr(p)
         ld (L III) (L VI)  # last[1] = out[0]
         ld (A CDR) Nil  # cdr(p) = Nil
         ld (L VII) Nil  # out[1] = Nil
         lea (L -I) (L VII)  # tail[1] = &out[1]
         do
            atom (L V)  # in[1] atomic?
            if nz  # Yes
               atom (L IV)  # in[0] also atomic?
               break nz  # Yes
               ld Y (L IV)  # p = in[0]
               ld (L I) Y
               atom Y  # List?
               if z  # Yes
                  ld (L IV) (Y CDR)  # in[0] = cdr(in[0])
               end
               ld (L II) Y  # last[0] = p
               lea A (L II)  # last
               call (Z)  # Less?
               if lt  # Yes
                  xchg (L -I) (L -II)  # Exchange tail[0] and tail[1]
               end
            else
               atom (L IV)  # in[0] atomic?
               if nz  # Yes
                  atom (L V)  # in[1] also atomic?
                  break nz  # Yes
                  ld Y (L V)  # p = in[1]
                  ld (L I) Y
                  ld (L II) Y  # last[0] = p
                  ld (L V) (Y CDR)  # in[1] = cdr(in[1])
                  lea A (L II)  # last
                  call (Z)  # Less?
                  if lt  # Yes
                     xchg (L -I) (L -II)  # Exchange tail[0] and tail[1]
                  end
               else  # Both in[0] and in[1] are lists
                  lea A (L II)  # last
                  ld (A) (L IV)  # last[0] = in[0]
                  call (Z)  # Less?
                  if lt  # Yes
                     lea A (L II)  # last
                     ld (A) (L V)  # last[0] = in[1]
                     call (Z)  # Less?
                     if ge  # No
                        ld Y (L V)  # p = in[1]
                        ld (L I) Y
                        ld (L V) (Y CDR)  # in[1] = cdr(in[1])
                     else
                        lea A (L IV)  # in
                        call (Z)  # Less?
                        if lt  # Yes
                           ld Y (L IV)  # p = in[0]
                           ld (L I) Y
                           ld (L IV) (Y CDR)  # in[0] = cdr(in[0])
                        else
                           ld Y (L V)  # p = in[1]
                           ld (L I) Y
                           ld (L V) (Y CDR)  # in[1] = cdr(in[1])
                        end
                        xchg (L -I) (L -II)  # Exchange tail[0] and tail[1]
                     end
                  else
                     lea A (L II)  # last
                     ld (A) (L V)  # last[0] = in[1]
                     call (Z)  # Less?
                     if lt  # Yes
                        ld Y (L IV)  # p = in[0]
                        ld (L I) Y
                        ld (L IV) (Y CDR)  # in[0] = cdr(in[0])
                     else
                        lea A (L IV)  # in
                        call (Z)  # Less?
                        if lt  # Yes
                           ld Y (L IV)  # p = in[0]
                           ld (L I) Y
                           ld (L IV) (Y CDR)  # in[0] = cdr(in[0])
                        else
                           ld Y (L V)  # p = in[1]
                           ld (L I) Y
                           ld (L V) (Y CDR)  # in[1] = cdr(in[1])
                        end
                     end
                  end
               end
            end
            ld ((L -II)) Y  # *tail[0] = p
            lea (L -II) (Y CDR)  # tail[0] = &cdr(p)
            ld (Y CDR) Nil  # cdr(p) = Nil
            ld (L III) Y  # last[1] = p
         loop
         atom (L VII)  # out[1]
      until nz
      ld E (L VI)  # Return out[0]
      drop
      pop Z
   end
   pop Y
   pop X
   ret

(code 'cmpDfltA_F 0)
   ld E ((A I))  # Get CAR of second item
   ld A ((A))  # and CAR of first item
   jmp compareAE_F  # Build-in compare function

(code 'cmpUserAX_F 0)
   push Y
   push Z
   lea Z (L VIII)  # Point Z to apply args
   ld (Z) ((A I))  # Copy CAR of second item
   ld (Z I) ((A))  # and CAR of first item
   lea Y (Z II)  # Point Y to 'fun'
   call applyXYZ_E  # Apply
   cmp E Nil  # Check result
   if ne
      lt  # Return "less"
   end
   pop Z
   pop Y
   ret

# vi:et:ts=3:sw=3
