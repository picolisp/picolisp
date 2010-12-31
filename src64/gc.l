# 12oct10abu
# (c) Software Lab. Alexander Burger

# Mark data
(code 'markE 0)
   ld X 0  # Clear TOS
   do
      do
         cnt E  # Short number?
      while z  # No
         ld A E  # Get cell pointer in A
         off A 15
         test (A CDR) 1  # Already marked?
      while nz  # No
         off (A CDR) 1  # Mark cell
         big E  # Bigum?
         if nz  # Yes
            ld C (A CDR)  # Second digit
            do
               cnt C  # Any?
            while z  # Yes
               test (C BIG) 1  # Marked?
            while nz  # Yes
               off (C BIG) 1  # Else mark it
               ld C (C BIG)  # Next digit
            loop
            break T
         end
         ld C E  # Previous item
         ld E (A)  # Get CAR
         or X 1  # First visit
         ld (A) X  # Keep TOS
         ld X C  # TOS on previous
      loop
      do
         ld A X  # TOS cell pointer in A
         and A -16  # Empty?
         jz ret  # Yes
         test (A) 1  # Second visit?
      while z  # Yes
         ld C X  # TMP
         ld X (A CDR)  # TOS up
         ld (A CDR) E  # Restore CDR
         ld E C  # E up
      loop
      ld C (A)  # Up pointer
      ld (A) E  # Restore CAR
      ld E (A CDR)  # Get CDR
      off C 1  # Set second visit
      ld (A CDR) C  # Store up pointer
   loop

# Reserve cells
(code 'needC 0)
   ld A (Avail)  # Get avail list
   do
      null A  # Enough free cells?
      jeq gc  # No: Collect garbage
      ld A (A)
      dec C
   until z
   ret

# Garbage collector
(code 'gc 0)
   push A  # Save
   push C
   push E
   push X
   push Y
   push Z
   ld (DB) ZERO  # Cut off DB root
   ### Prepare all cells ###
   ld X Nil  # Symbol table
   or (X) 1  # Set mark bit
   add X 32  # Skip padding
   do
      or (X) 1  # Set mark bit
      add X II  # Next symbol
      cmp X GcSymEnd
   until gt
   ld X (Heaps)  # Heap pointer
   do
      ld C CELLS
      do
         or (X CDR) 1  # Set mark bit
         add X II  # Next cell
         dec C  # Done?
      until z  # Yes
      ld X (X)  # Next heap
      null X  # Done?
   until eq  # Yes
   ### Mark ###
   ld Y Intern  # Mark globals
   do
      ld E (Y)  # Next global
      call markE  # Mark it
      add Y I
      cmp Y GcMarkEnd  # Done?
   until eq  # Yes
   ### Mark stack(s) ###
   ld Y L
   do
      null Y  # End of stack?
   while ne  # No
      ld Z (Y)  # Keep end of frame in Z
      do
         add Y I  # End of frame?
         cmp Y Z
      while ne  # No
         ld E (Y)  # Next item
         call markE  # Mark it
      loop
      ld Y (Y)  # Next frame
   loop
   ld Y (Catch)  # Catch frames
   do
      null Y  # Any?
   while ne  # Yes
      ld E (Y I)  # Mark 'tag'
      null E  # Any?
      if ne
         call markE  # Yes
      end
      ld E (Y II)  # Mark 'fin'
      call markE
      ld Y (Y)  # Next frame
   loop
   ld Y (Stack0)  # Search through stack segments
   ld C (Stacks)  # Segment bitmask
   do
      sub Y (StkSize)  # Next segment
      shr C 1  # In use?
      if c  # Yes
         null (Y -II)  # Active?
         if z  # Yes
            ld E (Y -I)  # Mark 'tag'
            call markE
         else
            push Y
            push C
            ld Y ((Y -II))  # Else get saved L
            do
               null Y  # End of stack?
            while ne  # No
               ld Z (Y)  # Keep end of frame in Z
               do
                  add Y I  # End of frame?
                  cmp Y Z
               while ne  # No
                  ld E (Y)  # Next item
                  call markE  # Mark it
               loop
               ld Y (Y)  # Next frame
            loop
            pop C
            pop Y
         end
         continue T
      end
   until z
   # Mark externals
   ld Y Extern
   ld Z 0  # Clear TOS
   do
      do
         off (Y CDR) 1  # Clear mark bit
         ld A (Y CDR)  # Get subtrees
         off (A CDR) 1  # Clear mark bit
         atom (A CDR)  # Right subtree?
      while z  # Yes
         ld C Y  # Go right
         ld Y (A CDR)  # Invert tree
         ld (A CDR) Z  # TOS
         ld Z C
      loop
      do
         ld E (Y)  # Get external symbol
         test (E) 1  # Already marked?
         if nz  # No
            ld A (E TAIL)
            num A  # Any properties?
            if z  # Yes
               off A (| SYM 1)  # Clear 'extern' tag and mark bit
               do
                  ld A (A CDR)  # Skip property
                  off A 1  # Clear mark bit
                  num A  # Find name
               until nz
            end
            rcl A 1  # Dirty or deleted?
            if c  # Yes
               call markE  # Mark external symbol
            end
         end
         ld A (Y CDR)  # Left subtree?
         atom (A)
         if z  # Yes
            ld C Y  # Go left
            ld Y (A)  # Invert tree
            ld (A) Z  # TOS
            or C SYM  # First visit
            ld Z C
            break T
         end
         do
            ld A Z  # TOS
            null A  # Empty?
            jeq 10  # Done
            sym A  # Second visit?
            if z  # Yes
               ld C (A CDR)  # Nodes
               ld Z (C CDR)  # TOS on up link
               ld (C CDR) Y
               ld Y A
               break T
            end
            off A SYM  # Set second visit
            ld C (A CDR)  # Nodes
            ld Z (C)
            ld (C) Y
            ld Y A
         loop
      loop
   loop
10 ld A Db1  # DB root object
   ld (DB) A  # Restore '*DB'
   test (A) 1  # Marked?
   if nz  # No
      ld (A) Nil  # Clear
      ld (A TAIL) DB1  # Set to "not loaded"
   end
   ld Y Extern  # Clean up
   ld Z 0  # Clear TOS
20 do
      do
         ld A (Y CDR)
         atom (A CDR)  # Right subtree?
      while z  # Yes
         ld C Y  # Go right
         ld Y (A CDR)  # Invert tree
         ld (A CDR) Z  # TOS
         ld Z C
      loop
      do
         test ((Y)) 1  # External symbol marked?
         if nz  # No: Remove it
            ld A (Y CDR)  # Get subtrees
            atom A  # Any?
            if nz  # No
               or (Y CDR) 1  # Set mark bit again
               ld Y A  # Use NIL
               jmp 40  # Already traversed
            end
            atom (A)  # Left branch?
            if nz  # No
               or (Y CDR) 1  # Set mark bit again
               ld Y (A CDR)  # Use right branch
               jmp 40  # Already traversed
            end
            atom (A CDR)  # Right branch?
            if nz  # No
               or (Y CDR) 1  # Set mark bit again
               ld Y (A)  # Use left branch
               jmp 20
            end
            ld A (A CDR)  # A on right branch
            ld X (A CDR)  # X on sub-branches
            atom (X)  # Left?
            if nz  # No
               ld (Y) (A)  # Insert right sub-branch
               ld ((Y CDR) CDR) (X CDR)
               jmp 30  # Traverse left branch
            end
            ld X (X)  # Left sub-branch
            do
               ld C (X CDR)  # More left branches?
               atom (C)
            while z  # Yes
               ld A X  # Go down left
               ld X (C)
            loop
            ld (Y) (X)  # Insert left sub-branch
            ld ((A CDR)) (C CDR)
         end
30       ld A (Y CDR)  # Left subtree?
         atom (A)
         if z  # Yes
            ld C Y  # Go left
            ld Y (A)  # Invert tree
            ld (A) Z  # TOS
            or C SYM  # First visit
            ld Z C
            break T
         end
40       do
            ld A Z  # TOS
            null A  # Empty?
            jeq 50  # Done
            sym A  # Second visit?
            if z  # Yes
               ld C (A CDR)  # Nodes
               ld Z (C CDR)  # TOS on up link
               ld (C CDR) Y
               ld Y A
               break T
            end
            off A SYM  # Set second visit
            ld C (A CDR)  # Nodes
            ld Z (C)
            ld (C) Y
            ld Y A
         loop
      loop
   loop
50 ### Clean up ###
   ld Y (Stack0)  # Search through stack segments
   ld C (Stacks)  # Segment bitmask
   ld A 1
   do
      sub Y (StkSize)  # Next segment
      shr C 1  # In use?
      if c  # Yes
         test ((Y -I)) 1  # 'tag' symbol gone?
         if nz  # Yes
            xor (Stacks) A  # Clear in segment bitmask
         else
            null (Y -II)  # Active?
            if nz  # No
               ld X (Y (pack -II "-(EnvMid-EnvApply)"))  # Saved apply stack
               do
                  null X  # End of stack?
               while ne  # No
                  ld Z (X)  # Keep end of frame in Z
                  add X II
                  do
                     off (X) 1  # Clear
                     add X II  # Next gc mark
                     cmp X Z  # End of frame?
                  until ge  # Yes
                  ld X (Z I)  # Next frame
               loop
            end
         end
         jmp 60
      end
   while nz
60    add A A
   loop
   ld Y (EnvApply)  # Apply stack
   do
      null Y  # End of stack?
   while ne  # No
      ld Z (Y)  # Keep end of frame in Z
      add Y II
      do
         off (Y) 1  # Clear
         add Y II  # Next gc mark
         cmp Y Z  # End of frame?
      until ge  # Yes
      ld Y (Z I)  # Next frame
   loop
   ### Sweep ###
   ld X 0  # Avail list
   ld Y (Heaps)  # Heap list in Y
   ld C (GcCount)  # Get cell count
   null C
   if ne  # Non-zero:
      do
         lea Z (Y (- HEAP II))  # Z on last cell in chunk
         do
            test (Z CDR) 1  # Free cell?
            if nz  # Yes
               ld (Z) X  # Link avail
               ld X Z
               dec C
            end
            sub Z II
            cmp Z Y  # Done?
         until lt  # Yes
         ld Y (Y HEAP)  # Next heap
         null Y
      until eq  # All heaps done
      ld (Avail) X  # Set new Avail
      do
         null C  # Count minimum reached?
      while ns  # No
         call heapAlloc  # Allocate heap
         sub C CELLS
      loop
   else  # Zero: Try to free heaps
      ld E Heaps  # Heap list link pointer in E
      do
         ld A (Avail)  # Keep avail list
         ld C CELLS  # Counter
         lea Z (Y (- HEAP II))  # Z on last cell in chunk
         do
            test (Z CDR) 1  # Free cell?
            if nz  # Yes
               ld (Z) X  # Link avail
               ld X Z
               dec C
            end
            sub Z II
            cmp Z Y  # Done?
         until lt  # Yes
         null C  # Remaining cells?
         if nz  # Yes
            lea E (Y HEAP)  # Point to link of next heap
            ld Y (E)  # Next heap
         else
            ld (Avail) A  # Reset avail list
            ld Y (Y HEAP)  # Next heap
            cc free((E))  # Free empty heap
            ld (E) Y  # Store next heap in list link
         end
         null Y  # Next heap?
      until z  # No
   end
   pop Z
   pop Y
   pop X
   pop E
   pop C
   pop A
   ret

# (gc ['cnt]) -> cnt | NIL
(code 'doGc 2)
   push X
   ld X E
   ld E (E CDR)  # Get arg
   ld E (E)
   eval  # Eval
   cmp E Nil  # Nil?
   if eq  # Yes
      call gc  # Collect with default
   else
      ld X E  # Save return value in X
      call xCntEX_FE  # Else get number of megabytes
      shl E 16  # Multiply with CELLS
      ld C (GcCount)  # Save default
      ld (GcCount) E  # Set new value
      call gc  # Collect with given count
      ld (GcCount) C  # Restore default
      ld E X
   end
   pop X
   ret

### Build cons cells ###
(code 'cons_A 0)
   ld A (Avail)  # Get avail list
   null A  # Empty?
   if ne  # No
      ld (Avail) (A)  # Set new avail list
      ret
   end
   call gc  # Collect garbage
   ld A (Avail)  # Get avail list again
   ld (Avail) (A)  # Set new avail list
   ret

(code 'cons_C 0)
   ld C (Avail)  # Get avail list
   null C  # Empty?
   if ne  # No
      ld (Avail) (C)  # Set new avail list
      ret
   end
   call gc  # Collect garbage
   ld C (Avail)  # Get avail list again
   ld (Avail) (C)  # Set new avail list
   ret

(code 'cons_E 0)
   ld E (Avail)  # Get avail list
   null E  # Empty?
   if ne  # No
      ld (Avail) (E)  # Set new avail list
      ret
   end
   call gc  # Collect garbage
   ld E (Avail)  # Get avail list again
   ld (Avail) (E)  # Set new avail list
   ret

(code 'cons_X 0)
   ld X (Avail)  # Get avail list
   null X  # Empty?
   if ne  # No
      ld (Avail) (X)  # Set new avail list
      ret
   end
   call gc  # Collect garbage
   ld X (Avail)  # Get avail list again
   ld (Avail) (X)  # Set new avail list
   ret

(code 'cons_Y 0)
   ld Y (Avail)  # Get avail list
   null Y  # Empty?
   if ne  # No
      ld (Avail) (Y)  # Set new avail list
      ret
   end
   call gc  # Collect garbage
   ld Y (Avail)  # Get avail list again
   ld (Avail) (Y)  # Set new avail list
   ret

(code 'cons_Z 0)
   ld Z (Avail)  # Get avail list
   null Z  # Empty?
   if ne  # No
      ld (Avail) (Z)  # Set new avail list
      ret
   end
   call gc  # Collect garbage
   ld Z (Avail)  # Get avail list again
   ld (Avail) (Z)  # Set new avail list
   ret

(code 'consA_A 0)
   null (Avail)  # Avail list empty?
   if ne  # No
      ld A (Avail)  # Get avail list
      ld (Avail) (A)  # Set new avail list
      ret
   end
   link  # Save A
   push A
   link
   call gc  # Collect garbage
   drop
   ld A (Avail)  # Get avail list
   ld (Avail) (A)  # Set new avail list
   ret

(code 'consC_A 0)
   ld A (Avail)  # Get avail list
   null A  # Empty?
   if ne  # No
      ld (Avail) (A)  # Set new avail list
      ret
   end
   link  # Save C
   push C
   link
   call gc  # Collect garbage
   drop
   ld A (Avail)  # Get avail list again
   ld (Avail) (A)  # Set new avail list
   ret

(code 'consE_A 0)
   ld A (Avail)  # Get avail list
   null A  # Empty?
   if ne  # No
      ld (Avail) (A)  # Set new avail list
      ret
   end
   link  # Save E
   push E
   link
   call gc  # Collect garbage
   drop
   ld A (Avail)  # Get avail list again
   ld (Avail) (A)  # Set new avail list
   ret

(code 'consX_A 0)
   ld A (Avail)  # Get avail list
   null A  # Empty?
   if ne  # No
      ld (Avail) (A)  # Set new avail list
      ret
   end
   link  # Save X
   push X
   link
   call gc  # Collect garbage
   drop
   ld A (Avail)  # Get avail list again
   ld (Avail) (A)  # Set new avail list
   ret

(code 'consA_C 0)
   ld C (Avail)  # Get avail list
   null C  # Empty?
   if ne  # No
      ld (Avail) (C)  # Set new avail list
      ret
   end
   link  # Save A
   push A
   link
   call gc  # Collect garbage
   drop
   ld C (Avail)  # Get avail list again
   ld (Avail) (C)  # Set new avail list
   ret

(code 'consC_C 0)
   null (Avail)  # Avail list empty?
   if ne  # No
      ld C (Avail)  # Get avail list
      ld (Avail) (C)  # Set new avail list
      ret
   end
   link  # Save C
   push C
   link
   call gc  # Collect garbage
   drop
   ld C (Avail)  # Get avail list
   ld (Avail) (C)  # Set new avail list
   ret

(code 'consE_C 0)
   ld C (Avail)  # Get avail list
   null C  # Empty?
   if ne  # No
      ld (Avail) (C)  # Set new avail list
      ret
   end
   link  # Save E
   push E
   link
   call gc  # Collect garbage
   drop
   ld C (Avail)  # Get avail list again
   ld (Avail) (C)  # Set new avail list
   ret

(code 'consA_E 0)
   ld E (Avail)  # Get avail list
   null E  # Empty?
   if ne  # No
      ld (Avail) (E)  # Set new avail list
      ret
   end
   link  # Save A
   push A
   link
   call gc  # Collect garbage
   drop
   ld E (Avail)  # Get avail list again
   ld (Avail) (E)  # Set new avail list
   ret

(code 'consC_E 0)
   ld E (Avail)  # Get avail list
   null E  # Empty?
   if ne  # No
      ld (Avail) (E)  # Set new avail list
      ret
   end
   link  # Save C
   push C
   link
   call gc  # Collect garbage
   drop
   ld E (Avail)  # Get avail list again
   ld (Avail) (E)  # Set new avail list
   ret

(code 'consE_E 0)
   null (Avail)  # Avail list empty?
   if ne  # No
      ld E (Avail)  # Get avail list
      ld (Avail) (E)  # Set new avail list
      ret
   end
   link  # Save E
   push E
   link
   call gc  # Collect garbage
   drop
   ld E (Avail)  # Get avail list
   ld (Avail) (E)  # Set new avail list
   ret

(code 'consX_E 0)
   ld E (Avail)  # Get avail list
   null E  # Empty?
   if ne  # No
      ld (Avail) (E)  # Set new avail list
      ret
   end
   link  # Save X
   push X
   link
   call gc  # Collect garbage
   drop
   ld E (Avail)  # Get avail list again
   ld (Avail) (E)  # Set new avail list
   ret

(code 'consA_X 0)
   ld X (Avail)  # Get avail list
   null X  # Empty?
   if ne  # No
      ld (Avail) (X)  # Set new avail list
      ret
   end
   link  # Save A
   push A
   link
   call gc  # Collect garbage
   drop
   ld X (Avail)  # Get avail list again
   ld (Avail) (X)  # Set new avail list
   ret

(code 'consE_X 0)
   ld X (Avail)  # Get avail list
   null X  # Empty?
   if ne  # No
      ld (Avail) (X)  # Set new avail list
      ret
   end
   link  # Save E
   push E
   link
   call gc  # Collect garbage
   drop
   ld X (Avail)  # Get avail list again
   ld (Avail) (X)  # Set new avail list
   ret

(code 'consY_X 0)
   ld X (Avail)  # Get avail list
   null X  # Empty?
   if ne  # No
      ld (Avail) (X)  # Set new avail list
      ret
   end
   link  # Save Y
   push Y
   link
   call gc  # Collect garbage
   drop
   ld X (Avail)  # Get avail list again
   ld (Avail) (X)  # Set new avail list
   ret

(code 'consA_Y 0)
   ld Y (Avail)  # Get avail list
   null Y  # Empty?
   if ne  # No
      ld (Avail) (Y)  # Set new avail list
      ret
   end
   link  # Save A
   push A
   link
   call gc  # Collect garbage
   drop
   ld Y (Avail)  # Get avail list again
   ld (Avail) (Y)  # Set new avail list
   ret

(code 'consA_Z 0)
   ld Z (Avail)  # Get avail list
   null Z  # Empty?
   if ne  # No
      ld (Avail) (Z)  # Set new avail list
      ret
   end
   link  # Save A
   push A
   link
   call gc  # Collect garbage
   drop
   ld Z (Avail)  # Get avail list again
   ld (Avail) (Z)  # Set new avail list
   ret

(code 'consAC_E 0)
   ld E (Avail)  # Get avail list
   null E  # Empty?
   if ne  # No
      ld (Avail) (E)  # Set new avail list
      ret
   end
   link  # Save A and C
   push A
   push C
   link
   call gc  # Collect garbage
   drop
   ld E (Avail)  # Get avail list again
   ld (Avail) (E)  # Set new avail list
   ret

### Build symbol cells ###
(code 'consSymX_E 0)
   cmp X ZERO  # Name?
   jeq retNil  # No
   ld E (Avail)  # Get avail list
   null E  # Empty?
   if eq  # Yes
      link  # Save name
      push X
      link
      call gc  # Collect garbage
      drop
      ld E (Avail)  # Get avail list again
   end
   ld (Avail) (E)  # Set new avail list
   ld (E) X  # Set new symbol's name
   or E SYM  # Make symbol
   ld (E) E  # Set value to itself
   ret

### Build number cells ###
(code 'boxNum_A 0)
   ld A (Avail)  # Get avail list
   null A  # Empty?
   if eq  # Yes
      call gc  # Collect garbage
      ld A (Avail)  # Get avail list again
   end
   ld (Avail) (A)  # Set new avail list
   ld (A CDR) ZERO  # Set CDR to ZERO
   or B BIG  # Make number
   ret

(code 'boxNum_C 0)
   ld C (Avail)  # Get avail list
   null C  # Empty?
   if eq  # Yes
      call gc  # Collect garbage
      ld C (Avail)  # Get avail list again
   end
   ld (Avail) (C)  # Set new avail list
   ld (C CDR) ZERO  # Set CDR to ZERO
   or C BIG  # Make number
   ret

(code 'boxNum_E 0)
   ld E (Avail)  # Get avail list
   null E  # Empty?
   if eq  # Yes
      call gc  # Collect garbage
      ld E (Avail)  # Get avail list again
   end
   ld (Avail) (E)  # Set new avail list
   ld (E CDR) ZERO  # Set CDR to ZERO
   or E BIG  # Make number
   ret

(code 'boxNum_X 0)
   ld X (Avail)  # Get avail list
   null X  # Empty?
   if eq  # Yes
      call gc  # Collect garbage
      ld X (Avail)  # Get avail list again
   end
   ld (Avail) (X)  # Set new avail list
   ld (X CDR) ZERO  # Set CDR to ZERO
   or X BIG  # Make number
   ret

(code 'boxNumA_A 0)
   push A
   ld A (Avail)  # Get avail list
   null A  # Empty?
   if eq  # Yes
      call gc  # Collect garbage
      ld A (Avail)  # Get avail list again
   end
   ld (Avail) (A)  # Set new avail list
   pop (A)  # Set new cell's CAR
   ld (A CDR) ZERO  # Set CDR to ZERO
   or B BIG  # Make number
   ret

(code 'boxNumE_E 0)
   push E
   ld E (Avail)  # Get avail list
   null E  # Empty?
   if eq  # Yes
      call gc  # Collect garbage
      ld E (Avail)  # Get avail list again
   end
   ld (Avail) (E)  # Set new avail list
   pop (E)  # Set new cell's CAR
   ld (E CDR) ZERO  # Set CDR to ZERO
   or E BIG  # Make number
   ret

(code 'consNumAC_A 0)
   push A
   ld A (Avail)  # Get avail list
   null A  # Empty?
   if eq  # Yes
      link  # Save C
      push C
      link
      call gc  # Collect garbage
      drop
      ld A (Avail)  # Get avail list again
   end
   ld (Avail) (A)  # Set new avail list
   pop (A)  # Set new cell's CAR
   ld (A CDR) C  # Set CDR
   or B BIG  # Make number
   ret

(code 'consNumAE_A 0)
   push A
   ld A (Avail)  # Get avail list
   null A  # Empty?
   if eq  # Yes
      link  # Save E
      push E
      link
      call gc  # Collect garbage
      drop
      ld A (Avail)  # Get avail list again
   end
   ld (Avail) (A)  # Set new avail list
   pop (A)  # Set new cell's CAR
   ld (A CDR) E  # Set CDR
   or B BIG  # Make number
   ret

(code 'consNumCA_C 0)
   push C
   ld C (Avail)  # Get avail list
   null C  # Empty?
   if eq  # Yes
      link  # Save A
      push A
      link
      call gc  # Collect garbage
      drop
      ld C (Avail)  # Get avail list again
   end
   ld (Avail) (C)  # Set new avail list
   pop (C)  # Set new cell's CAR
   ld (C CDR) A  # Set CDR
   or C BIG  # Make number
   ret

(code 'consNumCE_A 0)
   ld A (Avail)  # Get avail list
   null A  # Empty?
   if eq  # Yes
      link  # Save E
      push E
      link
      call gc  # Collect garbage
      drop
      ld A (Avail)  # Get avail list again
   end
   ld (Avail) (A)  # Set new avail list
   ld (A) C  # Set new cell's CAR
   ld (A CDR) E  # Set CDR
   or B BIG  # Make number
   ret

(code 'consNumCE_C 0)
   push C
   ld C (Avail)  # Get avail list
   null C  # Empty?
   if eq  # Yes
      link  # Save E
      push E
      link
      call gc  # Collect garbage
      drop
      ld C (Avail)  # Get avail list again
   end
   ld (Avail) (C)  # Set new avail list
   pop (C)  # Set new cell's CAR
   ld (C CDR) E  # Set CDR
   or C BIG  # Make number
   ret

(code 'consNumCE_E 0)
   null (Avail)  # Avail list empty?
   if eq  # Yes
      link  # Save E
      push E
      link
      call gc  # Collect garbage
      drop
   end
   push E
   ld E (Avail)  # Get avail list
   ld (Avail) (E)  # Set new avail list
   ld (E) C  # Set new cell's CAR
   pop (E CDR)  # Set CDR
   or E BIG  # Make number
   ret

(code 'consNumEA_A 0)
   null (Avail)  # Avail list empty?
   if eq  # Yes
      link  # Save A
      push A
      link
      call gc  # Collect garbage
      drop
   end
   push A
   ld A (Avail)  # Get avail list
   ld (Avail) (A)  # Set new avail list
   ld (A) E  # Set new cell's CAR
   pop (A CDR)  # Set CDR
   or B BIG  # Make number
   ret

(code 'consNumEA_E 0)
   push E
   ld E (Avail)  # Get avail list
   null E  # Empty?
   if eq  # Yes
      link  # Save A
      push A
      link
      call gc  # Collect garbage
      drop
      ld E (Avail)  # Get avail list again
   end
   ld (Avail) (E)  # Set new avail list
   pop (E)  # Set new cell's CAR
   ld (E CDR) A  # Set CDR
   or E BIG  # Make number
   ret

(code 'consNumEC_E 0)
   push E
   ld E (Avail)  # Get avail list
   null E  # Empty?
   if eq  # Yes
      link  # Save C
      push C
      link
      call gc  # Collect garbage
      drop
      ld E (Avail)  # Get avail list again
   end
   ld (Avail) (E)  # Set new avail list
   pop (E)  # Set new cell's CAR
   ld (E CDR) C  # Set CDR
   or E BIG  # Make number
   ret

# vi:et:ts=3:sw=3
