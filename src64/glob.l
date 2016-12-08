# 24nov16abu
# (c) Software Lab. Alexander Burger

(data 'Data)
   initData

:: AV          word  0           # Command line argument vector
:: AV0         word  0           # Command name
:: Home        word  0           # Home directory
:: Heaps       word  0           # Heap list
:: Avail       word  0           # Avail list
:: Buf         word  0           # General 16-byte buffer
               word  0

: Stack0       word  0           # Initial stack pointer
: Stack1       word  0           # Coroutine stack base
: Stacks       word  0           # Coroutine stack segment count
: StkSize      word  STACK       # Coroutine stack segment size
:: StkLimit    word  0           # Stack limit: StackN-Size+4096
: Termio       word  0           # Raw mode terminal I/O
: Tv           word  0           # 'timeval' structure
               word  0
: Time         word  0           # Pointer to time structure
: USec         word  0           # Startup microseconds
: TtyPid       word  0           # Terminal process ID
: InFDs        word  0           # Scaled number of input files
: InFiles      word  0           # Input files
: OutFDs       word  0           # Scaled number of output files
: OutFiles     word  0           # Output files
:: PutBinBZ    word  0           # Binary output function
:: GetBinZ_FB  word  0           # Binary input function
: Seed         word  0           # Random seed low
               word  0           # Random seed high
: TickU        word  0           # Ticks in user time
: TickS        word  0           # Ticks in system time
: Slot         word  0           # Child index
: Spkr         word  0           # RPC loadspeaker
: Mic          word  0           # RPC microphone
: SpMiPipe     word  0           # Speaker/microphone pipe
: Hear         word  0           # RPC listener
: Tell         word  0           # RPC broadcaster
: TellBuf      word  0           # RPC buffer
: Talking      word  0           # Active child
: Children     word  0           # Scaled number of children
: Child        word  0           # Child array
: ExtN         word  0           # External symbol offset
: Extn         word  0
: StrX         word  0           # String status
: StrC         word  0
: LineC        word  -1
: Break        word  0           # Breakpoint
: GcCount      word  CELLS       # Collector count
: Sep0         word  (char ".")  # Decimal separator
: Sep3         word  (char ",")  # Thousand separator
: BufEnd       word  0           # Common buffer end pointer

: Penv         word  Nil         # Pilog environment
: Pnl          word  Nil

# Signals
: Signal       skip  (* I SIGNALS)

# Database
:: DBs         word  0           # Scaled number of DB files
:: DbFile      word  0           # DB file
:: DbFiles     word  0           # DB files
:: MaxBlkSize  word  0           # Maximum block size
:: DbBlock     word  0           # Block buffer
: BlkIndex     word  0           # Block index
: BlkLink      word  0           # Next block
: DbJnl        word  0           # Journal file
: DbLog        word  0           # Transaction log file

# GC relevant data
: GcMark
:: Transient   word  Nil         # Short transient names
               word  Nil         # Long transient names
: Alarm        word  Nil         # Alarm handler
: Sigio        word  Nil         # Sigio handler
: LineX        word  ZERO        # Console line
: Lisp         word  Nil         # Lisp callbacks: tag+fun
               word  Nil
               word  Nil         # 2
               word  Nil
               word  Nil         # 3
               word  Nil
               word  Nil         # 4
               word  Nil
               word  Nil         # 5
               word  Nil
               word  Nil         # 6
               word  Nil
               word  Nil         # 7
               word  Nil
               word  Nil         # 8
               word  Nil
               word  Nil         # 9
               word  Nil
               word  Nil         # 10
               word  Nil
               word  Nil         # 11
               word  Nil
               word  Nil         # 12
               word  Nil
               word  Nil         # 13
               word  Nil
               word  Nil         # 14
               word  Nil
               word  Nil         # 15
               word  Nil
               word  Nil         # 16
               word  Nil
               word  Nil         # 17
               word  Nil
               word  Nil         # 18
               word  Nil
               word  Nil         # 19
               word  Nil
               word  Nil         # 20
               word  Nil
               word  Nil         # 21
               word  Nil
               word  Nil         # 22
               word  Nil
               word  Nil         # 23
               word  Nil
               word  Nil         # 24
               word  Nil
: LispEnd
: GcMarkEnd


# Symbol Table
(data 'SymTab 0)
   initSym Nil       "NIL"       Nil
               word  Nil         # CDR when NIL is accessed as an empty list
               word  0           # Padding
: Pico
               word  Nil         # Short internal names
               word  Nil         # Long internal names

   # Protected symbols
   initSym pico      "pico"      Pico
   initSym CPU       "*CPU"      TgCPU
   initSym OS        "*OS"       TgOS
   initSym DB        "*DB"       Db1
   initFun Meth      "meth"      doMeth
   initFun Quote     "quote"     doQuote
   initSym TSym      "T"         TSym  # Last protected symbol

   # System globals
   initSym ISym      "I"         Nil
   initSym NSym      "N"         Nil
   initSym SSym      "S"         Nil
   initSym CSym      "C"         Nil
   initSym BSym      "B"         Nil
   initSym Solo      "*Solo"     ZERO
   initSym PPid      "*PPid"     Nil
   initSym Pid       "*Pid"      0
   initSym At        "@"         Nil
   initSym At2       "@@"        Nil
   initSym At3       "@@@"       Nil
   initSym This      "This"      Nil
   initSym Prompt    "*Prompt"   Nil
   initSym Zap       "*Zap"      Nil
   initSym Ext       "*Ext"      Nil
   initSym Scl       "*Scl"      ZERO
   initSym Class     "*Class"    Nil
   initSym Run       "*Run"      Nil
   initSym Hup       "*Hup"      Nil
   initSym Sig1      "*Sig1"     Nil
   initSym Sig2      "*Sig2"     Nil
   initSym Up        "\^"        Nil
   initSym Err       "*Err"      Nil
   initSym Msg       "*Msg"      Nil
   initSym Uni       "*Uni"      Nil
   initSym Led       "*Led"      Nil
   initSym Tsm       "*Tsm"      Nil
   initSym Adr       "*Adr"      Nil
   initSym Fork      "*Fork"     Nil
   initSym Bye       "*Bye"      Nil
   initSym Dbg       "*Dbg"      Nil

   # System functions
   initFun NIL       "raw"       doRaw
   initFun NIL       "alarm"     doAlarm
   initFun NIL       "sigio"     doSigio
   initFun NIL       "kids"      doKids
   initFun NIL       "protect"   doProtect
   initFun NIL       "heap"      doHeap
   initFun NIL       "stack"     doStack
   initFun NIL       "adr"       doAdr
   initFun NIL       "env"       doEnv
   initFun NIL       "trail"     doTrail
   initFun NIL       "up"        doUp
   initFun NIL       "sys"       doSys
   initFun NIL       "quit"      doQuit
   initFun NIL       "errno"     doErrno
   initFun NIL       "native"    doNative
   initFun NIL       "struct"    doStruct
   initFun NIL       "lisp"      doLisp
   initFun NIL       "args"      doArgs
   initFun NIL       "next"      doNext
   initFun NIL       "arg"       doArg
   initFun NIL       "rest"      doRest
   initFun NIL       "date"      doDate
   initFun NIL       "time"      doTime
   initFun NIL       "usec"      doUsec
   initFun NIL       "pwd"       doPwd
   initFun NIL       "cd"        doCd
   initFun NIL       "ctty"      doCtty
   initFun NIL       "info"      doInfo
   initFun NIL       "file"      doFile
   initFun NIL       "dir"       doDir
   initFun NIL       "cmd"       doCmd
   initFun NIL       "argv"      doArgv
   initFun NIL       "opt"       doOpt
   initFun NIL       "version"   doVersion

   # Garbage collection
   initFun NIL       "gc"        doGc

   # Mapping
   initFun NIL       "apply"     doApply
   initFun NIL       "pass"      doPass
   initFun NIL       "maps"      doMaps
   initFun NIL       "map"       doMap
   initFun NIL       "mapc"      doMapc
   initFun NIL       "maplist"   doMaplist
   initFun NIL       "mapcar"    doMapcar
   initFun NIL       "mapcon"    doMapcon
   initFun NIL       "mapcan"    doMapcan
   initFun NIL       "filter"    doFilter
   initFun NIL       "extract"   doExtract
   initFun NIL       "seek"      doSeek
   initFun NIL       "find"      doFind
   initFun NIL       "pick"      doPick
   initFun NIL       "fully"     doFully
   initFun NIL       "cnt"       doCnt
   initFun NIL       "sum"       doSum
   initFun NIL       "maxi"      doMaxi
   initFun NIL       "mini"      doMini
   initFun NIL       "fish"      doFish
   initFun NIL       "by"        doBy

   # Control flow
   initFun NIL       "as"        doAs
   initFun NIL       "lit"       doLit
   initFun NIL       "eval"      doEval
   initFun NIL       "run"       doRun
   initFun NIL       "def"       doDef
   initFun NIL       "de"        doDe
   initFun NIL       "dm"        doDm
   initFun NIL       "box"       doBox
   initFun NIL       "new"       doNew
   initFun NIL       "type"      doType
   initFun NIL       "isa"       doIsa
   initFun NIL       "method"    doMethod
   initFun NIL       "send"      doSend
   initFun NIL       "try"       doTry
   initFun NIL       "super"     doSuper
   initFun NIL       "extra"     doExtra
   initFun NIL       "with"      doWith
   initFun NIL       "bind"      doBind
   initFun NIL       "job"       doJob
   initFun NIL       "let"       doLet
   initFun NIL       "let?"      doLetQ
   initFun NIL       "use"       doUse
   initFun NIL       "and"       doAnd
   initFun NIL       "or"        doOr
   initFun NIL       "nand"      doNand
   initFun NIL       "nor"       doNor
   initFun NIL       "xor"       doXor
   initFun NIL       "bool"      doBool
   initFun NIL       "not"       doNot
   initFun NIL       "nil"       doNil
   initFun NIL       "t"         doT
   initFun NIL       "prog"      doProg
   initFun NIL       "prog1"     doProg1
   initFun NIL       "prog2"     doProg2
   initFun NIL       "if"        doIf
   initFun NIL       "if2"       doIf2
   initFun NIL       "ifn"       doIfn
   initFun NIL       "when"      doWhen
   initFun NIL       "unless"    doUnless
   initFun NIL       "cond"      doCond
   initFun NIL       "nond"      doNond
   initFun NIL       "case"      doCase
   initFun NIL       "casq"      doCasq
   initFun NIL       "state"     doState
   initFun NIL       "while"     doWhile
   initFun NIL       "until"     doUntil
   initFun NIL       "at"        doAt
   initFun NIL       "do"        doDo
   initFun NIL       "loop"      doLoop
   initFun NIL       "for"       doFor
   initFun NIL       "catch"     doCatch
   initFun NIL       "throw"     doThrow
   initFun NIL       "finally"   doFinally
   initFun NIL       "co"        doCo
   initFun NIL       "yield"     doYield
   initFun NIL       "!"         doBreak
   initFun NIL       "e"         doE
   initFun NIL       "$"         doTrace
   initFun NIL       "exec"      doExec
   initFun NIL       "call"      doCall
   initFun NIL       "tick"      doTick
   initFun NIL       "ipid"      doIpid
   initFun NIL       "opid"      doOpid
   initFun NIL       "kill"      doKill
   initFun NIL       "fork"      doFork
   initFun NIL       "detach"    doDetach
   initFun NIL       "bye"       doBye

   # Symbol functions
   initFun NIL       "name"      doName
   initFun NIL       "sp?"       doSpQ
   initFun NIL       "pat?"      doPatQ
   initFun NIL       "fun?"      doFunQ
   initFun NIL       "getd"      doGetd
   initFun NIL       "all"       doAll
   initFun NIL       "symbols"   doSymbols
   initFun NIL       "intern"    doIntern
   initFun NIL       "extern"    doExtern
   initFun NIL       "===="      doHide
   initFun NIL       "box?"      doBoxQ
   initFun NIL       "str?"      doStrQ
   initFun NIL       "ext?"      doExtQ
   initFun NIL       "touch"     doTouch
   initFun NIL       "zap"       doZap
   initFun NIL       "chop"      doChop
   initFun NIL       "pack"      doPack
   initFun NIL       "glue"      doGlue
   initFun NIL       "text"      doText
   initFun NIL       "pre?"      doPreQ
   initFun NIL       "sub?"      doSubQ
   initFun NIL       "val"       doVal
   initFun NIL       "set"       doSet
   initFun NIL       "setq"      doSetq
   initFun NIL       "swap"      doSwap
   initFun NIL       "xchg"      doXchg
   initFun NIL       "on"        doOn
   initFun NIL       "off"       doOff
   initFun NIL       "onOff"     doOnOff
   initFun NIL       "zero"      doZero
   initFun NIL       "one"       doOne
   initFun NIL       "default"   doDefault
   initFun NIL       "push"      doPush
   initFun NIL       "push1"     doPush1
   initFun NIL       "push1q"    doPush1q
   initFun NIL       "pop"       doPop
   initFun NIL       "++"        doPopq
   initFun NIL       "cut"       doCut
   initFun NIL       "del"       doDel
   initFun NIL       "queue"     doQueue
   initFun NIL       "fifo"      doFifo
   initFun NIL       "idx"       doIdx
   initFun NIL       "lup"       doLup
   initFun NIL       "put"       doPut
   initFun NIL       "get"       doGet
   initFun NIL       "prop"      doProp
   initFun NIL       ";"         doSemicol
   initFun NIL       "=:"        doSetCol
   initFun NIL       ":"         doCol
   initFun NIL       "::"        doPropCol
   initFun NIL       "putl"      doPutl
   initFun NIL       "getl"      doGetl
   initFun NIL       "wipe"      doWipe
   initFun NIL       "meta"      doMeta
   initFun NIL       "low?"      doLowQ
   initFun NIL       "upp?"      doUppQ
   initFun NIL       "lowc"      doLowc
   initFun NIL       "uppc"      doUppc
   initFun NIL       "fold"      doFold

   # List processing
   initFun NIL       "car"       doCar
   initFun NIL       "cdr"       doCdr
   initFun NIL       "caar"      doCaar
   initFun NIL       "cadr"      doCadr
   initFun NIL       "cdar"      doCdar
   initFun NIL       "cddr"      doCddr
   initFun NIL       "caaar"     doCaaar
   initFun NIL       "caadr"     doCaadr
   initFun NIL       "cadar"     doCadar
   initFun NIL       "caddr"     doCaddr
   initFun NIL       "cdaar"     doCdaar
   initFun NIL       "cdadr"     doCdadr
   initFun NIL       "cddar"     doCddar
   initFun NIL       "cdddr"     doCdddr
   initFun NIL       "caaaar"    doCaaaar
   initFun NIL       "caaadr"    doCaaadr
   initFun NIL       "caadar"    doCaadar
   initFun NIL       "caaddr"    doCaaddr
   initFun NIL       "cadaar"    doCadaar
   initFun NIL       "cadadr"    doCadadr
   initFun NIL       "caddar"    doCaddar
   initFun NIL       "cadddr"    doCadddr
   initFun NIL       "cdaaar"    doCdaaar
   initFun NIL       "cdaadr"    doCdaadr
   initFun NIL       "cdadar"    doCdadar
   initFun NIL       "cdaddr"    doCdaddr
   initFun NIL       "cddaar"    doCddaar
   initFun NIL       "cddadr"    doCddadr
   initFun NIL       "cdddar"    doCdddar
   initFun NIL       "cddddr"    doCddddr
   initFun NIL       "nth"       doNth
   initFun NIL       "con"       doCon
   initFun NIL       "cons"      doCons
   initFun NIL       "conc"      doConc
   initFun NIL       "circ"      doCirc
   initFun NIL       "rot"       doRot
   initFun NIL       "list"      doList
   initFun NIL       "need"      doNeed
   initFun NIL       "range"     doRange
   initFun NIL       "full"      doFull
   initFun NIL       "make"      doMake
   initFun NIL       "made"      doMade
   initFun NIL       "chain"     doChain
   initFun NIL       "link"      doLink
   initFun NIL       "yoke"      doYoke
   initFun NIL       "copy"      doCopy
   initFun NIL       "mix"       doMix
   initFun NIL       "append"    doAppend
   initFun NIL       "delete"    doDelete
   initFun NIL       "delq"      doDelq
   initFun NIL       "replace"   doReplace
   initFun NIL       "insert"    doInsert
   initFun NIL       "remove"    doRemove
   initFun NIL       "place"     doPlace
   initFun NIL       "strip"     doStrip
   initFun NIL       "split"     doSplit
   initFun NIL       "reverse"   doReverse
   initFun NIL       "flip"      doFlip
   initFun NIL       "trim"      doTrim
   initFun NIL       "clip"      doClip
   initFun NIL       "head"      doHead
   initFun NIL       "tail"      doTail
   initFun NIL       "stem"      doStem
   initFun NIL       "fin"       doFin
   initFun NIL       "last"      doLast
   initFun NIL       "=="        doEq
   initFun NIL       "n=="       doNEq
   initFun NIL       "="         doEqual
   initFun NIL       "<>"        doNEqual
   initFun NIL       "=0"        doEq0
   initFun NIL       "=1"        doEq1
   initFun NIL       "=T"        doEqT
   initFun NIL       "n0"        doNEq0
   initFun NIL       "nT"        doNEqT
   initFun NIL       "<"         doLt
   initFun NIL       "<="        doLe
   initFun NIL       ">"         doGt
   initFun NIL       ">="        doGe
   initFun NIL       "max"       doMax
   initFun NIL       "min"       doMin
   initFun NIL       "atom"      doAtom
   initFun NIL       "pair"      doPair
   initFun NIL       "circ?"     doCircQ
   initFun NIL       "lst?"      doLstQ
   initFun NIL       "num?"      doNumQ
   initFun NIL       "sym?"      doSymQ
   initFun NIL       "flg?"      doFlgQ
   initFun NIL       "member"    doMember
   initFun NIL       "memq"      doMemq
   initFun NIL       "mmeq"      doMmeq
   initFun NIL       "sect"      doSect
   initFun NIL       "diff"      doDiff
   initFun NIL       "index"     doIndex
   initFun NIL       "offset"    doOffset
   initFun NIL       "prior"     doPrior
   initFun NIL       "length"    doLength
   initFun NIL       "size"      doSize
   initFun NIL       "bytes"     doBytes
   initFun NIL       "assoc"     doAssoc
   initFun NIL       "rassoc"    doRassoc
   initFun NIL       "asoq"      doAsoq
   initFun NIL       "rank"      doRank
   initFun NIL       "match"     doMatch
   initFun NIL       "fill"      doFill
   initFun NIL       "prove"     doProve
   initFun NIL       "->"        doArrow
   initFun NIL       "unify"     doUnify
   initFun NIL       "group"     doGroup
   initFun NIL       "sort"      doSort

   # Arithmetics
   initFun NIL       "format"    doFormat
   initFun NIL       "+"         doAdd
   initFun NIL       "-"         doSub
   initFun NIL       "inc"       doInc
   initFun NIL       "dec"       doDec
   initFun NIL       "*"         doMul
   initFun NIL       "*/"        doMulDiv
   initFun NIL       "/"         doDiv
   initFun NIL       "%"         doRem
   initFun NIL       ">>"        doShift
   initFun NIL       "lt0"       doLt0
   initFun NIL       "le0"       doLe0
   initFun NIL       "ge0"       doGe0
   initFun NIL       "gt0"       doGt0
   initFun NIL       "abs"       doAbs
   initFun NIL       "bit?"      doBitQ
   initFun NIL       "&"         doBitAnd
   initFun NIL       "|"         doBitOr
   initFun NIL       "x|"        doBitXor
   initFun NIL       "sqrt"      doSqrt
   initFun NIL       "seed"      doSeed
   initFun NIL       "hash"      doHash
   initFun NIL       "rand"      doRand

   # Input/Output
   initFun NIL       "path"      doPath
   initFun NIL       "read"      doRead
   initFun NIL       "wait"      doWait
   initFun NIL       "sync"      doSync
   initFun NIL       "hear"      doHear
   initFun NIL       "tell"      doTell
   initFun NIL       "poll"      doPoll
   initFun NIL       "key"       doKey
   initFun NIL       "peek"      doPeek
   initFun NIL       "char"      doChar
   initFun NIL       "skip"      doSkip
   initFun NIL       "eol"       doEol
   initFun NIL       "eof"       doEof
   initFun NIL       "from"      doFrom
   initFun NIL       "till"      doTill
   initFun NIL       "line"      doLine
   initFun NIL       "lines"     doLines
   initFun NIL       "any"       doAny
   initFun NIL       "sym"       doSym
   initFun NIL       "str"       doStr
   initFun NIL       "load"      doLoad
   initFun NIL       "in"        doIn
   initFun NIL       "out"       doOut
   initFun NIL       "err"       doErr
   initFun NIL       "ctl"       doCtl
   initFun NIL       "pipe"      doPipe
   initFun NIL       "open"      doOpen
   initFun NIL       "close"     doClose
   initFun NIL       "echo"      doEcho
   initFun NIL       "prin"      doPrin
   initFun NIL       "prinl"     doPrinl
   initFun NIL       "space"     doSpace
   initFun NIL       "print"     doPrint
   initFun NIL       "printsp"   doPrintsp
   initFun NIL       "println"   doPrintln
   initFun NIL       "flush"     doFlush
   initFun NIL       "rewind"    doRewind
   initFun NIL       "ext"       doExt
   initFun NIL       "rd"        doRd
   initFun NIL       "pr"        doPr
   initFun NIL       "wr"        doWr

   # Database
   initFun NIL       "pool"      doPool
   initFun NIL       "journal"   doJournal
   initFun NIL       "id"        doId
   initFun NIL       "seq"       doSeq
   initFun NIL       "lieu"      doLieu
   initFun NIL       "lock"      doLock
   initFun NIL       "commit"    doCommit
   initFun NIL       "rollback"  doRollback
   initFun NIL       "mark"      doMark
   initFun NIL       "free"      doFree
   initFun NIL       "dbck"      doDbck

   # Networking
   initFun NIL       "port"      doPort
   initFun NIL       "accept"    doAccept
   initFun NIL       "listen"    doListen
   initFun NIL       "host"      doHost
   initFun NIL       "connect"   doConnect
   initFun NIL       "udp"       doUdp

: SymTabEnd

# Transient symbols
   initSym TgCPU     `*Architecture TgCPU
   initSym TgOS      `*TargetOS     TgOS

# Database root symbol '{1}'
   word DB1  # Name
: Db1
   word Nil  # Value

: GcSymEnd

# Version number
:: Version
   word (short `(car *Version))
   word .+8
   word (short `(cadr *Version))
   word .+8
   word (short `(caddr *Version))
   word Nil

: ExtCnt       word  1           # External symbol count
: ExtSkip      word  0           # External tree skip
:: Extern      word  0           # External symbol tree

# Structures
: EnvCo  # Coroutine environment
:: Chr         word  0           # Single-char buffer
:: PutB        word  0           # Character output function
:: Get_A       word  0           # Character input function
:: InFile      word  0           # Input file
:: OutFile     word  0           # Output file
: Env  # <Catch III> environment
: EnvBind      word  0           # <III> Bind frames (first item in Env)
: Catch        word  0           # Catch frames
: EnvInFrames  word  0           # Input frames
: EnvOutFrames word  0           # Output frames
: EnvErrFrames word  0           # Error frames
: EnvCtlFrames word  0           # Control frames
:: EnvIntern   word  pico        # Current namespace of internal symbols
: EnvArgs      word  0           # Varargs frame
: EnvNext      word  0           # Next vararg
: EnvCls       word  0           # Method class
: EnvKey       word  0           # Method key
: EnvApply     word  0           # Apply frames
: EnvMake      word  0           # 'make' env
: EnvYoke      word  0
: CLink        word  0           # Saved C link register
: EnvParseX    word  0           # Parser status
: EnvParseC    word  0
: EnvParseEOF  word  -1
: EnvMid  # Must be aligned
: EnvCo7       word  0           # Coroutines
: EnvTask      word  Nil         # Task list
: EnvProtect   word  0           # Signal protection
: EnvTrace     word  0           # Trace level
: EnvEnd  # Must be aligned

: OrgTermio skip TERMIOS         # Original termio structure
: Flock     skip FLOCK           # File lock structure
: Tms       skip TMS             # 'times' structure
: Addr      skip SOCKADDR_IN6    # Internet socket address

: TBuf      byte (+ INTERN 4)    # 'T' in PLIO format
            byte (char "T")

# Case mappings from the GNU Kaffe Project
   align 2
: CaseBlocks
   hx2 ("1C2" "1C2" "1C1" "12C" "12B" "1A0" "1F8" "2DC" "25F" "2EE" "215" "346" "2DC" "326" "2BC" "216")
   hx2 ("15F" "2D4" "376" "376" "376" "369" "FE8F" "344" "FF85" "FF65" "FDB5" "FDA1" "1B" "2C4" "1C" "47")
   hx2 ("FEA8" "FF8C" "235" "FEFF" "1A" "FEBF" "26" "FB20" "FE28" "113" "104" "FB61" "FB5A" "10B" "109" "FE")
   hx2 ("FF08" "229" "25E" "1C7" "1FC" "1DC" "FC46" "229" "FE27" "FB55" "169" "FBC8" "FC" "103" "FB68" "FB48")
   hx2 ("FB28" "FB08" "FAE8" "FAC8" "FAA8" "FA88" "FA68" "FA48" "65" "50" "AB" "139" "FE0E" "63" "155" "1A8")
   hx2 ("F669" "129" "128" "F91F" "FE56" "108" "107" "FAC0" "FC8E" "FEAD" "C6" "FCA7" "FB95" "F47D" "9F" "FB17")
   hx2 ("FE20" "FD28" "FB2F" "3B" "F3B9" "FE57" "FCCE" "FFBB" "F339" "FA98" "FF8B" "FF3B" "FA54" "F7E3" "FF2B" "FAD7")
   hx2 ("FB69" "FC3A" "FEE5" "F4C8" "FCB0" "FA88" "FDBF" "F448" "FE45" "FCC7" "FE4F" "F7F1" "F715" "F2E8" "FD9F" "F348")
   hx2 ("F96A" "FC02" "FD97" "F2C8" "F2A8" "F4B9" "F4B3" "EF6B" "F86A" "F84A" "FC58" "F80A" "F7EA" "FC0F" "F7AA" "EE9C")
   hx2 ("FB90" "F74A" "F7FA" "F70A" "F7CA" "F792" "F471" "F4D2" "F732" "F64A" "F401" "F64D" "EFA8" "F5CA" "F5AA" "ECA1")
   hx2 ("F569" "F54A" "F52A" "F50A" "F4EA" "F4CA" "F4AA" "F48A" "F46A" "F44A" "F42A" "F40A" "F3EA" "F3CA" "F3AA" "F38A")
   hx2 ("F36A" "F34A" "F32A" "F289" "F777" "F2CA" "F2AA" "F737" "EC28" "EC08" "EBE8" "EBC8" "F1EA" "F4A2" "F545" "EDC6")
   hx2 ("F2D7" "F14A" "E8ED" "E81E" "F0EA" "F597" "EA68" "EA48" "EA28" "EA08" "E9E8" "E9C8" "E9A8" "E988" "E968" "E948")
   hx2 ("E928" "E908" "E8E8" "E8C8" "E8A8" "E888" "E868" "E848" "E828" "E808" "E7E8" "E7C8" "E7A8" "E788" "E768" "E748")
   hx2 ("E728" "E708" "E6E8" "E6C8" "E6A8" "E688" "E668" "E648" "E628" "E608" "E5E8" "E5C8" "E5A8" "E588" "E568" "E548")
   hx2 ("E55F" "E53F" "E51F" "E4FF" "EFD7" "E4BF" "E49F" "E485" "EF87" "EF57" "EF57" "EF57" "EF57" "EF47" "E1AD" "EF46")
   hx2 ("EF46" "EF46" "E1E0" "E3DD" "EF06" "E9D9" "EBEB" "E244" "EED4" "EF65" "E1F5" "EF45" "EEE9" "EF7C" "EE74" "EF70")
   hx2 ("EF7D" "EF78" "EE91" "EFD3" "EE7D" "EE25" "EE27" "EF65" "EFDD" "EE96" "EFD3" "EFE1" "EF69" "DF88" "DF68" "DF48")
   hx2 ("ED2B" "ED3D" "ED19" "EF1C" "EF08" "ED47" "ED3D" "ED33" "EC2B" "EC0B" "EBEB" "EBCB" "EBCE" "EA7C" "EB69" "EB6C")
   hx2 ("E9B6" "EB0B" "EAEB" "E9E9" "DCA8" "DC88" "DC68" "DC48" "E910" "EA23" "EB58" "EB4F" "EB45" "EAE5" "DB68" "DB48")
   hx2 ("E92B" "E90B" "E8EB" "E8CB" "E8AB" "E88B" "E86B" "E84B" "DA28" "DA08" "D9E8" "D9C8" "D9A8" "D988" "D968" "D948")
   hx2 ("D928" "D908" "D8E8" "D8C8" "D8A8" "D888" "D868" "D848" "D828" "D808" "D7E8" "D7C8" "D7A8" "D788" "D768" "D748")
   hx2 ("D728" "D708" "D6E8" "D6C8" "D6A8" "D688" "D668" "D648" "D628" "D608" "D5E8" "D5C8" "D5A8" "D588" "D568" "D548")
   hx2 ("D528" "D508" "D4E8" "D4C8" "E2B1" "E28B" "E26B" "E270" "E22B" "E20B" "E1EB" "E1CB" "E1AB" "E18B" "E18E" "DD8F")
   hx2 ("E3A8" "DFD3" "D929" "D90A" "E348" "D8C9" "D8AA" "DCD7" "DCB2" "D681" "D82A" "D80A" "E268" "CEDE" "D168" "D148")
   hx2 ("E116" "E0E9" "E1CB" "E0B7" "E0B7" "E15E" "DF17" "E034" "E013" "DFF3" "DFD3" "DE6C" "DF93" "DF73" "DF55" "DF34")
   hx2 ("D56A" "D54A" "D52A" "D50A" "D4EA" "D4CA" "D4AA" "D48A" "D46A" "D44A" "D42A" "D40A" "D3EA" "D3CA" "D3AA" "D38A")
   hx2 ("D36A" "D34A" "D32A" "D30A" "D2EA" "D2CA" "D2AA" "D28A" "D26A" "D24A" "D22A" "D20A" "D1EA" "D1CA" "D1AA" "D18A")
   hx2 ("D16A" "D14A" "D12A" "D10A" "D0EA" "D0CA" "D0AA" "D08A" "D06A" "D04A" "D02A" "D00A" "CFEA" "CFCA" "CFAA" "CF8A")
   hx2 ("CF6A" "CF4A" "CF2A" "CF0A" "CEEA" "CECA" "CEAA" "CE8A" "CE6A" "CE4A" "CE2A" "CE0A" "CDEA" "CDCA" "CDAA" "CD8A")
   hx2 ("CD6A" "CD4A" "CD2A" "CD0A" "CCEA" "CCCA" "CCAA" "CC8A" "CC6A" "CC4A" "CC2A" "CC0A" "CBEA" "CBCA" "CBAA" "CB8A")
   hx2 ("CB6A" "CB4A" "CB2A" "CB0A" "CAEA" "CACA" "CAAA" "CA8A" "CA6A" "CA4A" "CA2A" "CA0A" "C9EA" "C9CA" "C9AA" "C98A")
   hx2 ("C96A" "C94A" "C92A" "C90A" "C8EA" "C8CA" "C8AA" "C88A" "C86A" "C84A" "C82A" "C80A" "C7EA" "C7CA" "C7AA" "C78A")
   hx2 ("C76A" "C74A" "C72A" "C70A" "C6EA" "C6CA" "C6AA" "C68A" "C66A" "C64A" "C62A" "C60A" "C5EA" "C5CA" "C5AA" "C58A")
   hx2 ("C56A" "C54A" "C52A" "C50A" "C4EA" "C4CA" "C4AA" "C48A" "C46A" "C44A" "C42A" "C40A" "C3EA" "C3CA" "C3AA" "C38A")
   hx2 ("C36A" "C34A" "C32A" "C30A" "C2EA" "C2CA" "C2AA" "C28A" "C26A" "C24A" "C22A" "C20A" "C1EA" "C1CA" "C1AA" "C18A")
   hx2 ("C16A" "C14A" "C12A" "C10A" "C0EA" "C0CA" "C0AA" "C08A" "C06A" "C04A" "C02A" "C00A" "BFEA" "BFCA" "BFAA" "BF8A")
   hx2 ("BF6A" "BF4A" "BF2A" "BF0A" "BEEA" "BECA" "BEAA" "BE8A" "BE6A" "BE4A" "BE2A" "BE0A" "BDEA" "BDCA" "BDAA" "BD8A")
   hx2 ("BD6A" "BD4A" "BD2A" "BD0A" "BCEA" "BCCA" "BCAA" "BC8A" "BC6A" "BC4A" "BC2A" "BC0A" "BBEA" "B2E0" "B568" "B548")
   hx2 ("BB6A" "BB4A" "BB2A" "BB0A" "BAEA" "BACA" "BAAA" "BA8A" "BA6A" "BA4A" "BA2A" "BA0A" "B9EA" "B9CA" "B9AA" "B98A")
   hx2 ("B96A" "B94A" "B92A" "B90A" "B8EA" "B8CA" "B8AA" "B88A" "B86A" "B84A" "B82A" "B80A" "B7EA" "B7CA" "B7AA" "B78A")
   hx2 ("B76A" "B74A" "B72A" "B70A" "B6EA" "B6CA" "B6AA" "B68A" "B66A" "B64A" "B62A" "B60A" "B5EA" "B5CA" "B5AA" "B58A")
   hx2 ("B56A" "B54A" "B52A" "B50A" "B4EA" "B4CA" "B4AA" "B48A" "B46A" "B44A" "B42A" "B40A" "B3EA" "B3CA" "B3AA" "B38A")
   hx2 ("B36A" "B34A" "B32A" "B30A" "B2EA" "B2CA" "B2AA" "B28A" "B26A" "B24A" "B22A" "B20A" "B1EA" "B1CA" "B1AA" "B18A")
   hx2 ("B16A" "B14A" "B12A" "B10A" "B0EA" "B0CA" "B0AA" "B08A" "B06A" "B04A" "B02A" "B00A" "AFEA" "AFCA" "AFAA" "AF8A")
   hx2 ("AF6A" "AF4A" "AF2A" "AF0A" "AEEA" "AECA" "AEAA" "AE8A" "AE6A" "AE4A" "AE2A" "AE0A" "ADEA" "ADCA" "ADAA" "AD8A")
   hx2 ("AD6A" "AD4A" "AD2A" "AD0A" "ACEA" "ACCA" "ACAA" "AC8A" "AC6A" "AC4A" "AC2A" "AC0A" "ABEA" "ABCA" "ABAA" "AB8A")
   hx2 ("AB6A" "AB4A" "AB2A" "AB0A" "AAEA" "AACA" "AAAA" "AA8A" "AA6A" "AA4A" "AA2A" "AA0A" "A9EA" "A9CA" "A9AA" "A98A")
   hx2 ("A96A" "A94A" "A92A" "A90A" "A8EA" "A8CA" "A8AA" "A88A" "A86A" "A84A" "A82A" "A80A" "A7EA" "A7CA" "A7AA" "A78A")
   hx2 ("A76A" "A74A" "A72A" "A70A" "A6EA" "A6CA" "A6AA" "A68A" "A66A" "A64A" "A62A" "A60A" "A5EA" "A5CA" "A5AA" "A58A")
   hx2 ("A56A" "A54A" "A52A" "A50A" "A4EA" "A4CA" "A4AA" "A48A" "A46A" "A44A" "A42A" "A40A" "A3EA" "A3CA" "A3AA" "A38A")
   hx2 ("A36A" "A34A" "A32A" "A30A" "A2EA" "A2CA" "A2AA" "A28A" "A26A" "A24A" "A22A" "A20A" "A1EA" "A1CA" "A1AA" "A18A")
   hx2 ("A16A" "A14A" "A12A" "A10A" "A0EA" "A0CA" "A0AA" "A08A" "A06A" "A04A" "A02A" "A00A" "9FEA" "9FCA" "9FAA" "9F8A")
   hx2 ("9F6A" "9F4A" "9F2A" "9F0A" "9EEA" "9ECA" "9EAA" "9E8A" "9E6A" "9E4A" "9E2A" "9E0A" "9DEA" "9DCA" "9DAA" "9D8A")
   hx2 ("9D6A" "9D4A" "9D2A" "9D0A" "9CEA" "9CCA" "9CAA" "9C8A" "9C6A" "9C4A" "9C2A" "9C0A" "9BEA" "9BCA" "9BAA" "9B8A")
   hx2 ("9B6A" "9B4A" "9B2A" "9B0A" "9AEA" "9ACA" "9AAA" "9A8A" "9A6A" "9A4A" "9A2A" "9A0A" "99EA" "99CA" "99AA" "998A")
   hx2 ("996A" "994A" "992A" "990A" "98EA" "98CA" "98AA" "988A" "986A" "984A" "982A" "980A" "97EA" "97CA" "97AA" "978A")
   hx2 ("976A" "974A" "972A" "970A" "96EA" "96CA" "96AA" "968A" "966A" "964A" "962A" "960A" "95EA" "95CA" "95AA" "958A")
   hx2 ("956A" "954A" "952A" "950A" "94EA" "94CA" "94AA" "948A" "946A" "944A" "942A" "940A" "93EA" "93CA" "93AA" "938A")
   hx2 ("936A" "934A" "932A" "930A" "92EA" "92CA" "92AA" "928A" "926A" "924A" "922A" "920A" "91EA" "91CA" "91AA" "918A")
   hx2 ("916A" "914A" "912A" "910A" "90EA" "90CA" "90AA" "908A" "906A" "904A" "902A" "900A" "8FEA" "8FCA" "8FAA" "8F8A")
   hx2 ("8F6A" "8F4A" "8F2A" "8F0A" "8EEA" "8ECA" "8EAA" "8E8A" "8E6A" "8E4A" "8E2A" "8E0A" "8DEA" "8DCA" "8DAA" "8D8A")
   hx2 ("8D6A" "8D4A" "8D2A" "8D0A" "8CEA" "8CCA" "8CAA" "8C8A" "8C6A" "8C4A" "8C2A" "8C0A" "8BEA" "8BCA" "8BAA" "8B8A")
   hx2 ("8B6A" "8B4A" "8B2A" "8B0A" "8AEA" "8ACA" "8AAA" "8A8A" "8A6A" "8A4A" "8A2A" "8A0A" "89EA" "89CA" "89AA" "898A")
   hx2 ("896A" "894A" "892A" "890A" "88EA" "88CA" "88AA" "888A" "886A" "884A" "882A" "880A" "87EA" "87CA" "87AA" "878A")
   hx2 ("876A" "874A" "872A" "870A" "86EA" "86CA" "86AA" "868A" "866A" "864A" "862A" "860A" "85EA" "85CA" "85AA" "858A")
   hx2 ("856A" "854A" "852A" "850A" "84EA" "84CA" "84AA" "848A" "846A" "844A" "842A" "840A" "83EA" "83CA" "83AA" "838A")
   hx2 ("836A" "834A" "832A" "830A" "82EA" "82CA" "82AA" "828A" "826A" "824A" "822A" "820A" "81EA" "81CA" "81AA" "818A")
   hx2 ("816A" "814A" "812A" "810A" "80EA" "80CA" "80AA" "808A" "806A" "804A" "802A" "800A" "7FEA" "7FCA" "7FAA" "7F8A")
   hx2 ("7F6A" "7F4A" "7F2A" "7F0A" "7EEA" "7ECA" "7EAA" "7E8A" "7E6A" "7E4A" "7E2A" "7E0A" "7DEA" "7DCA" "7DAA" "7D8A")
   hx2 ("7D6A" "7D4A" "7D2A" "7D0A" "7CEA" "7CCA" "7CAA" "7C8A" "7C6A" "7C4A" "7C2A" "7C0A" "7BEA" "7BCA" "7BAA" "7B8A")
   hx2 ("7B6A" "7B4A" "7B2A" "7B0A" "7AEA" "7ACA" "7AAA" "7A8A" "7A6A" "7A4A" "7A2A" "7A0A" "79EA" "79CA" "79AA" "798A")
   hx2 ("796A" "794A" "792A" "790A" "78EA" "78CA" "78AA" "788A" "786A" "784A" "782A" "780A" "77EA" "77CA" "77AA" "778A")
   hx2 ("776A" "774A" "772A" "770A" "76EA" "76CA" "76AA" "768A" "766A" "764A" "762A" "760A" "75EA" "75CA" "75AA" "758A")
   hx2 ("756A" "754A" "752A" "750A" "74EA" "74CA" "74AA" "748A" "746A" "744A" "742A" "740A" "73EA" "73CA" "73AA" "738A")
   hx2 ("736A" "734A" "732A" "730A" "72EA" "72CA" "72AA" "728A" "726A" "724A" "722A" "720A" "71EA" "71CA" "71AA" "718A")
   hx2 ("716A" "714A" "712A" "710A" "70EA" "70CA" "70AA" "708A" "706A" "704A" "702A" "700A" "6FEA" "6FCA" "6FAA" "6F8A")
   hx2 ("6F6A" "6F4A" "6F2A" "6F0A" "6EEA" "6ECA" "6EAA" "6E8A" "6E6A" "6E4A" "6E2A" "6E0A" "6DEA" "6DCA" "6DAA" "6D8A")
   hx2 ("6D6A" "6D4A" "6D2A" "6D0A" "6CEA" "6CCA" "6CAA" "6C8A" "6C6A" "6C4A" "6C2A" "6C0A" "6BEA" "6BCA" "6BAA" "6B8A")
   hx2 ("6B6A" "6B4A" "6B2A" "6B0A" "6AEA" "6ACA" "6AAA" "6A8A" "6A6A" "6A4A" "6A2A" "6A0A" "69EA" "60F0" "6368" "6348")
   hx2 ("696A" "694A" "692A" "690A" "68EA" "68CA" "68AA" "688A" "686A" "684A" "682A" "680A" "67EA" "67CA" "67AA" "678A")
   hx2 ("676A" "674A" "672A" "670A" "66EA" "66CA" "66AA" "668A" "666A" "664A" "662A" "660A" "65EA" "65CA" "65AA" "658A")
   hx2 ("656A" "654A" "652A" "650A" "6B26" "6DE1" "6E9C" "5E48" "5E28" "5E08" "5DE8" "5DC8" "5DA8" "5D88" "5D68" "5D48")
   hx2 ("5D28" "5D08" "5CE8" "5CC8" "5CA8" "5C88" "5C68" "5C48" "5C28" "5C08" "5BE8" "5BC8" "5BA8" "5B88" "5B68" "5B48")
   hx2 ("5B28" "5B08" "5AE8" "5AC8" "5AA8" "5A88" "5A68" "5A48" "5A28" "5A08" "59E8" "59C8" "59A8" "5988" "5968" "5948")
   hx2 ("5928" "5908" "58E8" "58C8" "58A8" "5888" "5868" "5848" "5828" "5808" "57E8" "57C8" "57A8" "5788" "5768" "5748")
   hx2 ("5D6A" "5D4A" "5D2A" "5D0A" "5CEA" "5CCA" "5CAA" "5C8A" "5C6A" "5C4A" "5C2A" "5C0A" "5BEA" "5BCA" "5BAA" "5B8A")
   hx2 ("5B6A" "5B4A" "5B2A" "5B0A" "5AEA" "5ACA" "5AAA" "5A8A" "5A6A" "5A4A" "5A2A" "5A0A" "59EA" "59CA" "59AA" "598A")
   hx2 ("596A" "594A" "592A" "590A" "58EA" "58CA" "58AA" "588A" "586A" "584A" "582A" "580A" "57EA" "57CA" "57AA" "578A")
   hx2 ("576A" "574A" "572A" "570A" "56EA" "56CA" "56AA" "568A" "566A" "564A" "562A" "560A" "55EA" "55CA" "55AA" "558A")
   hx2 ("556A" "554A" "552A" "550A" "54EA" "54CA" "54AA" "548A" "546A" "544A" "542A" "540A" "53EA" "53CA" "53AA" "538A")
   hx2 ("536A" "534A" "532A" "530A" "52EA" "52CA" "52AA" "528A" "526A" "524A" "522A" "520A" "51EA" "51CA" "51AA" "518A")
   hx2 ("516A" "514A" "512A" "510A" "50EA" "50CA" "50AA" "508A" "506A" "504A" "502A" "500A" "4FEA" "4FCA" "4FAA" "4F8A")
   hx2 ("4F6A" "4F4A" "4F2A" "4F0A" "4EEA" "4ECA" "4EAA" "4E8A" "4E6A" "4E4A" "4E2A" "4E0A" "4DEA" "4DCA" "4DAA" "4D8A")
   hx2 ("4D6A" "4D4A" "4D2A" "4D0A" "4CEA" "4CCA" "4CAA" "4C8A" "4C6A" "4C4A" "4C2A" "4C0A" "4BEA" "4BCA" "4BAA" "4B8A")
   hx2 ("4B6A" "4B4A" "4B2A" "4B0A" "4AEA" "4ACA" "4AAA" "4A8A" "4A6A" "4A4A" "4A2A" "4A0A" "49EA" "49CA" "49AA" "498A")
   hx2 ("496A" "494A" "492A" "490A" "48EA" "48CA" "48AA" "488A" "486A" "484A" "482A" "480A" "47EA" "47CA" "47AA" "478A")
   hx2 ("476A" "474A" "472A" "470A" "46EA" "46CA" "46AA" "468A" "466A" "464A" "462A" "460A" "45EA" "45CA" "45AA" "458A")
   hx2 ("456A" "454A" "452A" "450A" "44EA" "44CA" "44AA" "448A" "446A" "444A" "442A" "440A" "43EA" "43CA" "43AA" "438A")
   hx2 ("436A" "434A" "432A" "430A" "42EA" "42CA" "42AA" "428A" "426A" "424A" "422A" "420A" "41EA" "41CA" "41AA" "418A")
   hx2 ("416A" "414A" "412A" "410A" "40EA" "40CA" "40AA" "408A" "406A" "404A" "402A" "400A" "3FEA" "3FCA" "3FAA" "3F8A")
   hx2 ("3F6A" "3F4A" "3F2A" "3F0A" "3EEA" "3ECA" "3EAA" "3E8A" "3E6A" "3E4A" "3E2A" "3E0A" "3DEA" "3DCA" "3DAA" "3D8A")
   hx2 ("3D6A" "3D4A" "3D2A" "3D0A" "3CEA" "3CCA" "3CAA" "3C8A" "3C6A" "3C4A" "3C2A" "3C0A" "3BEA" "3BCA" "3BAA" "3B8A")
   hx2 ("3B6A" "3B4A" "3B2A" "3B0A" "3AEA" "3ACA" "3AAA" "3A8A" "3A6A" "3A4A" "3A2A" "3A0A" "39EA" "39CA" "39AA" "398A")
   hx2 ("396A" "394A" "392A" "390A" "38EA" "38CA" "38AA" "388A" "386A" "384A" "382A" "380A" "37EA" "37CA" "37AA" "378A")
   hx2 ("376A" "374A" "372A" "370A" "36EA" "36CA" "36AA" "368A" "366A" "364A" "362A" "360A" "35EA" "35CA" "35AA" "358A")
   hx2 ("356A" "354A" "352A" "350A" "34EA" "34CA" "34AA" "348A" "346A" "344A" "342A" "340A" "33EA" "33CA" "33AA" "338A")
   hx2 ("336A" "334A" "332A" "330A" "32EA" "32CA" "32AA" "328A" "326A" "324A" "322A" "320A" "31EA" "28F2" "2B68" "2B48")
   hx2 ("3C2B" "3C0B" "3BEB" "3BCB" "3BAB" "3B8B" "3B6B" "3B4B" "3B2B" "3B0B" "3AEB" "3ACB" "3AAB" "3A8B" "3A6B" "3A4B")
   hx2 ("3A2B" "3A0B" "39EB" "39CB" "39AB" "398B" "396B" "394B" "392B" "390B" "38EB" "38CB" "38AB" "388B" "386B" "384B")
   hx2 ("382B" "380B" "37EB" "37CB" "37AB" "378B" "376B" "374B" "372B" "370B" "36EB" "36CB" "36AB" "368B" "366B" "364B")
   hx2 ("362B" "360B" "35EB" "35CB" "35AB" "358B" "356B" "354B" "352B" "350B" "34EB" "34CB" "34AB" "348B" "346B" "344B")
   hx2 ("344B" "342B" "340B" "33EB" "33CB" "33AB" "338B" "336B" "334B" "332B" "330B" "32EB" "32CB" "32AB" "328B" "326B")
   hx2 ("324B" "322B" "320B" "31EB" "31CB" "31AB" "318B" "316B" "314B" "312B" "310B" "30EB" "30CB" "30AB" "308B" "306B")
   hx2 ("304B" "302B" "300B" "2FEB" "2FCB" "2FAB" "2F8B" "2F6B" "2F4B" "2F2B" "2F0B" "2EEB" "2ECB" "2EAB" "2E8B" "2E6B")
   hx2 ("2E4B" "2E2B" "2E0B" "2DEB" "2DCB" "2DAB" "2D8B" "2D6B" "2D4B" "2D2B" "2D0B" "2CEB" "2CCB" "2CAB" "2C8B" "2C6B")
   hx2 ("2C4B" "2C2B" "2C0B" "2BEB" "2BCB" "2BAB" "2B8B" "2B6B" "2B4B" "2B2B" "2B0B" "2AEB" "2ACB" "2AAB" "2A8B" "2A6B")
   hx2 ("2A4B" "2A2B" "2A0B" "29EB" "29CB" "29AB" "298B" "296B" "294B" "292B" "290B" "28EB" "28CB" "28AB" "288B" "286B")
   hx2 ("284B" "282B" "280B" "27EB" "27CB" "27AB" "278B" "276B" "274B" "272B" "270B" "26EB" "26CB" "26AB" "268B" "266B")
   hx2 ("264B" "262B" "260B" "25EB" "25CB" "25AB" "258B" "256B" "254B" "252B" "250B" "24EB" "24CB" "24AB" "248B" "246B")
   hx2 ("244B" "242B" "240B" "23EB" "23CB" "23AB" "238B" "236B" "234B" "232B" "230B" "22EB" "22CB" "22AB" "228B" "226B")
   hx2 ("224B" "222B" "220B" "21EB" "21CB" "21AB" "218B" "216B" "214B" "212B" "210B" "20EB" "20CB" "20AB" "208B" "206B")
   hx2 ("204B" "202B" "200B" "1FEB" "1FCB" "1FAB" "1F8B" "1F6B" "1F4B" "1F2B" "1F0B" "1EEB" "1ECB" "1EAB" "1E8B" "1E6B")
   hx2 ("1E4B" "1E2B" "1E0B" "1DEB" "1DCB" "1DAB" "1D8B" "1D6B" "1D4B" "1D2B" "1D0B" "1CEB" "1CCB" "1CAB" "1C8B" "1C6B")
   hx2 ("1C4B" "1C2B" "1C0B" "1BEB" "1BCB" "1BAB" "1B8B" "1B6B" "106A" "104A" "102A" "100A" "FEA" "FCA" "FAA" "F8A")
   hx2 ("F6A" "668" "8E8" "8C8" "8A8" "888" "868" "848" "7D7" "194B" "7B6" "D1C" "CFC" "CB2" "CA9" "C9C")
   hx2 ("C7C" "C5C" "C3C" "C1C" "BFC" "BDC" "BBC" "B9C" "B7C" "B5E" "B2C" "B1C" "AB8" "ADC" "A9C" "2C2")
   hx2 ("528" "166B" "1667" "3FF" "9FC" "9DC" "9BC" "659" "BB8" "15A7" "FC6" "1C0" "1B1" "9CB" "82C" "1285")

: CaseData
   hx2 ("3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082")
   hx2 ("3001" "3082" "3001" "3082" "3001" "3082" "3E80" "3E80" "3001" "3082" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3A85" "3A85" "3E80" "3E80" "3E80" "3A85" "3A85" "3A85" "3E80" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3E80" "3A85" "3A85" "3A85" "3E80" "3E80" "3E80" "3E80" "5B88" "5B88" "3E80" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3A85" "3A85" "3A85" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3E80" "3E80" "3E80" "3E80" "5198" "3E80" "3E80" "3E80" "3E80" "4606" "3E80" "3E80" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3E80" "3E80" "3E80" "3E80" "3A85" "3A85" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "3E80" "3E80")
   hx2 ("3E80" "3E80" "5202" "5202" "5202" "5202" "5202" "5202" "5202" "5202" "5202" "5202" "5202" "5202" "5202" "5202")
   hx2 ("5202" "5202" "5202" "5202" "5202" "5202" "5202" "5202" "5202" "5202" "5202" "5202" "5202" "5202" "5202" "5202")
   hx2 ("5202" "2E82" "3E80" "5198" "2A14" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "4606" "4606" "4606" "4606" "4606")
   hx2 ("4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4686" "4606" "4606" "4606" "4606" "4606")
   hx2 ("4606" "4606" "4606" "4606" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "1A1B" "1A1B" "3E80" "3E80" "3E80" "3E80" "4584" "3E80" "3E80" "3E80" "298")
   hx2 ("3E80" "298" "6615" "6696" "298" "1A97" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("4584" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "4584")
   hx2 ("4584" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "4584")
   hx2 ("4584" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "2E82")
   hx2 ("7282" "2E82" "3E80" "2E82" "4902" "7481" "7481" "7481" "7481" "7383" "1A1B" "1A1B" "1A1B" "6D82" "6D82" "4902")
   hx2 ("4902" "3E80" "3E80" "2E82" "4902" "6E01" "6E01" "7501" "7501" "3E80" "1A1B" "1A1B" "1A1B" "1B02" "1B82" "1C02")
   hx2 ("1C82" "1D02" "1D82" "1E02" "1E82" "1F02" "1F82" "2002" "2082" "2102" "2182" "2202" "2282" "2302" "2382" "2402")
   hx2 ("2482" "2502" "2582" "2602" "2682" "2702" "2782" "455" "C99" "4D6" "C99" "F" "F" "F" "F" "F")
   hx2 ("10F" "F" "F" "F" "F" "F" "F" "F" "F" "F" "F" "F" "F" "F" "F" "F")
   hx2 ("F" "F" "F" "F" "F" "F" "F" "F" "F" "F" "F" "8F" "10F" "8F" "18F" "10F")
   hx2 ("F" "F" "F" "F" "F" "F" "F" "F" "F" "F" "F" "F" "F" "F" "10F" "10F")
   hx2 ("10F" "8F" "20C" "298" "298" "318" "39A" "318" "298" "298" "455" "4D6" "298" "519" "598" "614")
   hx2 ("598" "698" "709" "789" "809" "889" "909" "989" "A09" "A89" "B09" "B89" "598" "298" "C59" "C99")
   hx2 ("C59" "298" "D01" "D81" "E01" "E81" "F01" "F81" "1001" "1081" "1101" "1181" "1201" "1281" "1301" "1381")
   hx2 ("1401" "1481" "1501" "1581" "1601" "1681" "1701" "1781" "1801" "1881" "1901" "1981" "455" "298" "4D6" "1A1B")
   hx2 ("1A97" "298" "298" "298" "C99" "455" "4D6" "3E80" "298" "298" "298" "298" "298" "298" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("282C" "298" "39A" "39A" "39A" "39A" "289C" "289C" "1A1B" "289C" "2902" "29DD" "C99" "2A14" "289C" "1A1B")
   hx2 ("2A9C" "519" "2B0B" "2B8B" "1A1B" "2C02" "289C" "298" "1A1B" "2C8B" "2902" "2D5E" "2D8B" "2D8B" "2D8B" "298")
   hx2 ("298" "519" "614" "C99" "C99" "C99" "3E80" "298" "39A" "318" "298" "3E80" "3E80" "3E80" "3E80" "5405")
   hx2 ("5405" "5405" "3E80" "5405" "3E80" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405")
   hx2 ("5405" "5405" "3E80" "3E80" "3E80" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606")
   hx2 ("4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606")
   hx2 ("4606" "4606" "4606" "4606" "4606" "3E80" "501C" "501C" "4F81" "4F81" "4F81" "4F81" "4F81" "4F81" "4F81" "4F81")
   hx2 ("4F81" "4F81" "4F81" "4F81" "4F81" "4F81" "4F81" "4F81" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01")
   hx2 ("2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "C99")
   hx2 ("2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E82" "2E82" "2E82" "4902" "4902" "2E82" "2E82" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "2E82" "2E82" "2E82" "2E82" "2E82" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "5305" "4606" "5305" "5305" "3E80" "5305" "5305" "3E80" "5305" "5305" "5305" "5305")
   hx2 ("5305" "5305" "5305" "5305" "5305" "5305" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405")
   hx2 ("5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5398" "5405" "4606" "4606" "4606" "4606")
   hx2 ("4606" "4606" "4606" "5087" "5087" "4606" "5087" "5087" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "2D8B" "2D8B" "2D8B" "2D8B" "2D8B" "2D8B" "2D8B" "2D8B")
   hx2 ("2D8B" "2D8B" "2D8B" "2D8B" "840B" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "2E82" "3001")
   hx2 ("3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001")
   hx2 ("3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "5C09" "5C89" "5D09" "5D89" "5E09" "5E89" "5F09" "5F89" "6009" "6089" "4606")
   hx2 ("4606" "3A85" "3A85" "3A85" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "1A1B")
   hx2 ("1A1B" "4701" "298" "4781" "4781" "4781" "3E80" "4801" "3E80" "4881" "4881" "4902" "2E01" "2E01" "2E01" "2E01")
   hx2 ("2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2F02" "2F02" "2F02" "2F02")
   hx2 ("2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02")
   hx2 ("2F02" "2F02" "2F02" "C99" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F82" "2F02" "2F02" "4A82" "2F02")
   hx2 ("2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "4B02" "4B82" "4B82" "3E80" "4C02" "4C82" "4D01" "4D01")
   hx2 ("4D01" "4D82" "4E02" "2902" "3E80" "3E80" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082")
   hx2 ("3001" "3082" "3001" "3082" "3001" "3082" "2E82" "3B81" "3C03" "3C82" "3001" "3082" "3D81" "3E01" "3001" "3082")
   hx2 ("3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3101" "3182")
   hx2 ("3001" "3082" "3001" "3082" "3001" "3082" "2902" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001")
   hx2 ("3082" "3001" "3082" "3001" "3082" "3001" "3082" "4E82" "4F02" "3D02" "2902" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "5B10" "5B10" "5B10" "5B10" "5B10" "5B10" "7F0B" "3E80" "3E80")
   hx2 ("3E80" "7F8B" "800B" "808B" "810B" "818B" "820B" "519" "519" "C99" "455" "4D6" "2902" "3301" "3001" "3082")
   hx2 ("3001" "3082" "3381" "3001" "3082" "3401" "3401" "3001" "3082" "2902" "3481" "3501" "3581" "3001" "3082" "3401")
   hx2 ("3601" "3682" "3701" "3781" "3001" "3082" "2902" "2902" "3701" "3801" "2902" "3881" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3B81" "3C03" "3C82" "3B81" "3C03" "3C82" "3B81" "3C03" "3C82" "3001" "3082" "3001" "3082" "3001" "3082" "3001")
   hx2 ("3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3D02" "3001" "3082" "501C" "4606" "4606" "4606")
   hx2 ("4606" "3E80" "5087" "5087" "3E80" "3E80" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082")
   hx2 ("3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3201" "3001")
   hx2 ("3082" "3001" "3082" "3001" "3082" "3282" "3001" "3082" "3001" "3082" "3001" "3082" "3901" "3001" "3082" "3901")
   hx2 ("2902" "2902" "3001" "3082" "3901" "3001" "3082" "3981" "3981" "3001" "3082" "3001" "3082" "3A01" "3001" "3082")
   hx2 ("2902" "3A85" "3001" "3082" "2902" "3B02" "4D01" "3001" "3082" "3001" "3082" "3E80" "3E80" "3001" "3082" "3E80")
   hx2 ("3E80" "3001" "3082" "3E80" "3E80" "3E80" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082")
   hx2 ("3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "598" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "5398" "3E80" "3E80" "3E80" "5398" "5398" "5398" "5398" "5398" "5398" "5398" "5398" "5398")
   hx2 ("5398" "5398" "5398" "5398" "5398" "3E80" "5B10" "5405" "4606" "5405" "5405" "5405" "5405" "5405" "5405" "5405")
   hx2 ("5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405")
   hx2 ("5405" "5405" "5405" "5405" "5405" "5405" "3E80" "3E80" "5B10" "4D01" "4D01" "4D01" "4D01" "4D01" "4D01" "4D01")
   hx2 ("4D01" "4D01" "4D01" "4D01" "4D01" "4D01" "4D01" "4D01" "4D01" "4D01" "4D01" "4D01" "4D01" "4D01" "4D01" "4D01")
   hx2 ("4D01" "4D01" "4D01" "4D01" "4D01" "4D01" "4D01" "4D01" "4D01" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80")
   hx2 ("3A85" "3E80" "3E80" "3E80" "3E80" "3E80" "5C09" "5C89" "5D09" "5D89" "5E09" "5E89" "5F09" "5F89" "6009" "6089")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "2902" "2902" "2902" "3F02" "3F82" "2902" "4002" "4002" "2902" "4082")
   hx2 ("2902" "4102" "2902" "2902" "2902" "2902" "4002" "2902" "2902" "4182" "2902" "2902" "2902" "2902" "4202" "4282")
   hx2 ("2902" "2902" "2902" "2902" "2902" "4282" "2902" "2902" "4302" "2902" "2902" "4382" "2902" "2902" "2902" "2902")
   hx2 ("2902" "2902" "2902" "2902" "2902" "2902" "4402" "2902" "2902" "4402" "2902" "2902" "2902" "2902" "4402" "2902")
   hx2 ("4482" "4482" "2902" "2902" "2902" "2902" "2902" "2902" "4502" "2902" "2902" "2902" "2902" "2902" "2902" "2902")
   hx2 ("2902" "2902" "2902" "2902" "2902" "2902" "2902" "3E80" "3E80" "4584" "4584" "4584" "4584" "4584" "4584" "4584")
   hx2 ("4584" "4584" "1A1B" "1A1B" "4584" "4584" "4584" "4584" "4584" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B" "1A1B")
   hx2 ("1A1B" "1A1B" "4584" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "5101" "5101" "5101" "5101" "5101" "5101" "5101" "5101" "5101" "5101" "5101" "5101")
   hx2 ("5101" "5101" "5101" "5101" "5101" "5101" "5101" "5101" "5101" "5101" "5101" "3E80" "3E80" "4584" "5198" "5198")
   hx2 ("5198" "5198" "5198" "5198" "2E01" "2E01" "3E80" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01" "2E01")
   hx2 ("4982" "4A02" "4A02" "4A02" "4902" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02" "2F02")
   hx2 ("2F02" "2F02" "2F02" "2F02" "2F02" "4F02" "4F02" "4F02" "4F02" "4F02" "4F02" "4F02" "4F02" "4F02" "4F02" "4F02")
   hx2 ("4F02" "4F02" "4F02" "4F02" "4F02" "4606" "4606" "4606" "4606" "4606" "5198" "4606" "4606" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3E80" "3E80" "3E80" "3E80" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "3E80" "4606" "4606")
   hx2 ("4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606")
   hx2 ("4606" "4606" "4606" "4606" "4606" "3E80" "4606" "4606" "4606" "5298" "4606" "4606" "5298" "4606" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "5305" "5305" "5305" "5305" "5305" "5305" "5305")
   hx2 ("5305" "5305" "5305" "5305" "5305" "5305" "5305" "5305" "5305" "3E80" "3E80" "3E80" "3E80" "3E80" "5305" "5305")
   hx2 ("5305" "5298" "5298" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "5C89" "5D09")
   hx2 ("5D89" "5E09" "5E89" "5F09" "5F89" "6009" "6089" "640B" "648B" "650B" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "4606" "5B88" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3E80" "3E80" "3E80" "3A85" "3A85" "3A85" "3E80" "3A85" "3A85" "3A85" "3A85" "3E80" "3E80" "3E80" "3A85" "3A85")
   hx2 ("3E80" "3A85" "3E80" "3A85" "3A85" "3A85" "3A85" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606")
   hx2 ("5B88" "5B88" "5B88" "5B88" "3E80" "4606" "4606" "4606" "3E80" "4606" "4606" "4606" "4606" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "4606" "4606" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "4606")
   hx2 ("5B88" "5B88" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3E80" "3A85" "3A85" "3E80")
   hx2 ("3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3E80" "3E80" "3E80" "3E80" "5B88" "5B88" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3E80" "3E80" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3E80" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3E80" "3E80" "3A85" "3A85" "3A85" "3E80" "3E80" "3E80" "3E80" "5C09" "5C89" "5D09")
   hx2 ("5D89" "5E09" "5E89" "5F09" "5F89" "6009" "6089" "501C" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "5509" "5589" "5609" "5689" "5709" "5789" "5809" "5889" "5909")
   hx2 ("5989" "318" "5A18" "5A18" "5398" "3E80" "3E80" "4606" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405")
   hx2 ("5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "3E80" "3E80" "5405" "5405" "5405" "5405" "5405" "5405")
   hx2 ("5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405")
   hx2 ("5405" "5405" "5405" "5405" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "5405" "5405" "5405" "5405")
   hx2 ("5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405")
   hx2 ("5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "6615" "6696" "5484" "5405")
   hx2 ("5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "5405" "4606" "4606" "4606" "4606" "4606" "4606" "4606")
   hx2 ("4606" "4606" "4606" "4606" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "5B88" "5B88" "5198" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "4606" "4606" "5B88" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3E80" "3A85" "3E80" "3A85" "3A85" "3A85" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "5198" "5198" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "4606" "4606" "4606" "4606" "4606" "5484" "5484")
   hx2 ("4606" "4606" "289C" "4606" "4606" "4606" "4606" "3E80" "3E80" "709" "789" "809" "889" "909" "989" "A09")
   hx2 ("A89" "B09" "B89" "5405" "5405" "5405" "5A9C" "5A9C" "3E80" "3A85" "3A85" "3A85" "3E80" "3A85" "3E80" "3A85")
   hx2 ("3E80" "3E80" "3A85" "3A85" "3E80" "3A85" "3A85" "3A85" "3A85" "4606" "3A85" "3A85" "4606" "4606" "4606" "4606")
   hx2 ("4606" "4606" "3E80" "4606" "4606" "3A85" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3E80" "3E80" "3E80" "3E80" "4606" "4606" "5B88" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3E80" "4606" "3A85" "5B88" "5B88")
   hx2 ("5B88" "5B88" "5B88" "3E80" "4606" "5B88" "5B88" "3E80" "5B88" "5B88" "4606" "4606" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "5B88" "5B88" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3A85" "3E80" "5198" "5198")
   hx2 ("5198" "5198" "5198" "5198" "5198" "5198" "5C89" "5D09" "5D89" "5E09" "5E89" "5F09" "5F89" "6009" "6089" "640B")
   hx2 ("670B" "678B" "680B" "688B" "690B" "698B" "6A0B" "6A8B" "648B" "6B0B" "3E80" "3E80" "3E80" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3A85")
   hx2 ("3A85" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3E80" "3E80" "4606" "3A85" "5B88" "4606" "4606" "4606" "4606")
   hx2 ("4606" "4606" "4606" "4606" "5B88" "5B88" "5B88" "5B88" "4606" "3E80" "3E80" "3A85" "4606" "4606" "4606" "4606")
   hx2 ("3E80" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3E80" "3A85" "3E80" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3E80" "3E80" "4606")
   hx2 ("3E80" "5B88" "5B88" "5B88" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3A85" "3A85")
   hx2 ("3A85" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3E80" "3A85" "3E80" "3A85" "3A85" "3A85" "3A85" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3E80" "3A85" "3E80" "3A85" "3A85" "3A85" "3A85" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "4606" "3A85" "3A85" "4606" "4606")
   hx2 ("4606" "4606" "4606" "4606" "4606" "3E80" "3E80" "3E80" "3E80" "39A" "39A" "39A" "39A" "39A" "39A" "39A")
   hx2 ("39A" "39A" "39A" "39A" "39A" "39A" "39A" "39A" "39A" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3A85" "3A85" "4606" "4606" "5198" "5198" "5C09")
   hx2 ("5C89" "5D09" "5D89" "5E09" "5E89" "5F09" "5F89" "6009" "6089" "5198" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "298" "298" "318" "39A" "318" "298" "298")
   hx2 ("6615" "6696" "298" "519" "598" "614" "598" "698" "709" "789" "809" "889" "909" "989" "A09" "A89")
   hx2 ("B09" "B89" "598" "298" "C99" "C99" "C99" "298" "298" "298" "298" "298" "298" "2A14" "298" "298")
   hx2 ("298" "298" "5B10" "5B10" "5B10" "5B10" "3E80" "5C09" "5C89" "5D09" "5D89" "5E09" "5E89" "5F09" "5F89" "6009")
   hx2 ("6089" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3E80" "3E80" "3E80" "3E80" "5B88" "4606" "4606" "4606" "4606" "3E80" "3E80" "5B88" "5B88" "3E80" "3E80")
   hx2 ("5B88" "5B88" "4606" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "5B88" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3A85" "3A85" "3E80" "3A85" "3E80" "3E80" "3A85" "3A85" "3E80" "3A85" "3E80" "3E80" "3A85" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3A85" "3A85" "3E80" "3A85" "3A85")
   hx2 ("3E80" "3A85" "3A85" "3E80" "3E80" "4606" "3E80" "5B88" "5B88" "4606" "4606" "3E80" "3E80" "3E80" "3E80" "4606")
   hx2 ("4606" "3E80" "3E80" "4606" "4606" "4606" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3A85" "3A85" "3A85" "3A85" "3E80" "3A85" "3E80" "3A85" "3A85" "4606" "4606" "3E80" "3E80" "5C09" "5C89")
   hx2 ("5D09" "5D89" "5E09" "5E89" "5F09" "5F89" "6009" "6089" "3A85" "3A85" "39A" "39A" "610B" "618B" "620B" "628B")
   hx2 ("630B" "638B" "501C" "3E80" "3E80" "3E80" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3A85" "3A85" "3E80" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3E80" "3E80" "4606" "3A85" "5B88" "5B88" "4606" "4606" "4606" "4606" "4606" "3E80" "4606" "4606")
   hx2 ("5B88" "3E80" "5B88" "5B88" "4606" "3E80" "3E80" "3A85" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "5C09" "5C89" "5D09" "5D89" "5E09" "5E89" "5F09" "5F89" "6009")
   hx2 ("6089" "630B" "630B" "630B" "630B" "630B" "630B" "630B" "630B" "630B" "630B" "501C" "4606" "501C" "4606" "501C")
   hx2 ("4606" "6615" "6696" "6615" "6696" "5B88" "5B88" "4606" "4606" "4606" "3E80" "3E80" "3E80" "5B88" "5B88" "3E80")
   hx2 ("3E80" "5B88" "5B88" "4606" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "4606" "5B88" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3A85" "3A85" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3A85" "3A85" "3E80" "5B88" "4606")
   hx2 ("4606" "4606" "4606" "5B88" "4606" "3E80" "3E80" "3E80" "4606" "4606" "5B88" "4606" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "5B88" "5B88" "5B88" "4606" "4606" "4606" "4606" "4606" "4606" "4606")
   hx2 ("5B88" "5B88" "3E80" "3E80" "3E80" "5B88" "5B88" "5B88" "3E80" "5B88" "5B88" "5B88" "4606" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "5B88" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3E80" "4584" "3E80" "4606" "4606" "4606" "4606" "4606" "4606" "3E80" "3E80" "5C09")
   hx2 ("5C89" "5D09" "5D89" "5E09" "5E89" "5F09" "5F89" "6009" "6089" "3E80" "3E80" "3A85" "3A85" "3E80" "3E80" "3E80")
   hx2 ("3E80" "5C09" "5C89" "5D09" "5D89" "5E09" "5E89" "5F09" "5F89" "6009" "6089" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "4606" "4606" "4606" "4606" "4606")
   hx2 ("4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "5087" "5087" "5087" "5B88" "4606" "4606" "4606" "3E80")
   hx2 ("3E80" "5B88" "5B88" "5B88" "3E80" "5B88" "5B88" "5B88" "4606" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "5B88" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3E80" "3E80" "3E80" "4606" "3E80" "3E80" "3E80" "3E80" "5B88" "5B88" "5B88" "4606" "4606" "4606")
   hx2 ("3E80" "4606" "3E80" "5B88" "5B88" "5B88" "5B88" "5B88" "5B88" "5B88" "5B88" "4606" "5B88" "5B88" "4606" "4606")
   hx2 ("4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "4606" "5198" "5198" "5198" "5198" "5198" "5198" "5198")
   hx2 ("39A" "5198" "3E80" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "4584" "4606" "4606" "4606" "4606")
   hx2 ("4606" "4606" "4606" "4606" "5198" "5C09" "5C89" "5D09" "5D89" "5E09" "5E89" "5F09" "5F89" "6009" "6089" "5198")
   hx2 ("5198" "3E80" "3E80" "3E80" "3E80" "3A85" "501C" "501C" "501C" "5198" "5198" "5198" "5198" "5198" "5198" "5198")
   hx2 ("5198" "65B8" "5198" "5198" "5198" "5198" "5198" "5198" "501C" "501C" "501C" "501C" "501C" "4606" "4606" "501C")
   hx2 ("501C" "501C" "501C" "501C" "501C" "4606" "501C" "501C" "501C" "501C" "501C" "501C" "3E80" "3E80" "501C" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "289C")
   hx2 ("289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "3E80" "3E80" "3E80" "3E80" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3E80" "3E80" "3E80" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "1A97" "4584" "4584" "4584" "3E80" "5C09" "5C89" "5D09" "5D89" "5E09" "5E89" "5F09" "5F89" "6009")
   hx2 ("6089" "5198" "5198" "5198" "5198" "5198" "5198" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "5B88" "5B88" "4606")
   hx2 ("4606" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "20C" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "6615" "6696" "3E80" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "5198" "5198" "5198" "6B8B" "6C0B" "6C8B" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("4606" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001")
   hx2 ("3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "3001" "3082" "2E82" "2E82" "2E82")
   hx2 ("2E82" "2E82" "6D02" "3E80" "3E80" "3E80" "3E80" "6D82" "6D82" "6D82" "6D82" "6D82" "6D82" "6D82" "6D82" "6E01")
   hx2 ("6E01" "6E01" "6E01" "6E01" "6E01" "6E01" "6E01" "6D82" "6D82" "6D82" "6D82" "6D82" "6D82" "6D82" "6D82" "6E01")
   hx2 ("6E01" "6E01" "6E01" "6E01" "6E01" "6E01" "6E01" "6D82" "6D82" "6D82" "6D82" "6D82" "6D82" "3E80" "3E80" "6E01")
   hx2 ("6E01" "6E01" "6E01" "6E01" "6E01" "3E80" "3E80" "2E82" "6D82" "4902" "6D82" "4902" "6D82" "4902" "6D82" "3E80")
   hx2 ("6E01" "3E80" "6E01" "3E80" "6E01" "3E80" "6E01" "6D82" "6D82" "6D82" "6D82" "6D82" "6D82" "6D82" "6D82" "6E01")
   hx2 ("6E01" "6E01" "6E01" "6E01" "6E01" "6E01" "6E01" "6E82" "6E82" "6F02" "6F02" "6F02" "6F02" "6F82" "6F82" "7002")
   hx2 ("7002" "7082" "7082" "7102" "7102" "3E80" "3E80" "7182" "7182" "7182" "7182" "7182" "7182" "7182" "7182" "7203")
   hx2 ("7203" "7203" "7203" "7203" "7203" "7203" "7203" "7182" "7182" "7182" "7182" "7182" "7182" "7182" "7182" "7203")
   hx2 ("7203" "7203" "7203" "7203" "7203" "7203" "7203" "6D82" "6D82" "2E82" "7282" "2E82" "3E80" "2E82" "4902" "6E01")
   hx2 ("6E01" "7301" "7301" "7383" "1A1B" "7402" "1A1B" "1B02" "1B82" "1C02" "1C82" "1D02" "1D82" "1E02" "1E82" "1F02")
   hx2 ("1F82" "2002" "2082" "2102" "2182" "2202" "2282" "2302" "2382" "2402" "2482" "2502" "2582" "2602" "2682" "2702")
   hx2 ("2782" "6615" "C99" "6696" "C99" "3E80" "6D82" "6D82" "4902" "4902" "2E82" "7582" "2E82" "4902" "6E01" "6E01")
   hx2 ("7601" "7601" "7681" "1A1B" "1A1B" "1A1B" "3E80" "3E80" "2E82" "7282" "2E82" "3E80" "2E82" "4902" "7701" "7701")
   hx2 ("7781" "7781" "7383" "1A1B" "1A1B" "3E80" "20C" "20C" "20C" "20C" "20C" "20C" "20C" "782C" "20C" "20C")
   hx2 ("20C" "788C" "5B10" "5B10" "7910" "7990" "2A14" "7A34" "2A14" "2A14" "2A14" "2A14" "298" "298" "7A9D" "7B1E")
   hx2 ("6615" "7A9D" "7A9D" "7B1E" "6615" "7A9D" "298" "298" "298" "298" "298" "298" "298" "298" "7B8D" "7C0E")
   hx2 ("7C90" "7D10" "7D90" "7E10" "7E90" "782C" "318" "318" "318" "318" "318" "298" "298" "298" "298" "29DD")
   hx2 ("2D5E" "298" "298" "298" "298" "1A97" "7F0B" "2C8B" "2B0B" "2B8B" "7F8B" "800B" "808B" "810B" "818B" "820B")
   hx2 ("519" "519" "C99" "455" "4D6" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3E80" "3E80" "3E80" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C")
   hx2 ("289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "3E80" "3E80" "3E80" "3E80" "3E80" "289C")
   hx2 ("289C" "289C" "289C" "289C" "289C" "289C" "4D01" "289C" "289C" "289C" "289C" "4D01" "289C" "289C" "2902" "4D01")
   hx2 ("4D01" "4D01" "2902" "2902" "4D01" "4D01" "4D01" "2902" "289C" "4D01" "289C" "289C" "289C" "4D01" "4D01" "4D01")
   hx2 ("4D01" "4D01" "289C" "289C" "A20A" "A28A" "A30A" "A38A" "A40A" "A48A" "A50A" "A58A" "A60A" "4606" "4606" "4606")
   hx2 ("4606" "4606" "4606" "2A14" "4584" "4584" "4584" "4584" "4584" "289C" "289C" "A68A" "A70A" "A78A" "3E80" "3E80")
   hx2 ("3E80" "289C" "289C" "289C" "289C" "3E80" "289C" "289C" "289C" "289C" "3E80" "3E80" "289C" "289C" "289C" "289C")
   hx2 ("289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C")
   hx2 ("289C" "289C" "289C" "C99" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C")
   hx2 ("289C" "289C" "C99" "C99" "289C" "289C" "C99" "289C" "C99" "289C" "289C" "289C" "289C" "289C" "289C" "289C")
   hx2 ("289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "C99" "289C" "289C" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "948A" "950A" "958A" "960A" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "C99" "C99" "C99" "C99" "C99" "289C" "289C")
   hx2 ("289C" "289C" "289C" "C99" "C99" "289C" "289C" "289C" "289C" "4D01" "289C" "8281" "289C" "4D01" "289C" "8301")
   hx2 ("8381" "4D01" "4D01" "2A9C" "2902" "4D01" "4D01" "289C" "4D01" "2902" "3A85" "3A85" "3A85" "3A85" "2902" "289C")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "848A" "850A" "858A" "860A" "868A" "870A" "878A" "880A" "888A" "890A" "898A")
   hx2 ("8A0A" "8A8A" "8B0A" "8B8A" "8C0A" "8C8A" "8D0A" "8D8A" "8E0A" "8E8A" "8F0A" "8F8A" "900A" "908A" "910A" "918A")
   hx2 ("920A" "928A" "930A" "938A" "940A" "C99" "C99" "C59" "C59" "C99" "C99" "C59" "C59" "C59" "C59" "C59")
   hx2 ("C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C99" "C99")
   hx2 ("C99" "C99" "C99" "C59" "C59" "C59" "C59" "C99" "C99" "C99" "C99" "C99" "C99" "C99" "C99" "C99")
   hx2 ("C59" "C59" "C59" "C59" "C59" "C99" "C99" "C59" "C59" "C99" "C99" "C99" "C99" "C59" "C59" "C59")
   hx2 ("C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C99" "C99" "C59" "C59" "C59" "C59")
   hx2 ("C99" "C99" "C99" "C99" "C99" "C59" "C99" "C99" "C99" "C99" "C99" "C99" "C99" "289C" "289C" "C99")
   hx2 ("289C" "289C" "C99" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "C99" "289C" "289C" "289C" "289C" "289C")
   hx2 ("289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C")
   hx2 ("289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "3E80" "289C" "289C" "289C" "289C")
   hx2 ("289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C")
   hx2 ("289C" "289C" "289C" "289C" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "C99" "C59" "C59")
   hx2 ("C59" "C59" "C99" "C99" "C99" "C59" "C59" "C59" "C59" "C59" "C59" "C99" "C99" "C99" "C59" "519")
   hx2 ("519" "C99" "C59" "C59" "C99" "C99" "C99" "C59" "C59" "C59" "C59" "C99" "C59" "C99" "C59" "C99")
   hx2 ("C99" "C99" "C99" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C99" "C99" "C99" "C99")
   hx2 ("C99" "C59" "C99" "C59" "C59" "C59" "C59" "C59" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "455")
   hx2 ("4D6" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "501C" "501C" "501C" "501C")
   hx2 ("501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C")
   hx2 ("501C" "501C" "501C" "3E80" "3E80" "3E80" "3E80" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C")
   hx2 ("501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "9C1C" "9C1C" "9C1C")
   hx2 ("9C1C" "9C1C" "9C1C" "9C1C" "9C1C" "9C1C" "9C1C" "9C1C" "9C1C" "9C1C" "9C1C" "9C1C" "9C1C" "9C9C" "9C9C" "9C9C")
   hx2 ("9C9C" "9C9C" "9C9C" "9C9C" "9C9C" "9C9C" "9C9C" "9C9C" "9C9C" "9C9C" "9C9C" "9C9C" "9C9C" "7F0B" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "C59" "C99" "C59" "C99" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C99")
   hx2 ("C99" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59" "C59")
   hx2 ("C59" "C59" "C59" "C99" "C99" "C59" "C59" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "39A" "39A" "C99" "1A1B" "289C" "39A" "39A" "3E80" "289C" "C99" "C99")
   hx2 ("C99" "C99" "289C" "289C" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "5B10" "5B10")
   hx2 ("5B10" "289C" "289C" "3E80" "3E80" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C")
   hx2 ("289C" "289C" "289C" "289C" "289C" "3E80" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C")
   hx2 ("289C" "289C" "289C" "289C" "3E80" "289C" "3E80" "289C" "289C" "289C" "289C" "3E80" "3E80" "3E80" "289C" "3E80")
   hx2 ("289C" "289C" "289C" "289C" "289C" "289C" "289C" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "840B" "9D0B" "9D8B" "9E0B" "9E8B" "9F0B" "9F8B" "A00B" "A08B" "A10B" "840B")
   hx2 ("9D0B" "9D8B" "9E0B" "9E8B" "9F0B" "9F8B" "A00B" "A08B" "A10B" "289C" "3E80" "3E80" "3E80" "289C" "289C" "289C")
   hx2 ("289C" "289C" "289C" "289C" "289C" "C59" "C59" "C59" "C59" "289C" "289C" "289C" "289C" "289C" "289C" "289C")
   hx2 ("289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "289C" "501C" "289C")
   hx2 ("289C" "289C" "289C" "289C" "3E80" "3E80" "3E80" "3E80" "3E80" "630B" "630B" "630B" "630B" "630B" "630B" "630B")
   hx2 ("630B" "630B" "630B" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C")
   hx2 ("501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C")
   hx2 ("501C" "501C" "501C" "3E80" "3E80" "3E80" "501C" "610B" "618B" "620B" "628B" "A80B" "A88B" "A90B" "A98B" "AA0B")
   hx2 ("640B" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C")
   hx2 ("501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "289C" "3E80" "289C" "289C")
   hx2 ("289C" "3E80" "289C" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "2C8B" "2B0B" "2B8B" "7F8B")
   hx2 ("800B" "808B" "810B" "818B" "820B" "968B" "970B" "978B" "980B" "988B" "990B" "998B" "9A0B" "9A8B" "9B0B" "9B8B")
   hx2 ("2C8B" "2B0B" "2B8B" "7F8B" "800B" "808B" "810B" "818B" "820B" "968B" "970B" "978B" "980B" "988B" "990B" "998B")
   hx2 ("9A0B" "9A8B" "9B0B" "9B8B" "501C" "501C" "501C" "501C" "20C" "298" "298" "298" "289C" "4584" "3A85" "A18A")
   hx2 ("455" "4D6" "455" "4D6" "455" "4D6" "455" "4D6" "455" "4D6" "289C" "289C" "455" "4D6" "455" "4D6")
   hx2 ("455" "4D6" "455" "4D6" "2A14" "6615" "6696" "6696" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "3E80" "3E80")
   hx2 ("3E80" "4606" "4606" "1A1B" "1A1B" "4584" "4584" "3E80" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85")
   hx2 ("3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3A85" "3E80" "501C" "501C" "630B" "630B" "630B" "630B" "501C" "501C")
   hx2 ("501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "501C" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "AA93" "AA93" "AA93" "AA93" "AA93")
   hx2 ("AA93" "AA93" "AA93" "AA93" "AA93" "AA93" "AA93" "AA93" "AA93" "AA93" "AA93" "AA93" "AA93" "AA93" "AA93" "AA93")
   hx2 ("AA93" "AA93" "AA93" "AA93" "AA93" "AA93" "AA93" "AA93" "AA93" "AA93" "AA93" "AB12" "AB12" "AB12" "AB12" "AB12")
   hx2 ("AB12" "AB12" "AB12" "AB12" "AB12" "AB12" "AB12" "AB12" "AB12" "AB12" "AB12" "AB12" "AB12" "AB12" "AB12" "AB12")
   hx2 ("AB12" "AB12" "AB12" "AB12" "AB12" "AB12" "AB12" "AB12" "AB12" "AB12" "AB12" "5305" "5305" "5305" "5305" "5305")
   hx2 ("5305" "5305" "5305" "5305" "519" "5305" "5305" "5305" "5305" "5305" "5305" "5305" "5305" "5305" "5305" "5305")
   hx2 ("5305" "5305" "3E80" "5305" "5305" "5305" "5305" "5305" "3E80" "5305" "3E80" "4606" "4606" "4606" "4606" "3E80")
   hx2 ("3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "3E80" "298" "2A14" "2A14" "1A97" "1A97")
   hx2 ("6615" "6696" "6615" "6696" "6615" "6696" "6615" "6696" "6615" "6696" "6615" "6696" "3E80" "3E80" "3E80" "3E80")
   hx2 ("298" "298" "298" "298" "1A97" "1A97" "1A97" "598" "298" "598" "3E80" "298" "598" "298" "298" "2A14")
   hx2 ("6615" "6696" "6615" "6696" "6615" "6696" "318" "298" "D01" "D81" "E01" "E81" "F01" "F81" "1001" "1081")
   hx2 ("1101" "1181" "1201" "1281" "1301" "1381" "1401" "1481" "1501" "1581" "1601" "1681" "1701" "1781" "1801" "1881")
   hx2 ("1901" "1981" "6615" "298" "6696" "1A1B" "1A97")

: CaseUpper
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "FFE0" "FFE0" "FFE0" "FFE0" "FFE0" "FFE0" "FFE0" "FFE0" "FFE0" "FFE0")
   hx2 ("FFE0" "FFE0" "FFE0" "FFE0" "FFE0" "FFE0" "FFE0" "FFE0" "FFE0" "FFE0" "FFE0" "FFE0" "FFE0" "FFE0" "FFE0" "FFE0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "2E7" "0" "0" "0" "0" "0" "FFE0" "79")
   hx2 ("0" "FFFF" "0" "FF18" "0" "FED4" "0" "0" "0" "0" "0" "0" "0" "61" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "38" "0" "FFFF" "FFFE" "FFB1" "0" "0" "0" "FF2E" "FF32")
   hx2 ("FF33" "FF36" "FF35" "FF31" "FF2F" "FF2D" "FF2B" "FF2A" "FF26" "FF27" "FF25" "0" "0" "54" "0" "0")
   hx2 ("0" "0" "0" "FFDA" "FFDB" "FFE1" "FFC0" "FFC1" "FFC2" "FFC7" "0" "FFD1" "FFCA" "FFAA" "FFB0" "0")
   hx2 ("0" "0" "0" "0" "FFD0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "FFC5" "8" "0" "4A" "56" "64")
   hx2 ("80" "70" "7E" "8" "0" "9" "0" "0" "E3DB" "0" "0" "7" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "FFF0" "FFF0" "FFF0" "FFF0" "FFF0" "FFF0" "FFF0")
   hx2 ("FFF0" "FFF0" "FFF0" "FFF0" "FFF0" "FFF0" "FFF0" "FFF0" "FFF0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "FFE6" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0")

: CaseLower
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "20" "20" "20" "20" "20" "20")
   hx2 ("20" "20" "20" "20" "20" "20" "20" "20" "20" "20" "20" "20" "20" "20" "20" "20")
   hx2 ("20" "20" "20" "20" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "20" "0" "0" "0")
   hx2 ("1" "0" "FF39" "0" "FF87" "0" "D2" "CE" "CD" "4F" "CA" "CB" "CF" "0" "D3" "D1")
   hx2 ("D5" "D6" "DA" "D9" "DB" "0" "0" "2" "1" "0" "0" "FF9F" "FFC8" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "26" "25")
   hx2 ("40" "3F" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "50")
   hx2 ("0" "0" "30" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "FFF8" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "FFF8" "0" "FFB6" "FFF7" "0" "FFAA" "FF9C" "0" "FF90" "FFF9" "FF80" "FF82")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "E2A3" "DF41" "DFBA" "0" "10" "10" "10" "10" "10" "10" "10")
   hx2 ("10" "10" "10" "10" "10" "10" "10" "10" "10" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "1A" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")
   hx2 ("0" "0" "0" "0" "0" "0" "0")

# Bytes
:: Tio      byte 0               # Terminal I/O

: Repl      byte 0               # REPL flag
: PRepl     byte 0               # Parent REPL
: Jam       byte 0               # Error jam
: InBye     byte 0               # Exit status
: Sync      byte 0               # Family IPC synchronization
: Month bytes (31 31 28 31 30 31 30 31 31 30 31 30 31)

# Strings
:: _r_ asciz "r"
:: _w_ asciz "w"
:: _a_ asciz "a"
:: _ap_ asciz "a+"
:: _dot_ asciz "."

### System messages ###
# main.l
: Giveup asciz "%d %s\\n"
: ExecErr asciz "%s: Can't exec\\n"
: AllocErr asciz "No memory"
: PidSigMsg asciz "%d SIG-%d\\n"
: QuitMsg asciz "%s"
: CbErr asciz "Too many callbacks"
# flow.l
: HashBlank asciz "# "
: Redefined asciz " redefined\\n"
: SuperErr asciz "Bad super"
: ExtraErr asciz "Bad extra"
: ThrowErr asciz "Tag not found"
: Trc1 asciz " :"
: Trc2 asciz " = "
# io.l
: SetFD asciz "SETFD %s"
: FdTooHigh asciz "FD too high"
: Delim ascii " \\t\\n\\r\\\"'(),[]`~{}"
: DelimEnd
: Arrow asciz "-> "
# db.l
: RolbLog asciz "Last transaction not completed: Rollback\\n"
: IgnLog asciz "Discarding incomplete transaction\\n"
: CircFree asciz "Circular free list"
: BadChain asciz "Bad chain"
: BadCount asciz "Bad count"
# err.l
: ErrTok asciz "!? "
: Dashes asciz " -- "
: ProtErr asciz "Protected symbol"
: SymNsErr asciz "Bad symbol namespace"
: StkErr asciz "Stack overflow"
: ArgErr asciz "Bad argument"
: NumErr asciz "Number expected"
: CntErr asciz "Small number expected"
: SymErr asciz "Symbol expected"
: ExtErr asciz "External symbol expected"
: PairErr asciz "Cons pair expected"
: AtomErr asciz "Atom expected"
: LstErr asciz "List expected"
: VarErr asciz "Variable expected"
: DivErr asciz "Div/0"
: RenErr asciz "Can't rename"
: MakeErr asciz "Not making"
: ReentErr asciz "Reentrant coroutine"
: YieldErr asciz "No coroutine"
: MsgErr asciz "Bad message"
: BrkErr asciz "No Break"
: OpenErr asciz "Open error: %s"
: CloseErr asciz "Close error: %s"
: PipeErr asciz "Pipe error: %s"
: ForkErr asciz "Can't fork"
: WaitPidErr asciz "wait pid"
: BadFdErr asciz "Bad FD"
: NoFdErr asciz "No current fd"
: EofErr asciz "EOF Overrun"
: SuparErr asciz "Super parentheses mismatch"
: BadInput asciz "Bad input '%c'"
: BadDot asciz "Bad dotted pair"
: SelectErr asciz "Select error: %s"
: WrBytesErr asciz "bytes write: %s"
: WrChildErr asciz "child write: %s"
: WrSyncErr asciz "sync write: %s"
: WrJnlErr asciz "Journal write: %s"
: WrLogErr asciz "Log write: %s"
: TruncErr asciz "Log truncate error: %s"
: DbSyncErr asciz "DB fsync error: %s"
: TrSyncErr asciz "Transaction fsync error: %s"
: LockErr asciz "File lock: %s"
: DbfErr asciz "Bad DB file"
: JnlErr asciz "Bad Journal"
: IdErr asciz "Bad ID"
: DbRdErr asciz "DB read: %s"
: DbWrErr asciz "DB write: %s"
: DbSizErr asciz "DB Oversize"
: TellErr asciz "Tell PIPE_BUF"
: IpSocketErr asciz "IP socket error: %s"
: IpGetsocknameErr asciz "IP getsockname error: %s"
: IpV6onlyErr asciz "IP IPV6_V6ONLY error: %s"
: IpReuseaddrErr asciz "IP SO_REUSEADDR error: %s"
: IpBindErr asciz "IP bind error: %s"
: IpListenErr asciz "IP listen error: %s"
: UdpOvflErr asciz "UDP overflow"
: UndefErr asciz "Undefined"
: DlErr asciz "[DLL] %s"

# vi:et:ts=3:sw=3
