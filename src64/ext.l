# 01apr16abu
# (c) Software Lab. Alexander Burger

(data 'ExtData)
   initData

### Soundex Algorithm ###
(data 'SnxTab)
bytes (
   (char "0") (char "1") (char "2") (char "3") (char "4") (char "5") (char "6") (char "7")  # 48
   (char "8") (char "9")        0          0          0          0          0          0
          0          0   (char "F") (char "S") (char "T")        0   (char "F") (char "S")  # 64
          0          0   (char "S") (char "S") (char "L") (char "N") (char "N")        0
   (char "F") (char "S") (char "R") (char "S") (char "T")        0   (char "F") (char "F")
   (char "S")        0   (char "S")        0          0          0          0          0
          0          0   (char "F") (char "S") (char "T")        0   (char "F") (char "S")  # 96
          0          0   (char "S") (char "S") (char "L") (char "N") (char "N")        0
   (char "F") (char "S") (char "R") (char "S") (char "T")        0   (char "F") (char "F")
   (char "S")        0   (char "S")        0          0          0          0          0
          0          0          0          0          0          0          0          0  # 128
          0          0          0          0          0          0          0          0
          0          0          0          0          0          0          0          0
          0          0          0          0          0          0          0          0
          0          0          0          0          0          0          0          0  # 160
          0          0          0          0          0          0          0          0
          0          0          0          0          0          0          0          0
          0          0          0          0          0          0          0          0
          0          0          0          0          0          0          0   (char "S")  # 192
          0          0          0          0          0          0          0          0
   (char "T") (char "N")   0    0          0          0          0   (char "S")
          0          0          0          0          0          0          0   (char "S")
          0          0          0          0          0          0          0   (char "S")  # 224
          0          0          0          0          0          0          0          0
          0   (char "N") )

(equ SNXBASE 48)
(equ SNXSIZE (+ (* 24 8) 2))

(code 'ExtCode)
   initCode

# (ext:Snx 'any ['cnt]) -> sym
(code 'Snx 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   call evSymY_E  # Eval 'any'
   cmp E Nil
   if ne  # No
      ld E (E TAIL)
      call nameE_E  # Get name
      link
      push E  # <L II> Save Name
      link
      ld Y (Y CDR)  # Next arg
      atom Y  # Any?
      ldnz E 24  # Default to 24
      if z  # Yes
         call evCntXY_FE  # Eval 'cnt'
      end
      tuck ZERO  # <L I> Result
      ld X S
      link
      push 4  # <S II> Build name
      push X  # <S I> Pack status
      ld X (L II) # Get name
      ld C 0  # Index
      do
         call symCharCX_FACX  # First char?
         jz 90  # No
         cmp A SNXBASE  # Too small?
      until ge  # No
      cmp A (char "a")  # Lower case?
      if ge
         cmp A (char "z")
         jle 40  # Yes
      end
      cmp A 128
      jeq 40  # Yes
      cmp A 224
      if ge
         cmp A 255
         if le  # Yes
40          off B 32  # Convert to lower case
         end
      end
      push A  # <S> Last character
      xchg C (S II)  # Swap status
      xchg X (S I)
      call charSymACX_CX  # Pack first char
      xchg X (S I)  # Swap status
      xchg C (S II)
      do
         call symCharCX_FACX  # Next char?
      while nz  # Yes
         cmp A 32  # Non-white?
         if gt  # Yes
            sub A SNXBASE  # Too small?
            jlt 60  # Yes
            cmp A SNXSIZE  # Too big?
            jge 60  # Yes
            ld B (A SnxTab)  # Character entry?
            zxt
            null A
            if z  # No
60             ld (S) 0  # Clear last character
            else
               cmp A (S)  # Same as last?
               if ne  # No
                  dec E  # Decrement count
                  break z
                  ld (S) A  # Save last character
                  xchg C (S II)  # Swap status
                  xchg X (S I)
                  call charSymACX_CX  # Pack char
                  xchg X (S I)  # Swap status
                  xchg C (S II)
               end
            end
         end
      loop
90    ld X (L I)  # Get result
      call consSymX_E  # Make transient symbol
      drop
   end
   pop Y
   pop X
   ret


### File Descriptor ###
# (ext:FD 'cnt) -> fd
(code 'FD 2)
   push X
   ld X E
   ld E ((E CDR))  # Eval 'cnt'
   eval
   push E  # Save result
   call xCntEX_FE
   if ns
      ld X E  # Keep file descriptor
      ld A E
      call initInFileA_A  # Init input file
      ld A X
      call initOutFileA_A  # and output file
   end
   pop E  # Get result
   pop X
   ret


### Audio Data ###
(equ BIAS 132)
(equ CLIP (- 32767 BIAS))

# (ext:Ulaw 'cnt) -> cnt  # SEEEMMMM
(code 'Ulaw 2)
   push X
   ld X E
   ld E ((E CDR))  # Get arg
   eval  # Eval 'cnt'
   cnt E  #  # Short number?
   jz cntErrEX  # No
   ld X 0  # No sign
   shr E 4  # Normalize
   if x  # Negative?
      ld X (hex "80")  # Set sign
   end
   cmp E (+ CLIP 1)  # Clip the value
   if ge
      ld E CLIP
   end
   add E BIAS  # Increment by BIAS
   ld A E  # Double value
   add A A  # in 'tmp'
   ld C 7  # Exponent
   do
      test A (hex "8000")
   while z
      add A A  # Double 'tmp'
      dec C  # Decrement exponent
   until z
   ld A C  # Get exponent
   add A 3  # plus 3
   shr E A  # Shift value right
   and E 15  # Lowest 4 bits
   shl C 4  # Shift exponent left
   or E C  # Combine with value
   or E X  # and sign
   not E  # Negate
   and E (hex "FF")  # Get byte value
   shl E 4  # Make short number
   or E CNT
   pop X
   ret


### Base64 Encoding ###
(data 'Chr64 0)
            ascii "A"
: Chr64i    ascii "BCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
: Stat64    word 0  # State
: Next64    word 0  # Next value

# (ext:Base64) -> num|NIL
# (ext:Base64 'num1|NIL ['num2|NIL ['num3|NIL]]) -> flg
(code 'Base64 2)
   ld E (E CDR)  # E on args
   atom E  # Any?
   if nz  # No
      ld A (Chr)  # Look ahead char?
      null A
      if z  # No
         call (Get_A)  # Get next
      end
      do
         null A  # EOF?
      while ns  # No
         cmp B 32  # White space?
      while le  # Yes
         call (Get_A)  # Get next
      loop
      ld C Chr64
      memb C 64  # Legal character?
      if ne  # No
         cmp B (char "=")  # Filler?
         if eq  # Yes
            call (Get_A)  # Skip '='
            cmp (Stat64) 1  # State 1?
            if eq  # Yes
               call (Get_A)  # Skip '='
            end
         end
20       ld (Stat64) 0  # Clear state
         ld E Nil  # Return NIL
         ret
      end
      sub C Chr64i  # Numeric value in C
      call (Get_A)  # Fetch next input byte
      null (Stat64)  # Initial state?
      if z  # Yes
         ld A (Chr)  # Get next character
         ld E Chr64
         memb E 64  # Legal?
         jne 20  # No
         sub E Chr64i  # Numeric value in E
         ld (Next64) E  # Save E for next step
         call (Get_A)  # Fetch next input byte
         inc (Stat64)  # Increment state
         shl C (+ 2 4)  # Shift left 2 (upper six bits) and make short number
         and E (hex "30")  # Lower two bits
      else
         ld E (Next64)  # Load from last step
         cmp (Stat64) 1  # Second?
         if eq  # Yes
            inc (Stat64)  # Increment state
            ld (Next64) C  # Save C for next step
            and E 15  # Lower 4 bits from last
            shl E (+ 4 4)  # into upper 4 bits
            and C (hex "3C")  # lower 4 bits
            shl C (- 4 2)
         else
            ld (Stat64) 0  # Clear state
            and E 3  # Lower 2 bits from last
            shl E (+ 6 4)  # into upper 2 bits
            shl C 4  # Lower 6 bits
         end
      end
      or E C
      or E CNT  # Return short number
      ret
   end
   push X
   ld X E  # X on args
   ld E (X)  # Eval first 'num|NIL'
   eval
   cmp E Nil  # NIL?
   if ne  # No
      push Y
      shr E 4  # Normalize first arg
      ld Y E  # Keep in Y
      shr E 2  # Upper 6 bits
      call chr64E  # Output encoded
      ld X (X CDR)  # Next arg
      ld E (X)
      eval  # Eval second arg
      cmp E Nil  # NIL?
      if eq  # Yes
         ld E Y  # Get first arg
         and E 3  # Mask
         shl E 4  # Shift to upper position
         call chr64E  # Output encoded
         ld B (char "=")  # and two equal signs
         call (PutB)
         ld B (char "=")
         call (PutB)
         ld E Nil  # Return NIL
      else
         shr E 4  # Normalize second arg
         and Y 3  # Mask first arg
         shl Y 4  # Shift to upper position
         ld A E  # Get second arg
         shr A 4  # Normalize
         or A Y  # Combine
         ld Y E  # Keep second arg in Y
         call chr64A  # Output encoded
         ld X (X CDR)  # Next arg
         ld E (X)
         eval  # Eval third arg
         cmp E Nil  # NIL?
         if eq  # Yes
            ld A Y  # Get second
            and A 15  # Lowest four bits
            shl A 2  # Shift
            call chr64A  # Output encoded
            ld B (char "=")  # and an equal sign
            call (PutB)
            ld E Nil  # Return NIL
         else
            shr E 4  # Normalize third arg
            ld A E
            shr A 6  # Upper bits
            and Y 15  # Lowest four bits of second arg
            shl Y 2  # Shift
            or A Y  # Combine
            call chr64A  # Output encoded
            and E 63  # Last arg
            call chr64E  # Output encoded
            ld E TSym  # Return T
         end
      end
      pop Y
   end
   pop X
   ret

(code 'chr64E)
   ld A E
(code 'chr64A)
   ld B (A Chr64)  # Fetch from table
   jmp (PutB)  # Output byte

# vi:et:ts=3:sw=3
