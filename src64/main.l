# 23dec10abu
# (c) Software Lab. Alexander Burger

### Global return labels ###
(code 'Ret 0)
   ret
(code 'Retc 0)
   setc
   ret
(code 'Retnc 0)
   clrc
   ret
(code 'Retz 0)
   setz
   ret
(code 'Retnz 0)
   clrz
   ret
(code 'RetNil 0)
   ld E Nil
   ret
(code 'RetT 0)
   ld E TSym
   ret
(code 'RetE_E 0)
   ld E (E)  # Get value or CAR
   ret

### Main entry point ###
(code 'main)
   initCode
   # Locate home directory
   ld X (AV)  # Command line vector
   do
      ld Y (X)  # Next command
      null Y  # Any?
   while nz  # Yes
      ld B (Y)  # First byte
      cmp B (char "-")  # Dash?
      if ne  # No
         ld Z Y  # Keep in Y
         ld B (char "/")  # Contains a slash?
         slen C Y  # String length in C
         memb Z C
         if eq  # Yes
            do
               memb Z C  # Find last one
            until ne
            ld A Z
            sub A 2  # "./lib.l"?
            cmp A Y  # Last slash is second byte?
            jne 10  # No
            ld B (Y)  # First byte is "."?
            cmp B (char ".")
            if ne  # No
10             sub Z Y  # Length
               ld C Z  # Keep in Z
               inc C  # Space for null byte
               call allocC_A
               ld (Home) A  # Set 'Home'
               movn (A) (Y) Z  # Copy path including "/"
               add Z (Home)  # Pointer to null byte
               set (Z) 0  # Clear it
            end
         end
         break T
      end
      add X I
   loop
   # Initialize globals
   cc getpid()  # PID in A
   shl A 4  # Make short number
   or A CNT
   ld (Pid) A
   ld (Stack0) S  # Save top level stack pointer
   lea (StkLimit) (S (- 4096 STACK))  # Set stack limit
   ld L 0  # Init link register
   call heapAlloc  # Allocate initial heap
   ld E Nil  # Init internal symbols
   lea Z (E IV)  # Skip padding
   do
      ld X (E TAIL)  # Get name
      ld Y Intern
      call internEXY_FE  # Store to internals
      ld E Z
      cnt (Z TAIL)  # Short name?
      if nz  # Yes
         add Z II  # Next symbol
      else
         add Z IV
      end
      cmp E SymTabEnd
   until gt
   ld (Get_A) getStdin_A
   ld A 0  # Standard input
   call initInFileA_A  # Create input file
   ld (InFile) A  # Set to default InFile
   ld (PutB) putStdoutB
   ld A 2  # Standard error
   call initOutFileA_A  # Create output file
   ld A 1  # Standard output
   call initOutFileA_A  # Create output file
   ld (OutFile) A  # Set to default OutFile
   cc tcgetattr(0 OrgTermio)  # Save terminal I/O
   not B
   ld (Tio) B  # and flag
   sub S SIGSET_T  # Create signal mask structure
   cc sigfillset(S)  # Set all signals to unblocked
   cc sigprocmask(SIG_UNBLOCK S 0)
   add S SIGSET_T  # Drop mask structure
   ld E sig  # Install standard signal handler
   ld C SIGHUP
   call iSignalCE  # for SIGHUP
   ld C SIGUSR1
   call iSignalCE  # for SIGUSR1
   ld C SIGUSR2
   call iSignalCE  # for SIGUSR2
   ld C SIGALRM
   call iSignalCE  # for SIGALRM
   ld C SIGTERM
   call iSignalCE  # for SIGTERM
   ld C SIGIO
   call iSignalCE  # for SIGIO
   ld E sigTerm  # Install terminating signal handler for SIGINT
   ld C SIGINT
   call iSignalCE
   ld E sigChld  # Install child signal handler for SIGCHLD
   ld C SIGCHLD
   call iSignalCE
   cc signal(SIGCHLD sigChld)
   cc signal(SIGPIPE SIG_IGN)  # Ignore signals
   cc signal(SIGTTIN SIG_IGN)
   cc signal(SIGTTOU SIG_IGN)
   cc gettimeofday(Buf 0)  # Get time
   ld A (Buf)  # tv_sec
   mul 1000000  # Convert to microseconds
   add A (Buf I)  # tv_usec
   ld (USec) A  # Store
   ld X 0  # Runtime expression
   call loadAllX_E  # Load arguments
   ld E sig  # Install standard signal handler for SIGINT
   ld C SIGINT
   set (Repl) 1  # Set REPL flag
   call iSignalCE
(code 'restart)
   ld B (char ":")  # Prompt
   ld E Nil  # REPL
   ld X 0  # Runtime expression
   call loadBEX_E
   ld E 0
# Exit
(code 'byeE)
   nul (InBye)  # Re-entered?
   if z  # No
      set (InBye) 1
      push E  # Save exit code
      ld C 0  # Top frame
      call unwindC_Z  # Unwind
      ld E (Bye)  # Run exit expression(s)
      call execE
      pop E  # Restore exit code
   end
   call flushAll  # Flush all output channels
(code 'finishE)
   call setCooked  # Set terminal to cooked mode
   cc exit(E)

# Load all remaining arguments
(code 'loadAllX_E)
   do
      ld E ((AV))  # Command line vector
      null E  # Next string pointer?
      jz retNil  # No
      ld B (E)  # Single-dash argument?
      cmp B (char "-")
      if eq
         nul (E 1)
         jz retNil  # Yes
      end
      add (AV) I  # Increment vector pointer
      call mkStrE_E  # Make transient symbol
      ld B 0  # Prompt
      call loadBEX_E
   loop

# Give up
(code 'giveupX)
   ld A (Pid)  # Get PID
   shr A 4
   cc fprintf((stderr) Giveup A X)
   ld E 1
   jmp finishE
: Giveup asciz "%d %s\\n"

(code 'execErrS)
   cc fprintf((stderr) ExecErr (S))
   ld E 127
   jmp finishE
: ExecErr asciz "%s: Can't exec\\n"

# Install interrupting signal
(code 'iSignalCE)
   sub S (* 2 SIGACTION)  # 'sigaction' and 'oldact'
   ld (S SA_HANDLER) E  # Function pointer
   cc sigemptyset(&(S SA_MASK))
   ld (S SA_FLAGS) 0
   cc sigaction(C S &(S SIGACTION))  # Install handler
   add S (* 2 SIGACTION)
   ret

# Allocate memory
(code 'allocC_A 0)
   cc malloc(C)  # Allocate memory of size C
   null A  # OK?
   jz NoMemory  # No
   ret
(code 'allocAE_A 0)
   cc realloc(A E)  # Reallocate pointer in A to size E
   null A  # OK?
   jnz Ret  # Return
: NoMemory
   ld X Alloc  # No memory
   jmp giveupX
: Alloc asciz "No memory"


# Allocate cell heap
(code 'heapAlloc 0)  # AEX
   ld A 0  # NULL pointer
   ld E (+ HEAP I)  # Heap allocation size
   call allocAE_A
   ld E A  # Heap pointer
   ld (A HEAP) (Heaps)  # Set heap link
   ld (Heaps) A
   add A (- HEAP 16)  # A on last cell in chunk
   ld X (Avail)  # Initialize free list
   do
      ld (A) X  # Link avail
      ld X A
      sub A 16
      cmp A E  # Done?
   until lt  # Yes
   ld (Avail) X  # Set new Avail
   ret

# Signal handler
(code 'sighandler0)
   push E
   ld E 0
   call sighandlerE
   pop E
   ret

(code 'sighandlerX)
   push E
   ld E X
   call sighandlerE
   pop E
   ret

(code 'sighandlerE)
   null (EnvProtect)  # Protected?
   if z  # No
      ld (EnvProtect) 1
      push A
      push C
      do
         null (Signal (* I SIGIO))  # Test signals
         if nz
            dec (Signal)  # Decrement signal counters
            dec (Signal (* I SIGIO))
            ld E (Sigio)  # Run 'Sigio'
            call execE
         else
            null (Signal (* I SIGUSR1))
            if nz
               dec (Signal)
               dec (Signal (* I SIGUSR1))
               ld E (Sig1)  # Run 'Sig1'
               call execE
            else
               null (Signal (* I SIGUSR2))
               if nz
                  dec (Signal)
                  dec (Signal (* I SIGUSR2))
                  ld E (Sig2)  # Run 'Sig2'
                  call execE
               else
                  null (Signal (* I SIGALRM))
                  if nz
                     dec (Signal)
                     dec (Signal (* I SIGALRM))
                     ld E (Alarm)  # Run 'Alarm'
                     call execE
                  else
                     null (Signal (* I SIGINT))
                     if nz
                        dec (Signal)
                        dec (Signal (* I SIGINT))
                        nul (PRepl)  # Child of REPL process?
                        if z  # No
                           null E  # Runtime expression?
                           ldz E Nil  # No: Default to NIL
                           call brkLoadE_E  # Enter debug breakpoint
                        end
                     else
                        null (Signal (* I SIGHUP))
                        if nz
                           dec (Signal)
                           dec (Signal (* I SIGHUP))
                           ld E (Hup)  # Run 'Hup'
                           call execE
                        else
                           null (Signal (* I SIGTERM))
                           if nz
                              push X
                              ld X (Child)  # Iterate children
                              ld C (Children)  # Count
                              ld E 0  # Flag
                              do
                                 sub C VI  # More?
                              while ge  # Yes
                                 null (X)  # 'pid'?
                                 if nz  # Yes
                                    cc kill((X) SIGTERM)  # Try to terminate
                                    nul4  # OK?
                                    ldz E 1  # Yes: Set flag
                                 end
                                 add X VI  # Increment by sizeof(child)
                              loop
                              pop X
                              null E  # Still terminated any child?
                              if z  # No
                                 ld (Signal) 0
                                 ld E 0  # Exit OK
                                 jmp byeE
                              end
                           end
                        end
                     end
                  end
               end
            end
         end
         null (Signal)  # More signals?
      until z  # No
      pop C
      pop A
      ld (EnvProtect) 0
   end
   ret

(code 'sig)
   begin 1  # Signal number in A
   null (TtyPid)  # Kill terminal process?
   if nz  # Yes
      cc kill((TtyPid) A)
   else
      shl A 3  # Signal index
      inc (A Signal)
      inc (Signal)
   end
   return 1
   ret

(code 'sigTerm)
   begin 0  # Ignore signal number
   null (TtyPid)  # Kill terminal process?
   if nz  # Yes
      cc kill((TtyPid) SIGTERM)
   else
      inc (Signal (* I SIGTERM))
      inc (Signal)
   end
   return 0
   ret

(code 'sigChld)
   begin 0  # Ignore signal number
   call errno_A  # Save 'errno'
   push A
   sub S I  # 'stat'
   do
      cc waitpid(0 S WNOHANG)  # Wait for child
      nul4  # Pid greater zero?
   while nsz  # Yes
      ld C A  # Keep Pid
      call wifsignaledS_F  # WIFSIGNALED(S)?
      if nz  # Yes
         call wtermsigS_A  # Get signal number WTERMSIG(S)
         cc fprintf((stderr) PidSigMsg C A)
      end
   loop
   add S I  # Drop 'stat'
   pop C  # Restore 'errno'
   call errnoC
   return 0
   ret
: PidSigMsg asciz "%d SIG-%d\\n"

(code 'tcSetC)
   null (Termio)  # In raw mode?
   if nz  # Yes
      do
         cc tcsetattr(0 TCSADRAIN C)  # Set terminal I/O
         nul4  # OK?
      while nz  # No
         call errno_A
         cmp A EINTR  # Interrupted?
      until ne  # No
   end
   ret

(code 'sigTermStop)
   begin 0  # Ignore signal number
   ld C OrgTermio  # Set original terminal I/O
   call tcSetC
   sub S SIGSET_T  # Create mask structure
   cc sigemptyset(S)  # Init to empty signal set
   cc sigaddset(S SIGTSTP)  # Add stop signal
   cc sigprocmask(SIG_UNBLOCK S 0)  # Remove blocked signals
   add S SIGSET_T  # Drop mask structure
   cc signal(SIGTSTP SIG_DFL)
   cc raise(SIGTSTP)
   cc signal(SIGTSTP sigTermStop)
   ld C (Termio)
   call tcSetC
   return 0
   ret

(code 'setRaw 0)
   nul (Tio)  # Terminal I/O?
   if nz  # Yes
      null (Termio)  # Already in raw mode?
      if z  # No
         ld C TERMIOS  # Allocate space for termio structure
         call allocC_A
         ld (Termio) A  # Save it
         ld C A  # Pointer in C
         movn (C) (OrgTermio) TERMIOS  # Copy original termio structure
         ld A 0  # Clear c_iflag
         st4 (C C_IFLAG)
         ld A ISIG  # ISIG in c_lflag
         st4 (C C_LFLAG)
         set (C (+ C_CC VMIN)) 1
         set (C (+ C_CC VTIME)) 0
         call tcSetC  # Set terminal I/O
         cc signal(SIGTSTP SIG_IGN)  # Ignore stop signals
         cmp A SIG_DFL  # Not set yet?
         if eq  # Yes
            cc signal(SIGTSTP sigTermStop)  # Handle stop signals
         end
      end
   end
   ret

(code 'setCooked 0)
   ld C OrgTermio  # Set original terminal I/O
   call tcSetC
   cc free((Termio))  # Clear Termio
   ld (Termio) 0
   ret

#  (raw ['flg]) -> flg
(code 'doRaw 2)
   ld E (E CDR)  # Arg?
   atom E
   if nz  # No
      null (Termio)  # Return termio flag
      jnz retT
      ld E Nil
      ret
   end
   ld E (E)  # Evaluate arg
   eval
   cmp E Nil  # NIL?
   if eq  # Yes
      call setCooked  # Set terminal to cooked mode
      ld E Nil
      ret
   end
   call setRaw  # Set terminal to raw mode
   ld E TSym
   ret

# (alarm 'cnt . prg) -> cnt
(code 'doAlarm 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   call evCntXY_FE  # Get 'cnt'
   cc alarm(E)  # Set alarm
   ld (Alarm) (Y CDR)
   ld E A  # Get old alarm
   shl E 4  # Make short number
   or E CNT
   pop Y
   pop X
   ret

# (sigio ['cnt [. prg]]) -> cnt | prg
(code 'doSigio 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   atom Y  # Any?
   if nz  # No
      ld E (Sigio)  # Return current handler
   else
      call evCntXY_FE  # Get fd
      ld Y (Y CDR)  # Handler 'prg'
      ld (Sigio) Y  # Save in 'Sigio'
      atom Y  # Any?
      if z  # Yes
         ld A (Pid)  # Get process ID
         shr A 4  # Normalize
         cc fcntl(E F_SETOWN A)  # Receive SIGIO events
         cc fcntl(E F_GETFL 0)  # Get file status flags
         or A (| O_NONBLOCK O_ASYNC)
         cc fcntl(E F_SETFL A)  # Set file status flags
      end
      shl E 4  # Return fd
      or E CNT
   end
   pop Y
   pop X
   ret

# (protect . prg) -> any
(code 'doProtect 2)
   push X
   ld X (E CDR)  # Get 'prg'
   inc (EnvProtect)
   prog X  # Run 'prg'
   dec (EnvProtect)
   pop X
   ret

# (heap 'flg) -> cnt
(code 'doHeap 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   cmp E Nil  # NIL?
   if eq  # Yes
      ld E ZERO  # Init count
      ld A (Heaps)  # Get heap list
      do
         add E (hex "10")  # Increment count
         ld A (A HEAP)  # Get link
         null A  # Done?
      until z  # Yes
      ret
   end
   ld A 0  # Init count
   ld C (Avail)  # Get avail list
   do
      null C  # Any?
   while nz  # Yes
      inc A  # Increment count
      ld C (C)  # Follow link
   loop
   div CELLS  # (C is zero)
   ld E A
   shl E 4  # Make short number
   or E CNT
   ret

# (stack ['cnt]) -> cnt | (.. sym . cnt)
(code 'doStack 2)
   push X
   ld X E
   ld E (E CDR)  # Arg?
   atom E
   if z  # Yes
      null (Stacks)  # Stack segments allocated?
      if z  # No
         ld E (E)  # Eval 'cnt'
         call evCntEX_FE
         shl E 20  # [MB]
         ld (StkSize) E  # Set new stack size
         lea A ((Stack0) 4096)  # and stack limit
         sub A E
         ld (StkLimit) A
         shr E 16  # Make short number [MB]
         or E CNT
         pop X
         ret
      end
   end
   ld E (StkSize)  # Return current stack size
   shr E 16  # Make short number [MB]
   or E CNT
   ld X (Stack0)  # Collect coroutines
   ld C (Stacks)  # Segment bitmask
   do
      sub X (StkSize)  # Next segment
      shr C 1  # In use?
      if c  # Yes
         call consE_A  # Cons 'tag'
         ld (A) (X -I)
         ld (A CDR) E
         ld E A
         continue T
      end
   until z
   pop X
   ret

# (adr 'var) -> num
# (adr 'num) -> var
(code 'doAdr 2)
   ld E ((E CDR))  # Eval arg
   eval
   num E  # 'num' argument?
   if nz  # Yes
      off E CNT  # Make 'var'
      ret
   end
   or E CNT  # Make 'num'
   ret

# (env ['lst] | ['sym 'val] ..) -> lst
(code 'doEnv 2)
   push X
   ld X (E CDR)
   link
   push Nil  # <L II> Safe
   push Nil  # <L I> Result
   link
   atom X  # Args?
   if nz  # No
      push Y
      ld Y (EnvBind)  # Bindings
      do
         null Y  # Bindings?
      while nz  # Yes
         ld C (Y)  # End of bindings
         null (Y -I)  # Env swap zero?
         if z  # Yes
            add Y I  # Y on bindings
            do
               ld E (Y)  # Next symbol
               ld X (L I)  # Get result
               do
                  atom X  # More result items?
                  if nz  # No
                     call cons_A  # Cons symbol and its value
                     ld (A) E
                     ld (A CDR) (E)
                     call consA_X  # Cons to result
                     ld (X) A
                     ld (X CDR) (L I)
                     ld (L I) X
                     break T
                  end
                  cmp E ((X))  # Symbol already in result?
               while ne  # No
                  ld X (X CDR)  # Next result item
               loop
               add Y II  # Skip value
               cmp Y C  # More?
            until eq  # No
         end
         ld Y (C I)  # Bind link
      loop
      pop Y
   else
      do
         ld E (X)  # Eval 'lst' or 'sym'
         eval
         ld (L II) E  # Save
         atom E  # 'lst'?
         if z  # Yes
            do
               ld A (E)  # Already a pair?
               atom A
               if nz  # No
                  call cons_A  # Cons symbol and its value
                  ld (A) (E)
                  ld (A CDR) ((E))
               end
               call consA_C  # Cons to result
               ld (C) A
               ld (C CDR) (L I)
               ld (L I) C
               ld E (E CDR)  # Next item in 'lst'
               atom E  # Any?
            until nz  # No
         else
            cmp E Nil  # NIL?
            if ne  # No
               ld X (X CDR)  # Next arg
               ld E (X)  # Eval
               eval
               call consE_A  # Cons symbol and value
               ld (A) (L II)  # Safe
               ld (A CDR) E
               call consA_C  # Cons to result
               ld (C) A
               ld (C CDR) (L I)
               ld (L I) C
            end
         end
         ld X (X CDR)  # More args?
         atom X
      until nz  # No
   end
   ld E (L I)  # Get result
   drop
   pop X
   ret

# (up [cnt] sym ['val]) -> any
(code 'doUp 2)
   push X
   push Y
   push Z
   ld C 1  # Count
   ld E (E CDR)  # First arg
   ld X (E)  # Get 'sym'
   cnt X  # 'cnt'?
   if nz  # Yes
      ld C X  # Count
      shr C 4  # Normalize
      ld E (E CDR)  # Skip arg
      ld X (E)  # 'sym'
   end
   ld E (E CDR)  # Last arg
   ld Y (EnvBind)  # Bindings
   ld Z X  # Value pointer
   do
      null Y  # Bindings?
   while nz  # Yes
      ld A (Y)  # End of bindings in A
      add Y I
      do
         cmp X (Y)  # Found symbol?
         if eq  # Yes
            lea Z (Y I)  # Point to saved value
            dec C  # Decrement count
            jz 10  # Done
         end
         add Y II
         cmp Y A  # More?
      until eq  # No
      ld Y (A I)  # Bind link
   loop
10 atom E  # 'val' arg?
   if nz  # No
      ld E (Z)  # Get value
   else
      ld E (E)  # Eval last arg
      eval
      ld (Z) E  # Store value
   end
   pop Z
   pop Y
   pop X
   ret

(code 'circE_YF)
   ld Y E  # Keep list in Y
   do
      or (E) 1  # Mark
      ld E (E CDR)  # Normal list?
      atom E
      if nz  # Yes
         do
            off (Y) 1  # Unmark
            ld Y (Y CDR)
            atom Y  # Done?
         until nz  # Yes
         ret  # 'nz' - No circularity found
      end
      test (E) 1  # Detected circularity?
      if nz  # Yes
         do
            cmp Y E  # Skip non-circular part
         while ne
            off (Y) 1  # Unmark
            ld Y (Y CDR)
         loop
         do
            off (Y) 1  # Unmark circular part
            ld Y (Y CDR)
            cmp Y E  # Done?
         until eq  # Yes
         ret  # 'z' - Circularity in Y
      end
   loop

### Comparisons ###
(code 'equalAE_F 0)
   cmp A E  # Pointer-equal?
   jz ret  # Yes: 'eq'
   cnt A  # A short?
   jnz ret  # Yes: 'ne'
   big A  # A big?
   if nz  # Yes
      big E  # E also big?
      jz Retnz  # No: 'ne'
      test A SIGN  # A negative?
      if nz  # Yes
         test E SIGN  # E also negative?
         jz Retnz  # No: 'ne'
         off A SIGN  # Make both positive
         off E SIGN
      end
      do
         cmp (A DIG) (E DIG)  # Digits equal?
      while eq  # Yes
         ld A (A BIG)  # Else next digits
         ld E (E BIG)
         cmp A E  # Pointer-equal?
      while ne  # No
         cnt A  # A short?
      while z  # No
         cnt E  # E short?
      until nz  # Yes
      ret
   end
   sym A  # A symbolic?
   if nz  # Yes
      num E  # E also symbolic?
      jnz Retnz
      sym E
      jz Retnz  # No: 'ne'
      ld A (A TAIL)
      call nameA_A  # Get name of A
      zero A  # Any?
      jeq retnz  # No: 'ne'
      ld E (E TAIL)
      call nameE_E  # Get name of E
      zero E  # Any?
      jeq retnz  # No: 'ne'
      jmp equalAE_F
   end
   atom E  # E atomic?
   jnz ret  # Yes: 'ne'
   push X
   push Y
   ld X A  # Keep list heads
   ld Y E
   do
      push A  # Save lists
      push E
      cmp S (StkLimit)  # Stack check
      jlt stkErr
      ld A (A)  # Recurse on CARs
      ld E (E)
      call equalAE_F  # Equal?
      pop E  # Retrieve lists
      pop A
      break ne  # No: 'ne'
      atom (A CDR)  # A's CDR atomic?
      if nz  # Yes
         push A  # Save lists
         push E
         ld A (A CDR)  # Recurse on CDRs
         ld E (E CDR)
         call equalAE_F  # Compare with E's CDR
         pop E  # Retrieve lists
         pop A
         break T
      end
      atom (E CDR)  # E's CDR atomic?
      break nz  # Yes: 'ne'
      or (A) 1  # Mark
      ld A (A CDR)
      or (E) 1
      ld E (E CDR)
      test (A) 1  # Detected circularity?
      jnz 10  # Yes
      test (E) 1
      if nz
10       do
            cmp X A  # Skip non-circular parts
            if eq  # Done?
               cmp Y E  # Set result
               break T
            end
            cmp Y E
            if eq
               clrz  # Result "No"
               break T
            end
            off (X) 1  # Unmark
            ld X (X CDR)
            off (Y) 1
            ld Y (Y CDR)
         loop
         push F  # Save result
         do
            off (X) 1  # Unmark circular part
            ld X (X CDR)
            off (Y) 1
            ld Y (Y CDR)
            cmp X A
         until eq
         pop F  # Get result
         pop Y
         pop X
         ret
      end
   loop
   push F  # Save result
   do
      cmp X A  # Skip non-circular part
   while ne
      off (X) 1  # Unmark
      ld X (X CDR)
      off (Y) 1
      ld Y (Y CDR)
   loop
   pop F  # Get result
   pop Y
   pop X
   ret

(code 'compareAE_F 0)  # C
   cmp A E  # Pointer-equal?
   jz ret  # Yes
   cmp A Nil
   if eq  # [NIL E]
10    or B B  # nz
20    setc  # lt
      ret
   end
   cmp A TSym
   if eq  # [T E]
30    or B B  # nz
40    clrc  # gt
      ret
   end
   num A  # Number?
   if nz  # Yes
      num E  # Both?
      jnz cmpNumAE_F  # [<num> <num>]
      cmp E Nil
      jz 30  # [<num> NIL]
      setc  # lt
      ret
   end
   sym A
   if nz  # [<sym> ..]
      num E
      jnz 40  # [<sym> <num>]
      cmp E Nil
      jz 30  # [<sym> NIL]
      atom E
      jz 10  # [<sym> <cell>]
      cmp E TSym
      jz 10  # [<sym> T]
      push X  # [<sym> <sym>]
      ld X (A TAIL)
      call nameX_X  # Get A's name in X
      zero X  # Any?
      if eq  # No
         ld E (E TAIL)
         call nameE_E  # Second name in E
         zero E  # Any?
         if eq  # No
            rol B 4  # Random bit from A (...x1000) into carry (non-zero)
         else
            setc  # lt
         end
         pop X
         ret
      end
      ld E (E TAIL)
      call nameE_E  # Get E's name in E
      zero E  # Any?
      if eq  # No
50       or B B  # nz
60       clrc  # gt
70       pop X
         ret
      end
      do
         cnt X  # Get next digit from X into A
         if nz
            ld A X  # Short
            shr A 4  # Normalize
            ld X 0
         else
            ld A (X DIG)  # Get next digit
            ld X (X BIG)
         end
         cnt E  # Get next digit from E into C
         if nz
            ld C E  # Short
            shr C 4  # Normalize
            ld E 0
         else
            ld C (E DIG)  # Get next digit
            ld E (E BIG)
         end
         do
            cmp B C  # Bytes equal?
            jnz 70  # No: lt or gt
            shr A 8  # Next byte in A?
            if z  # No
               shr C 8  # Next byte in C?
               if nz  # Yes
                  setc  # lt
                  pop X
                  ret
               end
               null X  # X done?
               if z  # Yes
                  null E  # E also done?
                  jz 70  # Yes: eq
                  setc  # lt
                  pop X
                  ret
               end
               null E  # E done?
               jz 50  # Yes: gt
               break T
            end
            shr C 8  # Next byte in C?
            jz 50  # No: gt
         loop
      loop
   end
   atom E
   if nz  # [<cell> <sym>]
      cmp E TSym
      if eq  # [<cell> T]
         or B B  # nz
         setc  # lt
         ret
      end
      clrc  # gt
      ret
   end
   push X  # [<cell> <cell>]
   push Y
   ld X A  # Keep originals
   ld Y E
   do
      push A  # Recurse on CAR
      push E
      ld A (A)
      ld E (E)
      cmp S (StkLimit)  # Stack check
      jlt stkErr
      call compareAE_F  # Same?
      pop E
      pop A
   while eq  # Yes
      ld A (A CDR)  # Next elements
      ld E (E CDR)
      atom A  # End of A?
      if nz  # Yes
         cmp S (StkLimit)  # Stack check
         jlt stkErr
         call compareAE_F  # Compare CDRs
         break T
      end
      atom E  # End of E?
      if nz  # Yes
         cmp E TSym
         if ne
            clrc  # gt [<cell> <atom>]
            break T
         end
         or B B  # nz [<cell> T]
         setc  # lt
         break T
      end
      cmp A X  # Circular list?
      if eq
         cmp E Y
         break eq  # Yes
      end
   loop
   pop Y
   pop X
   ret  # F

(code 'memberXY_FY 0)
   ld C Y  # Keep head in C
   do
      atom Y  # List?
   while z  # Yes
      ld A X
      ld E (Y)
      call equalAE_F  # Member?
      jeq ret  # Return list
      ld Y (Y CDR)  # Next item
      cmp C Y  # Hit head?
      jeq retnz  # Yes
   loop
   ld A X
   ld E Y
   jmp equalAE_F  # Same atoms?

# (quit ['any ['any]])
(code 'doQuit 2)
   ld X (E CDR)  # Args
   call evSymX_E  # Evaluate to a symbol
   call bufStringE_SZ  # Write to stack buffer
   ld X (X CDR)  # Next arg?
   atom X
   ldnz E 0  # No
   if z  # Yes
      ld E (X)
      eval  # Eval
   end
   ld X 0  # No context
   ld Y QuitMsg  # Format string
   ld Z S  # Buffer pointer
   jmp errEXYZ  # Jump to error handler
: QuitMsg asciz "%s"

### Evaluation ###
# Apply EXPR in C to CDR of E
(code 'evExprCE_E 0)
   push X
   push Y
   push Z
   cmp S (StkLimit)  # Stack check
   jlt stkErrE
   ld X (E CDR)  # Get CDR
   ld Y (C)  # Parameter list in Y
   ld Z (C CDR)  # Body in Z
   push (EnvBind)  # Build bind frame
   link
   push (At)  # Bind At
   push At
   do
      atom Y  # More evaluating parameters?
   while z  # Yes
      ld E (X)  # Get next argument
      ld X (X CDR)
      eval+  # Evaluate and save
      push E
      push (Y)  # Save symbol
      ld Y (Y CDR)
   loop
   cmp Y Nil  # NIL-terminated parameter list?
   if eq  # Yes: Bind parameter symbols
      ld Y S  # Y on bindings
      do
         ld X (Y)  # Symbol in X
         add Y I
         ld A (X)  # Old value in A
         ld (X) (Y)  # Set new value
         ld (Y) A  # Save old value
         add Y I
         cmp Y L  # End?
      until eq  # Yes
      link
      ld (EnvBind) L  # Close bind frame
      push 0  # Init env swap
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
      pop Z
      pop Y
      pop X
      ret
   end
   # Non-NIL parameter
   cmp Y At  # '@'?
   if ne  # No
      push (Y)  # Save last parameter's old value
      push Y  # and the last parameter
      ld (Y) X  # Set to unevaluated argument list
      lea Y (S II)  # Y on evaluated bindings
      do
         ld X (Y)  # Symbol in X
         add Y I
         ld A (X)  # Old value in A
         ld (X) (Y)  # Set new value
         ld (Y) A  # Save old value
         add Y I
         cmp Y L  # End?
      until eq  # Yes
      link
      ld (EnvBind) L  # Close bind frame
      push 0  # Init env swap
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
      pop Z
      pop Y
      pop X
      ret
   end
   # Evaluated argument list
   link  # Close bind frame
   ld Y L  # Y on frame
   push 0  # Init env swap
   push (EnvNext)   # Save current 'next'
   push (EnvArgs)  # and varArgs base
   atom X  # Any args?
   if nz  # No
      ld (EnvArgs) 0
      ld (EnvNext) 0
   else
      link  # Build varArgs frame
      do
         ld E (X)  # Get next argument
         eval+  # Evaluate and save
         push E
         ld X (X CDR)
         atom X  # More args?
      until nz  # No
      ld (EnvArgs) S  # Set new varArgs base
      ld (EnvNext) L  # Set new 'next'
      link  # Close varArgs frame
   end
   ld (EnvBind) Y  # Close bind frame
   ld C (Y)  # End of bindings in C
   add Y I
   do
      ld X (Y)  # Symbol in X
      add Y I
      ld A (X)  # Old value in A
      ld (X) (Y)  # Set new value
      ld (Y) A  # Save old value
      add Y I
      cmp Y C  # End?
   until eq  # Yes
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
   pop Z
   pop Y
   pop X
   ret

# Evaluate a list
(code 'evListE_E 0)
   ld C (E)  # Get CAR in C
   num C  # Number?
   jnz ret  # Yes: Return list
   sym C  # Symbol?
   if nz  # Yes
10    do  # C is a symbol
         null (Signal)  # Signal?
         if nz  # Yes
            push E
            call sighandlerE
            pop E
         end
         ld A (C)  # Get VAL
         cnt A  # Short number?
         jnz (A)  # Yes: Eval SUBR
         big A  # Undefined if bignum
         jnz undefinedCE
         cmp A (A)  # Auto-symbol?
         if ne  # No
            ld C A
            atom C  # Symbol?
            jz evExprCE_E  # No: Apply EXPR
         else
            call sharedLibC_FA  # Try dynamic load
            jnz (A)  # Eval SUBR
            jmp undefinedCE
         end
      loop
   end
   push E
   ld E C
   cmp S (StkLimit)  # Stack check
   jlt stkErr
   call evListE_E
   ld C E
   pop E
   cnt C  # Short number?
   jnz (C)  # Yes: Eval SUBR
   big C  # Undefined if bignum
   jnz undefinedCE
   link
   push C  # Save function
   link
   atom C  # Symbol?
   if z
      call evExprCE_E  # No: Apply EXPR
   else
      call 10
   end
   drop
   ret

(code 'sharedLibC_FA)
   push C
   push E
   push Y
   push Z
   ld E C  # Get symbol in E
   call bufStringE_SZ  # Write to stack buffer
   ld C 0
   ld Y S  # Search for colon and slash
   do
      ld B (Y)  # Next byte
      or B B  # End of string?
      jz 90  # Yes
      cmp B (char ":")  # Colon?
   while ne  # No
      cmp B (char "/")  # Slash?
      if eq  # Yes
         ld C Y  # Keep pointer to slash
      end
      inc Y  # Increment buffer pointer
   loop
   cmp Y Z  # At start of buffer?
   jz 90  # Yes
   nul (Y 1)  # At end of buffer?
   jz 90  # Yes
   set (Y) 0  # Replace colon with null byte
   inc Y  # Point to token
   null C  # Contained '/'?
   ld C S  # Pointer to lib name
   if z  # No
      sub S 8  # Extend buffer
      sub C 4  # Prepend "lib/"
      set (C 3) (char "/")
      set (C 2) (char "b")
      set (C 1) (char "i")
      set (C) (char "l")
      ld A (Home)  # Home directory?
      null A
      if nz  # Yes
         do
            inc A  # Find end
            nul (A)
         until z
         sub A (Home)  # Calculate length
         sub C A  # Adjust buffer
         ld S C
         off S 7
         movn (C) ((Home)) A  # Insert home path
      end
   end
   cc dlopen(C (| RTLD_LAZY RTLD_GLOBAL))  # Open dynamic library
   null A  # OK?
   if nz  # Yes
      cc dlsym(A Y)  # Find dynamic symbol
      null A  # OK?
      if nz  # Yes
         ld (E) A  # 'nz' - Set function definition
      end
   end
90 ld S Z  # Drop buffer
   pop Z
   pop Y
   pop E
   pop C
   ret

# (errno) -> cnt
(code 'doErrno 2)
   call errno_A  # Get 'errno'
   ld E A
   shl E 4  # Make short number
   or E CNT
   ret

# (native 'cnt1|sym1 'cnt2|sym2 'sym|lst 'any ..) -> any
(code 'doNative 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval library 'cnt1|sym1'
   eval
   cnt E  # Library handle?
   if nz  # Yes
      shr E 4  # Normalize
      push E  # <S> Library handle
   else
      big E  # Library handle?
      if nz  # Yes
         push (E DIG)  # <S> Library handle
      else
         call needSymEX  # Check symbol
         ld A (E TAIL)  # Check for main program library
         call nameA_A  # Get name
         cmp A (| CNT (>> -4 (char "@")))  # "@"?
         if eq  # Yes
            cc dlopen(0 (| RTLD_LAZY RTLD_GLOBAL))  # Open main library
         else
            call pathStringE_SZ  # Write to stack buffer
            cc dlopen(S (| RTLD_LAZY RTLD_GLOBAL))  # Open dynamic library
            ld S Z  # Drop buffer
         end
         null A  # OK?
         jz dlErrX  # No
         push A  # <S> Library handle
         test A (hex "F000000000000000")  # Fit in short number?
         if z  # Yes
            shl A 4  # Make short number
            or A CNT
         else
            call boxNumA_A  # Make bignum
         end
         ld (E) A  # Set value of 'sym1'
      end
   end
   ld Y (Y CDR)  # Second arg
   ld E (Y)  # Eval function 'cnt2|sym2'
   eval
   ld Z S  # Stack marker in Z
   cnt E  # Function pointer?
   if nz  # Yes
      shr E 4  # Normalize
      ld (S) E  # <Z> Function pointer
   else
      big E  # Function pointer??
      if nz  # Yes
         ld (S) (E DIG)  # <Z> Function pointer
      else
         call needSymEX  # Check symbol
         call bufStringE_SZ  # Write to stack buffer
         cc dlsym((Z) S)  # Find dynamic symbol
         null A  # OK?
         jz dlErrX  # No
         ld S Z  # Drop buffer
         ld (S) A  # <Z> Function pointer
         test A (hex "F000000000000000")  # Fit in short number?
         if z  # Yes
            shl A 4  # Make short number
            or A CNT
         else
            call boxNumA_A  # Make bignum
         end
         ld (E) A  # Set value
      end
   end
   ld Y (Y CDR)  # Third arg
   ld E (Y)  # Eval result specification
   eval
   link
   push E  # <Z -II> Result specification
   do
      ld Y (Y CDR)  # Arguments?
      atom Y
   while z  # Yes
      ld E (Y)  # Eval argument specification
      eval+
      push E
   loop
   ld X S  # X on last argument
   link
   lea Y (Z -II)  # Limit
   do
      cmp X Y  # More args?
   while ne  # Yes
      ld E (X)  # Argument specification
      num E  # Number?
      if nz  # Yes
         cnt E  # Short?
         if nz  # Yes
            shr E 4  # Normalize
            if c  # Sign?
               neg E  # Yes
            end
         else
            test E SIGN  # Get sign
            push F  # Save
            off E (| SIGN BIG)  # Get cell pointer
            ld A (E CDR)  # High word
            ld E (E)  # Low word
            shr A 5  # Get highest four bits
            rcr E 1
            shr A 1
            rcr E 1
            shr A 1
            rcr E 1
            shr A 1
            rcr E 1
            pop F  # Negative
            if nz  # Yes
               neg E  # Negate
            end
         end
         push E  # Pass long argument
         push 0  # as Integer/pointer value
      else
         sym E  # String?
         if nz  # Yes
            push Z
            call bufStringE_SZ  # Write to stack buffer
            cc strdup(S)  # Make new string
            ld S Z  # Drop buffer
            pop Z
            push A  # Pass pointer argument
            push 0  # as Integer/pointer value
         else
            ld C (E CDR)  # Fixpoint?
            cnt C
            if nz  # Yes
               push (E)  # Pass number or flag
               push C  # as fixpoint value
            else
               ld E C  # Ignore variable
               ld C ((E))  # Get buffer size
               shr C 4  # Normalize
               call allocC_A  # Allocate buffer
               push A  # Pass pointer argument
               push 0  # as Integer/pointer value
               push Z
               ld Z A  # Buffer pointer in Z
               do
                  ld E (E CDR)
                  cnt E  # Fill rest?
                  if nz  # Yes
                     ld A E  # Byte value
                     shr A 4  # in B
                     do
                        sub C 1  # Done?
                     while ns  # No
                        ld (Z) B  # Store byte in buffer
                        inc Z  # Increment buffer pointer
                     loop
                     break T
                  end
                  atom E  # Fill bytes?
               while z  # Yes
                  ld A (E)  # Next byte value
                  shr A 4  # in B
                  ld (Z) B  # Store in buffer
                  inc Z  # Increment buffer pointer
                  dec C  # Buffer full?
               until z  # Yes
               pop Z
            end
         end
      end
      add X I  # Next arg
   loop
   ld X S  # Start of args in X
   off S 15  # Align stack to cell boundary
   ld A S  # Keep end of duplicated args in A
   ld C L  # Top of args
   sub C X  # Bytes
   sub S C  # Space for args
   movm (S) (X) (L)  # Duplicate args
   ld Y (Z)  # Get function pointer
   cc (Y) A  # Call C-function
   ld S X  # Drop duplicated args
   ld E (Z -II)  # Get result specification
   ld C 0  # No pointer yet
   push (Link)  # Save L
   ld (Link) L
   call natRetACE_CE  # Extract return value
   pop (Link)
   ld (Z -II) E  # Save result
   lea Y (Z -III)  # Clean up allocated C args
   do
      cmp Y L  # Args?
   while ne  # Yes
      add S I  # Drop type
      pop X  # Next C arg
      ld E (Y)  # Next Lisp arg
      num E  # Number?
      if z  # No
         sym E  # String?
         jnz 10  # Yes
         cnt (E CDR)  # Fixpoint?
         if z  # No
            cmp (E) Nil  # Variable?
            if ne  # Yes
               ld C X  # Structure pointer
               ld E (((E CDR)) CDR)  # Result specification
               call natRetACE_CE  # Extract value
               ld (((Y))) E  # Store in variable
            end
10          cc free(X)  # Free string or buffer
         end
      end
      sub Y I
   loop
   ld E (Z -II)  # Get result
   drop
   pop A  # Drop library handle
   pop Z
   pop Y
   pop X
   ret

(code 'natRetACE_CE 0)
   cmp E Nil  # NIL?
   if ne
      cnt E  # Scale?
      if nz  # Yes
         null C  # Pointer?
         if nz  # Yes
            test E SIGN  # Negative?
            if z  # No
               dval  # Get double value
               add C 8  # Size of double
            else
               fval  # Get float value
               add C 4  # Size of float
            end
         end
         fix  # Get fixpoint number or flg
      else
         cmp E ISym  # 'I'?
         if eq  # Yes
            null C  # Pointer?
            if nz  # Yes
               ld4 (C)
               add C 4  # Size of int
            end
            ld E (hex "FFFFFFFF")  # Sign-extend integer
            and E A  # into E
            ld A (hex "80000000")
            xor E A
            sub E A  # Negative?
            if ns  # No
               shl E 4  # Make short number
               or E CNT
            else
               neg E  # Negate
               shl E 4  # Make negative short number
               or E (| SIGN CNT)
            end
         else
            cmp E NSym  # 'N'?
            if eq  # Yes
               null C  # Pointer?
               if nz  # Yes
                  ld A (C)
                  add C 8  # Size of long/pointer
               end
               ld E A  # Number
               null E  # Negative?
               if ns  # No
                  test E (hex "F000000000000000")  # Fit in short?
                  if z  # Yes
                     shl E 4  # Make short number
                     or E CNT
                  else
                     call boxNumE_E  # Make bignum
                  end
               else
                  neg E  # Negate
                  test E (hex "F000000000000000")  # Fit in short?
                  if z  # Yes
                     shl E 4  # Make negative short number
                     or E (| SIGN CNT)
                  else
                     call boxNumE_E  # Make bignum
                     or E SIGN  # Set negative
                  end
               end
            else
               cmp E SSym  # 'S'?
               if eq  # Yes
                  null C  # Pointer?
                  if nz  # Yes
                     ld A (C)
                     add C 8  # Size of pointer
                  end
                  ld E A  # Make transient symbol
                  call mkStrE_E
               else
                  cmp E CSym  # 'C'?
                  if eq  # Yes
                     null C  # Pointer?
                     if nz  # Yes
                        call fetchCharC_AC  # Fetch char
                     end
                     ld E Nil  # Preload
                     null A  # Char?
                     if nz  # Yes
                        call mkCharA_A  # Make char
                        ld E A
                     end
                  else
                     cmp E BSym  # 'B'?
                     if eq  # Yes
                        null C  # Pointer?
                        if nz  # Yes
                           ld B (C)
                           inc C  # Size of byte
                        end
                        zxt  # Byte
                        ld E A
                        shl E 4  # Make short number
                        or E CNT
                     else
                        atom E  # Atomic?
                        if z  # No: Arrary or structure
                           null A  # Returned NULL?
                           ldz E Nil  # Yes: Return NIL
                           if nz
                              null C  # Pointer?
                              ldz C A  # Yes: Load into C
                              push X
                              push Y
                              push Z
                              ld X E  # Get specification in X
                              ld E (X)
                              call natRetACE_CE  # First item
                              call cons_Y  # Make cell
                              ld (Y) E
                              ld (Y CDR) Nil
                              link
                              push Y  # <L I> Result
                              link
                              do
                                 ld Z (X CDR)
                                 cnt Z  # (sym . cnt)
                                 if nz
                                    shr Z 4  # Normalize
                                    do
                                       dec Z  # Decrement count
                                    while nz
                                       ld E (X)  # Repeat last type
                                       call natRetACE_CE  # Next item
                                       call cons_A  # Cons into cell
                                       ld (A) E
                                       ld (A CDR) Nil
                                       ld (Y CDR) A  # Append to result
                                       ld Y A
                                    loop
                                    break T
                                 end
                                 atom Z  # End of specification?
                              while z  # No
                                 ld X Z
                                 ld E (X)  # Next type
                                 call natRetACE_CE  # Next item
                                 call cons_A  # Cons into cell
                                 ld (A) E
                                 ld (A CDR) Nil
                                 ld (Y CDR) A  # Append to result
                                 ld Y A
                              loop
                              ld E (L I)  # Get result
                              drop
                              pop Z
                              pop Y
                              pop X
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
   ret

(code 'fetchCharC_AC 0)
   ld B (C)  # Fetch first byte
   zxt
   or B B  # Any?
   if nz  # Yes
      inc C
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
            ld B (C)  # Fetch second byte
            zxt
            inc C
            and B (hex "3F")  # 10xxxxxx
            or A (S)  # Combine
            shl A 6  # xxxxxxxxxx000000
            ld (S) A
         end
         ld B (C)  # Fetch last byte
         zxt
         inc C
         and B (hex "3F")  # 10xxxxxx
         or (S) A  # Combine
         pop A  # Get result
      end
   end
   ret

: cbl
   begin 5  # Arguments in A, C, E, X and Y
   push L  # Save C frame pointer
   ld L (Link)  # Restore link register
   link  # Apply args
   push (Z I)  # 'fun'
   xchg A E  # First arg
   call boxCntE_E  # Make number
   push E
   ld E C  # Second arg
   call boxCntE_E  # Make number
   push E
   ld E A  # Third arg
   call boxCntE_E  # Make number
   push E
   ld E X  # Fourth arg
   call boxCntE_E  # Make number
   push E
   ld E Y  # Fifth arg
   call boxCntE_E  # Make number
   push E
   ld Z S  # Z on last argument
   link  # Close frame
   lea Y (S VI)  # Pointer to 'fun' in Y
   call applyXYZ_E  # Apply
   ld A E  # Return value
   shr A 4  # Normalize
   if c  # Sign?
      neg A  # Yes
   end
   drop
   pop L  # Restore C frame pointer
   return 5
   pop Z
   ret

(code 'cbl1 0)
   push Z
   lea Z (Lisp)  # Address of callback function
   jmp cbl
: cbl2
   push Z
   lea Z (Lisp II)
   jmp cbl
: cbl3
   push Z
   lea Z (Lisp (* 2 II))
   jmp cbl
: cbl4
   push Z
   lea Z (Lisp (* 3 II))
   jmp cbl
: cbl5
   push Z
   lea Z (Lisp (* 4 II))
   jmp cbl
: cbl6
   push Z
   lea Z (Lisp (* 5 II))
   jmp cbl
: cbl7
   push Z
   lea Z (Lisp (* 6 II))
   jmp cbl
: cbl8
   push Z
   lea Z (Lisp (* 7 II))
   jmp cbl
: cbl9
   push Z
   lea Z (Lisp (* 8 II))
   jmp cbl
: cbl10
   push Z
   lea Z (Lisp (* 9 II))
   jmp cbl
: cbl11
   push Z
   lea Z (Lisp (* 10 II))
   jmp cbl
: cbl12
   push Z
   lea Z (Lisp (* 11 II))
   jmp cbl
: cbl13
   push Z
   lea Z (Lisp (* 12 II))
   jmp cbl
: cbl14
   push Z
   lea Z (Lisp (* 13 II))
   jmp cbl
: cbl15
   push Z
   lea Z (Lisp (* 14 II))
   jmp cbl
: cbl16
   push Z
   lea Z (Lisp (* 15 II))
   jmp cbl
: cbl17
   push Z
   lea Z (Lisp (* 16 II))
   jmp cbl
: cbl18
   push Z
   lea Z (Lisp (* 17 II))
   jmp cbl
: cbl19
   push Z
   lea Z (Lisp (* 18 II))
   jmp cbl
: cbl20
   push Z
   lea Z (Lisp (* 19 II))
   jmp cbl
: cbl21
   push Z
   lea Z (Lisp (* 20 II))
   jmp cbl
: cbl22
   push Z
   lea Z (Lisp (* 21 II))
   jmp cbl
: cbl23
   push Z
   lea Z (Lisp (* 22 II))
   jmp cbl
: cbl24
   push Z
   lea Z (Lisp (* 23 II))
   jmp cbl

# (lisp 'sym ['fun]) -> num
(code 'doLisp 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Get tag
   call evSymY_E  # Evaluate to a symbol
   ld A Lisp  # Search lisp callback definitions
   ld C cbl1
   do
      cmp E (A)  # Found tag?
      jeq  10  # Yes
      add A II  # Next entry
      add C "cbl2-cbl1"
      cmp A LispEnd
   until eq
   ld A Lisp  # Not found, search for empty slot
   ld C cbl1
   do
      cmp (A I) Nil  # Empty?
      if eq  # Yes
10       push C  # Save function pointer
         push A  # And callback entry
         ld (A) E  # Store tag
         ld E ((Y CDR))  # Eval 'fun'
         eval
         pop A
         ld (A I) E  # Store in slot
         pop E  # Get function pointer
         pop Y
         pop X
         test E (hex "F000000000000000")  # Fit in short number?
         jnz boxNumE_E  # No
         shl E 4  # Else make short number
         or E CNT
         ret
      end
      add A II  # Next entry
      add C "cbl2-cbl1"
      cmp A LispEnd
   until eq
   ld Y CbErr
   jmp errEXYZ
: CbErr asciz "Too many callbacks"

(code 'lisp 0)
   begin 6  # Function name in A, arguments in C, E, X, Y and Z
   push L  # Save C frame pointer
   ld L (Link)  # Restore link register
   link  # Apply args
   push ZERO  # Space for 'fun'
   xchg C E  # First arg
   call boxCntE_E  # Make number
   push E
   ld E C  # Second arg
   call boxCntE_E  # Make number
   push E
   ld E X  # Third arg
   call boxCntE_E  # Make number
   push E
   ld E Y  # Fourth arg
   call boxCntE_E  # Make number
   push E
   ld E Z  # Fifth arg
   call boxCntE_E  # Make number
   push E
   ld Z S  # Z on last argument
   link  # Close frame
   ld C 4  # Build name
   ld E A  # Function name argument
   lea X (S VI)  # Pointer to 'fun' entry
   do
      ld B (E)
      call byteSymBCX_CX  # Pack byte
      inc E  # Next byte
      nul (E)  # Any?
   until z
   ld X (S VI)  # Get name
   call findSymX_E  # Find or create symbol
   lea Y (S VI)  # Pointer to 'fun' in Y
   ld (Y) E  #  Store 'fun'
   call applyXYZ_E  # Apply
   ld A E  # Return value
   shr A 4  # Normalize
   if c  # Sign?
      neg A  # Yes
   end
   drop
   pop L  # Restore C frame pointer
   return 6
   ret

(code 'execE 0)
   push X
   ld X E
   link
   push (At)  # <L I> Preserve '@'
   link
   exec X  # Execute body
   ld (At) (L I)
   drop
   pop X
   ret

(code 'runE_E 0)
   push X
   ld X E
   link
   push (At)  # <L I> Preserve '@'
   link
   prog X  # Run body
   ld (At) (L I)
   drop
   pop X
   ret

(code 'funqE_FE 0)
   cnt E  # Short number?
   jnz retz  # Yes
   big E  # Big number?
   jnz ret  # No
   sym E  # Symbol?
   jnz ret  # Yes
   ld C (E CDR)  # Check function body
   do
      atom C  # More?
   while z  # Yes
      cmp C E  # Circular?
      jeq retnz  # Yes
      ld A (C)  # Next item
      atom A  # Cell?
      if z  # Yes
         num (A)  # CAR a number?
         if nz  # Yes
            atom (C CDR)  # Must be the last
            jz retnz
         else
            cmp (A) Nil  # CAR is NIL?
            jeq retnz  # Yes
            cmp (A) TSym  # CAR is T?
            jeq retnz  # Yes
         end
      else
         cmp (C CDR) Nil  # Atomic item must be the last
         jne ret
      end
      ld C (C CDR)
   loop
   cmp C Nil  # Must be NIL-terminated
   jne ret
   ld E (E)  # Get parameter(s)
   cmp E Nil  # Any?
   ldz E TSym  # No: Return T
   if ne  # Yes
      ld C E
      do
         atom C  # Atomic parameter?
      while z  # No
         ld A (C)  # Next parameter
         num A  # Number?
         jnz ret  # Yes
         atom A  # List?
         jz retnz  # Yes
         cmp A Nil  # NIL?
         jeq retnz  # Yes
         cmp A TSym  # T?
         jeq retnz  # Yes
         ld C (C CDR)  # Rest
         cmp C E  # Circular?
         jeq retnz  # Yes
      loop
      cmp C TSym  # T?
      jeq retnz  # Yes
      num C  # Number?
      jnz ret  # Yes
   end
   ret

(code 'evSymX_E 0)
   ld E (X)  # Get CAR
   jmp evSymE_E
(code 'evSymY_E 0)
   ld E (Y)  # Get CAR
(code 'evSymE_E)
   eval  # Evaluate
(code 'xSymE_E)
   num E  # Number?
   if z  # No
      sym E  # Symbol?
      jnz ret  # Yes
   end
   push X
   link
   push E  # Save 'any'
   push ZERO  # <L II> Number safe
   push ZERO  # <L I> Result
   ld C 4  # Build name
   ld X S
   link
   call packECX_CX
   ld X (L I)  # Get result
   call consSymX_E  # Make transient symbol
   drop
   pop X
   ret

(code 'evCntXY_FE 0)
   ld E (Y)  # Get CAR
(code 'evCntEX_FE)
   eval  # Evaluate
(code 'xCntEX_FE 0)
   cnt E  #  # Short number?
   jz cntErrEX  # No
   shr E 4  # Normalize
   if c  # Sign?
      neg E  # Yes
   end
   ret  # 'z' if null, 's' if negative

(code 'xCntCX_FC 0)
   cnt C  #  # Short number?
   jz cntErrCX  # No
   shr C 4  # Normalize
   if c  # Sign?
      neg C  # Yes
   end
   ret  # 'z' if null, 's' if negative

(code 'xCntAX_FA 0)
   cnt A  #  # Short number?
   jz cntErrAX  # No
   shr A 4  # Normalize
   if c  # Sign?
      neg A  # Yes
   end
   ret  # 'z' if null, 's' if negative

(code 'boxCntE_E 0)
   null E  # Positive?
   if ns  # Yes
      shl E 4  # Make short number
      or E CNT
      ret
   end
   neg E  # Else negate
   shl E 4  # Make short number
   or E 10  # with SIGN
   ret

(code 'putStringB 0)
   push X
   push C
   ld X (StrX)  # Get string status
   ld C (StrC)
   call byteSymBCX_CX  # Add byte to result
   ld (StrC) C  # Save string status
   ld (StrX) X
   pop C
   pop X
   ret

(code 'begString 0)
   pop A  # Get return address
   link
   push ZERO  # <L I> Result
   ld (StrC) 4  # Build name
   ld (StrX) S
   link
   push (PutB)  # Save 'put'
   ld (PutB) putStringB  # Set new
   jmp (A)  # Return

(code 'endString_E 0)
   pop A  # Get return address
   pop (PutB)  # Restore 'put'
   ld E Nil  # Preload NIL
   cmp (L I) ZERO  # Name?
   if ne  # Yes
      call cons_E  # Cons symbol
      ld (E) (L I)  # Set name
      or E SYM  # Make symbol
      ld (E) E  # Set value to itself
   end
   drop
   jmp (A)  # Return

(code 'msec_A)
   push C
   cc gettimeofday(Buf 0)  # Get time
   ld A (Buf)  # tv_sec
   mul 1000  # Convert to milliseconds
   ld (Buf) A  # Save
   ld A (Buf I)  # tv_usec
   div 1000  # Convert to milliseconds (C is zero)
   add A (Buf)
   pop C
   ret

# (args) -> flg
(code 'doArgs 2)
   cmp (EnvNext) (EnvArgs)  # VarArgs?
   ld E Nil
   ldnz E TSym  # Yes
   ret

# (next) -> any
(code 'doNext 2)
   ld C (EnvNext)  # VarArgs
   cmp C (EnvArgs)  # Any?
   if ne  # Yes
      sub C I  # Get next
      ld E (C)
      ld (EnvNext) C
      ret
   end
   ld E Nil  # No (more) arguments
   null C  # Any previous arg?
   if nz  # Yes
      ld (C) E  # Set to NIL
   end
   ret

# (arg ['cnt]) -> any
(code 'doArg 2)
   null (EnvArgs)  # Any args?
   jz retNil  # No
   ld E (E CDR)  # 'cnt' arg?
   atom E
   if nz  # No
      ld E ((EnvNext))  # Return arg from last call to 'next'
      ret
   end
   ld E (E)
   eval  # Eval 'cnt'
   test E SIGN  # Negative?
   if z  # No
      shr E 1  # Normalize to word index
      off E 1  # Clear 'cnt' tag
      if nz  # Greater zero
         ld C (EnvNext)  # VarArgs
         sub C E  # Subtract from VarArgs pointer
         cmp C (EnvArgs)  # Out of range?
         if ge  # No
            ld E (C)  # Get value
            ret
         end
      end
   end
   ld E Nil
   ret

# (rest) -> lst
(code 'doRest 2)
   ld E Nil  # Return value
   ld C (EnvArgs)  # VarArgs
   do
      cmp C (EnvNext)  # Any?
   while ne  # Yes
      call consE_A  # New cell
      ld (A) (C)
      ld (A CDR) E
      ld E A
      add C I  # Next
   loop
   ret

(code 'tmDateC_E 0)
   ld4 (C TM_MDAY)  # Get day
   ld X A
   ld4 (C TM_MON)  # month
   inc A
   ld Y A
   ld4 (C TM_YEAR)  # and year
   add A 1900
   ld Z A
# Date function
(code 'dateXYZ_E 0)
   cmp Y 0  # Month <= 0?
   jle retNil
   cmp Y 12  # Month > 12?
   jgt retNil
   cmp X 0  # Day <= 0?
   jle retNil
   ld B (Y Month)  # Max monthly days
   cmp X B  # Day > max?
   if gt  # Yes
      cmp Y 2  # February?
      jne retNil
      cmp X 29  # 29th?
      jne retNil
      test Z 3  # year a multiple of 4?
      jnz retNil
      ld A Z  # Year
      ld C 0
      div 100
      null C  # Multiple of 100?
      if z  # Yes
         ld A Z  # Year
         div 400
         null C  # Multiple of 400?
         jnz retNil
      end
   end
   ld A Z  # Get year
   mul 12  # times 12
   add A Y  # plus month
   sub A 3  # minus 3
   ld C 0
   div 12  # divide by 12
   ld E A  # n =  (12 * year + month - 3) / 12
   ld C 0
   div 100  # divide by 100
   ld C E
   shr E 2  # n/4
   add C C  # n*2
   sub E C  # n/4 - n*2
   sub E A  # n/4 - n*2 - n/100
   shr A 2  # n/400
   add E A  # E = n/4 - n*2 - n/100 + n/400
   ld A Z  # Year
   mul 4404  # times 4404
   ld Z A
   ld A Y  # Month
   mul 367  # times 367
   add A Z  # plus year*4404
   sub A 1094  # minus 1094
   div 12  # A = (4404*year + 367*month - 1094) / 12
   add E A  # Add up
   add E X  # plus days
   shl E 4  # Make short number
   or E CNT
   ret
: Month bytes (31 31 28 31 30 31 30 31 31 30 31 30 31)

# (date ['T]) -> dat
# (date 'dat) -> (y m d)
# (date 'y 'm 'd) -> dat | NIL
# (date '(y m d)) -> dat | NIL
(code 'doDate 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   atom Y  # Any?
   if nz  # No
      cc time(Buf)  # Get current time
      cc localtime(Buf)  # Convert to local time
      ld (Time) A  # Keep in 'Time'
      ld C A
      call tmDateC_E  # Extract date
   else
      ld E (Y)  # Eval first
      eval
      cmp E TSym  # T?
      if eq  # Yes
         cc time(Buf)  # Get current time
         cc gmtime(Buf)  # Convert to Greenwich Mean Time
         ld (Time) A  # Keep in 'Time'
         ld C A
         call tmDateC_E  # Extract date
      else
         cmp E Nil  # NIL?
         if ne  # No
            atom E  # List?
            if z  # Yes
               ld C (E)  # Extract year
               call xCntCX_FC
               ld Z C
               ld E (E CDR)
               ld C (E)  # month
               call xCntCX_FC
               ld Y C
               ld C ((E CDR))  # and day
               call xCntCX_FC
               ld X C
               call dateXYZ_E
            else
               ld Y (Y CDR)  # More args?
               atom Y
               if nz  # No
                  call xCntEX_FE  # Get date
                  ld A E  # 100 * n
                  mul 100
                  sub A 20  # minus 20
                  ld C 0  # divide by 3652425
                  div 3652425
                  ld Z A  # year = (100*n - 20) / 3652425
                  add E A  # n += (year - year/4)
                  shr A 2
                  sub E A
                  ld A E  # n
                  mul 100  # 100 * n
                  sub A 20  # minus 20
                  div 36525  # divide by 36525
                  ld Z A  # year = (100*n - 20) / 36525
                  mul 36525  # times 36525
                  div 100  # divide by 100
                  sub E A  # n -= 36525*y / 100
                  ld A E  # n
                  mul 10  # times 10
                  sub A 5  # minus 5
                  div 306  # divide by 306
                  ld Y A  # month = (10*n - 5) / 306
                  mul 306  # times 306
                  ld X A
                  ld A E  # n
                  mul 10  # times 10
                  sub A X  # minus 306*month
                  add A 5  # push 5
                  div 10  # divide by 10
                  ld X A  # day = (10*n - 306*month + 5) / 10
                  cmp Y 10  # month < 10?
                  if lt  # Yes
                     add Y 3  # month += 3
                  else
                     inc Z  # Increment year
                     sub Y 9  # month -= 9
                  end
                  shl X 4  # Make short day
                  or X CNT
                  call cons_E  # into cell
                  ld (E) X
                  ld (E CDR) Nil
                  shl Y 4  # Make short month
                  or Y CNT
                  call consE_C  # Cons
                  ld (C) Y
                  ld (C CDR) E
                  shl Z 4  # Make short year
                  or Z CNT
                  call consC_E  # Cons
                  ld (E) Z
                  ld (E CDR) C
               else
                  call xCntEX_FE  # Extract year
                  ld Z E  # into Z
                  call evCntXY_FE  # Eval month
                  push E  # Save
                  ld Y (Y CDR)  # Eval day
                  call evCntXY_FE
                  ld X E  # Get day
                  pop Y  # and month
                  call dateXYZ_E
               end
            end
         end
      end
   end
   pop Z
   pop Y
   pop X
   ret

(code 'tmTimeY_E 0)
   ld4 (Y TM_HOUR)  # Get hour
   mul 3600
   ld E A
   ld4 (Y TM_MIN)  # Get minute
   mul 60
   add E A
   ld4 (Y TM_SEC)  # Get second
   add E A
   shl E 4  # Make short number
   or E CNT
   ret

# (time ['T]) -> tim
# (time 'tim) -> (h m s)
# (time 'h 'm ['s]) -> tim | NIL
# (time '(h m [s])) -> tim | NIL
(code 'doTime 2)
   push X
   push Y
   ld Y (E CDR)  # Y on args
   atom Y  # Any?
   if nz  # No
      cc time(Buf)  # Get current time
      cc localtime(Buf)  # Convert to local time
      ld Y A
      call tmTimeY_E  # Extract time
   else
      ld E (Y)  # Eval first
      eval
      cmp E TSym  # T?
      if eq  # Yes
         ld Y (Time)  # Get time from last call to 'date'
         null Y  # Any?
         if nz  # Yes
            call tmTimeY_E  # Extract time
         else
            ld E Nil
         end
      else
         cmp E Nil  # NIL?
         if ne  # No
            atom E  # List?
            if z  # Yes
               ld A (E)  # Extract hour
               call xCntAX_FA
               mul 3600
               ld Y A
               ld E (E CDR)
               ld A (E)  # minute
               call xCntAX_FA
               mul 60
               add Y A
               ld E (E CDR)  # and second
               atom E  # Any?
               ldnz E Y  # No
               if z  # Yes
                  ld E (E)
                  call xCntEX_FE
                  add E Y  # add minutes and hours
               end
               shl E 4  # Make short number
               or E CNT
            else
               ld Y (Y CDR)  # More args?
               atom Y
               if nz  # No
                  call xCntEX_FE  # Get time in total seconds
                  ld A E
                  ld C 0
                  div 60  # Seconds in C
                  shl C 4  # Make short number
                  or C CNT
                  call cons_Y  # into cell
                  ld (Y) C
                  ld (Y CDR) Nil
                  ld A E
                  ld C 0
                  div 60  # Total minutes in A
                  ld C 0
                  div 60  # Minutes in C
                  shl C 4  # Make short number
                  or C CNT
                  call consY_X
                  ld (X) C
                  ld (X CDR) Y
                  xchg A E  # Get total seconds again
                  ld C 0
                  div 3600  # Hours in A
                  shl A 4  # Make short number
                  or A CNT
                  call consX_E
                  ld (E) A
                  ld (E CDR) X
               else
                  call xCntEX_FE  # Extract hour
                  ld A E
                  mul 3600
                  push A  # Save hour
                  call evCntXY_FE  # Eval minute
                  ld A E
                  mul 60
                  add (S) A  # Add to hour
                  ld Y (Y CDR)  # Eval second
                  atom Y  # Any?
                  if z  # Yes
                     call evCntXY_FE
                     add (S) E
                  end
                  pop E  # Get result
                  shl E 4  # Make short number
                  or E CNT
               end
            end
         end
      end
   end
   pop Y
   pop X
   ret

# (usec) -> num
(code 'doUsec 2)
   cc gettimeofday(Buf 0)  # Get time
   ld A (Buf)  # tv_sec
   mul 1000000  # Convert to microseconds
   add A (Buf I)  # tv_usec
   sub A (USec)  # Diff to startup time
   ld E A
   shl E 4  # Make short number
   or E CNT
   ret

# (pwd) -> sym
(code 'doPwd 2)
   cc getcwd(0 0)  # Get current working directory
   null A  # OK?
   jz retNil  # No
   push A  # Save buffer pointer
   ld E A  # Make transient symbol
   call mkStrE_E
   cc free(pop)  # Free buffer
   ret

# (cd 'any) -> sym
(code 'doCd 2)
   push Z
   ld E ((E CDR))  # Get arg
   call evSymE_E  # Evaluate to a symbol
   call pathStringE_SZ  # Write to stack buffer
   ld E Nil  # Preload return value
   cc getcwd(0 0)  # Get current working directory
   null A  # OK?
   if nz  # Yes
      push A  # Save buffer pointer
      nul (S I)  # CWD empty?
      jz 10  # Yes
      cc chdir(&(S I))  # Stack buffer
      nul4  # OK?
      if z  # Yes
10       ld E (S)  # Make transient symbol
         call mkStrE_E
      end
      cc free(pop)  # Free buffer
   end
   ld S Z  # Drop buffer
   pop Z
   ret

# (ctty 'sym|pid) -> flg
(code 'doCtty 2)
   push X
   ld X E
   ld E ((E CDR))  # E on arg
   eval  # Eval it
   cnt E  # 'pid'?
   if nz  # Yes
      shr E 4  # Normalize
      ld (TtyPid) E  # Keep in global
      ld E TSym  # Return T
   else
      sym E  # Need symbol
      jz argErrEX
      push Z
      call bufStringE_SZ  # Write to stack buffer
      ld E Nil  # Preload return value
      cc freopen(S _r_ (stdin))  # Re-open standard input
      null A  # OK?
      if nz  # Yes
         cc freopen(S _w_ (stdout))  # Re-open standard output
         null A  # OK?
         if nz  # Yes
            cc freopen(S _w_ (stderr))  # Re-open standard error
            null A  # OK?
            if nz  # Yes
               ld (((OutFiles) I) II) 1  # (stdout) OutFiles[1]->tty
               ld E TSym  # Return T
            end
         end
      end
      ld S Z  # Drop buffer
      pop Z
   end
   pop X
   ret

# (info 'any) -> (cnt|T dat . tim)
(code 'doInfo 2)
   push X
   push Y
   push Z
   ld E ((E CDR))  # Get arg
   call evSymE_E  # Evaluate to a symbol
   call pathStringE_SZ  # Write to stack buffer
   ld E S  # path name pointer
   sub S STAT  # 'stat' structure
   cc stat(E S)  # Get status
   ld E Nil  # Preload return value
   nul4  # 'stat' OK?
   if ns
      cc gmtime(&(S ST_MTIME))  # Get modification time
      ld Y A  # Keep time pointer in Y
      call tmTimeY_E  # Extract time
      push E  # Save time
      push Z
      ld C Y  # Extract date
      call tmDateC_E
      pop Z
      call cons_X  # New cell
      ld (X) E  # Set date
      pop (X CDR)  # and time
      call consX_E  # New cell
      call s_isdirS_F  # Directory?
      if eq  # Yes
         ld (E) TSym  # CAR is T
      else
         ld A (S ST_SIZE)  # Get size
         shl A 4  # Make short number
         or A CNT
         ld (E) A
      end
      ld (E CDR) X
   end
   ld S Z  # Drop buffers
   pop Z
   pop Y
   pop X
   ret

# (file) -> (sym1 sym2 . num) | NIL
(code 'doFile 2)
   ld C (InFile)  # Current InFile?
   null C
   jz retNil  # No
   ld E (C VI)  # Filename?
   null E
   jz retNil  # No
   ld B (char "/")  # Contains a slash?
   slen C E  # String length in C
   memb E C
   if eq  # Yes
      do
         memb E C  # Find last one
      until ne
      push Z
      ld Z E  # Pointer to rest
      dec Z  # without slash in Z
      call mkStrE_E  # Make string
      call consE_C  # Cons
      ld (C) E
      ld A ((InFile) V)  # with 'src'
      shl A 4  # Make short number
      or A CNT
      ld (C CDR) A
      link
      push C  # Save
      link
      ld E ((InFile) VI)  # Filename again
      call mkStrEZ_A  # Make string up to Z
      call consA_E  # Cons into list
      ld (E) A
      ld (E CDR) (L I)
      drop
      pop Z
   else
      call mkStrE_E  # Make string
      call consE_C  # Cons
      ld (C) E
      ld A ((InFile) V)  # with 'src'
      shl A 4  # Make short number
      or A CNT
      ld (C CDR) A
      call consC_A  # Cons symbol
      ld (A) (hex "2F2E2")  # "./"
      or A SYM  # Make symbol
      ld (A) A  # Set value to itself
      call consAC_E  # Cons into list
      ld (E) A
      ld (E CDR) C
   end
   ret

# (dir ['any] ['flg]) -> lst
(code 'doDir 2)
   push X
   push Z
   ld X (E CDR)  # Args
   ld E (X)  # Get 'any'
   call evSymE_E  # Evaluate to a symbol
   cmp E Nil  # NIL?
   if eq  # Yes
      cc opendir(_dot_)  # Open "." directory
   else
      call pathStringE_SZ  # Write to stack buffer
      cc opendir(S)  # Open directory
      ld S Z  # Drop buffer
   end
   null A  # OK?
   jz 10  # No
   ld Z A  # Get directory pointer
   ld X (X CDR)  # Eval 'flg'
   ld E (X)
   eval
   ld X E  # into X
   do
      cc readdir(Z)  # Find first directory entry
      null A  # OK?
      if z  # No
10       ld E Nil  # Return NIL
         pop Z
         pop X
         ret
      end
      lea E (A D_NAME)  # Pointer to name entry
      cmp X Nil  # flg?
   while eq  # Yes
      ld B (E)  # First char
      cmp B (char ".")  # Skip dot names
   until ne
   call mkStrE_E  # Make transient symbol
   call consE_C  # Cons first cell
   ld (C) E
   ld (C CDR) Nil
   link
   push C  # <L I> Result
   link
   do
      cc readdir(Z)  # Read next directory entry
      null A  # OK?
   while nz  # Yes
      lea E (A D_NAME)  # Pointer to name entry
      cmp X Nil  # flg?
      jne 20  # Yes
      ld B (E)  # First char
      cmp B (char ".")  # Ignore dot names
      if ne
20       call mkStrE_E  # Make transient symbol
         call consE_A  # Cons next cell
         ld (A) E
         ld (A CDR) Nil
         ld (C CDR) A  # Concat to result
         ld C A
      end
   loop
   ld E (L I)  # Get result
   drop
   cc closedir(Z)  # Close directory
   pop Z
   pop X
   ret

# (cmd ['any]) -> sym
(code 'doCmd 2)
   ld E ((E CDR))  # Get arg
   call evSymE_E  # Evaluate to a symbol
   cmp E Nil  # NIL?
   if eq
      ld E (AV0)  # Return invocation command
      jmp mkStrE_E  # Return transient symbol
   end
   push Z
   call bufStringE_SZ  # Write to stack buffer
   slen C S  # String length in C
   inc C  # plus null byte
   movn ((AV0)) (S) C  # Copy to system buffer
   ld S Z  # Drop buffer
   pop Z
   ret

# (argv [var ..] [. sym]) -> lst|sym
(code 'doArgv 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   ld Z (AV)  # Command line vector
   ld E (Z)
   null E  # Empty?
   if nz  # No
      ld B (E)  # Single-dash argument?
      cmp B (char "-")
      if eq
         nul (E 1)
         if z  # Yes
            add Z I  # Skip "-"
         end
      end
   end
   cmp Y Nil  # Any args?
   if eq  # No
      ld E Nil  # Preload return value
      null (Z)  # More command line arguments?
      if nz  # Yes
         ld E (Z)  # Next
         call mkStrE_E  # Make transient symbol
         call consE_C  # First result cell
         ld (C) E
         ld (C CDR) Nil
         link
         push C  # <L I> Result
         link
         do
            add Z I  # Next command line argument
            null (Z)  # Any?
         while nz  # Yes
            ld E (Z)  # Get it
            call mkStrE_E  # Make transient symbol
            call consE_A  # Next result cell
            ld (A) E
            ld (A CDR) Nil
            ld (C CDR) A  # Concat to result
            ld C A
         loop
         ld E (L I)  # Get result
         drop
      end
   else
      do
         atom Y  # Atomic tail?
      while z  # No
         ld E (Y)  # Next 'var'
         call needVarEX
         ld E (Z)  # Next command line argument
         null E  # Any?
         if nz  # No
            add Z I  # Increment command line index
         end
         call mkStrE_E  # Make transient symbol
         ld ((Y)) E  # Set value
         ld Y (Y CDR)  # Next arg
         cmp Y Nil  # End of list?
         jeq 90  # Yes
      loop
      num Y  # Need symbol
      jnz symErrYX
      call checkVarYX  # Check variable
      ld E (Z)  # Next command line argument
      null E  # Any?
      if z  # No
         ld E Nil  # Set and return NIL
         ld (Y) E
      else
         call mkStrE_E  # Make transient symbol
         call consE_C  # First result cell
         ld (C) E
         ld (C CDR) Nil
         link
         push C  # <L I> Result
         link
         do
            add Z I  # Next command line argument
            null (Z)  # Any?
         while nz  # Yes
            ld E (Z)  # Get it
            call mkStrE_E  # Make transient symbol
            call consE_A  # Next result cell
            ld (A) E
            ld (A CDR) Nil
            ld (C CDR) A  # Concat to result
            ld C A
         loop
         ld E (L I)  # Get and set result
         ld (Y) E
         drop
      end
   end
90 pop Z
   pop Y
   pop X
   ret

# (opt) -> sym
(code 'doOpt 2)
   ld E ((AV))  # Command line vector
   null E  # Next string pointer?
   jz retNil  # No
   ld B (E)  # Single-dash argument?
   cmp B (char "-")
   if eq
      nul (E 1)
      jz retNil  # Yes
   end
   add (AV) I  # Increment vector pointer
   jmp mkStrE_E  # Return transient symbol

# (version ['flg]) -> lst
(code 'doVersion 2)
   ld E ((E CDR))  # Eval flg
   eval
   cmp E Nil  # Suppress output?
   if eq  # No
      ld E Version  # Print version
      do
         ld A (E)  # Next number
         shr A 4  # Normalize
         call outWordA  # Print it
         ld E (E CDR)  # More numbers?
         atom E
      while z  # Yes
         ld B `(char ".")  # Output dot
         call (PutB)
      loop
      call newline
   end
   ld E Version  # Return version
   ret

# vi:et:ts=3:sw=3
