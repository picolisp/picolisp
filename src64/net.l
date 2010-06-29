# 19may10abu
# (c) Software Lab. Alexander Burger

# (port ['T] 'cnt|(cnt . cnt) ['var]) -> cnt
(code 'doPort 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   ld Z SOCK_STREAM  # Type defaults to TCP
   ld E (Y)  # Eval first arg
   eval
   cmp E TSym  # 'T'?
   if eq  # Yes
      ld Z SOCK_DGRAM  # Type UDP
      ld Y (Y CDR)  # Eval next arg
      ld E (Y)
      eval
   end
   cc socket(AF_INET Z 0)  # Create socket
   nul4  # OK?
   js ipSocketErrX  # No
   ld C A  # Keep socket in C
   call closeOnExecAX
   ld B 0  # Clear socket structure
   mset (Addr) SOCKADDR_IN
   ld A AF_INET
   st2 (Addr SIN_FAMILY)
   cc htonl(INADDR_ANY)
   st4 (Addr SIN_ADDR.S_ADDR)
   cnt E  # Single port-argument?
   if nz  # Yes
      shr E 4  # Port zero?
      if nz  # No
         ld A 1  # Socket option value
         st4 (Buf)  # Store into 'optval'
         cc setsockopt(C SOL_SOCKET SO_REUSEADDR Buf 4)  # "Reuse socket" option
         nul4  # OK?
         js ipSetsockoptErrX  # No
      end
      push 0  # <S> No range limit
   else
      atom E  # Port range?
      jnz argErrEX  # No
      ld A (E CDR)  # Get second port
      ld E (E)  # First port
      shr E 4  # Range start
      shr A 4  # Normalize second port
      push A  # <S> Range limit
   end
   do
      cc htons(E)  # Convert port to network order
      st2 (Addr SIN_PORT)  # Store as port
      cc bind(C Addr SOCKADDR_IN)  # Try to bind socket
      nul4  # OK?
   while s  # No
      inc E  # Next port in range
      cmp E (S)  # Exceeded limit?
      if gt  # Yes
         cc close(C)  # Close socket
         jmp ipBindErrX
      end
   loop
   pop A  # Drop range limit
   cmp Z SOCK_STREAM  # TCP socket?
   if eq  # Yes
      cc listen(C 5)  # Mark as server socket
      nul4  # OK?
      if s  # No
         cc close(C)  # Close socket
         jmp ipListenErrX
      end
   end
   ld Z C  # Keep socket in Z
   ld Y (Y CDR)  # Eval 'var'
   ld E (Y)
   eval
   cmp E Nil  # Any?
   if ne  # Yes
      ld A SOCKADDR_IN  # Structure size
      st4 (Buf)  # Store into 'namelen'
      cc getsockname(Z Addr Buf)  # Get socket name
      nul4  # OK?
      if s  # No
         cc close(Z)  # Close socket
         jmp ipGetsocknameErrX
      end
      call needVarEX  # Need variable
      ld2 (Addr SIN_PORT)  # Get port
      cc ntohs(A)  # Convert to host byte order
      shl A 4  # Make short number
      or A CNT
      ld (E) A  # Store in variable
   end
   ld E Z  # Get socket
   shl E 4  # Make short number
   or E CNT
   pop Z
   pop Y
   pop X
   ret

(code 'tcpAcceptA_FE)
   ld E A  # Save socket in E
   call nonblockingA_A  # Set socket to non-blocking
   push A  # Save old socket status flags
   ld A SOCKADDR_IN  # Structure size
   st4 (Buf)  # Store into 'addrlen'
   ld C 200  # Maximally 20 seconds
   do
      cc accept(E Addr Buf)  # Accept connection
      nul4  # OK?
      if nz  # Yes
         xchg A (S)  # Save new socket, retrieve flags
         cc fcntl(E F_SETFL A)  # Restore socket status flags
         ld4 (Addr SIN_ADDR.S_ADDR)  # Get address
         cc inet_ntoa(A)  # Convert to IPv4 dotted-decimal string
         ld E A
         call mkStrE_E  # Make transient symbol
         ld (Adr) E  # Store in '*Adr'
         ld A (S)  # Get socket
         call initInFileA_A  # Init input file
         ld A (S)
         call initOutFileA_A  # and output file
         pop E  # Get new socket
         shl E 4  # Make short number
         or E CNT  # Return 'nz'
         ret
      end
      cc usleep(100000)  # Sleep 100 milliseconds
      dec C  # Done?
   until z  # Yes
   cc fcntl(E F_SETFL pop)  # Restore socket status flags
   setz  # Return 'z'
   ret

# (accept 'cnt) -> cnt | NIL
(code 'doAccept 2)
   push X
   ld X E
   ld E ((E CDR))  # Eval socket descriptor
   call evCntEX_FE
   ld A E  # Accept connection
   call tcpAcceptA_FE  # OK?
   ldz E Nil  # No
   pop X
   ret

# (listen 'cnt1 ['cnt2]) -> cnt | NIL
(code 'doListen 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   call evCntXY_FE  # Eval 'cnt1'
   ld Z E  # Keep socket descriptor in Z
   ld Y (Y CDR)  # Next arg
   ld E (Y)
   eval  # Eval 'cnt2'
   cmp E Nil  # Given?
   ldz Y -1  # No timeout
   if ne  # Yes
      call xCntEX_FE  # Milliseconds
      ld Y E
   end
   do
      ld C Z  # Socket descriptor
      ld E Y  # Milliseconds
      call waitFdCEX_A  # Wait for events
      ld E Nil  # Preload NIL
      null A  # Timeout?
   while nz  # No
      ld A Z  # Accept connection
      call tcpAcceptA_FE  # OK?
   until nz  # Yes
   pop Z
   pop Y
   pop X
   ret

# (host 'any) -> sym
(code 'doHost 2)
   push Z
   ld E ((E CDR))  # Eval IP address
   call evSymE_E
   call bufStringE_SZ  # Write to stack buffer
   cc inet_aton(S Buf)  # Convert to binary form
   ld S Z  # Drop buffer
   pop Z
   nul4  # Valid?
   jz retNil  # No
   cc gethostbyaddr(Buf IN_ADDR AF_INET)  # Get hostent
   null A  # Any?
   jz retNil  # No
   ld E (A H_NAME)
   jmp mkStrE_E  # Make transient symbol

# (connect 'any 'cnt) -> cnt | NIL
(code 'doConnect 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   call evSymY_E  # Eval host
   ld Y (Y CDR)  # Next arg
   call serverEY_F  # Found server?
   jz 80  # No: Return NIL
   cc socket(AF_INET SOCK_STREAM 0)  # Create socket
   nul4  # OK?
   js ipSocketErrX  # No
   ld Y A  # Keep socket in Y
   call closeOnExecAX
   cc connect(Y Addr SOCKADDR_IN)  # Try to connect
   nul4  # OK?
   if ns  # Yes
      ld A Y  # Get socket
      call initInFileA_A  # Init input file
      ld A Y
      call initOutFileA_A  # and output file
      ld E Y  # Return socket
      shl E 4  # Make short number
      or E CNT
   else
      cc close(Y)  # Close socket
80    ld E Nil  # Return NIL
   end
   pop Z
   pop Y
   pop X
   ret

(code 'serverEY_F)
   link
   push E  # <L I> Host
   link
   ld B 0  # Clear socket structure
   mset (Addr) SOCKADDR_IN
   call evCntXY_FE  # Eval port
   cc htons(E)  # Convert to network order
   st2 (Addr SIN_PORT)  # Store as port
   ld A AF_INET
   st2 (Addr SIN_FAMILY)
   ld E (L I)  # Get host
   call bufStringE_SZ  # Write host to stack buffer
   cc inet_aton(S &(Addr SIN_ADDR))  # Convert numbers/dots to binary address
   nul4  # Valid?
   if z  # No
      cc gethostbyname(S)  # Find hostent for given hostname
      null A  # Found?
      jz 90  # No
      ld E A  # Keep hostent pointer in E
      ld4 (E H_LENGTH)  # Length of address?
      nul4
      jz 90  # No
      ld4 (((E H_ADDR_LIST)))  # Take first address
      st4 (Addr SIN_ADDR.S_ADDR)
   end
   clrz  # Return 'nz'
90 ld S Z  # Drop buffer
   drop
   ret

# (udp 'any1 'cnt 'any2) -> any
# (udp 'cnt) -> any
(code 'doUdp 2)
   push X
   push Y
   push Z
   sub S UDPMAX  # Allocate udp buffer
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval  # 'any1' or 'cnt'
   ld Y (Y CDR)  # Next arg?
   atom Y
   if nz  # No
      call xCntEX_FE  # 'cnt'
      cc recv(E S UDPMAX 0)  # Receive message
      null A  # OK?
      js 10  # No
      ld Z S  # Buffer pointer
      lea (BufEnd) (Z UDPMAX)  # Calculate buffer end
      ld (GetBinZ_FB) getUdpZ_FB  # Set binary read function
      ld (Extn) (ExtN)  # Set external symbol offset
      call binReadZ_FE  # Read item?
      if c  # No
10       ld E Nil  # Return NIL
      end
   else
      call serverEY_F  # Found server?
      ldz E Nil  # No
      if nz  # Yes
         ld Y (Y CDR)  # Next arg
         ld E (Y)  # Eval 'any2'
         eval
         ld Y E  # Keep return value in Y
         ld Z S  # Buffer pointer
         lea (BufEnd) (Z UDPMAX)  # Calculate buffer end
         ld (PutBinBZ) putUdpBZ  # Set binary print function
         ld (Extn) (ExtN)  # Set external symbol offset
         call binPrintEZ  # Print item
         cc socket(AF_INET SOCK_DGRAM 0)  # Create socket
         nul4  # OK?
         js ipSocketErrX  # No
         ld C A  # Keep socket in C
         sub Z S  # Data length
         cc sendto(C S Z 0 Addr SOCKADDR_IN)  # Transmit message
         cc close(C)  # Close socket
         ld E Y  # Get return value
      end
   end
   add S UDPMAX  # Drop buffer
   pop Z
   pop Y
   pop X
   ret

(code 'getUdpZ_FB 0)
   cmp Z (BufEnd)  # End of buffer data?
   jeq retc  # Yes: Return 'c'
   ld B (Z)  # Next byte
   add Z 1  # (nc)
   ret

(code 'putUdpBZ 0)
   cmp Z (BufEnd)  # End of buffer data?
   jeq udpOvflErr  # Yes
   ld (Z) B  # Store byte
   inc Z  # Increment pointer
   ret

# vi:et:ts=3:sw=3
