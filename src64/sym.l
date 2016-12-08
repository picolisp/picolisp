# 24nov16abu
# (c) Software Lab. Alexander Burger

### Compare long names ###
(code 'cmpLongAX_F 0)
   push X  # Keep X
   do
      cmp (A DIG) (X DIG)  # Equal?
      if ne  # No
         pop X
         ret
      end
      ld A (A BIG)
      ld X (X BIG)
      big A  # A on last digit?
      if z  # Yes
         big X  # X also on last digit?
         if nz  # No
            lt  # A is smaller
            pop X
            ret
         end
         cmp A X  # Equal?
         pop X
         ret
      end
      cnt X  # A not on last digit. X on last digit?
   until nz  # Yes
   gt  # A is greater
   pop X
   ret

### Is symbol interned? ###
# E symbol
# X name
# Y tree
(code 'isInternEXY_F 0)
   cnt X  # Short name?
   if nz  # Yes
      ld Y (Y)  # Y on first tree
      do
         atom Y  # Empty?
         jnz ret  # Return NO
         ld A ((Y) TAIL)  # Next symbol
         call nameA_A  # Get name
         cmp A X  # Equal?
      while ne  # No
         if lt
            ld Y ((Y CDR) CDR)  # Symbol is smaller
         else
            ld Y ((Y CDR))  # Symbol is greater
         end
      loop
      cmp E (Y)  # Same Symbol?
      ret  # Return YES or NO
   end
   # Long name
   ld Y (Y CDR)  # Y on second tree
   do
      atom Y  # Empty?
      jnz ret  # Return NO
      ld A ((Y) TAIL)  # Next symbol
      call nameA_A  # Get name
      call cmpLongAX_F  # Equal?
   while ne  # No
      if lt
         ld Y ((Y CDR) CDR)  # Symbol is smaller
      else
         ld Y ((Y CDR))  # Symbol is greater
      end
   loop
   cmp E (Y)  # Same Symbol?
   ret   # Return YES or NO

### Intern a symbol/name ###
# E symbol
# X name
# Y tree
(code 'internEXY_FE 0)
   cnt X  # Short name?
   if nz  # Yes
      ld C (Y)  # C on first tree
      atom C  # Empty?
      if nz  # Yes
         null E  # New symbol?
         if z
            call consSymX_E  # Yes
         end
         call consE_X  # Cons into a new node
         ld (X) E
         ld (X CDR) Nil
         ld (Y) X  # Store in first tree
         lt  # Return new symbol
         ret
      end
      do
         ld A ((C) TAIL)  # Next symbol
         call nameA_A  # Get name
         cmp A X  # Equal?
         if eq  # Yes
            ld E (C)  # Found symbol
            ret
         end
         if lt  # Symbol is smaller
            atom (C CDR)  # Already has link?
            if nz  # No
               null E  # New symbol?
               if z
                  call consSymX_E  # Yes
               end
               call consE_A  # Cons into a new node
               ld (A) E
               ld (A CDR) Nil
               call consA_X  # Cons into a new link
               ld (X) Nil
               ld (X CDR) A
               ld (C CDR) X
               lt  # Return new symbol
               ret
            end
            ld C (C CDR)
            atom (C CDR)  # CDR of link?
            ldz C (C CDR)  # Yes: Get CDR of link in C
            if nz  # No
               null E  # New symbol?
               if z
                  call consSymX_E  # Yes
               end
               call consE_A  # Cons into a new node
               ld (A) E
               ld (A CDR) Nil
               ld (C CDR) A  # Store in CDR of link
               lt  # Return new symbol
               ret
            end
         else  # Symbol is greater
            atom (C CDR)  # Already has link?
            if nz  # No
               null E  # New symbol?
               if z
                  call consSymX_E  # Yes
               end
               call consE_A  # Cons into a new node
               ld (A) E
               ld (A CDR) Nil
               call consA_X  # Cons into a new link
               ld (X) A
               ld (X CDR) Nil
               ld (C CDR) X
               lt  # Return new symbol
               ret
            end
            ld C (C CDR)
            atom (C)  # CAR of link?
            ldz C (C)  # Yes: Get CAR of link in C
            if nz  # No
               null E  # New symbol?
               if z
                  call consSymX_E  # Yes
               end
               call consE_A  # Cons into a new node
               ld (A) E
               ld (A CDR) Nil
               ld (C) A  # Store in CAR of link
               lt  # Return new symbol
               ret
            end
         end
      loop
   end
   # Long name
   ld C (Y CDR)  # C on second tree
   atom C  # Empty?
   if nz  # Yes
      null E  # New symbol?
      if z
         call consSymX_E  # Yes
      end
      call consE_X  # Cons into a new node
      ld (X) E
      ld (X CDR) Nil
      ld (Y CDR) X  # Store in second tree
      lt  # Return new symbol
      ret
   end
   do
      ld A ((C) TAIL)  # Next symbol
      call nameA_A  # Get name
      call cmpLongAX_F  # Equal?
      if eq  # Yes
         ld E (C)  # Found symbol
         ret
      end
      if lt  # Symbol is smaller
         atom (C CDR)  # Already has link?
         if nz  # No
            null E  # New symbol?
            if z
               call consSymX_E  # Yes
            end
            call consE_A  # Cons into a new node
            ld (A) E
            ld (A CDR) Nil
            call consA_X  # Cons into a new link
            ld (X) Nil
            ld (X CDR) A
            ld (C CDR) X
            lt  # Return new symbol
            ret
         end
         ld C (C CDR)
         atom (C CDR)  # CDR of link?
         ldz C (C CDR)  # Yes: Get CDR of link in C
         if nz  # No
            null E  # New symbol?
            if z
               call consSymX_E  # Yes
            end
            call consE_A  # Cons into a new node
            ld (A) E
            ld (A CDR) Nil
            ld (C CDR) A  # Store in CDR of link
            lt  # Return new symbol
            ret
         end
      else  # Symbol is greater
         atom (C CDR)  # Already has link?
         if nz  # No
            null E  # New symbol?
            if z
               call consSymX_E  # Yes
            end
            call consE_A  # Cons into a new node
            ld (A) E
            ld (A CDR) Nil
            call consA_X  # Cons into a new link
            ld (X) A
            ld (X CDR) Nil
            ld (C CDR) X
            lt  # Return new symbol
            ret
         end
         ld C (C CDR)
         atom (C)  # CAR of link?
         ldz C (C)  # Yes: Get CAR of link in C
         if nz  # No
            null E  # New symbol?
            if z
               call consSymX_E  # Yes
            end
            call consE_A  # Cons into a new node
            ld (A) E
            ld (A CDR) Nil
            ld (C) A  # Store in CAR of link
            lt  # Return new symbol
            ret
         end
      end
   loop

(code 'findSymX_E 0)  # Y
   ld E 0  # No symbol yet
   ld Y ((EnvIntern))
   call internEXY_FE  # New internal symbol?
   jge Ret  # No
   ld (E) Nil  # Init to 'NIL'
   ret

# X name
(code 'externX_E 0)  # C
   push Y
   call need3  # Reserve 3 cells
   ld Y (Extern)  # Y on external symbol tree
   ld C 0  # Level counter
   do
      inc C  # Next level
      ld E (Y)  # Next symbol
      ld A (E TAIL)  # Get name
      call nameA_A
      and A (hex "3FFFFFFFFFFFFFF7")  # Mask status and extern bits
      cmp A X  # Equal to key?
   while ne  # No
      if lt  # Symbol is smaller
         ld E (Y CDR)  # Get link cell
         atom E  # Already has link?
         if z  # Yes
            ld Y (E CDR)  # Right node?
            atom Y
            continue z  # Yes
         else
            call cons_E  # New link cell
            ld (Y CDR) E
            ld (E) Nil
         end
         call cons_A  # New right node
         ld (E CDR) A
      else  # Symbol is greater
         ld E (Y CDR)  # Get link cell
         atom E  # Already has link?
         if z  # Yes
            ld Y (E)  # Left node?
            atom Y
            continue z  # Yes
         else
            call cons_E  # New link cell
            ld (Y CDR) E
            ld (E CDR) Nil
         end
         call cons_A  # New left node
         ld (E) A
      end
      inc (ExtCnt)  # Increment count
      call cons_E  # New symbol
      ld (E) X  # Set name
      or (E) SYM  # Set 'extern' tag
      or E SYM  # Make symbol
      ld (A) E  # Store in node
      ld (A CDR) Nil
      ld (E) Nil  # Init to 'NIL'
      break T
   loop
   ld A 1  # 2 ** (C/2)
   shr C 1
   shl A C
   cmp A (ExtCnt)  # Tree too deep?
   if gt  # Yes
      ld Y (Extern)  # Y on external symbol tree again
      ld A (ExtSkip)  # Levels to skip
      inc A  # Increment
      cmp A C  # Beyond half depth?
      if gt  # Yes
         ld (ExtSkip) 0  # Don't skip
      else
         ld C A  # Skip
         ld (ExtSkip) A  # Save new value
         do
            ld A ((Y) TAIL)  # Get name
            ld Y (Y CDR)  # Get link cell
            call nameA_A
            and A (hex "3FFFFFFFFFFFFFF7")  # Mask status and extern bits
            cmp A X  # Compare name with key
            if lt
               ld Y (Y CDR)  # Go left if symbol is smaller
            else
               ld Y (Y)  # else go right
            end
            dec C  # Done?
         until z  # Yes
      end
      do
         ld A ((Y) TAIL)  # Get name
         call nameA_A
         and A (hex "3FFFFFFFFFFFFFF7")  # Mask status and extern bits
         cmp A X  # Equal to key?
      while ne  # No
         ld C (Y CDR)  # Get link cell
         if lt  # Symbol is smaller
            ld A (C CDR)  # A on right node
            atom (A CDR)  # Right link?
            break nz  # No
            xchg (A) (Y)  # Pivot left
            ld A (A CDR)  # A also on the link
            ld Y (A CDR)  # Rotate pointers
            ld (A CDR) (A)
            ld (A) (C)
            ld (C) (C CDR)
            ld (C CDR) Y
         else  # Symbol is greater
            ld A (C)  # A on left node
            atom (A CDR)  # Left link?
            break nz  # No
            xchg (A) (Y)  # Pivot right
            ld A (A CDR)  # A also on the link
            ld Y (A)  # Rotate pointers
            ld (A) (A CDR)
            ld (A CDR) (C CDR)
            ld (C CDR) (C)
            ld (C) Y
         end
      loop
   end
   pop Y
   ret

### Unintern a symbol ###
# E symbol
# X name
# Y tree
(code 'uninternEXY 0)
   cmp X ZERO  # Name?
   jeq ret  # No
   cnt X  # Short name?
   if nz  # Yes
      do  # Y on first tree
         ld C (Y)  # Next node
         atom C  # Empty?
         jnz ret  # Yes
         ld A ((C) TAIL)  # Next symbol
         call nameA_A  # Get name
         cmp A X  # Equal?
         if eq  # Yes
            cmp E (C)  # Correct symbol?
            jne Ret  # No
            ld A (C CDR)  # Get subtrees
            atom (A)  # Left branch?
            if nz  # No
               ld (Y) (A CDR)  # Use right branch
               ret
            end
            atom (A CDR)  # Right branch?
            if nz  # No
               ld (Y) (A)  # Use left branch
               ret
            end
            ld A (A CDR)  # A on right branch
            ld Y (A CDR)  # Y on sub-branches
            atom (Y)  # Left?
            if nz  # No
               ld (C) (A)  # Insert right sub-branch
               ld ((C CDR) CDR) (Y CDR)
               ret
            end
            ld Y (Y)  # Left sub-branch
            do
               ld X (Y CDR)  # More left branches?
               atom (X)
            while z  # Yes
               ld A Y  # Go down left
               ld Y (X)
            loop
            ld (C) (Y)  # Insert left sub-branch
            ld ((A CDR)) (X CDR)
            ret
         end
         ld C (C CDR)
         if lt  # Symbol is smaller
            atom C  # Link?
            jnz ret  # No
            lea Y (C CDR)  # Go right
         else  # Symbol is greater
            atom C  # Link?
            jnz ret  # No
            ld Y C  # Go left
         end
      loop
   end
   # Long name
   lea Y (Y CDR)
   do  # Y on second tree
      ld C (Y)  # Get next node
      atom C  # Empty?
      jnz ret  # Yes
      ld A ((C) TAIL)  # Next symbol
      call nameA_A  # Get name
      call cmpLongAX_F  # Equal?
      if eq  # Yes
         cmp E (C)  # Correct symbol?
         jne Ret  # No
         ld A (C CDR)  # Get subtrees
         atom (A)  # Left branch?
         if nz  # No
            ld (Y) (A CDR)  # Use right branch
            ret
         end
         atom (A CDR)  # Right branch?
         if nz  # No
            ld (Y) (A)  # Use left branch
            ret
         end
         ld A (A CDR)  # A on right branch
         ld Y (A CDR)  # Y on sub-branches
         atom (Y)  # Left?
         if nz  # No
            ld (C) (A)  # Insert right sub-branch
            ld ((C CDR) CDR) (Y CDR)
            ret
         end
         ld Y (Y)  # Left sub-branch
         do
            ld X (Y CDR)  # More left branches?
            atom (X)
         while z  # Yes
            ld A Y  # Go down left
            ld Y (X)
         loop
         ld (C) (Y)  # Insert left sub-branch
         ld ((A CDR)) (X CDR)
         ret
      end
      ld C (C CDR)
      if lt  # Symbol is smaller
         atom C  # Link?
         jnz ret  # No
         lea Y (C CDR)  # Go right
      else  # Symbol is greater
         atom C  # Link?
         jnz ret  # No
         ld Y C  # Go left
      end
   loop

(code 'nameA_A 0)
   off A SYM  # Clear 'extern' tag
   do
      num A  # Find name
      jnz ret
      ld A (A CDR)  # Skip property
   loop

(code 'nameE_E 0)
   off E SYM  # Clear 'extern' tag
   do
      num E  # Find name
      jnz ret
      ld E (E CDR)  # Skip property
   loop

(code 'nameX_X 0)
   off X SYM  # Clear 'extern' tag
   do
      num X  # Find name
      jnz ret
      ld X (X CDR)  # Skip property
   loop

(code 'nameY_Y 0)
   off Y SYM  # Clear 'extern' tag
   do
      num Y  # Find name
      jnz ret
      ld Y (Y CDR)  # Skip property
   loop

# (name 'sym ['sym2]) -> sym
(code 'doName 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval 'sym'
   eval
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   ld Y (Y CDR)  # Second arg?
   atom Y
   if nz  # No
      cmp E Nil  # NIL?
      if ne  # No
         ld X (E TAIL)
         sym X  # External symbol?
         if z  # No
            call nameX_X  # Get name
            call consSymX_E  # Make new transient symbol
         else
            call nameX_X  # Get name
            call packExtNmX_E  # Pack it
         end
      end
   else
      cmp E Nil  # NIL?
      jeq renErrEX  # Yes
      sym (E TAIL)  # External symbol?
      jnz renErrEX  # Yes
      push X  # Save expression
      push Y
      ld X (E TAIL)
      call nameX_X  # Get name
      ld Y ((EnvIntern))  # Internal symbol?
      call isInternEXY_F
      pop Y
      pop X
      jz renErrEX  # Yes
      link
      push E  # <L I> First (transient) symbol
      link
      ld E (Y)
      eval  # Eval second arg
      num E  # Need symbol
      jnz symErrEX
      sym E
      jz symErrEX
      ld X (E TAIL)
      call nameX_X  # Get name
      push X  # Save new name
      ld E (L I)  # Get first symbol
      ld X (E TAIL)
      call nameX_X  # Get name
      ld Y Transient
      call uninternEXY  # Unintern
      lea Y (E TAIL)
      do
         num (Y)  # Find name
      while z
         lea Y ((Y) CDR)
      loop
      pop (Y)  # Store name of second
      drop
   end
   pop Y
   pop X
   ret

# Make single-char symbol
(code 'mkCharA_A 0)
   cmp A (hex "80")  # ASCII?
   if ge  # No
      cmp A (hex "800")  # Double-byte?
      if lt  # Yes
         ld (Buf) B  # 110xxxxx 10xxxxxx
         shr A 6  # Upper five bits
         and B (hex "1F")
         or B (hex "C0")
         xchg B (Buf)  # Save first byte
         and A (hex "3F")  # Lower 6 bits
         or B (hex "80")
         shl A 8  # into second byte
         ld B (Buf)  # Get first byte
      else
         cmp A TOP  # Special "top" character?
         if eq  # Yes
            ld B (hex "FF")  # Above legal UTF-8
            zxt
         else
            push C
            ld C A  # 1110xxxx 10xxxxxx 10xxxxxx
            shr A 12  # Hightest four bits
            and B (hex "0F")
            or B (hex "E0")
            ld (Buf) B  # Save first byte
            ld A C
            shr A 6  # Middle six bits
            and A (hex "3F")
            or B (hex "80")
            shl A 8  # into second byte
            xchg A C
            and A (hex "3F")  # Lowest 6 bits
            or B (hex "80")  # Add third byte
            shl A 16  # into third byte
            or A C  # Combine with second byte
            ld B (Buf)  # and first byte
            pop C
         end
      end
   end
   shl A 4  # Make short name
   or A CNT
   push A  # Save character
   call cons_A  # New cell
   pop (A)  # Set name
   or A SYM  # Make symbol
   ld (A) A  # Set value to itself
   ret

(code 'mkStrE_E 0)
   null E  # NULL pointer?
   jz retNil
   nul (E)  # Empty string?
   jz retNil
   push C
   push X
   link
   push ZERO  # <L I> Name
   ld C 4  # Build name
   ld X S
   link
   do
      ld B (E)
      call byteSymBCX_CX  # Pack byte
      inc E  # Next byte
      nul (E)  # Any?
   until z
   call cons_E  # Cons symbol
   ld (E) (L I)  # Set name
   or E SYM  # Make symbol
   ld (E) E  # Set value to itself
   drop
   pop X
   pop C
   ret

(code 'mkStrEZ_A 0)
   push X
   link
   push ZERO  # <L I> Name
   ld C 4  # Build name
   ld X S
   link
   do
      ld B (E)
      call byteSymBCX_CX  # Pack byte
      cmp E Z  # Reached Z?
   while ne  # No
      inc E  # Next byte
      nul (E)  # Any?
   until z
   call cons_A  # Cons symbol
   ld (A) (L I)  # Set name
   or A SYM  # Make symbol
   ld (A) A  # Set value to itself
   drop
   pop X
   ret

(code 'firstByteA_B 0)
   sym A  # External symbol?
   if z  # No
      call nameA_A  # Get name
      cnt A  # Short?
      if nz  # Yes
         shr A 4  # Normalize
      else
         ld A (A DIG)  # Get first digit
      end
      ret
   end
   ld A 0
   ret

(code 'firstCharE_A 0)
   ld A 0
   cmp E Nil  # NIL?
   if ne  # No
      push X
      ld X (E TAIL)
      sym X  # External symbol?
      if z  # No
         call nameX_X  # Get name
         ld C 0
         call symCharCX_FACX  # Get first character
      end
      pop X
   end
   ret

(code 'isBlankE_F 0)
   num E  # Symbol?
   jnz ret  # No
   sym E
   jz retGt  # No
   cmp E Nil  # NIL?
   jeq ret  # Yes
   sym (E TAIL)  # External symbol?
   jnz ret  # Yes
   push X
   ld X (E TAIL)
   call nameX_X  # Get name
   ld C 0
   do
      call symByteCX_FACX  # Next byte
   while nz
      cmp B 32  # Larger than blank?
      break gt  # Yes
   loop
   pop X
   ret

# (sp? 'any) -> flg
(code 'doSpQ 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   call isBlankE_F  # Blank?
   ld E TSym  # Yes
   ldnz E Nil
   ret

# (pat? 'any) -> sym | NIL
(code 'doPatQ 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   num E  # Number?
   jnz retNil  # Yes
   sym E  # Symbol?
   jz retNil  # No
   ld A (E TAIL)
   call firstByteA_B  # starting with "@"?
   cmp B (char "@")
   ldnz E Nil  # No
   ret

# (fun? 'any) -> any
(code 'doFunQ 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   call funqE_FE  # Function definition?
   ldnz E Nil  # No
   ret

# (getd 'any) -> fun | NIL
(code 'doGetd 2)
   ld E ((E CDR))  # E on arg
   eval  # Eval it
   num E  # No number?
   if z  # Yes
      sym E  # Symbol?
      if nz  # Yes
         push E
         ld E (E)  # Get value
         call funqE_FE  # Function definition?
         pop E
         if eq  # Yes
            ld E (E)  # Return value
            ret
         end
         cmp (E) Nil  # Value NIL?
         if eq  # Yes
            ld C E
            call sharedLibC_FA  # Dynamically loaded?
            if nz  # Yes
               ld E A  # Return function pointer
               ret
            end
         end
      end
   end
   ld E Nil
   ret

# (all ['NIL | 'T | '0 | '(NIL . flg) | '(T . flg) | '(0)]) -> lst
(code 'doAll 2)
   push X
   ld E ((E CDR))  # Eval arg
   eval
   atom E  # Direct tree?
   if z  # Yes
      cmp (E) Nil  # Internal trees?
      if eq  # Yes
         cmp (E CDR) Nil  # Short names?
         ldz E (((EnvIntern)))  # Yes
         ldnz E (((EnvIntern)) I)
      else
         cmp (E) TSym  # Transient trees?
         ldnz E (Extern)  # No: External symbols
         if eq  # Yes
            cmp (E CDR) Nil  # Short names?
            ldz E (Transient)  # Yes
            ldnz E (Transient I)
         end
      end
   else
      cmp E Nil  # Nil?
      if eq  # Yes
         ld X (((EnvIntern)) I)  # Internal symbols
         call consTreeXE_E
         ld X (((EnvIntern)))
      else
         cmp E TSym  # T?
         if eq  # Yes
            ld E Nil
            ld X (Transient I)  # Transient symbols
            call consTreeXE_E
            ld X (Transient)
         else
            ld E Nil
            ld X (Extern)  # External symbols
         end
      end
      call consTreeXE_E
   end
   pop X
   ret

# Build sorted list from tree
(code 'consTreeXE_E 0)
   atom X  # Tree empty?
   jnz ret  # Yes
   link
   push X  # <L II> Tree
   push Nil  # <L I> TOS
   link
   do
      do
         ld A (X CDR)  # Get subtrees
         atom (A CDR)  # Right subtree?
      while z  # Yes
         ld C X  # Go right
         ld X (A CDR)  # Invert tree
         ld (A CDR) (L I)  # TOS
         ld (L I) C
      loop
      ld (L II) X  # Save tree
      do
         call consE_A  # Cons value
         ld (A) (X)
         ld (A CDR) E
         ld E A  # into E
         ld A (X CDR)  # Left subtree?
         atom (A)
         if z  # Yes
            ld C X  # Go left
            ld X (A)  # Invert tree
            ld (A) (L I)  # TOS
            or C SYM  # First visit
            ld (L I) C
            ld (L II) X  # Save tree
            break T
         end
         do
            ld A (L I)  # TOS
            cmp A Nil  # Empty?
            jeq 90  # Done
            sym A  # Second visit?
            if z  # Yes
               ld C (A CDR)  # Nodes
               ld (L I) (C CDR)  # TOS on up link
               ld (C CDR) X
               ld X A
               ld (L II) X  # Save tree
               break T
            end
            off A SYM  # Set second visit
            ld C (A CDR)  # Nodes
            ld (L I) (C)
            ld (C) X
            ld X A
            ld (L II) X  # Save tree
         loop
      loop
   loop
90 drop  # Return E
   ret

# Build balanced copy of a namespace
(code 'balanceXY)  # ACE
   ld E Nil  # Build list
   call consTreeXE_E
   link
   push E  # <L I> Save list
   link
   ld A E  # Get list in A
   ld C 0  # Calculate length
   do
      atom A  # More cells?
   while z  # Yes
      inc C  # Increment length
      ld A (A CDR)  # Next cell
   loop
   call balanceCEY
   drop
   ret

(code 'balanceCEY 0)
   do
      null C  # Length zero?
      jz ret  # Yes
      push C  # <S II> Save length
      push E  # <S I> and list
      inc C  # (length + 1) / 2
      shr C 1
      push C  # <S> Rest length
      do
         dec C  # nth
      while nsz
         ld E (E CDR)
      loop
      push (E CDR)  # Save rest
      ld E (E)  # Next symbol
      ld X (E TAIL)  # Get name
      call nameX_X
      call internEXY_FE  # Insert
      pop E  # Retrieve rest
      ld C (S II)  # Get length
      sub C (S)  # minus rest length
      call balanceCEY  # Recurse
      pop C  # Retrieve rest length
      dec C  # Decrement
      pop E  # Retrieve list
      add S I  # Drop length
   loop  # Tail recurse

# (symbols) -> sym
# (symbols 'sym1) -> sym2
# (symbols 'sym1 'sym ..) -> sym2
(code 'doSymbols 2)
   push X
   push Y
   push Z
   ld X E
   ld Z (E CDR)  # Z on args
   atom Z  # Any?
   if nz  # No
      ld E (EnvIntern)  # Return current symbol namespace
   else
      ld E (Z)  # Eval first
      eval
      num E  # Need symbol
      jnz symErrEX
      sym E
      jz symErrEX
      ld Z (Z CDR)  # Second arg
      atom Z  # Any?
      if nz  # No
         atom (E)  # Value must be a pair
         jnz symNsErrEX
      else
         call checkVarEX
         link
         push E  # <L III> Save new symbol namespace
         push Nil  # <L II> Space for value
         push Nil  # <L I> and source
         link
         call cons_Y  # Create namespace cell
         ld (Y) Nil  # Initialize
         ld (Y CDR) Nil
         ld (L II) Y  # New value
         do
            ld E (Z)
            eval  # Eval next source symbol namespace
            ld (L I) E  # Save source
            num E  # Need symbol
            jnz symErrEX
            sym E
            jz symErrEX
            ld C (E)  # Get source value
            atom C  # Must be a pair
            jnz symNsErrEX
            push X
            ld X (C)  # Source short names
            call balanceXY  # Balanced copy of short names
            ld X (((L I)) CDR)  # Source long names
            call balanceXY  # Balanced copy of long names
            pop X
            ld Z (Z CDR)  # Next arg
            atom Z  # Any?
         until nz  # No
         ld C (L II)  # Get value
         ld E (L III)  # And new symbol namespace
         call redefineCE  # Redefine
         drop
      end
      xchg (EnvIntern) E  # Set new symbol namespace, return old
   end
   pop Z
   pop Y
   pop X
   ret

# (intern 'sym) -> sym
(code 'doIntern 2)
   push X
   ld X E
   ld E ((E CDR))  # E on arg
   eval  # Eval it
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   ld X (E TAIL)
   call nameX_X  # Get name
   cmp X ZERO  # Any?
   if ne  # Yes
      push Y
      ld Y ((EnvIntern))  # Insert internal
      call internEXY_FE
      pop Y
      pop X
      ret
   end
   ld E Nil
   pop X
   ret

# (extern 'sym) -> sym | NIL
(code 'doExtern 2)
   push X
   push Y
   ld X E
   ld E ((E CDR))  # E on arg
   eval  # Eval it
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   ld X (E TAIL)
   call nameX_X  # Get name
   cmp X ZERO  # Any?
   if ne  # Yes
      ld C 0  # Character index
      call symCharCX_FACX  # First char
      cmp B (char "{")  # Open brace?
      if eq  # Yes
         call symCharCX_FACX  # Skip it
      end
      ld E 0  # Init file number
      do
         cmp B (char "@")  # File done?
      while ge  # No
         cmp B (char "O")  # In A-O range?
         jgt 90  # Yes
         sub B (char "@")
         shl E 4  # Add to file number
         add E A
         call symCharCX_FACX  # Next char?
         jz 90  # No
      loop
      cmp B (char "0")  # Octal digit?
      jlt 90
      cmp B (char "7")
      jgt 90  # No
      sub B (char "0")
      zxt
      ld Y A  # Init object ID
      do
         call symCharCX_FACX  # Next char?
      while nz  # Yes
         cmp B (char "}")  # Closing brace?
      while ne  # No
         cmp B (char "0")  # Octal digit?
         jlt 90
         cmp B (char "7")
         jgt 90  # No
         sub B (char "0")
         shl Y 3  # Add to object ID
         add Y A
      loop
      ld C Y  # Object ID
      call extNmCE_X  # Build external symbol name
      call externX_E  # New external symbol
      call isLifeE_F  # Alive?
      ldnz E Nil  # No
      pop Y
      pop X
      ret
   end
90 ld E Nil
   pop Y
   pop X
   ret

# (==== ['sym ..]) -> NIL
(code 'doHide 2)
   ld A Nil  # Clear transient index trees
   ld (Transient) A
   ld (Transient I) A
   push X
   push Y
   push Z
   ld X E
   ld Z (E CDR)  # Args
   do
      atom Z  # More?
   while z  # Yes
      ld E (Z)  # Eval next
      eval
      num E  # Need symbol
      jnz symErrEX
      sym E
      jz symErrEX
      push X
      ld X (E TAIL)
      call nameX_X  # Get name
      ld Y Transient  # Insert transient
      call internEXY_FE
      pop X
      ld Z (Z CDR)  # Z on rest
   loop
   pop Z
   pop Y
   pop X
   ret

# (box? 'any) -> sym | NIL
(code 'doBoxQ 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   num E  # Number?
   jnz retNil  # Yes
   sym E  # Symbol?
   jz retNil  # No
   ld A (E TAIL)
   call nameA_A  # Get name
   cmp A ZERO  # Any?
   jne retNil
   ret

# (str? 'any) -> sym | NIL
(code 'doStrQ 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   num E  # Number?
   jnz retNil  # Yes
   sym E  # Symbol?
   jz retNil  # No
   sym (E TAIL)  # External symbol?
   jnz retNil  # Yes
   push X
   push Y
   ld X (E TAIL)  # Get name
   call nameX_X
   ld Y ((EnvIntern))  # Internal symbol?
   call isInternEXY_F
   ldz E Nil  # Return NIL
   pop Y
   pop X
   ret

# (ext? 'any) -> sym | NIL
(code 'doExtQ 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   num E  # Number?
   jnz retNil  # Yes
   sym E  # Symbol?
   jz retNil  # No
   ld A (E TAIL)
   sym A  # External symbol?
   jz retNil  # No
   call isLifeE_F  # Alive?
   ldnz E Nil  # No
   ret

# (touch 'sym) -> sym
(code 'doTouch 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   sym (E TAIL)  # External symbol?
   if nz  # Yes
      call dbTouchEX  # Touch it
   end
   ret

# (zap 'sym) -> sym
(code 'doZap 2)
   push X
   ld X E
   ld E ((E CDR))  # E on arg
   eval  # Eval it
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   ld A (E TAIL)
   sym A  # External symbol?
   if nz  # Yes
      call dbZapE  # Mark as "deleted"
   else
      push Y
      ld X (E TAIL)
      call nameX_X  # Get name
      ld Y ((EnvIntern))
      call uninternEXY  # Unintern symbol
      pop Y
   end
   pop X
   ret

# (chop 'any) -> lst
(code 'doChop 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   atom E  # Atomic?
   if nz  # Yes
      cmp E Nil  # NIL?
      if ne  # No
         push X
         call xSymE_E  # Extract symbol
         ld X (E TAIL)
         call nameX_X  # Get name
         sym (E TAIL)  # External symbol?
         if z  # No
            ld C 0
            call symCharCX_FACX  # First char?
            if nz  # Yes
               push Y
               link
               push X  # Save name
               link
               call mkCharA_A  # Make single character
               call consA_Y  # Cons it
               ld (Y) A
               ld (Y CDR) Nil  # with NIL
               tuck Y  # <L I> Result
               link
               do
                  call symCharCX_FACX  # Next char
               while nz
                  call mkCharA_A  # Make char
                  call consA_E  # Cons it
                  ld (E) A
                  ld (E CDR) Nil
                  ld (Y CDR) E  # Append to result
                  ld Y E
               loop
               ld E (L I)  # Get result
               drop
               pop Y
            else
               ld E Nil  # Else return NIL
            end
         else  # External symbol
            call chopExtNmX_E
         end
         pop X
      end
   end
   ret

# (pack 'any ..) -> sym
(code 'doPack 2)
   push X
   push Y
   push Z
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   link
   push E  # <L III> 'any'
   push ZERO  # <L II> Safe
   push ZERO  # <L I> Result
   ld C 4  # Build name
   ld X S
   link
   do
      call packECX_CX
      ld Y (Y CDR)  # More args?
      atom Y
   while z  # Yes
      ld Z C  # Save C
      ld E (Y)  # Eval next arg
      eval
      ld (L III) E  # Save
      ld C Z
   loop
   ld X (L I)  # Get result
   call consSymX_E  # Make transient symbol
   drop
   pop Z
   pop Y
   pop X
   ret

(code 'packECX_CX 0)
   atom E  # Atomic?
   if z  # No
      cmp S (StkLimit)  # Stack check
      jlt stkErr
      do  # List
         push (E CDR)  # Save rest
         ld E (E)  # Recurse on CAR
         call packECX_CX
         pop E  # Done?
         atom E
      until nz  # Yes
   end
   cmp E Nil  # NIL?
   jeq ret  # Yes
   num E  # Number?
   if z  # No
      sym (E TAIL)  # External symbol?
      if nz  # Yes
         ld B (char "{")
         call byteSymBCX_CX  # Pack "{"
         push C  # Save status
         push X
         ld X (E TAIL)  # Get name
         call nameX_X
         call packExtNmX_E  # Pack name
         ld (L II) E  # Save
         pop X  # Restore status
         pop C
         call packExt  # Pack external symbol
         ld B (char "}")
         jmp byteSymBCX_CX  # Pack "}"
      end
   else
      ld A 0  # Scale
      call fmtNum0AE_E  # Convert to symbol
      ld (L II) E  # Save
   end
: packExt
   push C  # Save status
   push X
   ld X (E TAIL)
   call nameX_X  # Get name
   ld C 0
   do
      call symByteCX_FACX  # Next char
   while nz
      xchg C (S I)  # Swap status
      xchg X (S)
      call byteSymBCX_CX  # Pack byte
      xchg X (S)  # Swap status
      xchg C (S I)
   loop
   pop X  # Restore status
   pop C
   ret

# (glue 'any 'lst) -> sym
(code 'doGlue 2)
   push X
   push Y
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   link
   push E  # <L IV> 'any'
   ld X (X CDR)  # X on rest
   ld E (X)  # Eval second
   eval+
   push E  # <L III> 'lst'
   push ZERO  # <L II> Number safe
   push ZERO  # <L I> Result
   ld C 4  # Build name
   ld X S
   link
   atom E  # Any items?
   if z  # Yes
      ld Y E  # 'lst'
      do
         ld E (Y)  # Get next item
         call packECX_CX  # Pack it
         ld Y (Y CDR)  # More?
         atom Y
      while z  # Yes
         ld E (L IV)  # Get 'any'
         call packECX_CX  # Pack it
      loop
      ld X (L I)  # Get result
      call consSymX_E  # Make transient symbol
   end
   drop
   pop Y
   pop X
   ret

# (text 'any1 'any ..) -> sym
(code 'doText 2)
   push X
   push Y
   ld X (E CDR)  # Args
   call evSymX_E  # Eval first
   cmp E Nil  # NIL?
   if ne  # No
      ld E (E TAIL)
      call nameE_E  # Get name
      link
      push E  # <(L) -I> Name of 'any1'
      do
         ld X (X CDR)  # Next arg
         atom X  # Any?
      while z  # Yes
         ld E (X)  # Eval next arg
         eval+
         push E  # and save it
      loop
      push ZERO  # <L II> Number safe
      push ZERO  # <L I> Result
      ld X S
      link
      push 4  # <S I> Build name
      push X  # <S> Pack status
      ld X ((L) -I) # Get name of 'any1'
      ld C 0  # Index
      do
         call symByteCX_FACX  # Next char?
      while nz
         cmp B (char "@")  # Pattern?
         if ne  # No
10          xchg C (S I)  # Swap status
            xchg X (S)
            call byteSymBCX_CX  # Pack byte
            xchg X (S)  # Swap status
            xchg C (S I)
            continue T
         end
         call symByteCX_FACX  # Next char after "@"?
      while nz
         cmp B (char "@")  # "@@"?
         jeq 10  # Yes
         sub B (char "0")  # >= "1"?
         if gt  # Yes
            cmp B 9  # > 9?
            if gt
               sub B 7  # Adjust for letter
            end
            shl A 3  # Vector index
            lea E ((L) -I)  # Point above first 'any' arg
            sub E A  # Get arg address
            lea A (L II)  # Address of number save
            cmp E A  # Arg address too low?
            if gt  # No
               ld E (E)
               xchg C (S I)  # Swap status
               xchg X (S)
               call packECX_CX  # Pack it
               xchg X (S)  # Swap status
               xchg C (S I)
            end
         end
      loop
      ld X (L I)  # Get result
      call consSymX_E  # Make transient symbol
      drop
   end
   pop Y
   pop X
   ret

(code 'preCEXY_F 0)
   do
      call symByteCX_FACX  # First string done?
      jz ret  # Yes
      ld (Buf) B  # Keep
      xchg C E  # Second string
      xchg X Y
      call symByteCX_FACX  # Next byte?
      jz retGt  # No
      cmp (Buf) B  # Equal?
      jne ret  # No
      xchg C E  # First string
      xchg X Y
   loop

(code 'subStrAE_F 0)
   cmp A Nil  # NIL?
   jeq ret  # Yes
   ld A (A TAIL)  # First symbol
   call nameA_A  # Get name
   cmp A ZERO  # None?
   jeq ret  # Yes
   ld E (E TAIL)  # Second symbol
   call nameE_E  # Get name
   cmp E ZERO  # Any?
   jeq retGt  # No
   push X
   push Y
   push Z
   push A  # <S I> First name
   ld Z E  # Second name
   push 0  # <S> Second index
   do
      ld X (S I)  # First name
      ld C 0  # First index
      ld Y Z  # Second name
      ld E (S)  # Second index
      call preCEXY_F  # Prefix?
   while ne  # No
      ld A (S)
      shr A 8  # New round in second index?
      if z  # Yes
         cmp Z ZERO  # Second done?
         if eq  # Yes
            gt  # 'nz'
            break T
         end
         cnt Z  # Short?
         if nz  # Yes
            ld A Z  # Get short
            shr A 4  # Normalize
            ld Z ZERO  # Clear for next round
         else
            ld A (Z DIG)  # Get next digit
            ld Z (Z BIG)
         end
      end
      ld (S) A
   loop
   lea S (S II)  # Drop locals
   pop Z
   pop Y
   pop X
   ret  # 'z' or 'nz'

# (pre? 'any1 'any2) -> any2 | NIL
(code 'doPreQ 2)
   push X
   push Y
   push Z
   ld X (E CDR)  # X on args
   call evSymX_E  # Eval first
   link
   push E  # <L I> 'any1'
   link
   ld X (X CDR)  # Next arg
   call evSymX_E  # Eval second
   ld X (L I)  # 'any1'
   cmp X Nil  # NIL?
   if ne  # No
      ld Z E  # Keep second in Z
      ld X (X TAIL)  # 'any1'
      call nameX_X  # First name
      ld C 0
      ld E (E TAIL)  # 'any2'
      call nameE_E  # Second name
      ld Y E
      ld E 0
      call preCEXY_F  # Prefix?
      ld E Nil
      ldz E Z  # Yes
   end
   drop
   pop Z
   pop Y
   pop X
   ret

# (sub? 'any1 'any2) -> any2 | NIL
(code 'doSubQ 2)
   push X
   ld X (E CDR)  # X on args
   call evSymX_E  # Eval first
   link
   push E  # <L I> 'any1'
   link
   ld X (X CDR)  # Next arg
   call evSymX_E  # Eval second
   ld A (L I)  # 'any1'
   ld X E  # Keep second in X
   call subStrAE_F  # Substring?
   ld E Nil
   ldz E X  # Yes
   drop
   pop X
   ret

# (val 'var) -> any
(code 'doVal 2)
   push X
   ld X E
   ld E ((E CDR))  # E on arg
   eval  # Eval it
   num E  # Need variable
   jnz varErrEX
   sym E  # Symbol?
   if nz  # Yes
      sym (E TAIL)  # External symbol?
      if nz  # Yes
         call dbFetchEX  # Fetch it
      end
   end
   ld E (E)  # Return value
   pop X
   ret

# (set 'var 'any ..) -> any
(code 'doSet 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   link
   push ZERO  # <L I> Safe
   link
   do
      ld E (Y)  # Eval next
      eval
      call needVarEX  # Need variable
      sym E  # Symbol?
      if nz  # Yes
         sym (E TAIL)  # External symbol?
         if nz  # Yes
            call dbTouchEX  # Touch it
         end
      end
      ld (L I) E  # Save it
      ld Y (Y CDR)  # Next arg
      ld E (Y)
      eval  # Eval 'any'
      ld ((L I)) E  # Set value
      ld Y (Y CDR)  # Next arg
      atom Y  # Any?
   until nz  # No
   drop
   pop Y
   pop X
   ret

# (setq var 'any ..) -> any
(code 'doSetq 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   do
      ld E (Y)  # Next var
      call needVarEX  # Need variable
      ld Z E  # Keep in Z
      ld Y (Y CDR)  # Eval next arg
      ld E (Y)
      eval
      ld (Z) E  # Store value
      ld Y (Y CDR)  # More args?
      atom Y
   until nz  # No
   pop Z
   pop Y
   pop X
   ret

# (swap 'var 'any) -> any
(code 'doSwap 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   call needVarEX  # Need variable
   sym E  # Symbol?
   if nz  # Yes
      sym (E TAIL)  # External symbol?
      if nz  # Yes
         call dbTouchEX  # Touch it
      end
   end
   link
   push E  # <L I> 'var'
   link
   ld E ((Y CDR))  # Eval next arg
   eval
   xchg E ((L I))  # Swap value
   drop
   pop Y
   pop X
   ret

# (xchg 'var 'var ..) -> any
(code 'doXchg 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   link
   push ZERO  # <L I> Safe
   link
   do
      ld E (Y)  # Eval next
      eval
      call needVarEX  # Need variable
      sym E  # Symbol?
      if nz  # Yes
         sym (E TAIL)  # External symbol?
         if nz  # Yes
            call dbTouchEX  # Touch it
         end
      end
      ld (L I) E  # Save it
      ld Y (Y CDR)  # Next arg
      ld E (Y)
      eval  # Eval next arg
      call needVarEX  # Need variable
      sym E  # Symbol?
      if nz  # Yes
         sym (E TAIL)  # External symbol?
         if nz  # Yes
            call dbTouchEX  # Touch it
         end
      end
      ld C (L I)  # Get first 'var'
      ld A (C)  # Get value
      ld (C) (E)  # Set new
      ld (E) A
      ld Y (Y CDR)  # Next arg
      atom Y  # Any?
   until nz  # No
   ld E A  # Return last
   drop
   pop Y
   pop X
   ret

# (on var ..) -> T
(code 'doOn 2)
   ld A (E CDR)
   do
      ld ((A)) TSym  # Set next arg to 'T'
      ld A (A CDR)  # More?
      atom A
   until nz  # No
   ld E TSym
   ret

# (off var ..) -> NIL
(code 'doOff 2)
   ld A (E CDR)
   do
      ld ((A)) Nil  # Set next arg to 'Nil'
      ld A (A CDR)  # More?
      atom A
   until nz  # No
   ld E Nil
   ret

# (onOff var ..) -> flg
(code 'doOnOff 2)
   ld A (E CDR)
   do
      ld C (A)  # Get next arg
      cmp (C) Nil  # Value NIL?
      ld E TSym  # Negate
      ldnz E Nil
      ld (C) E  # Set new value
      ld A (A CDR)  # More?
      atom A
   until nz  # No
   ret  # Return last

# (zero var ..) -> 0
(code 'doZero 2)
   ld A (E CDR)
   do
      ld ((A)) ZERO  # Set next arg to '0'
      ld A (A CDR)  # More?
      atom A
   until nz  # No
   ld E ZERO
   ret

# (one var ..) -> 1
(code 'doOne 2)
   ld A (E CDR)
   do
      ld ((A)) ONE  # Set next arg to '1'
      ld A (A CDR)  # More?
      atom A
   until nz  # No
   ld E ONE
   ret

# (default sym 'any ..) -> any
(code 'doDefault 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   do
      ld E (Y)  # Next var
      ld Y (Y CDR)
      call needVarEX  # Need variable
      ld Z E  # Keep in Z
      cmp (Z) Nil  # Value 'NIL'?
      if eq  # Yes
         ld E (Y)  # Eval next arg
         eval
         ld (Z) E  # Store value
      end
      ld Y (Y CDR)  # More args?
      atom Y
   until nz  # No
   ld E (Z)  # Return value
   pop Z
   pop Y
   pop X
   ret

# (push 'var 'any ..) -> any
(code 'doPush 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   call needVarEX  # Need variable
   sym E  # Symbol?
   if nz  # Yes
      sym (E TAIL)  # External symbol?
      if nz  # Yes
         call dbTouchEX  # Touch it
      end
   end
   link
   push E  # <L I> 'var'
   link
   ld Y (Y CDR)  # Second arg
   do
      ld E (Y)
      eval  # Eval next arg
      call consE_A  # Cons into value
      ld (A) E
      ld C (L I)  # 'var'
      ld (A CDR) (C)
      ld (C) A
      ld Y (Y CDR)  # Next arg
      atom Y  # Any?
   until nz  # No
   drop
   pop Y
   pop X
   ret

# (push1 'var 'any ..) -> any
(code 'doPush1 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   call needVarEX  # Need variable
   sym E  # Symbol?
   if nz  # Yes
      sym (E TAIL)  # External symbol?
      if nz  # Yes
         call dbTouchEX  # Touch it
      end
   end
   link
   push E  # <L I> 'var'
   link
   ld Y (Y CDR)  # Second arg
   do
      ld E (Y)
      eval  # Eval next arg
      ld C ((L I))  # Value of 'var'
      do  # 'member'
         atom C  # List?
      while z  # Yes
         ld A (C)
         ld Z E  # Preserve E
         call equalAE_F  # Member?
         ld E Z
         jeq 10  # Yes
         ld C (C CDR)
      loop
      call consE_A  # Cons into value
      ld (A) E
      ld C (L I)  # 'var'
      ld (A CDR) (C)
      ld (C) A
10    ld Y (Y CDR)  # Next arg
      atom Y  # Any?
   until nz  # No
   drop
   pop Z
   pop Y
   pop X
   ret

# (push1q 'var 'any ..) -> any
(code 'doPush1q 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   call needVarEX  # Need variable
   sym E  # Symbol?
   if nz  # Yes
      sym (E TAIL)  # External symbol?
      if nz  # Yes
         call dbTouchEX  # Touch it
      end
   end
   link
   push E  # <L I> 'var'
   link
   ld Y (Y CDR)  # Second arg
   do
      ld E (Y)
      eval  # Eval next arg
      ld C ((L I))  # Value of 'var'
      do  # 'memq'
         atom C  # List?
      while z  # Yes
         cmp E (C)  # Member?
         jeq 10  # Yes
         ld C (C CDR)
      loop
      call consE_A  # Cons into value
      ld (A) E
      ld C (L I)  # 'var'
      ld (A CDR) (C)
      ld (C) A
10    ld Y (Y CDR)  # Next arg
      atom Y  # Any?
   until nz  # No
   drop
   pop Y
   pop X
   ret

# (pop 'var) -> any
(code 'doPop 2)
   push X
   ld X E
   ld E ((E CDR))  # E on arg
   eval  # Eval it
   call needVarEX  # Need variable
   sym E  # Symbol?
   if nz  # Yes
      sym (E TAIL)  # External symbol?
      if nz  # Yes
         call dbTouchEX  # Touch it
      end
   end
   ld A E  # 'var' in A
   ld E (A)  # Get value
   atom E  # List?
   if z  # Yes
      ld (A) (E CDR)  # Set to CDR
      ld E (E)  # Return CAR
   end
   pop X
   ret

# (++ var) -> any
(code 'doPopq 2)
   ld A ((E CDR))  # 'var' in A
   ld E (A)  # Get value
   atom E  # List?
   if z  # Yes
      ld (A) (E CDR)  # Set to CDR
      ld E (E)  # Return CAR
   end
   ret

# (cut 'cnt 'var) -> lst
(code 'doCut 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   call evCntXY_FE  # Eval 'cnt'
   if nsz  # Yes
      ld Y ((Y CDR))  # Second arg
      xchg E Y  # 'cnt' in Y
      eval  # Eval 'var'
      call needVarEX  # Need variable
      sym E  # Symbol?
      if nz  # Yes
         sym (E TAIL)  # External symbol?
         if nz  # Yes
            call dbTouchEX  # Touch it
         end
      end
      atom (E)  # List value?
      ldnz E (E)
      if z  # Yes
         call consE_X  # Cons first cell
         ld C (E)  # Get value
         ld (X) (C)  # CAR
         ld (X CDR) Nil
         link
         push E  # <L II> 'var'
         push X  # <L I> 'lst'
         link
         do
            ld C (C CDR)  # More elements?
            atom C
         while z  # Yes
            dec Y  # Count?
         while nz  # Yes
            call cons_A  # Copy next cell
            ld (A) (C)
            ld (A CDR) Nil
            ld (X CDR) A  # Append to result
            ld X (X CDR)
         loop
         ld ((L II)) C  # Set new value
         ld E (L I)  # Get result
         drop
      end
      pop Y
      pop X
      ret
   end
   ld E Nil
   pop Y
   pop X
   ret

# (del 'any 'var) -> lst
(code 'doDel 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   link
   push E  # <L II/III> 'any'
   ld Y (Y CDR)
   ld E (Y)  # Eval second
   eval+
   push E  # <L I/II> 'var'
   link
   call needVarEX  # Need variable
   sym E  # Symbol?
   if nz  # Yes
      sym (E TAIL)  # External symbol?
      if nz  # Yes
         call dbTouchEX  # Touch it
      end
   end
   ld E ((L I))  # Get value of 'var'
   atom E  # List?
   if z  # Yes
      ld Y E  # Keep value in Y
      ld E (Y)  # First element
      ld A (L II)  # 'any'
      call equalAE_F  # Equal?
      if eq  # Yes
         ld E (Y CDR)  # Get value's CDR
         ld ((L I)) E  # Set 'var'
      else
         call cons_Z  # Copy first cell
         ld (Z) (Y)
         ld (Z CDR) Nil
         tuck Z  # <L I> Save it
         link
         do
            ld Y (Y CDR)  # More cells?
            atom Y
         while z  # Yes
            ld E (Y)  # Next element
            ld A (L III)  # 'any'
            call equalAE_F  # Equal?
            if eq  # Yes
               ld (Z CDR) (Y CDR)  # Skip found element
               ld E (L I)  # Result
               ld ((L II)) E  # Set 'var'
               jmp 90
            end
            call cons_A  # Copy next cell
            ld (A) (Y)
            ld (A CDR) Nil
            ld (Z CDR) A   # Append to result
            ld Z (Z CDR)
         loop
         ld E ((L II))  # Not found: Return old value of 'var'
      end
   end
90 drop
   pop Z
   pop Y
   pop X
   ret

# (queue 'var 'any) -> any
(code 'doQueue 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   call needVarEX  # Need variable
   sym E  # Symbol?
   if nz  # Yes
      sym (E TAIL)  # External symbol?
      if nz  # Yes
         call dbTouchEX  # Touch it
      end
   end
   link
   push E  # <L I> 'var'
   link
   ld E ((Y CDR))  # Eval next arg
   eval
   call consE_C  # Build cell
   ld (C) E
   ld (C CDR) Nil
   ld X (L I)  # Get 'var'
   ld Y (X)  # Value
   atom Y  # Atomic?
   if nz  # Yes
      ld (X) C  # Store first cell
   else
      do
         atom (Y CDR)  # Find last cell
      while z
         ld Y (Y CDR)
      loop
      ld (Y CDR) C
   end
   drop
   pop Y
   pop X
   ret

# (fifo 'var ['any ..]) -> any
(code 'doFifo 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   call needVarEX  # Need variable
   sym E  # Symbol?
   if nz  # Yes
      sym (E TAIL)  # External symbol?
      if nz  # Yes
         call dbTouchEX  # Touch it
      end
   end
   link
   push E  # <L I> 'var'
   link
   ld Y (Y CDR)  # More args?
   atom Y
   if z  # Yes
      ld E (Y)  # Eval 'any'
      eval
      call consE_A  # Cons into new cell
      ld (A) E
      ld C (L I)  # Get 'var'
      ld X (C)  # Value in X
      atom X  # List?
      if z  # Yes
         ld (A CDR) (X CDR)  # Concat to value
         ld (X CDR) A
      else
         ld (A CDR) A  # Circular cell
         ld (C) X  # Set new value
      end
      ld X A
      do
         ld Y (Y CDR)  # More args?
         atom Y
      while z  # Yes
         ld E (Y)  # Eval next 'any'
         eval
         call consE_A  # Cons into new cell
         ld (A) E
         ld (A CDR) (X CDR)  # Concat to value
         ld (X CDR) A
         ld X A
      loop
      ld ((L I)) X  # Set new value
   else
      ld C (L I)  # Get 'var'
      ld X (C)  # Value in X
      atom X  # Any?
      if nz  # No
         ld E Nil
      else
         cmp X (X CDR)  # Single cell?
         if eq  # Yes
            ld E (X)  # Return CAR
            ld (C) Nil  # Clear value
         else
            ld E ((X CDR))  # Return CADR
            ld (X CDR) ((X CDR) CDR)  # Cut cell
         end
      end
   end
   drop
   pop Y
   pop X
   ret

# (idx 'var 'any 'flg) -> lst
# (idx 'var 'any) -> lst
# (idx 'var) -> lst
(code 'doIdx 2)
   push X
   ld X E
   ld E ((E CDR))  # Eval first arg
   eval
   call needVarEX  # Need variable
   ld X ((X CDR) CDR)  # Second arg?
   atom X
   if nz  # No
      ld X (E)  # Get tree
      ld E Nil  # Cons a list
      call consTreeXE_E
   else
      push Y
      link
      push E  # <L II> 'var'
      ld E (X)
      eval+  # Eval second arg
      push E  # <L I> 'any'
      link  # Save it
      ld Y E  # Keep in Y
      ld X (X CDR)  # Third arg?
      atom X
      if nz  # No
         ld X (L II)  # Get 'var'
         call idxGetXY_E  # Find
      else
         ld E (X)  # Eval last arg
         eval
         ld X (L II)  # Get 'var'
         cmp E Nil  # Delete?
         if ne  # No
            call idxPutXY_E  # Insert
         else
            call idxDelXY_E  # Delete
         end
      end
      drop
      pop Y
   end
   pop X
   ret

(code 'idxGetXY_E 0)
   ld X (X)  # Get value of 'var'
   do
      atom X  # More nodes?
      ld E Nil
   while z  # Yes
      ld A Y  # Get key
      ld E (X)  # Compare with node value
      call compareAE_F  # Found?
      ld E X
   while ne  # No
      if lt
         ld X ((X CDR))  # Smaller
      else
         ld X ((X CDR) CDR)  # Greater
      end
   loop
   ret

(code 'idxPutXY_E 0)
   atom (X)  # First insert?
   if nz  # Yes
      call cons_A  # Cons new node
      ld (A) Y  # 'any'
      ld (A CDR) Nil
      ld (X) A  # Set 'var'
      ld E Nil  # return NIL
   else
      ld X (X)  # Get value of 'var'
      do
         ld A Y  # Get key
         ld E (X)  # Compare with node value
         call compareAE_F  # Equal?
         ld E X
      while ne  # No
         ld A (X CDR)
         if ge  # Greater
            atom A  # Already has link?
            if nz  # No
               call cons_A  # Cons into a new node
               ld (A) Y  # key
               ld (A CDR) Nil
               call consA_C  # Cons a new link
               ld (C) Nil
               ld (C CDR) A
               ld (X CDR) C
               ld E Nil  # Return NIL
               ret
            end
            ld X A
            atom (X CDR)  # CDR of link?
            ldz X (X CDR)  # Yes: Get CDR of link in X
            if nz  # No
               call cons_A  # Else cons into a new node
               ld (A) Y  # key
               ld (A CDR) Nil
               ld (X CDR) A  # Store in CDR of link
               ld E Nil  # Return NIL
               ret
            end
         else  # Smaller
            atom A  # Already has link?
            if nz  # No
               call cons_A  # Cons into a new node
               ld (A) Y  # key
               ld (A CDR) Nil
               call consA_C  # Cons a new link
               ld (C) A
               ld (C CDR) Nil
               ld (X CDR) C
               ld E Nil  # Return NIL
               ret
            end
            ld X A
            atom (X)  # CAR of link?
            ldz X (X)  # Yes: Get CAR of link in X
            if nz  # No
               call cons_A  # Else cons into a new node
               ld (A) Y  # key
               ld (A CDR) Nil
               ld (X) A  # Store in CAR of link
               ld E Nil  # Return NIL
               ret
            end
         end
      loop
   end
   ret

(code 'idxDelXY_E 0)
   do
      atom (X)  # Next node?
      ld E Nil
   while z  # Yes
      ld A Y  # Get key
      ld E ((X))  # Compare with node value
      call compareAE_F  # Equal?
      if eq  # Yes
         ld C (X)  # Found subtree
         ld E C  # Preset return value
         ld A (C CDR)  # Get subtrees
         atom (A)  # Left branch?
         if nz  # No
            ld (X) (A CDR)  # Use right branch
            ret
         end
         atom (A CDR)  # Right branch?
         if nz  # No
            ld (X) (A)  # Use left branch
            ret
         end
         ld A (A CDR)  # A on right branch
         ld X (A CDR)  # X on sub-branches
         atom (X)  # Left?
         if nz  # No
            ld (C) (A)  # Insert right sub-branch
            ld ((C CDR) CDR) (X CDR)
            ret
         end
         push E  # Save return value
         ld X (X)  # Left sub-branch
         do
            ld E (X CDR)  # More left branches?
            atom (E)
         while z  # Yes
            ld A X  # Go down left
            ld X (E)
         loop
         ld (C) (X)  # Insert left sub-branch
         ld ((A CDR)) (E CDR)
         pop E
         ret
      end
      ld E Nil
      ld X ((X) CDR)
      if ge  # Node value is greater
         atom X  # Link?
         break nz  # No
         lea X (X CDR)  # Go right
      else  # Node value is smaller
         atom X  # Link?
         break nz  # No
      end
   loop
   ret

# (lup 'lst 'any) -> lst
# (lup 'lst 'any 'any2) -> lst
(code 'doLup 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval first
   eval
   atom E  # List?
   if z  # Yes
      link
      push E  # <L V> 'lst'
      ld X (X CDR)  # Eval second
      ld E (X)
      eval+  # 'any'
      ld X (X CDR)  # Next arg?
      atom X
      if nz  # No
         pop X  # Get 'lst' in X
         pop L  # Discard partial stack frame
         push Y
         ld Y E  # Get 'any' in Y
         do
            ld E (X)  # CAR of 'lst'
            cmp E TSym  # Is it T?
            if eq  # Yes
               ld X ((X CDR))  # Go to CADR
            else
               atom E  # Atomic?
               if nz  # Yes
                  ld X ((X CDR) CDR)  # Go to CDDR
               else
                  ld A Y  # Key 'any'
                  ld E (E)  # CAAR of 'lst'
                  call compareAE_F  # Equal?
                  if eq  # Yes
                     ld E (X)  # Return CAR of 'lst'
                     pop Y
                     pop X
                     ret
                  end
                  if lt
                     ld X ((X CDR))  # Smaller
                  else
                     ld X ((X CDR) CDR)  # Greater
                  end
               end
            end
            atom X  # Reached leaf?
         until nz  # Yes
         ld E Nil  # Return NIL
         pop Y
      else
         push E  # <L IV> "from" key
         ld E (X)  # Eval next
         eval+
         push E  # <L III> "to" key
         push Nil  # <L II> TOS
         push Nil  # <L I> Result
         link
         ld X (L V)  # Get 'lst' in X
         do
            do
               ld A (X CDR)
               atom (A CDR)  # Right subtree?
            while z  # Yes
               ld E (X)  # CAR of 'lst'
               cmp E TSym  # Is it T?
            while ne  # No
               atom E  # Atomic?
               jnz 10  # Yes
               ld A (L III)  #  "to" key
               ld E (E)  # CAAR of 'lst'
               call compareAE_F  # Greater or equal?
            while ge  # Yes
10             ld C X  # Go right
               ld A (X CDR)
               ld X (A CDR)  # Invert tree
               ld (A CDR) (L II)  # TOS
               ld (L II) C
            loop
            ld (L V) X  # Save tree
            do
               ld E (X)  # CAR of 'lst'
               atom E  # Atomic?
               if z  # No
                  ld A (L IV)  #  "from" key
                  ld E (E)  # CAAR of 'lst'
                  call compareAE_F  # Less or equal?
                  if le  # Yes
                     ld A (L III)  #  "to" key
                     ld E ((X))  # CAAR of 'lst'
                     call compareAE_F  # Greater or equal?
                     if ge  # Yes
                        call cons_A  # Cons value
                        ld (A) (X)
                        ld (A CDR) (L I)  # Into result
                        ld (L I) A
                     end
                     ld A (X CDR)  # Left subtree?
                     atom (A)
                     if z  # Yes
                        ld C X  # Go left
                        ld X (A)  # Invert tree
                        ld (A) (L II)  # TOS
                        or C SYM  # First visit
                        ld (L II) C
                        ld (L V) X  # Save tree
                        break T
                     end
                  end
               end
               do
                  ld A (L II)  # TOS
                  cmp A Nil  # Empty?
                  if eq  # Yes
                     ld E (L I)  # Return result
                     drop
                     pop X
                     ret
                  end
                  sym A  # Second visit?
                  if z  # Yes
                     ld C (A CDR)  # Nodes
                     ld (L II) (C CDR)  # TOS on up link
                     ld (C CDR) X
                     ld X A
                     ld (L V) X  # Save tree
                     break T
                  end
                  off A SYM  # Set second visit
                  ld C (A CDR)  # Nodes
                  ld (L II) (C)
                  ld (C) X
                  ld X A
                  ld (L V) X  # Save tree
               loop
            loop
         loop
      end
   end
   pop X
   ret

### Property access ###
(code 'putACE 0)
   push X
   ld X (A TAIL)  # Properties
   num X  # Any?
   if z  # Yes
      off X SYM  # Clear 'extern' tag
      atom (X)  # First property atomic?
      if nz  # Yes
         cmp C (X)  # Found flag?
         if eq  # Yes
            cmp E Nil  # Value NIL?
            if eq  # Yes
10             ld X (X CDR)  # Remove property
               sym (A TAIL)  # Extern?
               if nz  # Yes
                  or X SYM  # Set 'extern' tag
               end
               ld (A TAIL) X
20             pop X
               ret
            end
            cmp E TSym  # Value T?
            jeq 20  # No change
            push C
            call consE_C  # New property cell
            ld (C) E
            pop (C CDR)
            ld (X) C
            pop X
            ret
         end
      else
         cmp C ((X) CDR)  # Found property?
         if eq  # Yes
            cmp E Nil  # Value NIL?
            jeq 10  # Yes
            cmp E TSym  # Value T?
            if ne  # No
               ld ((X)) E  # Set new value
            else
               ld (X) C  # Change to flag
            end
            pop X
            ret
         end
      end
      push Y
      do
         ld Y (X CDR)  # Next property
         atom Y  # Any?
      while z  # Yes
         atom (Y)  # Atomic?
         if nz  # Yes
            cmp C (Y)  # Found flag?
            if eq  # Yes
               cmp E Nil  # Value NIL?
               if eq  # Yes
                  ld (X CDR) (Y CDR)  # Remove cell
               else
                  cmp E TSym  # Value T?
                  if ne  # No
                     push C
                     call consE_C  # New property cell
                     ld (C) E
                     pop (C CDR)
                     ld (Y) C  # Store
                  end
                  ld (X CDR) (Y CDR)  # Unlink cell
                  ld X (A TAIL)  # Get tail
                  sym X  # Extern?
                  if z  # No
                     ld (Y CDR) X  # Insert cell in front
                  else
                     off X SYM  # Clear 'extern' tag
                     ld (Y CDR) X  # Insert cell in front
                     or Y SYM  # Set 'extern' tag
                  end
                  ld (A TAIL) Y
                  pop Y
                  pop X
                  ret
               end
            end
         else
            cmp C ((Y) CDR)  # Found property?
            if eq  # Yes
               cmp E Nil  # Value NIL?
               if eq  # Yes
                  ld (X CDR) (Y CDR)  # Remove cell
               else
                  cmp E TSym  # Value T?
                  if ne  # No
                     ld ((Y)) E  # Set new value
                  else
                     ld (Y) C  # Change to flag
                  end
                  ld (X CDR) (Y CDR)  # Unlink cell
                  ld X (A TAIL)  # Get tail
                  sym X  # Extern?
                  if z  # No
                     ld (Y CDR) X  # Insert cell in front
                  else
                     off X SYM  # Clear 'extern' tag
                     ld (Y CDR) X  # Insert cell in front
                     or Y SYM  # Set 'extern' tag
                  end
                  ld (A TAIL) Y
                  pop Y
                  pop X
                  ret
               end
            end
         end
         ld X Y
      loop
      pop Y
      ld X (A TAIL)  # Get properties again
   end
   cmp E Nil  # Value Non-NIL?
   if ne  # Yes
      cmp E TSym  # Flag?
      if ne  # No
         push C
         call consE_C  # New property cell
         ld (C) E
         pop (C CDR)
      end
      push C
      call consC_C  # New first property
      pop (C)
      sym X  # Extern?
      if z  # No
         ld (C CDR) X
      else
         off X SYM  # Clear 'extern' tag
         ld (C CDR) X
         or C SYM  # Set 'extern' tag
      end
      ld (A TAIL) C  # Set new tail
   end
   pop X
   ret

(code 'getnECX_E 0)
   num E  # Need symbol or pair
   jnz argErrEX
   atom E  # List?
   if z  # Yes
      num C  # Numeric key?
      if nz  # Yes
         shr C 4  # Positive?
         if nx  # Yes
            jz retNil  # Return NIL if zero
            do
               dec C  # nth
               jz retE_E
               ld E (E CDR)
            loop
         end
         # Key is negative
         do
            ld E (E CDR)
            dec C  # nth
         until z
         ret
      end
      do  # asoq
         atom (E)  # CAR atomic?
         if z  # No
            cmp C ((E))  # Found?
            break eq  # Yes
         end
         ld E (E CDR)  # Next
         atom E  # Done?
         jnz retNil  # Return NIL
      loop
      ld E ((E) CDR)  # Return CDAR
      ret
   end
   # E is symbolic
   sym (E TAIL)  # External symbol?
   if nz  # Yes
      call dbFetchEX  # Fetch it
   end
(code 'getEC_E 0)
   cmp C ZERO  # Key is zero?
   jeq retE_E  # Get value
   ld A (E TAIL)  # Get tail
   num A  # No properties?
   jnz retNil  # Return NIL
   off A SYM  # Clear 'extern' tag
   atom (A)  # First property atomic?
   if nz  # Yes
      cmp C (A)  # Found flag?
      jeq retT  # Return T
   else
      cmp C ((A) CDR)  # Found property?
      if eq  # Yes
         ld E ((A))  # Return value
         ret
      end
   end
   push X
   do
      ld X (A CDR)  # Next property
      atom X  # Any?
   while z  # Yes
      atom (X)  # Atomic?
      if nz  # Yes
         cmp C (X)  # Found flag?
         if eq  # Yes
            ld (A CDR) (X CDR)  # Unlink cell
            ld A (E TAIL)  # Get tail
            sym A  # Extern?
            if z  # No
               ld (X CDR) A  # Insert cell in front
            else
               off A SYM  # Clear 'extern' tag
               ld (X CDR) A  # Insert cell in front
               or X SYM  # Set 'extern' tag
            end
            ld (E TAIL) X
            ld E TSym  # Return T
            pop X
            ret
         end
      else
         cmp C ((X) CDR)  # Found property?
         if eq  # Yes
            ld (A CDR) (X CDR)  # Unlink cell
            ld A (E TAIL)  # Get tail
            sym A  # Extern?
            if z  # No
               ld (X CDR) A  # Insert cell in front
               ld (E TAIL) X
               ld E ((X))  # Return value
            else
               off A SYM  # Clear 'extern' tag
               ld (X CDR) A  # Insert cell in front
               ld A ((X))  # Return value
               or X SYM  # Set 'extern' tag
               ld (E TAIL) X
               ld E A
            end
            pop X
            ret
         end
      end
      ld A X
   loop
   ld E Nil  # Return NIL
   pop X
   ret

(code 'propEC_E 0)
   push X
   ld A (E TAIL)  # Get tail
   num A  # Properties?
   if z  # Yes
      off A SYM  # Clear 'extern' tag
      atom (A)  # First property atomic?
      if nz  # Yes
         cmp C (A)  # Found flag?
         if eq  # Yes
            ld E C  # Return key
            pop X
            ret
         end
      else
         cmp C ((A) CDR)  # Found property?
         if eq  # Yes
            ld E (A)  # Return property
            pop X
            ret
         end
      end
      do
         ld X (A CDR)  # Next property
         atom X  # Any?
      while z  # Yes
         atom (X)  # Atomic?
         if nz  # Yes
            cmp C (X)  # Found flag?
            if eq  # Yes
               ld (A CDR) (X CDR)  # Unlink cell
               ld A (E TAIL)  # Get tail
               sym A  # Extern?
               if z  # No
                  ld (X CDR) A  # Insert cell in front
               else
                  off A SYM  # Clear 'extern' tag
                  ld (X CDR) A  # Insert cell in front
                  or X SYM  # Set 'extern' tag
               end
               ld (E TAIL) X
               ld E C  # Return key
               pop X
               ret
            end
         else
            cmp C ((X) CDR)  # Found property?
            if eq  # Yes
               ld (A CDR) (X CDR)  # Unlink cell
               ld A (E TAIL)  # Get tail
               sym A  # Extern?
               if z  # No
                  ld (X CDR) A  # Insert cell in front
                  ld (E TAIL) X
                  ld E (X)  # Return property
               else
                  off A SYM  # Clear 'extern' tag
                  ld (X CDR) A  # Insert cell in front
                  ld A (X)  # Return property
                  or X SYM  # Set 'extern' tag
                  ld (E TAIL) X
                  ld E A
               end
               pop X
               ret
            end
         end
         ld A X
      loop
   end
   call cons_A  # New property cell
   ld (A) Nil  # (NIL . key)
   ld (A CDR) C
   call consA_C  # New first property
   ld (C) A
   ld X (E TAIL)  # Get tail
   sym X  # Extern?
   if z  # No
      ld (C CDR) X
   else
      off X SYM  # Clear 'extern' tag
      ld (C CDR) X
      or C SYM  # Set 'extern' tag
   end
   ld (E TAIL) C  # Set new tail
   ld E A  # Return first (new) cell
   pop X
   ret

# (put 'sym1|lst ['sym2|cnt ..] 'sym|0 'any) -> any
(code 'doPut 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   link
   push E  # <L II> 'sym1|lst' item
   ld Y (Y CDR)
   ld E (Y)  # Eval second
   eval+
   push E  # <L I> 'sym2|cnt' key
   link
   do
      ld Y (Y CDR)  # Args
      atom (Y CDR)  # More than one?
   while z  # Yes
      ld C E  # Key
      ld E (L II)  # Current item
      call getnECX_E
      ld (L II) E  # Store item
      ld E (Y)
      eval  # Eval next arg
      ld (L I) E  # Save it
   loop
   ld E (L II)  # Get item
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   ld E (Y)  # Eval 'any'
   eval
   ld A (L II)  # Get symbol
   ld C (L I)  # Get key
   sym (A TAIL)  # External symbol?
   if nz  # Yes
      push E  # Save 'any'
      ld E A  # Get symbol
      cmp C Nil  # Volatile property?
      if ne  # No
         call dbTouchEX  # Touch it
      else
         call dbFetchEX  # else fetch
      end
      ld A E
      pop E
   end
   cmp C ZERO  # Key is zero?
   if eq  # Yes
      call checkVarAX  # Check variable
      ld (A) E  # Set value
   else
      call putACE  # Put value or propery
   end
   drop
   pop Y
   pop X
   ret

# (get 'sym1|lst ['sym2|cnt ..]) -> any
(code 'doGet 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   ld Y (Y CDR)  # Next arg?
   atom Y
   if z  # Yes
      link
      push E  # <L I> 'sym|lst' item
      link
      do
         ld E (Y)
         eval  # Eval next arg
         ld C E  # Key
         ld E (L I)  # Current item
         call getnECX_E
         ld Y (Y CDR)  # More args?
         atom Y
      while z  # Yes
         ld (L I) E  # Save item
      loop
      drop
   end
   pop Y
   pop X
   ret

# (prop 'sym1|lst ['sym2|cnt ..] 'sym) -> var
(code 'doProp 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   link
   push E  # <L II> 'sym|lst' item
   ld Y (Y CDR)  # Next arg
   ld E (Y)
   eval+  # Eval next arg
   push E  # <L I> 'sym2|cnt' key
   link
   do
      ld Y (Y CDR)  # More args?
      atom Y
   while z  # Yes
      ld C E  # Key
      ld E (L II)  # Current item
      call getnECX_E
      ld (L II) E  # Store item
      ld E (Y)
      eval  # Eval next arg
      ld (L I) E  # Save it
   loop
   ld E (L II)  # Get item
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   cmp E Nil  # Can't be NIL
   jeq protErrEX
   ld C (L I)  # Get key
   sym (E TAIL)  # External symbol?
   if nz  # Yes
      cmp C Nil  # Volatile property?
      if ne  # No
         call dbTouchEX  # Touch symbol
      else
         call dbFetchEX  # else fetch
      end
   end
   call propEC_E
   drop
   pop Y
   pop X
   ret

# (; 'sym1|lst [sym2|cnt ..]) -> any
(code 'doSemicol 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   ld Y (Y CDR)  # Next arg?
   atom Y
   if z  # Yes
      link
      push E  # <L I> 'sym|lst' item
      link
      do
         ld C (Y)  # Key
         ld E (L I)  # Current item
         call getnECX_E
         ld Y (Y CDR)  # More args?
         atom Y
      while z  # Yes
         ld (L I) E  # Save item
      loop
      drop
   end
   pop Y
   pop X
   ret

# (=: sym|0 [sym1|cnt .. sym2|0] 'any) -> any
(code 'doSetCol 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (This)  # Get value of This
   ld C (Y)  # sym1|cnt
   ld Y (Y CDR)  # Args
   atom (Y CDR)  # More than one?
   if z  # Yes
      sym (E TAIL)  # External symbol?
      if nz  # Yes
         call dbFetchEX  # Fetch it
      end
      call getEC_E
      do
         ld C (Y)  # sym2|cnt
         ld Y (Y CDR)  # Args
         atom (Y CDR)  # More than one?
      while z  # Yes
         call getnECX_E
      loop
   end
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   sym (E TAIL)  # External symbol?
   if nz  # Yes
      cmp C Nil  # Volatile property?
      if ne  # No
         call dbTouchEX  # Touch symbol
      else
         call dbFetchEX  # else fetch
      end
   end
   push C  # Save key
   push E  # Save symbol
   ld E (Y)  # Eval 'any'
   eval
   pop A  # Retrieve symbol
   pop C  # and key
   cmp C ZERO  # Key is zero?
   if eq  # Yes
      call checkVarAX  # Check variable
      ld (A) E  # Set value
   else
      call putACE  # Put value or propery
   end
   pop Y
   pop X
   ret

# (: sym|0 [sym1|cnt ..]) -> any
(code 'doCol 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (This)  # Get value of This
   sym (E TAIL)  # External symbol?
   if nz  # Yes
      call dbFetchEX  # Fetch it
   end
   ld C (Y)  # Next key
   call getEC_E
   do
      ld Y (Y CDR)  # More args?
      atom Y
   while z  # Yes
      ld C (Y)  # Next key
      call getnECX_E
   loop
   pop Y
   pop X
   ret

# (:: sym|0 [sym1|cnt .. sym2]) -> var
(code 'doPropCol 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (This)  # Get value of This
   ld C (Y)  # Next key
   atom (Y CDR)  # More than one arg?
   if z  # Yes
      sym (E TAIL)  # External symbol?
      if nz  # Yes
         call dbFetchEX  # Fetch it
      end
      call getEC_E
      do
         ld Y (Y CDR)
         ld C (Y)  # Next key
         atom (Y CDR)  # More than one arg?
      while z  # Yes
         call getnECX_E
      loop
   end
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   cmp E Nil  # Can't be NIL
   jeq protErrEX
   sym (E TAIL)  # External symbol?
   if nz  # Yes
      cmp C Nil  # Volatile property?
      if ne  # No
         call dbTouchEX  # Touch symbol
      else
         call dbFetchEX  # else fetch
      end
   end
   call propEC_E
   pop Y
   pop X
   ret

# (putl 'sym1|lst1 ['sym2|cnt ..] 'lst) -> lst
(code 'doPutl 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   link
   push E  # <L II> 'sym|lst' item
   ld Y (Y CDR)  # Next arg
   ld E (Y)
   eval+  # Eval next arg
   push E  # <L I> 'sym2|cnt' key
   link
   do
      ld Y (Y CDR)  # More args?
      atom Y
   while z  # Yes
      ld C E  # Key
      ld E (L II)  # Current item
      call getnECX_E
      ld (L II) E  # Store item
      ld E (Y)
      eval  # Eval next arg
      ld (L I) E  # Save it
   loop
   ld E (L II)  # Get item
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   cmp E Nil  # Can't be NIL
   jeq protErrEX
   sym (E TAIL)  # External symbol?
   if nz  # Yes
      call dbTouchEX  # Touch it
   end
   ld X (E TAIL)  # Skip old properties
   off X SYM  # Clear 'extern' tag
   do
      num X  # More properties?
   while z  # Yes
      ld X (X CDR)
   loop
   ld Y (L I)  # New property list
   do
      atom Y  # Any?
   while z  # Yes
      ld C (Y)
      atom C  # Flag?
      if nz  # Yes
         ld A X
         call consA_X  # New property cell
         ld (X) C
         ld (X CDR) A
      else
         cmp (C) Nil  # Value Nil?
         if ne  # No
            cmp (C) TSym  # Flag?
            if eq  # Yes
               ld C (C CDR)  # Get key
            end
            ld A X
            call consA_X  # New property cell
            ld (X) C
            ld (X CDR) A
         end
      end
      ld Y (Y CDR)
   loop
   sym (E TAIL)  # Extern?
   if nz  # Yes
      or X SYM  # Set 'extern' tag
   end
   ld (E TAIL) X
   ld E (L I)  # Return new property list
   drop
   pop Y
   pop X
   ret

# (getl 'sym1|lst1 ['sym2|cnt ..]) -> lst
(code 'doGetl 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   link
   push E  # <L I> 'sym|lst' item
   link
   do
      ld Y (Y CDR)  # More args?
      atom Y
   while z
      ld E (Y)
      eval  # Eval next arg
      ld C E  # Key
      ld E (L I)  # Current item
      call getnECX_E
      ld (L I) E  # Save item
   loop
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   sym (E TAIL)  # External symbol?
   if nz  # Yes
      call dbFetchEX  # Fetch it
   end
   ld X (E TAIL)  # Get tail
   num X  # No properties?
   if nz  # Yes
      ld E Nil
   else
      off X SYM  # Clear 'extern' tag
      call cons_C  # Copy first cell
      ld (C) (X)
      ld (C CDR) Nil
      tuck C  # Save it
      link
      do
         ld X (X CDR)  # More properties?
         atom X
      while z  # Yes
         call cons_A  # Copy next cell
         ld (A) (X)
         ld (A CDR) Nil
         ld (C CDR) A  # Append
         ld C A
      loop
      ld E (L I)  # Get result
   end
   drop
   pop Y
   pop X
   ret

# (wipe 'sym|lst) -> sym|lst
(code 'doWipe 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   cmp E Nil  # NIL?
   if ne  # No
      atom E  # List?
      if nz  # No
         call wipeEX  # Wipe it
      else
         push E  # Save
         ld C E  # Get list
         do
            ld E (C)  # Next symbol
            call wipeEX  # Wipe it
            ld C (C CDR)
            atom C  # More?
         until nz  # No
         pop E
      end
   end
   pop X
   ret

(code 'wipeEX 0)
   call needSymEX  # Need variable
   ld A (E TAIL)  # Get tail
   sym A  # Extern?
   if z  # No
      call nameA_A  # Get name
      ld (E) Nil  # Clear value
      ld (E TAIL) A  # And properties
      ret
   end
   call nameA_A  # Get name
   shl A 1  # Dirty?
   if nx  # No
      shl A 1  # Loaded?
      if x  # Yes
         ror A 2  # Set "not loaded"
         ld (E) Nil  # Clear value
         or A SYM  # Set 'extern' tag
         ld (E TAIL) A
      end
   end
   ret

# (meta 'obj|typ 'sym ['sym2|cnt ..]) -> any
(code 'doMeta 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   link
   push E  # <L I> 'obj|typ'
   link
   num E  # Need symbol or pair
   jnz argErrEX
   sym E  # Symbol?
   if nz  # Yes
      sym (E TAIL)  # External symbol?
      if nz  # Yes
         call dbFetchEX  # Fetch it
      end
      ld (L I) (E)  # Get value
   end
   ld Y (Y CDR)  # Next arg
   ld E (Y)
   eval  # Eval next arg
   ld C E  # Key
   ld X (L I)  # 'obj|typ'
   call metaCX_E  # Fetch
   do
      ld Y (Y CDR)  # More args?
      atom Y
   while z  # Yes
      ld (L I) E  # Save item
      ld E (Y)
      eval  # Eval next arg
      ld C E  # Key
      ld E (L I)  # Current item
      call getnECX_E
   loop
   drop
   pop Y
   pop X
   ret

(code 'metaCX_E 0)
   do
      atom X  # List?
      jnz retNil  # No
      ld E (X)  # Next item
      num E  # Symbol?
      if z
         sym E
         if nz  # Yes
            call getEC_E  # Propery
            cmp E Nil  # found?
            jne Ret  # No
            cmp S (StkLimit)  # Stack check
            jlt stkErr
            push X
            ld X ((X))  # Try in superclass(es)
            call metaCX_E
            pop X
            cmp E Nil  # found?
            jne Ret  # No
         end
      end
      ld X (X CDR)
   loop

### Case mappings from the GNU Kaffe Project ###
(code 'caseDataA_AC 0)
   ld C A  # Keep character in C
   shr A 4  # Make index
   off A 1
   ld2 (A CaseBlocks)  # Get blocks entry
   add A C  # Add character
   and A (hex "FFFF")  # Limit to 16 bits
   add A A  # Adjust index
   ld2 (A CaseData)  # Get case data
   ret

# (low? 'any) -> sym | NIL
(code 'doLowQ 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   num E  # Number?
   jnz retNil  # Yes
   sym E  # Symbol?
   jz retNil  # No
   call firstCharE_A  # Get first character
   call caseDataA_AC  # Get case info
   and B (hex "1F")  # Character type
   cmp B CHAR_LOWERCASE  # Lower case?
   ldnz E Nil  # No
   ret

# (upp? 'any) -> sym | NIL
(code 'doUppQ 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   num E  # Number?
   jnz retNil  # Yes
   sym E  # Symbol?
   jz retNil  # No
   call firstCharE_A  # Get first character
   call caseDataA_AC  # Get case info
   and B (hex "1F")  # Character type
   cmp B CHAR_UPPERCASE  # Lower case?
   ldnz E Nil  # No
   ret

# (lowc 'any) -> any
(code 'doLowc 2)
   push X
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   num E  # Number?
   if z  # No
      sym E  # Symbol?
      if nz  # Yes
         cmp E Nil  # NIL?
         if ne  # No
            sym (E TAIL)  # External symbol?
            if z  # No
               ld E (E TAIL)
               call nameE_E  # Get name
               link
               push E  # <L II> Name
               push ZERO  # <L I> Result
               ld X S
               link
               push 4  # <S I> Build name
               push X  # <S> Pack status
               ld X (L II) # Get name
               ld C 0  # Index
               do
                  call symCharCX_FACX  # Next char?
               while nz
                  ld E C  # Save C
                  call caseDataA_AC  # Get case info
                  and A (hex "FFFF")
                  shr A 6  # Make index
                  off A 1
                  ld2 (A CaseLower)  # Get lower case entry
                  add A C  # plus character
                  and A (hex "FFFF")
                  ld C (S I)  # Swap status
                  xchg X (S)
                  call charSymACX_CX  # Pack char
                  xchg X (S)  # Swap status
                  ld (S I) C
                  ld C E  # Restore C
               loop
               ld X (L I)  # Get result
               call consSymX_E  # Make transient symbol
               drop
            end
         end
      end
   end
   pop X
   ret

# (uppc 'any) -> any
(code 'doUppc 2)
   push X
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   num E  # Number?
   if z  # No
      sym E  # Symbol?
      if nz  # Yes
         cmp E Nil  # NIL?
         if ne  # No
            sym (E TAIL)  # External symbol?
            if z  # No
               ld E (E TAIL)
               call nameE_E  # Get name
               link
               push E  # <L II> Name
               push ZERO  # <L I> Result
               ld X S
               link
               push 4  # <S I> Build name
               push X  # <S> Pack status
               ld X (L II) # Get name
               ld C 0  # Index
               do
                  call symCharCX_FACX  # Next char?
               while nz
                  ld E C  # Save C
                  call caseDataA_AC  # Get case info
                  and A (hex "FFFF")
                  shr A 6  # Make index
                  off A 1
                  ld2 (A CaseUpper)  # Get upper case entry
                  add A C  # plus character
                  and A (hex "FFFF")
                  ld C (S I)  # Swap status
                  xchg X (S)
                  call charSymACX_CX  # Pack char
                  xchg X (S)  # Swap status
                  ld (S I) C
                  ld C E  # Restore C
               loop
               ld X (L I)  # Get result
               call consSymX_E  # Make transient symbol
               drop
            end
         end
      end
   end
   pop X
   ret

# (fold 'any ['cnt]) -> sym
(code 'doFold 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   num E  # Number?
   if z  # No
      sym E  # Symbol?
      if nz  # Yes
         cmp E Nil  # NIL?
         if ne
            sym (E TAIL)  # External symbol?
            if z  # No
               ld E (E TAIL)
               call nameE_E  # Get name
               link
               push E  # <L II> Name
               push ZERO  # <L I> Result
               link
               ld Y (Y CDR)  # Next arg?
               atom Y
               if nz  # No
                  push 0  # <S II> Default 'cnt' zero
               else
                  call evCntXY_FE  # Eval 'cnt'
                  push E  # <S II> 'cnt'
               end
               push 4  # <S I> Build name
               lea X (L I)
               push X  # <S> Pack status
               ld X (L II) # Get name
               ld C 0  # Index
               do
                  call symCharCX_FACX  # Next char?
               while nz
                  ld E C  # Save C
                  call isLetterOrDigitA_F  # Letter or digit?
                  if nz  # Yes
                     call caseDataA_AC  # Get case info
                     and A (hex "FFFF")
                     shr A 6  # Make index
                     off A 1
                     ld2 (A CaseLower)  # Get lower case entry
                     add A C  # plus character
                     and A (hex "FFFF")
                     ld C (S I)  # Swap status
                     xchg X (S)
                     call charSymACX_CX  # Pack char
                     xchg X (S)  # Swap status
                     ld (S I) C
                     dec (S II)  # Decrement 'cnt'
                     break z
                  end
                  ld C E  # Restore C
               loop
               ld X (L I)  # Get result
               call consSymX_E  # Make transient symbol
               drop
            end
         end
      end
   end
   pop Y
   pop X
   ret

(code 'isLetterOrDigitA_F 0)  # C
   push A
   call caseDataA_AC  # Get case info
   and B (hex "1F")  # Character type
   ld C 1
   zxt
   shl C A
   test C (| CHAR_DIGIT CHAR_LETTER)
   pop A
   ret

# vi:et:ts=3:sw=3
