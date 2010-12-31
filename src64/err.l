# 12oct10abu
# (c) Software Lab. Alexander Burger

# Debug print routine
(code 'dbgS)
   xchg E (S)  # Get return address
   xchg E (S I)  # Get argument, save return
   push C  # Save all registers
   push A
   push F  # And flags
   push (OutFile)  # Save output channel
   ld (OutFile) ((OutFiles) II)  # Set to OutFiles[2] (stderr)
   push (PutB)  # Save 'put'
   ld (PutB) putStdoutB  # Set new
   call printE  # Print argument
   call newline  # and a newline
   pop (PutB)  # Restore 'put'
   pop (OutFile)  # and output channel
   pop F
   pop A
   pop C
   pop E
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
   sub S (+ 240 IV)  # <S> Message buffer, <S 240> outFrame
   cc sprintf(S Y Z)  # Build message
   null X  # Error context?
   ld A Nil
   ldnz A X  # Yes
   ld (Up) A  # Save it
   nul (S)  # Message empty?
   if nz  # No
      push E  # Save reason
      lea E (S I)  # Make transient symbol
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
                  jmp caught
               end
               ld Y (Y CDR)  # Tag list
            loop
         end
         ld C (C)  # Next frame
      loop
      pop E  # Retrieve reason
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
      push E  # Save reason
      ld E X  # Get context
      call printE  # Print context
      call newline
      pop E  # Retrieve reason
   end
   null E  # Reason?
   if nz  # Yes
      call printE  # Print reason
      ld C Dashes  # Print " -- "
      call outStringC
   end
   nul (S)  # Message empty?
   if nz  # No
      call outStringS  # Print message
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
   ld (EnvTask) Nil
   ld (EnvArgs) 0
   ld (EnvNext) 0
   ld (EnvMake) 0
   ld (EnvYoke) 0
   ld (EnvTrace) 0
   ld L 0  # Init link register
   ld S (Stack0)  # stack pointer
   lea A (S 4096)  # and stack limit
   sub A (StkSize)
   ld (StkLimit) A
   ld (Stacks) 0  # Free all stack segments
   jmp restart  # Restart interpreter
: ErrTok asciz "!? "
: Dashes asciz " -- "

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
         cmp (EnvInFrames) (X IV)  # Open input frames?
      while ne  # Yes
         call popInFiles  # Clean up
      loop
      do
         cmp (EnvOutFrames) (X V)  # Open output frames?
      while ne  # Yes
         call popOutFiles  # Clean up
      loop
      do
         cmp (EnvCtlFrames) (X VI)  # Open control frames?
      while ne  # Yes
         call popCtlFiles  # Clean up
      loop
      ld Z (EnvCo7)  # Get coroutines
      do
         cmp Z (X "EnvCo7-EnvCo")  # Skipped?
      while ne  # Yes
         ld C (Stack0)  # Find stack segment
         ld A 1
         do
            sub C (StkSize)  # Next segment
            cmp C (Z II)  # Found 'seg'?
         while ne  # No
            add A A
         loop
         not A  # Clear in segment bitmask
         and (Stacks) A
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
   pop A  # Drop target frame
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
      null (EnvCtlFrames)  # Open control frames?
   while nz  # Yes
      call popCtlFiles  # Clean up
   loop
   ret

### Checks ###
(code 'needSymAX 0)
   num A  # Need symbol
   jnz symErrAX
   sym A
   jz symErrAX
   cmp A Nil  # A < NIL ?
   jc ret  # Yes
   cmp A TSym  # A > T ?
   jncz Ret  # Yes
   ld E A
   jmp protErrEX

(code 'needSymEX 0)
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   cmp E Nil  # E < NIL ?
   jc ret  # Yes
   cmp E TSym  # E > T ?
   jncz Ret  # Yes
   jmp protErrEX

(code 'needVarAX 0)
   num A  # Need variable
   jnz varErrAX
   cmp A Nil  # A < NIL ?
   jc ret  # Yes
   cmp A TSym  # A > T ?
   jncz Ret  # Yes
   ld E A
   jmp protErrEX

(code 'needVarEX 0)
   num E  # Need variable
   jnz varErrEX
   cmp E Nil  # E < NIL ?
   jc ret  # Yes
   cmp E TSym  # E > T ?
   jncz Ret  # Yes
   jmp protErrEX

(code 'checkVarAX 0)
   cmp A Nil  # A < NIL ?
   jc ret  # Yes
   cmp A TSym  # A > T ?
   jncz Ret  # Yes
   ld E A
   jmp protErrEX

(code 'checkVarYX 0)
   cmp Y Nil  # Y < NIL ?
   jc ret  # Yes
   cmp Y TSym  # Y > T ?
   jncz Ret  # Yes
   ld E Y
   jmp protErrEX

(code 'checkVarEX 0)
   cmp E Nil  # E < NIL ?
   jc ret  # Yes
   cmp E TSym  # E > T ?
   jncz Ret  # Yes
(code 'protErrEX)
   ld Y ProtErr
   jmp errEXYZ
: ProtErr asciz "Protected symbol"

### Error messages ###
(code 'stkErr)
   ld E 0
(code 'stkErrE)
   ld X E
(code 'stkErrX)
   ld E 0
(code 'stkErrEX)
   ld Y StkErr
   ld (StkLimit) 0  # Temporarily without stack limit
   jmp errEXYZ
: StkErr asciz "Stack overflow"

(code 'argErrAX)
   ld E A
(code 'argErrEX)
   ld Y ArgErr
   jmp errEXYZ
: ArgErr asciz "Bad argument"

(code 'numErrAX)
   ld E A
(code 'numErrEX)
   ld Y NumErr
   jmp errEXYZ
: NumErr asciz "Number expected"

(code 'cntErrAX)
   ld C A
(code 'cntErrCX)
   ld E C
(code 'cntErrEX)
   ld Y CntErr
   jmp errEXYZ
: CntErr asciz "Small number expected"

(code 'symErrAX)
   ld Y A
(code 'symErrYX)
   ld E Y
(code 'symErrEX)
   ld Y SymErr
   jmp errEXYZ
: SymErr asciz "Symbol expected"

(code 'extErrEX)
   ld Y ExtErr
   jmp errEXYZ
: ExtErr asciz "External symbol expected"

(code 'cellErrAX)
   ld E A
(code 'cellErrEX)
   ld Y CellErr
   jmp errEXYZ
: CellErr asciz "Cell expected"

(code 'atomErrAX)
   ld E A
(code 'atomErrEX)
   ld Y AtomErr
   jmp errEXYZ
: AtomErr asciz "Atom expected"

(code 'lstErrAX)
   ld E A
(code 'lstErrEX)
   ld Y LstErr
   jmp errEXYZ
: LstErr asciz "List expected"

(code 'varErrAX)
   ld E A
(code 'varErrEX)
   ld Y VarErr
   jmp errEXYZ
: VarErr asciz "Variable expected"

(code 'divErrX)
   ld E 0
   ld Y DivErr
   jmp errEXYZ
: DivErr asciz "Div/0"

(code 'renErrEX)
   ld Y RenErr
   jmp errEXYZ
: RenErr asciz "Can't rename"

(code 'makeErrX)
   ld E 0
   ld Y MakeErr
   jmp errEXYZ
: MakeErr asciz "Not making"

(code 'reentErrEX)
   ld Y ReentErr
   jmp errEXYZ
: ReentErr asciz "Reentrant coroutine"

(code 'yieldErrX)
   ld E 0
(code 'yieldErrEX)
   ld Y YieldErr
   jmp errEXYZ
: YieldErr asciz "No coroutine"

(code 'msgErrYX)
   ld A Y
(code 'msgErrAX)
   ld E A
(code 'msgErrEX)
   ld Y MsgErr
   jmp errEXYZ
: MsgErr asciz "Bad message"

(code 'brkErrX)
   ld E 0
   ld Y BrkErr
   jmp errEXYZ
: BrkErr asciz "No Break"

# I/O errors
(code 'openErrEX)
   ld Y OpenErr
   jmp errnoEXY
: OpenErr asciz "Open error: %s"

(code 'closeErrX)
   ld E 0
(code 'closeErrEX)
   ld Y CloseErr
   jmp errnoEXY
: CloseErr asciz "Close error: %s"

(code 'pipeErrX)
   ld E 0
   ld Y PipeErr
   jmp errnoEXY
: PipeErr asciz "Pipe error: %s"

(code 'forkErrX)
   ld E 0
   ld Y ForkErr
   jmp errEXYZ
: ForkErr asciz "Can't fork"

(code 'waitPidErrX)
   ld E 0
   ld Y WaitPidErr
   jmp errnoEXY
: WaitPidErr asciz "wait pid"

(code 'badFdErrEX)
   ld Y BadFdErr
   jmp errEXYZ
: BadFdErr asciz "Bad FD"

(code 'noFdErrX)
   ld E 0
   ld Y NoFdErr
   jmp errEXYZ
: NoFdErr asciz "No current fd"

(code 'eofErr)
   ld E 0
   ld X 0
   ld Y EofErr
   jmp errEXYZ
: EofErr asciz "EOF Overrun"

(code 'suparErrE)
   ld X 0
   ld Y SuparErr
   jmp errEXYZ
: SuparErr asciz "Super parentheses mismatch"

(code 'badInputErrB)
   zxt
   ld Z A
   ld E 0
   ld X 0
   ld Y BadInput
   jmp errEXYZ
: BadInput asciz "Bad input '%c'"

(code 'badDotErrE)
   ld X 0
   ld Y BadDot
   jmp errEXYZ
: BadDot asciz "Bad dotted pair"

(code 'selectErrX)
   ld E 0
   ld Y SelectErr
   jmp errnoEXY
: SelectErr asciz "Select error: %s"

(code 'wrBytesErr)
   ld E 0
   ld X 0
   ld Y WrBytesErr
   jmp errnoEXY
: WrBytesErr asciz "bytes write: %s"

(code 'wrChildErr)
   ld E 0
   ld X 0
   ld Y WrChildErr
   jmp errnoEXY
: WrChildErr asciz "child write: %s"

(code 'wrSyncErrX)
   ld E 0
   ld Y WrSyncErr
   jmp errnoEXY
: WrSyncErr asciz "sync write: %s"

(code 'wrJnlErr)
   ld E 0
   ld X 0
   ld Y WrJnlErr
   jmp errnoEXY
: WrJnlErr asciz "Journal write: %s"

(code 'wrLogErr)
   ld E 0
   ld X 0
   ld Y WrLogErr
   jmp errnoEXY
: WrLogErr asciz "Log write: %s"

(code 'truncErrX)
   ld E 0
   ld Y TruncErr
   jmp errnoEXY
: TruncErr asciz "Log truncate error: %s"

(code 'dbSyncErrX)
   ld E 0
   ld Y DbSyncErr
   jmp errnoEXY
: DbSyncErr asciz "DB fsync error: %s"

(code 'trSyncErrX)
   ld E 0
   ld Y TrSyncErr
   jmp errnoEXY
: TrSyncErr asciz "Transaction fsync error: %s"

(code 'lockErr)
   ld E 0
   ld X 0
   ld Y LockErr
   jmp errnoEXY
: LockErr asciz "File lock: %s"

(code 'dbfErrX)
   ld E 0
   ld Y DbfErr
   jmp errEXYZ
: DbfErr asciz "Bad DB file"

(code 'jnlErrX)
   ld E 0
   ld Y JnlErr
   jmp errEXYZ
: JnlErr asciz "Bad Journal"

(code 'idErrXL)
   ld E (L I)  # Get symbol
   ld Y IdErr
   jmp errEXYZ
: IdErr asciz "Bad ID"

(code 'dbRdErr)
   ld E 0
   ld X 0
   ld Y DbRdErr
   jmp errnoEXY
: DbRdErr asciz "DB read: %s"

(code 'dbWrErr)
   ld E 0
   ld X 0
   ld Y DbWrErr
   jmp errnoEXY
: DbWrErr asciz "DB write: %s"

(code 'dbSizErr)
   ld E 0
   ld X 0
   ld Y DbSizErr
   jmp errEXYZ
: DbSizErr asciz "DB Oversize"

(code 'tellErr)
   ld E 0
   ld X 0
   ld Y TellErr
   jmp errEXYZ
: TellErr asciz "Tell PIPE_BUF"

(code 'ipSocketErrX)
   ld E 0
   ld Y IpSocketErr
   jmp errnoEXY
: IpSocketErr asciz "IP socket error: %s"

(code 'ipGetsocknameErrX)
   ld E 0
   ld Y IpGetsocknameErr
   jmp errnoEXY
: IpGetsocknameErr asciz "IP getsockname error: %s"

(code 'ipSetsockoptErrX)
   ld E 0
   ld Y IpSetsockoptErr
   jmp errnoEXY
: IpSetsockoptErr asciz "IP setsockopt error: %s"

(code 'ipBindErrX)
   ld E 0
   ld Y IpBindErr
   jmp errnoEXY
: IpBindErr asciz "IP bind error: %s"

(code 'ipListenErrX)
   ld E 0
   ld Y IpListenErr
   jmp errnoEXY
: IpListenErr asciz "IP listen error: %s"

(code 'udpOvflErr)
   ld E 0
   ld X 0
   ld Y UdpOvflErr
   jmp errEXYZ
: UdpOvflErr asciz "UDP overflow"

### Undefined symbol ###
(code 'undefinedCE)
   ld X E
(code 'undefinedCX)
   ld E C
(code 'undefinedEX)
   ld Y UndefErr
   jmp errEXYZ
: UndefErr asciz "Undefined"

(code 'dlErrX)
   ld E 0
   cc dlerror()  # Get dynamic loader error message
   ld Y DlErr
   ld Z A
   jmp errEXYZ
: DlErr asciz "[DLL] %s"

### Global return labels ###
(code 'ret 0)
   ret
(code 'retc 0)
   setc
   ret
(code 'retnc 0)
   clrc
   ret
(code 'retz 0)
   setz
   ret
(code 'retnz 0)
   clrz
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
