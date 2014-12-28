" Picolisp syntax file
" Language: Picolisp 
" Maintainer: Pedro Gomes
" Last Change: 2014 Aug 07
" Notes: The original syntax file was written by Kriangkrai Soatthiyanont

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

" Picolisp is case sensitive.
syn case match

setl iskeyword+=?,$,+,*,/,%,=,>,<,!

syn match PicoLispComment /#.*$/
syn region PicoLispCommentRegion start="#{" end="}#"
syn match PicoLispNumber /\v<[-+]?\d+(\.\d+)?>/
syn region PicoLispString start=/"/ skip=/\\\\\|\\"/ end=/"/
syn region PicoLispStringRaw start=/{\$/ end=/\$}/
syn match PicoLispParentheses /[()\[\]]/
syn keyword PicoLispSpecial NIL T *OS *DB *Solo *PPid *Pid @ @@ @@@ This *Dbg *Zap *Scl *Class *Dbs *Run *Hup *Sig1 *Sig ^ *Err *Msg *Uni *Led *Adr *Allow *Fork *Bye 
syn keyword PicoLispCond prog1 prog2 cond case if if2 ifn when unless and or nor not nand nond loop do while until for state 
syn keyword PicoLispOperator not == n== = <> =0 =T n0 nT < <= > >= match + - * / % */ ** inc dec >> lt0 ge0 gt0 abs bit? & x| \| 
syn keyword PicoLispFuncs new sym str char name sp? pat? fun? all intern extern qsym loc box? str? ext? touch zap length size format chop pack glue pad align center 
syn keyword PicoLispFuncs text wrap pre? sub? low? upp? lowc uppc fold val getd set setq def de dm recur undef redef daemon patch xchg on off onOff zero one default 
syn keyword PicoLispFuncs expr subr let let? use accu push push1 pop cut del queue fifo idx lup cache locale dirname put get prop ; =: : :: putl getl wipe ; meta atom 
syn keyword PicoLispFuncs pair lst? num? sym? flg? sp? pat? fun? box? str? ext? bool sqrt seed rand max min length size accu format pad oct hex fmt64 money
syn keyword PicoLispFuncs car cdr caar cadr cdar cddr caaar caadr cadar caddr cdaar cdadr cddar cdddr cadddr cddddr 
syn keyword PicoLispFuncs caaaar caaadr caadar caaddr cadaar cadadr caddar cdaaar cdaadr cdadar cdaddr cddaar cddadr cdddar
syn keyword PicoLispFuncs nth con cons conc circ rot list need full make made chain link yoke
syn keyword PicoLispFuncs copy mix append delete delq replace insert remove place strip split reverse flip trim clip head tail stem fin last member memq mmeq sect diff 
syn keyword PicoLispFuncs index offset assoc asoq rank sort uniq group length size val set xchg push push1 pop cut queue fifo idx balance get fill apply range load args 
syn keyword PicoLispFuncs next arg rest pass quote as pid lit eval run macro curry def de dm recur recurse undef box new type isa method meth send try super extra with 
syn keyword PicoLispFuncs bind job let let? use xor bool nil t prog at catch throw finally ! e $ sys call tick ipid opid kill quit task fork pipe later timeout abort 
syn keyword PicoLispFuncs apply pass maps map mapc maplist mapcar mapcon mapcan filter extract seek find pick cnt sum maxi mini fish by path in ipid out opid pipe ctl any 
syn keyword PicoLispFuncs sym str load hear tell key poll peek char skip eol eof from till line format scl read print println printsp prin prinl msg space beep tab flush 
syn keyword PicoLispFuncs rewind rd pr wr rpc wait sync echo info file dir lines open close port listen accept host connect nagle udp script once rc pretty pp show view 
syn keyword PicoLispFuncs here prEval mail *Class class dm rel var var: new type isa method meth send try object extend super extra with This pool journal id seq lieu lock 
syn keyword PicoLispFuncs begin commit rollback mark free dbck rel dbs dbs+ db: fmt64 tree root fetch store count leaf minKey maxKey genKey useKey init step scan iter prune 
syn keyword PicoLispFuncs zapTree chkTree db aux collect goal prove -> unify ? cmd argv opt gc raw alarm protect heap env up date time usec stamp dat$ $dat datSym datStr 
syn keyword PicoLispFuncs strDat expDat day week ultimo tim$ $tim telStr expTel locale allowed allow pwd cd chdir ctty dir dirname call tick kill quit task fork pipe 
syn keyword PicoLispFuncs timeout mail test bye
syn keyword PicoLispDebug lit test $ ! trace traceAll debug pretty pp show loc debug vi em ld lint noLint lintAll fmt64

hi default link PicoLispComment Comment
hi default link PicoLispCommentRegion Comment
hi default link PicoLispNumber Number
hi default link PicoLispString String
hi default link PicoLispStringRaw String
hi default link PicoLispSpecial Constant
hi default link PicoLispCond Conditional
hi default link PicoLispFuncs Identifier
hi default link PicoLispOperator Define
hi default link PicoLispDebug Type

hi PicoLispParentheses ctermfg=8 guifg=DarkGrey

if has("conceal")
    set conceallevel=2
    syn region picoLispTransient concealends matchgroup=picoLispString start=/"/ skip=/\\\\\|\\"/ end=/"/
    hi picoLispTransient gui=underline term=underline cterm=underline
    hi picoLispString ctermfg=red guifg=red
endif

let b:current_syntax = "picolisp"
