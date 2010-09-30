# 03jul10abu
# (c) Software Lab. Alexander Burger

### Destructive primitives ###
# Remove leading zeroes
(code 'zapZeroA_A 0)
   push A  # Save number
   ld C S  # Short-tail in C
   ld E C  # Null-tail in E
   do
      cnt (A BIG)  # Last cell?
   while z  # No
      null (A DIG)  # Null digit?
      if nz  # No
         ld E C  # New null-tail
      end
      lea C (A BIG)  # New short-tail
      ld A (C)  # Next cell
   loop
   zero (A BIG)  # Trailing short zero?
   if eq  # Yes
      ld A (A DIG)
      null A  # Null digit?
      if nz  # No
         test A (hex "F000000000000000")  # Fit in short number?
         if z  # Yes
            shl A 4  # Make short number
            or A CNT
            ld (C) A  # Store in short-tail
         end
      else
         ld A ((E) DIG)  # Digit in null-tail
         test A (hex "F000000000000000")  # Fit in short number?
         if nz  # No
            ld ((E) BIG) ZERO  # Trim null-tail
         else
            shl A 4  # Make short number
            or A CNT
            ld (E) A  # Store in null-tail
         end
      end
   end
   pop A  # Result
   ret

# Multiply (unsigned) number by 2
(code 'twiceA_A 0)
   cnt A  # A short?
   if nz  # Yes
      xor A 3  # Prepare tag bit
      shl A 1  # Shift left
      jnc Ret  # Done
      rcr A 1  # Else normalize
      shr A 3
      jmp boxNumA_A  # Return bignum
   end
: twiceBigA_A
   push A  # Save bignum
   ld C (A DIG)  # Lowest digit
   shl C 1  # Shift left
   do
      push F  # Save carry
      ld (A DIG) C  # Store digit
      ld E (A BIG)  # Next cell
      cnt E  # End of bignum?
   while z  # No
      ld A E
      ld C (A DIG)  # Next digit
      pop F
      rcl C 1  # Rotate left
   loop
   shr E 4  # Normalize
   pop F
   rcl E 1  # Rotate left
   test E (hex "F000000000000000")  # Fit in short number?
   if z  # Yes
      shl E 4  # Make short number
      or E CNT
   else
      call boxNumE_E  # New cell
   end
   ld (A BIG) E  # Store in final cell
   pop A  # Return bignum
   ret

# Divide (unsigned) number by 2
(code 'halfA_A 0)
   cnt A  # A short?
   if nz  # Yes
      shr A 1  # Shift right
      off A 9  # Clear lowest bit and tag
      or A CNT  # Make short number
      ret
   end
   ld C (A DIG)  # Lowest digit
   ld E (A BIG)  # Next cell
   cnt E  # Any?
   if nz  # No
      shr E 5  # Normalize and shift right
      if nz  # Non-empty
         rcr C 1  # Rotate right
      else
         rcr C 1  # Rotate right
         test C (hex "F000000000000000")  # Fit in short number?
         if z  # Yes
            shl C 4  # Return short number
            or C CNT
            ld A C
            ret
         end
      end
      ld (A DIG) C  # Store lowest digit
      shl E 4  # Make short number
      or E CNT
      ld (A BIG) E  # Store in the cell
      ret
   end
   push A  # Save bignum
   do
      test (E DIG) 1  # Shift bit?
      if nz  # Yes
         setc
      end
      rcr C 1  # Rotate right with carry
      ld (A DIG) C  # Store digit
      ld C (E BIG)  # More cells?
      cnt C
   while z  # Yes
      ld A E  # Advance pointers
      ld E C
      ld C (A DIG)  # Next digit
   loop
   shr C 5  # Normalize and shift right
   if nz  # Non-empty
      rcr (E DIG) 1  # Shift previous digit
      shl C 4  # Make short number
      or C CNT
   else
      ld C (E DIG)  # Shift previous digit
      rcr C 1
      test C (hex "F000000000000000")  # Fit in short number?
      if z  # Yes
         shl C 4  # Make short number
         or C CNT
         ld (A BIG) C
         pop A  # Return bignum
         ret
      end
      ld (E DIG) C
      ld C ZERO
   end
   ld (E BIG) C  # Store in the cell
   pop A  # Return bignum
   ret

# Multiply (unsigned) number by 10
(code 'tenfoldA_A 0)
   cnt A  # A short?
   if nz  # Yes
      shr A 4  # Normalize
      mul 10  # Multiply by 10
      test A (hex "F000000000000000")  # Fit in short number?
      jnz boxNumA_A  # No: Return bignum
      shl A 4  # Make short number
      or A CNT
      ret
   end
   push X
   push A  # Save bignum
   ld X A  # Bignum in X
   ld A (X DIG)  # Multiply lowest digit by 10
   mul 10
   do
      ld (X DIG) A  # Store lower word
      ld E C  # Keep upper word in E
      ld A (X BIG)  # Next cell
      cnt A  # End of bignum?
   while z  # No
      ld X A
      ld A (X DIG)  # Next digit
      mul 10  # Multiply by 10
      add D E  # Add previous upper word
   loop
   shr A 4  # Normalize
   mul 10  # Multiply by 10
   add A E  # Add previous upper word
   test A (hex "F000000000000000")  # Fit in short number?
   if z  # Yes
      shl A 4  # Make short number
      or A CNT
   else
      call boxNumA_A  # Return bignum
   end
   ld (X BIG) A  # Store in final cell
   pop A  # Return bignum
   pop X
   ret

### Non-destructive primitives ###
# Multiply (unsigned) number by 2
(code 'shluA_A 0)
   cnt A  # A short?
   if nz  # Yes
      xor A 3  # Prepare tag bit
      shl A 1  # Shift left
      jnc Ret  # Done
      rcr A 1  # Else normalize
      shr A 3
      jmp boxNumA_A  # Return bignum
   end
   call boxNum_E  # Build new head
   ld (E DIG) (A DIG)  # Lowest digit
   link
   push E  # <L I> Result
   link
   shl (E DIG) 1  # Shift left
   push F  # Save carry
   do
      ld A (A BIG)  # Next cell
      cnt A  # End of bignum?
   while z  # No
      call boxNum_C  # Build next cell
      ld (E BIG) C
      ld E (A DIG)  # Next digit
      pop F
      rcl E 1  # Rotate left
      push F  # Save carry
      ld (C DIG) E
      ld E C
   loop
   shr A 4  # Normalize
   pop F
   rcl A 1  # Rotate left
   test A (hex "F000000000000000")  # Fit in short number?
   if z  # Yes
      shl A 4  # Make short number
      or A CNT
   else
      call boxNumA_A  # New cell
   end
   ld (E BIG) A  # Store in final cell
   ld A (L I)  # Return bignum
   drop
   ret

# Divide (unsigned) number by 2
(code 'shruA_A 0)
   cnt A  # A short?
   if nz  # Yes
      shr A 1  # Shift right
      off A 9  # Clear lowest bit and tag
      or A CNT  # Make short number
      ret
   end
   ld E (A BIG)  # Next cell
   cnt E  # Any?
   if nz  # No
      ld C (A DIG)  # Lowest digit
      shr E 5  # Normalize and shift right
      if nz  # Non-empty
         rcr C 1  # Rotate right
      else
         rcr C 1  # Rotate right
         test C (hex "F000000000000000")  # Fit in short number?
         if z  # Yes
            shl C 4  # Return short number
            or C CNT
            ld A C
            ret
         end
      end
      shl E 4  # Make short number
      or E CNT
      jmp consNumCE_A  # Return bignum
   end
   call boxNum_C  # Build new head
   ld (C DIG) (A DIG)  # Lowest digit
   link
   push C  # <L I> Result
   link
   do
      test (E DIG) 1  # Shift bit?
      if nz  # Yes
         setc
      end
      rcr (C DIG) 1  # Rotate right with carry
      cnt (E BIG)  # More cells?
   while z  # Yes
      call boxNum_A  # Build next digit
      ld (A DIG) (E DIG)
      ld (C BIG) A
      ld E (E BIG)  # Advance pointers
      ld C A
   loop
   ld A (E BIG)  # Final short number
   shr A 5  # Normalize and shift right
   if nz  # Non-empty
      ld E (E DIG)  # Shift previous digit
      rcr E 1
      shl A 4  # Make short number
      or A CNT
      call consNumEA_E  # Last cell
      ld (C BIG) E  # Store in the cell
   else
      ld E (E DIG)  # Shift previous digit
      rcr E 1
      test E (hex "F000000000000000")  # Fit in short number?
      if z  # Yes
         shl E 4  # Make short number
         or E CNT
         ld (C BIG) E
         ld A (L I)  # Return bignum
         drop
         ret
      end
      call boxNum_A  # New cell
      ld (A DIG) E
      ld (C BIG) A
   end
   ld A (L I)  # Return bignum
   drop
   ret

# Bitwise AND of two (unsigned) numbers
(code 'anduAE_A 0)
   cnt A  # A short?
   if nz  # Yes
      cnt E  # E also short?
      if z  # No
         ld E (E DIG)  # Get digit
         shl E 4  # Make short number
         or E CNT
      end
      and A E  # Return short number
      ret
   end
   # A is big
   cnt E  # E short?
   if nz  # Yes
      ld A (A DIG)  # Get digit
      shl A 4  # Make short number
      or A CNT
      and A E  # Return short number
      ret
   end
   # Both are big
   push X
   link
   push ZERO  # <L I> Result
   link
   ld C (A DIG)  # AND first digits
   and C (E DIG)
   call boxNum_X  # Make bignum
   ld (X DIG) C
   ld (L I) X  # Init result
   do
      ld A (A BIG)  # Get tails
      ld E (E BIG)
      cnt A  # End of A?
      if nz  # Yes
         cnt E  # Also end of E?
         if z  # No
            ld E (E DIG)  # Get digit
            shl E 4  # Make short number
            or E CNT
         end
         and A E  # Concat short
         ld (X BIG) A
         ld A (L I)  # Return bignum
         drop
         pop X
         jmp zapZeroA_A  # Remove leading zeroes
      end
      cnt E  # End of E?
      if nz  # Yes
         ld A (A DIG)  # Get digit
         shl A 4  # Make short number
         or A CNT
         and A E  # Concat short
         ld (X BIG) A
         ld A (L I)  # Return bignum
         drop
         pop X
         jmp zapZeroA_A  # Remove leading zeroes
      end
      ld C (A DIG)  # AND digits
      and C (E DIG)
      call consNumCE_C  # New bignum cell
      ld (X BIG) C  # Concat to result
      ld X C
   loop

# Bitwise OR of two (unsigned) numbers
(code 'oruAE_A 0)
   cnt A  # A short?
   if nz  # Yes
      cnt E  # E also short?
      if nz  # Yes
         or A E  # Return short number
         ret
      end
      shr A 4  # Normalize
      or A (E DIG)  # OR digit
      ld E (E BIG)  # Rest of E
      jmp consNumAE_A  # Append rest
   end
   # A is big
   cnt E  # E short?
   if nz  # Yes
      shr E 4  # Normalize
      or E (A DIG)  # OR digit
      ld A (A BIG)  # Rest of A
      jmp consNumEA_A  # Append rest
   end
   # Both are big
   push X
   link
   push ZERO  # <L I> Result
   link
   ld C (A DIG)  # OR first digits
   or C (E DIG)
   call boxNum_X  # Make bignum
   ld (X DIG) C
   ld (L I) X  # Init result
   do
      ld A (A BIG)  # Get tails
      ld E (E BIG)
      cnt A  # End of A?
      if nz  # Yes
         cnt E  # Also end of E?
         if nz  # Yes
            or A E  # Concat short number
         else
            shr A 4  # Normalize
            or A (E DIG)  # OR digit
            ld E (E BIG)  # Rest of E
            call consNumAE_A  # Append rest
         end
         ld (X BIG) A
         ld A (L I)  # Return bignum
         drop
         pop X
         ret
      end
      cnt E  # End of E?
      if nz  # Yes
         shr E 4  # Normalize
         or E (A DIG)  # OR digit
         ld A (A BIG)  # Rest of A
         call consNumEA_A  # Append rest
         ld (X BIG) A
         ld A (L I)  # Return bignum
         drop
         pop X
         ret
      end
      ld C (A DIG)  # OR digits
      or C (E DIG)
      call consNumCE_C  # New bignum cell
      ld (X BIG) C  # Concat to result
      ld X C
   loop

# Bitwise XOR of two (unsigned) numbers
(code 'xoruAE_A 0)
   cnt A  # A short?
   if nz  # Yes
      cnt E  # E also short?
      if nz  # Yes
         xor A E  # Return short number
         or A CNT
         ret
      end
      shr A 4  # Normalize
      xor A (E DIG)  # XOR digit
      ld E (E BIG)  # Rest of E
      call consNumAE_A  # Append rest
      jmp zapZeroA_A  # Remove leading zeroes
   end
   # A is big
   cnt E  # E short?
   if nz  # Yes
      shr E 4  # Normalize
      xor E (A DIG)  # XOR digit
      ld A (A BIG)  # Rest of A
      call consNumEA_A  # Append rest
      jmp zapZeroA_A  # Remove leading zeroes
   end
   # Both are big
   push X
   link
   push ZERO  # <L I> Result
   link
   ld C (A DIG)  # XOR first digits
   xor C (E DIG)
   call boxNum_X  # Make bignum
   ld (X DIG) C
   ld (L I) X  # Init result
   do
      ld A (A BIG)  # Get tails
      ld E (E BIG)
      cnt A  # End of A?
      if nz  # Yes
         cnt E  # Also end of E?
         if nz  # Yes
            xor A E  # Concat short number
            or A CNT
         else
            shr A 4  # Normalize
            xor A (E DIG)  # XOR digit
            ld E (E BIG)  # Rest of E
            call consNumAE_A  # Append rest
         end
         ld (X BIG) A
         ld A (L I)  # Return bignum
         drop
         pop X
         jmp zapZeroA_A  # Remove leading zeroes
      end
      cnt E  # End of E?
      if nz  # Yes
         shr E 4  # Normalize
         xor E (A DIG)  # XOR digit
         ld A (A BIG)  # Rest of A
         call consNumEA_A  # Append rest
         ld (X BIG) A
         ld A (L I)  # Return bignum
         drop
         pop X
         jmp zapZeroA_A  # Remove leading zeroes
      end
      ld C (A DIG)  # XOR digits
      xor C (E DIG)
      call consNumCE_C  # New bignum cell
      ld (X BIG) C  # Concat to result
      ld X C
   loop

# Add two (unsigned) numbers
(code 'adduAE_A 0)
   cnt A  # A short?
   if nz  # Yes
      cnt E  # E also short?
      jz 10  # No: Jump
      off E CNT  # Else clear tag
      add A E  # Add short numbers
      jnc Ret  # Done
      rcr A 1  # Get top bit
      shr A 3  # Normalize
      jmp boxNumA_A  # Return bignum
   end
   # A is big
   cnt E  # E short?
   if nz  # Yes
      xchg A E  # Exchange args
10    shr A 4  # Normalize short
      add A (E DIG)  # Add first digit
      ld E (E BIG)  # Tail in E
      jnc consNumAE_A  # Cons new cell if no carry
      call consNumAE_A  # Else build new head
      link
      push A  # <L I> Result
      link
      do
         cnt E  # Short number?
         if nz  # Yes
            add E (hex "10")  # Add carry
            if nc  # No further carry
               ld (A BIG) E  # Append it
            else  # Again carry
               rcr E 1  # Get top bit
               shr E 3  # Normalize
               call boxNum_C  # New cell
               ld (C DIG) E
               ld (A BIG) C  # Append it
            end
            ld A (L I)  # Return bignum
            drop
            ret
         end
         ld C (E DIG)  # Next digit
         ld E (E BIG)
         add C 1  # Add carry
         if nc  # None
            call consNumCE_E  # New last cell
            ld (A BIG) E
            ld A (L I)  # Return bignum
            drop
            ret
         end
         call consNumCE_C  # New cell
         ld (A BIG) C  # Append it
         ld A C  # Tail of result
      loop
   end
   # Both are big
   push X
   link
   push ZERO  # <L I> Result
   link
   ld C (A DIG)  # Add first digits
   add C (E DIG)
   push F  # Save carry
   call boxNum_X  # Make bignum
   ld (X DIG) C
   ld (L I) X  # Init result
   do
      ld A (A BIG)  # Get tails
      ld E (E BIG)
      cnt A  # End of A?
      if nz  # Yes
         cnt E  # Also end of E?
         jz 20  # No: Jump
         shr A 4  # Normalize A
         shr E 4  # Normalize E
         pop F
         addc A E  # Add final shorts with carry
         shl A 4
         if nc
            or A CNT  # Make short number
         else  # Again carry
            rcr A 1  # Get top bit
            shr A 3  # Normalize
            call boxNumA_A  # Make bignum
         end
         ld (X BIG) A
         ld A (L I)  # Return bignum
         drop
         pop X
         ret
      end
      cnt E  # End of E?
      if nz  # Yes
         xchg A E  # Exchange args
20       shr A 4  # Normalize A
         pop F
         addc A (E DIG)  # Add next digit with carry
         do
            ld E (E BIG)
            if nc  # No carry
               call consNumAE_A  # Append rest
               ld (X BIG) A
               ld A (L I)  # Return bignum
               drop
               pop X
               ret
            end
            call consNumAE_A  # New cell
            ld (X BIG) A  # Concat to result
            ld X A  # Pointer to last cell
            cnt E  # End of E?
            if nz  # Yes
               add E (hex "10")  # Add carry
               if nc  # No further carry
                  ld (X BIG) E  # Append it
               else  # Again carry
                  rcr E 1  # Get top bit
                  shr E 3  # Normalize
                  call boxNum_C  # New cell
                  ld (C DIG) E
                  ld (X BIG) C  # Append it
               end
               ld A (L I)  # Return bignum
               drop
               pop X
               ret
            end
            ld A (E DIG)  # Add carry to next digit
            add A 1
         loop
      end
      ld C (A DIG)  # Add digits
      pop F
      addc C (E DIG)
      push F
      call consNumCE_C  # New bignum cell
      ld (X BIG) C  # Concat to result
      ld X C
   loop

# Subtract two (unsigned) numbers
(code 'subuAE_A 0)
   cnt A  # A short?
   if nz  # Yes
      cnt E  # E also short?
      if nz  # Yes
         off E CNT  # Clear tag
         sub A E  # Subtract short numbers
         jnc Ret  # Done
         xor A -16  # 2-complement
         add A (hex "18")
         ret
      end
      xchg A E  # Exchange args
      call 10  # Subtract short from big
      zero A  # Zero?
      if ne  # No
         or A SIGN  # Set negative
      end
      ret
   end
   # A is big
   cnt E  # E short?
   if nz  # Yes
10    shr E 4  # Normalize short
      ld C (A DIG)
      sub C E  # Subtract from first digit
      ld E (A BIG)  # Tail in E
      if nc  # No borrow
         zero E  # Leading zero?
         jne consNumCE_A  # No: Cons new cell
         test C (hex "F000000000000000")  # Fit in short number?
         jnz consNumCE_A  # No: Cons new cell
         ld A C  # Get digit
         shl A 4  # Make short number
         or A CNT
         ret
      end
      call consNumCE_A  # Else build new head
      link
      push A  # <L I> Result
      link
      do
         cnt E  # Short number?
         if nz  # Yes
            sub E (hex "10")  # Subtract borrow
            if c  # Again borrow: Must be the first pass
               ld A C  # C still has lowest digit
               neg A  # Negate
               shl A 4
               or A (| SIGN CNT)  # Make short negative number
               drop
               ret
            end
            ld (A BIG) E  # Append it
            ld A (L I)  # Return bignum
            drop
            jmp zapZeroA_A  # Remove leading zeroes
         end
         ld C (E DIG)  # Next digit
         ld E (E BIG)
         sub C 1  # Subtract borrow
         if nc  # None
            call consNumCE_E  # New last cell
            ld (A BIG) E  # Append it
            ld A (L I)  # Return bignum
            drop
            jmp zapZeroA_A  # Remove leading zeroes
         end
         call consNumCE_C  # New cell
         ld (A BIG) C  # Append it
         ld A C  # Tail of result
      loop
   end
   # Both are big
   push X
   link
   push ZERO  # <L I> Result
   link
   ld C (A DIG)  # Subtract first digits
   sub C (E DIG)
   push F  # Save borrow
   ld A (A BIG)  # Get tail
   call consNumCA_C  # First bignum cell
   ld (L I) C  # Init result
   do
      ld X C  # Keep last cell in X
      ld E (E BIG)  # Get tail
      cnt E  # End of E?
      if nz  # Yes
         shr E 4  # Normalize E
         do
            cnt A  # Also end of A?
         while z  # No
            ld C (A DIG)  # Subtract final digit with borrow
            ld A (A BIG)  # Next cell
            pop F
            subc C E  # Borrow again?
            if nc  # No
               call consNumCA_C  # Final new bignum tail
               ld (X BIG) C  # Concat to result
20             ld A (L I)  # Return bignum
               drop
               pop X
               jmp zapZeroA_A  # Remove leading zeroes
            end
            push F  # Save borrow
            call consNumCA_C  # New bignum tail
            ld (X BIG) C  # Concat to result
            ld X C  # Keep last cell
            ld E 0
         loop
         shr A 4  # Normalize A
         break T
      end
      cnt A  # End of A?
      if nz  # Yes
         shr A 4  # Normalize A
         do
            pop F
            subc A (E DIG)  # Subtract next digit with borrow
            push F
            call boxNum_C  # New bignum tail
            ld (C DIG) A
            ld (X BIG) C  # Concat to result
            ld X C  # Keep last cell
            ld E (E BIG)  # Next cell
            ld A 0
            cnt E  # Also end of E?
         until nz  # Yes
         shr E 4  # Normalize E
         break T
      end
      ld C (A DIG)  # Subtract digits
      pop F
      subc C (E DIG)
      push F  # Save borrow
      ld A (A BIG)
      call consNumCA_C  # New bignum cell
      ld (X BIG) C  # Concat to result
   loop
   pop F
   subc A E  # Subtract final shorts with borrow
   push F  # Save borrow
   shl A 4
   or A CNT  # Make short number
   ld (X BIG) A
   pop F  # Borrow?
   jnc 20  # No
   ld A (L I)  # Get result
   ld E A  # 2-complement
   do
      not (E DIG)  # Invert
      ld C (E BIG)  # Next digit
      cnt C  # Done?
   while z  # No
      ld E C  # Next digit
   loop
   xor C -16  # Invert final short
   ld (E BIG) C
   ld E A  # Result again
   do
      add (E DIG) 1  # Increment
      jnc 90  # Skip if no carry
      ld C (E BIG)  # Next digit
      cnt C  # Done?
   while z  # No
      ld E C  # Next digit
   loop
   add C (hex "10")  # Increment final short
   ld (E BIG) C
90 drop
   pop X
   call zapZeroA_A  # Remove leading zeroes
   or A SIGN  # Set negative
   ret

# Multiply two (unsigned) numbers
(code 'muluAE_A 0)
   cnt A  # A short?
   if nz  # Yes
      zero A  # Multiply with zero?
      jeq ret  # Yes: Return zero
      shr A 4  # Normalize
      cnt E  # E also short?
      if nz  # Yes
         xchg A E
         shr A 4  # Normalize
         mul E  # Multiply
         null C  # Only lower word?
         if z  # Yes
            test A (hex "F000000000000000")  # Fit in short number?
            if z  # Yes
               shl A 4  # Make short number
               or A CNT
               ret
            end
         end
         shl C 4  # Make short number
         or C CNT
         jmp consNumAC_A  # Return bignum
      end
10    push X
      push Y
      push Z
      ld Y A  # Save digit in Y
      mul (E DIG)  # Multiply lowest digit
      call boxNum_X  # First cell
      ld (X DIG) A
      link
      push X  # <L I> Safe
      link
      ld Z C  # Keep upper word in Z
      do
         ld E (E BIG)
         cnt E  # End of bignum?
      while z  # No
         ld A (E DIG)  # Get next digit
         mul Y  # Multiply digit
         add D Z  # Add previous upper word
         ld Z C
         call boxNum_C  # Next cell
         ld (C DIG) A
         ld (X BIG) C
         ld X C
      loop
      ld A Y  # Retrieve digit
      shr E 4  # Normalize
      mul E  # Multiply
      add D Z  # Add previous upper word
      if z  # Only lower word
         test A (hex "F000000000000000")  # Fit in short number?
         if z  # Yes
            shl A 4  # Make short number
            or A CNT
20          ld (X BIG) A  # Store in final cell
            ld A (L I)  # Return bignum
            drop
            pop Z
            pop Y
            pop X
            ret
         end
      end
      shl C 4  # Make short number
      or C CNT
      call consNumAC_A  # Return bignum
      jmp 20
   end
   # A is big
   cnt E  # E short?
   if nz  # Yes
      zero E  # Multiply with zero?
      jeq ret  # Yes: Return zero
      xchg A E  # Exchange args
      shr A 4  # Normalize
      jmp 10
   end
   # Both are big
   push X
   push Y
   push Z
   ld Y A  # Arg1 in Y
   ld Z E  # Arg2 in Z
   call boxNum_X  # Zero bignum
   ld (X DIG) 0
   link
   push X  # <L I> Safe
   link
   push X  # <L -I> Safe index
   push Y  # <L -II> Arg1 index
   do
      ld A (Y DIG)  # Multiply digits
      mul (Z DIG)
      add D (X DIG)  # Add lower word to safe
      do
         ld (X DIG) A  # Store lower word
         ld E C  # Keep upper word in E
         ld A (X BIG)  # Next safe cell
         cnt A  # End of safe?
         if nz  # Yes
            call boxNum_A  # Extend safe
            ld (A DIG) 0
            ld (X BIG) A
         end
         ld X A
         ld Y (Y BIG)  # Next cell of Arg1
         cnt Y #  End of bignum?
      while z  # No
         ld A (Y DIG)  # Multiply digits
         mul (Z DIG)
         add D (X DIG)  # Add safe
         addc D E  # plus carry
      loop
      ld A Y  # Final short number
      shr A 4  # Normalize
      mul (Z DIG)
      add D (X DIG)  # Add safe
      addc D E  # plus carry
      ld (X DIG) A
      if nz  # Uppper word
         ld A (X BIG)  # Next safe cell
         cnt A  # End of safe?
         if nz  # Yes
            call boxNum_A  # Extend safe
            ld (A DIG) 0
            ld (X BIG) A
         end
         ld (A DIG) C  # Store uppper word
      end
      ld Y (L -II)  # Get Arg1 index
      ld X ((L -I) BIG)  # Advance safe index
      ld (L -I) X
      ld Z (Z BIG)  # Next cell of Arg2
      cnt Z #  End of bignum?
   until nz  # Yes
   ld A Z
   shr A 4  # Normalize
   ld Z A
   mul (Y DIG)  # Multiply digit
   add D (X DIG)  # Add lower word to safe
   do
      ld (X DIG) A  # Store lower word
      ld E C  # Keep upper word in E
      ld A (X BIG)  # Next safe cell
      cnt A  # End of safe?
      if nz  # Yes
         call boxNum_A  # Extend safe
         ld (A DIG) 0
         ld (X BIG) A
      end
      ld X A
      ld Y (Y BIG)  # Next cell of Arg1
      cnt Y #  End of bignum?
   while z  # No
      ld A (Y DIG)  # Multiply digit
      mul Z
      add D (X DIG)  # Add safe
      addc D E  # plus carry
   loop
   ld A Y  # Final short number
   shr A 4  # Normalize
   mul Z  # Multiply digit
   add D (X DIG)  # Add safe
   addc D E  # plus carry
   ld (X DIG) A
   if nz  # Uppper word
      ld A (X BIG)  # Next safe cell
      cnt A  # End of safe?
      if nz  # Yes
         call boxNum_A  # Extend safe
         ld (A DIG) 0
         ld (X BIG) A
      end
      ld (A DIG) C  # Store uppper word
   end
   ld A (L I)  # Return bignum
   drop
   pop Z
   pop Y
   pop X
   jmp zapZeroA_A  # Remove leading zeroes

# Divide two (unsigned) numbers (Knuth Vol.2, p.257)
(code 'divuAE_A 0)
   cnt A  # A short?
   if nz  # Yes
      cnt E  # E also short?
      if nz  # Yes
         shr A 4  # Normalize A
         ld C 0
         shr E 4  # Normalize E
         div E  # Divide
         shl A 4  # Make short number
         or A CNT  # Quotient
         ret
      end
      ld A ZERO  # Else return zero
      ret
   end
   push X
   push Y
   push Z
   link
   push ZERO  # <L III> Quotient
   push A  # <L II> Dividend 'u'
   push E  # <L I> Divisor 'v'
   link
   ld E (A DIG)  # Copy dividend
   call boxNumE_E
   ld (L II) E  # Save new 'u'
   ld X 0  # Calculate 'm'
   do
      ld A (A BIG)  # Next cell of 'u'
      cnt A  # Last one?
   while z  # No
      call boxNum_C  # Copy next digit
      ld (C DIG) (A DIG)
      ld (E BIG) C
      ld E C
      inc X  # Increment 'm'
   loop
   zero A  # Trailing short zero?
   if ne  # No
      shr A 4  # Normalize
      call boxNum_C  # Append in new cell
      ld (C DIG) A
      ld (E BIG) C
      ld E C
      inc X  # Increment 'm'
   end
   ld Z E  # Keep last cell in Z
   push X  # <L -I> 'm'
   ld Y 0  # Last cell
   ld C 0  # Calculate 'n'
   ld A (L I)  # Get divisor
   cnt A  # Short?
   if nz  # Yes
      shr A 4  # Normalize
      call boxNumA_A  # Make big
      ld (L I) A  # Save new 'v'
      ld X A  # Keep in X
      inc C  # 'n' = 1
   else
      call boxNum_X  # Copy divisor
      ld (X DIG) (A DIG)
      ld (L I) X  # Save new 'v'
      do
         inc C  # Increment 'n'
         ld A (A BIG)  # Next cell of 'v'
         cnt A  # Last one?
      while z  # No
         ld E (A DIG)  # Copy next digit
         call boxNumE_E
         ld (X BIG) E  # Append to 'v'
         ld Y X  # Keep last cell
         ld X E
         dec (L -I)  # Decrement 'm'
      loop
      zero A  # Trailing short zero?
      if ne  # No
         shr A 4  # Normalize
         call boxNumA_A  # Append in new cell
         ld (X BIG) A  # Append to 'v'
         ld Y X  # Set last cell
         ld X A
         dec (L -I)  # Decrement 'm'
         inc C  # Increment 'n'
      end
      null (L -I)  # 'm' negative?
      js divUnder  # Yes
   end
   push C  # <L -II> 'n'
   ld A 0  # Append additional cell
   call boxNumA_A
   ld (Z BIG) A
   ld Z 0  # Calculate 'd'
   do
      null (X DIG)  # Max left position?
   while ns  # No
      ld A (L II)  # Shift left 'u'
      call twiceBigA_A
      ld A (L I)  # and 'v'
      call twiceBigA_A
      inc Z  # Increment 'd'
   loop
   push Z  # <L -III> 'd'
   push (X DIG)  # <L -IV> 'v1'
   null Y  # Last cell?
   if nz  # Yes
      ld Y (Y DIG)  # Yes: Get digit
   end
   push Y  # <L -V> Last cell 'v2'
   push 0  # <S> tmp
   do
      ld C (L -I)  # Get 'm'
      ld X (L II)  # and 'u'
      do
         sub C 1
      while ge
         ld X (X BIG)  # Index X -> u
      loop
      ld E (L -II)  # Get 'n' in E
      ld Y X
      ld C 0  # 'u1' in C
      ld A 0  # 'u2' in A
      do
         ld (S) A  # Save 'u3' im tmp
         ld A C  # Shift words
         ld C (Y DIG)
         ld Y (Y BIG)
         sub E 1
      until lt
      ld Z C  # Keep 'r' = 't' in Z,Y
      ld Y A
      cmp C (L -IV)  # 'u1' = 'v1'?
      if ne  # No
         div (L -IV)  # 'q' = 't' / 'v1'
      else
         ld A -1  # 'q' = MAX
      end
      ld E A  # Save 'q' in E
      mul (L -IV)  # 'q' * 'v1'
      sub Y A  # Subtract from 'r'
      subc Z C
      do
         null Z  # 'r' <= MAX?
      while z  # Yes
         ld A E  # 'q' * 'v2'
         mul (L -V)
         cmp C Y  # > lo(r), 'u3'?
      while ge
         if eq
            cmp A (S)  # 'u3' in tmp
            break le
         end
         dec E  # Yes: Decrement 'q'
         add Y (L -IV)  # Increment 'r' by 'v1'
         addc Z 0
      loop
      ld (S) E  # Save 'q' in tmp
      ld Z X  # Get 'x'
      ld Y (L I)  # 'v'
      ld A E  # and 'q'
      mul (Y DIG)  # Multiply lowest digit
      sub (Z DIG) A  # Subtract from 'x'
      addc C 0
      ld E C  # Borrow in E
      do
         ld Y (Y BIG)  # More in 'v'?
         cnt Y
      while z  # Yes
         ld Z (Z BIG)  # Next 'x'
         ld A (S)  # Multiply with 'q' in tmp
         mul (Y DIG)  # 't' in D
         sub (Z DIG) E  # Subtract borrow
         ld E 0
         rcl E 1  # New borrow
         sub (Z DIG) A  # Subtract lo(t)
         addc E C  # Adjust borrow plus hi(t)
      loop
      null E  # Borrow?
      if nz  # Yes
         ld Z (Z BIG)  # Next 'x'
         sub (Z DIG) E  # Subtract borrow
         if c
            dec (S)  # Decrement 'q'
            null (L -I)  # 'm' ?
            if nz  # Yes
               ld Y (L I)  # Get 'v'
               add (X DIG) (Y DIG)  # 'x' += 'v'
               push F  # Save carry
               do
                  ld X (X BIG)  # More?
                  ld Y (Y BIG)
                  cnt Y
               while z  # Yes
                  pop F  # Get carry
                  addc (X DIG) (Y DIG)  # Add digits
                  push F
               loop
               pop F  # Final carry
               addc (X DIG) 0
            end
         end
      end
      ld A (S)  # Get 'q'
      ld C (L III)  # Quotient so far
      call consNumAC_A  # Prepend 'q'
      ld (L III) A  # Store result
      sub (L -I) 1  # Decrement 'm'
   until lt
   ld A (L III)  # Return quotient in A
   call zapZeroA_A
: divDone
   drop
   pop Z
   pop Y
   pop X
   ret
: divUnder  # Dividend smaller than divisor
   ld A ZERO  # Return quotient 0
   jmp divDone

# Remainder of two (unsigned) numbers
(code 'remuAE_A 0)
   cnt A  # A short?
   if nz  # Yes
      cnt E  # E also short?
      if nz  # Yes
         shr A 4  # Normalize A
         ld C 0
         shr E 4  # Normalize E
         div E  # Divide
         ld A C  # Get remainder
         shl A 4  # Make short number
         or A CNT  # Quotient
         ret
      end
      ret  # Remainder is in A
   end
   push X
   push Y
   push Z
   link
   push ZERO  # <L III> Quotient
   push A  # <L II> Dividend 'u'
   push E  # <L I> Divisor 'v'
   link
   ld E (A DIG)  # Copy dividend
   call boxNumE_E
   ld (L II) E  # Save new 'u'
   ld X 0  # Calculate 'm'
   do
      ld A (A BIG)  # Next cell of 'u'
      cnt A  # Last one?
   while z  # No
      call boxNum_C  # Copy next digit
      ld (C DIG) (A DIG)
      ld (E BIG) C
      ld E C
      inc X  # Increment 'm'
   loop
   zero A  # Trailing short zero?
   if ne  # No
      shr A 4  # Normalize
      call boxNum_C  # Append in new cell
      ld (C DIG) A
      ld (E BIG) C
      ld E C
      inc X  # Increment 'm'
   end
   ld Z E  # Keep last cell in Z
   push X  # <L -I> 'm'
   ld Y 0  # Last cell
   ld C 0  # Calculate 'n'
   ld A (L I)  # Get divisor
   cnt A  # Short?
   if nz  # Yes
      shr A 4  # Normalize
      call boxNumA_A  # Make big
      ld (L I) A  # Save new 'v'
      ld X A  # Keep in X
      inc C  # 'n' = 1
   else
      call boxNum_X  # Copy divisor
      ld (X DIG) (A DIG)
      ld (L I) X  # Save new 'v'
      do
         inc C  # Increment 'n'
         ld A (A BIG)  # Next cell of 'v'
         cnt A  # Last one?
      while z  # No
         ld E (A DIG)  # Copy next digit
         call boxNumE_E
         ld (X BIG) E  # Append to 'v'
         ld Y X  # Keep last cell
         ld X E
         dec (L -I)  # Decrement 'm'
      loop
      zero A  # Trailing short zero?
      if ne  # No
         shr A 4  # Normalize
         call boxNumA_A  # Append in new cell
         ld (X BIG) A  # Append to 'v'
         ld Y X  # Set last cell
         ld X A
         dec (L -I)  # Decrement 'm'
         inc C  # Increment 'n'
      end
      null (L -I)  # 'm' negative?
      js remUnder  # Yes
   end
   push C  # <L -II> 'n'
   ld A 0  # Append additional cell
   call boxNumA_A
   ld (Z BIG) A
   ld Z 0  # Calculate 'd'
   do
      null (X DIG)  # Max left position?
   while ns  # No
      ld A (L II)  # Shift left 'u'
      call twiceBigA_A
      ld A (L I)  # and 'v'
      call twiceBigA_A
      inc Z  # Increment 'd'
   loop
   push Z  # <L -III> 'd'
   push (X DIG)  # <L -IV> 'v1'
   null Y  # Last cell?
   if nz  # Yes
      ld Y (Y DIG)  # Yes: Get digit
   end
   push Y  # <L -V> Last cell 'v2'
   push 0  # <S> tmp
   do
      ld C (L -I)  # Get 'm'
      ld X (L II)  # and 'u'
      do
         sub C 1
      while ge
         ld X (X BIG)  # Index X -> u
      loop
      ld E (L -II)  # Get 'n' in E
      ld Y X
      ld C 0  # 'u1' in C
      ld A 0  # 'u2' in A
      do
         ld (S) A  # Save 'u3' im tmp
         ld A C  # Shift words
         ld C (Y DIG)
         ld Y (Y BIG)
         sub E 1
      until lt
      ld Z C  # Keep 'r' = 't' in Z,Y
      ld Y A
      cmp C (L -IV)  # 'u1' = 'v1'?
      if ne  # No
         div (L -IV)  # 'q' = 't' / 'v1'
      else
         ld A -1  # 'q' = MAX
      end
      ld E A  # Save 'q' in E
      mul (L -IV)  # 'q' * 'v1'
      sub Y A  # Subtract from 'r'
      subc Z C
      do
         null Z  # 'r' <= MAX?
      while z  # Yes
         ld A E  # 'q' * 'v2'
         mul (L -V)
         cmp C Y  # > lo(r), 'u3'?
      while ge
         if eq
            cmp A (S)  # 'u3' in tmp
            break le
         end
         dec E  # Yes: Decrement 'q'
         add Y (L -IV)  # Increment 'r' by 'v1'
         addc Z 0
      loop
      ld (S) E  # Save 'q' in tmp
      ld Z X  # Get 'x'
      ld Y (L I)  # 'v'
      ld A E  # and 'q'
      mul (Y DIG)  # Multiply lowest digit
      sub (Z DIG) A  # Subtract from 'x'
      addc C 0
      ld E C  # Borrow in E
      do
         ld Y (Y BIG)  # More in 'v'?
         cnt Y
      while z  # Yes
         ld Z (Z BIG)  # Next 'x'
         ld A (S)  # Multiply with 'q' in tmp
         mul (Y DIG)  # 't' in D
         sub (Z DIG) E  # Subtract borrow
         ld E 0
         rcl E 1  # New borrow
         sub (Z DIG) A  # Subtract lo(t)
         addc E C  # Adjust borrow plus hi(t)
      loop
      null E  # Borrow?
      if nz  # Yes
         ld Z (Z BIG)  # Next 'x'
         sub (Z DIG) E  # Subtract borrow
         if c
            dec (S)  # Decrement 'q'
            ld Y (L I)  # Get 'v'
            add (X DIG) (Y DIG)  # 'x' += 'v'
            push F  # Save carry
            do
               ld X (X BIG)  # More?
               ld Y (Y BIG)
               cnt Y
            while z  # Yes
               pop F  # Get carry
               addc (X DIG) (Y DIG)  # Add digits
               push F
            loop
            pop F  # Final carry
            addc (X DIG) 0
         end
      end
      ld A (S)  # Get 'q'
      ld C (L III)  # Quotient so far
      call consNumAC_A  # Prepend 'q'
      ld (L III) A  # Store result
      sub (L -I) 1  # Decrement 'm'
   until lt
   ld A (L II)  # Get remainder
   call zapZeroA_A
   do
      null (L -III)  # 'd'?
   while nz  # Yes
      call halfA_A  # Shift right (destructive)
      dec (L -III)  # Decrement 'd'
   loop
: remDone
   drop
   pop Z
   pop Y
   pop X
   ret
: remUnder  # Dividend smaller than divisor
   ld A (L II)  # Get remainder
   call zapZeroA_A
   jmp remDone

# Increment a (signed) number
(code 'incE_A 0)
   ld A ONE
   test E SIGN  # Positive?
   jz adduAE_A  # Increment
   off E SIGN  # Make positive
   call subuAE_A  # Subtract
   zero A  # Zero?
   if ne  # No
      or A SIGN  # Negate again
   end
   ret

# Decrement a (signed) number
(code 'decE_A 0)
   ld A ONE
   test E SIGN  # Positive?
   if z  # Yes
      xchg A E
      jmp subuAE_A  # Decrement
   end
   off E SIGN  # Make positive
   call adduAE_A  # Add
   or A SIGN  # Negate again
   ret

# Add two (signed) numbers
(code 'addAE_A 0)
   test A SIGN  # Positive?
   if z  # Yes
      test E SIGN  # Arg also positive?
      jz adduAE_A  # Add [+ A E]
      off E SIGN  # [+ A -E]
      jmp subuAE_A  # Sub
   end
   # Result negatve
   test E SIGN  # Arg positive?
   if z  # [+ -A E]
      off A SIGN
      call subuAE_A  # Sub
   else  # [+ -A -E]
      off A SIGN
      off E SIGN
      call adduAE_A  # Add
   end
   zero A  # Zero?
   if ne  # No
      xor A SIGN  # Negate
   end
   ret

# Subtract to (signed) numbers
(code 'subAE_A 0)
   test A SIGN  # Positive?
   if z  # Yes
      test E SIGN  # Arg also positive?
      jz subuAE_A  # Sub [- A E]
      off E SIGN  # [- A -E]
      jmp adduAE_A  # Add
   end
   # Result negatve
   test E SIGN  # Arg positive?
   if z  # [- -A E]
      off A SIGN
      call adduAE_A  # Add
   else  # [- -A -E]
      off A SIGN
      off E SIGN
      call subuAE_A  # Sub
   end
   zero A  # Zero?
   if ne  # No
      xor A SIGN  # Negate
   end
   ret

### Comparisons ###
(code 'cmpNumAE_F 0)
   test A SIGN  # A positive?
   if z  # Yes
      test E SIGN  # E also positive?
      jz cmpuAE_F  # Yes [A E]
      clrc  # gt [A -E]
      ret
   end
   # A negative
   test E SIGN  # E positive?
   if z  # Yes
      or B B  # nz [-A E]
      setc  # lt
      ret
   end
   xchg A E  # [-A -E]
   off A SIGN
   off E SIGN

# Compare two (unsigned) numbers
(code 'cmpuAE_F 0)
   cnt A  # A short?
   if nz  # Yes
      cnt E  # E also short?
      if nz  # Yes
         cmp A E  # F
         ret
      end
      or B B  # nz (E is big)
      setc  # lt
      ret
   end
   # A is big
   cnt E  # E short?
   if nz  # Yes
      clrc  # gt (E is short)
      ret
   end
   # Both are big
   push X
   push Y
   ld X 0  # Clear reverse pointers
   ld Y 0
   do
      ld C (A BIG)  # Tails equal?
      cmp C (E BIG)
      if eq  # Yes
         do
            ld C (A DIG)  # Compare digits
            cmp C (E DIG)
         while eq
            null X  # End of reversed list?
            if z  # Yes
               pop Y  # eq
               pop X
               ret
            end
            ld C (X BIG)  # Restore A
            ld (X BIG) A
            ld A X
            ld X C
            ld C (Y BIG)  # Restore E
            ld (Y BIG) E
            ld E Y
            ld Y C
         loop
         push F
         break T
      end
      cnt C  # End of A?
      if nz  # Yes
         cnt (E BIG)  # Also end of E?
         if nz  # Yes
            cmp C (E BIG)  # F
         else
            or B B  # nz (E is bigger)
            setc  # lt
         end
         push F
         break T
      end
      cnt (E BIG)  # End of E?
      if nz  # Yes
         clrc  # gt
         push F
         break T
      end
      ld (A BIG) X  # Reverse A
      ld X A
      ld A C
      ld C (E BIG)  # Reverse E
      ld (E BIG) Y
      ld Y E
      ld E C
   loop
   do
      null X  # Reversed?
   while nz  # Yes
      ld C (X BIG)  # Restore A
      ld (X BIG) A
      ld A X
      ld X C
      ld C (Y BIG)  # Restore E
      ld (Y BIG) E
      ld E Y
      ld Y C
   loop
   pop F  # Return flags
   pop Y
   pop X
   ret

### Conversions ###
# Make number from symbol
(code 'symToNumXA_FE 0)
   link
   push ZERO  # <L I> Safe
   link
   push A  # <L -I> Scale
   push 0  # <L -II> Sign flag
   push 0  # <L -III> Fraction flag
   ld C 0
   call symByteCX_FACX  # Get first byte
   jz 99  # None
   do
      cmp B 32  # Skip white space
   while le
      call symByteCX_FACX  # Next byte
      jz 99  # None
   loop
   cmp B (char "+")  # Plus sign?
   jz 10  # Yes
   cmp B (char "-")  # Plus sign?
   if eq  # Yes
      or (L -II) 1  # Set Sign
10    call symByteCX_FACX  # Next byte
      jz 99  # None
   end
   sub A (char "0")  # First digit
   cmp A 10  # Too big?
   jnc 99  # Return NO
   shl A 4  # Make short number
   or A CNT
   ld (L I) A  # Save
   do
      call symCharCX_FACX  # More?
   while nz  # Yes
      test (L -III) 1  # Fraction?
      if nz  # Yes
         null (L -I)  # Scale?
         if z  # No
            sub A (char "0")  # Next digit
            cmp A 10  # Too big?
            jnc 99  # Return NO
            cmp A 5  # Round?
            if ge  # Yes
               ld A ONE  # Increment
               ld E (L I)
               push C
               call adduAE_A
               pop C
               ld (L I) A
            end
            do
               call symByteCX_FACX  # More?
            while nz  # Yes
               sub A (char "0")  # Next digit
               cmp A 10  # Too big?
               jnc 99  # Return NO
            loop
            break T
         end
      end
      cmp A (Sep0)  # Decimal separator?
      if eq  # Yes
         test (L -III) 1  # Fraction?
         jnz 99  # Return NO
         or (L -III) 1  # Set Fraction
      else
         cmp A (Sep3)  # Thousand separator?
         if ne  # No
            sub A (char "0")  # Next digit
            cmp A 10  # Too big?
            jnc 99  # Return NO
            push C  # Save symByte args
            push X
            push A  # Save digit
            ld A (L I)  # Multiply number by 10
            call tenfoldA_A
            ld (L I) A  # Save
            pop E  # Get digit
            shl E 4  # Make short number
            or E CNT
            call adduAE_A  # Add to number
            ld (L I) A  # Save again
            pop X  # Pop symByte args
            pop C
            test (L -III) 1  # Fraction?
            if nz  # Yes
               dec (L -I)  # Decrement Scale
            end
         end
      end
   loop
   test (L -III) 1  # Fraction?
   if nz  # Yes
      do
         sub (L -I) 1  # Decrement Scale
      while nc  # >= 0
         ld A (L I)  # Multiply number by 10
         call tenfoldA_A
         ld (L I) A  # Save
      loop
   end
   ld E (L I)  # Get result
   test (L -II) 1  # Sign?
   if nz  # Yes
      zero E  # Zero?
      if ne  # No
         xor E SIGN  # Negate
      end
   end
   setc  # Return YES
99 drop
   ret

# Format number to output, length, or symbol
(code 'fmtNum0AE_E 0)
   ld (Sep3) 0  # Thousand separator 0
   ld (Sep0) 0  # Decimal separator 0
(code 'fmtNumAE_E)
   push C
   push X
   push Y
   push Z
   link
   push ZERO  # <L I> Name
   link
   push A  # <L -I> Scale
   ld A E  # Get number
   cnt A  # Short number?
   if nz  # Yes
      push 16  # <L -II> mask
   else
      push 1  # <L -II> mask
   end
   shr B 3  # Get sign bit
   push A  # <L -III> Sign flag
   off E SIGN
   # Calculate buffer size
   ld A 19  # Decimal length of 'cnt' (60 bit)
   ld C E  # Get number
   do
      cnt C  # Last digit?
   while z  # No
      add A 20  # Add decimal length of 'digit' (64 bit)
      ld C (C BIG)
   loop
   add A 17  # Round up
   ld C 0  # Divide by 18
   div 18
   shl A 3  # Word count
   sub S A  # Space for incrementor
   ld (S) 1  # Init to '1'
   ld X S  # Keep pointer to incrementor in X
   sub S A  # <S III> Accumulator
   cmp S (StkLimit)  # Stack check
   jlt stkErr
   ld (S) 0  # Init to '0'
   push S # <S II> Top of accumulator
   push X  # <S I> Pointer to incrementor
   push X  # <S> Top of incrementor
   do
      cnt E  # Short number?
      ldnz Z E  # Yes
      if z
         ld Z (E DIG)  # Digit in Z
      end
      do
         ld A Z  # Current digit
         test A (L -II)  # Test next bit with mask
         if nz
            # Add incrementor to accumulator
            ld C 0  # Carry for BCD addition
            lea X (S III)  # Accumulator
            ld Y (S I)  # Incrementor
            do
               cmp X (S II)  # X > Top of accumulator?
               if gt  # Yes
                  add (S II) 8  # Extend accumulator
                  ld (X) 0  # with '0'
               end
               ld A (X)
               add A (Y)  # Add BCD
               add A C  # Add BCD-Carry
               ld C 0  # Clear BCD-Carry
               cmp A 1000000000000000000  # BCD overflow?
               if nc  # Yes
                  sub A 1000000000000000000
                  ld C 1  # Set BCD-Carry
               end
               ld (X) A  # Store BCD digit in accumulator
               add X 8
               add Y 8
               cmp Y (S)  # Reached top of incrementor?
            until gt  # Yes
            null C  # BCD-Carry?
            if ne  # Yes
               add (S II) 8  # Extend accumulator
               ld (X) 1  # With '1'
            end
         end
         # Shift incrementor left
         ld C 0  # Clear BCD-Carry
         ld Y (S I)  # Incrementor
         do
            ld A (Y)
            add A A  # Double
            add A C  # Add BCD-Carry
            ld C 0  # Clear BCD-Carry
            cmp A 1000000000000000000  # BCD overflow?
            if nc  # Yes
               sub A 1000000000000000000
               ld C 1  # Set BCD-Carry
            end
            ld (Y) A  # Store BCD digit in incrementor
            add Y 8
            cmp Y (S)  # Reached top of incrementor?
         until gt  # Yes
         null C  # BCD-Carry?
         if ne  # Yes
            add (S) 8  # Extend incrementor
            ld (Y) 1  # With '1'
         end
         shl (L -II) 1  # Shift bit mask
      until z
      cnt E  # Short number?
   while z  # No
      ld E (E BIG)  # Next digit
      cnt E  # Short number?
      if nz  # Yes
         ld A 16  # Mask
      else
         ld A 1
      end
      ld (L -II) A  # Set bit mask
   loop
   ld Y (S II)  # Top of accumulator
   lea Z (S III)  # Accumulator
   null (L -I)  # Scale negative?
   if s  # Yes
      cmp (L -I) -1  # Direct print?
      if eq  # Yes
         test (L -III) 1  # Sign?
         if nz  # Yes
            ld B (char "-")  # Output sign
            call (PutB)
         end
         ld A (Y)  # Output highest word
         call outWordA
         do
            sub Y 8  # More?
            cmp Y Z
         while ge  # Yes
            ld A (Y)  # Output words in reverse order
            ld E 100000000000000000  # Digit scale
            do
               ld C 0  # Divide by digit scale
               div E
               push C  # Save remainder
               add B (char "0")  # Output next digit
               call (PutB)
               cmp E 1  # Done?
            while ne  # No
               ld C 0  # Divide digit scale by 10
               ld A E
               div 10
               ld E A
               pop A  # Get remainder
            loop
         loop
      else  # Calculate length
         ld A Y  # Top of accumulator
         sub A Z  # Accumulator
         shr A 3  # Number of accumulator words
         mul 18  # Number of digits
         ld E A
         ld A (Y)  # Length of highest word
         do
            inc E  # Increment length
            ld C 0  # Divide by 10
            div 10
            null A  # Done?
         until z  # Yes
         test (L -III) 1  # Sign?
         if nz  # Yes
            inc E  # Space for '-'
         end
         shl E 4  # Make short number
         or E CNT
      end
      drop
   else
      ld C 4  # Build name
      lea X (L I)
      test (L -III) 1  # Sign?
      if nz  # Yes
         ld B (char "-")  # Insert sign
         call byteSymBCX_CX
      end
      push C  # Save name index
      ld A Y  # Top of accumulator
      sub A Z  # Accumulator
      shr A 3  # Number of accumulator words
      mul 18  # Number of digits
      ld E A  # Calculate length-1
      ld A (Y)  # Highest word
      do
         ld C 0  # Divide by 10
         div 10
         null A  # Done?
      while nz  # No
         inc E  # Increment length
      loop
      pop C  # Restore name index
      sub E (L -I)  # Scale
      ld (L -I) E  # Decrement by Length-1
      if lt  # Scale < 0
         ld B (char "0")  # Prepend '0'
         call byteSymBCX_CX
         ld A (Sep0)  # Prepend decimal separator
         call charSymACX_CX
         do
            cmp (L -I) -1   # Scale
         while lt
            inc (L -I)  # Increment scale
            ld B (char "0")  # Ouput zeroes
            call byteSymBCX_CX
         loop
      end
      ld A (Y)  # Pack highest word
      call fmtWordACX_CX
      do
         sub Y 8  # More?
         cmp Y Z
      while ge  # Yes
         ld A (Y)  # Pack words in reverse order
         ld E 100000000000000000  # Digit scale
         do
            push A
            call fmtScaleCX_CX  # Handle scale character(s)
            pop A
            push C  # Save name index
            ld C 0  # Divide by digit scale
            div E
            xchg C (S)  # Save remainder, restore name index
            add B (char "0")  # Pack next digit
            call byteSymBCX_CX
            cmp E 1  # Done?
         while ne  # No
            push C  # Save name index
            ld C 0  # Divide digit scale by 10
            ld A E
            div 10
            pop C  # Restore name index
            ld E A
            pop A  # Get remainder
         loop
      loop
      ld X (L I)  # Get name
      drop
      call consSymX_E
   end
   pop Z
   pop Y
   pop X
   pop C
   ret

(code 'fmtWordACX_CX 0)
   cmp A 9  # Single digit?
   if gt  # No
      ld E C  # Save C
      ld C 0  # Divide by 10
      div 10
      push C  # Save remainder
      ld C E  # Restore C
      call fmtWordACX_CX  # Recurse
      call fmtScaleCX_CX  # Handle scale character(s)
      pop A
   end
   add B (char "0")  # Make ASCII digit
   jmp byteSymBCX_CX

(code 'fmtScaleCX_CX 0)
   null (L -I)  # Scale null?
   if z  # Yes
      ld A (Sep0)  # Output decimal separator
      call charSymACX_CX
   else
      null (Sep3)  # Thousand separator?
      if nz  # Yes
         ld A (L -I)  # Scale > 0?
         null A
         if nsz  # Yes
            push C
            ld C 0  # Modulus 3
            div 3
            null C
            pop C
            if z
               ld A (Sep3)  # Output thousand separator
               call charSymACX_CX
            end
         end
      end
   end
   dec (L -I)  # Decrement scale
   ret

# (format 'num ['cnt ['sym1 ['sym2]]]) -> sym
# (format 'sym|lst ['cnt ['sym1 ['sym2]]]) -> num
(code 'doFormat 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   link
   push E  # <L I> 'num' | 'sym'
   link
   ld Y (Y CDR)  # Second arg
   ld E (Y)
   eval  # Eval 'cnt'
   cmp E Nil  # Any?
   if eq  # No
      ld E 0  # Zero
   else
      call xCntEX_FE  # Extract 'cnt'
   end
   push E  # <L -I> Scale
   push (char ".")  # <L -II> Sep0
   push 0  # Sep3
   ld Y (Y CDR)  # Third arg?
   atom Y
   if z  # Yes
      ld E (Y)
      eval  # Eval 'sym1'
      num E  # Need symbol
      jnz symErrEX
      sym E
      jz symErrEX
      call firstCharE_A
      ld (L -II) A  # Sep0
      ld Y (Y CDR)  # Fourth arg?
      atom Y
      if z  # Yes
         ld E (Y)
         eval  # Eval 'sym2'
         num E  # Need symbol
         jnz symErrEX
         sym E
         jz symErrEX
         call firstCharE_A
         ld (S) A
      end
   end
   pop (Sep3)  # Get Sep3
   pop (Sep0)  # and Sep0
   ld E (L I)  # Get 'num' | 'sym'
   num E  # Number?
   if nz  # Yes
      pop A  # Get scale
      call fmtNumAE_E  # Convert to string
   else
      sym E  # Symbol?
      if nz  # Yes
         ld X (E TAIL)
         call nameX_X  # Get name
      else
         link
         push ZERO  # <L II> Number safe
         push ZERO  # <L I> Result
         ld C 4  # Build name
         ld X S
         link
         call packECX_CX
         ld X (L I)  # Get result
         drop
      end
      pop A  # Get scale
      call symToNumXA_FE  # Convert to number
      if nc  # Failed
         ld E Nil
      end
   end
   drop
   pop Y
   pop X
   ret

### Arithmetics ###
# (+ 'num ..) -> num
(code 'doAdd 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)
   eval  # Eval first arg
   cmp E Nil
   if ne  # Non-NIL
      num E  # Number?
      jz numErrEX  # No
      link
      push ZERO  # <L II> Safe
      push E  # <L I> Result
      link
      do
         ld Y (Y CDR)  # More args?
         atom Y
      while z  # Yes
         ld E (Y)
         eval  # Eval next arg
         cmp E Nil
         jz 10  # Abort if NIL
         num E  # Number?
         jz numErrEX  # No
         ld (L II) E  # Save arg
         ld A (L I)  # Result
         call addAE_A  # Add
         ld (L I) A  # Result
      loop
      ld E (L I)  # Result
10    drop
   end
   pop Y
   pop X
   ret

# (- 'num ..) -> num
(code 'doSub 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)
   eval  # Eval first arg
   cmp E Nil
   if ne  # Non-NIL
      num E  # Number?
      jz numErrEX  # No
      ld Y (Y CDR)  # More than one arg?
      atom Y
      if nz  # No: Unary minus
         zero E  # Zero?
         if ne  # No
            xor E SIGN  # Negate
         end
      else
         link
         push ZERO  # <L II> Safe
         push E  # <L I> Result
         link
         do
            ld E (Y)
            eval  # Eval next arg
            cmp E Nil
            jz 10  # Abort if NIL
            num E  # Number?
            jz numErrEX  # No
            ld (L II) E  # Save arg
            ld A (L I)  # Result
            call subAE_A  # Subtract
            ld (L I) A  # Result
            ld Y (Y CDR)  # More args?
            atom Y
         until nz  # No
         ld E (L I)  # Result
10       drop
      end
   end
   pop Y
   pop X
   ret

# (inc 'num) -> num
# (inc 'var ['num]) -> num
(code 'doInc 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)
   eval  # Eval first arg
   cmp E Nil
   if ne  # Non-NIL
      link
      push E  # <L I/II> First arg
      link
      num E  # Number?
      if nz  # Yes
         call incE_A  # Increment it
      else
         call checkVarEX
         sym E  # Symbol?
         if nz  # Yes
            sym (E TAIL)  # External symbol?
            if nz  # Yes
               call dbTouchEX  # Touch it
            end
         end
         ld Y (Y CDR)  # Next arg?
         atom Y
         if nz  # No
            ld E (E)  # Get VAL
            cmp E Nil  # NIL?
            ldz A E
            if ne  # No
               num E  # Number?
               jz numErrEX  # No
               call incE_A  # Increment it
               ld ((L I)) A  # Set new value
            end
         else
            ld E (Y)
            eval  # Eval next arg
            tuck E  # <L I> Second arg
            link
            ld A ((L II))  # First arg's VAL
            cmp A Nil  # NIL?
            if ne  # No
               num A  # Number?
               jz numErrAX  # No
               ld E (L I)  # Second arg
               cmp E Nil  # NIL?
               ldz A E
               if ne  # No
                  num E
                  jz numErrEX  # No
                  call addAE_A  # Add
                  ld ((L II)) A  # Set new value
               end
            end
         end
      end
      ld E A  # Get result
      drop
   end
   pop Y
   pop X
   ret

# (dec 'num) -> num
# (dec 'var ['num]) -> num
(code 'doDec 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)
   eval  # Eval first arg
   cmp E Nil
   if ne  # Non-NIL
      link
      push E  # <L I/II> First arg
      link
      num E  # Number?
      if nz  # Yes
         call decE_A  # Decrement it
      else
         call checkVarEX
         sym E  # Symbol?
         if nz  # Yes
            sym (E TAIL)  # External symbol?
            if nz  # Yes
               call dbTouchEX  # Touch it
            end
         end
         ld Y (Y CDR)  # Next arg?
         atom Y
         if nz  # No
            ld E (E)  # Get VAL
            cmp E Nil  # NIL?
            ldz A E
            if ne  # No
               num E  # Number?
               jz numErrEX  # No
               call decE_A  # Decrement it
               ld ((L I)) A  # Set new value
            end
         else
            ld E (Y)
            eval  # Eval next arg
            tuck E  # <L I> Second arg
            link
            ld A ((L II))  # First arg's VAL
            cmp A Nil  # NIL?
            if ne  # No
               num A  # Number?
               jz numErrAX  # No
               ld E (L I)  # Second arg
               cmp E Nil  # NIL?
               ldz A E
               if ne  # No
                  num E
                  jz numErrEX  # No
                  call subAE_A  # Subtract
                  ld ((L II)) A  # Set new value
               end
            end
         end
      end
      ld E A  # Get result
      drop
   end
   pop Y
   pop X
   ret

# (* 'num ..) -> num
(code 'doMul 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)
   eval  # Eval first arg
   cmp E Nil
   if ne  # Non-NIL
      num E  # Number?
      jz numErrEX  # No
      ld B 0  # Init sign
      test E SIGN
      if nz
         off E SIGN
         inc B
      end
      link
      push ZERO  # <L II> Safe
      push E  # <L I> Result
      link
      push A  # <L -I> Sign flag
      do
         ld Y (Y CDR)  # More args?
         atom Y
      while z  # Yes
         ld E (Y)
         eval  # Eval next arg
         cmp E Nil
         jz 10  # Abort if NIL
         num E  # Number?
         jz numErrEX  # No
         test E SIGN  # Arg negative?
         if nz  # Yes
            off E SIGN  # Make argument positive
            xor (L -I) 1  # Toggle result sign
         end
         ld (L II) E  # Save arg
         ld A (L I)  # Result
         call muluAE_A  # Multiply
         ld (L I) A  # Result
      loop
      ld E (L I)  # Result
      test (L -I) 1  # Sign?
      if nz  # Yes
         zero E  # Zero?
         if ne  # No
            or E SIGN  # Set negative
         end
      end
10    drop
   end
   pop Y
   pop X
   ret

# (*/ 'num1 ['num2 ..] 'num3) -> num
(code 'doMulDiv 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)
   eval  # Eval first arg
   cmp E Nil
   if ne  # Non-NIL
      num E  # Number?
      jz numErrEX  # No
      ld B 0  # Init sign
      test E SIGN
      if nz
         off E SIGN
         inc B
      end
      link
      push ZERO  # <L II> Safe
      push E  # <L I> Result
      link
      push A  # <L -I> Sign flag
      do
         ld Y (Y CDR)  # Next arg
         ld E (Y)
         eval  # Eval next arg
         cmp E Nil
         jz 10  # Abort if NIL
         num E  # Number?
         jz numErrEX  # No
         test E SIGN  # Arg negative?
         if nz  # Yes
            off E SIGN  # Make argument positive
            xor (L -I) 1  # Toggle result sign
         end
         ld (L II) E  # Save arg
         atom (Y CDR)  # More args?
      while z  # Yes
         ld A (L I)  # Result
         call muluAE_A  # Multiply
         ld (L I) A  # Result
      loop
      zero E  # Zero?
      jeq divErrX  # Yes
      ld A E  # Last argument
      call shruA_A  # / 2
      ld E (L I)  # Product
      call adduAE_A  # Add for rounding
      ld E (L II)  # Last argument
      call divuAE_A  # Divide
      ld E A  # Result
      test (L -I) 1  # Sign?
      if nz  # Yes
         zero E  # Zero?
         if ne  # No
            or E SIGN  # Set negative
         end
      end
10    drop
   end
   pop Y
   pop X
   ret

# (/ 'num ..) -> num
(code 'doDiv 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)
   eval  # Eval first arg
   cmp E Nil
   if ne  # Non-NIL
      num E  # Number?
      jz numErrEX  # No
      ld B 0  # Init sign
      test E SIGN
      if nz
         off E SIGN
         inc B
      end
      link
      push ZERO  # <L II> Safe
      push E  # <L I> Result
      link
      push A  # <L -I> Sign flag
      do
         ld Y (Y CDR)  # More args?
         atom Y
      while z  # Yes
         ld E (Y)
         eval  # Eval next arg
         cmp E Nil
         jz 10  # Abort if NIL
         num E  # Number?
         jz numErrEX  # No
         zero E  # Zero?
         jeq divErrX  # Yes
         test E SIGN  # Arg negative?
         if nz  # Yes
            off E SIGN  # Make argument positive
            xor (L -I) 1  # Toggle result sign
         end
         ld (L II) E  # Save arg
         ld A (L I)  # Result
         call divuAE_A  # Divide
         ld (L I) A  # Result
      loop
      ld E (L I)  # Result
      test (L -I) 1  # Sign?
      if nz  # Yes
         zero E  # Zero?
         if ne  # No
            or E SIGN  # Set negative
         end
      end
10    drop
   end
   pop Y
   pop X
   ret

# (% 'num ..) -> num
(code 'doRem 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)
   eval  # Eval first arg
   cmp E Nil
   if ne  # Non-NIL
      num E  # Number?
      jz numErrEX  # No
      ld B 0  # Init sign
      test E SIGN
      if nz
         off E SIGN
         ld B 1
      end
      link
      push ZERO  # <L II> Safe
      push E  # <L I> Result
      link
      push A  # <L -I> Sign flag
      do
         ld Y (Y CDR)  # More args?
         atom Y
      while z  # Yes
         ld E (Y)
         eval  # Eval next arg
         cmp E Nil
         jz 10  # Abort if NIL
         num E  # Number?
         jz numErrEX  # No
         zero E  # Zero?
         jeq divErrX  # Yes
         off E SIGN  # Make argument positive
         ld (L II) E  # Save arg
         ld A (L I)  # Result
         call remuAE_A  # Remainder
         ld (L I) A  # Result
      loop
      ld E (L I)  # Result
      test (L -I) 1  # Sign?
      if nz  # Yes
         zero E  # Zero?
         if ne  # No
            or E SIGN  # Set negative
         end
      end
10    drop
   end
   pop Y
   pop X
   ret

# (>> 'cnt 'num) -> num
(code 'doShift 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   call evCntXY_FE  # Get shift count
   link
   push ZERO  # <L I> Safe
   link
   push E  # <L -I> Shift count
   ld Y (Y CDR)  # Second arg
   ld E (Y)
   eval  # Eval number
   cmp E Nil  # Any?
   if nz  # Yes
      num E  # Number?
      jz numErrEX  # No
      ld A E  # Number in A
      off A SIGN  # Make positive
      and E SIGN  # Sign bit
      push E  # <L -II> Sign bit
      null (L -I)  # Shift count?
      if nz  # Yes
         if ns  # Positive
            call shruA_A  # Non-destructive
            ld (L I) A
            do
               dec (L -I)  # Shift count?
            while nz
               call halfA_A  # Shift right (destructive)
               ld (L I) A
            loop
         else
            call shluA_A  # Non-destructive
            ld (L I) A
            do
               inc (L -I)  # Shift count?
            while nz
               call twiceA_A  # Shift left (destructive)
               ld (L I) A
            loop
         end
      end
      zero A  # Result zero?
      if ne  # No
         or A (L -II)  # Sign bit
      end
      ld E A  # Get result
   end
   drop
   pop Y
   pop X
   ret

# (lt0 'any) -> num | NIL
(code 'doLt0 2)
   ld E (E CDR)  # Get arg
   ld E (E)
   eval  # Eval it
   num E  # Number?
   jz retNil
   test E SIGN  # Negative?
   jz retNil
   ret  # Yes: Return num

# (ge0 'any) -> num | NIL
(code 'doGe0 2)
   ld E (E CDR)  # Get arg
   ld E (E)
   eval  # Eval it
   num E  # Number?
   jz retNil
   test E SIGN  # Positive?
   jnz retNil
   ret  # Yes: Return num

# (gt0 'any) -> num | NIL
(code 'doGt0 2)
   ld E (E CDR)  # Get arg
   ld E (E)
   eval  # Eval it
   num E  # Number?
   jz retNil
   zero E  # Zero?
   jeq retNil
   test E SIGN  # Positive?
   jnz retNil
   ret  # Yes: Return num

# (abs 'num) -> num
(code 'doAbs 2)
   push X
   ld X E
   ld E (E CDR)  # Get arg
   ld E (E)
   eval  # Eval it
   cmp E Nil  # Any?
   if nz  # Yes
      num E  # Number?
      jz numErrEX  # No
      off E SIGN  # Clear sign
   end
   pop X
   ret

### Bit operations ###
# (bit? 'num ..) -> num | NIL
(code 'doBitQ 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)
   eval  # Eval first arg
   num E  # Number?
   jz numErrEX  # No
   off E SIGN  # Clear sign
   link
   push E  # <L I> Bit mask
   link
   do
      ld Y (Y CDR)  # More args?
      atom Y
   while z  # Yes
      ld E (Y)
      eval  # Eval next arg
      cmp E Nil
   while ne  # Abort if NIL
      num E  # Number?
      jz numErrEX  # No
      off E SIGN  # Clear sign
      ld C (L I)  # Get mask
      do
         cnt C  # C short?
      while z  # No
         cnt E  # E short?
         jnz 10  # Yes: Return NIL
         ld A (E DIG)  # Get digit
         and A (C DIG)  # Match?
         cmp A (C DIG)
         jnz 10  # No: Return NIL
         ld C (C BIG)
         ld E (E BIG)
      loop
      cnt E  # E also short?
      if z  # No
         shr C 4  # Normalize
         ld E (E DIG)  # Get digit
      end
      and E C  # Match?
      cmp E C
      if ne  # No
10       ld E Nil  # Return NIL
         drop
         pop Y
         pop X
         ret
      end
   loop
   ld E (L I)  # Return bit mask
   drop
   pop Y
   pop X
   ret

# (& 'num ..) -> num
(code 'doBitAnd 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)
   eval  # Eval first arg
   cmp E Nil
   if ne  # Non-NIL
      num E  # Number?
      jz numErrEX  # No
      off E SIGN  # Clear sign
      link
      push ZERO  # <L II> Safe
      push E  # <L I> Result
      link
      do
         ld Y (Y CDR)  # More args?
         atom Y
      while z  # Yes
         ld E (Y)
         eval  # Eval next arg
         cmp E Nil
         jz 10  # Abort if NIL
         num E  # Number?
         jz numErrEX  # No
         off E SIGN  # Clear sign
         ld (L II) E  # Save arg
         ld A (L I)  # Result
         call anduAE_A  # Bitwise AND
         ld (L I) A  # Result
      loop
      ld E (L I)  # Result
10    drop
   end
   pop Y
   pop X
   ret

# (| 'num ..) -> num
(code 'doBitOr 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)
   eval  # Eval first arg
   cmp E Nil
   if ne  # Non-NIL
      num E  # Number?
      jz numErrEX  # No
      off E SIGN  # Clear sign
      link
      push ZERO  # <L II> Safe
      push E  # <L I> Result
      link
      do
         ld Y (Y CDR)  # More args?
         atom Y
      while z  # Yes
         ld E (Y)
         eval  # Eval next arg
         cmp E Nil
         jz 10  # Abort if NIL
         num E  # Number?
         jz numErrEX  # No
         off E SIGN  # Clear sign
         ld (L II) E  # Save arg
         ld A (L I)  # Result
         call oruAE_A  # Bitwise OR
         ld (L I) A  # Result
      loop
      ld E (L I)  # Result
10    drop
   end
   pop Y
   pop X
   ret

# (x| 'num ..) -> num
(code 'doBitXor 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)
   eval  # Eval first arg
   cmp E Nil
   if ne  # Non-NIL
      num E  # Number?
      jz numErrEX  # No
      off E SIGN  # Clear sign
      link
      push ZERO  # <L II> Safe
      push E  # <L I> Result
      link
      do
         ld Y (Y CDR)  # More args?
         atom Y
      while z  # Yes
         ld E (Y)
         eval  # Eval next arg
         cmp E Nil
         jz 10  # Abort if NIL
         num E  # Number?
         jz numErrEX  # No
         off E SIGN  # Clear sign
         ld (L II) E  # Save arg
         ld A (L I)  # Result
         call xoruAE_A  # Bitwise XOR
         ld (L I) A  # Result
      loop
      ld E (L I)  # Result
10    drop
   end
   pop Y
   pop X
   ret

### Random generator ###
(code 'initSeedE_E 0)
   push C  # Counter
   ld C 0
   do
      atom E  # Cell?
   while z  # Yes
      push E  # Recurse on CAR
      ld E (E)
      call initSeedE_E
      add C E
      pop E  # Loop on CDR
      ld E (E CDR)
   loop
   cmp E Nil  # NIL?
   if ne  # No
      num E  # Need number
      if z  # Must be symbol
         ld E (E TAIL)
         call nameE_E  # Get name
      end
      do
         cnt E  # Short?
      while z  # No
         add C (E DIG)  # Add next digit
         ld E (E BIG)
      loop
      add C E  # Add final short
   end
   ld E C  # Return counter
   pop C
   ret

# (seed 'any) -> cnt
(code 'doSeed 2)
   ld E (E CDR)  # Get arg
   ld E (E)
   eval  # Eval it
   call initSeedE_E  # Initialize 'Seed'
   ld A 6364136223846793005  # Multiplier
   mul E  # times 'Seed'
   add D 1  # plus 1
   ld (Seed) D  # Save
   ld E (Seed 4)  # Get high halfword
   off E 7  # Keep sign
   or E CNT  # Make short number
   ret

# (rand ['cnt1 'cnt2] | ['T]) -> cnt | flg
(code 'doRand 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld A 6364136223846793005  # Multiplier
   mul (Seed)  # times 'Seed'
   add D 1  # plus 1
   ld (Seed) D  # Save
   ld E (Y)
   eval  # Eval first arg
   cmp E Nil  # Any
   if eq  # No
      ld E (Seed 4)  # Get high halfword
      off E 7  # Keep sign
      or E CNT  # Make short number
      pop Y
      pop X
      ret
   end
   cmp E TSym  # Boolean
   if eq
      ld A (Seed)
      rcl A 1  # Highest bit?
      if nc  # No
         ld E Nil  # Return NIL
      end  # else return T
      pop Y
      pop X
      ret
   end
   call xCntEX_FE  # Get cnt1
   push E  # Save it
   ld Y (Y CDR)  # Second arg
   call evCntXY_FE  # Get cnt2
   inc E  # Seed % (cnt2 + 1 - cnt1) + cnt1
   sub E (S)
   ld A (Seed 4)  # Get high halfword
   ld C 0
   div E  # Modulus in C
   pop E  # + cnt1
   add E C
   pop Y
   pop X
   jmp boxCntE_E  # Return short number

# vi:et:ts=3:sw=3
