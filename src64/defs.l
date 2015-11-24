# 29oct15abu
# (c) Software Lab. Alexander Burger

# Constants
(equ HEAP (* 1024 1024))      # Heap size in bytes
(equ CELLS (/ HEAP 16))       # Number of cells in a single heap (65536)
(equ STACK (* 64 1024))       # Default coroutine stack segment size (64 kB)
(equ ZERO (short 0))          # Short number '0'
(equ ONE (short 1))           # Short number '1'
(equ TOP (hex "10000"))       # Character top
(equ DB1 (hex "1A"))          # Name of '{1}'

# Pointer offsets
(equ I 8)
(equ II 16)
(equ III 24)
(equ IV 32)
(equ V 40)
(equ VI 48)
(equ VII 56)
(equ VIII 64)
(equ IX 72)

(equ -I -8)
(equ -II -16)
(equ -III -24)
(equ -IV -32)
(equ -V -40)
(equ -VI -48)
(equ -VII -56)
(equ -VIII -64)

# Cell offsets
(equ CNT 2)    # Count tag
(equ BIG 4)    # Rest of a bignum + bignum tag
(equ DIG -4)   # First digit of a big number
(equ CDR 8)    # CDR part of a cons pair
(equ SIGN 8)   # Sign bit of a number
(equ SYM 8)    # Symbol tag
(equ TAIL -8)  # Tail of a symbol

# I/O Tokens
(equ NIX 0)       # NIL
(equ BEG 1)       # Begin list
(equ DOT 2)       # Dotted pair
(equ END 3)       # End list
(equ NUMBER 0)    # Number
(equ INTERN 1)    # Internal symbol
(equ TRANSIENT 2) # Transient symbol
(equ EXTERN 3)    # External symbol

# DB-I/O
(equ BLK 6)       # Block address size
(equ BLKSIZE 64)  # DB block unit size
(equ BLKTAG 63)   # Block tag mask

# Networking
(equ UDPMAX 4096) # UDP buffer size

# Case mappings from the GNU Kaffe Project
(equ CHAR_UPPERCASE 1)
(equ CHAR_LOWERCASE 2)
(equ CHAR_LETTER 62)
(equ CHAR_DIGIT 512)

# vi:et:ts=3:sw=3
