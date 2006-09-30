/* 03sep06abu
 * (c) Software Lab. Alexander Burger
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <unistd.h>
#include <limits.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include <errno.h>
#include <fcntl.h>
#include <dirent.h>
#include <termios.h>
#include <setjmp.h>
#include <signal.h>
#include <dlfcn.h>
#include <time.h>
#include <sys/time.h>
#include <sys/times.h>
#include <sys/stat.h>
#ifndef NOWAIT
#include <sys/wait.h> // tcc doen't like it
#endif

#ifndef __CYGWIN__
#define MAIN main
#else
#define MAIN main2
#endif

#ifndef __linux__
#define fflush_unlocked fflush
#define fread_unlocked fread
#define fwrite_unlocked fwrite
#endif

#define CELLS     (1024*1024/sizeof(cell))   // Heap allocation unit 1MB
#define HASH      4999                       // Hash table size (should be prime)
#define TOP       0x10000                    // Character Top

typedef unsigned long word;
typedef unsigned char byte;
typedef unsigned char *ptr;
typedef unsigned long long word2;

typedef enum {NO,YES} bool;

typedef struct cell {            // Pico primary data type
   struct cell *car;
   struct cell *cdr;
} cell, *any;

typedef any (*fun)(any);

typedef struct heap {
   cell cells[CELLS];
   struct heap *next;
} heap;

typedef struct bindFrame {
   struct bindFrame *link;
   int i, cnt;
   struct {any sym; any val;} bnd[1];
} bindFrame;

typedef struct methFrame {
   struct methFrame *link;
   any key, cls;
} methFrame;

typedef struct inFrame {
   struct inFrame *link;
   FILE *fp;
   int next;
   pid_t pid;
} inFrame;

typedef struct outFrame {
   struct outFrame *link;
   FILE *fp;
   pid_t pid;
} outFrame;

typedef struct ctlFrame {
   struct ctlFrame *link;
   int fd;
} ctlFrame;

typedef struct parseFrame {
   any name;
   word dig, eof;
} parseFrame;

typedef struct stkEnv {
   cell *stack, *arg;
   bindFrame *bind;
   methFrame *meth;
   int next;
   any make;
   inFrame *inFiles;
   outFrame *outFiles;
   ctlFrame *ctlFiles;
   parseFrame *parser;
   void (*get)(void);
   void (*put)(int);
   bool brk;
} stkEnv;

typedef struct catchFrame {
   struct catchFrame *link;
   any tag;
   stkEnv env;
   jmp_buf rst;
} catchFrame;

/*** Macros ***/
#define Free(p)         ((p)->cdr=Avail, Avail=(p))
#define cellPtr(x)      ((any)(num(x) & ~7))

/* Number access */
#define num(x)          ((word)(x))
#define numPtr(x)       ((any)(num(x)+2))
#define numCell(n)      ((any)(num(n)-2))
#define box(n)          (consNum(n,Nil))
#define unDig(x)        num(car(numCell(x)))
#define setDig(x,v)     (car(numCell(x))=(any)(v))
#define isNeg(x)        (unDig(x) & 1)
#define pos(x)          (car(numCell(x)) = (any)(unDig(x) & ~1))
#define neg(x)          (car(numCell(x)) = (any)(unDig(x) ^ 1))
#define lo(w)           num((w) & 0xFFFFFFFF)
#define hi(w)           num((w) >> 32)

/* Symbol access */
#define symPtr(x)       ((any)(num(x)+4))
#define val(x)          (cellPtr(x)->car)
#define tail(x)         (cellPtr(x)->cdr)
#define extSym(s)       ((any)(num(s)|2))

/* Cell access */
#define car(x)          ((x)->car)
#define cdr(x)          ((x)->cdr)
#define caar(x)         (car(car(x)))
#define cadr(x)         (car(cdr(x)))
#define cdar(x)         (cdr(car(x)))
#define cddr(x)         (cdr(cdr(x)))
#define caaar(x)        (car(car(car(x))))
#define caadr(x)        (car(car(cdr(x))))
#define cadar(x)        (car(cdr(car(x))))
#define caddr(x)        (car(cdr(cdr(x))))
#define cdaar(x)        (cdr(car(car(x))))
#define cdadr(x)        (cdr(car(cdr(x))))
#define cddar(x)        (cdr(cdr(car(x))))
#define cdddr(x)        (cdr(cdr(cdr(x))))
#define cadddr(x)       (car(cdr(cdr(cdr(x)))))
#define cddddr(x)       (cdr(cdr(cdr(cdr(x)))))

#define data(c)         ((c).car)
#define Save(c)         ((c).cdr=Env.stack, Env.stack=&(c))
#define drop(c)         (Env.stack=(c).cdr)
#define Push(c,x)       (data(c)=(x), Save(c))
#define Tuck(c1,c2,x)   (data(c1)=(x), (c1).cdr=(c2).cdr, (c2).cdr=&(c1))
#define Pop(c)          (drop(c), data(c))

#define Bind(s,f)       ((f).i=0, (f).cnt=1, (f).bnd[0].sym=(s), (f).bnd[0].val=val(s), (f).link=Env.bind, Env.bind=&(f))
#define Unbind(f)       (val((f).bnd[0].sym)=(f).bnd[0].val, Env.bind=(f).link)

/* Predicates */
#define isNil(x)        ((x)==Nil)
#define isNum(x)        ((num(x)&6)==2)
#define isSym(x)        (num(x)&4)
#define isExt(x)        ((num(x)&6)==6)
#define isCell(x)       (!(num(x)&6))
#define IsZero(x)       (!unDig(x) && !isNum(cdr(numCell(x))))

/* Evaluation */
#define EVAL(x)         (isSym(x)? val(x) : (isCell(x)? evList(x) : x))
#define evSubr(f,x)     (*(fun)unDig(f))(x)

/* Error checking */
#define NeedNum(ex,x)   if (!isNum(x)) numError(ex,x)
#define NeedCnt(ex,x)   if (!isNum(x) || isNum(cdr(numCell(x)))) cntError(ex,x)
#define NeedSym(ex,x)   if (!isSym(x)) symError(ex,x)
#define NeedExt(ex,x)   if (!isExt(x)) extError(ex,x)
#define NeedCell(ex,x)  if (!isCell(x)) cellError(ex,x)
#define NeedAtom(ex,x)  if (isCell(x)) atomError(ex,x)
#define NeedLst(ex,x)   if (!isCell(x) && !isNil(x)) lstError(ex,x)
#define NeedVar(ex,x)   if (isNum(x)) varError(ex,x)
#define CheckNil(ex,x)  if (isNil(x)) protError(ex,x)
#define CheckVar(ex,x)  if ((x)>=Nil && (x)<=T) protError(ex,x)

/* External symbol access */
#define Fetch(ex,x)     if (isExt(x)) db(ex,x,1)
#define Touch(ex,x)     if (isExt(x)) db(ex,x,2)

/* Globals */
extern bool SigInt, SigTerm;
extern int Chr, Spkr, Mic, Slot, Hear, Tell, PSize, *Pipe, Trace;
extern char **AV, *Home;
extern heap *Heaps;
extern cell *Avail;
extern stkEnv Env;
extern catchFrame *CatchPtr;
extern struct termios *Termio;
extern FILE *InFile, *OutFile;
extern int (*getBin)(int);
extern void (*putBin)(int);
extern any TheKey, TheCls;
extern any Line, Zero, One, Intern[HASH], Transient[HASH], Extern[HASH];
extern any ApplyArgs, ApplyBody, DbVal, DbTail;
extern any Nil, DB, Solo, Up, At, At2, At3, This, Meth, Quote, T;
extern any Dbg, PPid, Pid, Scl, Class, Key, Led, Tsm, Err, Rst, Msg, Uni, Adr, Fork, Bye;

/* Prototypes */
void *alloc(void*,size_t);
any apply(any,any,bool,int,cell*);
void argError(any,any) __attribute__ ((noreturn));
void atomError(any,any) __attribute__ ((noreturn));
void begString(void);
void bigAdd(any,any);
int bigCompare(any,any);
any bigCopy(any);
void bigSub(any,any);
void binPrint(any);
any binRead(void);
any boxChar(int,int*,any*);
any boxWord2(word2);
void brkLoad(any);
int bufSize(any);
void bufString(any,char*);
void bye(int) __attribute__ ((noreturn));
void byteSym(int,int*,any*);
void cellError(any,any) __attribute__ ((noreturn));
void charSym(int,int*,any*);
void cntError(any,any) __attribute__ ((noreturn));
int compare(any,any);
any cons(any,any);
any consNum(word,any);
any consStr(any);
any consSym(any,any);
void crlf(void);
void ctOpen(any,any,ctlFrame*);
void db(any,any,int);
int dbSize(any,any);
void digAdd(any,word);
void digDiv2(any);
void digMul2(any);
void digSub1(any);
any doubleToNum(double);
any endString(void);
bool equal(any,any);
void err(any,any,char*,...) __attribute__ ((noreturn));
any evExpr(any,any);
long evCnt(any,any);
double evDouble(any,any);
any evList(any);
any evSym(any);
void execError(char*) __attribute__ ((noreturn));
void extError(any,any) __attribute__ ((noreturn));
any findHash(any,any*);
int firstByte(any);
pid_t forkLisp(any);
any get(any,any);
void getStdin(void);
void giveup(char*) __attribute__ ((noreturn));
unsigned long hash(any);
bool hashed(any,long,any*);
void heapAlloc(void);
void initSymbols(void);
bool isBlank(any);
bool isLife(any);
void lstError(any,any) __attribute__ ((noreturn));
any load(any,int,any);
any method(any);
any mkChar(int);
any mkDat(int,int,int);
any mkName(char*);
any mkStr(char*);
any name(any);
any newId(int);
int numBytes(any);
void numError(any,any) __attribute__ ((noreturn));
double numToDouble(any);
any numToSym(any,int,int,int);
void outName(any);
void outString(char*);
void outWord(word);
void pack(any,int*,any*,cell*);
int pathSize(any);
void pathString(any,char*);
void pipeError(any,char*);
void popCtlFiles(void);
void popInFiles(void);
void popOutFiles(void);
void pr(any);
void prin(any);
void print(any);
void prn(long);
void protError(any,any) __attribute__ ((noreturn));
void protect(bool);
void pushInFiles(inFrame*);
void pushOutFiles(outFrame*);
void pushCtlFiles(ctlFrame*);
any put(any,any,any);
void putStdout(int);
void rdOpen(any,any,inFrame*);
any read1(int);
bool rdBytes(int,byte*,int);
int secondByte(any);
void setCooked(void);
void setRaw(void);
int slow(int,byte*,int);
void space(void);
int symByte(any);
int symChar(any);
void symError(any,any) __attribute__ ((noreturn));
any symToNum(any,int,int,int);
void undefined(any,any);
void unwind (catchFrame*);
void varError(any,any) __attribute__ ((noreturn));
long waitFd(any,int,long);
bool wrBytes(int,byte*,int);
void wrOpen(any,any,outFrame*);
long xCnt(any,any);
any xSym(any);
void zapZero(any);

any doAbs(any);
any doAccept(any);
any doAdd(any);
any doAll(any);
any doAnd(any);
any doAny(any);
any doAppend(any);
any doApply(any);
any doArg(any);
any doArgs(any);
any doArgv(any);
any doAsoq(any);
any doAs(any);
any doAssoc(any);
any doAt(any);
any doAtom(any);
any doBegin(any);
any doBind(any);
any doBitAnd(any);
any doBitOr(any);
any doBitQ(any);
any doBitXor(any);
any doBool(any);
any doBox(any);
any doBoxQ(any);
any doBreak(any);
any doBy(any);
any doBye(any) __attribute__ ((noreturn));
any doCaaar(any);
any doCaadr(any);
any doCaar(any);
any doCadar(any);
any doCadddr(any);
any doCaddr(any);
any doCadr(any);
any doCall(any);
any doCar(any);
any doCase(any);
any doCatch(any);
any doCd(any);
any doCdaar(any);
any doCdadr(any);
any doCdar(any);
any doCddar(any);
any doCddddr(any);
any doCdddr(any);
any doCddr(any);
any doCdr(any);
any doChain(any);
any doChar(any);
any doChop(any);
any doCirc(any);
any doClip(any);
any doClose(any);
any doCnt(any);
any doCol(any);
any doCommit(any);
any doCon(any);
any doConc(any);
any doCond(any);
any doConnect(any);
any doCons(any);
any doCopy(any);
any doCtl(any);
any doCtty(any);
any doCut(any);
any doDate(any);
any doDbck(any);
any doDe(any);
any doDec(any);
any doDef(any);
any doDefault(any);
any doDel(any);
any doDelete(any);
any doDelq(any);
any doDir(any);
any doDiv(any);
any doDm(any);
any doDo(any);
any doE(any);
any doEcho(any);
any doEnv(any);
any doEof(any);
any doEq(any);
any doEqual(any);
any doEqual0(any);
any doEqualT(any);
any doEval(any);
any doExtern(any);
any doExtQ(any);
any doExtra(any);
any doFill(any);
any doFilter(any);
any doFin(any);
any doFinally(any);
any doFind(any);
any doFish(any);
any doFlgQ(any);
any doFlip(any);
any doFlush(any);
any doFold(any);
any doFor(any);
any doFork(any);
any doFormat(any);
any doFree(any);
any doFrom(any);
any doFunQ(any);
any doGc(any);
any doGe(any);
any doGe0(any);
any doGet(any);
any doGetl(any);
any doGt(any);
any doGt0(any);
any doHead(any);
any doHeap(any);
any doHear(any);
any doHide(any);
any doHost(any);
any doId(any);
any doIdx(any);
any doIf(any);
any doIf2(any);
any doIfn(any);
any doIn(any);
any doInc(any);
any doIndex(any);
any doInfo(any);
any doIntern(any);
any doIsa(any);
any doJob(any);
any doJournal(any);
any doKey(any);
any doKill(any);
any doLast(any);
any doLe(any);
any doLength(any);
any doLet(any);
any doLetQ(any);
any doLieu(any);
any doLine(any);
any doLines(any);
any doLink(any);
any doList(any);
any doListen(any);
any doLit(any);
any doLstQ(any);
any doLoad(any);
any doLock(any);
any doLookup(any);
any doLoop(any);
any doLowQ(any);
any doLowc(any);
any doLt(any);
any doLt0(any);
any doLup(any);
any doMade(any);
any doMake(any);
any doMap(any);
any doMapc(any);
any doMapcan(any);
any doMapcar(any);
any doMapcon(any);
any doMaplist(any);
any doMaps(any);
any doMark(any);
any doMatch(any);
any doMax(any);
any doMaxi(any);
any doMember(any);
any doMemq(any);
any doMeta(any);
any doMeth(any);
any doMethod(any);
any doMin(any);
any doMini(any);
any doMix(any);
any doMmeq(any);
any doMul(any);
any doMulDiv(any);
any doNagle(any);
any doName(any);
any doNand(any);
any doNEq(any);
any doNEq0(any);
any doNEqT(any);
any doNEqual(any);
any doNeed(any);
any doNew(any);
any doNext(any);
any doNil(any);
any doNond(any);
any doNor(any);
any doNot(any);
any doNth(any);
any doNumQ(any);
any doOff(any);
any doOffset(any);
any doOn(any);
any doOne(any);
any doOnOff(any);
any doOpen(any);
any doOpt(any);
any doOr(any);
any doOut(any);
any doPack(any);
any doPair(any);
any doPass(any);
any doPath(any);
any doPatQ(any);
any doPeek(any);
any doPick(any);
any doPipe(any);
any doPoll(any);
any doPool(any);
any doPop(any);
any doPort(any);
any doPr(any);
any doPreQ(any);
any doPrin(any);
any doPrinl(any);
any doPrint(any);
any doPrintln(any);
any doPrintsp(any);
any doProg(any);
any doProg1(any);
any doProg2(any);
any doProp(any);
any doPropCol(any);
any doProtect(any);
any doProve(any);
any doPush(any);
any doPut(any);
any doPutl(any);
any doPwd(any);
any doQueue(any);
any doQuit(any);
any doQuote(any);
any doRand(any);
any doRank(any);
any doRaw(any);
any doRd(any);
any doRead(any);
any doRem(any);
any doReplace(any);
any doRest(any);
any doReverse(any);
any doRewind(any);
any doRollback(any);
any doRot(any);
any doRpc(any);
any doRun(any);
any doSeed(any);
any doSeek(any);
any doSend(any);
any doSeq(any);
any doSet(any);
any doSetCol(any);
any doSetq(any);
any doShift(any);
any doSize(any);
any doSkip(any);
any doSort(any);
any doSpace(any);
any doSplit(any);
any doSpQ(any);
any doSqrt(any);
any doState(any);
any doStem(any);
any doStk(any);
any doStr(any);
any doStrip(any);
any doStrQ(any);
any doSub(any);
any doSubQ(any);
any doSum(any);
any doSuper(any);
any doSym(any);
any doSymQ(any);
any doSync(any);
any doSys(any);
any doT(any);
any doTail(any);
any doTell(any);
any doThrow(any);
any doTick(any);
any doTill(any);
any doTime(any);
any doTouch(any);
any doTrace(any);
any doTrim(any);
any doTry(any);
any doType(any);
any doUdp(any);
any doUnify(any);
any doUnless(any);
any doUntil(any);
any doUp(any);
any doUppQ(any);
any doUppc(any);
any doUse(any);
any doUsec(any);
any doVal(any);
any doWait(any);
any doWhen(any);
any doWhile(any);
any doWipe(any);
any doWith(any);
any doWr(any);
any doXchg(any);
any doXor(any);
any doZap(any);
any doZero(any);

static inline long unBox(any x) {
   long n = unDig(x) / 2;
   return unDig(x) & 1? -n : n;
}

static inline any boxCnt(long n) {return box(n>=0?  n*2 : -n*2+1);}

/* List element access */
static inline any nCdr(int n, any x) {
   while (--n >= 0)
      x = cdr(x);
   return x;
}

static inline any nth(int n, any x) {
   if (--n < 0)
      return Nil;
   return nCdr(n,x);
}

static inline any getn(any x, any y) {
   if (isNum(x)) {
      long n = unDig(x) / 2;

      if (isNeg(x)) {
         while (--n)
            y = cdr(y);
         return cdr(y);
      }
      if (n == 0)
         return Nil;
      while (--n)
         y = cdr(y);
      return car(y);
   }
   do
      if (isCell(car(y)) && x == caar(y))
         return cdar(y);
   while (isCell(y = cdr(y)));
   return Nil;
}

/* List length calculation */
static inline int length(any x) {
   int n;

   for (n = 0; isCell(x); x = cdr(x))
      ++n;
   return n;
}

/* Membership */
static inline any member(any x, any y) {
   any z = y;

   while (isCell(y)) {
      if (equal(x, car(y)))
         return y;
      if (z == (y = cdr(y)))
         return Nil;
   }
   return equal(x,y)? y : NULL;
}

static inline any memq(any x, any y) {
   any z = y;

   while (isCell(y)) {
      if (x == car(y))
         return y;
      if (z == (y = cdr(y)))
         return Nil;
   }
   return x == y? y : NULL;
}

static inline int indx(any x, any y) {
   int n = 1;
   any z = y;

   while (isCell(y)) {
      if (equal(x, car(y)))
         return n;
      ++n;
      if (z == (y = cdr(y)))
         return 0;
   }
   return 0;
}

/* List interpreter */
static inline any prog(any x) {
   any y;

   do
      y = EVAL(car(x));
   while (isCell(x = cdr(x)));
   return y;
}

static inline any run(any x) {
   any y;
   cell at;

   Push(at,val(At));
   do
      y = EVAL(car(x));
   while (isCell(x = cdr(x)));
   val(At) = Pop(at);
   return y;
}
