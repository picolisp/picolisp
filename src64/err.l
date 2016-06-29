# 27may16abu
# (c) Software Lab. Alexander Burger

# Debug print routine
(code 'dbg)
   push zscx  # Save flags
   push A  # Save registers
   push C
   push E
   push (OutFile)  # Save output channel
   ld (OutFile) ((OutFiles) II)  # Set to OutFiles[2] (stderr)
   push (PutB)  # Save 'put'
   ld (PutB) putStdoutB  # Set new
   ld E (Dbg)  # Print item
   call printE_E
   call newline  # and a newline
   pop (PutB)  # Restore 'put'
   pop (OutFile)  # and output channel
   pop E
   pop C
   pop A
   pop zscx
   ret

# System error number
(code 'errnoEXY)
   call errno_A  # Get 'errno'
   cc strerror(A)  # Convert to string
   ld Z A

# E reason
# X context
# Y message format
# Z message parameter
(code 'errEXYZ)
   null E  # Reason?
   if nz  # Yes
      link
      push E  # Save reason
      link
   else
      push E  # Push reason
      sub S I  # and dummy
   end
   sub S (+ 240 IV)  # <S> Message, <S 240> outFrame, <S (+ 240 V)> reason
   cc snprintf(S 240 Y Z)  # Build message
   null X  # Error context?
   ld A Nil
   ldnz A X  # Yes
   ld (Up) A  # Save it
   nul (S)  # Message empty?
   if nz  # No
      ld E S  # Make transient symbol
      call mkStrE_E
      ld (Msg) E  # Store in '*Msg'
      ld C (Catch)  # Search catch frames
      do
         null C  # Any?
      while nz  # Yes
         ld Y (C I)  # Tag non-zero?
         null Y
         if nz  # Yes
            do
               atom Y  # List?
            while z  # Yes
               ld A (Y)  # Next element of tag list
               ld E (Msg)  # Substring of '*Msg'?
               push C
               call subStrAE_F
               pop C
               if eq  # Yes
                  ld Y (Y)  # Get tag list element
                  cmp Y Nil  # NIL?
                  ldz Y (Msg)  # Yes: Use *Msg instead
                  push Y  # Save tag list element
                  call unwindC_Z  # Unwind environments
                  pop E  # Return tag list element from 'catch'
                  ld S Z  # Restore stack
                  pop (Catch)  # Restore catch link
                  add S (pack II "+(EnvEnd-Env)")  # Clean up
                  pop L
                  pop Z
                  pop Y
                  pop X
                  throw
               end
               ld Y (Y CDR)  # Tag list
            loop
         end
         ld C (C)  # Next frame
      loop
   end
   ld (Chr) 0  # Init globals
   ld (ExtN) 0
   ld (Break) 0
   ld (Alarm) Nil
   ld (Sigio) Nil
   ld (LineX) ZERO
   ld (LineC) -1
   lea Y (S 240)  # Pointer to outFrame
   ld (Y I) 2  # fd = stderr
   ld (Y II) 0  # pid = 0
   call pushOutFilesY
   ld Y (InFile)  # Current InFile
   null Y  # Any?
   if nz  # Yes
      ld C (Y VI)  # Filename?
      null C
      if nz  # Yes
         ld B (char "[")  # Output location
         call (PutB)
         call outStringC  # Print filename
         ld B (char ":")  # Separator ':'
         call (PutB)
         ld A (Y V)  # Get 'src'
         call outWordA  # Print line number
         ld B (char "]")
         call (PutB)
         call space
      end
   end
   null X  # Error context?
   if nz  # Yes
      ld C ErrTok  # Print error token
      call outStringC
      ld E X  # Get context
      call printE  # Print context
      call newline
   end
   ld E (S (+ 240 V))  # Get reason
   null E  # any?
   if nz  # Yes
      call printE  # Print reason
      ld C Dashes  # Print " -- "
      call outStringC
   end
   nul (S)  # Message empty?
   if nz  # No
      ld C S
      call outStringC  # Print message
      call newline
      cmp (Err) Nil  # Error handler?
      if ne  # Yes
         nul (Jam)  # Jammed?
         if z  # No
            set (Jam) 1  # Set flag
            ld X (Err)  # Run error handler
            prog X
            set (Jam) 0  # Reset flag
         end
      end
      ld E 1  # Exit error code
      cc isatty(0)  # STDIN
      nul4  # on a tty?
      jz byeE  # No
      cc isatty(1)  # STDOUT
      nul4  # on a tty?
      jz byeE  # No
      ld B (char "?")  # Prompt
      ld E Nil  # Load argument
      ld X 0  # Runtime expression
      call loadBEX_E
   end
   ld C 0  # Top frame
   call unwindC_Z  # Unwind
   ld (EnvProtect) 0  # Reset environments
   ld (EnvIntern) pico
   ld (EnvTask) Nil
   ld (EnvCo7) 0
   ld (EnvArgs) 0
   ld (EnvNext) 0
   ld (EnvMake) 0
   ld (EnvYoke) 0
   ld (EnvTrace) 0
   ld L 0  # Init link register
   ld S (Stack0)  # stack pointer
   null (Stacks)  # Coroutines?
   if nz  # Yes
      lea A (S 4096)  # Set stack limit
      sub A (StkSize)
      ld (StkLimit) A
   end
   ld (PutB) putStdoutB
   ld (Get_A) getStdin_A
   jmp restart  # Restart interpreter

(code 'unwindC_Z 0)
   push C  # <S> Target frame
   ld X (Catch)  # Catch link
   ld Y (EnvBind)  # Bindings
   do
      null X  # Catch frames?
   while nz  # Yes
      do
         null Y  # Bindings?
      while nz  # Yes
         ld C (Y -I)  # First env swap
         null C  # Zero?
         if nz  # No
            ld A C  # 'j'
            ld E 0  # 'n'
            ld Z Y  # Bindings in Z
            do
               inc E  # Increment 'n'
               inc A  # Done?
            while nz  # No
               ld Z ((Z) I)  # Follow link
               null Z  # Any?
            while nz  # Yes
               cmp (Z -I) C  # Env swap nesting?
               if lt  # Yes
                  dec A  # Adjust
               end
            loop
            do
               ld Z Y  # Get bindings
               ld A E  # and 'n'
               do
                  dec A  # 'n-1' times
               while nz
                  ld Z ((Z) I)  # Follow link
               loop
               sub (Z -I) C  # Increment 'eswp' by absolute first eswp
               if ge  # Last pass
                  if gt  # Overflowed
                     ld (Z -I) 0  # Reset
                  end
                  lea A ((Z) -II)  # End of bindings in A
                  do
                     xchg ((A)) (A I)  # Exchange next symbol value with saved value
                     sub A II
                     cmp A Z  # More?
                  until lt  # No
               end
               dec E  # Decrement 'n'
            until z  # Done
         end
         cmp Y (X III)  #  Reached last bind frame?
      while ne  # No
         ld C (Y)  # C on link
         null (Y -I)  # Env swap now zero?
         if z  # Yes
            add Y I  # Y on bindings
            do
               ld Z (Y)  # Next symbol
               add Y I
               ld (Z) (Y)  # Restore value
               add Y I
               cmp Y C  # More?
            until eq  # No
         end
         ld Y (C I)  # Bind link
      loop
      do
         cmp (EnvInFrames) (X (pack III "+(EnvInFrames-Env)"))  # Open input frames?
      while ne  # Yes
         call popInFiles  # Clean up
      loop
      do
         cmp (EnvOutFrames) (X (pack III "+(EnvOutFrames-Env)"))  # Open output frames?
      while ne  # Yes
         call popOutFiles  # Clean up
      loop
      do
         cmp (EnvErrFrames) (X (pack III "+(EnvErrFrames-Env)"))  # Open error frames?
      while ne  # Yes
         call popErrFiles  # Clean up
      loop
      do
         cmp (EnvCtlFrames) (X (pack III "+(EnvCtlFrames-Env)"))  # Open control frames?
      while ne  # Yes
         call popCtlFiles  # Clean up
      loop
      ld Z (EnvCo7)  # Get coroutines
      do
         cmp Z (X (pack III "+(EnvCo7-Env)"))  # Skipped?
      while ne  # Yes
         ld C (Stack1)  # Find stack segment
         do
            cmp C (Z II)  # Found 'seg'?
         while ne  # No
            sub C (StkSize)  # Next segment
         loop
         ld (C -I) 0  # Mark segment as unused
         dec (Stacks)  # Last coroutine?
         if z  # Yes
            ld (StkLimit) 0  # Clear stack limit
         end
         ld Z (Z)  # Next coroutine
      loop
      load (Env) (EnvEnd) (X III)  # Restore environment
      ld E (X II)  # 'fin'
      eval  # Evaluate 'finally' expression
      cmp X (S)  # Reached target catch frame?
      ld X (X)  # Catch link
      ld (Catch) X
      if eq  # Yes
         pop Z  # Get target frame
         ret
      end
   loop
   add S I  # Drop target frame
   do  # Top level bindings
      null Y  # Any?
   while nz  # Yes
      ld C (Y)  # C on link
      null (Y -I)  # Env swap zero?
      if z  # Yes
         add Y I  # Y on bindings
         do
            ld Z (Y)  # Next symbol
            add Y I
            ld (Z) (Y)  # Restore value
            add Y I
            cmp Y C  # More?
         until eq  # No
      end
      ld Y (C I)  # Bind link
   loop
   ld (EnvBind) 0
   do
      null (EnvInFrames)  # Open input frames?
   while nz  # Yes
      call popInFiles  # Clean up
   loop
   do
      null (EnvOutFrames)  # Open output frames?
   while nz  # Yes
      call popOutFiles  # Clean up
   loop
   do
      null (EnvErrFrames)  # Open error frames?
   while nz  # Yes
      call popErrFiles  # Clean up
   loop
   do
      null (EnvCtlFrames)  # Open control frames?
   while nz  # Yes
      call popCtlFiles  # Clean up
   loop
   ld X (Stack1)  # Search through stack segments
   ld C (Stacks)  # Segment count
   do
      null C  # Any?
   while nz  # Yes
      null (X -I)  # In use?
      if nz  # Yes
         null (X -II)  # Active?
         if z  # Yes
            ld (X -I) 0  # Mark segment as unused
            dec (Stacks)  # Last coroutine?
            if z  # Yes
               ld (StkLimit) 0  # Clear stack limit
            end
         end
         dec C  # Decrement count
      end
      sub X (StkSize)  # Next segment
   loop
   ret

### Checks ###
(code 'needSymAX 0)
   num A  # Need symbol
   jnz symErrAX
   sym A
   jz symErrAX
   cmp A Nil  # A < NIL ?
   jlt ret  # Yes
   cmp A TSym  # A > T ?
   jgt Ret  # Yes
   ld E A
   jmp protErrEX

(code 'needSymEX 0)
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   cmp E Nil  # E < NIL ?
   jlt ret  # Yes
   cmp E TSym  # E > T ?
   jgt Ret  # Yes
   jmp protErrEX

(code 'needVarAX 0)
   num A  # Need variable
   jnz varErrAX
   cmp A Nil  # A < NIL ?
   jlt ret  # Yes
   cmp A TSym  # A > T ?
   jgt Ret  # Yes
   ld E A
   jmp protErrEX

(code 'needVarEX 0)
   num E  # Need variable
   jnz varErrEX
   cmp E Nil  # E < NIL ?
   jlt ret  # Yes
   cmp E TSym  # E > T ?
   jgt Ret  # Yes
   jmp protErrEX

(code 'checkVarAX 0)
   cmp A Nil  # A < NIL ?
   jlt ret  # Yes
   cmp A TSym  # A > T ?
   jgt Ret  # Yes
   ld E A
   jmp protErrEX

(code 'checkVarYX 0)
   cmp Y Nil  # Y < NIL ?
   jlt ret  # Yes
   cmp Y TSym  # Y > T ?
   jgt Ret  # Yes
   ld E Y
   jmp protErrEX

(code 'checkVarEX 0)
   cmp E Nil  # E < NIL ?
   jlt ret  # Yes
   cmp E TSym  # E > T ?
   jgt Ret  # Yes
(code 'protErrEX)
   ld Y ProtErr
   jmp errEXYZ

(code 'symNsErrEX)
   ld Y SymNsErr
   jmp errEXYZ

### Error messages ###
(code 'stkErr)
   ld E 0
(code 'stkErrE)
   ld X E
(code 'stkErrX)
   ld E 0
(code 'stkErrEX)
   ld Y StkErr
   ld (StkLimit) 0  # Reset stack limit
   jmp errEXYZ

(code 'argErrAX)
   ld E A
(code 'argErrEX)
   ld Y ArgErr
   jmp errEXYZ

(code 'numErrAX)
   ld E A
(code 'numErrEX)
   ld Y NumErr
   jmp errEXYZ

(code 'cntErrAX)
   ld C A
(code 'cntErrCX)
   ld E C
(code 'cntErrEX)
   ld Y CntErr
   jmp errEXYZ

(code 'symErrAX)
   ld Y A
(code 'symErrYX)
   ld E Y
(code 'symErrEX)
   ld Y SymErr
   jmp errEXYZ

(code 'extErrEX)
   ld Y ExtErr
   jmp errEXYZ

(code 'pairErrAX)
   ld E A
(code 'pairErrEX)
   ld Y PairErr
   jmp errEXYZ

(code 'atomErrAX)
   ld E A
(code 'atomErrEX)
   ld Y AtomErr
   jmp errEXYZ

(code 'lstErrAX)
   ld E A
(code 'lstErrEX)
   ld Y LstErr
   jmp errEXYZ

(code 'varErrAX)
   ld E A
(code 'varErrEX)
   ld Y VarErr
   jmp errEXYZ

(code 'divErrX)
   ld E 0
   ld Y DivErr
   jmp errEXYZ

(code 'renErrEX)
   ld Y RenErr
   jmp errEXYZ

(code 'makeErrX)
   ld E 0
   ld Y MakeErr
   jmp errEXYZ

(code 'reentErrEX)
   ld Y ReentErr
   jmp errEXYZ

(code 'yieldErrX)
   ld E 0
(code 'yieldErrEX)
   ld Y YieldErr
   jmp errEXYZ

(code 'msgErrYX)
   ld A Y
(code 'msgErrAX)
   ld E A
(code 'msgErrEX)
   ld Y MsgErr
   jmp errEXYZ

(code 'brkErrX)
   ld E 0
   ld Y BrkErr
   jmp errEXYZ

# I/O errors
(code 'openErrEX)
   ld Y OpenErr
   jmp errnoEXY

(code 'closeErrX)
   ld E 0
(code 'closeErrEX)
   ld Y CloseErr
   jmp errnoEXY

(code 'pipeErrX)
   ld E 0
   ld Y PipeErr
   jmp errnoEXY

(code 'forkErrX)
   ld E 0
   ld Y ForkErr
   jmp errEXYZ

(code 'waitPidErrX)
   ld E 0
   ld Y WaitPidErr
   jmp errnoEXY

(code 'badFdErrEX)
   ld Y BadFdErr
   jmp errEXYZ

(code 'noFdErrX)
   ld E 0
   ld Y NoFdErr
   jmp errEXYZ

(code 'eofErr)
   ld E 0
   ld X 0
   ld Y EofErr
   jmp errEXYZ

(code 'suparErrE)
   ld X 0
   ld Y SuparErr
   jmp errEXYZ

(code 'badInputErrB)
   zxt
   ld Z A
   ld E 0
   ld X 0
   ld Y BadInput
   jmp errEXYZ

(code 'badDotErrE)
   ld X 0
   ld Y BadDot
   jmp errEXYZ

(code 'selectErrX)
   ld E 0
   ld Y SelectErr
   jmp errnoEXY

(code 'wrBytesErr)
   ld E 0
   ld X 0
   ld Y WrBytesErr
   jmp errnoEXY

(code 'wrChildErr)
   ld E 0
   ld X 0
   ld Y WrChildErr
   jmp errnoEXY

(code 'wrSyncErrX)
   ld E 0
   ld Y WrSyncErr
   jmp errnoEXY

(code 'wrJnlErr)
   ld E 0
   ld X 0
   ld Y WrJnlErr
   jmp errnoEXY

(code 'wrLogErr)
   ld E 0
   ld X 0
   ld Y WrLogErr
   jmp errnoEXY

(code 'truncErrX)
   ld E 0
   ld Y TruncErr
   jmp errnoEXY

(code 'dbSyncErrX)
   ld E 0
   ld Y DbSyncErr
   jmp errnoEXY

(code 'trSyncErrX)
   ld E 0
   ld Y TrSyncErr
   jmp errnoEXY

(code 'lockErr)
   ld E 0
   ld X 0
   ld Y LockErr
   jmp errnoEXY

(code 'dbfErrX)
   ld E 0
   ld Y DbfErr
   jmp errEXYZ

(code 'jnlErrX)
   ld E 0
   ld Y JnlErr
   jmp errEXYZ

(code 'idErrXL)
   ld E (L I)  # Get symbol
   ld Y IdErr
   jmp errEXYZ

(code 'dbRdErr)
   ld E 0
   ld X 0
   ld Y DbRdErr
   jmp errnoEXY

(code 'dbWrErr)
   ld E 0
   ld X 0
   ld Y DbWrErr
   jmp errnoEXY

(code 'dbSizErr)
   ld E 0
   ld X 0
   ld Y DbSizErr
   jmp errEXYZ

(code 'tellErr)
   ld E 0
   ld X 0
   ld Y TellErr
   jmp errEXYZ

(code 'ipSocketErrX)
   ld E 0
   ld Y IpSocketErr
   jmp errnoEXY

(code 'ipGetsocknameErrX)
   ld E 0
   ld Y IpGetsocknameErr
   jmp errnoEXY

(code 'ipV6onlyErrX)
   ld E 0
   ld Y IpV6onlyErr
   jmp errnoEXY

(code 'ipReuseaddrErrX)
   ld E 0
   ld Y IpReuseaddrErr
   jmp errnoEXY

(code 'ipBindErrX)
   ld E 0
   ld Y IpBindErr
   jmp errnoEXY

(code 'ipListenErrX)
   ld E 0
   ld Y IpListenErr
   jmp errnoEXY

(code 'udpOvflErr)
   ld E 0
   ld X 0
   ld Y UdpOvflErr
   jmp errEXYZ

### Undefined symbol ###
(code 'undefinedCE)
   ld X E
(code 'undefinedCX)
   ld E C
(code 'undefinedEX)
   ld Y UndefErr
   jmp errEXYZ

(code 'dlErrX)
   ld E 0
   cc dlerror()  # Get dynamic loader error message
   ld Y DlErr
   ld Z A
   jmp errEXYZ

### Global return labels ###
(code 'ret 0)
   ret
(code 'retEq 0)
   eq
   ret
(code 'retGt 0)
   gt
   ret
(code 'retLt 0)
   lt
   ret
(code 'retNull 0)
   ld E 0
   ret
(code 'retNil 0)
   ld E Nil
   ret
(code 'retT 0)
   ld E TSym
   ret
(code 'retE_E 0)
   ld E (E)  # Get value or CAR
   ret

# vi:et:ts=3:sw=3
