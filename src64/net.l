# 23mar16abu
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
   cc socket(AF_INET6 Z 0)  # Create socket
   nul4  # OK?
   js ipSocketErrX  # No
   ld C A  # Keep socket in C
   call closeOnExecAX
   ? (<> *TargetOS "OpenBSD")
      ld A 0  # Socket option "off"
      st4 (Buf)  # Store into 'optval'
      cc setsockopt(C IPPROTO_IPV6 IPV6_V6ONLY Buf 4)  # "Not only IPv6" option
      nul4  # OK?
      js ipV6onlyErrX  # No
   =
   ld B 0  # Clear socket structure
   mset (Addr) SOCKADDR_IN6
   ld A AF_INET6
   st2 (Addr SIN6_FAMILY)
   ld B 0  # Clear sin6_addr
   mset (Addr SIN6_ADDR) 16  # "::" (16 null-bytes)
   cnt E  # Single port-argument?
   if nz  # Yes
      shr E 4  # Port zero?
      if nz  # No
         ld A 1  # Socket option "on"
         st4 (Buf)  # Store into 'optval'
         cc setsockopt(C SOL_SOCKET SO_REUSEADDR Buf 4)  # "Reuse socket" option
         nul4  # OK?
         js ipReuseaddrErrX  # No
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
      st2 (Addr SIN6_PORT)  # Store as port
      cc bind(C Addr SOCKADDR_IN6)  # Try to bind socket
      nul4  # OK?
   while s  # No
      inc E  # Next port in range
      cmp E (S)  # Exceeded limit?
      if gt  # Yes
         cc close(C)  # Close socket
         jmp ipBindErrX
      end
   loop
   add S I  # Drop range limit
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
      ld A SOCKADDR_IN6  # Structure size
      st4 (Buf)  # Store into 'namelen'
      cc getsockname(Z Addr Buf)  # Get socket name
      nul4  # OK?
      if s  # No
         cc close(Z)  # Close socket
         jmp ipGetsocknameErrX
      end
      call needVarEX  # Need variable
      ld2 (Addr SIN6_PORT)  # Get port
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
   push A  # <S> Old socket status flags
   ld C 200  # Maximally 20 seconds
   do
      ld A SOCKADDR_IN6  # Structure size
      st4 (Buf)  # Store into 'addrlen'
      cc accept(E Addr Buf)  # Accept connection
      nul4  # OK?
      if ns  # Yes
         xchg A (S)  # Save new socket, retrieve flags
         cc fcntl(E F_SETFL A)  # Restore socket status flags
         ? (<> *TargetOS "Linux")  # Non-Linux (BSD sockets)?
            cc fcntl((S) F_SETFL 0)  # Yes: Set new socket to non-blocking
         =
         sub S (%% INET6_ADDRSTRLEN)  # Allocate name buffer
         cc inet_ntop(AF_INET6 &(Addr SIN6_ADDR) S INET6_ADDRSTRLEN)
         ld E S
         call mkStrE_E  # Make transient symbol
         ld (Adr) E  # Store in '*Adr'
         add S (%% INET6_ADDRSTRLEN)  # Drop buffer
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
   eq  # Return 'z'
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
   sub S I  # 'lst' buffer
   call bufStringE_SZ  # Write to stack buffer
   cc getaddrinfo(S 0 0 Z)  # Get address info
   ld S Z  # Drop buffer
   pop Z  # Get 'lst' into Z
   ld E Nil  # Preset return value
   nul4  # Address valid?
   if z  # Yes
      sub S (%% NI_MAXHOST)  # <S> Hostname buffer
      ld C Z  # Get 'lst'
      do
         nulp C  # Any?
      while nz  # Yes
         ld4 (C AI_ADDRLEN)
         cc getnameinfo((C AI_ADDR) A S NI_MAXHOST 0 0 NI_NAMEREQD)
         nul4  # OK?
         if z  # Yes
            ld E S
            call mkStrE_E  # Make transient symbol
            break T
         end
         ld C (C AI_NEXT)  # Try next
      loop
      add S (%% NI_MAXHOST)  # Drop buffer
      cc freeaddrinfo(Z)
   end
   pop Z
   ret

# (connect 'any1 'any2) -> cnt | NIL
(code 'doConnect 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   call evSymY_E  # Eval host
   ld Y (Y CDR)  # Next arg
   ld C SOCK_STREAM
   call serverCEY_FE  # Found server?
   if z  # Yes
      ld Z E  # Keep list in Z
      do
         nulp E  # Any?
      while nz  # Yes
         ld4 (E AI_SOCKTYPE)  # Create socket
         ld C A
         ld4 (E AI_FAMILY)
         cc socket(A C 0)
         nul4  # OK?
         if ns  # Yes
            ld Y A  # Keep socket in Y
            ld4 (E AI_ADDRLEN)
            cc connect(Y (E AI_ADDR) A)  # Try to connect
            nul4  # OK?
            if z  # Yes
               ld A Y
               call closeOnExecAX
               ld A Y  # Get socket
               call initInFileA_A  # Init input file
               ld A Y
               call initOutFileA_A  # and output file
               ld E Y  # Return socket
               shl E 4  # Make short number
               or E CNT
               jmp 80
            end
            cc close(Y)  # Close socket
         end
         ld E (E AI_NEXT)  # Try next
      loop
      ld E Nil  # Return NIL
80    cc freeaddrinfo(Z)
   end
   pop Z
   pop Y
   pop X
   ret

(code 'serverCEY_FE)
   link
   push E  # <L I> Host
   link
   sub S (%% ADDRINFO)  # <S> Hints
   ld B 0  # Clear hints
   mset (S) ADDRINFO
   ld A AF_UNSPEC  # Accept IPv4 and IPv6
   st4 (S AI_FAMILY)  # Store into 'ai_family'
   ld A C  # Get type
   st4 (S AI_SOCKTYPE)  # Store into 'ai_socktype'
   call evSymY_E  # Eval service
   call bufStringE_SZ  # Write to stack buffer
   push Z  # Save pointer to hints
   ld E (L I)  # Get host
   call bufStringE_SZ  # Write to stack buffer
   sub S I  # 'lst' buffer
   cc getaddrinfo(&(S I) &(Z I) (Z) S)  # Get address info
   pop E  # Into 'lst'
   ld S (Z)  # Clean up
   add S (%% ADDRINFO)
   nul4  # Address valid -> 'z'
   ldnz E Nil
   drop
   ret

# (udp 'any1 'any2 'any3) -> any
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
      if lt  # No
10       ld E Nil  # Return NIL
      end
   else
      call xSymE_E  # Host
      ld C SOCK_DGRAM
      call serverCEY_FE  # Found server?
      if z  # Yes
         ld X E  # Keep list in X
         ld Y (Y CDR)  # Next arg
         ld E (Y)  # Eval 'any2'
         eval
         ld Y E  # Keep return value in Y
         ld Z S  # Buffer pointer
         lea (BufEnd) (Z UDPMAX)  # Calculate buffer end
         ld (PutBinBZ) putUdpBZ  # Set binary print function
         ld (Extn) (ExtN)  # Set external symbol offset
         call binPrintEZ  # Print item
         ld E X  # Get list
         do
            nulp E  # Any?
         while nz  # Yes
            ld4 (E AI_SOCKTYPE)  # Create socket
            ld C A
            ld4 (E AI_FAMILY)
            cc socket(A C 0)
            nul4  # OK?
            if ns  # Yes
               ld C A  # Keep socket in C
               sub Z S  # Data length
               ld4 (E AI_ADDRLEN)
               cc sendto(C S Z 0 (E AI_ADDR) A)  # Transmit message
               cc close(C)  # Close socket
               ld E Y  # Get return value
               jmp 80
            end
            ld E (E AI_NEXT)  # Try next
         loop
         ld E Nil  # Return NIL
80       cc freeaddrinfo(X)
      end
   end
   add S UDPMAX  # Drop buffer
   pop Z
   pop Y
   pop X
   ret

(code 'getUdpZ_FB 0)
   cmp Z (BufEnd)  # End of buffer data?
   jeq retLt  # Yes: Return 'lt'
   ld B (Z)  # Next byte
   add Z 1  # (gt)
   ret

(code 'putUdpBZ 0)
   cmp Z (BufEnd)  # End of buffer data?
   jeq udpOvflErr  # Yes
   ld (Z) B  # Store byte
   inc Z  # Increment pointer
   ret

# vi:et:ts=3:sw=3
