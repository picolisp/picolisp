# 11jun10abu
# (c) Software Lab. Alexander Burger

### Hypertext I/O functions ###
(data 'HtOK)
align 8  asciz "<b>"
align 8  asciz "</b>"
align 8  asciz "<i>"
align 8  asciz "</i>"
align 8  asciz "<u>"
align 8  asciz "</u>"
align 8  asciz "<p>"
align 8  asciz "</p>"
align 8  asciz "<pre>"
align 8  asciz "</pre>"
align 8  asciz "<div "
align 8  asciz "</div>"
align 8  asciz "<br>"
align 8  asciz "<hr>"
: HtOkEnd

: HtLt asciz "&lt;"
: HtGt asciz "&gt;"
: HtAmp asciz "&amp;"
: HtQuot asciz "&quot;"
: HtNbsp asciz "&nbsp;"

: HtEsc ascii " \\\"#%&:;<=>?_"
(equ HTESC 12)

(code 'findHtOkY_FE 0)
   push X
   ld X HtOK
   do
      push X
      push Y
      do
         ld B (X)  # Compare bytes
         cmp B (Y)  # Equal?
      while eq  # Yes
         inc X  # End of HtOk string?
         nul (X)
         if z  # Yes: Found
            slen C Y  # Length of the remaining string
            ld B (char ">")  # Is there a closing tag?
            memb Y C
            ldz E Y  # Yes: Return pointer to next char in E
            pop Y
            pop X
            pop X
            ret  # 'z' or 'nz'
         end
         inc Y  # End of data?
         nul (Y)
      until z  # Yes
      pop Y
      pop X
      add X 8  # Try next
      cmp X HtOkEnd  # Done?
   until gt  # Yes
   pop X
   ret  # 'nz'

# (ht:Prin 'sym ..) -> sym
(code 'Prin 2)
   push X
   push Y
   push Z
   ld X (E CDR)  # Args
   do
      ld E (X)  # Eval next
      eval
      num E  # Number?
      jnz 20  # Yes
      atom E  # Cell?
      jz 20  # Yes
      sym (E TAIL)  # External symbol?
      if nz  # Yes
20       call prinE_E  # Plain print
      else
         push E  # Save return value
         call bufStringE_SZ  # Write to stack buffer
         ld Y S  # Point to string
         do
            nul (Y)  # Null byte?
         while nz  # No
            call findHtOkY_FE  # Preserved pattern?
            if z  # Yes
               do
                  ld B (Y)  # Output partial string
                  call envPutB
                  inc Y  # till end pointer in E
                  cmp Y E
               until eq
            else
               ld B (Y)  # Next byte
               cmp B (char "<")  # Escape special characters
               if eq
                  ld C HtLt  # "&lt;"
                  call outStringC
               else
                  cmp B (char ">")
                  if eq
                     ld C HtGt  # "&gt;"
                     call outStringC
                  else
                     cmp B (char "&")
                     if eq
                        ld C HtAmp  # "&amp;"
                        call outStringC
                     else
                        cmp B (char "\"")
                        if eq
                           ld C HtQuot  # "&quot;"
                           call outStringC
                        else
                           cmp B (hex "FF")
                           if eq
                              ld B (hex "EF")
                              call envPutB
                              ld B (hex "BF")
                              call envPutB
                              ld B (hex "BF")
                              call envPutB
                           else
                              ld C A  # Save char
                              call envPutB  # Output it
                              test C (hex "80")  # Double byte?
                              if nz  # Yes
                                 inc Y  # Next
                                 ld B (Y)  # Output second byte
                                 call envPutB
                                 test C (hex "20")  # Triple byte?
                                 if nz  # Yes
                                    inc Y  # Next
                                    ld B (Y)  # Output third byte
                                    call envPutB
                                 end
                              end
                           end
                        end
                     end
                  end
               end
               inc Y  # Increment string pointer
            end
         loop
         ld S Z  # Drop buffer
         pop E
      end
      ld X (X CDR)  # X on rest
      atom X  # More?
   until nz  # No
   pop Z
   pop Y
   pop X
   ret

(code 'putHexB 0)  # E
   ld E A  # Save B
   ld B (char "%")  # Prefix with "%"
   call envPutB
   ld A E  # Get B
   shr B 4  # Get upper nibble
   and B 15
   cmp B 9  # Letter?
   if gt  # Yes
      add B 7
   end
   add B (char "0")
   call envPutB  # Output upper nibble
   ld A E  # Get B again
   and B 15  # Get lower nibble
   cmp B 9  # Letter?
   if gt  # Yes
      add B 7
   end
   add B (char "0")
   jmp envPutB  # Output lower nibble

(code 'htFmtE 0)
   cmp E Nil  # NIL?
   if ne  # No
      num E  # Number?
      if nz  # Yes
         ld B (char "+")  # Prefix with "+"
         call envPutB
         jmp prinE  # and print it
      end
      push X
      atom E  # List?
      if z  # Yes
         ld X E
         do
            ld B (char "_")  # Prefix with "_"
            call envPutB
            ld E (X)  # Print next item
            call htFmtE
            ld X (X CDR)  # End of list?
            atom X
         until nz  # Yes
      else  # Symbol
         ld X (E TAIL)
         call nameX_X  # Get name
         cmp X ZERO  # Any?
         if ne  # Yes
            sym (E TAIL)  # External symbol?
            if nz  # Yes
               ld B (char "-")  # Prefix with "-"
               call envPutB
               call prExtNmX  # Print external
            else
               push Y
               ld Y Intern
               call isInternEXY_F  # Internal symbol?
               ld C 0
               if eq  # Yes
                  ld B (char "$")  # Prefix with "$"
                  call envPutB
               else
                  call symByteCX_FACX  # Get first byte
                  cmp B (char "$")  # Dollar, plus or dot?
                  jeq 40
                  cmp B (char "+")
                  jeq 40
                  cmp B (char "-")
                  if eq
40                   call putHexB  # Encode hexadecimal
                  else
                     call envPutB
                  end
               end
               do
                  call symByteCX_FACX  # Next byte
               while nz
                  memb HtEsc HTESC  # Escape?
                  if eq  # Yes
                     call putHexB  # Encode hexadecimal
                  else
                     ld E A  # Save char
                     call envPutB  # Output it
                     test E (hex "80")  # Double byte?
                     if nz  # Yes
                        call symByteCX_FACX  # Next byte
                        call envPutB  # Output second byte
                        test E (hex "20")  # Triple byte?
                        if nz  # Yes
                           call symByteCX_FACX  # Next byte
                           call envPutB  # Output third byte
                        end
                     end
                  end
               loop
               pop Y
            end
         end
      end
      pop X
   end
   ret

# (ht:Fmt 'any ..) -> sym
(code 'Fmt 2)
   push X
   push Y
   push Z
   ld X (E CDR)  # X on args
   link
   do
      ld E (X)
      eval+  # Eval next arg
      push E
      ld X (X CDR)
      atom X  # More args?
   until nz  # No
   lea Y (L -I)  # Y on first arg
   ld Z S  # Z on last arg
   link
   call begString  # Start string
   ld E (Y)
   call htFmtE  # Format first arg
   do
      cmp Y Z  # More args?
   while ne  # Yes
      ld B (char "&")
      call envPutB
      sub Y I  # Next arg
      ld E (Y)
      call htFmtE  # Format it
   loop
   call endString_E  # Retrieve result
   drop
   pop Z
   pop Y
   pop X
   ret

(code 'getHexX_A 0)
   ld A ((X) TAIL)  # Get first hex digit
   call firstByteA_B
   sub B (char "0")  # Convert
   cmp B 9
   if gt
      and B (hex "DF")
      sub B 7
   end
   ld X (X CDR)  # Next symbol
   ret

(code 'getUnicodeX_FAX 0)
   ld E X  # Save X
   ld C 0  # Init unicode value
   do
      ld X (X CDR)
      ld A ((X) TAIL)  # Get next character symbol
      call firstByteA_B
      cmp B (char "0")  # Digit?
   while ge
      cmp B (char "9")
   while le  # Yes
      sub B (char "0")  # Convert
      push A  # Save digit
      ld A C  # Get accu
      mul 10  # Build decimal number
      pop C  # Get digit
      add C A  # New unicode value
   loop
   cmp B (char ";")  # Terminator?
   if eq  # Yes
      ld X (X CDR)  # Skip ";"
      ld A C  # Get value
      null A  # Any?
      jnz Ret  # Yes
   end
   ld X E  # Restore X
   setz  # 'z'
   ret

(code 'headCX_FX 0)  # E
   ld E X  # Save X
   do
      inc C  # Point to next char
      nul (C)  # Any?
   while nz  # Yes
      ld A ((X) TAIL)  # Get next character symbol
      call firstByteA_B
      cmp B (C)  # Matched?
   while eq  # Yes
      ld X (X CDR)
   loop
   ldnz X E  # Restore X when no match
   ret  # 'z' if match

# (ht:Pack 'lst) -> sym
(code 'Pack 2)
   push X
   ld E ((E CDR))  # Eval arg
   eval
   link
   push E  # Save
   link
   ld X E  # List in X
   call begString  # Start string
   do
      atom X  # More items?
   while z  # Yes
      ld E (X)  # Get next character symbol
      ld A (E TAIL)
      call firstByteA_B
      cmp B (char "%")  # Hex-escaped?
      if eq  # Yes
         ld X (X CDR)  # Skip "%"
         call getHexX_A  # Get upper nibble
         shl A 4
         ld C A  # into C
         call getHexX_A  # Get lower nibble
         or A C  # Combine
         call envPutB  # Output
      else
         ld X (X CDR)  # Next symbol
         cmp B (char "&")  # Ampersand?
         if ne  # No
            call outNameE  # Normal output
         else
            ld C HtLt  # "&lt;"
            call headCX_FX
            if eq
               ld B (char "<")
               call envPutB
            else
               ld C HtGt  # "&gt;"
               call headCX_FX
               if eq
                  ld B (char ">")
                  call envPutB
               else
                  ld C HtAmp  # "&amp;"
                  call headCX_FX
                  if eq
                     ld B (char "&")
                     call envPutB
                  else
                     ld C HtQuot  # "&quot;"
                     call headCX_FX
                     if eq
                        ld B (char "\"")
                        call envPutB
                     else
                        ld C HtNbsp  # "&nbsp;"
                        call headCX_FX
                        if eq
                           ld B (char " ")
                           call envPutB
                        else
                           ld A ((X) TAIL)  # Get next byte
                           call firstByteA_B
                           cmp B (char "#")  # Hash?
                           jne 40  # No
                           call getUnicodeX_FAX  # Unicode?
                           if nz  # Yes
                              call mkCharA_A  # Make symbol
                              ld E A
                              call outNameE  # Output unicode char
                           else
40                            ld B (char "&")  # Else ouput an ampersand
                              call envPutB
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   loop
   call endString_E  # Retrieve result
   drop
   pop X
   ret

### Read content length bytes ###
# (ht:Read 'cnt) -> lst
(code 'Read 2)
   push X
   ld X E
   ld E ((E CDR))  # E on arg
   call evCntEX_FE  # Eval 'cnt'
   if nsz  # > 0
      ld A (Chr)  # Look ahead char?
      null A
      if z  # No
         call envGet_A  # Get next char
      end
      null A  # EOF?
      if ns  # No
         call getChar_A  # Read first char
         cmp A 128  # Double byte?
         if ge  # Yes
            dec E  # Decrement count
            cmp A 2048  # Triple byte?
            if ge  # Yes
               dec E  # Decrement count
            end
         end
         sub E 1  # Less than zero?
         if ns  # No
            call mkCharA_A  # First character
            call consA_X  # Build first cell
            ld (X) A
            ld (X CDR) Nil
            link
            push X  # <L I> Result
            link
            do
               null E  # Count?
               if z  # No
                  ld E (L I)  # Return result
                  break T
               end
               call envGet_A  # Get next char
               null A  # EOF?
               if s  # Yes
                  ld E Nil  # Return NIL
                  break T
               end
               call getChar_A
               cmp A 128  # Double byte?
               if ge  # Yes
                  dec E  # Decrement count
                  cmp A 2048  # Triple byte?
                  if ge  # Yes
                     dec E  # Decrement count
                  end
               end
               sub E 1  # Less than zero?
               if s  # Yes
                  ld E Nil  # Return NIL
                  break T
               end
               call mkCharA_A  # Build next character
               call consA_C  # And next cell
               ld (C) A
               ld (C CDR) Nil
               ld (X CDR) C  # Append to result
               ld X C
            loop
            ld (Chr) 0  # Clear look ahead char
            drop
            pop X
            ret
         end
      end
   end
   ld E Nil  # Return NIL
   pop X
   ret


### Chunked Encoding ###
(equ CHUNK 4000)

(data 'Chunk 0)
word 0      # <Y> Chunk size count
word 0      # <Y I> Saved Get_A function
word 0      # <Y II> Saved PutB function
skip CHUNK  # <Y III> Chunk buffer

: Newlines asciz "0\\r\\n\\r\\n"

(code 'chrHex_AF 0)
   ld B (Chr)
   cmp B (char "0")  # Decimal digit?
   if ge
      cmp B (char "9")
      if le
         sub B 48  # Yes
         ret  # 'nc'
      end
   end
   and B (hex "DF")  # Force upper case
   cmp B (char "A")  # Hex letter?
   if ge
      cmp B (char "F")
      if le
         sub B 55  # Yes
         ret  # 'nc'
      end
   end
   ld A 0
   sub A 1  # -1
   ret  # 'c'

(code 'chunkSize 0)
   push X
   ld X Chunk  # Get Chunk
   null (Chr)  # 'Chr'?
   if z  # No
      ld A (X I)  # Call saved 'get'
      call (A)
   end
   call chrHex_AF  # Read encoded count
   ld (X) A  # Save in count
   if ge  # >= 0
      do
         ld A (X I)  # Call saved 'get'
         call (A)
         call chrHex_AF  # Read encoded count
      while ge  # >= 0
         ld C (X)  # Get count
         shl C 4  # Combine
         or C A
         ld (X) C
      loop
      do
         cmp (Chr) 10  # Fine linefeed
      while ne
         null (Chr)  # EOF?
         js 90  # Return
         ld A (X I)  # Call saved 'get'
         call (A)
      loop
      ld A (X I)  # Call saved 'get'
      call (A)
      null (X)  # Count is zero?
      if z  # Yes
         ld A (X I)  # Call saved 'get'
         call (A)  # Skip '\r' of empty line
         ld (Chr) 0  # Discard '\n'
      end
   end
90 pop X
   ret

(code 'getChunked_A 0)
   push Y
   ld Y Chunk  # Get Chunk
   null (Y)  # Count <= 0
   if sz  # Yes
      ld A -1  # Return EOF
      ld (Chr) A
   else
      ld A (Y I)  # Call saved 'get'
      call (A)
      dec (Y)  # Decrement count
      if z
         ld A (Y I)  # Call saved 'get'
         call (A)
         ld A (Y I)  # Skip '\n', '\r'
         call (A)
         call chunkSize
      end
   end
   pop Y
   ret

# (ht:In 'flg . prg) -> any
(code 'In 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval 'flg'
   eval
   ld X (X CDR)  # X on 'prg'
   cmp E Nil  # 'flg?
   if eq  # No
      prog X  # Run 'prg'
   else
      push Y
      ld Y Chunk  # Get Chunk
      ld (Y I) (Get_A)  # Save current 'get'
      ld (Get_A) getChunked_A  # Set new
      call chunkSize
      prog X  # Run 'prg'
      ld (Get_A) (Y I)  # Restore 'get'
      ld (Chr) 0  # Clear look ahead char
      pop Y
   end
   pop X
   ret


(code 'outHexA 0)
   cmp A 15  # Single digit?
   if gt  # No
      push A
      shr A 4  # Divide by 16
      call outHexA  # Recurse
      pop A
      and B 15
   end
   cmp B 9  # Digit?
   if gt  # No
      add B 39  # Make lower case letter
   end
   add B (char "0")  # Make ASCII digit
   jmp envPutB

(code 'wrChunkY 0)  # X
   ld (PutB) (Y II)  # Restore 'put'
   ld A (Y)  # Get count
   call outHexA  # Print as hex
   ld B 13  # Output 'return'
   call envPutB
   ld B 10  # Output 'newline'
   call envPutB
   lea X (Y III)  # X on chunk buffer
   do
      ld B (X)  # Next byte from chunk buffer
      call envPutB  # Output
      inc X  # Increment pointer
      dec (Y)  # Decrement 'Cnt'
   until z
   ld B 13  # Output 'return'
   call envPutB
   ld B 10  # Output 'newline'
   call envPutB
   ld (Y II) (PutB)  # Save 'put'
   ld (PutB) putChunkedB  # Set new
   ret

(code 'putChunkedB 0)
   push X
   push Y
   ld Y Chunk  # Get Chunk
   lea X (Y III)  # X on chunk buffer
   add X (Y)  # Count index
   ld (X) B  # Store byte
   inc (Y)  # Increment count
   cmp (Y) CHUNK   # Max reached?
   if eq  # Yes
      call wrChunkY  # Write buffer
   end
   pop Y
   pop X
   ret

# (ht:Out 'flg . prg) -> any
(code 'Out 2)
   push X
   ld X (E CDR)  # Args
   ld E (X)  # Eval 'flg'
   eval
   ld X (X CDR)  # X on 'prg'
   cmp E Nil  # 'flg?
   if eq  # No
      prog X  # Run 'prg'
   else
      push Y
      ld Y Chunk  # Get Chunk
      ld (Y) 0  # Clear count
      ld (Y II) (PutB)  # Save current 'put'
      ld (PutB) putChunkedB  # Set new
      prog X  # Run 'prg'
      null (Y)  # Count?
      if nz  # Yes
         call wrChunkY  # Write rest
      end
      ld (PutB) (Y II)  # Restore 'put'
      ld C Newlines  # Output termination string
      call outStringC
      pop Y
   end
   ld A (OutFile)  # Flush OutFile
   call flushA_F  # OK?
   pop X
   ret

# vi:et:ts=3:sw=3
