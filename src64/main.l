# 02dec16abu
# (c) Software Lab. Alexander Burger

(code 'Code)
   initCode

### Global return labels ###
(code 'Ret 0)
   ret
(code 'RetEq 0)
   eq
   ret
(code 'RetGt 0)
   gt
   ret
(code 'RetLt 0)
   lt
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
   initMain
   ld (AV0) X  # Save command
   ld (AV) Y  # and argument vector
   # Check debug mode
   ld C (Z)  # Last argument
   ld B (C)  # First byte
   cmp B (char "+")  # Single plus?
   if eq  # Yes
      nul (C 1)
      if z  # Yes
         ld (Dbg) TSym  # Set '*Dbg'
         ld (Z) 0  # Clear last argument
      end
   end
   # Locate home directory
   ld Y (Y)  # First argument
   null Y  # Any?
   if nz  # Yes
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
      end
   end
   # Initialize globals
   cc getpid()  # PID in A
   shl A 4  # Make short number
   or A CNT
   ld (Pid) A
   ld (Stack0) S  # Save top level stack pointer
   ld A S  # Stack top in A
   sub A (* 4 STACK)  # Decrement by main segment size
   ld (Stack1) A  # Set coroutine stack base
   ld (StkLimit) 0  # Initially without stack limit
   ld L 0  # Init link register
   call heapAlloc  # Allocate initial heap
   ld E Nil  # Init internal symbols
   lea Z (E VI)  # Skip padding and 'pico' cell
   do
      ld X (E TAIL)  # Get name
      ld Y Pico  # From initial symbol namespace
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
   call cons_A  # Create external symbol tree root node
   ld (A) Db1  # '{1}'
   ld (A CDR) Nil
   ld (Extern) A
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
   sub S (%% SIGSET_T)  # Create signal mask structure
   cc sigfillset(S)  # Set all signals to unblocked
   cc sigprocmask(SIG_UNBLOCK S 0)
   add S (%% SIGSET_T)  # Drop mask structure
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
   cc signal(SIGCHLD sigChld)  # Install child signal handler for SIGCHLD
   cc signal(SIGPIPE SIG_IGN)  # Ignore signals
   cc signal(SIGTTIN SIG_IGN)
   cc signal(SIGTTOU SIG_IGN)
   cc gettimeofday(Tv 0)  # Get time
   ld A (Tv)  # tv_sec
   mul 1000000  # Convert to microseconds
   add A (Tv I)  # tv_usec
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
   jmp restart

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

(code 'execErrS)
   cc fprintf((stderr) ExecErr (S))
   stop

# Install interrupting signal
(code 'iSignalCE)
   sub S (%% SIGACTION)  # 'sigaction' and 'oldact'
   ld (S SA_HANDLER) E  # Function pointer
   cc sigemptyset(&(S SA_MASK))
   ld (S SA_FLAGS) 0
   cc sigaction(C S 0)  # Install handler
   add S (%% SIGACTION)
   ret

# Allocate memory
(code 'allocC_A 0)
   cc malloc(C)  # Allocate memory of size C
   null A  # OK?
   jz noMemory  # No
   ret
(code 'allocAE_A 0)
   cc realloc(A E)  # Reallocate pointer in A to size E
   null A  # OK?
   jnz Ret  # Return
: noMemory
   ld X AllocErr  # No memory
   jmp giveupX


# Allocate cell heap
(code 'heapAlloc 0)  # AEX
   ld A 0  # NULL pointer
   ld E (+ HEAP I II)  # Heap size + link + space
   call allocAE_A
   ? (= *Architecture "emu")
      add A 15  # Align to cell boundary
      off B 15
   =
   ld E A  # Heap pointer
   ld (A HEAP) (Heaps)  # Set heap link
   ld (Heaps) A
   add A (- HEAP II)  # A on last cell in chunk
   ld X (Avail)  # Initialize free list
   do
      ld (A) X  # Link avail
      ld X A
      sub A II
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
      inc (EnvProtect)
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
                              break T
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
   begin  # Signal number in A
   null (TtyPid)  # Kill terminal process?
   if nz  # Yes
      cc kill((TtyPid) A)
   else
      shl A 3  # Signal index
      inc (A Signal)
      inc (Signal)
   end
   return

(code 'sigTerm)
   begin  # Ignore signal number
   null (TtyPid)  # Kill terminal process?
   if nz  # Yes
      cc kill((TtyPid) SIGTERM)
   else
      inc (Signal (* I SIGTERM))
      inc (Signal)
   end
   return

(code 'sigChld)
   begin  # Ignore signal number
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
   return

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
   begin  # Ignore signal number
   ld C OrgTermio  # Set original terminal I/O
   call tcSetC
   sub S (%% SIGSET_T)  # Create mask structure
   cc sigemptyset(S)  # Init to empty signal set
   cc sigaddset(S SIGTSTP)  # Add stop signal
   cc sigprocmask(SIG_UNBLOCK S 0)  # Remove blocked signals
   add S (%% SIGSET_T)  # Drop mask structure
   cc signal(SIGTSTP SIG_DFL)
   cc raise(SIGTSTP)
   cc signal(SIGTSTP sigTermStop)
   ld C (Termio)
   call tcSetC
   return

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
         ld A (+ OPOST ONLCR)  # Set ONLCR in c_oflag
         st4 (C C_OFLAG)
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

# (sigio 'cnt . prg) -> cnt
(code 'doSigio 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   call evCntXY_FE  # Get fd
   ld (Sigio) (Y CDR)  # Set handler
   ld A (Pid)  # Get process ID
   shr A 4  # Normalize
   cc fcntl(E F_SETOWN A)  # Receive SIGIO events
   cc fcntl(E F_GETFL 0)  # Get file status flags
   or A (| O_NONBLOCK O_ASYNC)
   cc fcntl(E F_SETFL A)  # Set file status flags
   shl E 4  # Return fd
   or E CNT
   pop Y
   pop X
   ret

# (kids) -> lst
(code 'doKids 2)
   push X
   ld E Nil  # Result
   ld X (Child)  # Iterate children
   ld C (Children)  # Count
   do
      sub C VI  # More?
   while ge  # Yes
      null (X)  # 'pid'?
      if nz  # Yes
         call consE_A  # Cons result
         ld (A CDR) E
         ld E (X)  # with short number
         shl E 4
         or E CNT
         ld (A) E
         ld E A
      end
      add X VI  # Increment by sizeof(child)
   loop
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
   ld E 0  # Init count
   ld C (Avail)  # Get avail list
   do
      null C  # Any?
   while nz  # Yes
      inc E  # Increment count
      ld C (C)  # Follow link
   loop
   shr E (- 20 4)  # Divide by CELLS (1M/16), clear tags
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
         shl E 12  # Main stack segment size [times 4 kB]
         ld A (Stack0)  # Get stack top
         sub A E  # Decrement by main segment size
         ld (Stack1) A  # New coroutine stack base
         shr E 2  # [to bytes]
         ld (StkSize) E  # Set new stack size
         shr E 6  # Make short number [kB]
         or E CNT
         pop X
         ret
      end
   end
   ld E (StkSize)  # Return current stack size
   shr E 6  # Make short number [kB]
   or E CNT
   ld X (Stack1)  # Collect coroutines
   ld C (Stacks)  # Segment bitmask
   do
      null C  # Any?
   while nz  # Yes
      null (X -I)  # In use?
      if nz  # Yes
         call consE_A  # Cons 'tag'
         ld (A) (X -I)
         ld (A CDR) E
         ld E A
         dec C  # Decrement count
      end
      sub X (StkSize)  # Next segment
   loop
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
         null Y  # Any?
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
               call cons_A  # Prepare new cell
               ld C (E)  # Next item already a pair?
               atom C
               if z  # Yes
                  ld (A) (C)  # Copy it
                  ld (A CDR) (C CDR)
               else
                  ld (A) C  # Cons symbol and its value
                  ld (A CDR) (C)
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

# (trail ['flg]) -> lst
(code 'doTrail 2)
   push X
   push Y
   push Z
   ld E ((E CDR))  # Evaluate arg
   eval
   ld Z E  # Keep 'flg' in Z
   ld X (EnvBind)  # Bindings
   ld E Nil  # Result
   do
      null X  # Bindings?
   while nz  # Yes
      ld C (X)  # End of bindings
      null (X -I)  # Env swap zero?
      if z  # Yes
         add X I  # X on bindings
         do
            ld Y (X)  # Next symbol
            add X II  # Next entry
            cmp Y At  # Lambda frame?
            if eq  # Yes
               cmp X C  # Last entry?
               if eq  # Yes
                  call consE_A  # Cons 'exe'
                  ld (A) (C II)
                  ld (A CDR) E
                  ld E A
                  break T
               end
            end
            cmp Z Nil  # 'flg'?
            if ne  # Yes
               call consE_A  # Cons value
               ld (A) (Y)
               ld (A CDR) E
               call consA_E  # Cons symbol
               ld (E) Y
               ld (E CDR) A
               ld (Y) (X -I)  # Set old value
            end
            cmp X C  # More?
         until eq  # No
      end
      ld X (C I)  # Bind link
   loop
   ld X E  # Restore values
   do
      atom X  # More?
   while z  # Yes
      ld Y (X)  # Next entry
      ld X (X CDR)
      atom Y # Symbol?
      if nz  # Yes
         ld (Y) (X)  # Set old value
         ld X (X CDR)
      end
   loop
   pop Z
   pop Y
   pop X
   ret

# (up [cnt] sym ['val]) -> any
(code 'doUp 2)
   push X
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
   cmp X Nil  # NIL?
   if eq  # Yes
      ld X (EnvBind)  # Bindings
      do
         null X  # Any?
      while nz  # Yes
         ld A (X)  # End of bindings in A
         cmp (A -II) At  # Lambda frame?
         if eq  # Yes
            dec C  # Done?
            if z  # Yes
               ld E (A II)  # Return 'exe'
               pop X
               ret
            end
         end
         ld X (A I)  # Bind link
      loop
      ld E Nil  # Return NIL
      pop X
      ret
   end
   push Y
   push Z
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

# (sys 'any ['any]) -> sym
(code 'doSys 2)
   push X
   push Z
   ld X (E CDR)  # X on args
   call evSymX_E  # Evaluate first symbol
   call bufStringE_SZ  # Write to stack buffer
   ld X (X CDR)  # Next arg?
   atom X
   if nz  # No
      cc getenv(S)  # Get value from system
      ld E A
      call mkStrE_E  # Make transient symbol
   else
      push Z
      call evSymX_E  # Evaluate second symbol
      lea X (S I)  # Keep pointer to first buffer
      call bufStringE_SZ  # Write to stack buffer
      cc setenv(X S 1)  # Set system value
      nul4  # OK?
      ldnz E Nil  # No
      ld S Z  # Drop buffer
      pop Z
   end
   ld S Z  # Drop buffer
   pop Z
   pop X
   ret

(code 'circE_EF)
   atom E  # Atom?
   jnz 10  # Yes
   ld A E  # List in A
   do
      or (A) 1  # Mark
      ld A (A CDR)  # Normal list?
      atom A
      if nz  # Yes
         ld A E  # List in A again
         do
            off (A) 1  # Unmark
            ld A (A CDR)
            atom A  # Done?
         until nz  # Yes
10       ret  # 'nz' - No circularity found
      end
      test (A) 1  # Detected circularity?
      if nz  # Yes
         do
            cmp E A  # Skip non-circular part
         while ne
            off (E) 1  # Unmark
            ld E (E CDR)
         loop
         do
            off (A) 1  # Unmark circular part
            ld A (A CDR)
            cmp A E  # Done?
         until eq  # Yes
         ret  # 'eq' - Circularity in E
      end
   loop

### Comparisons ###
(code 'equalAE_F 0)
   cmp A E  # Pointer-equal?
   jeq ret  # Yes: 'eq'
   cnt A  # A short?
   jnz ret  # Yes: 'ne'
   big A  # A big?
   if nz  # Yes
      big E  # E also big?
      jz RetGt  # No: 'ne'
      test A SIGN  # A negative?
      if nz  # Yes
         test E SIGN  # E also negative?
         jz RetGt  # No: 'ne'
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
      jnz RetGt
      sym E
      jz RetGt  # No: 'ne'
      ld A (A TAIL)
      call nameA_A  # Get name of A
      cmp A ZERO  # Any?
      jeq retGt  # No: 'ne'
      ld E (E TAIL)
      call nameE_E  # Get name of E
      cmp E ZERO  # Any?
      jeq retGt  # No: 'ne'
      jmp equalAE_F
   end
   atom E  # E atomic?
   jnz ret  # Yes: 'ne'
   cmp S (StkLimit)  # Stack check
   jlt stkErr
   push X
   push Y
   ld X A  # Keep list heads
   ld Y E
   do
      push A  # Save lists
      push E
      ld A (A)  # Recurse on CARs
      ld E (E)
      off E 1  # Clear possible mark
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
      ld E (E CDR)
      test (A) 1  # Detected circularity?
      if nz
         do
            cmp X A  # Skip non-circular parts
            if eq  # Done
               cmp Y E  # Circular parts same length?
               if eq  # Perhaps
                  do
                     ld X (X CDR)  # Compare
                     ld Y (Y CDR)
                     cmp Y E  # End of second?
                     if eq  # Yes
                        cmp X A  # Also end of first?
                        break T
                     end
                     cmp X A  # End of first?
                     break eq  # Yes
                  loop
               end
               break T
            end
            cmp Y E
            if eq
               gt  # Result "No"
               break T
            end
            off (X) 1  # Unmark
            ld X (X CDR)
            ld Y (Y CDR)
         loop
         push zsc  # Save result
         do
            off (X) 1  # Unmark circular part
            ld X (X CDR)
            cmp X A
         until eq
         pop zsc  # Get result
         pop Y
         pop X
         ret
      end
   loop
   push zsc  # Save result
   do
      cmp X A  # Skip non-circular part
   while ne
      off (X) 1  # Unmark
      ld X (X CDR)
   loop
   pop zsc  # Get result
   pop Y
   pop X
   ret

(code 'compareAE_F 0)  # C
   cmp A E  # Pointer-equal?
   jeq ret  # Yes
   cmp A Nil
   if eq
10    lt  # [NIL E]
      ret
   end
   cmp A TSym
   if eq  # [T E]
20    gt
      ret
   end
   num A  # Number?
   if nz  # Yes
      num E  # Both?
      jnz cmpNumAE_F  # [<num> <num>]
      cmp E Nil
      jeq 20  # [<num> NIL]
      lt  # [<num> <sym|pair>]
      ret
   end
   sym A
   if nz  # [<sym> ..]
      num E
      jnz 20  # [<sym> <num>]
      cmp E Nil
      jeq 20  # [<sym> NIL]
      atom E
      jz 10  # [<sym> <pair>]
      cmp E TSym
      jeq 10  # [<sym> T]
      push X  # [<sym> <sym>]
      ld X (A TAIL)
      call nameX_X  # Get A's name in X
      cmp X ZERO  # Any?
      if eq  # No
         ld X (E TAIL)
         call nameX_X  # Second name in X
         cmp X ZERO  # Any?
         if eq  # No
            cmp A E  # Compare symbol addresses
         else
            lt
         end
         pop X
         ret
      end
      ld E (E TAIL)
      call nameE_E  # Get E's name in E
      cmp E ZERO  # Any?
      if eq  # No
30       gt
40       pop X
         ret
      end
      do
         cnt X  # Get next digit from X into A
         if nz
            ld A X  # Short
            shr A 4  # Normalize
            and A (hex "3FFFFFFFFFFFFFF")  # Mask status bits
            ld X 0
         else
            ld A (X DIG)  # Get next digit
            ld X (X BIG)
         end
         cnt E  # Get next digit from E into C
         if nz
            ld C E  # Short
            shr C 4  # Normalize
            and C (hex "3FFFFFFFFFFFFFF")  # Mask status bits
            ld E 0
         else
            ld C (E DIG)  # Get next digit
            ld E (E BIG)
         end
         do
            cmp B C  # Bytes equal?
            jne 40  # No: lt or gt
            shr A 8  # Next byte in A?
            if z  # No
               shr C 8  # Next byte in C?
               if nz  # Yes
                  lt
                  pop X
                  ret
               end
               null X  # X done?
               if z  # Yes
                  null E  # E also done?
                  jz 40  # Yes: eq
                  lt
                  pop X
                  ret
               end
               null E  # E done?
               jz 30  # Yes: gt
               break T
            end
            shr C 8  # Next byte in C?
            jz 30  # No: gt
         loop
      loop
   end
   atom E
   if nz  # [<pair> <sym>]
      cmp E TSym
      if eq
         lt  # [<pair> T]
         ret
      end
      gt
      ret
   end
   cmp S (StkLimit)  # Stack check
   jlt stkErr
   push X  # [<pair> <pair>]
   push Y
   ld X A  # Keep originals
   ld Y E
   do
      push A  # Recurse on CAR
      push E
      ld A (A)
      ld E (E)
      call compareAE_F  # Same?
      pop E
      pop A
   while eq  # Yes
      ld A (A CDR)  # Next elements
      ld E (E CDR)
      atom A  # End of A?
      if nz  # Yes
         call compareAE_F  # Compare CDRs
         break T
      end
      atom E  # End of E?
      if nz  # Yes
         cmp E TSym
         if ne
            gt  # [<pair> <atom>]
            break T
         end
         lt  # [<pair> T]
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

(code 'binSizeX_A 0)
   cnt X  # Short number?
   if nz  # Yes
      shr X 3  # Normalize short, keep sign bit
      jmp 20
   end
   big X  # Big number?
   if nz  # Yes
      off X SIGN  # Make positive
      ld A 9  # Count 8 significant bytes plus 1
      do
         ld C (X DIG)  # Keep digit
         ld X (X BIG)  # More cells?
         cnt X
      while z  # Yes
         add A 8  # Increment count by 8
      loop
      shr X 4  # Normalize short
      add C C  # Get most significant bit of last digit
      addc X X  # Any significant bits in short number?
      jmp 40
   end
   ld A 1  # Preload 1
   cmp X Nil  # NIL?
   if ne  # No
      sym X  # Symbol?
      if nz  # Yes
         ld X (X TAIL)
         call nameX_X  # Get name
         cmp X ZERO  # Any?
         if ne  # Yes
            cnt X  # Short name?
            if nz  # Yes
               shl X 2  # Strip status bits
               shr X 6  # Normalize
20             ld A 2  # Count significant bytes plus 1
               do
                  shr X 8  # More bytes?
               while nz  # Yes
                  inc A  # Increment count
               loop
               ret
            end
            ld A 9  # Count significant bytes plus 1
            do
               ld X (X BIG)  # More cells?
               cnt X
            while z  # Yes
               add A 8  # Increment count by 8
            loop
            shr X 4  # Any significant bits in short name/number?
40          if nz  # Yes
               do
                  inc A  # Increment count
                  shr X 8  # More bytes?
               until z  # No
            end
            cmp A (+ 63 1)  # More than one chunk?
            if ge  # Yes
               ld X A  # Keep size+1 in X
               sub A 64  # Size-63
               ld C 0  # Divide by 255
               div 255
               lt  # Plus 1
               addc A X  # Plus size+1
            end
         end
         ret
      end
      push X  # <S I> List head
      push 2  # <S> Count
      do
         push (X CDR)  # Save rest
         ld X (X)  # Recurse on CAR
         call binSizeX_A
         pop X
         add (S) A  # Add result to count
         cmp X Nil  # CDR is NIL?
      while ne  # No
         cmp X (S I)  # Circular?
         if eq  # Yes
            inc (S)  # Increment count once more
            break T
         end
         atom X  # Atomic CDR?
         if nz  # Yes
            call binSizeX_A  # Get size
            add (S) A  # Add result to count
            break T
         end
      loop
      pop A  # Get result
      add S I  # Drop list head
   end
   ret

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
      jeq retGt  # Yes
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

### Evaluation ###
# Apply EXPR in C to CDR of E
(code 'evExprCE_E 0)
   cmp S (StkLimit)  # Stack check
   jlt stkErrE
   push X
   push Y
   push Z
   ld X (E CDR)  # Get CDR
   ld Y (C)  # Parameter list in Y
   ld Z (C CDR)  # Body in Z
   push E  # Save 'exe'
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
      add S I  # Drop env swap
      pop L  # Get link
      do  # Unbind symbols
         pop X  # Next symbol
         pop (X)  # Restore value
         cmp S L  # More?
      until eq  # No
      pop L  # Restore link
      pop (EnvBind)  # Restore bind link
      add S I  # Drop 'exe'
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
      add S I  # Drop env swap
      pop L  # Get link
      do  # Unbind symbols
         pop X  # Next symbol
         pop (X)  # Restore value
         cmp S L  # More?
      until eq  # No
      pop L  # Restore link
      pop (EnvBind)  # Restore bind link
      add S I  # Drop 'exe'
      pop Z
      pop Y
      pop X
      ret
   end
   # Evaluated argument list
   link  # Close bind frame
   ld Y L  # Y on frame
   push 0  # Init env swap
   push (EnvArgs)  # Save varArgs base
   atom X  # Any args?
   if nz  # No
      ld (EnvArgs) 0
      push (EnvNext)   # Save current 'next'
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
      link  # Close varArgs frame
      push (EnvNext)   # Save current 'next'
      ld (EnvNext) (L)  # Set new 'next'
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
   pop (EnvNext)   # Restore 'next'
   null (EnvArgs)  # VarArgs?
   if nz  # Yes
      drop  # Drop varArgs
   end
   pop (EnvArgs)  # Restore varArgs base
   add S I  # Drop env swap
   pop L  # Get link
   do  # Unbind symbols
      pop X  # Next symbol
      pop (X)  # Restore value
      cmp S L  # More?
   until eq  # No
   pop L  # Restore link
   pop (EnvBind)  # Restore bind link
   add S I  # Drop 'exe'
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
: evListSym
      do  # C is a symbol
         null (Signal)  # Signal?
         if nz  # Yes
            push E
            call sighandlerE
            pop E
         end
         ld A (C)  # Get VAL
         cnt A  # Short number?
         jnz (A T)  # Yes: Eval SUBR
         big A  # Undefined if bignum
         jnz undefinedCE
         cmp A (A)  # Auto-symbol?
         if ne  # No
            ld C A
            atom C  # Symbol?
            jz evExprCE_E  # No: Apply EXPR
         else
            call sharedLibC_FA  # Try dynamic load
            jnz (A T)  # Eval SUBR
            jmp undefinedCE
         end
      loop
   end
   cmp S (StkLimit)  # Stack check
   jlt stkErr
   push E
   ld E C
   call evListE_E
   ld C E
   pop E
   cnt C  # Short number?
   jnz (C T)  # Yes: Eval SUBR
   big C  # Undefined if bignum
   jnz undefinedCE
   link
   push C  # Save function
   link
   atom C  # Symbol?
   if z
      call evExprCE_E  # No: Apply EXPR
   else
      call evListSym
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
      nul B  # End of string?
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
   jeq 90  # Yes
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
         initLib
         ? *AlignedCode
            or A CNT  # Make short number
         =
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

# (native 'cnt1|sym1 'cnt2|sym2 'any 'any ..) -> any
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
   cmp E TSym  # 'T'?
   if ne  # Yes: Don't call
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
      push (CLink)  # Save Link
      ld (CLink) L
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
               if x  # Sign?
                  neg E  # Yes
               end
            else
               test E SIGN  # Sign?
               if z  # No
                  ld E (E DIG)
               else
                  ld E (E (- DIG SIGN))
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
               else  # Structure
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
                           dec C  # Done?
                        while ns  # No
                           ld (Z) B  # Store byte in buffer
                           inc Z  # Increment buffer pointer
                        loop
                        break T
                     end
                     atom E  # Fill structure?
                  while z  # Yes
                     ld A (E)  # Next value
                     call natBufACZ_CZ  # Store in buffer
                     null C  # Buffer full?
                  until z  # Yes
                  pop Z
               end
            end
         end
         add X I  # Next arg
      loop
      lea X (L -I)  # Top of arguments
      ld Y (Z)  # Get function pointer
      cc (Y) X  # Call C-function
      ld (CLink) (L -I)  # Restore Link
      ld E (Z -II)  # Get result specification
      ld C 0  # No pointer yet
      call natRetACE_CE  # Extract return value
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
10             cc free(X)  # Free string or buffer
            end
         end
         sub Y I
      loop
      ld E (Z -II)  # Get result
      drop
   end
   add S I  # Drop library handle
   pop Z
   pop Y
   pop X
   ret

(code 'natBufACZ_CZ 0)
   atom A  # Byte or unsigned?
   if nz  # Yes
      shr A 4  # Byte?
      if nx  # Yes
         ld (Z) B  # Store byte in buffer
         inc Z  # Increment buffer pointer
         dec C  # Decrement size
         ret
      end
      st4 (Z)  # Store unsigned in buffer
      add Z 4  # Size of unsigned
      sub C 4  # Decrement size
      ret
   end
   # (num|sym . cnt) or ([-]1.0 . lst)
   push X
   ld X (A CDR)  # 'cnt' or 'lst'
   ld A (A)  # 'num', 'sym' or [-]1.0
   cnt X  # 'cnt'?
   if nz  # Yes
      push Y
      ld Y Z  # Y on buffer
      shr X 4  # Normalize length
      add Z X  # Field width
      sub C X  # New buffer size
      num A  # (num . cnt)?
      if nz  # Yes
         cnt A  # Short?
         if nz  # Yes
            shr A 4  # Normalize
            if x  # Sign?
               neg A  # Yes
            end
         else
            test A SIGN  # Sign?
            if z  # No
               ld A (A DIG)
            else
               ld A (A (- DIG SIGN))
               neg A  # Negate
            end
         end
         ? *LittleEndian
            do
               ld (Y) B  # Store byte
               inc Y  # Increment pointer
               shr A 8
               dec X  # Done?
            until z  # Yes
         =
         ? (not *LittleEndian)
            ld Y Z
            do
               dec Y  # Decrement pointer
               ld (Y) B  # Store byte
               shr A 8
               dec X  # Done?
            until z  # Yes
         =
      else
         sym A  # (sym . cnt)?
         if nz  # Yes
            push C
            ld X (A TAIL)  # Get name
            call nameX_X
            ld C 0
            do
               call symByteCX_FACX  # Next byte
            while nz
               ld (Y) B  # Store it
               inc Y  # Increment pointer
            loop
            set (Y) 0  # Null byte
            pop C
         end
      end
      pop Y
   else  # ([-]1.0 . lst)
      do
         atom X  # More fixpoint numbers?
      while z  # Yes
         float  # Convert to floating point
         test A SIGN  # Scale negative?
         if z  # No
            std  # Store double value
            add Z 8  # Size of double
            sub C 8  # Decrement buffer size
         else
            stf  # Store float value
            add Z 4  # Size of float
            sub C 4  # Decrement buffer size
         end
         ld X (X CDR)
      loop
   end
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
               ldd  # Get double value
               add C 8  # Size of double
            else
               ldf  # Get float value
               add C 4  # Size of float
            end
         end
         fixnum  # Get fixpoint number or flg
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
               call boxE_E
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
                           null C  # Primary return value?
                           ldz C A  # Yes: Get into C
                           null C  # Value NULL?
                           ldz E Nil  # Yes: Return NIL
                           if nz
                              push X
                              push Y
                              push Z
                              ld X E  # Get specification in X
                              ld E (X)
                              call natRetACE_CE  # First item
                              cmp E Nil  # NIL?
                              jne 10  # No
                              cmp (X) CSym  # Was it 'C'?
                              if ne  # No
10                               call consE_Y  # Make cell
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
                                          cmp E Nil  # NIL?
                                          if eq  # Yes
                                             cmp (X) CSym  # Was it 'C'?
                                             break eq  # Yes
                                          end
                                          call consE_A  # Cons into cell
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
                                    cmp E Nil  # NIL?
                                    if eq  # Yes
                                       cmp (X) CSym  # Was it 'C'?
                                       break eq  # Yes
                                    end
                                    call consE_A  # Cons into cell
                                    ld (A) E
                                    ld (A CDR) Nil
                                    ld (Y CDR) A  # Append to result
                                    ld Y A
                                 loop
                                 ld E (L I)  # Get result
                                 drop
                              end
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

# (struct 'num 'any 'any ..) -> any
(code 'doStruct 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval native value (pointer or scalar)
   eval
   num E  # Number?
   jz numErrEX  # No
   cnt E  # Short?
   if nz  # Yes
      shr E 4  # Normalize
      ld Z E  # Native value in Z
   else
      ld Z (E DIG)  # Native value in Z
   end
   ld Y (Y CDR)  # Next arg
   ld E (Y)
   eval  # Eval 'any'
   link
   push E  # <L I> Result specification
   link
   push Z  # Save native value
   do
      ld Y (Y CDR)  # Arguments?
      atom Y
   while z  # Yes
      ld E (Y)  # Eval next struct element
      eval
      ld A E  # in A (unused C)
      call natBufACZ_CZ  # Store in buffer
   loop
   pop A  # Get native value
   ld C 0  # No pointer yet
   ld E (L I)  # Result specification
   call natRetACE_CE  # Extract return value
   drop
   pop Z
   pop Y
   pop X
   ret

(code 'fetchCharC_AC 0)
   ld B (C)  # Fetch first byte
   zxt
   null A  # Any?
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

(code 'cbl 0)
   push L  # Save C frame pointer
   ld L (CLink)  # Restore link register
   link  # Apply args
   push (Z I)  # 'fun'
   xchg A E  # First arg
   call boxE_E  # Make number
   push E
   ld E C  # Second arg
   call boxE_E  # Make number
   push E
   ld E A  # Third arg
   call boxE_E  # Make number
   push E
   ld E X  # Fourth arg
   call boxE_E  # Make number
   push E
   ld E Y  # Fifth arg
   call boxE_E  # Make number
   push E
   ld Z S  # Z on last argument
   link  # Close frame
   lea Y (S VI)  # Pointer to 'fun' in Y
   call applyXYZ_E  # Apply
   ld A E  # Return value
   shr A 4  # Normalize
   if x  # Sign?
      neg A  # Yes
   end
   drop
   pop L  # Restore C frame pointer
   return

(code 'cbl1 0)
   begin  # Arguments in A, C, E, X and Y
   lea Z (Lisp)  # Address of callback function
   jmp cbl
: cbl2
   begin
   lea Z (Lisp II)
   jmp cbl
: cbl3
   begin
   lea Z (Lisp (* 2 II))
   jmp cbl
: cbl4
   begin
   lea Z (Lisp (* 3 II))
   jmp cbl
: cbl5
   begin
   lea Z (Lisp (* 4 II))
   jmp cbl
: cbl6
   begin
   lea Z (Lisp (* 5 II))
   jmp cbl
: cbl7
   begin
   lea Z (Lisp (* 6 II))
   jmp cbl
: cbl8
   begin
   lea Z (Lisp (* 7 II))
   jmp cbl
: cbl9
   begin
   lea Z (Lisp (* 8 II))
   jmp cbl
: cbl10
   begin
   lea Z (Lisp (* 9 II))
   jmp cbl
: cbl11
   begin
   lea Z (Lisp (* 10 II))
   jmp cbl
: cbl12
   begin
   lea Z (Lisp (* 11 II))
   jmp cbl
: cbl13
   begin
   lea Z (Lisp (* 12 II))
   jmp cbl
: cbl14
   begin
   lea Z (Lisp (* 13 II))
   jmp cbl
: cbl15
   begin
   lea Z (Lisp (* 14 II))
   jmp cbl
: cbl16
   begin
   lea Z (Lisp (* 15 II))
   jmp cbl
: cbl17
   begin
   lea Z (Lisp (* 16 II))
   jmp cbl
: cbl18
   begin
   lea Z (Lisp (* 17 II))
   jmp cbl
: cbl19
   begin
   lea Z (Lisp (* 18 II))
   jmp cbl
: cbl20
   begin
   lea Z (Lisp (* 19 II))
   jmp cbl
: cbl21
   begin
   lea Z (Lisp (* 20 II))
   jmp cbl
: cbl22
   begin
   lea Z (Lisp (* 21 II))
   jmp cbl
: cbl23
   begin
   lea Z (Lisp (* 22 II))
   jmp cbl
: cbl24
   begin
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
         func
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

(code 'lisp 0)
   begin  # Function name in A, arguments in C, E, X, Y and Z
   push L  # Save C frame pointer
   ld L (CLink)  # Restore link register
   link  # Apply args
   push ZERO  # Space for 'fun'
   xchg C E  # First arg
   call boxE_E  # Make number
   push E
   ld E C  # Second arg
   call boxE_E  # Make number
   push E
   ld E X  # Third arg
   call boxE_E  # Make number
   push E
   ld E Y  # Fourth arg
   call boxE_E  # Make number
   push E
   ld E Z  # Fifth arg
   call boxE_E  # Make number
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
   if x  # Sign?
      neg A  # Yes
   end
   drop
   pop L  # Restore C frame pointer
   return

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
   jnz retEq  # Yes
   big E  # Big number?
   jnz ret  # No
   sym E  # Symbol?
   jnz ret  # Yes
   call circE_EF  # Circular?
   jeq retGt  # Yes
   ld C (E CDR)  # Check function body
   do
      atom C  # More?
   while z  # Yes
      ld A (C)  # Next item
      atom A  # Pair?
      if z  # Yes
         num (A)  # CAR a number?
         if nz  # Yes
            atom (C CDR)  # Must be the last
            jz retGt
         else
            cmp (A) Nil  # CAR is NIL?
            jeq retGt  # Yes
            cmp (A) TSym  # CAR is T?
            jeq retGt  # Yes
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
      call circE_EF  # Circular?
      jeq retGt  # Yes
      ld C E
      do
         atom C  # Atomic parameter?
      while z  # No
         ld A (C)  # Next parameter
         num A  # Number?
         jnz ret  # Yes
         atom A  # List?
         jz retGt  # Yes
         cmp A Nil  # NIL?
         jeq retGt  # Yes
         cmp A TSym  # T?
         jeq retGt  # Yes
         ld C (C CDR)  # Rest
      loop
      cmp C TSym  # T?
      jeq retGt  # Yes
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
   if x  # Sign?
      neg E  # Yes
   end
   ret  # 'z' if null, 's' if negative

(code 'xCntCX_FC 0)
   cnt C  #  # Short number?
   jz cntErrCX  # No
   shr C 4  # Normalize
   if x  # Sign?
      neg C  # Yes
   end
   ret  # 'z' if null, 's' if negative

(code 'xCntAX_FA 0)
   cnt A  #  # Short number?
   jz cntErrAX  # No
   shr A 4  # Normalize
   if x  # Sign?
      neg A  # Yes
   end
   ret  # 'z' if null, 's' if negative

(code 'boxE_E 0)
   null E  # Positive?
   if ns  # Yes
      test E (hex "F000000000000000")  # Fit in short number?
      jnz boxNumE_E  # No
      shl E 4  # Make short number
      or E CNT
      ret
   end
   neg E  # Else negate
   test E (hex "F000000000000000")  # Fit in short?
   if z  # Yes
      shl E 4  # Make negative short number
      or E (| SIGN CNT)
      ret
   end
   call boxNumE_E  # Make bignum
   or E SIGN  # Set negative
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

(code 'begString_S 0)
   tos A  # Get return entry
   link
   push ZERO  # <L I> Result
   ld (StrC) 4  # Build name
   ld (StrX) S
   link
   push (PutB)  # Save 'put'
   ld (PutB) putStringB  # Set new
   jmp (A)  # Return

(code 'endStringS_E 0)
   tos A  # Get return entry
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

? (<> *TargetOS "Linux")
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
=

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
   null Z  # Year <= 0?
   jsz retNil
   null Y  # Month <= 0?
   jsz retNil
   cmp Y 12  # Month > 12?
   jgt retNil
   null X  # Day <= 0?
   jsz retNil
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
      cc gettimeofday(Tv 0)  # Get current time
      cc localtime(Tv)  # Convert to local time
      ld (Time) A  # Keep in 'Time'
      ld C A
      call tmDateC_E  # Extract date
   else
      ld E (Y)  # Eval first
      eval
      cmp E TSym  # T?
      if eq  # Yes
         cc gettimeofday(Tv 0)  # Get current time
         cc gmtime(Tv)  # Convert to Greenwich Mean Time
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
                  if s
                     ld E Nil  # Can't convert date
                     jmp 90
                  end
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
90 pop Z
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
      cc gettimeofday(Tv 0)  # Get current time
      cc localtime(Tv)  # Convert to local time
      ld Y A
      call tmTimeY_E  # Extract time
   else
      ld E (Y)  # Eval first
      eval
      cmp E TSym  # T?
      if eq  # Yes
         ld Y (Time)  # Get time from last call to 'date'
         null Y  # Any?
         ldz E Nil
         if nz  # Yes
            call tmTimeY_E  # Extract time
         end
      else
         cmp E Nil  # NIL?
         if ne  # No
            atom E  # List?
            if z  # Yes
               ld A (E)  # Extract hour
               call xCntAX_FA
               js 90
               mul 3600
               ld Y A
               ld E (E CDR)
               ld A (E)  # minute
               call xCntAX_FA
               js 90
               cmp A 59
               jgt 90
               mul 60
               add Y A
               ld E (E CDR)  # and second
               atom E  # Any?
               ldnz E Y  # No
               if z  # Yes
                  ld E (E)
                  call xCntEX_FE
                  js 90
                  cmp E 60
                  jgt 90
                  add E Y  # add minutes and hours
               end
               shl E 4  # Make short number
               or E CNT
            else
               ld Y (Y CDR)  # More args?
               atom Y
               if nz  # No
                  call xCntEX_FE  # Get time in total seconds
                  js 90
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
                  js 90
                  ld A E
                  mul 3600
                  push A  # Save hour
                  call evCntXY_FE  # Eval minute
                  js 80
                  cmp E 59
                  jgt 80
                  ld A E
                  mul 60
                  add (S) A  # Add to hour
                  ld Y (Y CDR)  # Eval second
                  atom Y  # Any?
                  if z  # Yes
                     call evCntXY_FE
                     js 80
                     cmp E 60
                     jgt 80
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
80 add S I  # Drop partial result
90 ld E Nil  # Can't convert time
   pop Y
   pop X
   ret

# (usec ['flg]) -> num
(code 'doUsec 2)
   ld E ((E CDR))  # Eval arg
   eval
   cmp E Nil  # NIL?
   ldnz E (Tv I)  # No: tv_usec from last 'time' call
   if eq  # Yes
      cc gettimeofday(Tv 0)  # Get time
      ld A (Tv)  # tv_sec
      mul 1000000  # Convert to microseconds
      add A (Tv I)  # tv_usec
      sub A (USec)  # Diff to startup time
      ld E A
   end
   shl E 4  # Make short number
   or E CNT
   ret

# (pwd) -> sym
(code 'doPwd 2)
   cc getcwd(0 GETCWDLEN)  # Get current working directory
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
   cc getcwd(0 GETCWDLEN)  # Get current working directory
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
               ld A ((InFiles))  # InFiles[0] (stdin)
               ld (A I) 0  # Clear 'ix'
               ld (A II) 0  # Clear 'cnt'
               ld (A III) 0  # Clear 'next'
               cc tcgetattr(0 OrgTermio)  # Save terminal I/O
               not B
               ld (Tio) B  # and flag
               ld A ((OutFiles) I)  # OutFiles[1] (stdout)
               ld (A II) 1  # Set 'tty'
               ld (A I) 0  # Clear 'ix'
               ld E TSym  # Return T
            end
         end
      end
      ld S Z  # Drop buffer
      pop Z
   end
   pop X
   ret

# (info 'any ['flg]) -> (cnt|flg dat . tim)
(code 'doInfo 2)
   push X
   push Y
   push Z
   ld X (E CDR)  # Args
   ld E (X)  # Get 'any'
   call evSymE_E  # Evaluate to a symbol
   call pathStringE_SZ  # Write to stack buffer
   ld Y S  # path name pointer
   sub S (%% STAT)  # 'stat' structure
   ld X (X CDR)  # Eval 'flg'
   ld E (X)
   eval
   cmp E Nil  # NIL?
   if eq  # Yes
      cc stat(Y S)  # Get status
   else
      cc lstat(Y S)  # or link status
   end
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
      ld4 (S ST_MODE)  # Get 'st_mode' from 'stat'
      and A S_IFMT
      cmp A S_IFDIR  # Directory?
      if eq  # Yes
         ld (E) TSym  # CAR is T
      else
         cmp A S_IFREG  # Non-regular?
         if ne  # Yes
            ld (E) Nil  # CAR is NIL
         else
            ld A (S ST_SIZE)  # Get size
            shl A 4  # Make short number
            or A CNT
            ld (E) A
         end
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
         cc closedir(Z)  # Close directory
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
