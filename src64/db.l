# 27may16abu
# (c) Software Lab. Alexander Burger

# 6 bytes in little endian format
# Get block address from buffer
(code 'getAdrZ_A 0)
   ld B (Z 5)  # Highest byte
   zxt
   shl A 8
   ld B (Z 4)
   shl A 8
   ld B (Z 3)
   shl A 8
   ld B (Z 2)
   shl A 8
   ld B (Z 1)
   shl A 8
   ld B (Z)  # Lowest byte
   ret

# Set block address in buffer
(code 'setAdrAZ 0)
   ld (Z) B  # Lowest byte
   shr A 8
   ld (Z 1) B
   shr A 8
   ld (Z 2) B
   shr A 8
   ld (Z 3) B
   shr A 8
   ld (Z 4) B
   shr A 8
   ld (Z 5) B  # Highest byte
   ret

# Read file number from 'Buf' into 'DbFile'
(code 'dbfBuf_AF 0)
   ld B (Buf 1)  # Two bytes little endian
   zxt
   shl A 8
   ld B (Buf)
   shl A 6  # 'dbFile' index
   cmp A (DBs)  # Local file?
   jge retEq  # No: 'z'
   add A (DbFiles)  # Get DB file
   ld (DbFile) A  # Set current
   ret  # 'nz'

# Build external symbol name
(code 'extNmCE_X 0)
   ld X C  # Get object ID into X
   and X (hex "FFFFF")  # Lowest 20 bits
   shr C 20  # Middle part of object ID
   ld A C
   and A (hex "FFF")  # Lowest 12 bits
   shl A 28
   or X A  # into X
   shr C 12  # Rest of object ID
   shl C 48
   or X C  # into X
   ld A E  # Get file number
   and A (hex "FF")  # Lowest 8 bits
   shl A 20  # Insert
   or X A  # into X
   shr E 8  # Rest of file number
   shl E 40
   or X E  # into X
   shl X 4  # Make short name
   or X CNT
   ret

# Pack external symbol name
(code 'packExtNmX_E)
   link
   push ZERO  # <L I> Name
   link
   call fileObjX_AC  # Get file and object ID
   push C  # Save object ID
   ld C 4  # Build name
   lea X (L I)
   null A  # Any?
   if nz  # Yes
      call packAoACX_CX  # Pack file number
   end
   pop A  # Get object ID
   call packOctACX_CX  # Pack it
   call cons_E  # Cons symbol
   ld (E) (L I)  # Set name
   or E SYM  # Make symbol
   ld (E) E  # Set value to itself
   drop
   ret

(code 'packAoACX_CX 0)
   cmp A 15  # Single digit?
   if gt  # No
      push A  # Save
      shr A 4  # Divide by 16
      call packAoACX_CX  # Recurse
      pop A
      and B 15  # Get remainder
   end
   add B (char "@")  # Make ASCII letter
   jmp byteSymBCX_CX  # Pack byte

(code 'packOctACX_CX 0)
   cmp A 7  # Single digit?
   if gt  # No
      push A  # Save
      shr A 3  # Divide by 8
      call packOctACX_CX  # Recurse
      pop A
      and B 7  # Get remainder
   end
   add B (char "0")  # Make ASCII digit
   jmp byteSymBCX_CX  # Pack byte

# Chop external symbol name
(code 'chopExtNmX_E)
   call fileObjX_AC  # Get file and object ID
   ld X A  # Keep file in X
   call oct3C_CA  # Get lowest octal digits
   call consA_E  # Final cell
   ld (E) A
   ld (E CDR) Nil
   link
   push E  # <L I> Result
   link
   do
      shr C 3  # Higher octal digits?
   while nz  # Yes
      call oct3C_CA  # Get next three digits
      call consA_E  # Cons into result
      ld (E) A
      ld (E CDR) (L I)
      ld (L I) E
   loop
   null X  # File number?
   if nz  # Yes
      ld E 0  # Build A-O encoding
      ld A 0
      do
         ld B X  # Next hax digit
         and B 15  # Lowest four bits
         add B (char "@")  # Make ASCII letter
         or E B
         shr X 4  # More hax digits?
      while nz  # Yes
         shl E 8  # Shift result
      loop
      shl E 4  # Make short name
      or E CNT
      call cons_A  # Make transient symbol
      ld (A) E  # Set name
      or A SYM  # Make symbol
      ld (A) A  # Set value to itself
      call consA_E  # Cons into result
      ld (E) A
      ld (E CDR) (L I)
      ld (L I) E
   end
   ld E (L I)  # Get result
   drop
   ret

(code 'oct3C_CA 0)
   ld A 0
   ld B C  # Lowest octal digit
   and B 7
   add B (char "0")  # Make ASCII digit
   ld E A
   shr C 3  # Next digit?
   if nz  # Yes
      ld B C  # Second octal digit
      and B 7
      add B (char "0")  # Make ASCII digit
      shl E 8
      or E B
      shr C 3  # Next digit?
      if nz  # Yes
         ld B C  # Hightest octal digit
         and B 7
         add B (char "0")  # Make ASCII digit
         shl E 8
         or E B
      end
   end
   shl E 4  # Make short name
   or E CNT
   call cons_A  # Make transient symbol
   ld (A) E  # Set name
   or A SYM  # Make symbol
   ld (A) A  # Set value to itself
   ret

# Get file and object ID from external symbol name
(code 'fileObjX_AC 0)
   shl X 2  # Strip status bits
   shr X 6  # Normalize
   ld C X  # Get object ID
   and C (hex "FFFFF")  # Lowest 20 bits
   shr X 20  # Get file number
   ld A X
   and A (hex "FF")  # Lowest 8 bits
   shr X 8  # More?
   if nz  # Yes
      ld E X  # Rest in E
      and E (hex "FFF")  # Middle 12 bits of object ID
      shl E 20
      or C E  # into C
      shr X 12  # High 8 bits of file number
      ld E X  # into E
      and E (hex "FF")  # Lowest 8 bits
      shl E 8
      or A E  # into A
      shr X 8  # Rest of object ID
      shl X 32
      or C X  # into C
   end
   ret

# Get file and object ID from external symbol
(code 'fileObjE_AC 0)
   push X
   ld X (E TAIL)
   call nameX_X  # Get name
   call fileObjX_AC
   pop X
   ret

# Get dbFile index and block index from external symbol
(code 'dbFileBlkY_AC 0)
   push X
   ld X Y  # Name in X
   call fileObjX_AC
   shl A 6  # 'dbFile' index
   shl C 6  # Block index
   pop X
   ret

(code 'rdLockDb)
   cmp (Solo) TSym  # Already locked whole DB?
   jeq ret  # Yes
   ld A (| F_RDLCK (hex "10000"))  # Read lock, length 1
   ld C ((DbFiles))  # Descriptor of first file
   jmp lockFileAC

(code 'wrLockDb)
   cmp (Solo) TSym  # Already locked whole DB?
   jeq ret  # Yes
   ld A (| F_WRLCK (hex "10000"))  # Write lock, length 1
   ld C ((DbFiles))  # Descriptor of first file
   jmp lockFileAC

(code 'rwUnlockDbA)
   cmp (Solo) TSym  # Already locked whole DB?
   jeq ret  # Yes
   null A  # Length zero?
   if z  # Yes
      push X
      push Y
      ld X (DbFiles)  # Iterate DB files
      ld Y (DBs)  # Count
      do
         sub Y VIII  # Done?
      while ne  # No
         add X VIII  # Skip first, increment by sizeof(dbFile)
         nul (X (+ IV 0))  # This one locked?
         if nz  # Yes
            ld A (| F_UNLCK (hex "00000"))  # Unlock, length 0
            ld C (X)  # File descriptor
            call unLockFileAC
            set (X (+ IV 0)) 0  # Clear lock entry
         end
      loop
      pop Y
      pop X
      ld (Solo) ZERO  # Reset solo mode
      ld A 0  # Length zero again
   end
   or A F_UNLCK
   ld C ((DbFiles))  # Unlock first file
   jmp unLockFileAC

(code 'tryLockCE_FA)
   do
      ld A F_WRLCK  # Write lock
      st2 (Flock L_TYPE)  # 'l_type'
      ld (Flock L_START) C  # Start position ('l_whence' is SEEK_SET)
      ld (Flock L_LEN) E  # Length
      cc fcntl(((DbFile)) F_SETLK Flock)  # Try to lock
      nul4  # OK?
      if ns  # Yes
         set ((DbFile) (+ IV 0)) 1  # Set lock flag
         null C  # 'Start position is zero?
         if z  # Yes
            ld (Solo) TSym  # Set solo mode
         else
            cmp (Solo) TSym  # Already locked whole DB?
            if ne  # No
               ld (Solo) Nil  # Clear solo mode
               eq
            end
         end
         ret  # 'z'
      end
      call errno_A
      cmp A EINTR  # Interrupted?
      if ne  # No
         cmp A EACCES  # Locked by another process?
         if ne  # No
            cmp A EAGAIN  # Memory-mapped by another process?
            jne lockErr  # No
         end
      end
      do
         cc fcntl(((DbFile)) F_GETLK Flock)  # Try to get lock
         nul4  # OK?
      while s  # No
         call errno_A
         cmp A EINTR  # Interrupted?
         jne lockErr  # No
      loop
      ld2 (Flock L_TYPE)  # Get 'l_type'
      cmp B F_UNLCK  # Locked by another process?
   until ne  # Yes
   ld4 (Flock L_PID)  # Return PID
   ret  # 'nz'

(code 'jnlFileno_A)
   cc fileno((DbJnl))  # Get fd
   ret

(code 'logFileno_A)
   cc fileno((DbLog))  # Get fd
   ret

(code 'lockJnl)
   call jnlFileno_A  # Get fd
   ld C A  # into C
   jmp wrLockFileC  # Write lock journal

(code 'unLockJnl)
   cc fflush((DbJnl))  # Flush journal
   call jnlFileno_A  # Get fd
   ld C A  # into C
   ld A (| F_UNLCK (hex "00000"))  # Unlock, length 0
   jmp unLockFileAC  # Unlock journal

(code 'setBlockAC_Z 0)
   add A (DbFiles)  # Get DB file
: setBlkAC_Z
   ld (DbFile) A  # Set current
   ld (BlkIndex) C  # Set block index
   ld A (A III)  # Block size
   ld Z (DbBlock)  # Get block buffer in Z
   add A Z  # Caclulate data end
   ld (BufEnd) A
   ret

(code 'rdBlockLinkZ_Z)
   ld A (BlkLink)  # Next block
(code 'rdBlockIndexAZ_Z)
   ld (BlkIndex) A  # Set block index
   ld Z (DbBlock)  # Block buffer in Z
(code 'rdBlockZ_Z)
   ld A (DbFile)  # Get current file
   ld C (A III)  # Block size
   ld E (BlkIndex)  # Get block index in E
   shl E (A II)  # Shift for current file
   call blkPeekCEZ  # Read block
   call getAdrZ_A  # Get link address
   off A BLKTAG
   ld (BlkLink) A  # Store as next block
   add Z BLK  # Point to block data
   ret

(code 'blkPeekCEZ)
   cc pread(((DbFile)) Z C E)  # Read C bytes from pos E into buffer Z
   cmp A C  # OK?
   jne dbRdErr  # No
   ret

(code 'wrBlockZ)
   ld A (DbFile)  # Get current file
   ld C (A III)  # Block size
   ld E (BlkIndex)  # Get block index in E
   shl E (A II)  # Shift for current file
(code 'blkPokeCEZ)
   cc pwrite(((DbFile)) Z C E)  # Write C bytes from buffer Z to pos E
   cmp A C  # OK?
   jne dbWrErr  # No
   null (DbJnl)  # Journal?
   if nz  # Yes
      cmp A ((DbFile) III)  # Size (in A and C) equal to current file's block size?
      if eq  # Yes
         ld A BLKSIZE  # Use block unit size instead
      end
      cc putc_unlocked(A (DbJnl))  # Write size
      sub S (+ BLK 2)  # <S> Buffer
      ld A ((DbFile) I)  # Get file number
      ld (S) B  # Store low byte
      shr A 8
      ld (S 1) B  # and high byte
      ld A E  # Get position
      shr A ((DbFile) II)  # Un-shift for current file
      ld (S 2) B  # Set block address in buffer
      shr A 8
      ld (S 3) B
      shr A 8
      ld (S 4) B
      shr A 8
      ld (S 5) B
      shr A 8
      ld (S 6) B
      shr A 8
      ld (S 7) B  # Highest byte
      cc fwrite(S (+ BLK 2) 1 (DbJnl))  # Write file number and address
      cmp A 1  # OK?
      jne wrJnlErr  # No
      cc fwrite(Z C 1 (DbJnl))  # Write C bytes from buffer Z
      cmp A 1  # OK?
      jne wrJnlErr  # No
      add S (+ BLK 2)  # Drop buffer
   end
   ret

(code 'logBlock)
   sub S (+ BLK 2)  # <S> Buffer
   ld A ((DbFile) I)  # Get file number
   ld (S) B  # Store low byte
   shr A 8
   ld (S 1) B  # and high byte
   ld A (BlkIndex)  # Get block index in E
   ld (S 2) B  # Write into buffer
   shr A 8
   ld (S 3) B
   shr A 8
   ld (S 4) B
   shr A 8
   ld (S 5) B
   shr A 8
   ld (S 6) B
   shr A 8
   ld (S 7) B  # Highest byte
   cc fwrite(S (+ BLK 2) 1 (DbLog))  # Write file number and address
   cmp A 1  # OK?
   jne wrLogErr  # No
   cc fwrite((DbBlock) ((DbFile) III) 1 (DbLog))  # Write 'siz' bytes from block buffer
   cmp A 1  # OK?
   jne wrLogErr  # No
   add S (+ BLK 2)  # Drop buffer
   ret

(code 'newBlock_X)
   push Z
   ld C (* 2 BLK)  # Read 'free' and 'next'
   ld E 0  # from block zero
   ld Z Buf  # into 'Buf'
   call blkPeekCEZ
   call getAdrZ_A  # 'free'?
   null A
   jz 10  # No
   null ((DbFile) VII)  # 'fluse'?
   if nz  # Yes
      ld X A  # Keep 'free' in X
      ld C (DbFile)
      shl A (C II)  # Shift 'free'
      dec (C VII)  # Decrement 'fluse'
      ld E A  # Read 'free' link
      ld C BLK
      call blkPeekCEZ  # into 'Buf'
      ld E 0  # Restore block zero in E
      ld C (* 2 BLK)  # and poke size in C
   else
10    add Z BLK  # Get 'next'
      call getAdrZ_A
      cmp A (hex "FFFFFFFFFFC0")  # Max object ID
      jeq dbSizErr  # DB Oversize
      ld X A  # Keep in X
      add A BLKSIZE  # Increment 'next'
      call setAdrAZ
      sub Z BLK  # Restore 'Buf' in Z
   end
   call blkPokeCEZ  # Write 'Buf' back
   ld C ((DbFile) III)  # Current file's block size
   sub S C  # <S> Buffer
   ld B 0  # Clear buffer
   mset (S) C  # with block size
   ld E X  # Get new block address
   shl E ((DbFile) II)  # Shift it
   ld Z S  # Write initblock
   call blkPokeCEZ
   add S ((DbFile) III)  # Drop buffer
   pop Z
   ret

(code 'newIdEX_X)
   dec E  # Zero-based
   shl E 6  # 'dbFile' index
   cmp E (DBs)  # In Range?
   jge dbfErrX  # No
   add E (DbFiles)  # Get DB file
   ld (DbFile) E  # Set current
   null (DbLog)  # Transaction log?
   if z  # No
      inc (EnvProtect)  # Protect the operation
   end
   call wrLockDb  # Write lock DB
   null (DbJnl)  # Journal?
   if nz  # Yes
      call lockJnl  # Write lock journal
   end
   call newBlock_X  # Allocate new block
   ld C X  # Object ID
   shr C 6  # Normalize
   ld E ((DbFile) I)  # Get file number
   call extNmCE_X  # Build external symbol name
   null (DbJnl)  # Journal?
   if nz  # Yes
      call unLockJnl  # Unlock journal
   end
   ld A (hex "10000")  # Length 1
   call rwUnlockDbA  # Unlock
   null (DbLog)  # Transaction log?
   if z  # No
      dec (EnvProtect)  # Unprotect
   end
   ret

(code 'isLifeE_F)
   push E  # Save symbol
   call fileObjE_AC  # Get file and ID
   pop E  # Restore symbol
   shl C 6  # Block index?
   jz retGt  # No
   shl A 6  # 'dbFile' index
   cmp A (DBs)  # Local file?
   if lt  # Yes
      add A (DbFiles)  # Get DB file
      ld (DbFile) A  # Set current
      ld A (E TAIL)  # Get tail
      call nameA_A  # Get name
      add A A  # Dirty?
      jc retEq  # Yes
      add A A  # Loaded?
      jc RetEq  # Yes
      push E
      push Z
      push C  # Save block index
      ld C BLK  # Read 'next'
      ld E BLK
      ld Z Buf  # into 'Buf'
      call blkPeekCEZ
      call getAdrZ_A  # Get 'next'
      pop C  # Get block index
      cmp C A  # Less than 'next'?
      if ge  # No
         gt  # 'nz'
         jmp 90
      end
      ld E C  # Block index
      shl E ((DbFile) II)  # Shift
      ld C BLK  # Read link field
      call blkPeekCEZ  # into 'Buf'
      ld B (Z)  # Get tag byte
      and B BLKTAG  # Block tag
      cmp B 1  # One?
90    pop Z
      pop E
   else
      atom (Ext)  # Extended databases?
   end
   ret  # 'z' if OK

(code 'cleanUpY)
   ld C BLK  # Read 'free'
   ld E 0  # from block zero
   ld Z Buf  # into 'Buf'
   call blkPeekCEZ
   call getAdrZ_A  # Get 'free'
   push A  # Save 'free'
   ld A Y  # Deleted block
   call setAdrAZ  # Store in buffer
   call blkPokeCEZ  # Set new 'free'
   ld E Y  # Deleted block
   do
      shl E ((DbFile) II)  # Shift it
      call blkPeekCEZ  # Get block link
      off (Z) BLKTAG  # Clear tag
      call getAdrZ_A  # Get link
      null A  # Any?
   while nz  # Yes
      ld Y A  # Keep link in Y
      call blkPokeCEZ  # Write link
      ld E Y  # Get link
   loop
   pop A  # Retrieve 'free'
   call setAdrAZ  # Store in buffer
   jmp blkPokeCEZ  # Append old 'free' list

(code 'getBlockZ_FB 0)
   cmp Z (BufEnd)  # End of block data?
   if eq  # Yes
      ld A (BlkLink)  # Next block?
      null A
      jz ret  # No: Return 'z'
      push C
      push E
      call rdBlockIndexAZ_Z  # Read block
      pop E
      pop C
   end
   ld B (Z)  # Next byte
   add Z 1  # 'nz'
   ret

(code 'putBlockBZ 0)
   cmp Z (BufEnd)  # End of block data?
   if eq  # Yes
      push A  # Save byte
      push C
      push E
      ld Z (DbBlock)  # Block buffer
      null (BlkLink)  # Next block?
      if nz  # Yes
         call wrBlockZ  # Write current block
         call rdBlockLinkZ_Z  # Read next block
      else
         push X
         call newBlock_X  # Allocate new block
         ld B (Z)  # Get block count (link is zero)
         zxt
         push A  # Save count
         or A X  # Combine with new link
         call setAdrAZ  # Store in current block
         call wrBlockZ  # Write current block
         ld (BlkIndex) X  # Set new block index
         pop A  # Retrieve count
         cmp A BLKTAG  # Max reached?
         if ne  # No
            inc A  # Increment count
         end
         call setAdrAZ  # Store in new current block
         add Z BLK  # Point to block data
         pop X
      end
      pop E
      pop C
      pop A  # Retrieve byte
   end
   ld (Z) B  # Store byte
   inc Z  # Increment pointer
   ret

# (pool ['sym1 ['lst] ['sym2] ['sym3]]) -> T
(code 'doPool 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   call evSymY_E  # Eval database name
   link
   push E  # <L IV> 'sym1'
   ld Y (Y CDR)
   ld E (Y)  # Eval scale factor list
   eval+
   push E  # <L III> 'lst'
   link
   cmp E Nil  # Need list
   if ne
      atom E
      jnz lstErrEX
   end
   ld Y (Y CDR)
   call evSymY_E  # Eval replication journal
   tuck E  # <L II> 'sym2'
   link
   ld Y (Y CDR)
   call evSymY_E  # Eval transaction log
   tuck E  # <L I> 'sym3'
   link
   ld (Solo) ZERO  # Reset solo mode
   null (DBs)  # DB open?
   if nz  # Yes
      call doRollback  # Roll back possible changes
      ld E (DbFiles)  # Iterate DB files
      ld C (DBs)  # Count
      do
         ld A (E)  # File descriptor
         call closeAX  # Close it
         cc free((E VI))  # Free mark bit vector
         add E VIII  # Increment by sizeof(dbFile)
         sub C VIII  # Done?
      until z  # Yes
      ld (DBs) 0
      null (DbJnl)  # Journal?
      if nz  # Yes
         cc fclose((DbJnl))  # Close it
         ld (DbJnl) 0
      end
      null (DbLog)  # Transaction log?
      if nz  # Yes
         cc fclose((DbLog))  # Close it
         ld (DbLog) 0
      end
   end
   ld E (L IV)  # Database name
   cmp E Nil  # Given?
   if ne  # Yes
      push A  # 8 bytes additional buffer space
      call pathStringE_SZ  # <S II> DB name
      slen C S  # String length in C
      add C S  # Add to buffer
      push C  # <S I> DB name end pointer
      ld E VIII  # Default to single dbFile
      ld A (L III)  # Get scale factor list
      atom A  # Any?
      if z  # Yes
         ld E 0  # Calculate length
         do
            add E VIII  # Increment by sizeof(dbFile)
            ld A (A CDR)
            atom A  # More cells?
         until nz  # No
      end
      ld A (DbFiles)  # DB file structure array
      call allocAE_A  # Set to new size
      ld (DbFiles) A
      ld Y A  # Index in Y
      add A E
      push A  # <S> Limit
      ld (MaxBlkSize) 0  # Init block size maximum
      do
         ld C (S I)  # Get DB name end pointer
         ld A Y  # Get index
         sub A (DbFiles)
         shr A 6  # Revert to file number
         ld (Y I) A  # Store in 'dbFile'
         atom (L III)  # Scale factor list?
         if z  # Yes
            call bufAoAC_C  # Append AO encoding to DB base name
         end
         set (C) 0  # Null-byte string terminator
         ld A (L III)  # Scale factor list
         ld (L III) (A CDR)
         ld A (A)  # Next scale factor
         cnt A  # Given?
         ldz A 2  # No: Default to 2
         if nz
            shr A 4  # Else normalize
         end
         ld (Y II) A  # Set block shift
         ld (DbFile) Y  # Set current file
         cc open(&(S II) O_RDWR)  # Try to open
         nul4  # OK?
         if ns  # Yes
            ld (Y) A  # Set file descriptor
            ld C (+ BLK BLK 1)  # Read block shift
            ld E 0  # from block zero
            ld Z Buf  # into 'Buf'
            call blkPeekCEZ
            ld B (Z (+ BLK BLK))  # Get block shift
            ld (Y II) B  # Override argument block shift
            ld C BLKSIZE  # Calculate block size
            shl C B
            ld (Y III) C  # Set in dbFile
         else
            ld E (L IV)  # Database name (if error)
            call errno_A
            cmp A ENOENT  # Non-existing?
            jne openErrEX  # No
            cc open(&(S II) (| O_CREAT O_EXCL O_RDWR) (oct "0666"))  # Try to create
            nul4  # OK?
            js openErrEX  # No
            ld (Y) A  # Set file descriptor
            ld C BLKSIZE  # Calculate block size
            shl C (Y II)
            ld (Y III) C  # Set in dbFile
            sub S C  # <S> Buffer
            ld B 0  # Clear buffer
            mset (S) C  # with block size
            ld E 0  # Position of DB block zero
            lea Z (S BLK)  # Address of 'next' in buffer
            cmp Y (DbFiles)  # First file?
            if ne  # No
               ld A BLKSIZE  # Only block zero
            else
               ld A (* 2 BLKSIZE)  # Block zero plus DB root
            end
            call setAdrAZ  # into 'next'
            ld Z S  # Buffer address
            set (Z (* 2 BLK)) (Y II)  # Set block shift in block zero
            call blkPokeCEZ  # Write DB block zero
            cmp Y (DbFiles)  # First file?
            if eq  # Yes
               ld (S) 0  # Clear 'next' link in buffer
               ld (S I) 0
               ld Z S  # Address of 'link' in buffer
               ld A 1  # First block for DB root
               call setAdrAZ  # into link field
               ld E (Y III)  # Second block has block size position
               call blkPokeCEZ  # Write first ID-block (DB root block)
            end
            add S (Y III)  # Drop buffer
         end
         ld A (Y)  # Get fd
         call closeOnExecAX
         ld A (Y III)  # Block size
         cmp A (MaxBlkSize)  # Calculate maximum
         if gt
            ld (MaxBlkSize) A
         end
         ld (Y IV) 0  # Clear 'flgs'
         ld (Y V) 0  # mark vector size
         ld (Y VI) 0  # and mark bit vector
         ld (Y VII) -1  # Init 'fluse'
         add Y VIII  # Increment index by sizeof(dbFile)
         ld A Y  # Get index
         sub A (DbFiles)  # Advanced so far
         ld (DBs) A  # Set new scaled DB file count
         cmp Y (S)  # Done?
      until eq  # Yes
      ld A (DbBlock)  # Allocate block buffer
      ld E (MaxBlkSize)  # for maximal block size
      call allocAE_A
      ld (DbBlock) A
      ld E (L II)  # Replication journal?
      cmp E Nil
      if ne  # Yes
         call pathStringE_SZ  # Write journal to stack buffer
         cc fopen(S _a_)  # Open for appending
         ld S Z  # Drop buffer
         null A  # OK?
         jz openErrEX  # No
         ld (DbJnl) A
         call jnlFileno_A  # Get fd
         call closeOnExecAX
      end
      ld E (L I)  # Transaction log?
      cmp E Nil
      if ne  # Yes
         call pathStringE_SZ  # Write journal to stack buffer
         cc fopen(S _ap_)  # Open for reading and appending
         ld S Z  # Drop buffer
         null A  # OK?
         jz openErrEX  # No
         ld (DbLog) A
         call logFileno_A  # Get fd
         call closeOnExecAX
         call rewindLog  # Test for existing transaction
         cc fread(Buf 2 1 (DbLog))  # Read first file number
         null A  # Any?
         if nz  # Yes
            cc feof((DbLog))  # EOF?
            nul4
            if z  # No
               call ignLog  # Discard incomplete transaction
            else
               do
                  ld2 (Buf)  # Get file number (byte order doesn't matter)
                  cmp A (hex "FFFF")  # End marker?
                  if eq  # Yes
                     cc fprintf((stderr) RolbLog)  # Rollback incomplete transaction
                     call rewindLog  # Rewind transaction log
                     ld E (DbFiles)  # Iterate DB files
                     ld C (DBs)  # Count
                     do
                        set (E (+ IV 1)) 0  # Clear dirty flag
                        add E VIII  # Increment by sizeof(dbFile)
                        sub C VIII  # Done?
                     until z  # Yes
                     sub S (MaxBlkSize)  # <S> Buffer
                     do
                        cc fread(Buf 2 1 (DbLog))  # Read file number
                        null A  # Any?
                        jz jnlErrX  # No
                        ld2 (Buf)  # Get file number (byte order doesn't matter)
                        cmp A (hex "FFFF")  # End marker?
                     while ne  # No
                        call dbfBuf_AF  # Read file number from 'Buf' to 'DbFile'
                        jz jnlErrX  # No local file
                        cc fread(Buf BLK 1 (DbLog))  # Read object ID
                        cmp A 1  # OK?
                        jne jnlErrX  # No
                        cc fread(S ((DbFile) III) 1 (DbLog))  # Read block data
                        cmp A 1  # OK?
                        jne jnlErrX  # No
                        ld Z Buf  # Get object ID from 'Buf'
                        call getAdrZ_A
                        shl A ((DbFile) II)  # Shift
                        ld C ((DbFile) III)  # Block size
                        cc pwrite(((DbFile)) S C A)  # Write C bytes from stack buffer to pos A
                        cmp A C  # OK?
                        jne dbWrErr
                        set ((DbFile) (+ IV 1)) 1  # Set dirty flag
                     loop
                     add S (MaxBlkSize)  # Drop buffer
                     call fsyncDB  # Sync DB files to disk
                     break T
                  end
                  call dbfBuf_AF  # Read file number from 'Buf' into 'DbFile'
                  jz 40  # No local file
                  cc fread(Buf BLK 1 (DbLog))  # Read object ID
                  cmp A 1  # OK?
                  jne 40  # No
                  cc fseek((DbLog) ((DbFile) III) SEEK_CUR)  # Skip by 'siz'
                  nul4  # OK?
                  jnz 40  # No
                  cc fread(Buf 2 1 (DbLog))  # Read next file number
                  cmp A 1  # OK?
                  if nz  # No
40                   call ignLog  # Discard incomplete transaction
                     break T
                  end
               loop
            end
         end
         call truncLog  # Truncate log file
      end
   end
   drop
   pop Z
   pop Y
   pop X
   ld E TSym  # Return T
   ret

(code 'ignLog)
   cc fprintf((stderr) IgnLog)
   ret

(code 'rewindLog)
   cc fseek((DbLog) 0 SEEK_SET)  # Rewind transaction log
   ret

(code 'fsyncDB)
   ld E (DbFiles)  # Iterate DB files
   ld C (DBs)  # Count
   do
      nul (E (+ IV 1))  # Dirty?
      if nz  # Yes
         cc fsync((E))  # Sync DB file to disk
         nul4  # OK?
         js dbSyncErrX  # No
      end
      add E VIII  # Increment by sizeof(dbFile)
      sub C VIII  # Done?
   until z  # Yes
   ret

(code 'truncLog)
   call rewindLog  # Rewind transaction log
   call logFileno_A  # Get fd
   cc ftruncate(A 0)  # Truncate log file
   nul4  # OK?
   jnz truncErrX
   ret

# Append A-O encoding to string
(code 'bufAoAC_C 0)
   cmp A 15  # Single digit?
   if gt  # No
      push A  # Save
      shr A 4  # Divide by 16
      call bufAoAC_C  # Recurse
      pop A
      and B 15  # Get remainder
   end
   add B (char "@")  # Make ASCII letter
   ld (C) B  # Store in buffer
   inc C
   ret

# (journal 'any ..) -> T
(code 'doJournal 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   sub S (MaxBlkSize)  # <S /I> Buffer
   do
      atom Y  # More args?
   while z  # Yes
      call evSymY_E  # Next file name
      call pathStringE_SZ  # Write to stack buffer
      cc fopen(S _r_)  # Open file
      ld S Z  # Drop buffer
      null A  # OK?
      jz openErrEX  # No
      ld E A  # Keep journal file pointer in E
      do
         cc getc_unlocked(E)  # Next char
         nul4  # EOF?
      while ns  # No
         ld C A  # Size in C
         cc fread(Buf 2 1 E)  # Read file number
         cmp A 1  # OK?
         jne jnlErrX  # No
         call dbfBuf_AF  # Read file number from 'Buf' to 'DbFile'
         jz dbfErrX  # No local file
         cmp C BLKSIZE  # Whole block?
         ldz C (A III)  # Yes: Take file's block size
         cc fread(Buf BLK 1 E)  # Read object ID
         cmp A 1  # OK?
         jne jnlErrX  # No
         cc fread(S C 1 E)  # Read data into buffer
         cmp A 1  # OK?
         jne jnlErrX  # No
         push E  # Save journal file pointer
         ld Z Buf  # Get object ID from 'Buf'
         call getAdrZ_A
         ld E A  # into E
         shl E ((DbFile) II)  # Shift
         lea Z (S I)  # Buffer
         call blkPokeCEZ  # Write object data
         pop E  # Restore journal file pointer
      loop
      cc fclose(E)  # Close file pointer
      ld Y (Y CDR)
   loop
   add S (MaxBlkSize)  # Drop buffer
   ld E TSym  # Return T
   pop Z
   pop Y
   pop X
   ret

# (id 'num ['num]) -> sym
# (id 'sym [NIL]) -> num
# (id 'sym T) -> (num . num)
(code 'doId 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   num E  # File number?
   if nz  # Yes
      shr E 4  # Normalize
      push E  # <S> Scaled file number or object ID
      ld Y (Y CDR)  # Next arg
      ld E (Y)
      eval  # Eval object ID
      cmp E Nil  # Given?
      if eq  # No
         pop C  # Get object ID
         ld E 0  # File defaults to zero
      else
         call xCntEX_FE  # Eval object ID
         ld C E  # into C
         pop E  # Get file number
         dec E  # Zero-based
      end
      call extNmCE_X  # Build external symbol name
      call externX_E  # New external symbol
      pop Y
      pop X
      ret
   end
   sym E  # Need symbol
   jz symErrEX
   sym (E TAIL)  # External symbol?
   jz extErrEX  # No
   xchg E Y  # Keep symbol in Y
   ld E ((E CDR))  # Eval second arg
   eval  # Eval flag
   xchg E Y  # Keep flag in Y, get symbol in E
   call fileObjE_AC  # Get file and ID
   shl C 4  # Make short object ID
   or C CNT
   cmp Y Nil  # Return only object ID?
   ldz E C  # Yes
   if ne  # No
      inc A  # File is zero-based
      shl A 4  # Make short file number
      or A CNT
      call cons_E  # Return (file . id)
      ld (E) A
      ld (E CDR) C
   end
   pop Y
   pop X
   ret

# (seq 'cnt|sym1) -> sym | NIL
(code 'doSeq 2)
   push X
   push Y
   push Z
   ld X E
   ld E ((E CDR))  # Eval arg
   eval
   num E  # File number?
   if nz  # Yes
      off E 15  # Normalize + 'dbFile' index
      sub E (hex "10")  # Zero-based
      shl E 2
      push E  # <S> Scaled file number
      cmp E (DBs)  # Local file?
      jge dbfErrX  # No
      add E (DbFiles)  # Get DB file
      ld (DbFile) E  # Set current
      ld X 0  # Block index zero
   else
      sym E  # Need symbol
      jz symErrEX
      sym (E TAIL)  # External symbol?
      jz extErrEX  # No
      call fileObjE_AC  # Get file and ID
      shl A 6  # 'dbFile' index
      push A  # <S> Scaled file number
      cmp A (DBs)  # Local file?
      jge dbfErrX  # No
      add A (DbFiles)  # Get DB file
      ld (DbFile) A  # Set current
      shl C 6  # Block index from object ID
      ld X C  # Block index in X
   end
   call rdLockDb  # Lock for reading
   ld C BLK  # Read 'next'
   ld E BLK
   ld Z Buf  # into 'Buf'
   call blkPeekCEZ
   call getAdrZ_A  # Get 'next'
   ld Y A  # into Y
   do
      add X BLKSIZE  # Increment block index
      cmp X Y  # Less than 'next'?
      if ge  # No
         add S I  # Drop file number
         ld E Nil  # Return NIL
         break T
      end
      ld E X  # Block index
      shl E ((DbFile) II)  # Shift
      ld C BLK  # Read link field
      call blkPeekCEZ  # into 'Buf'
      ld B (Z)  # Get tag byte
      and B BLKTAG  # Block tag
      cmp B 1  # One?
      if eq  # Yes
         pop E  # Get scaled file number
         shr E 6  # Normalize
         ld C X  # Object ID
         shr C 6  # Normalize
         call extNmCE_X  # Build external symbol name
         call externX_E  # New external symbol
         break T
      end
   loop
   ld A (hex "10000")  # Length 1
   call rwUnlockDbA  # Unlock
   pop Z
   pop Y
   pop X
   ret

# (lieu 'any) -> sym | NIL
(code 'doLieu 2)
   ld E ((E CDR))  # Get arg
   eval  # Eval it
   num E  # Number?
   jnz retNil  # Yes
   sym E  # Symbol?
   jz retNil  # No
   ld A (E TAIL)  # Get tail
   sym A  # External symbol?
   jz retNil  # No
   off A SYM  # Clear 'extern' tag
   do
      num A  # Found name?
      if nz  # Yes
         add A A  # Dirty?
         if nc  # No
            add A A  # Loaded?
            if nc  # No
               ld E Nil  # No
            end
            ret
         end
         add A A  # Deleted?
         if c  # Yes
            ld E Nil
         end
         ret
      end
      ld A (A CDR)  # Skip property
   loop

# (lock ['sym]) -> cnt | NIL
(code 'doLock 2)
   push X
   ld X E
   ld E ((E CDR))  # E on arg
   eval  # Eval it
   cmp E Nil  # NIL?
   if eq  # Yes
      ld (DbFile) (DbFiles)  # Use first dbFile
      ld C 0  # Start
      ld E 0  # Length
      call tryLockCE_FA  # Lock whole DB
   else
      num E  # Need symbol
      jnz symErrEX
      sym E
      jz symErrEX
      sym (E TAIL)  # External symbol?
      jz extErrEX  # No
      call fileObjE_AC  # Get file and ID
      shl A 6  # 'dbFile' index
      cmp A (DBs)  # Local file?
      jge dbfErrX  # No
      add A (DbFiles)  # Get DB file
      ld (DbFile) A
      ld A (A III)  # Get block size
      mul C  # Multiply with object ID for start position
      ld C A  # Start
      ld E 1  # Length
      call tryLockCE_FA  # Lock external symbol
   end
   ld E Nil  # Preload NIL
   if nz  # Locked by another process
      ld E A  # Get PID
      shl E 4  # Make short number
      or E CNT
   end
   pop X
   ret

(code 'dbFetchEX 0)
   ld A (E TAIL)  # Get tail
   num A  # Any properties?
   jz Ret  # Yes
   rxl A 1  # Dirty?
   jx ret  # Yes
   rxl A 1  # Loaded?
   jx ret  # Yes
   setx  # Set "loaded"
   rxr A 1
   shr A 1
(code 'dbAEX 0)
   push Y
   push Z
   push C
   link
   push E  # <L I> Symbol
   link
   ld Y A  # Status/name in Y
   call dbFileBlkY_AC  # Get file and block index
   cmp A (DBs)  # Local file?
   if lt  # Yes
      call setBlockAC_Z  # Set up block env
      call rdLockDb  # Lock for reading
      call rdBlockZ_Z  # Read first block
      ld B (Z (- BLK))  # Get tag byte
      and B BLKTAG  # Block tag
      cmp B 1  # One?
      jne idErrXL  # Bad ID
      ld (GetBinZ_FB) getBlockZ_FB  # Set binary read function
      ld (Extn) 0  # Set external symbol offset to zero
      call binReadZ_FE  # Read first item
      ld A (L I)  # Get symbol
      ld (A) E  # Set value
      ld (A TAIL) Y  # and status/name
      call binReadZ_FE  # Read first property key
      cmp E Nil  # Any?
      if ne  # Yes
         call consE_A  # Build first property cell
         ld (A) E  # Cons key
         ld (A CDR) Y  # With status/name
         ld Y A  # Keep cell in Y
         or A SYM  # Set 'extern' tag
         ld ((L I) TAIL) A  # Set symbol's tail
         call binReadZ_FE  # Read property value
         cmp E TSym  # T?
         if ne  # No
            call consE_A  # Cons property value
            ld (A) E
            ld (A CDR) (Y)  # With key
            ld (Y) A  # Save in first property cell
         end
         do
            call binReadZ_FE  # Read next property key
            cmp E Nil  # Any?
         while ne  # Yes
            call consE_A  # Build next property cell
            ld (A) E  # Cons key
            ld (A CDR) (Y CDR)  # With name
            ld (Y CDR) A  # Insert
            ld Y A  # Point Y to new cell
            call binReadZ_FE  # Read property value
            cmp E TSym  # T?
            if ne  # No
               call consE_A  # Cons property value
               ld (A) E
               ld (A CDR) (Y)  # With key
               ld (Y) A  # Save in property cell
            end
         loop
      end
      ld A (hex "10000")  # Length 1
      call rwUnlockDbA  # Unlock
   else
      shr A 6  # Revert to file number
      ld Z (Ext)  # Extended databases?
      atom Z
      jnz dbfErrX  # No
      inc A  # File is zero-based
      ld C ((Z))  # First offset
      shr C 4  # Normalize
      cmp A C  # First offset too big?
      jlt dbfErrX  # Yes
      do
         ld E (Z CDR)  # More?
         atom E
      while z  # Yes
         ld C ((E))  # Next offset
         shr C 4  # Normalize
         cmp A C  # Matching entry?
      while ge  # No
         ld Z E  # Try next DB extension
      loop
      push Y  # Save name
      push ((Z) CDR)  # fun ((Obj) ..)
      ld Y S  # Pointer to fun in Y
      push (L I)  # Symbol
      ld Z S  # Z on (last) argument
      call applyXYZ_E  # Apply
      pop Z  # Get symbol
      add S I  # Drop 'fun'
      pop Y  # Get name
      ld (Z) (E)  # Set symbol's value
      ld E (E CDR)  # Properties?
      atom E
      if z  # Yes
         ld A E  # Set 'extern' tag
         or A SYM
         ld (Z TAIL) A  # Set property list
         do
            atom (E CDR)  # Find end
         while z
            ld E (E CDR)
         loop
         ld (E CDR) Y  # Set name
      else
         or Y SYM  # Set 'extern' tag
         ld (Z TAIL) Y  # Set name
      end
   end
   ld E (L I)  # Restore symbol
   drop
   pop C
   pop Z
   pop Y
   ret

(code 'dbTouchEX 0)
   push C
   lea C (E TAIL)  # Get tail
   ld A (C)
   num A  # Any properties?
   if z  # Yes
      off A SYM  # Clear 'extern' tag
      do
         lea C (A CDR)  # Skip property
         ld A (C)
         num A  # Find name
      until nz
   end
   rxl A 1  # Already dirty?
   if nx  # No
      rxl A 1  # Loaded?
      if x  # Yes
         shr A 1
         setx  # Set "dirty"
         rxr A 1
         ld (C) A  # in status/name
         pop C
         ret
      end
      shr A 1
      setx  # Set "dirty"
      rxr A 1
      pop C
      jmp dbAEX
   end
   pop C
   ret

(code 'dbZapE 0)
   ld A (E TAIL)  # Get tail
   num A  # Any properties?
   if z  # Yes
      off A SYM  # Clear 'extern' tag
      do
         ld A (A CDR)  # Skip property
         num A  # Find name
      until nz
      or A SYM  # Set 'extern' tag
   end
   shl A 2  # Set "deleted"
   setx
   rxr A 1
   setx
   rxr A 1
   ld (E TAIL) A  # Set empty tail
   ld (E) Nil  # Clear value
   ret

# (commit ['any] [exe1] [exe2]) -> T
(code 'doCommit 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval 'any'
   eval
   link
   push E  # <L I> 'any'
   link
   null (DbLog)  # Transaction log?
   if z  # No
      inc (EnvProtect)  # Protect the operation
   end
   call wrLockDb  # Write lock DB
   null (DbJnl)  # Journal?
   if nz  # Yes
      call lockJnl  # Write lock journal
   end
   null (DbLog)  # Transaction log?
   if nz  # Yes
      ld E (DbFiles)  # Iterate DB files
      ld C (DBs)  # Count
      do
         set (E (+ IV 1)) 0  # Clear dirty flag
         ld (E VII) 0  # and 'fluse'
         add E VIII  # Increment by sizeof(dbFile)
         sub C VIII  # Done?
      until z  # Yes
      push X
      push Y
      ld X (Extern)  # Iterate external symbol tree
      ld Y 0  # Clear TOS
      do
         do
            ld A (X CDR)  # Get subtrees
            atom (A)  # Left subtree?
         while z  # Yes
            ld C X  # Go left
            ld X (A)  # Invert tree
            ld (A) Y  # TOS
            ld Y C
         loop
         do
            ld A ((X) TAIL)  # Get external symbol's tail
            call nameA_A  # Get name
            rxl A 1  # Dirty or deleted?
            if x  # Yes
               push Y
               rxr A 1
               ld Y A  # Name in Y
               call dbFileBlkY_AC  # Get file and block index
               cmp A (DBs)  # Local file?
               if lt  # Yes
                  call setBlockAC_Z  # Set up block env
                  call rdBlockZ_Z  # Read first block
                  do
                     call logBlock  # Write to transaction log
                     null (BlkLink)  # More blocks?
                  while nz  # Yes
                     call rdBlockLinkZ_Z  # Read next block
                  loop
                  ld C (DbFile)
                  set (C (+ IV 1)) 1  # Set dirty flag
                  rxl Y 2  # Deleted?
                  if nx  # No
                     inc (C VII)  # Increment 'fluse'
                  end
               end
               pop Y
            end
            ld A (X CDR)  # Right subtree?
            atom (A CDR)
            if z  # Yes
               ld C X  # Go right
               ld X (A CDR)  # Invert tree
               ld (A CDR) Y  # TOS
               or C SYM  # First visit
               ld Y C
               break T
            end
            do
               ld A Y  # TOS
               null A  # Empty?
               jeq 20  # Done
               sym A  # Second visit?
               if z  # Yes
                  ld C (A CDR)  # Nodes
                  ld Y (C)  # TOS on up link
                  ld (C) X
                  ld X A
                  break T
               end
               off A SYM  # Set second visit
               ld C (A CDR)  # Nodes
               ld Y (C CDR)
               ld (C CDR) X
               ld X A
            loop
         loop
      loop
20    ld X (DbFiles)  # Iterate DB files
      ld Y (DBs)  # Count
      do
         ld A (X VII)  # Get 'fluse'
         null A  # Any?
         if nz  # Yes
            push A  # Save as count
            ld A X
            ld C 0  # Save Block 0 and free list
            call setBlkAC_Z  # Set up block env
            call rdBlockZ_Z  # Read first block
            do
               call logBlock  # Write to transaction log
               null (BlkLink)  # More blocks?
            while nz  # Yes
               sub (S) 1  # Decrement count
            while nb
               call rdBlockLinkZ_Z  # Read next block
            loop
            add S I  # Drop count
         end
         add X VIII  # Increment by sizeof(dbFile)
         sub Y VIII  # Done?
      until z  # Yes
      cc putc_unlocked((hex "FF") (DbLog))  # Write end marker
      cc putc_unlocked((hex "FF") (DbLog))
      cc fflush((DbLog))  # Flush Transaction log
      call logFileno_A  # Sync log file to disk
      cc fsync(A)
      nul4  # OK?
      js trSyncErrX  # No
      pop Y
      pop X
   end
   ld Y (Y CDR)  # Eval pre-expression
   ld E (Y)
   eval
   cmp (L I) Nil  # 'any'?
   if eq  # No
      push 0  # <L -I> No notification
   else
      ld A (Tell)
      or A (Children)
      push A  # <L -I> Notify flag
      if nz
         push A  # <L -II> Tell's buffer pointer
         push (TellBuf)  # <L -III> Save current 'tell' env
         sub S PIPE_BUF  # <L - III - PIPE_BUF> New 'tell' buffer
         ld Z S  # Buffer pointer
         call tellBegZ_Z  # Start 'tell' message
         ld E (L I)  # Get 'any'
         call prTellEZ  # Print to 'tell'
         ld (L -II) Z  # Save buffer pointer
      end
   end
   push X
   push Y
   ld X (Extern)  # Iterate external symbol tree
   ld Y 0  # Clear TOS
   do
      do
         ld A (X CDR)  # Get subtrees
         atom (A)  # Left subtree?
      while z  # Yes
         ld C X  # Go left
         ld X (A)  # Invert tree
         ld (A) Y  # TOS
         ld Y C
      loop
      do
         lea C ((X) TAIL)  # Get external symbol's tail
         ld A (C)
         num A  # Any properties?
         if z  # Yes
            off A SYM  # Clear 'extern' tag
            do
               lea C (A CDR)  # Skip property
               ld A (C)
               num A  # Find name
            until nz
         end
         rxl A 1  # Dirty?
         if x  # Yes
            push Y
            rxl A 1  # Deleted?
            if nx  # No
               setx  # Set "loaded"
               rxr A 1
               shr A 1
               ld (C) A  # in status/name
               ld Y A  # Name in Y
               call dbFileBlkY_AC  # Get file and block index
               cmp A (DBs)  # Local file?
               if lt  # Yes
                  call setBlockAC_Z  # Set up block env
                  call rdBlockZ_Z  # Read first block
                  ld B 1  # First block in object (might be a new object)
                  or (Z (- BLK)) B  # Set in tag byte
                  ld (PutBinBZ) putBlockBZ  # Set binary print function
                  ld Y (X)  # Get external symbol
                  ld E (Y)  # Print value
                  ld (Extn) 0  # Set external symbol offset to zero
                  call binPrintEZ
                  ld Y (Y TAIL)  # Get tail
                  off Y SYM  # Clear 'extern' tag
                  do
                     num Y  # Properties?
                  while z  # Yes
                     atom (Y)  # Flag?
                     if z  # No
                        ld E ((Y) CDR)  # Get key
                        cmp E Nil  # Volatile property?
                        if ne  # No
                           call binPrintEZ  # Print key
                           ld E ((Y))  # Print value
                           call binPrintEZ
                        end
                     else
                        ld E (Y)  # Get key
                        cmp E Nil  # Volatile property?
                        if ne  # No
                           call binPrintEZ  # Print key
                           ld E TSym  # Print 'T'
                           call binPrintEZ
                        end
                     end
                     ld Y (Y CDR)
                  loop
                  ld B NIX
                  call putBlockBZ  # Output NIX
                  ld Z (DbBlock)  # Block buffer in Z again
                  ld B (Z)  # Lowest byte of link field
                  and B BLKTAG  # Clear link
                  zxt
                  call setAdrAZ  # Store in last block
                  call wrBlockZ  # Write block
                  ld Y (BlkLink)  # More blocks?
                  null Y
                  if nz  # Yes
                     call cleanUpY  # Clean up
                  end
                  null (L -I)  # Notify?
                  if nz  # Yes
                     ld Z (L -II)  # Get buffer pointer
                     lea A ((TellBuf) (- PIPE_BUF 10))  # Space for EXTERN+<8>+END?
                     cmp Z A
                     if ge  # No
                        ld A 0  # Send to all PIDs
                        call tellEndAZ  # Close 'tell'
                        lea Z (L (- (+ III PIPE_BUF)))  # Reset buffer pointer
                        call tellBegZ_Z  # Start new 'tell' message
                        ld E (L I)  # Get 'any'
                        call prTellEZ  # Print to 'tell'
                     end
                     ld E (X)  # Get external symbol
                     call prTellEZ  # Print to 'tell'
                     ld (L -II) Z  # Save buffer pointer
                  end
               end
            else  # Deleted
               shr A 2  # Set "not loaded"
               ld (C) A  # in status/name
               ld Y A  # Name in Y
               call dbFileBlkY_AC  # Get file and block index
               cmp A (DBs)  # Local file?
               if lt  # Yes
                  add A (DbFiles)  # Get DB file
                  ld (DbFile) A  # Set current
                  ld Y C
                  call cleanUpY  # Clean up
                  null (L -I)  # Notify?
                  if nz  # Yes
                     ld Z (L -II)  # Get buffer pointer
                     lea A ((TellBuf) (- PIPE_BUF 10))  # Space for EXTERN+<8>+END?
                     cmp Z A
                     if ge  # No
                        ld A 0  # Send to all PIDs
                        call tellEndAZ  # Close 'tell'
                        lea Z (L (- (+ III PIPE_BUF)))  # Reset buffer pointer
                        call tellBegZ_Z  # Start new 'tell' message
                        ld E (L I)  # Get 'any'
                        call prTellEZ  # Print to 'tell'
                     end
                     ld E (X)  # Get external symbol
                     call prTellEZ  # Print to 'tell'
                     ld (L -II) Z  # Save buffer pointer
                  end
               end
            end
            pop Y
         end
         ld A (X CDR)  # Right subtree?
         atom (A CDR)
         if z  # Yes
            ld C X  # Go right
            ld X (A CDR)  # Invert tree
            ld (A CDR) Y  # TOS
            or C SYM  # First visit
            ld Y C
            break T
         end
         do
            ld A Y  # TOS
            null A  # Empty?
            jeq 40  # Done
            sym A  # Second visit?
            if z  # Yes
               ld C (A CDR)  # Nodes
               ld Y (C)  # TOS on up link
               ld (C) X
               ld X A
               break T
            end
            off A SYM  # Set second visit
            ld C (A CDR)  # Nodes
            ld Y (C CDR)
            ld (C CDR) X
            ld X A
         loop
      loop
   loop
40 pop Y
   pop X
   null (L -I)  # Notify?
   if nz  # Yes
      ld A 0  # Send to all PIDs
      ld Z (L -II)  # Get buffer pointer
      call tellEndAZ  # Close 'tell'
      add S PIPE_BUF  # Drop 'tell' buffer
      pop (TellBuf)
   end
   ld Y (Y CDR)  # Eval post-expression
   ld E (Y)
   eval
   null (DbJnl)  # Journal?
   if nz  # Yes
      call unLockJnl  # Unlock journal
   end
   ld Y (Zap)  # Objects to delete?
   atom Y
   if z  # Yes
      push (OutFile)  # Save output channel
      sub S (+ III BUFSIZ)  # <S> Local buffer with sizeof(outFile)
      ld E (Y CDR)  # Get zap file pathname
      call pathStringE_SZ  # Write to stack buffer
      cc open(S (| O_APPEND O_CREAT O_WRONLY) (oct "0666"))  # Open zap file
      nul4  # OK?
      js openErrEX  # No
      ld S Z  # Drop buffer
      ld (S) A  # Store 'fd' in outFile
      ld (S I) 0  # Clear 'ix'
      ld (S II) 0  # and 'tty'
      ld (OutFile) S  # Set OutFile
      ld (PutBinBZ) putStdoutB  # Set binary print function
      ld Y (Y)  # Get zap list
      do
         atom Y  # More symbols?
      while z  # Yes
         ld E (Y)  # Get next
         ld (Extn) 0  # Set external symbol offset to zero
         call binPrintEZ  # Print it
         ld Y (Y CDR)
      loop
      ld A S  # Flush file
      call flushA_F
      ld A S  # Close file
      call closeAX
      ld ((Zap)) Nil  # Clear zap list
      add S (+ III BUFSIZ)  # Drop buffer
      pop (OutFile)  # Restore output channel
   end
   null (DbLog)  # Transaction log?
   if nz  # Yes
      call fsyncDB  # Sync DB files to disk
      call truncLog  # Truncate log file
   end
   ld A 0  # Length
   call rwUnlockDbA  # Unlock all
   call unsync  # Release sync
   null (DbLog)  # Transaction log?
   if z  # No
      dec (EnvProtect)  # Unprotect
   end
   ld E (DbFiles)  # Iterate DB files
   ld C (DBs)  # Count
   do
      ld (E VII) -1  # Init 'fluse'
      add E VIII  # Increment by sizeof(dbFile)
      sub C VIII  # Done?
   until z  # Yes
   drop
   pop Z
   pop Y
   pop X
   ld E TSym  # Return T
   ret

# (rollback) -> flg
(code 'doRollback 2)
   null (DBs)  # DB open?
   if z  # No
      atom (Ext)  # or extended?
      jnz retNil  # No
   end
   push X
   push Y
   ld X (Extern)  # Iterate external symbol tree
   ld Y 0  # Clear TOS
   do
      do
         ld A (X CDR)  # Get subtrees
         atom (A CDR)  # Right subtree?
      while z  # Yes
         ld C X  # Go right
         ld X (A CDR)  # Invert tree
         ld (A CDR) Y  # TOS
         ld Y C
      loop
      do
         ld E (X)  # Get external symbol
         ld A (E TAIL)
         num A  # Any properties?
         if z  # Yes
            off A SYM  # Clear 'extern' tag
            do
               ld A (A CDR)  # Skip property
               num A  # Find name
            until nz
            or A SYM  # Set 'extern' tag
         end
         shl A 2  # Strip status bits
         shr A 2
         ld (E TAIL) A  # Set status/name
         ld (E) Nil  # Clear value
         ld A (X CDR)  # Left subtree?
         atom (A)
         if z  # Yes
            ld C X  # Go left
            ld X (A)  # Invert tree
            ld (A) Y  # TOS
            or C SYM  # First visit
            ld Y C
            break T
         end
         do
            ld A Y  # TOS
            null A  # Empty?
            jeq 90  # Done
            sym A  # Second visit?
            if z  # Yes
               ld C (A CDR)  # Nodes
               ld Y (C CDR)  # TOS on up link
               ld (C CDR) X
               ld X A
               break T
            end
            off A SYM  # Set second visit
            ld C (A CDR)  # Nodes
            ld Y (C)
            ld (C) X
            ld X A
         loop
      loop
   loop
90 ld Y (Zap)  # Objects to delete?
   atom Y
   if z  # Yes
      ld (Y) Nil  # Clear zap list
   end
   null (DBs)  # DB open?
   if nz  # Yes
      ld A 0  # Length
      call rwUnlockDbA  # Unlock all
   end
   call unsync  # Release sync
   pop Y
   pop X
   ld E TSym  # Return T
   ret

# (mark 'sym|0 [NIL | T | 0]) -> flg
(code 'doMark 2)
   push X
   push Y
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   cmp E ZERO  # Zero?
   if eq  # Yes
      ld X (DbFiles)  # Iterate DB files
      ld Y (DBs)  # Count
      do
         sub Y VIII  # Done?
      while ge  # No
         ld (X V) 0  # Mark vector size zero
         cc free((X VI))  # Free mark bit vector
         ld (X VI) 0  # Set to null
         add X VIII  # Increment by sizeof(dbFile)
      loop
      ld E Nil  # Return NIL
      pop Y
      pop X
      ret
   end
   num E  # Need symbol
   jnz symErrEX
   sym E
   jz symErrEX
   sym (E TAIL)  # External symbol?
   jz extErrEX  # No
   push E  # <S> 'sym'
   ld E ((Y CDR))  # Eval second arg
   eval
   xchg E (S)  # <S> NIL | T | 0
   call fileObjE_AC  # Get file and ID
   shl A 6  # 'dbFile' index
   cmp A (DBs)  # Local file?
   jge dbfErrX  # No
   add A (DbFiles)  # Get DB file
   ld X A  # into X
   ld E C  # Object ID in E
   shr E 3  # Byte position
   cmp E (X V)  # Greater or equal to mark vector size?
   if ge  # Yes
      push E  # Save byte position
      inc E  # New size
      ld Y E  # Keep in Y
      ld A (X VI)  # Get mark bit vector
      call allocAE_A  # Increase to new size
      ld (X VI) A
      xchg E (X V)  # Store size in 'dbFile', get old size
      sub Y E  # Length of new area
      add E A  # Start position of new area
      ld B 0  # Clear new area
      mset (E) Y
      pop E  # Restore byte position
   end
   add E (X VI)  # Byte position in bit vector
   and C 7  # Lowest three bits of object ID
   ld B 1  # Bit position
   shl B C  # in B
   test (E) B  # Bit test
   if z  # Not set
      cmp (S) TSym  # Second arg 'T'?
      if eq  # Yes
         or (E) B  # Set mark
      end
      ld E Nil  # Return NIL
   else  # Bit was set
      cmp (S) ZERO  # Second arg '0'?
      if eq  # Yes
         not B
         and (E) B  # Clear mark
      end
      ld E TSym  # Return T
   end
   add S I  # Drop second arg
   pop Y
   pop X
   ret

# (free 'cnt) -> (sym . lst)
(code 'doFree 2)
   push X
   push Y
   push Z
   ld X E
   ld E ((E CDR))  # Eval 'cnt'
   call evCntEX_FE
   dec E  # File is zero-based
   shl E 6  # 'dbFile' index
   cmp E (DBs)  # Local file?
   jge dbfErrX  # No
   add E (DbFiles)  # Get DB file
   ld (DbFile) E  # Set current
   call rdLockDb  # Lock for reading
   ld C (* 2 BLK)  # Read 'free' and 'next'
   ld E 0  # from block zero
   ld Z Buf  # into 'Buf'
   call blkPeekCEZ
   call getAdrZ_A  # Get 'free'
   ld (BlkLink) A  # Store as next block
   add Z BLK
   call getAdrZ_A  # Get 'next'
   ld C A  # Object ID
   shr C 6  # Normalize
   ld E ((DbFile) I)  # Get file number
   call extNmCE_X  # Build external symbol name
   call externX_E  # New external symbol
   call cons_Y  # Cons as CAR of result list
   ld (Y) E
   ld (Y CDR) Nil
   link
   push Y  # (L I) Result list
   link
   do  # Collect free list
      ld C (BlkLink)  # Next free block?
      null C
   while nz  # Yes
      shr C 6  # Normalize
      ld E ((DbFile) I)  # Get file number
      call extNmCE_X  # Build external symbol name
      call externX_E  # New external symbol
      call cons_A  # Next cell
      ld (A) E
      ld (A CDR) Nil
      ld (Y CDR) A  # Append ot result list
      ld Y A
      call rdBlockLinkZ_Z  # Read next block
   loop
   ld A (hex "10000")  # Length 1
   call rwUnlockDbA  # Unlock
   ld E (L I)  # Get result list
   drop
   pop Z
   pop Y
   pop X
   ret

# (dbck ['cnt] 'flg) -> any
(code 'doDbck 2)
   push X
   push Y
   push Z
   ld X E
   ld Y (E CDR)  # Y on args
   ld E (Y)  # Eval first
   eval
   ld (DbFile) (DbFiles)  # Default to first dbFile
   cnt E  # 'cnt' arg?
   if nz  # Yes
      off E 15  # Normalize + 'dbFile' index
      sub E (hex "10")  # Zero-based
      shl E 2
      cmp E (DBs)  # Local file?
      jge dbfErrX  # No
      add E (DbFiles)  # Get DB file
      ld (DbFile) E  # Set current
      ld Y (Y CDR)  # Next arg
      ld E (Y)
      eval  # Eval next arg
   end
   push (DbJnl)  # <S IV> Journal
   push E  # <S III> 'flg'
   push ZERO  # <S II> 'syms'
   push ZERO  # <S I> 'blks'
   inc (EnvProtect)  # Protect the operation
   call wrLockDb  # Write lock DB
   null (DbJnl)  # Journal?
   if nz  # Yes
      call lockJnl  # Write lock journal
   end
   ld C (* 2 BLK)  # Read 'free' and 'next'
   ld E 0  # from block zero
   ld Z Buf  # into 'Buf'
   call blkPeekCEZ
   call getAdrZ_A  # Get 'free'
   ld (BlkLink) A  # Store as next block
   add Z BLK
   call getAdrZ_A  # Get 'next'
   push A  # <S> 'next'
   ld Y BLKSIZE  # 'cnt' in Y
   ld (DbJnl) 0  # Disable Journal
   do  # Check free list
      ld A (BlkLink)  # Next block?
      null A
   while nz  # Yes
      call rdBlockIndexAZ_Z  # Read next block
      add Y BLKSIZE  # Increment 'cnt'
      cmp Y (S)  # Greater than 'next'?
      if gt  # Yes
         ld E CircFree  # Circular free list
         call mkStrE_E  # Return message
         jmp 90
      end
      ld Z (DbBlock)  # Block buffer in Z again
      or (Z) BLKTAG  # Mark free list
      call wrBlockZ  # Write block
   loop
   ld (DbJnl) (S IV)  # Restore Journal
   ld X BLKSIZE  # 'p' in X
   do  # Check all chains
      cmp X (S)  # Reached 'next'?
   while ne  # No
      ld A X  # Get 'p'
      call rdBlockIndexAZ_Z  # Read next block
      sub Z BLK  # Block buffer in Z again
      ld B (Z)  # Get tag byte
      and B BLKTAG  # Block tag zero?
      if z  # Yes
         add Y BLKSIZE  # Increment 'cnt'
         movn (Z) (Buf) BLK  # Insert into free list
         call wrBlockZ  # Write block
         ld A X  # Write 'free'
         ld Z Buf  # into 'Buf'
         call setAdrAZ
         ld C BLK
         ld E 0  # 'free' address
         call blkPokeCEZ  # Write 'Buf'
      else
         cmp B 1  # ID-block of symbol?
         if eq  # Yes
            push X
            add (S II) (hex "10")  # Increment 'blks'
            add (S III) (hex "10")  # Increment 'syms'
            add Y BLKSIZE  # Increment 'cnt'
            ld X 2  # Init 'i'
            do
               ld A (BlkLink)  # Next block?
               null A
            while nz  # Yes
               add Y BLKSIZE  # Increment 'cnt'
               add (S II) (hex "10")  # Increment 'blks'
               call rdBlockIndexAZ_Z  # Read next block
               ld B (Z (- BLK))  # Get tag byte
               and B BLKTAG  # Block tag
               cmp B X  # Same as 'i'?
               if ne  # No
                  ld E BadChain  # Bad object chain
                  call mkStrE_E  # Return message
                  jmp 90
               end
               cmp X BLKTAG  # Less than maximum?
               if lt  # Yes
                  inc X  # Increment
               end
            loop
            pop X
         end
      end
      add X BLKSIZE  # Increment 'p'
   loop
   ld Z Buf  # Get 'free'
   call getAdrZ_A
   ld (BlkLink) A  # Store as next block
   ld (DbJnl) 0  # Disable Journal
   do  # Unmark free list
      null A  # Any?
   while nz  # Yes
      call rdBlockIndexAZ_Z  # Read next block
      sub Z BLK  # Block buffer in Z again
      ld B (Z)  # Get tag byte
      and B BLKTAG  # Block tag non-zero?
      if nz  # Nes
         off (Z) BLKTAG  # Clear tag
         call wrBlockZ  # Write block
      end
      ld A (BlkLink)  # Get next block
   loop
   cmp Y (S)  # 'cnt' == 'next'?
   if ne  # No
      ld E BadCount  # Circular free list
      call mkStrE_E  # Return message
   else
      cmp (S III) Nil  # 'flg' is NIL?
      ldz E Nil  # Yes: Return NIL
      if ne  # No
         call cons_E  # Return (blks . syms)
         ld (E) (S I)  # 'blks'
         ld (E CDR) (S II)  # 'syms'
      end
   end
90 add S IV  # Drop 'next', 'blks', 'syms' and 'flg'
   pop (DbJnl)  # Restore Journal
   null (DbJnl)  # Any?
   if nz  # Yes
      call unLockJnl  # Unlock journal
   end
   ld A (hex "10000")  # Length 1
   call rwUnlockDbA  # Unlock
   dec (EnvProtect)  # Unprotect
   pop Z
   pop Y
   pop X
   ret

# vi:et:ts=3:sw=3
