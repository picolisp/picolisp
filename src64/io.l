# 25nov09abu
# (c) Software Lab. Alexander Burger

# Close file descriptor
(code 'closeAX)
   cc close(A)
   nul4  # OK?
   jz Ret  # Yes
   ld E A  # Get file descriptor
   shl E 4  # Make short number
   or E CNT
   jmp closeErrEX

# Lock/unlock file
(code 'unLockFileAC)
   st2 (Flock)  # 'l_type'
   ld (Flock L_START) 0  # Start position ('l_whence' is SEEK_SET)
   shr A 16  # Get length
   ld (Flock L_LEN) A  # Length
   cc fcntl(C F_SETLK Flock)  # Try to unlock
   ret

(code 'wrLockFileC)
   ld A F_WRLCK  # Write lock, length 0
   jmp lockFileAC
(code 'rdLockFileC)
   ld A F_RDLCK  # Read lock, length 0
(code 'lockFileAC)
   st2 (Flock)  # 'l_type'
   ld (Flock L_START) 0  # Start position ('l_whence' is SEEK_SET)
   shr A 16  # Get length
   ld (Flock L_LEN) A  # Length
   do
      cc fcntl(C F_SETLKW Flock)  # Try to lock
      nul4  # OK?
      jns Ret  # Yes
      call errno_A
      cmp A EINTR  # Interrupted?
      jne lockErr  # No
   loop

# Set the close-on-exec flag
(code 'closeOnExecAX)
   cc fcntl(A F_SETFD FD_CLOEXEC)
   nul4  # OK?
   jns Ret  # Yes
   ld Y SetFD
   jmp errnoEXY
: SetFD string "SETFD %s"

# Set file descriptor to non-blocking / blocking
(code 'nonblockingA_A)
   push C
   ld C A  # Keep fd
   cc fcntl(C F_GETFL 0)  # Get file status flags
   push A  # Save flags
   or A O_NONBLOCK
   cc fcntl(C F_SETFL A)  # Set file status flags
   pop A  # Return old flags
   pop C
   ret

# Initialize input file
(code 'initInFileA_A)  # E
   ld C 0  # No name
: initInFileAC_A
   xchg A C
: initInFileCA_A
   push A  # Save 'name'
   push C  # and 'fd'
   shl C 3  # Vector index
   cmp C (InFDs)  # 'fd' >= 'InFDs'?
   if ge  # Yes
      push X
      ld X (InFDs)  # Keep old 'InFDs'
      ld E C  # Get vector index
      add E I  # Plus 1
      ld (InFDs) E  # Store new 'InFDs'
      ld A (InFiles)  # Get vector
      call allocAE_A  # Extend vector
      ld (InFiles) A
      add X A  # X on beg
      add A E  # A on end
      do
         ld (X) 0  # Clear new range
         add X I
         cmp X A
      until eq
      pop X
   end
   add C (InFiles)  # Get vector
   ld A (C)  # Old inFile (should be NULL!)
   ld E (+ VII BUFSIZ)  # sizeof(inFile)
   call allocAE_A
   ld (C) A  # New inFile
   pop (A)  # Set 'fd'
   ld (A I) 0  # Clear 'ix'
   ld (A II) 0  # Clear 'cnt'
   ld (A III) 0  # Clear 'next'
   ld C 1
   ld (A IV) C  # line = 1
   ld (A V) C  # src = 1
   pop (A VI)  # Set filename
   ret

# Initialize output file
(code 'initOutFileA_A)
   ld C A
   push A  # Save 'fd'
   cc isatty(A)
   push A  # Save 'tty' flag
   shl C 3  # Vector index
   cmp C (OutFDs)  # 'fd' >= 'OutFDs'?
   if ge  # Yes
      push X
      ld X (OutFDs)  # Keep old 'OutFDs'
      ld E C  # Get vector index
      add E I  # Plus 1
      ld (OutFDs) E  # Store new 'OutFDs'
      ld A (OutFiles)  # Get vector
      call allocAE_A  # Extend vector
      ld (OutFiles) A
      add X A  # X on beg
      add A E  # A on end
      do
         ld (X) 0  # Clear new range
         add X I
         cmp X A
      until eq
      pop X
   end
   add C (OutFiles)  # Get vector
   ld A (C)  # Old outFile (should be NULL!)
   ld E (+ III BUFSIZ)  # sizeof(outFile)
   call allocAE_A
   ld (C) A  # New outFile
   pop (A II)  # Set 'tty'
   ld (A I) 0  # Clear 'ix'
   pop (A)  # Set 'fd'
   ret

# Close input file
(code 'closeInFileA)
   shl A 3  # Vector index
   cmp A (InFDs)  # 'fd' < 'InFDs'?
   if lt  # Yes
      push X
      add A (InFiles)  # Get vector
      ld X (A)
      null X  # Any?
      if nz  # Yes
         cmp X (InFile)  # Current Infile?
         if eq  # Yes
            ld (InFile) 0  # Clear it
         end
         ld (A) 0  # Clear slot
         cc free((X VI))  # Free filename
         cc free(X)  # And inFile
      end
      pop X
   end
   ret

# Close output file
(code 'closeOutFileA)
   shl A 3  # Vector index
   cmp A (OutFDs)  # 'fd' < 'OutFDs'?
   if lt  # Yes
      push X
      add A (OutFiles)  # Get vector
      ld X (A)
      null X  # Any?
      if nz  # Yes
         cmp A (OutFile)  # Current Outfile?
         if eq  # Yes
            ld (OutFile) 0  # Clear it
         end
         ld (A) 0  # Clear slot
         cc free(X)  # And inFile
      end
      pop X
   end
   ret

# Interruptible read
(code 'slowZ_F)
   ld (Z I) 0  # Clear 'ix'
   ld (Z II) 0  # Clear 'cnt'
   do
      cc read((Z) &(Z VII) BUFSIZ)  # Read into buffer
      null A  # OK?
      if ns  # Yes
         ld (Z II) A  # Set new 'cnt'
         ret  # Return 'ge'
      end
      call errno_A
      cmp A EINTR  # Interrupted?
      if ne  # No
         setz  # Return 'z'
         ret
      end
      nul (Signal)  # Signal?
      if nz  # Yes
         call sighandler0
      end
   loop

(code 'slowNbC_FA)
   ld (C I) 0  # Clear 'ix'
   ld (C II) 0  # Clear 'cnt'
   do
      ld A (C)  # Set non-blocking
      call nonblockingA_A
      push A  # Save old file status flags
      cc read((C) &(C VII) BUFSIZ)  # Read into buffer
      xchg A (S)
      cc fcntl((C) F_SETFL A)  # Restore file status flags
      pop A  # Get 'read' return value
      null A  # OK?
      if ns  # Yes
         ld (C II) A  # Set new 'cnt'
         ret  # Return 'ge'
      end
      call errno_A
      cmp A EAGAIN  # No data available?
      if eq  # Yes
         setc  # Return 'lt'
         ret
      end
      cmp A EINTR  # Interrupted?
      if ne  # No
         setz  # Return 'z'
         ret
      end
      nul (Signal)  # Signal?
      if nz  # Yes
         call sighandler0
      end
   loop

(code 'rdBytesCEX_F)
   do
      do
         cc read(C X E)  # Read into buffer
         null A  # OK?
      while sz  # No
         jz Ret  # EOF
         call errno_A
         cmp A EINTR  # Interrupted?
         jne Retz  # No: Return 'z'
         nul (Signal)  # Signal?
         if nz  # Yes
            call sighandler0
         end
      loop
      add X A  # Increment buffer pointer
      sub E A  # Decrement count
   until z
   null A  # 'nsz'
   ret

(code 'rdBytesNbCEX_F)
   do
      ld A C  # Set non-blocking
      call nonblockingA_A
      push A  # Save old file status flags
      cc read(C X E)  # Read into buffer
      xchg A (S)
      cc fcntl(C F_SETFL A)  # Restore file status flags
      pop A  # Get 'read' return value
      null A  # OK?
      if nsz  # Yes
         do
            add X A  # Increment buffer pointer
            sub E A  # Decrement count
            if z  #  Got all
               null A  # 'nsz'
               ret
            end
            do
               cc read(C X E)  # Read into buffer
               null A  # OK?
            while sz  # No
               jz Ret  # EOF
               call errno_A
               cmp A EINTR  # Interrupted?
               jne Retz  # No: Return 'z'
               nul (Signal)  # Signal?
               if nz  # Yes
                  call sighandler0
               end
            loop
         loop
      end
      jz Ret  # EOF
      call errno_A
      cmp A EAGAIN  # No data available?
      if eq  # Yes
         setc  # Return 'lt'
         ret
      end
      cmp A EINTR  # Interrupted?
      jne Retz  # No: Return 'z'
      nul (Signal)  # Signal?
      if nz  # Yes
         call sighandler0
      end
   loop

(code 'wrBytesCEX_F)
   do
      cc write(C X E)  # Write buffer
      null A  # OK?
      if ns  # Yes
         sub E A  # Decrement count
         jz Ret  # Return 'z' if OK
         add X A  # Increment buffer pointer
      else
         call errno_A
         cmp A EBADF  # Bad file number?
         jz retnz  # Return 'nz'
         cmp A EPIPE  # Broken pipe?
         jz retnz  # Return 'nz'
         cmp A ECONNRESET  # Connection reset by peer?
         jz retnz  # Return 'nz'
         cmp A EINTR  # Interrupted?
         jne wrBytesErr  # No
      end
      nul (Signal)  # Signal?
      if nz  # Yes
         call sighandler0
      end
   loop

(code 'clsChildY 0)
   ld (Y) 0  # Clear 'pid'
   cc close((Y I))  # Close 'hear'
   cc close((Y II))  # and 'tell'
   cc free((Y V))  # Free buffer
   ret

(code 'wrChildCXY)  # E
   ld E (Y IV)  # Get buffer count
   null E  # Any?
   if z  # No
      do
         cc write((Y II) X C)  # Write buffer to 'tell' pipe
         null A  # OK?
         if ns  # Yes
            sub C A  # Decrement count
            jz Ret  # Done
            add X A  # Increment buffer pointer
         else
            call errno_A
            cmp A EAGAIN  # Would block?
            break eq  # Yes
            cmp A EPIPE  # Broken pipe?
            jeq clsChildY  # Close child
            cmp A ECONNRESET  # Connection reset by peer?
            jeq clsChildY  # Close child
            cmp A EINTR  # Interrupted?
            jne wrChildErr  # No
         end
      loop
   end
   ld A (Y V)  # Get buffer
   add E C  # Increment count
   add E 2  # plus count size
   call allocAE_A  # Extend buffer
   ld (Y V) A  # Store
   ld E (Y IV)  # Get buffer count again
   add E (Y IV)  # Point to new count
   ld A C  # Store new
   st2 (E)
   add E 2  # Point to new data
   movn (E) (X) C  # Copy data
   add C 2  # Total new size
   add (Y IV)  # Add to buffer count
   ret

(code 'flushA_F 0)
   null A  # Output file?
   if nz  # Yes
      push E
      ld E (A I)  # Get 'ix'
      null E  # Any?
      if nz  # Yes
         push C
         push X
         ld (A I) 0  # Clear 'ix'
         ld C (A)  # Get 'fd'
         lea X (A III)  # Buffer pointer
         call wrBytesCEX_F  # Write buffer
         pop X
         pop C
      end
      pop E
   end
   ret  # Return 'z' if OK

(code 'flushAll)  # C
   ld C 0  # Iterate output files
   do
      cmp C (OutFDs)  # 'fd' < 'OutFDs'?
   while lt
      ld A C  # Get vector index
      add A (OutFiles)  # Get OutFile
      ld A (A)
      call flushA_F  # Flush it
      add C I  # Increment vector index
   loop
   ret

### Low level I/O ###
(code 'stdinByte_FA)
   push Z
   ld Z ((InFiles))  # Get stdin
   null Z  # Open?
   if nz  # Yes
      call getBinaryZ_FB  # Get byte
      zxt
      pop Z
      ret
   end
   setc
   pop Z
   ret

(code 'getBinaryZ_FB 0)
   ld A (Z I)  # Get 'ix'
   cmp A (Z II)  # Equals 'cnt'?
   if eq  # Yes
      call slowZ_F  # Read into buffer
      jz retc  # EOF (c)
      ld A 0  # 'ix'
   end
   add (Z I) 1  # Increment 'ix'
   add A Z  # Fetch byte (nc)
   ld B (A VII)  # from buffer
   ret  # nc

# Add next byte to a number
(code 'byteNumBCX_CX 0)
   zxt
   big X  # Big number?
   if z  # No: Direct buffer pointer
      # xxxxx.xxxxxxx.xxxxxxx.xxxxxxx.xxxxxxx.xxxxxxx.xxxxxxx.xxxxxxS010
      #    59      51      43      35      27      19      11       3
      cmp C 59  # Short digit full?
      if ne  # No
         shl A C  # Shift byte to character position
         or (X) A  # Combine with short number
         add C 8  # Increment position
         ret
      end
      ld C (X)  # Get short number
      shr C 3  # De-normalize, keep sign bit
      shl A 56  # Combine byte with digit
      or C A
      call boxNum_A  # Box number
      ld (A DIG) C
      ld (X) A
      ld X A
      ld C 0  # Start new digit
      ret
   end
   null C  # Last bit of big digit?
   if z  # Yes
      ld C (X DIG)
      shr A 1  # Get lowest bit
      rcr C 1  # into highest bit of big digit
      ld (X DIG) C
      rcl A 1  # Get sign bit into A
      shl A 3  # Normalize with sign
      or A CNT  # Make short number
      ld (X BIG) A
      ld C 11  # Set up for second byte
      ret
   end
   cmp C 59  # Short digit full?
   if ne  # No
      shl A C  # Shift byte to character position
      or (X BIG) A  # Combine with name digit
      add C 8  # Increment position
      ret
   end
   ld C (X BIG)  # Get short number
   shr C 3  # De-normalize, keep sign bit
   shl A 56  # Combine byte with digit
   or C A
   call boxNum_A  # Box number
   ld (A DIG) C
   ld (X BIG) A
   ld X A
   ld C 0  # Start new digit
   ret

# Read binary expression
(code 'binReadZ_FE)
   call (GetBinZ_FB)  # Tag byte?
   jc ret  # No
   nul B  # NIX?
   jz retNil  # Return NIL
   zxt
   test B (hex "FC")  # Atomic?
   if z  # No
      ld E A
      cmp B BEG  # Begin a list?
      jnz retnc  # No: Return DOT or END
      call binReadZ_FE  # Else read list
      jc ret
      push X
      call consE_X  # First cell
      ld (X) E
      ld (X CDR) Nil
      link
      push X  # <L I> Save it
      link
      do
         call binReadZ_FE  # Next item
         jc 10  # EOF
         cmp E END  # Any?
      while ne  # Yes
         cmp E DOT  # Dotted pair?
         if eq  # Yes
            call binReadZ_FE  # Get CDR
            if c  # EOF
10             drop
               pop X
               ret  # Return 'c'
            end
            cmp E END  # Circular list?
            ldz E (L I)  # Yes: Get first cell
            ld (X CDR) E  # Store in last cell
            break T
         end
         call consE_C  # Append next cell
         ld (C) E
         ld (C CDR) Nil
         ld (X CDR) C
         ld X C
      loop
      ld E (L I)  # Return list
      drop  # Return 'nc'
      pop X
      ret
   end
   push X
   link
   push ZERO  # <L I> Result
   ld X S
   link
   ld E A  # Get tag byte
   shr E 2  # Count
   and A 3  # Tag
   if z  # NUMBER
      ld C 3  # Build signed number
      cmp E 63  # More than one chunk?
      if eq  # Yes
         do
            do
               call (GetBinZ_FB)  # Next byte?
               jc 90  # No
               call byteNumBCX_CX
               sub E 1  # Decrement count
            until z
            call (GetBinZ_FB)  # Next count?
            jc 90  # No
            zxt
            ld E A
            cmp B 255  # Another chunk?
         until ne  # No
         or B B  # Empty?
         jz 20  # Yes
      end
      do
         call (GetBinZ_FB)  # Next byte?
         jc 90  # No
         call byteNumBCX_CX
         sub E 1  # Decrement count
      until z
20    ld E (L I)  # Get result
      big X  # Big number?
      if nz  # Yes
         ld A (X BIG)  # Get last short
         and A SIGN  # Sign bit
         off (X BIG) SIGN
         or E A  # Set sign bit in result
      end
   else  # INTERN, TRANSIENT or EXTERN
      push A  # Tag
      ld C 4  # Build name
      cmp E 63  # More than one chunk?
      if eq  # Yes
         do
            do
               call (GetBinZ_FB)  # Next byte?
               jc 90  # No
               call byteSymBCX_CX
               sub E 1  # Decrement count
            until z
            call (GetBinZ_FB)  # Next count?
            jc 90  # No
            zxt
            ld E A
            cmp B 255  # Another chunk?
         until ne  # No
         or B B  # Empty?
         jz 30  # Yes
      end
      do
         call (GetBinZ_FB)  # Next byte?
         jc 90  # No
         call byteSymBCX_CX
         sub E 1  # Decrement count
      until z
30    ld X (L I)  # Get name
      pop A  # Get tag
      cmp A TRANSIENT  # Transient?
      if eq  # Yes
         call consSymX_E  # Build symbol
      else
         cmp A INTERN  # Internal?
         if eq  # Yes
            push Y
            ld Y Intern
            ld E 0  # No symbol yet
            call internEXY_FE  # New internal symbol?
            if c  # Yes
               ld (E) Nil  # Init to 'NIL'
            end
            pop Y
         else  # External
            null (Extn)  # External symbol offset?
            if nz  # Yes
               ld A X  # Get file number
               shr A 24  # Lower 8 bits
               ld C A  # into C
               and C (hex "FF")
               shr A 12  # Upper 8 bits
               and A (hex "FF00")
               or A C
               add A (Extn)  # Add external symbol offset
               shl A 24
               ld C A  # Lower result bits
               shl A 12
               or A C
               and A (hex "000FF000FF000000")  # Mask file number
               and X (hex "FFF00FFF00FFFFFF")  # Mask object ID
               or X A  # Combine
            end
            call externX_E  # New external symbol
         end
      end
   end
   clrc
90 drop
   pop X
   ret

# Binary print next byte from a number
(code 'prByteCEXY 0)
   null C  # New round?
   if z  # Yes
      cnt X  # Short number?
      if z  # No
         ld E (X DIG)  # Next digit
         ld X (X BIG)
      else
         ld E X  # Get short
         shr E 4  # Normalize
      end
      shr Y 1  # Get overflow bit
      rcl E 1  # Shift into digit
      rcl Y 1  # Keep new overflow bit
      ld C 8  # Init count
   end
   ld A E  # Output next byte
   call (PutBinBZ)
   shr E 8  # Shift to next
   sub C 1  # Decrement count
   ret

# Binary print short number
(code 'prCntCE 0)
   ld A E
   do
      shr A 8  # More bytes?
   while nz  # Yes
      add C 4  # Increment count
   loop
   ld A C  # Output tag byte
   call (PutBinBZ)
   shr C 2  # Discard tag bits
   do
      ld A E  # Next data byte
      shr E 8
      call (PutBinBZ)  # Output data byte
      sub C 1  # More?
   until z  # No
   ret

# Binary print expression
(code 'prTellEZ 0)
   ld (PutBinBZ) putTellBZ  # Set binary print function
   ld (Extn) 0  # Set external symbol offset to zero
   call binPrintEZ
   ret

(code 'prE)
   ld (PutBinBZ) putStdoutB  # Set binary print function
(code 'binPrintEZ)
   cnt E  # Short number?
   if nz  # Yes
      ld C 4  # Count significant bytes (adjusted to tag)
      shr E 3  # Normalize
      jmp prCntCE  # Output 'cnt'
   end
   big E  # Big number?
   if nz  # Yes
      push X
      push Y
      push E  # Save signed number
      off E SIGN  # Make positive
      ld X E  # Keep in X
      ld A 8  # Count 8 significant bytes
      do
         ld C (E DIG)  # Keep digit
         ld E (E BIG)  # More cells?
         cnt E
      while z  # Yes
         add A 8  # Increment count by 8
      loop
      shr E 4  # Normalize short
      shl C 1  # Get most significant bit of last digit
      addc E E  # Any significant bits in short number?
      if nz  # Yes
         do
            add A 1  # Increment count
            shr E 8  # More bytes?
         until z  # No
      end
      pop Y  # Get sign
      shr Y 3  # into lowest bit
      ld C 0  # Init byte count
      cmp A 63  # Single chunk?
      if lt  # Yes
         push A  # <S> Count
         shl A 2  # Adjust to tag byte
         call (PutBinBZ)  # Output tag byte
         do
            call prByteCEXY  # Output next data bye
            sub (S) 1  # More?
         until z  # No
      else
         sub A 63  # Adjust count
         push A  # <S I> Count
         ld A (* 4 63)  # Output first tag byte
         call (PutBinBZ)
         push 63  # <S> and first 63 data bytes
         do
            call prByteCEXY  # Output next data bye
            sub (S) 1  # More?
         until z  # No
         do
            cmp (S I) 255  # Count greater or equal 255?
         while ge  # Yes
            ld A 255  # Next chunk
            ld (S) A  # and the next 255 data bytes
            call (PutBinBZ)  # Output count byte
            do
               call prByteCEXY  # Output next data bye
               sub (S) 1  # More?
            until z  # No
            sub (S I) 255  # Decrement counter
         loop
         pop A  # Drop second count
         ld A (S)  # Retrieve count
         call (PutBinBZ)  # Output last count
         do
            sub (S) 1  # More?
         while ge  # Yes
            call prByteCEXY  # Output next data bye
         loop
      end
      pop A  # Drop count
      pop Y
      pop X
      ret
   end
   sym E  # Symbol?
   if nz  # Yes
      cmp E Nil  # NIL?
      if eq  # Yes
         ld A NIX
         jmp (PutBinBZ)  # Output NIX
      end
      sym (E TAIL)  # External symbol?
      if nz  # Yes
         ld E (E TAIL)
         call nameE_E  # Get name
         null (Extn)  # External symbol offset?
         if nz  # Yes
            ld A E  # Get file number
            shr A 24  # Lower 8 bits
            ld C A  # into C
            and C (hex "FF")
            shr A 12  # Upper 8 bits
            and A (hex "FF00")
            or A C
            sub A (Extn)  # Subtract external symbol offset
            shl A 24
            ld C A  # Lower result bits
            shl A 12
            or A C
            and A (hex "000FF000FF000000")  # Mask file number
            and E (hex "FFF00FFF00FFFFFF")  # Mask object ID
            or E A  # Combine
         end
         shl E 2  # Strip status bits
         shr E 6  # Normalize
         ld C (+ 4 EXTERN)  # Count significant bytes (adjusted to tag)
         jmp prCntCE  # Output external name
      end
      push X
      push Y
      ld X (E TAIL)
      call nameX_X  # Get name
      zero X  # Any?
      if eq  # No
         ld A NIX
         call (PutBinBZ)  # Output NIX
      else
         ld Y Intern
         call isInternEXY_F  # Internal symbol?
         ld C INTERN  # Yes
         ldnz C TRANSIENT  # No
         cnt X  # Short name?
         if nz  # Yes
            add C 4  # Count significant bytes (adjusted to tag)
            ld E X  # Get name
            shr E 4  # Normalize
            call prCntCE  # Output internal or transient name
         else  # Long name
            ld E X  # Into E
            ld A 8  # Count significant bytes
            do
               ld E (E BIG)  # More cells?
               cnt E
            while z  # Yes
               add A 8  # Increment count
            loop
            shr E 4  # Any significant bits in short name?
            if nz  # Yes
               do
                  add A 1  # Increment count
                  shr E 8  # More bytes?
               until z  # No
            end
            ld E A  # Keep count in E
            cmp A 63  # Single chunk?
            if lt  # Yes
               shl A 2  # Adjust to tag byte
               or A C  # Combine with tag
               call (PutBinBZ)  # Output tag byte
               ld C 0
               do
                  call symByteCX_FACX  # Next data byte
                  call (PutBinBZ)  # Output it
                  sub E 1  # More?
               until z  # No
            else
               ld A (* 4 63)  # Output first tag byte
               or A C  # Combine with tag
               call (PutBinBZ)
               sub E 63  # Adjust count
               push E  # <S> Count
               ld E 63  # and first 63 data bytes
               ld C 0
               do
                  call symByteCX_FACX  # Next data byte
                  call (PutBinBZ)  # Output it
                  sub E 1  # More?
               until z  # No
               do
                  cmp (S) 255  # Count greater or equal 255?
               while ge  # Yes
                  ld A 255  # Next chunk
                  ld E A  # and the next 255 data bytes
                  call (PutBinBZ)  # Output count byte
                  do
                     call symByteCX_FACX  # Next data byte
                     call (PutBinBZ)  # Output it
                     sub E 1  # More?
                  until z  # No
                  sub (S) 255  # Decrement counter
               loop
               pop E  # Retrieve count
               ld A E
               call (PutBinBZ)  # Output last count
               do
                  sub E 1  # More?
               while ge  # Yes
                  call symByteCX_FACX  # Next data byte
                  call (PutBinBZ)  # Output it
               loop
            end
         end
      end
      pop Y
      pop X
      ret
   end
   push X
   push Y
   ld X E  # Get expression
   ld Y E  # in X and Y
   ld A BEG  # Begin list
   call (PutBinBZ)
   do
      ld E (X)  # Next item
      call binPrintEZ
      ld X (X CDR)  # More?
      cmp X Nil
   while ne  # Yes
      cmp X Y  # Circular?
      if eq  # Yes
         ld A DOT  # Output dotted pair
         call (PutBinBZ)
         break T
      end
      atom X  # End of list?
      if nz  # Yes
         ld A DOT  # Output dotted pair
         call (PutBinBZ)
         ld E X  # Output atom
         call binPrintEZ
         pop Y  # Return
         pop X
         ret
      end
   loop
   pop Y
   pop X
   ld A END  # End list
   jmp (PutBinBZ)

# Family IPC
(code 'putTellBZ 0)
   ld (Z) B  # Store byte
   add Z 1  # Increment pointer
   lea A ((TellBuf) (- PIPE_BUF 1))  # Reached (TellBuf + PIPE_BUF - 1)?
   cmp Z A
   jeq tellErr  # Yes
   ret

(code 'tellBegZ_Z 0)
   ld (TellBuf) Z  # Set global buffer
   add Z 2  # 2 bytes space for count
   set (Z) BEG  # Begin a list
   add Z 1
   ret

(code 'tellEndZ)
   push X
   push Y
   set (Z) END  # Close list
   add Z 1
   ld X (TellBuf)  # Get buffer
   ld E Z  # Calculate total size
   sub E X
   ld A E  # Size in A
   sub A 2  # without count
   st2 (X)  # Store in buffer count
   push A  # <S> Size
   ld C (Tell)  # File descriptor
   null C  # Any?
   if nz  # Yes
      call wrBytesCEX_F  # Write buffer to pipe
      if nz  # Not successful
         cc close(C)  # Close 'Tell'
         ld (Tell) 0  # Clear 'Tell'
      end
   end
   ld Y (Child)  # Iterate children
   ld Z (Children)  # Count
   do
      sub Z VI  # More?
   while ge  # Yes
      null (Y)  # 'pid'?
      if nz  # Yes
         ld C (S)  # Get size
         lea X ((TellBuf) 2)  # and data
         call wrChildCXY  # Write to child
      end
      add Y VI  # Increment by sizeof(child)
   loop
   pop A  # Drop size
   pop Y
   pop X
   ret

(code 'rdHear_FE)
   push Z
   ld A (Hear)  # Get 'hear' fd
   shl A 3  # Vector index
   add A (InFiles)  # Get vector
   ld Z (A)  # Input file
   ld (GetBinZ_FB) getBinaryZ_FB  # Set binary read function
   ld (Extn) 0  # Set external symbol offset to zero
   call binReadZ_FE  # Read item
   pop Z
   ret

# Return next byte from symbol name
(code 'symByteCX_FACX 0)
   null C  # New round?
   if z  # Yes
      zero X  # Done?
      jeq ret  # Yes: Return 'z'
      cnt X  # Short?
      if nz  # Yes
         ld C X  # Get short
         shr C 4  # Normalize
         ld X ZERO  # Clear for next round
      else
         ld C (X DIG)  # Get next digit
         ld X (X BIG)
      end
   end
   ld A C  # Get byte
   shr C 8  # Shift out
   or B B  # Return B
   zxt
   ret

(code 'symCharCX_FACX 0)  # Return next char from symbol name
   call symByteCX_FACX  # First byte
   jz ret  # Return 'z' if none
   cmp B (hex "FF")  # Special?
   if ne  # No
      cmp B 128  # Single byte?
      if ge  # No
         test B (hex "20")  # Two bytes?
         if z  # Yes
            and B (hex "1F")  # First byte 110xxxxx
            shl A 6  # xxxxx000000
            push A
         else  # Three bytes
            and B (hex "F")  # First byte 1110xxxx
            shl A 6  # xxxx000000
            push A
            call symByteCX_FACX  # Second byte
            and B (hex "3F")  # 10xxxxxx
            or A (S)  # Combine
            shl A 6  # xxxxxxxxxx000000
            ld (S) A
         end
         call symByteCX_FACX  # Last byte
         and B (hex "3F")  # 10xxxxxx
         or (S) A  # Combine
         pop A  # Get result
      end
      ret
   end
   ld A TOP  # Return special "top" character
   or A A
   ret

(code 'bufStringE_SZ 0)
   ld Z S  # 8-byte-buffer
   push (Z)  # Save return address
   push X  # and X
   cmp E Nil  # Empty?
   if ne  # No
      ld X (E TAIL)
      call nameX_X  # Get name
      ld C 0
      do
         call symByteCX_FACX
      while nz
         ld (Z) B  # Store next byte
         add Z 1
         test Z 7  # Buffer full?
         if z  # Yes
            sub S 8  # Extend buffer
            movm (S) (S 8) (Z)
            sub Z 8  # Reset buffer pointer
         end
      loop
   end
   set (Z) 0  # Null byte
   add Z 8  # Round up
   off Z 7
   pop X
   ret

(code 'pathStringE_SZ 0)
   ld Z S  # 8-byte-buffer
   push (Z)  # Save return address
   push X  # and X
   cmp E Nil  # Empty?
   if ne  # No
      ld X (E TAIL)
      call nameX_X  # Get name
      ld C 0
      call symByteCX_FACX  # First byte
      if nz
         cmp B (char "+")  # Plus?
         if eq
            ld (Z) B  # Store "+"
            add Z 1
            call symByteCX_FACX  # Second byte
         end
         cmp B (char "@")  # Home path?
         if ne
            do
               ld (Z) B  # Store byte
               add Z 1
               test Z 7  # Buffer full?
               if z  # Yes
                  sub S 8  # Extend buffer
                  movm (S) (S 8) (Z)
                  sub Z 8  # Reset buffer pointer
               end
               call symByteCX_FACX  # Next byte?
            until z  # No
         else
            push E
            ld E (Home)  # Home directory?
            null E
            if nz  # Yes
               do
                  ld B (E)
                  ld (Z) B  # Store next byte
                  add Z 1
                  test Z 7  # Buffer full?
                  if z  # Yes
                     sub S 8  # Extend buffer
                     movm (S) (S 8) (Z)
                     sub Z 8  # Reset buffer pointer
                  end
                  add E 1
                  nul (E)  # More?
               until z  # No
            end
            pop E
            do
               call symByteCX_FACX
            while nz
               ld (Z) B  # Store next byte
               add Z 1
               test Z 7  # Buffer full?
               if z  # Yes
                  sub S 8  # Extend buffer
                  movm (S) (S 8) (Z)
                  sub Z 8  # Reset buffer pointer
               end
            loop
         end
      end
   end
   set (Z) 0  # Null byte
   add Z 8  # Round up
   off Z 7
   pop X
   ret

# (path 'any) -> sym
(code 'doPath 2)
   push Z
   ld E ((E CDR))  # Get arg
   call evSymE_E  # Evaluate to a symbol
   call pathStringE_SZ  # Write to stack buffer
   ld E S  # Make transient symbol
   call mkStrE_E
   ld S Z  # Drop buffer
   pop Z
   ret

# Add next char to symbol name
(code 'charSymACX_CX 0)
   cmp A (hex "80")  # ASCII??
   jlt byteSymBCX_CX  # Yes: 0xxxxxxx
   cmp A (hex "800")  # Double-byte?
   if lt  # Yes
      push A  # 110xxxxx 10xxxxxx
      shr A 6  # Upper five bits
      and B (hex "1F")
      or B (hex "C0")
      call byteSymBCX_CX  # Add first byte
      pop A
      and B (hex "3F")  # Lower 6 bits
      or B (hex "80")
      jmp byteSymBCX_CX  # Add second byte
   end
   cmp A TOP  # Special "top" character?
   if eq  # Yes
      ld B (hex "FF")
      jmp byteSymBCX_CX
   end
   push A  # 1110xxxx 10xxxxxx 10xxxxxx
   shr A 12  # Hightest four bits
   and B (hex "0F")
   or B (hex "E0")
   call byteSymBCX_CX  # Add first byte
   ld A (S)
   shr A 6  # Middle six bits
   and B (hex "3F")
   or B (hex "80")
   call byteSymBCX_CX  # Add second byte
   pop A
   and B (hex "3F")  # Lowest 6 bits
   or B (hex "80")  # Add third byte

# Add next byte to symbol name
(code 'byteSymBCX_CX 0)
   zxt
   big X  # Long name?
   if z  # No: Direct buffer pointer
      # 0000.xxxxxxx.xxxxxxx.xxxxxxx.xxxxxxx.xxxxxxx.xxxxxxx.xxxxxxx0010
      #   60      52      44      36      28      20      12       4
      cmp C 60  # Short digit full?
      if ne  # No
         shl A C  # Shift byte to character position
         or (X) A  # Combine with name digit
         add C 8  # Increment position
         ret
      end
      ld C (X)  # Get short number
      shr C 4  # De-normalize
      shl A 56  # Combine byte with digit
      or C A
      call boxNum_A  # Box number
      ld (A DIG) C
      ld (X) A
      ld X A
      ld C 4  # Start new digit
      ret
   end
   cmp C 60  # Short digit full?
   if ne  # No
      shl A C  # Shift byte to character position
      or (X BIG) A  # Combine with name digit
      add C 8  # Increment position
      ret
   end
   ld C (X BIG)  # Get short number
   shr C 4  # De-normalize
   shl A 56  # Combine byte with digit
   or C A
   call boxNum_A  # Box number
   ld (A DIG) C
   ld (X BIG) A
   ld X A
   ld C 4  # Start new digit
   ret

(code 'currFdX_C 0)
   ld C (EnvInFrames)  # InFrames or OutFrames?
   or C (EnvOutFrames)
   jz noFdErrX  # No
(code 'currFd_C)
   ld C (EnvOutFrames)  # OutFrames?
   null C
   if z  # No
      ld C (EnvInFrames)  # Use InFrames
   else
      null (EnvInFrames)  # InFrames?
      if nz  # Both
         cmp C (EnvInFrames)  # OutFrames > InFrames?
         if gt  # Yes
            ld C (EnvInFrames)  # Take InFrames
         end
      end
   end
   ld C (C I)  # Get 'fd'
   ret

(code 'rdOpenEXY)
   cmp E Nil  # Standard input?
   if eq  # Yes
      ld (Y I) 0  # fd = stdin
      ld (Y II) 0  # pid = 0
   else
      num E  # Descriptor?
      if nz  # Yes
         cnt E  # Need short
         jz cntErrEX
         ld (Y II) 0  # pid = 0
         ld A E  # Get fd
         shr A 4  # Normalize
         if c  # Negative
            ld C (EnvInFrames)  # Fetch from input frames
            do
               ld C (C)  # Next frame
               null C  # Any?
               jz badFdErrEX  # No
               sub A 1  # Found frame?
            until z  # Yes
            ld A (C I)  # Get fd from frame
         end
         ld (Y I) A  # Store 'fd'
         shl A 3  # Vector index
         cmp A (InFDs)  # 'fd' >= 'InFDs'?
         jge badFdErrEX  # Yes
         add A (InFiles)  # Get vector
         ld A (A)  # Input file
         null A  # Any?
         jz badFdErrEX  # No
      else
         push Z
         sym E  # File name?
         if nz  # Yes
            ld (Y II) 1  # pid = 1
            call pathStringE_SZ
            do
               ld B (S)  # First char
               cmp B (char "+")  # Plus?
               if eq  # Yes
                  cc open(&(S 1) (| O_APPEND O_CREAT O_RDWR) (oct "0666"))
               else
                  cc open(S O_RDONLY)
               end
               nul4  # OK?
            while s  # No
               call errno_A
               cmp A EINTR  # Interrupted?
               jne openErrEX  # No
               nul (Signal)  # Signal?
               if nz  # Yes
                  call sighandlerX
               end
            loop
            ld (Y I) A  # Save 'fd'
            ld B (S)  # First char
            cmp B (char "+")  # Plus?
            if eq  # Yes
               cc strdup(&(S 1))  # Duplicate name
            else
               cc strdup(S)  # Duplicate name
            end
            ld C (Y I)  # Get 'fd'
            call initInFileCA_A
            ld A (Y I)  # Get fd
            call closeOnExecAX
            ld S Z  # Drop buffer
         else  # Else pipe
            push X
            push 0  # End-of-buffers marker
            ld X E  # Get list
            ld E (X)  # Pathname
            call xSymE_E  # Make symbol
            call pathStringE_SZ  # Write to stack buffer
            do
               ld X (X CDR)  # Arguments?
               atom X
            while z  # Yes
               push Z  # Buffer chain
               ld E (X)  # Next argument
               call xSymE_E  # Make symbol
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
            ld X (X I)  # Retrieve X
            push A  # Create 'pipe' structure
            cc pipe(S)  # Open pipe
            nul4  # OK?
            jnz pipeErrX
            ld4 (S)  # Get pfd[0]
            call closeOnExecAX
            ld4 (S 4)  # Get pfd[1]
            call closeOnExecAX
            cc fork()  # Fork child process
            ld (Y II) A  # Set 'pid'
            nul4  # In child?
            js forkErrX
            if z  # Yes
               cc setpgid(0 0)  # Set process group
               ld4 (S)  # Close read pipe
               call closeAX
               ld4 (S 4)  # Get write pipe
               cmp A 1  # STDOUT_FILENO?
               if ne  # No
                  cc dup2(A 1)  # Dup to STDOUT_FILENO
                  ld4 (S 4)  # Close write pipe
                  call closeAX
               end
               cc execvp((S 8) &(S 8))  # Execute program
               jmp execErrS  # Error if failed
            end
            cc setpgid(A 0)  # Set process group
            ld4 (S 4)  # Close write pipe
            call closeAX
            ld4 (S)  # Get read pipe
            ld (Y I) A  # Set 'fd'
            call initInFileA_A
            pop A  # Drop 'pipe' structure
            do
               ld S Z  # Clean up buffers
               pop Z  # Chain
               null Z  # End?
            until z  # Yes
            pop X
         end
         pop Z
      end
   end
   ret

(code 'wrOpenEXY)
   cmp E Nil  # Standard output?
   if eq  # Yes
      ld (Y I) 1  # fd = stdout
      ld (Y II) 0  # pid = 0
   else
      num E  # Descriptor?
      if nz  # Yes
         cnt E  # Need short
         jz cntErrEX
         ld (Y II) 0  # pid = 0
         ld A E  # Get fd
         shr A 4  # Normalize
         if c  # Negative
            ld C (EnvOutFrames)  # Fetch from output frames
            do
               ld C (C)  # Next frame
               null C  # Any?
               jz badFdErrEX  # No
               sub A 1  # Found frame?
            until z  # Yes
            ld A (C I)  # Get fd from frame
         end
         ld (Y I) A  # Store 'fd'
         shl A 3  # Vector index
         cmp A (OutFDs)  # 'fd' >= 'OutFDs'?
         jnc badFdErrEX  # Yes
         add A (OutFiles)  # Get vector
         ld A (A)  # Slot?
         null A  # Any?
         jz badFdErrEX  # No
      else
         push Z
         sym E  # File name?
         if nz  # Yes
            ld (Y II) 1  # pid = 1
            call pathStringE_SZ
            do
               ld B (S)  # First char
               cmp B (char "+")  # Plus?
               if eq  # Yes
                  cc open(&(S 1) (| O_APPEND O_CREAT O_WRONLY) (oct "0666"))
               else
                  cc open(S (| O_CREAT O_TRUNC O_WRONLY) (oct "0666"))
               end
               nul4  # OK?
            while s  # No
               call errno_A
               cmp A EINTR  # Interrupted?
               jne openErrEX  # No
               nul (Signal)  # Signal?
               if nz  # Yes
                  call sighandlerX
               end
            loop
            ld (Y I) A  # Save 'fd'
            call initOutFileA_A
            ld A (Y I)  # Get fd
            call closeOnExecAX
            ld S Z  # Drop buffer
         else  # Else pipe
            push X
            push 0  # End-of-buffers marker
            ld X E  # Get list
            ld E (X)  # Pathname
            call xSymE_E  # Make symbol
            call pathStringE_SZ  # Write to stack buffer
            do
               ld X (X CDR)  # Arguments?
               atom X
            while z  # Yes
               push Z  # Buffer chain
               ld E (X)  # Next argument
               call xSymE_E  # Make symbol
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
            ld X (X I)  # Retrieve X
            push A  # Create 'pipe' structure
            cc pipe(S)  # Open pipe
            nul4  # OK?
            jnz pipeErrX
            ld4 (S)  # Get pfd[0]
            call closeOnExecAX
            ld4 (S 4)  # Get pfd[1]
            call closeOnExecAX
            cc fork()  # Fork child process
            ld (Y II) A  # Set 'pid'
            nul4  # In child?
            js forkErrX
            if z  # Yes
               cc setpgid(0 0)  # Set process group
               ld4 (S 4)  # Close write pipe
               call closeAX
               ld4 (S)  # Get read pipe
               cmp A 0  # STDIN_FILENO?
               if ne  # No
                  cc dup2(A 0)  # Dup to STDIN_FILENO
                  ld4 (S)  # Close read pipe
                  call closeAX
               end
               cc execvp((S 8) &(S 8))  # Execute program
               jmp execErrS  # Error if failed
            end
            cc setpgid(A 0)  # Set process group
            ld4 (S)  # Close read pipe
            call closeAX
            ld4 (S 4)  # Get write pipe
            ld (Y I) A  # Set 'fd'
            call initOutFileA_A
            pop C  # Drop 'pipe' structure
            do
               ld S Z  # Clean up buffers
               pop Z  # Chain
               null Z  # End?
            until z  # Yes
            pop X
         end
         pop Z
      end
   end
   ret

(code 'ctOpenEXY)
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   cmp E Nil  # Shared lock on current I/O channel?
   if eq  # Yes
      ld (Y I) -1  # 'fd'
      call currFdX_C  # Get current fd
      call rdLockFileC
   else
      cmp E TSym  # Exclusive lock on current I/O channel?
      if eq  # Yes
         ld (Y I) -1  # 'fd'
         call currFdX_C  # Get current fd
         call wrLockFileC
      else
         push Z
         call pathStringE_SZ  # File name
         do
            ld B (S)  # First char
            cmp B (char "+")  # Plus?
            if eq  # Yes
               cc open(&(S 1) (| O_CREAT O_RDWR) (oct "0666"))
            else
               cc open(S (| O_CREAT O_RDWR) (oct "0666"))
            end
            nul4  # OK?
         while s  # No
            call errno_A
            cmp A EINTR  # Interrupted?
            jne openErrEX  # No
            nul (Signal)  # Signal?
            if nz  # Yes
               call sighandlerX
            end
         loop
         ld S Z  # Drop buffer
         pop Z
         ld (Y I) A  # Save 'fd'
         ld C A  # Keep in C
         ld B (S)  # First char
         cmp B (char "+")  # Plus?
         if eq  # Yes
            call rdLockFileC  # Read lock
         else
            call wrLockFileC  # Write lock
         end
         ld A (Y I)  # Get fd
         call closeOnExecAX
      end
   end
   ret

(code 'getStdin_A 0)
   push Z
   ld Z (InFile)  # Current InFile
   null Z  # Any?
   if nz  # Yes
      cmp Z ((InFiles))  # On stdin?
      if ne  # No
         ld A (Z I)  # Get 'ix'
         cmp A (Z II)  # Equals 'cnt'?
         if eq  # Yes
            call slowZ_F  # Read into buffer
            jz 90  # Return -1
            ld A 0  # 'ix'
         end
         add (Z I) 1  # Increment 'ix'
         add A Z  # Fetch byte
         ld B (A VII)  # from buffer
         cmp B 10  # Newline?
         if z  # Yes
            add (Z IV) 1  # Increment line
         end
         zxt  # Extend into A
      else
         push C
         push E
         push X
         atom (Led)  # Line editor?
         if nz  # No
            ld C 0  # Standard input
            ld E -1  # No timeout
            ld X 0  # Runtime expression
            call waitFdCEX_A  # Wait for events
            call stdinByte_FA  # Get byte?
            if c  # No
               ld A -1  # Return -1
            end
         else
            ld C (LineC)
            null C  # First call?
            if ns  # No
               ld X (LineX)  # Get line status
            else
               ld E (Led)  # Run line editor
               call runE_E
               cmp E Nil  # NIL
               if eq  # Yes
                  ld X ZERO  # Empty
               else
                  ld X (E TAIL)
                  call nameX_X  # Get name
               end
               ld C 0
            end
            call symByteCX_FACX  # Extract next byte
            if z  # None
               ld A 10  # Default to linefeed
               ld C -1
            end
            ld (LineX) X  # Save line status
            ld (LineC) C
         end
         pop X
         pop E
         pop C
      end
   else
90    ld A -1  # Return EOF
   end
   ld (Chr) A
   pop Z
   ret

(code 'getParse_A 0)
   push C
   push X
   ld X (EnvParseX)  # Get parser status
   ld C (EnvParseC)
   call symByteCX_FACX  # Extract next byte
   if z  # Done
      ld A (EnvParseEOF)  # Yes
      ld B (hex "FF")  # Fill upper bits
      ror A 8  # Get next eof byte in B
      ld (EnvParseEOF) A
      sxt  # Extend B
   end
   ld (Chr) A
   ld (EnvParseX) X  # Save status
   ld (EnvParseC) C
   pop X
   pop C
   ret

(code 'pushInFilesY)
   ld A (InFile)  # Current InFile?
   null A
   if nz  # Yes
      ld (A III) (Chr)  # Save Chr in next
   end
   ld A (Y I)  # Get 'fd'
   shl A 3  # Vector index
   add A (InFiles)  # Get InFile
   ld A (A)
   ld (InFile) A  # Store new
   null A  # Any?
   if nz  # Yes
      ld A (A III)  # Get 'next'
   else
      ld A -1
   end
   ld (Chr) A  # Save in 'Chr'
   ld (Y III) (EnvGet_A)  # Save 'get'
   ld (EnvGet_A) getStdin_A  # Set new
   ld (Y) (EnvInFrames)  # Set link
   ld (EnvInFrames) Y  # Link frame
   ret

(code 'pushOutFilesY)
   ld A (Y I)  # Get 'fd'
   shl A 3  # Vector index
   add A (OutFiles)  # Get OutFile
   ld (OutFile) (A)  # Store new
   ld (Y III) (EnvPutB)  # Save 'put'
   ld (EnvPutB) putStdoutB  # Set new
   ld (Y) (EnvOutFrames)  # Set link
   ld (EnvOutFrames) Y  # Link frame
   ret

(code 'pushCtlFilesY)
   ld (Y) (EnvCtlFrames)  # Set link
   ld (EnvCtlFrames) Y  # Link frame
   ret

(code 'popInFiles)  # C
   ld C (EnvInFrames)  # Get InFrames
   null (C II)  # 'pid'?
   if nz  # Yes
      cc close((C I))  # Close 'fd'
      ld A (C I)  # Close input file
      call closeInFileA
      cmp (C II) 1  # 'pid' > 1?
      if gt  # Yes
         do
            cc waitpid((C II) 0 0)  # Wait for pipe process
            nul4  # OK?
         while s  # No
            call errno_A
            cmp A EINTR  # Interrupted?
            jne closeErrX
            nul (Signal)  # Signal?
            if nz  # Yes
               call sighandler0
            end
         loop
      end
   end
   ld (EnvGet_A) (C III)  # Retrieve 'get'
   ld C (C)  # Get link
   ld (EnvInFrames) C  # Restore InFrames
   null C  # Any?
   if z  # No
      ld A ((InFiles))  # InFiles[0] (stdin)
   else
      ld A (C I)  # Get 'fd'
      shl A 3  # Vector index
      add A (InFiles)
      ld A (A)  # Get previous InFile
   end
   ld (InFile) A  # Set InFile
   null A  # Any?
   if nz  # Yes
      ld A (A III)  # Get 'next'
   else
      ld A -1
   end
   ld (Chr) A  # Save in 'Chr'
   ret

(code 'popOutFiles)  # C
   ld A (OutFile)  # Flush OutFile
   call flushA_F
   ld C (EnvOutFrames)  # Get OutFrames
   null (C II)  # 'pid'?
   if nz  # Yes
      cc close((C I))  # Close 'fd'
      ld A (C I)  # Close input file
      call closeOutFileA
      cmp (C II) 1  # 'pid' > 1?
      if gt  # Yes
         do
            cc waitpid((C II) 0 0)  # Wait for pipe process
            nul4  # OK?
         while s  # No
            call errno_A
            cmp A EINTR  # Interrupted?
            jne closeErrX
            nul (Signal)  # Signal?
            if nz  # Yes
               call sighandler0
            end
         loop
      end
   end
   ld (EnvPutB) (C III)  # Retrieve 'put'
   ld C (C)  # Get link
   ld (EnvOutFrames) C  # Restore OutFrames
   null C  # Any?
   if z  # No
      ld A ((OutFiles) I)  # OutFiles[1] (stdout)
   else
      ld A (C I)  # Get 'fd'
      shl A 3  # Vector index
      add A (OutFiles)
      ld A (A)  # Get previous OutFile
   end
   ld (OutFile) A  # Set OutFile
   ret

(code 'popCtlFiles)  # C
   ld C (EnvCtlFrames)  # Get CtlFrames
   null (C I)  # 'fd' >= 0?
   if ns  # Yes
      cc close((C I))  # Close 'fd'
   else
      call currFd_C  # Get current fd
      ld A (| F_UNLCK (hex "00000"))  # Unlock, length 0
      call unLockFileAC  # Unlock
   end
   ld (EnvCtlFrames) ((EnvCtlFrames))  # Restore CtlFrames
   ret

# Get full char from input channel
(code 'getChar_A 0)
   ld A (Chr)  # Get look ahead
   cmp B (hex "FF")  # Special "top" character?
   if ne  # No
      cmp B 128  # Single byte?
      if ge  # No
         test B (hex "20")  # Two bytes?
         if z  # Yes
            and B (hex "1F")  # First byte 110xxxxx
            shl A 6  # xxxxx000000
            push A
         else  # Three bytes
            and B (hex "F")  # First byte 1110xxxx
            shl A 6  # xxxx000000
            push A
            call (EnvGet_A)  # Get second byte
            and B (hex "3F")  # 10xxxxxx
            or A (S)  # Combine
            shl A 6  # xxxxxxxxxx000000
            ld (S) A
         end
         call (EnvGet_A)  # Get last byte
         and B (hex "3F")  # 10xxxxxx
         or (S) A  # Combine
         pop A  # Get result
      end
      ret
   end
   ld A TOP
   ret

# Skip White Space and Comments
(code 'skipC_A 0)
   ld A (Chr)
   do
      null A  # EOF?
   while ns  # No
      do
         cmp B 32  # White space?
      while le  # Yes
         call (EnvGet_A)  # Get next
         null A  # EOF?
         js ret  # Yes
      loop
      cmp A C  # Comment char?
   while eq  # Yes
      call (EnvGet_A)
      cmp C (char "#")  # Block comment?
      jne 10  # No
      cmp B (char "{")
      if ne  # No
10       do
            cmp B 10  # Linefeed?
         while ne  #No
            null A  # EOF?
            js ret  # Yes
            call (EnvGet_A)
         loop
      else  # Block comment
         do
            call (EnvGet_A)
            null A  # EOF?
            js ret  # Yes
            cmp B (char "}")  # End of block comment?
            if eq
               call (EnvGet_A)
               cmp B (char "#")
               break eq  # Yes
            end
         loop
      end
      call (EnvGet_A)
   loop
   ret

(code 'testEscA_F 0)
   do
      null A  # EOF?
      if s  # Yes
         clrc  # Return NO
         ret
      end
      cmp B (char "\^")  # Caret?
      if eq  # Yes
         call (EnvGet_A)  # Skip '^'
         cmp B (char "?")  # Question-mark?
         if eq  # Yes
            ld B 127  # DEL
         else
            and B 31  # Control-character
         end
10       setc  # Return YES
         ret
      end
      cmp B (char "\\")  # Backslash?
      jnz 10  # No
      call (EnvGet_A)  # Skip '\'
      cmp B 10  # Newline?
      jnz 10  # No
      do
         call (EnvGet_A)  # Skip white space
         cmp B 32
         continue eq
         cmp B 9
      until ne
   loop

(code 'anonymousX_FE 0)
   ld C 0
   call symByteCX_FACX  # First byte
   cmp B (char "$")  # Starting with '$'?
   jne Ret  # No
   call symByteCX_FACX  # Second byte
   cmp B (char "1")  # >= '1'?
   if ge  # Yes
      cmp B (char "7")  # <= '7'?
      if le  # Yes
         sub B (char "0")  # Digit
         ld E A  # Calculate number
         call symByteCX_FACX  # Third byte
         do
            cmp B (char "0")  # >= '0'?
         while ge  # Yes
            cmp B (char "7")  # <= '7'?
         while le  # Yes
            shl E 3  # Times 8
            sub B (char "0")  # Digit
            add E A  # Add to result
            call symByteCX_FACX  # Next byte?
            if z  # No
               shl E 4  # Make symbol pointer
               or E SYM
               setz
               ret
            end
         loop
      end
   end
   ret

(code 'rdAtomBYL_E)  # X
   ld C 4  # Build name
   lea X (L I)  # Safe
   call byteSymBCX_CX  # Pack first char
   ld A Y  # Get second
   do
      null A  # EOF?
   while ns  # No
      memb Delim "(DelimEnd-Delim)"  # Delimiter?
      jeq 10  # Yes
      cmp B (char "\\")  # Backslash?
      if eq  # Yes
         call (EnvGet_A)  # Get next char
      end
      call byteSymBCX_CX  # Pack char
      call (EnvGet_A)  # Get next
   loop
10 ld X (L I)  # Get name
   ld A 0  # Scale
   cnt (Scl)  # Numeric?
   if nz  # Yes
      ld A (Scl)
      shr A 4  # Normalize
   end
   ld (Sep3) 0  # Thousand separator
   ld (Sep0) (char ".")  # Decimal separator
   call symToNumXA_FE  # Legal number?
   if nc  # No
      ld X (L I)  # Get name
      call anonymousX_FE  # Anonymous symbol?
      if ne  # No
         ld X (L I)  # Get name
         ld Y Intern
         ld E 0  # No symbol yet
         call internEXY_FE  # New internal symbol?
         if c  # Yes
            ld (E) Nil  # Init to 'NIL'
         end
      end
   end
   ret
: Delim ascii " \\t\\n\\r\\\"'(),[]`~{}"
: DelimEnd

(code 'rdList_E)
   call (EnvGet_A)  # Skip paren
   do
      ld C (char "#")
      call skipC_A  # and white space
      cmp B (char ")")  # Empty list?
      if eq  # Yes
         call (EnvGet_A)  # Skip paren
         ld E Nil  # Return NIL
         ret
      end
      cmp B (char "]")  # Empty list?
      jz retNil  # Yes
      cmp B (char "~")  # Tilde?
      if ne  # No
         ld A 0
         call readA_E  # Read expression
         call consE_A  # Make a pair
         ld (A) E
         ld (A CDR) Nil
         link
         push A  # <L I> Save it
         link
         ld E A  # Keep last cell in E
         jmp 10  # Exit
      end
      call (EnvGet_A)  # Skip tilde
      ld A 0
      call readA_E  # Read expression
      link
      push E  # <L I> Save it
      link
      eval  # Evaluate
      ld (L I) E  # Save again
      atom E  # Pair?
      if z  # Yes
         do
            atom (E CDR)  # Find last cell
         while z
            ld E (E CDR)
         loop
         jmp 10  # Exit
      end
      drop  # Continue
   loop
10 do
      ld C (char "#")
      call skipC_A  # Skip white space
      cmp B (char ")")  # Done?
      if eq  # Yes
         call (EnvGet_A)  # Skip paren
         jmp 90  # Done
      end
      cmp B (char "]")  # Done?
      jz 90  # Yes
      cmp B (char ".")  # Dotted pair?
      if eq  # Yes
         call (EnvGet_A)  # Skip dot
         memb Delim "(DelimEnd-Delim)"  # Delimiter?
         if eq  # Yes
            ld C (char "#")
            call skipC_A  # and white space
            cmp B (char ")")  # Circular list?
            jz 20  # Yes
            cmp B (char "]")
            if eq  # Yes
20             ld (E CDR) (L I)  # Store list in CDR
            else
               push E
               ld A 0
               call readA_E  # Read expression
               ld A E
               pop E
               ld (E CDR) A  # Store in CDR
            end
            ld C (char "#")
            call skipC_A  # Skip white space
            cmp B (char ")")  # Done?
            if eq  # Yes
               call (EnvGet_A)  # Skip paren
               jmp 90  # Done
            end
            cmp B (char "]")
            jz 90  # Done
            ld E (L I)  # Else bad dottet pair
            jmp badDotErrE
         end
         push X
         push Y
         link
         push ZERO  # <L I> Safe
         link
         push E
         ld Y A  # Save first char
         ld B (char ".")  # Restore dot
         call rdAtomBYL_E  # Read atom
         call consE_A  # Make a pair
         ld (A) E
         ld (A CDR) Nil
         pop E
         ld (E CDR) A  # Store in last cell
         ld E A
         drop
         pop Y
         pop X
      else
         cmp B (char "~")  # Tilde?
         if ne  # No
            push E
            ld A 0
            call readA_E  # Read expression
            call consE_A  # Make a pair
            ld (A) E
            ld (A CDR) Nil
            pop E
            ld (E CDR) A  # Store in last cell
            ld E A
         else
            call (EnvGet_A)  # Skip tilde
            push E
            ld A 0
            call readA_E  # Read expression
            ld A (S)
            ld (A CDR) E  # Save in last cell
            eval  # Evaluate
            pop A
            ld (A CDR) E  # Store in last cell
            do
               atom (E CDR)  # Pair?
            while z  # Yes
               ld E (E CDR)  # Find last cell
            loop
         end
      end
   loop
90 ld E (L I)  # Return list
   drop
   ret

(code 'readA_E)
   push X
   push Y
   link
   push ZERO  # <L I> Safe
   link
   push A  # <L -I> Top flag
   ld C (char "#")
   call skipC_A
   null A  # EOF?
   if s  # Yes
      null (L -I)  # Top?
      jz eofErr  # No: Error
      ld E Nil  # Yes: Return NIL
      jmp 99
   end
   null (L -I)  # Top?
   if nz  # Yes
      ld C (InFile)  # And reading file?
      null C
      if nz  # Yes
         ld (C V) (C IV)  # src = line
      end
   end
   cmp B (char "(")  # Opening a list?
   if eq  # Yes
      call rdList_E  # Read it
      null (L -I)  # Top?
      if nz  # Yes
         cmp (Chr) (char "]")  # And super-parentheses?
         if eq  # Yes
            call (EnvGet_A)  # Skip ']'
         end
      end
      jmp 99  # Return list
   end
   cmp B (char "[")  # Opening super-list?
   if eq  # Yes
      call rdList_E  # Read it
      cmp (Chr) (char "]")  # Matching super-parentheses?
      jnz suparErrE  # Yes: Error
      call (EnvGet_A)  # Else skip ']'
      jmp 99
   end
   cmp B (char "'")  # Quote?
   if eq  # Yes
      call (EnvGet_A)  # Skip "'"
      ld A 0
      call readA_E  # Read expression
      ld C E
      call consC_E  # Cons with 'quote'
      ld (E) Quote
      ld (E CDR) C
      jmp 99
   end
   cmp B (char ",")  # Comma?
   if eq  # Yes
      call (EnvGet_A)  # Skip ','
      ld X Uni  # Maintain '*Uni' index
      ld A 0
      call readA_E  # Read expression
      ld Y E
      ld (L I) E  # Save it
      call idxPutXY_E
      ld E Y  # Return value
      jmp 99
   end
   cmp B (char "`")  # Backquote?
   if eq  # Yes
      call (EnvGet_A)  # Skip '`'
      ld A 0
      call readA_E  # Read expression
      ld (L I) E  # Save it
      eval  # Evaluate
      jmp 99
   end
   cmp B (char "\"")  # String?
   if eq  # Yes
      call (EnvGet_A)  # Skip '"'
      cmp B (char "\"")  # Empty string?
      if eq  # Yes
         call (EnvGet_A)  # Skip '"'
         ld E Nil  # Return NIL
         jmp 99
      end
      call testEscA_F
      jnc eofErr
      ld C 4  # Build name
      lea X (L I)  # Safe
      do
         call byteSymBCX_CX  # Pack char
         call (EnvGet_A)  # Get next
         cmp B (char "\"")  # Done?
      while ne
         call testEscA_F
         jnc eofErr
      loop
      call (EnvGet_A)  # Skip '"'
      ld X (L I)  # Get name
      ld Y Transient
      ld E 0  # No symbol yet
      call internEXY_FE  # Check transient symbol
      jmp 99
   end
   cmp B (char "{")  # External symbol?
   if eq  # Yes
      call (EnvGet_A)  # Skip '{'
      cmp B (char "}")  # Empty?
      if eq  # Yes
         call (EnvGet_A)  # Skip '}'
         call cons_E  # New symbol
         ld (E) ZERO  # anonymous
         or E SYM
         ld (E) Nil  # Set to NIL
         jmp 99
      end
      ld E 0  # Init file number
      do
         cmp B (char "@")  # File done?
      while ge  # No
         cmp B (char "O")  # In A-O range?
         jgt badInputErrB  # Yes
         sub B (char "@")
         shl E 4  # Add to file number
         add E A
         call (EnvGet_A)  # Get next char
      loop
      cmp B (char "0")  # Octal digit?
      jlt badInputErrB
      cmp B (char "7")
      jgt badInputErrB  # No
      sub B (char "0")
      zxt
      ld C A  # Init object ID
      do
         call (EnvGet_A)  # Get next char
         cmp B (char "}")  # Done?
      while ne  # No
         cmp B (char "0")  # Octal digit?
         jlt badInputErrB
         cmp B (char "7")
         jgt badInputErrB  # No
         sub B (char "0")
         shl C 3  # Add to object ID
         add C A
      loop
      call (EnvGet_A)  # Skip '}'
      call extNmCE_X  # Build external symbol name
      call externX_E  # New external symbol
      jmp 99
   end
   cmp B (char ")")  # Closing paren?
   jeq badInputErrB  # Yes
   cmp B (char "]")
   jeq badInputErrB
   cmp B (char "~")  # Tilde?
   jeq badInputErrB  # Yes
   cmp B (char "\\")  # Backslash?
   if eq  # Yes
      call (EnvGet_A)  # Get next char
   end
   ld Y A  # Save in Y
   call (EnvGet_A)  # Next char
   xchg A Y  # Get first char
   call rdAtomBYL_E  # Read atom
99 drop
   pop Y
   pop X
   ret

(code 'readC_E)
   null (Chr)  # Empty channel?
   if z  # Yes
      call (EnvGet_A)  # Fill 'Chr'
   end
   cmp C (Chr)  # Terminator?
   if eq  # Yes
      ld E Nil  # Return 'NIL'
   else
      ld A 1  # Top level
      call readA_E  # Read expression
      push E
      ld A (Chr)
      do
         null A  # EOF?
      while nsz  # No
         cmp B 32  # Space?
         jz 10
         cmp B 9  # Tab?
         jz 10
         cmp B (char ")")  # or closing parens?
         jz 10
         cmp B (char "]")
      while eq  # Yes
10       call (EnvGet_A)
      loop
      pop E
   end
   ret

(code 'tokenCE_E)  # X
   null (Chr)  # Look ahead char?
   if z  # No
      call (EnvGet_A)  # Get next
   end
   call skipC_A  # Skip white space and comments
   null A  # EOF?
   js retNull  # Yes
   cmp B (char "\"")  # String?
   if eq  # Yes
      call (EnvGet_A)  # Skip '"'
      cmp B (char "\"")  # Empty string?
      if eq  # Yes
         call (EnvGet_A)  # Skip '"'
         ld E Nil  # Return NIL
         ret
      end
      call testEscA_F
      jnc retNil
      link
      push ZERO  # <L I> Result
      ld C 4  # Build name
      ld X S
      link
      do
         call byteSymBCX_CX  # Pack char
         call (EnvGet_A)  # Get next
         cmp B (char "\"")  # Done?
         if eq  # Yes
            call (EnvGet_A)  # Skip '"'
            break T
         end
         call testEscA_F
      until nc
      ld X (L I)  # Get name
      drop
      jmp consSymX_E  # Make transient symbol
   end
   cmp B (char "0")  # Digit?
   if ge
      cmp B (char "9")
      if le  # Yes
         link
         push ZERO  # <L I> Result
         ld C 4  # Build digit string
         ld X S
         link
         do
            call byteSymBCX_CX  # Pack char
            call (EnvGet_A)  # Get next
            cmp B (char ".")  # Dot?
            continue eq  # Yes
            cmp B (char "0")  # Or digit?
         while ge
            cmp B (char "9")
         until gt  # No
         ld X (L I)  # Get name
         ld A 0  # Scale
         cnt (Scl)  # Numeric?
         if nz  # Yes
            ld A (Scl)
            shr A 4  # Normalize
         end
         drop
         ld (Sep3) 0  # Thousand separator
         ld (Sep0) (char ".")  # Decimal separator
         jmp symToNumXA_FE  # Convert to number
      end
   end
   push Y
   push Z
   ld Y A  # Keep char in Y
   call bufStringE_SZ  # <S I/IV> Stack buffer
   push A  # <S /III> String length
   slen (S) (S I)
   ld A Y  # Restore char
   cmp B (char "a")  # Lower case letter?
   if ge
      cmp B (char "z")
      jle 10  # Yes
   end
   cmp B (char "A")  # Upper case letter?
   if ge
      cmp B (char "Z")
      jle 10  # Yes
   end
   cmp B (char "\\")  # Backslash?
   if eq  # Yes
      call (EnvGet_A)  # Use next char
      jmp 10
   end
   memb (S I) (S)  # Member of character set?
   if eq  # Yes
10    link
      push ZERO  # <L I> Result
      ld C 4  # Build name
      ld X S
      link
      do
         call byteSymBCX_CX  # Pack char
         call (EnvGet_A)  # Get next
         cmp B (char "a")  # Lower case letter?
         if ge
            cmp B (char "z")
            continue le  # Yes
         end
         cmp B (char "A")  # Upper case letter?
         if ge
            cmp B (char "Z")
            continue le  # Yes
         end
         cmp B (char "0")  # Digit?
         if ge
            cmp B (char "9")
            continue le  # Yes
         end
         cmp B (char "\\")  # Backslash?
         if eq  # Yes
            call (EnvGet_A)  # Use next char
            continue T
         end
         memb (S IV) (S III)  # Member of character set?
      until ne  # No
      ld X (L I)  # Get name
      ld Y Intern
      ld E 0  # No symbol yet
      call internEXY_FE  # New internal symbol?
      if c  # Yes
         ld (E) Nil  # Init to 'NIL'
      end
      drop
   else
      call getChar_A
      call mkCharA_A  # Return char
      ld E A
      call (EnvGet_A)  # Skip it
   end
   ld S Z  # Drop buffer
   pop Z
   pop Y
   ret

# (read ['sym1 ['sym2]]) -> any
(code 'doRead 2)
   atom (E CDR)  # Arg?
   if nz  # No
      ld C 0  # No terminator
      call readC_E  # Read item
   else
      push X
      ld X (E CDR)  # Args
      ld E (X)  # Eval 'sym1'
      eval
      sym E  # Need symbol
      jz symErrEX
      link
      push E  # <L I> Safe
      link
      ld E ((X CDR))  # Eval 'sym2'
      eval
      sym E  # Need symbol
      jz symErrEX
      call firstCharE_A  # Get first character
      ld C A  # as comment char
      ld E (L I)  # Get Set of characters
      call tokenCE_E  # Read token
      null E  # Any?
      ldz E Nil  # No
      drop
      pop X
   end
   cmp (Chr) 10  # Hit linefeed?
   if eq  # Yes
      cmp (InFile) ((InFiles))  # Current InFile on stdin?
      if eq  # Yes
         ld (Chr) 0  # Clear it
      end
   end
   ret

# Check if input channel has data
(code 'inFilesA_FC 0)
   ld C A
   shl C 3  # Vector index
   add C (InFiles)  # Get vector
   ld C (C)  # Slot?
   null C  # Any?
   ret

(code 'inReadyC_F 0)
   cmp (C I) (C II)  # 'ix' < 'cnt'?
   ret  # Yes: 'nz'

(code 'inReadyA_FC 0)
   ld C A
   shl C 3  # Vector index
   cmp C (InFDs)  # 'fd' >= 'InFDs'?
   jge ret  # No
   add C (InFiles)  # Get vector
   ld C (C)  # Slot?
   null C  # Any?
   jz retnc  # No
   cmp (C I) (C II)  # 'ix' < 'cnt'?
   ret  # Yes: Return 'c'

(code 'rdSetRdyASL_F 0)  # Z
   ld C A
   shl C 3  # Vector index
   cmp C (InFDs)  # 'fd' >= 'InFDs'?
   jge rdSetASL_F  # Yes
   add C (InFiles)  # Get vector
   ld C (C)  # Slot?
   null C  # Any?
   jz rdSetASL_F  # No
   call inReadyC_F  # Data in buffer?
   if z  # No
      lea Z (L -III)  # Beyond last 'poll' structure
      do
         sub Z POLLFD  # Next structure
         cmp Z S  # More structures?
         jle retz  # No: 'z'
         cmp4 (Z)  # Found 'fd'?
      until eq  # Yes
      ld2 (Z POLL_REVENTS)  # 'revents'
      test A (| POLLIN POLLHUP)  # Ready?
      if nz  # Yes
         call slowNbC_FA  # Try non-blocking read
         jge retnz
         setz
      end
   end
   ret

(code 'rdSetASL_F 0)  # Z
   lea Z (L -III)  # Beyond last 'poll' structure
   do
      sub Z POLLFD  # Next structure
      cmp Z S  # More structures?
      jle retz  # No: 'z'
      cmp4 (Z)  # Found 'fd'?
   until eq  # Yes
   ld2 (Z POLL_REVENTS)  # 'revents'
   test A (| POLLIN POLLHUP)  # Ready?
   ret  # Return 'nz'

(code 'wrSetASL_F 0)  # Z
   lea Z (L -III)  # Beyond last 'poll' structure
   do
      sub Z POLLFD  # Next structure
      cmp Z S  # More structures?
      jle retz  # No: 'z'
      cmp4 (Z)  # Found 'fd'?
   until eq  # Yes
   ld2 (Z POLL_REVENTS)  # 'revents'
   test A POLLOUT  # Ready?
   ret  # Return 'nz'

(code 'waitFdCEX_A)
   push Y
   push Z
   push (EnvTask)  # <L IV> Save task list
   link
   push (At)  # <L II> '@'
   push ZERO  # <L I> '*Run'
   link
   push C  # <L -I> File descriptor
   push E  # <L -II> Milliseconds
   push E  # <L -III> Timeout
   do
      ld Z 0  # Structure count
      ld A (L -I)  # File descriptor
      null A  # Positive?
      if ns  # Yes
         call inReadyA_FC  # Ready?
         if c  # Yes
            ld (L -III) 0  # Timeout = 0
         else
            sub S POLLFD  # Create 'poll' structure
            st4 (S)  # Store 'fd'
            ld A POLLIN  # Poll input
            st2 (S POLL_EVENTS)  # Store 'events'
            add Z 1  # Increment count
         end
      end
      ld Y (Run)  # Get '*Run'
      ld (L I) Y  # Save it
      ld (EnvTask) Y
      do
         atom Y  # '*Run' elements?
      while z  # Yes
         ld E (Y)  # Next element
         ld A (L IV)  # memq in saved tasklist?
         do
            atom A  # End of tasklist?
         while z  # No
            cmp E (A)  # Member?
            jeq 10  # Yes: Skip
            ld A (A CDR)
         loop
         ld A (E)  # Get fd or timeout value
         shr A 4  # Negative?
         if c  # Yes
            ld A ((E CDR))  # Get CADR
            shr A 4  # Normalize
            cmp A (L -III)  # Less than current timeout?
            if lt  # Yes
               ld (L -III) A  # Set new timeout
            end
         else
            cmp A (L -I)  # Different from argument-fd?
            if ne  # Yes
               call inReadyA_FC  # Ready?
               if c  # Yes
                  ld (L -III) 0  # Timeout = 0
               else
                  sub S POLLFD  # Create 'poll' structure
                  st4 (S)  # Store 'fd'
                  ld A POLLIN  # Poll input
                  st2 (S POLL_EVENTS)  # Store 'events'
                  add Z 1  # Increment count
               end
            end
         end
10       ld Y (Y CDR)
      loop
      ld A (Hear)  # RPC listener?
      null A
      if nz  # Yes
         cmp A (L -I)  # Different from argument-fd?
         if ne  # Yes
            call inFilesA_FC  # Still open?
            if nz  # Yes
               call inReadyC_F  # Data in buffer?
               if nz  # Yes
                  ld (L -III) 0  # Timeout = 0
               else
                  sub S POLLFD  # Create 'poll' structure
                  st4 (S)  # Store 'Hear'
                  ld A POLLIN  # Poll input
                  st2 (S POLL_EVENTS)  # Store 'events'
                  add Z 1  # Increment count
               end
            end
         end
      end
      ld A (Spkr)  # Speaker open?
      null A
      if nz  # Yes
         sub S POLLFD  # Create 'poll' structure
         st4 (S)  # Store 'Spkr'
         ld A POLLIN  # Poll input
         st2 (S POLL_EVENTS)  # Store 'events'
         add Z 1  # Increment count
      end
      ld Y (Child)  # Iterate children
      ld E (Children)  # Count
      do
         sub E VI  # More?
      while ge  # Yes
         null (Y)  # 'pid'?
         if nz  # Yes
            sub S POLLFD  # Create 'poll' structure
            ld A (Y I)  # Store child's 'hear' fd
            st4 (S)
            ld A POLLIN  # Poll input
            st2 (S POLL_EVENTS)  # Store 'events'
            add Z 1  # Increment count
            null (Y IV)  # Child's buffer count?
            if nz  # Yes
               sub S POLLFD  # Create 'poll' structure
               ld A (Y II)  # Store child's 'tell' fd
               st4 (S)
               ld A POLLOUT  # Poll output
               st2 (S POLL_EVENTS)  # Store 'events'
               add Z 1  # Increment count
            end
         end
         add Y VI  # Increment by sizeof(child)
      loop
      call msec_A  # Get milliseconds
      ld E A  # into E
      do
         cc poll(S Z (L -III))  # Wait for event or timeout
         nul4  # OK?
      while s  # No
         call errno_A
         cmp A EINTR  # Interrupted?
         if ne  # No
            ld (Run) Nil  # Clear '*Run'
            jmp selectErrX
         end
         nul (Signal)  # Signal?
         if nz  # Yes
            call sighandlerX
         end
      loop
      call msec_A  # Get milliseconds
      sub A E  # Time difference
      ld (L -III) A  # Save it
      set (Flg) 0  # Guarantee flushed pipes
      ld Y (Child)  # Iterate children
      ld Z (Children)  # Count
      do
         sub Z VI  # More?
      while ge  # Yes
         null (Y)  # 'pid'?
         if nz  # Yes
            push Z  # Outer loop count
            ld A (Y I)  # Get child's 'hear' fd
            call rdSetASL_F  # Ready?
            if nz  # Yes
               ld C (Y I)  # Get 'hear' fd again
               ld E 2  # Size of count
               ld X Buf  # Buffer pointer
               call rdBytesNbCEX_F  # Read count
               if ns  # Greater or equal zero
                  if z
                     call clsChildY  # Close child
                     pop Z
                     continue T
                  end
                  sub S PIPE_BUF  # <S II> Pipe buffer
                  push Y  # <S> Outer child index
                  ld C (Y I)  # Get 'hear' fd again
                  ld2 (Buf)  # Get size
                  ld E A
                  lea X (S II)  # Buffer pointer
                  call rdBytesCEX_F  # Read data?
                  if nz  # Yes
                     set (Flg) 1  # Still got data from pipe
                     ld Y (Child)  # Iterate children
                     ld Z (Children)  # Count
                     do
                        cmp Y (S)  # Same as outer loop child?
                        if ne  # No
                           null (Y)  # 'pid'?
                           if nz  # Yes
                              ld2 (Buf)  # Get size
                              ld C A
                              lea X (S II)  # and data
                              call wrChildCXY  # Write to child
                           end
                        end
                        add Y VI  # Increment by sizeof(child)
                        sub Z VI  # More?
                     until z  # No
                  else
                     call clsChildY  # Close child
                     pop Y
                     add S PIPE_BUF  # Drop 'tell' buffer
                     pop Z
                     continue T
                  end
                  pop Y
                  add S PIPE_BUF  # Drop 'tell' buffer
               end
            end
            ld A (Y II)  # Get child's 'tell' fd
            call wrSetASL_F  # Ready?
            if nz  # Yes
               ld C (Y II)  # Get 'tell' fd again
               ld X (Y V)  # Get buffer pointer
               add X (Y III)  # plus buffer offset
               ld2 (X)  # Get size
               ld E A
               add X 2  # Point to data (beyond size)
               push E  # Keep size
               call wrBytesCEX_F  # Write data?
               pop E
               if z  # Yes
                  add E (Y III)  # Add size to buffer offset
                  add E 2  # plus size of size
                  ld (Y III) E  # New buffer offset
                  add E E  # Twice the offset
                  cmp E (Y IV)  # greater or equal to buffer count?
                  if ge  # Yes
                     sub (Y IV) (Y III)  # Decrement count by offset
                     if nz
                        ld X (Y V)  # Get buffer pointer
                        add X (Y III)  # Add buffer offset
                        movn ((Y V)) (X) (Y IV)  # Copy data
                        ld A (Y V)  # Get buffer pointer
                        ld E (Y IV)  # and new count
                        call allocAE_A  # Shrink buffer
                        ld (Y V) A  # Store
                     end
                  end
                  ld (Y III) 0  # Clear buffer offset
               else
                  call clsChildY  # Close child
               end
            end
            pop Z
         end
         add Y VI  # Increment by sizeof(child)
      loop
      nul (Flg)  # All pipes flushed?
      if z  # Yes
         ld A (Spkr)  # Speaker open?
         null A
         if nz  # Yes
            call rdSetASL_F  # Ready?
            if nz  # Yes
               ld C (Spkr)  # Get fd
               ld E I  # Size of slot
               ld X Buf  # Buffer pointer
               call rdBytesNbCEX_F  # Read slot?
               if nsz  # Yes
                  ld Y (Child)  # Get child
                  add Y (Buf)  # in slot
                  null (Y)  # 'pid'?
                  if nz  # Yes
                     ld C 2  # Size of 'TBuf'
                     ld X TBuf  # Buffer pointer
                     call wrChildCXY  # Write to child
                  end
               end
            end
         end
      end
      ld A (Hear)  # RPC listener?
      null A
      if nz  # Yes
         cmp A (L -I)  # Different from argument-fd?
         if ne  # Yes
            call rdSetRdyASL_F  # Ready?
            if nz  # Yes
               call rdHear_FE  # Read expression?
               if nc  # Yes
                  cmp E TSym  # Read 'T'?
                  if eq  # Yes
                     set (Sync) 1  # Set sync flag
                  else
                     link
                     push E  # Save expression
                     link
                     call evListE_E  # Execute it
                     drop
                  end
               else
                  call closeAX  # Close 'Hear'
                  ld A (Hear)
                  call closeInFileA
                  ld A (Hear)
                  call closeOutFileA
                  ld (Hear) 0  # Clear value
               end
            end
         end
      end
      ld Y (L I)  # Get '*Run'
      do
         atom Y  # More elements?
      while z  # Yes
         ld E (Y)  # Next element
         ld A (L IV)  # memq in saved tasklist?
         do
            atom A  # End of tasklist?
         while z  # No
            cmp E (A)  # Member?
            jeq 20  # Yes: Skip
            ld A (A CDR)
         loop
         ld A (E)  # Get fd or timeout value
         shr A 4  # Negative?
         if c  # Yes
            ld C (E CDR)  # Get CDR
            ld A (C)  # and CADR
            shr A 4  # Normalize
            sub A (L -III)  # Subtract time difference
            if nc  # Not yet timed out
               shl A 4  # Make short number
               or A CNT
               ld (C) A  # Store in '*Run'
            else  # Timed out
               ld A (E)  # Timeout value
               ld (C) A  # Store in '*Run'
               ld (At) (E)  # Set to CAR
               ld Z (C CDR)  # Run body
               prog Z
            end
         else
            cmp A (L -I)  # Different from argument-fd?
            if ne  # Yes
               call rdSetRdyASL_F  # Ready?
               if nz  # Yes
                  ld (At) (E)  # Set to fd
                  ld Z (E CDR)  # Run body
                  prog Z
               end
            end
         end
20       ld Y (Y CDR)
      loop
      nul (Signal)  # Signal?
      if nz  # Yes
         call sighandlerX
      end
      ld A (L -II)  # Milliseconds
      or A A
      if nsz  # Greater zero
         sub A (L -III)  # Subtract time difference
         if s  # < 0
            xor A A  # Set to zero, 'z'
         end
         ld (L -II) A
      end
   while nz  # Milliseconds non-zero
      ld (L -III) A  # Set timeout
      ld A (L -I)  # File descriptor
      null A  # Positive?
   while ns  # Yes
      call rdSetRdyASL_F  # Ready?
   while z  # No
      lea S (L -III)  # Drop 'poll' structures
   loop
   ld (At) (L II)  # Restore '@'
   ld A (L -II)  # Return milliseconds
   drop
   pop (EnvTask)
   pop Z
   pop Y
   ret

# (wait ['cnt] . prg) -> any
(code 'doWait 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval 'cnt'
   eval
   cmp E Nil  # None?
   if eq  # Yes
      push -1  # Wait infinite
   else
      call xCntEX_FE  # Get 'cnt'
      push E  # <S> Milliseconds
   end
   ld Y (Y CDR)  # Y on 'prg'
   do
      ld Z Y  # Run 'prg'
      prog Z
      cmp E Nil  # NIL?
   while eq  # Yes
      ld C -1  # No file descriptor
      ld E (S)  # Milliseconds
      call waitFdCEX_A  # Wait for events
      null A  # Timeout?
      if z  # Yes
         prog Y  # Run 'prg'
         break T
      end
      ld (S) A  # New milliseconds
   loop
   pop A  # Drop milliseconds
   pop Z
   pop Y
   pop X
   ret

# (sync) -> flg
(code 'doSync 2)
   null (Mic)  # No 'mic' channel?
   jz retNil  # Yes
   null (Hear)  # No 'hear' channel?
   jz retNil  # Yes
   push X
   ld X E
   ld E Slot  # Buffer pointer
   ld C I  # Count
   do
      cc write((Mic) E C)  # Write 'Slot' to 'Mic'
      nul4  # OK?
      if ns  # Yes
         sub C A  # Decrement count
         break z  # Done
         add E A  # Increment buffer pointer
      else
         call errno_A
         cmp A EINTR  # Interrupted?
         jne wrSyncErrX  # No
      end
      nul (Signal)  # Signal?
      if nz  # Yes
         call sighandlerX
      end
   loop
   set (Sync) 0  # Clear sync flag
   do
      ld C -1  # No fd
      ld E C  # Wait infinite
      call waitFdCEX_A  # Wait for events
      nul (Sync)  # Synchronized?
   until nz  # Yes
   ld E TSym  # Return T
   pop X
   ret

# (hear 'cnt) -> cnt
(code 'doHear 2)
   push X
   ld X E
   ld E ((E CDR))  # E on arg
   eval  # Eval it
   cnt E  #  # Short number?
   jz cntErrEX  # No
   ld C E  # Get fd
   shr C 4  # Normalize
   jc badFdErrEX  # Negative
   ld A C  # Keep 'fd' in C
   shl A 3  # Vector index
   cmp A (InFDs)  # 'fd' >= 'InFDs'?
   jge badFdErrEX  # Yes
   add A (InFiles)  # Get vector
   ld A (A)  # Slot?
   null A  # Any?
   jz badFdErrEX  # No
   ld A (Hear)  # Current value?
   null A
   if nz  # Yes
      call closeAX  # Close 'Hear'
      ld A (Hear)
      call closeInFileA
      ld A (Hear)
      call closeOutFileA
   end
   ld (Hear) C  # Set new value
   pop X
   ret

# (tell 'sym ['any ..]) -> any
(code 'doTell 2)
   ld A (Tell)  # RPC?
   or A (Children)
   jz retNil  # No
   push X
   push Y
   push Z
   push (TellBuf)  # Save current 'tell' env
   sub S PIPE_BUF  # New 'tell' buffer
   ld Z S  # Buffer pointer
   call tellBegZ_Z  # Start 'tell' message
   ld X (E CDR)  # Args
   do
      ld E (X)  # Eval next
      eval
      ld Y E  # Keep result
      call prTellEZ  # Print to 'tell'
      ld X (X CDR)  # More args?
      atom X
   until nz  # No
   call tellEndZ  # Close 'tell'
   ld E Y  # Get result
   add S PIPE_BUF  # Drop 'tell' buffer
   pop (TellBuf)
   pop Z
   pop Y
   pop X
   ret

# (poll 'cnt) -> cnt | NIL
(code 'doPoll 2)
   push X
   ld X E
   ld E ((E CDR))  # E on arg
   eval  # Eval it
   ld A E  # Keep
   call xCntEX_FE  # Get fd
   xchg A E
   null A  # fd < 0?
   js badFdErrEX  # Yes
   ld C A
   shl C 3  # Vector index
   cmp C (InFDs)  # 'fd' >= 'InFDs'?
   jge badFdErrEX  # Yes
   call inFilesA_FC  # Readable input file?
   ldz E Nil  # No: Return NIL
   if nz
      do
         call inReadyC_F  # Data in buffer?
      while z  # No
         sub S POLLFD  # Create 'poll' structure
         st4 (S)  # Store 'fd'
         ld A POLLIN  # Poll input
         st2 (S POLL_EVENTS)  # Store 'events'
         do
            cc poll(S 1 0)  # Check
            nul4  # OK?
         while s  # No
            call errno_A
            cmp A EINTR  # Interrupted?
            if ne  # No
               ld (Run) Nil  # Clear '*Run'
               jmp selectErrX
            end
         loop
         ld2 (S POLL_REVENTS)  # 'revents'
         add S POLLFD  # Drop 'poll' structure
         test A (| POLLIN POLLHUP)  # Ready?
         ldz E Nil  # No: Return NIL
      while nz
         call slowNbC_FA  # Try non-blocking read
      until ge
   end
   pop X
   ret

# (key ['cnt]) -> sym
(code 'doKey 2)
   push X
   ld X E
   ld E ((E CDR))  # E on arg
   eval  # Eval it
   cmp E Nil  # None?
   if eq  # Yes
      ld E -1  # Wait infinite
   else
      call xCntEX_FE  # Get milliseconds
   end
   call flushAll  # Flush all output channels
   call setRaw  # Set terminal to raw mode
   ld C 0  # Standard input
   call waitFdCEX_A  # Wait for events
   null A  # Timeout?
   if nz  # No
      call stdinByte_FA  # First byte?
      if nc  # Yes
         cmp B (hex "FF")  # Special "top" character?
         if ne  # No
            cmp B 128  # Single byte?
            if ge  # No
               test B (hex "20")  # Two bytes?
               if z  # Yes
                  and B (hex "1F")  # First byte 110xxxxx
                  shl A 6  # xxxxx000000
                  push A
               else  # Three bytes
                  and B (hex "F")  # First byte 1110xxxx
                  shl A 6  # xxxx000000
                  push A
                  call stdinByte_FA  # Read second byte
                  and B (hex "3F")  # 10xxxxxx
                  or A (S)  # Combine
                  shl A 6  # xxxxxxxxxx000000
                  ld (S) A
               end
               call stdinByte_FA  # Read last byte
               and B (hex "3F")  # 10xxxxxx
               or (S) A  # Combine
               pop A  # Get result
            end
         else
            ld A TOP
         end
         call mkCharA_A  # Return char
         ld E A
         pop X
         ret
      end
   end
   ld E Nil
   pop X
   ret

# (peek) -> sym
(code 'doPeek 2)
   ld A (Chr)  # Look ahead char?
   null A
   if z  # No
      call (EnvGet_A)  # Get next
   end
   null A  # EOF?
   js retNil  # Yes
   call mkCharA_A  # Return char
   ld E A
   ret

# (char) -> sym
# (char 'cnt) -> sym
# (char T) -> sym
# (char 'sym) -> cnt
(code 'doChar 2)
   push X
   ld X E
   ld E (E CDR)  # Any args?
   atom E
   if nz  # No
      ld A (Chr)  # Look ahead char?
      null A
      if z  # No
         call (EnvGet_A)  # Get next
      end
      null A  # EOF?
      if ns  # No
         call getChar_A
         call mkCharA_A  # Make char
         ld E A
         call (EnvGet_A)  # Get next
      else
         ld E Nil
      end
      pop X
      ret
   end
   ld E (E)
   eval  # Eval arg
   cnt E  # 'cnt'?
   if nz  # Yes
      ld A E  # Get 'cnt'
      shr A 4  # Normalize
      if nz
         call mkCharA_A  # Make char
         ld E A
      else
         ld E Nil
      end
      pop X
      ret
   end
   sym E  # 'sym'?
   jz atomErrEX  # No
   cmp E TSym  # T?
   if ne
      call firstCharE_A
      shl A 4  # Make short number
      or A CNT
   else
      ld A TOP  # Special "top" character
      call mkCharA_A
   end
   ld E A
   pop X
   ret

# (skip ['any]) -> sym
(code 'doSkip 2)
   ld E ((E CDR))  # Get arg
   call evSymE_E  # Evaluate to a symbol
   call firstCharE_A  # Get first character
   ld C A  # Use as comment char
   call skipC_A  # Skip white space and comments
   null A  # EOF?
   js retNil  # Yes
   ld A (Chr)  # Return 'Chr'
   call mkCharA_A  # Return char
   ld E A
   ret

# (eol) -> flg
(code 'doEol 2)
   cmp (Chr) 10  # Linefeed?
   jeq retT  # Yes
   null (Chr)  # Chr <= 0?
   jsz retT  # Yes
   ld E Nil  # Return NIL
   ret

# (eof ['flg]) -> flg
(code 'doEof 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   cmp E Nil  # NIL?
   if eq  # Yes
      ld A (Chr)  # Look ahead char?
      null A
      if z  # No
         call (EnvGet_A)  # Get next
      end
      null A  # EOF?
      jns RetNil  # No
   else
      ld (Chr) -1  # Set EOF
   end
   ld E TSym  # Return T
   ret

# (from 'any ..) -> sym
(code 'doFrom 2)
   push X
   push Z
   ld X (E CDR)  # X on args
   push 0  # End-of-buffers marker
   do
      call evSymX_E  # Next argument
      call bufStringE_SZ  # <S V> Stack buffer
      push 0  # <S IV> Index
      link
      push E  # <S II> Symbol
      link
      push Z  # <S> Buffer chain
      ld X (X CDR)  # More arguments?
      atom X
   until nz  # No
   ld A (Chr)  # Look ahead char?
   null A
   if z  # No
      call (EnvGet_A)  # Get next
   end
   do
      null A  # EOF?
   while ns  # No
      ld Z S  # Buffer chain
      do
         do
            lea C (Z V)  # Stack buffer
            add C (Z IV)  # Index
            cmp B (C)  # Bytes match?
            if eq  # Yes
               add (Z IV) 1  # Increment index
               nul (C 1)  # End of string?
               break nz  # No
               call (EnvGet_A)  # Skip next input byte
               ld E (Z II)  # Return matched symbol
               jmp 90
            end
            null (Z IV)  # Still at beginning of string?
            break z  # Yes
            lea C (Z (+ V 1))  # Offset pointer to second byte
            do
               sub (Z IV) 1  # Decrement index
            while nz
               cmpn (Z V) (C) (Z IV)  # Compare stack buffer
            while nz
               add C 1  # Increment offset
            loop
         loop
         ld Z (Z)  # Next in chain
         null (Z)  # Any?
      until z  # No
      call (EnvGet_A)  # Get next input byte
   loop
   ld E Nil  # Return NIL
90 pop Z  # Clean up buffers
   do
      drop
      ld S Z
      pop Z
      null Z  # End?
   until z  # Yes
   pop Z
   pop X
   ret

# (till 'any ['flg]) -> lst|sym
(code 'doTill 2)
   push X
   push Z
   ld X (E CDR)  # Args
   call evSymX_E  # Evaluate to a symbol
   call bufStringE_SZ  # <S I/IV> Stack buffer
   push A  # <S /III> String length
   slen (S) (S I)
   ld A (Chr)  # Look ahead char?
   null A
   if z  # No
      call (EnvGet_A)  # Get next
   end
   null A  # EOF?
   if ns  # No
      memb (S I) (S)  # Matched first char?
      if ne  # No
         ld E ((X CDR))  # Eval 'flg'
         eval
         cmp E Nil  # NIL?
         if eq  # Yes
            call getChar_A  # Get first character
            call mkCharA_A  # Make char
            call consA_X  # Build first cell
            ld (X) A
            ld (X CDR) Nil
            link
            push X  # <L I> Result list
            link
            do
               call (EnvGet_A)  # Get next
               null A  # EOF?
            while nsz  # No
               memb (S IV) (S III)  # Matched char?
            while ne  # No
               call getChar_A  # Get next character
               call mkCharA_A
               call consA_C  # Build next cell
               ld (C) A
               ld (C CDR) Nil
               ld (X CDR) C  # Append to sublist
               ld X C
            loop
            ld E (L I)  # Get result list
         else
            link
            push ZERO  # <L I> Result
            ld X S
            link
            ld C 4  # Build name
            do
               call getChar_A  # Get next character
               call charSymACX_CX  # Insert
               call (EnvGet_A)  # Get next
               null A  # EOF?
            while nsz  # No
               memb (S IV) (S III)  # Matched char?
            until eq  # Yes
            ld X (L I)  # Get result name
            call consSymX_E
         end
         drop
         ld S Z  # Drop buffer
         pop Z
         pop X
         ret
      end
   end
   ld E Nil  # Return NIL
   ld S Z  # Drop buffer
   pop Z
   pop X
   ret

(code 'eolA_F 0)
   null A  # EOF?
   js retz  # Yes
   cmp A 10  # Linefeed?
   if ne  # No
      cmp A 13  # Return?
      jne Ret  # No
      call (EnvGet_A)  # Get next
      cmp A 10  # Linefeed?
      jnz retz
   end
   ld (Chr) 0  # Clear look ahead
   ret  # 'z'

# (line 'flg ['cnt ..]) -> lst|sym
(code 'doLine 2)
   ld A (Chr)  # Look ahead char?
   null A
   if z  # No
      call (EnvGet_A)  # Get next
   end
   call eolA_F  # End of line?
   jeq retNil  # Yes
   push X
   push Y
   push Z
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval 'flg'
   eval
   cmp E Nil  # 'flg' was non-NIL?
   if ne  # Yes: Pack
      ld Y (Y CDR)  # More args?
      atom Y
      if nz  # No
         link
         push ZERO  # <L I> Result
         ld X S
         link
         ld C 4  # Build name
         do
            call getChar_A  # Get next character
            call charSymACX_CX  # Insert
            call (EnvGet_A)  # Get next
            call eolA_F  # End of line?
         until eq  # Yes
         ld X (L I)  # Get result name
         call consSymX_E
      else
         call cons_Z  # First cell of top list
         ld (Z) ZERO
         ld (Z CDR) Nil
         link
         push Z  # <L I> Result
         link
         do
            ld C 4  # Build name
            ld X Z
            call getChar_A  # Get next character
            call charSymACX_CX  # Insert first char
            push C
            ld E (Y)
            eval  # Eval next arg
            pop C
            shr E 4  # Normalize
            do
               sub E 1  # Decrement count
            while nz
               call (EnvGet_A)  # Get next
               call eolA_F  # End of line?
               if eq  # Yes
                  ld X (Z)  # Get last sub-result
                  call consSymX_E
                  ld (Z) E
                  jmp 20
               end
               call getChar_A  # Get next character
               call charSymACX_CX  # Insert
            loop
            ld X (Z)  # Get last sub-result
            call consSymX_E
            ld (Z) E
            ld Y (Y CDR)  # More args?
            atom Y
            jnz 10  # No
            call (EnvGet_A)  # Get next
            call eolA_F  # End of line?
            jeq 20  # Yes
            call cons_A  # New cell to top list
            ld (A) ZERO
            ld (A CDR) Nil
            ld (Z CDR) A
            ld Z A
         loop
      end
   else
      call getChar_A  # Get first character
      call mkCharA_A  # Make char
      call consA_Z  # Build first cell
      ld (Z) A
      ld (Z CDR) Nil
      link
      push Z  # <L I> Result
      link
      ld Y (Y CDR)  # More args?
      atom Y
      if z  # Yes
         ld X Z  # Current sublist
         call cons_Z  # First cell of top list
         ld (Z) X
         ld (Z CDR) Nil
         ld (L I) Z  # New result
         do
            ld E (Y)
            eval  # Eval next arg
            shr E 4  # Normalize
            do
               sub E 1  # Decrement count
            while nz
               call (EnvGet_A)  # Get next
               call eolA_F  # End of line?
               jeq 20  # Yes
               call getChar_A  # Get next character
               call mkCharA_A
               call consA_C  # Build next cell
               ld (C) A
               ld (C CDR) Nil
               ld (X CDR) C  # Append to sublist
               ld X C
            loop
            ld Y (Y CDR)  # More args?
            atom Y
         while z  # Yes
            call (EnvGet_A)  # Get next
            call eolA_F  # End of line?
            jeq 20  # Yes
            call getChar_A  # Get next character
            call mkCharA_A
            call consA_X  # Build new sublist
            ld (X) A
            ld (X CDR) Nil
            call consX_A  # Append to top list
            ld (A) X
            ld (A CDR) Nil
            ld (Z CDR) A
            ld Z A
         loop
      end
10    do
         call (EnvGet_A)  # Get next
         call eolA_F  # End of line?
      while ne  # No
         call getChar_A  # Get next character
         call mkCharA_A
         call consA_C  # Build next cell
         ld (C) A
         ld (C CDR) Nil
         ld (Z CDR) C  # Append
         ld Z C
      loop
20    ld E (L I)  # Get result
   end
   drop
   pop Z
   pop Y
   pop X
   ret

# (lines 'any ..) -> cnt
(code 'doLines 2)
   push X
   push Y
   push Z
   ld X (E CDR)  # Args
   ld Y 0  # Result
   do
      atom X  # More args?
   while z  # Yes
      call evSymX_E  # Evaluate next file name
      call pathStringE_SZ  # Write to stack buffer
      cc fopen(S _r_)  # Open file
      ld S Z  # Drop buffer
      null A  # OK?
      if nz  # Yes
         ld E A  # File pointer
         null Y  # First hit?
         if z  # Yes
            ld Y ZERO  # Init short number
         end
         do
            cc getc_unlocked(E)  # Next char
            nul4  # EOF?
         while ns  # No
            cmp A 10  # Linefeed?
            if eq  # Yes
               add Y (hex "10")  # Increment count
            end
         loop
         cc fclose(E)  # Close file pointer
      end
      ld X (X CDR)
   loop
   null Y  # Result?
   ld E Y  # Yes
   ldz E Nil  # No
   pop Z
   pop Y
   pop X
   ret

(code 'parseBCE_E)
   push (EnvParseX)  # Save old parser status
   push (EnvParseC)
   push (EnvParseEOF)
   push (EnvGet_A)  # Save 'get' status
   push (Chr)
   ld E (E TAIL)
   call nameE_E  # Get name
   link
   push E  # Save it
   link
   ld (EnvParseX) E  # Set new parser status
   ld (EnvParseC) 0
   null C  # Token?
   if z  # No
      ld E (hex "FFFFFFFFFF5D0A00")  # linefeed, ']', EOF
   else
      ld E -1
   end
   ld (EnvParseEOF) E
   ld (EnvGet_A) getParse_A  # Set 'get' status
   ld (Chr) 0
   or B B  # Skip?
   if nz  # Yes
      call getParse_A  # Skip first char
   end
   null C  # Token?
   if z  # No
      call rdList_E  # Read a list
   else
      push X
      push C  # <S III> Set of characters
      ld E C  # in E
      ld C 0  # No comment char
      call tokenCE_E  # Read token
      null E  # Any?
      ldz E Nil
      if nz  # Yes
         call consE_X  # Build first result cell
         ld (X) E
         ld (X CDR) Nil
         link
         push X  # <L I> Result
         link
         do
            ld C 0  # No comment char
            ld E (S III)  # Get set of characters
            push X
            call tokenCE_E  # Next token?
            pop X
            null E
         while nz  # Yes
            call consE_A  # Build next result cell
            ld (A) E
            ld (A CDR) Nil
            ld (X CDR) A
            ld X A
         loop
         ld E (L I)  # Get result
         drop
      end
      pop A  # Drop set
      pop X
   end
   drop
   pop (Chr)  # Retrieve 'get' status
   pop (EnvGet_A)
   pop (EnvParseEOF)  # Restore old parser status
   pop (EnvParseC)
   pop (EnvParseX)
   ret

# (any 'sym) -> any
(code 'doAny 2)
   push X
   ld X E
   ld E ((E CDR))  # E on arg
   eval  # Eval it
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   cmp E Nil  # NIL?
   if ne  # No
      push (EnvParseX)  # Save old parser status
      push (EnvParseC)
      push (EnvParseEOF)
      push (EnvGet_A)  # Save 'get' status
      push (Chr)
      ld E (E TAIL)
      call nameE_E  # Get name
      link
      push E  # Save it
      link
      ld (EnvParseX) E  # Set new parser status
      ld (EnvParseC) 0
      ld (EnvParseEOF) (hex "FFFFFFFFFFFF2000")  # Blank, EOF
      ld (EnvGet_A) getParse_A  # Set 'get' status
      ld (Chr) 0
      call getParse_A  # Skip first char
      ld A 1  # Top level
      call readA_E  # Read expression
      drop
      pop (Chr)  # Retrieve 'get' status
      pop (EnvGet_A)
      pop (EnvParseEOF)  # Restore old parser status
      pop (EnvParseC)
      pop (EnvParseX)
   end
   pop X
   ret

# (sym 'any) -> sym
(code 'doSym 2)
   ld E ((E CDR))  # Eval arg
   eval
   link
   push E  # Save
   link
   call begString  # Start string
   call printE  # Print to string
   call endString_E  # Retrieve result
   drop
   ret

# (str 'sym ['sym1]) -> lst
# (str 'lst) -> sym
(code 'doStr 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   cmp E Nil  # NIL?
   if ne  # No
      num E  # Number?
      jnz argErrEX  # Yes
      sym E  # Symbol?
      if nz  # Yes
         link
         push E  # <L II> 'sym'
         link
         ld X (Y CDR)  # Second arg?
         atom X
         if nz  # No
            ld C 0  # No token
         else
            call evSymX_E  # Eval 'sym1'
            tuck E  # Save
            link
            ld C E  # Get token
            ld E (L II)  # and 'sym'
         end
         ld B 0  # Don't skip
         call parseBCE_E  # Parse
         drop
      else
         link
         push E  # Save 'lst'
         link
         call begString  # Start string
         ld X E  # 'lst'
         do
            ld E (X)  # Get CAR
            call printE  # Print to string
            ld X (X CDR)  # More items?
            atom X
         while z  # Yes
            call space
         loop
         call endString_E  # Retrieve result
         drop
      end
   end
   pop Y
   pop X
   ret

# Read-Eval-Print loop
(code 'loadBEX_E)
   ld C A  # Save prompt in C
   sym E  # Symbolic argument?
   if nz  # Yes
      ld A (E TAIL)
      call firstByteA_B  # starting with "-"?
      cmp B (char "-")
      if eq  # Yes
         ld C 0  # No token
         call parseBCE_E  # Parse executable list
         link
         push E  # Save expression
         link
         call evListE_E  # Execute it
         drop
         ret
      end
   end
   push Y
   link
   push ZERO  # <L II>
   push ZERO  # <L I>
   link
   push C  # <L -I> Prompt
   sub S IV  # InFrame
   ld Y S
   call rdOpenEXY
   ld E Nil  # Close transient scope
   call doHide
   call pushInFilesY
   do
      ld A ((InFiles))  # Get stdin
      cmp A (InFile)  # Reading from file?
      if ne  # Yes
         ld C 0  # No terminator
         call readC_E  # Read expression
      else
         ld A (L -I)
         or B B  # Prompt?
         if nz  # Yes
            null (Chr)
            if z
               call (EnvPutB)  # Output prompt
               call space
               call flushAll
            end
         end
         ld C 10  # Linefeed terminator
         cc isatty(0)  # STDIN
         nul4  # on a tty?
         ldz C 0  # No
         call readC_E  # Read expression
         cmp (Chr) 10  # Hit linefeed?
         if eq  # Yes
            ld (Chr) 0  # Clear it
         end
      end
      cmp E Nil
   while ne
      ld (L I) E  # Save read expression
      ld A ((InFiles))  # Get stdin
      cmp A (InFile)  # Reading from file?
      if nz  # Yes
10       eval  # Evaluate
      else
         null (Chr)  # Line?
         jnz 10  # Yes
         ld A (L -I)
         or B B  # Prompt?
         jz 10  # No
         call flushAll
         ld (L II) (At)  # Save '@'
         eval  # Evaluate
         ld (At) E  # Save result
         ld (At3) (At2)
         ld (At2) (L II)  # Retrieve previous '@'
         ld C Arrow
         call outStringC
         call flushAll
         call printE_E
         call newline
      end
      ld (L I) E  # Save result
   loop
   call popInFiles
   ld E Nil  # Close transient scope
   call doHide
   ld E (L I)
   drop
   pop Y
   ret
: Arrow string "-> "

# (load 'any ..) -> any
(code 'doLoad 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   do
      ld E (Y)  # Eval arg
      eval
      cmp E TSym  # Load remaining command line args?
      if ne  # No
         ld B (char ">")  # Prompt
         call loadBEX_E
      else
         call loadAllX_E
      end
      ld Y (Y CDR)  # More args?
      atom Y
   until nz  # No
   pop Y
   pop X
   ret

# (in 'any . prg) -> any
(code 'doIn 2)
   push X
   push Y
   ld X E  # Expression in X
   ld E (E CDR)
   ld E (E)  # Eval 'any'
   eval
   sub S IV  # InFrame
   ld Y S
   call rdOpenEXY
   call pushInFilesY
   ld X ((X CDR) CDR)  # Get 'prg'
   prog X
   call popInFiles
   add S IV  # Drop InFrame
   pop Y
   pop X
   ret

# (out 'any . prg) -> any
(code 'doOut 2)
   push X
   push Y
   ld X E  # Expression in X
   ld E (E CDR)
   ld E (E)  # Eval 'any'
   eval
   sub S IV  # OutFrame
   ld Y S
   call wrOpenEXY
   call pushOutFilesY
   ld X ((X CDR) CDR)  # Get 'prg'
   prog X
   call popOutFiles
   add S IV  # Drop InFrame
   pop Y
   pop X
   ret

# (pipe exe) -> cnt
# (pipe exe . prg) -> any
(code 'doPipe 2)
   push X
   push Y
   ld X E  # Expression in X
   sub S IV  # In/OutFrame
   ld Y S
   push A  # Create 'pipe' structure
   cc pipe(S)  # Open pipe
   nul4  # OK?
   jnz pipeErrX
   ld4 (S)  # Get pfd[0]
   call closeOnExecAX
   ld4 (S 4)  # Get pfd[1]
   call closeOnExecAX
   call forkLispX_FE  # Fork child process
   if c  # In child
      atom ((X CDR) CDR)  # 'prg'?
      if z  # Yes
         cc setpgid(0 0)  # Set process group
      end
      ld4 (S)  # Close read pipe
      call closeAX
      ld4 (S 4)  # Get write pipe
      cmp A 1  # STDOUT_FILENO?
      if ne  # No
         cc dup2(A 1)  # Dup to STDOUT_FILENO
         ld4 (S 4)  # Close write pipe
         call closeAX
      end
      ld E Nil  # Standard output
      call wrOpenEXY
      call pushOutFilesY
      ld (Run) Nil  # Switch off all tasks
      ld E ((X CDR))  # Get 'exe'
      eval  # Evaluate it
      ld E 0  # Exit OK
      jmp byeE
   end
   ld (Y II) E  # Set 'pid'
   ld4 (S 4)  # Close write pipe
   call closeAX
   ld4 (S)  # Get read pipe
   call initInFileA_A
   ld E (A)  # Get file descriptor
   ld X ((X CDR) CDR)  # Get 'prg'
   atom X  # Any?
   if nz  # No
      shl E 4  # In parent
      or E CNT  # Return PID
   else
      ld (Y I) E  # Save 'fd'
      cc setpgid((Y II) 0)  # Set process group
      call pushInFilesY
      prog X
      call popInFiles
   end
   add S (+ 8 IV)  # Drop 'pipe' structure and In/OutFrame
   pop Y
   pop X
   ret

# (ctl 'sym . prg) -> any
(code 'doCtl 2)
   push X
   push Y
   ld X E  # Expression in X
   ld E (E CDR)
   ld E (E)  # Eval 'any'
   eval
   push A  # CtlFrame
   push A
   ld Y S
   call ctOpenEXY
   call pushCtlFilesY
   ld X ((X CDR) CDR)  # Get 'prg'
   prog X
   call popCtlFiles
   pop A  # Drop CtlFrame
   pop A
   pop Y
   pop X
   ret

# (open 'sym) -> cnt | NIL
(code 'doOpen 2)
   push X
   push Z
   ld X E
   ld E ((E CDR))  # Get arg
   call evSymE_E  # Evaluate to a symbol
   call pathStringE_SZ  # Write to stack buffer
   do
      cc open(S (| O_CREAT O_RDWR) (oct "0666"))  # Try to open
      nul4  # OK?
   while s  # No
      call errno_A
      cmp A EINTR  # Interrupted?
      if nz  # No
         ld E Nil  # Return NIL
         jmp 90
      end
      nul (Signal)  # Signal?
      if nz  # Yes
         call sighandlerX
      end
   loop
   ld X A  # Keep 'fd'
   call closeOnExecAX
   ld C X  # 'fd'
   cc strdup(S)  # Duplicate name
   call initInFileCA_A  # Init input file structure
   ld A X  # 'fd' again
   call initOutFileA_A  # Init output file structure
   ld E X  # Return 'fd'
   shl E 4  # Make short number
   or E CNT
90 ld S Z  # Drop buffer
   pop Z
   pop X
   ret

# (close 'cnt) -> cnt | NIL
(code 'doClose 2)
   push X
   ld X E
   ld E ((E CDR))  # Eval 'cnt'
   eval
   ld C E  # Keep in E
   call xCntCX_FC  # Get fd
   cc close(C)  # Close it
   nul4  # OK?
   ldnz E Nil
   if z  # Yes
      ld A C  # Close InFile
      call closeInFileA
      ld A C  # Close OutFile
      call closeOutFileA
   end
   pop X
   ret

# (echo ['cnt ['cnt]] | ['sym ..]) -> sym
(code 'doEcho 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   ld Y (Y CDR)  # Next arg
   ld A (Chr)  # Look ahead char?
   null A
   if z  # No
      call (EnvGet_A)  # Get next
   end
   cmp E Nil  # Empty arg?
   if eq  # Yes
      atom Y  # No further args?
      if nz  # Yes
         do
            null A  # EOF?
         while ns  # No
            call (EnvPutB)  # Output byte
            call (EnvGet_A)  # Get next
         loop
         ld E TSym  # Return T
         pop Y
         pop X
         ret
      end
   end
   num E  # Number?
   if nz  # Yes
      call xCntEX_FE  # Get 'cnt'
      atom Y  # Second 'cnt' arg?
      if z  # Yes
         ld Y (Y)  # Get second 'cnt'
         xchg Y E  # First 'cnt' in Y
         call evCntEX_FE  # Evaluate second
         ld A (Chr)  # Get Chr again
         do
            sub Y 1  # Decrement first 'cnt'
         while ns
            null A  # EOF?
            if s  # Yes
               ld E Nil  # Return NIL
               pop Y
               pop X
               ret
            end
            call (EnvGet_A)  # Get next
         loop
      end
      do
         sub E 1  # Decrement second 'cnt'
      while ns
         null A  # EOF?
         if s  # Yes
            ld E Nil  # Return NIL
            pop Y
            pop X
            ret
         end
         call (EnvPutB)  # Output byte
         call (EnvGet_A)  # Get next
      loop
      ld E TSym  # Return T
      pop Y
      pop X
      ret
   end
   sym E  # Need symbol
   jz argErrEX
   push Z
   push 0  # End-of-buffers marker
   do
      call bufStringE_SZ  # <S V> Stack buffer
      push 0  # <S IV> Index
      link
      push E  # <S II> Symbol
      link
      push Z  # <S> Buffer chain
      atom Y  # More arguments?
   while z  # Yes
      call evSymY_E  # Next argument
      ld Y (Y CDR)
   loop
   ld X 0  # Clear current max
   ld A (Chr)  # Look ahead char
   do
      null A  # EOF?
   while ns  # No
      ld Y X  # Output max
      null Y  # Any?
      if nz  # Yes
         ld E (Y IV)  # Set output index
      end
      ld Z S  # Buffer chain
      do
         do
            lea C (Z V)  # Stack buffer
            add C (Z IV)  # Index
            cmp B (C)  # Bytes match?
            if eq  # Yes
               add (Z IV) 1  # Increment index
               nul (C 1)  # End of string?
               if nz  # No
                  null X  # Current max?
                  if z  # No
                     ld X Z
                  else
                     cmp (X IV) (Z IV)  # Smaller than index?
                     ldc X Z  # Yes
                  end
                  break T
               end
               null Y  # Output max?
               if nz  # Yes
                  lea C (Y V)  # Buffer of output max
                  sub E (Z IV)  # Diff to current index
                  do  # Done?
                  while ge  # No
                     ld B (C)
                     call (EnvPutB)  # Output bytes
                     add C 1
                     sub E 1
                  loop
               end
               call (EnvGet_A)  # Skip next input byte
               ld E (Z II)  # Return matched symbol
               jmp 90
            end
            null (Z IV)  # Still at beginning of string?
            break z  # Yes
            lea C (Z (+ V 1))  # Offset pointer to second byte
            do
               sub (Z IV) 1  # Decrement index
            while nz
               cmpn (Z V) (C) (Z IV)  # Compare stack buffer
            while nz
               add C 1  # Increment offset
            loop
            cmp X Z  # On current max?
            if eq  # Yes
               ld X 0  # Clear current max
               ld C S  # Buffer chain
               do
                  null (C IV)  # Index?
                  if nz  # Yes
                     null X  # Current max?
                     if z  # No
                        ld X C
                     else
                        cmp (X IV) (C IV)  # Smaller than index?
                        ldc X C  # Yes
                     end
                  end
                  ld C (C)  # Next in chain
                  null (C)  # Any?
               until z  # No
            end
         loop
         ld Z (Z)  # Next in chain
         null (Z)  # Any?
      until z  # No
      null X  # Current max?
      if z  # No
         null Y  # Output max?
         if nz
            push A  # Save current byte
            push E  # and output index
            lea C (Y V)  # Buffer of output max
            do
               ld B (C)
               call (EnvPutB)  # Output bytes
               add C 1
               sub E 1  # Done?
            until z  # Yes
            pop E
            pop A
         end
         call (EnvPutB)  # Output current byte
      else
         null Y  # Output max?
         if nz
            lea C (Y V)  # Buffer of output max
            sub E (X IV)  # Diff to current max index
            do  # Done?
               while ge  # No
               ld B (C)
               call (EnvPutB)  # Output bytes
               add C 1
               sub E 1
            loop
         end
      end
      call (EnvGet_A)  # Get next input byte
   loop
   ld E Nil  # Return NIL
90 pop Z  # Clean up buffers
   do
      drop
      ld S Z
      pop Z
      null Z  # End?
   until z  # Yes
   pop Z
   pop Y
   pop X
   ret

(code 'putStdoutB 0)
   push Y
   ld Y (OutFile)  # OutFile?
   null Y
   if nz  # Yes
      push E
      push X
      ld E (Y I)  # Get 'ix'
      lea X (Y III)  # Buffer pointer
      cmp E BUFSIZ  # Reached end of buffer?
      if eq  # Yes
         push A
         push C
         ld (Y I) 0  # Clear 'ix'
         ld C (Y)  # Get 'fd'
         call wrBytesCEX_F  # Write buffer
         ld E 0  # Get 'ix'
         lea X (Y III)  # Buffer pointer
         pop C
         pop A
      end
      add X E  # Buffer index
      ld (X) B  # Store byte
      add E 1  # Increment ix
      ld (Y I) E  # Store 'ix'
      cmp B 10  # Linefeed?
      if eq  # Yes
         null (Y II)  # and 'tty'?
         if nz  # Yes
            push C
            ld (Y I) 0  # Clear 'ix'
            ld C (Y)  # Get 'fd'
            lea X (Y III)  # Buffer pointer
            call wrBytesCEX_F  # Write buffer
            pop C
         end
      end
      pop X
      pop E
   end
   pop Y
   ret

(code 'newline)
   ld B 10
   jmp (EnvPutB)

(code 'space)
   ld B 32
(code 'envPutB)  # DLL hook
   jmp (EnvPutB)

(code 'envGet_A)  # DLL hook
   jmp (EnvGet_A)

# Output decimal number
(code 'outNumE)
   shr E 4  # Normalize
   if c  # Sign
      ld B (char "-")  # Output sign
      call (EnvPutB)
   end
   ld A E
(code 'outWordA)
   cmp A 9  # Single digit?
   if gt  # No
      ld C 0  # Divide by 10
      div 10
      push C  # Save remainder
      call outWordA  # Recurse
      pop A
   end
   add B (char "0")  # Make ASCII digit
   jmp (EnvPutB)

(code 'prExtNmX)
   call fileObjX_AC  # Get file and object ID
   null A  # File?
   if nz  # Yes
      call outAoA  # Output file number
   end
   ld A C  # Get object ID
# Output octal number
(code 'outOctA 0)
   cmp A 7  # Single digit?
   if gt  # No
      push A  # Save
      shr A 3  # Divide by 8
      call outOctA  # Recurse
      pop A
      and B 7  # Get remainder
   end
   add B (char "0")  # Make ASCII digit
   jmp (EnvPutB)

# Output A-O encoding
(code 'outAoA 0)
   cmp A 15  # Single digit?
   if gt  # No
      push A  # Save
      shr A 4  # Divide by 16
      call outAoA  # Recurse
      pop A
      and B 15  # Get remainder
   end
   add B (char "@")  # Make ASCII letter
   jmp (EnvPutB)

(code 'outStringS)  # C
   lea C (S I)  # Buffer above return address
(code 'outStringC)
   do
      ld B (C)  # Next char
      add C 1
      or B B  # Null?
   while ne  # No
      call (EnvPutB)
   loop
   ret

(code 'outNameE)
   push X
   ld X (E TAIL)
   call nameX_X  # Get name
   call prNameX  # Print it
   pop X
   ret

(code 'prNameX)
   ld C 0
   do
      call symByteCX_FACX  # Next byte
   while nz
      call (EnvPutB)  # Output byte
   loop
   ret

# Print one expression
(code 'printE_E)
   push E  # Save expression
   call printE  # Print it
   pop E  # Restore
   ret

(code 'printE 0)
   nul (Signal)  # Signal?
   if nz  # Yes
      call sighandler0
   end
   cnt E  # Short number?
   jnz outNumE  # Yes
   big E  # Bignum?
   if nz  # Yes
      ld A -1  # Scale
      jmp fmtNum0AE_E  # Print it
   end
   push X
   sym E  # Symbol?
   if nz  # Yes
      ld X (E TAIL)
      call nameX_X  # Get name
      zero X  # Any?
      if eq  # No
         ld B (char "$")  # $xxxxxx
         call (EnvPutB)
         shr E 4  # Normalize symbol pointer
         ld A E
         call outOctA
         pop X
         ret
      end
      sym (E TAIL)  # External symbol?
      if nz  # Yes
         ld B (char "{")  # {AB123}
         call (EnvPutB)
         call prExtNmX  # Print it
         ld B (char "}")
         call (EnvPutB)
         pop X
         ret
      end
      push Y
      ld Y Intern
      call isInternEXY_F  # Internal symbol?
      if eq  # Yes
         ld C 0
         call symByteCX_FACX  # Get first byte
         do
            memb Delim "(DelimEnd-Delim)"  # Delimiter?
            if eq  # Yes
               push A  # Save char
               ld B (char "\\")  # Print backslash
               call (EnvPutB)
               pop A
            else
               cmp B (char ".")  # Dot?
               if eq  # Yes
                  call symByteCX_FACX  # Next byte?
                  if z  # No
                     ld B (char "\\")  # Print backslash
                     call (EnvPutB)
                     ld B (char ".")  # Print dot
                     call (EnvPutB)
                     break T  # Done
                  end
                  push A  # Save char
                  ld B (char ".")  # Print dot
                  call (EnvPutB)
                  pop A
               end
            end
            call (EnvPutB)  # Put byte
            call symByteCX_FACX  # Next byte
         until z  # Done
      else  # Else transient symbol
         call tsm_F  # Transient symbol markup?
         if z  # No
            ld B (char "\"")
            call (EnvPutB)
         else
            ld E ((Tsm))  # Get CAR
            call outNameE  # Write transient symbol markup
         end
         ld C 0
         call symByteCX_FACX  # Get first byte
         do
            cmp B (char "\"")  # Double quote?
            jz 20
            cmp B (char "\^")  # Caret?
            jz 20
            cmp B (char "\\")  # Backslash?
            if eq  # Yes
20             push A  # Save char
               ld B (char "\\")  # Escape with backslash
               call (EnvPutB)
               pop A
            else
               cmp B 127  # DEL?
               if eq  # Yes
                  ld B (char "\^")  # Print ^?
                  call (EnvPutB)
                  ld B (char "?")
               else
                  cmp B 32  # White space?
                  if lt  # Yes
                     push A  # Save char
                     ld B (char "\^")  # Escape with caret
                     call (EnvPutB)
                     pop A
                     or A 64  # Make printable
                  end
               end
            end
            call (EnvPutB)  # Put byte
            call symByteCX_FACX  # Next byte
         until z  # Done
         call tsm_F  # Transient symbol markup?
         if z  # No
            ld B (char "\"")  # Final double quote
            call (EnvPutB)
         else
            ld E ((Tsm) CDR)  # Get CDR
            call outNameE  # Write transient symbol markup
         end
      end
      pop Y
      pop X
      ret
   end
   # Print list
   cmp (E) Quote  # CAR 'quote'?
   if eq  # Yes
      cmp E (E CDR)  # Circular?
      if ne  # No
         ld B (char "'")  # Print single quote
         call (EnvPutB)
         ld E (E CDR)  # And CDR
         call printE
         pop X
         ret
      end
   end
   ld X E  # Keep list head
   ld B (char "(")  # Open paren
   call (EnvPutB)
   do
      push (E CDR)  # Save rest
      ld E (E)  # Print CAR
      call printE
      pop E
      cmp E Nil  # NIL-terminated?
   while ne  # No
      cmp E X  # Circular?
      if eq  # Yes
         call space  # Print " ."
         ld B (char ".")
         call (EnvPutB)
         break T
      end
      atom E  # Atomic tail?
      if nz  # Yes
         call space  # Print " . "
         ld B (char ".")
         call (EnvPutB)
         call space
         call printE  # and the atom
         break T
      end
      call space  # Print space
   loop
   ld B (char ")")  # Closing paren
   call (EnvPutB)
   pop X
   ret

(code 'tsm_F 0)
   cmp (Tsm) Nil  # Transient symbol markup?
   jeq ret  # No
   cmp (EnvPutB) putStdoutB  # to stdout?
   jne Retz  # No
   null ((OutFile) II)  # and 'tty'?
   ret  # Return 'nz'

# Print string representation
(code 'prinE_E 0)
   push E  # Save expression
   call prinE  # Print it
   pop E  # Restore
   ret

(code 'prinE 0)
   nul (Signal)  # Signal?
   if nz  # Yes
      call sighandler0
   end
   cmp E Nil  # NIL?
   if ne  # No
      cnt E  # Short number?
      jnz outNumE  # Yes
      big E  # Bignum?
      if nz  # Yes
         ld A -1  # Scale
         jmp fmtNum0AE_E  # Print it
      end
      push X
      sym E  # Symbol?
      if nz  # Yes
         ld X (E TAIL)
         call nameX_X  # Get name
         zero X  # Any?
         if ne  # Yes
            sym (E TAIL)  # External symbol?
            if z  # No
               call prNameX
            else
               ld B (char "{")  # {AB123}
               call (EnvPutB)
               call prExtNmX  # Print it
               ld B (char "}")
               call (EnvPutB)
            end
         end
      else
         ld X E  # Get list in X
         do
            ld E (X)  # Prin CAR
            call prinE
            ld X (X CDR)  # Next
            cmp X Nil  # NIL-terminated?
         while ne  # No
            atom X  # Done?
            if nz  # Yes
               ld E X  # Print atomic rest
               call prinE
               break T
            end
         loop
      end
      pop X
   end
   ret

# (prin 'any ..) -> any
(code 'doPrin 2)
   push X
   ld X (E CDR)  # Get arguments
   do
      ld E (X)
      eval  # Eval next arg
      call prinE_E  # Print string representation
      ld X (X CDR)  # More arguments?
      atom X
   until nz  # No
   pop X
   ret

# (prinl 'any ..) -> any
(code 'doPrinl 2)
   call doPrin  # Print arguments
   jmp newline

(code 'doSpace 2)
   push X
   ld X E
   ld E ((E CDR))  # Eval 'cnt'
   eval
   cmp E Nil  # NIL?
   if eq  # Yes
      call space  # Output single space
      ld E ONE  # Return 1
   else
      ld C E  # Keep in E
      call xCntCX_FC  # Get cnt
      do
         sub C 1  # 'cnt' times
      while ns
         call space  # Output spaces
      loop
   end
   pop X
   ret

# (print 'any ..) -> any
(code 'doPrint 2)
   push X
   ld X (E CDR)  # Get arguments
   do
      ld E (X)
      eval  # Eval next arg
      call printE_E  # Print it
      ld X (X CDR)  # More arguments?
      atom X
   while z  # Yes
      call space  # Print space
   loop
   pop X
   ret

# (printsp 'any ..) -> any
(code 'doPrintsp 2)
   push X
   ld X (E CDR)  # Get arguments
   do
      ld E (X)
      eval  # Eval next arg
      call printE_E  # Print it
      call space  # Print space
      ld X (X CDR)  # More arguments?
      atom X
   until nz  # No
   pop X
   ret

# (println 'any ..) -> any
(code 'doPrintln 2)
   call doPrint  # Print arguments
   jmp newline

# (flush) -> flg
(code 'doFlush 2)
   ld A (OutFile)  # Flush OutFile
   call flushA_F  # OK?
   ld E TSym  # Yes
   ldnz E Nil
   ret

# (rewind) -> flg
(code 'doRewind 2)
   ld E Nil  # Preload return value
   ld C (OutFile)  # OutFile?
   null C
   if nz  # Yes
      ld (C I) 0  # Clear 'ix'
      cc lseek((C) 0 SEEK_SET)  # Seek to beginning of file
      null A  # OK?
      if z  # Yes
         cc ftruncate((C) 0)  # Truncate file
         nul4  # OK?
         ldz E TSym  # Return T
      end
   end
   ret

# (ext 'cnt . prg) -> any
(code 'doExt 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   call evCntXY_FE  # Eval 'cnt'
   push (ExtN)  # Save external symbol offset
   ld (ExtN) E  # Set new
   ld X (Y CDR)  # Run 'prg'
   prog X
   pop (ExtN)  # Restore external symbol offset
   pop Y
   pop X
   ret

# (rd ['sym]) -> any
# (rd 'cnt) -> num | NIL
(code 'doRd 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   cnt E  # Read raw bytes?
   if z  # No
      push Z
      ld Z (InFile)  # Current InFile
      null Z  # Any?
      if nz  # Yes
         link
         push E  # <L I> EOF
         link
         ld (GetBinZ_FB) getBinaryZ_FB  # Set binary read function
         ld (Extn) (ExtN)  # Set external symbol offset
         call binReadZ_FE  # Read item?
         ldc E (L I)  # No: Return EOF
         drop
      end
      pop Z
      ret
   end
   ld C (InFile)  # Current InFile?
   null C
   jz retNil  # No
   push X
   push Y
   push Z
   link
   push ZERO  # <L I> Result
   link
   shr E 4  # Normalize
   jz 80  # Zero
   if c  # Little endian
      sub S E  # Buffer
      ld Y S  # Buffer pointer
      ld Z 1  # Forward direction
   else
      ld Y S  # Buffer pointer
      ld Z -1  # Backward direction
      add Y Z  # Point to last byte
      sub S E  # Buffer
   end
   ld C (C)  # Get 'fd' of InFile
   ld X S  # Buffer pointer
   push E  # <S> Count
   call rdBytesCEX_F  # OK?
   if z  # No
80    ld E Nil  # Return NIL
      jmp 90
   end
   lea X (L I)  # X on result
   ld C 4  # Build unsigned number
   do
      ld B (Y)  # Next byte from buffer
      call byteNumBCX_CX
      add Y Z  # Add direction offset
      sub (S) 1  # Decrement count
   until z
   ld E (L I)  # Get result
   big E  # Bignum?
   if nz  # Yes
      ld A E
      call zapZeroA_A  # Remove leading zeroes
      ld E A
   end
90 drop
   pop Z
   pop Y
   pop X
   ret

# (pr 'any ..) -> any
(code 'doPr 2)
   push X
   ld X (E CDR)  # Get arguments
   do
      ld E (X)
      eval  # Eval next arg
      push E  # Keep
      ld (Extn) (ExtN)  # Set external symbol offset
      call prE  # Print binary
      pop E
      ld X (X CDR)  # More arguments?
      atom X
   until nz  # No
   pop X
   ret

# (wr 'cnt ..) -> cnt
(code 'doWr 2)
   push X
   ld X (E CDR)  # Args
   do
      ld E (X)  # Eval next
      eval
      ld A E  # Get byte
      shr A 4  # Normalize
      call putStdoutB  # Output
      ld X (X CDR)  # X on rest
      atom X  # Done?
   until nz  # Yes
   pop X
   ret

# (rpc 'sym ['any ..]) -> flg
(code 'doRpc 2)
   push X
   ld X (E CDR)  # Args
   ld A BEG  # Begin list
   call putCharA
   do
      ld E (X)  # Eval next arg
      eval
      ld (PutBinBZ) putCharA  # Set binary print function
      ld (Extn) (ExtN)  # Set external symbol offset
      call binPrintEZ
      ld X (X CDR)  # X on rest
      atom X  # Any
   until nz  # No
   ld A END  # End list
   call putCharA
   cc fflush((stdout))  # Flush
   nul4  # OK?
   ld E Nil
   ldz E TSym  # Yes
   pop X
   ret

(code 'putCharA 0)
   cc putchar_unlocked(A)
   ret

# vi:et:ts=3:sw=3
