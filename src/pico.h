/* 24nov16abu
 * (c) Software Lab. Alexander Burger
 */

#include <stdio.h>
#include <stdint.h>
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
#include <sys/types.h>
#include <sys/time.h>
#include <sys/times.h>
#include <sys/stat.h>
#include <sys/resource.h>
#ifndef NOWAIT
#include <sys/wait.h> // tcc doen't like it
#endif
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>

#ifndef __CYGWIN__
#define MAIN main
#else
#define MAIN main2
#endif

#define WORD ((int)sizeof(long))
#define BITS (8*WORD)
#define MASK ((word)-1)
#define CELLS (1024*1024/sizeof(cell)) // Heap allocation unit 1MB
#define IHASH 4999                     // Internal hash table size (should be prime)
#define EHASH 49999                    // External hash table size (should be prime)
#define TOP 0x10000                    // Character Top

typedef unsigned long word;
typedef unsigned char byte;
typedef unsigned char *ptr;
typedef unsigned long long word2;
typedef long long adr;

#undef bool
typedef enum {NO,YES} bool;

typedef struct cell {            // PicoLisp primary data type
   struct cell *car;
   struct cell *cdr;
} cell, *any;

typedef any (*fun)(any);

typedef struct heap {
   cell cells[CELLS];
   struct heap *next;
} heap;

typedef struct child {
   pid_t pid;
   int hear, tell;
   int ofs, cnt;
   byte *buf;
} child;

typedef struct bindFrame {
   struct bindFrame *link;
   int i, cnt;
   struct {any sym; any val;} bnd[1];
} bindFrame;

typedef struct inFile {
   int fd, ix, cnt, next;
   int line, src;
   char *name;
   byte buf[BUFSIZ];
} inFile;

typedef struct outFile {
   int fd, ix;
   bool tty;
   byte buf[BUFSIZ];
} outFile;

typedef struct inFrame {
   struct inFrame *link;
   void (*get)(void);
   pid_t pid;
   int fd;
} inFrame;

typedef struct outFrame {
   struct outFrame *link;
   void (*put)(int);
   pid_t pid;
   int fd;
} outFrame;

typedef struct errFrame {
   struct errFrame *link;
   int fd;
} errFrame;

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
   int next, protect, trace;
   any cls, key, task, *make, *yoke;
   inFrame *inFrames;
   outFrame *outFrames;
   errFrame *errFrames;
   ctlFrame *ctlFrames;
   parseFrame *parser;
   void (*get)(void);
   void (*put)(int);
} stkEnv;

typedef struct catchFrame {
   struct catchFrame *link;
   any tag, fin;
   stkEnv env;
   jmp_buf rst;
} catchFrame;

/*** Macros ***/
#define Free(p)         ((p)->car=Avail, Avail=(p))
#define cellPtr(x)      ((any)((word)(x) & ~(2*WORD-1)))

/* Number access */
#define num(x)          ((word)(x))
#define numPtr(x)       ((any)(num(x)+(WORD/2)))
#define numCell(n)      ((any)(num(n)-(WORD/2)))
#define box(n)          (consNum(n,Nil))
#define unDig(x)        num(car(numCell(x)))
#define setDig(x,v)     (car(numCell(x))=(any)(v))
#define isNeg(x)        (unDig(x) & 1)
#define pos(x)          (car(numCell(x)) = (any)(unDig(x) & ~1))
#define neg(x)          (car(numCell(x)) = (any)(unDig(x) ^ 1))
#define lo(w)           num((w)&MASK)
#define hi(w)           num((w)>>BITS)

/* Symbol access */
#define symPtr(x)       ((any)&(x)->cdr)
#define val(x)          ((x)->car)
#define tail(s)         (((s)-1)->cdr)
#define tail1(s)        ((any)(num(tail(s)) & ~1))
#define Tail(s,v)       (tail(s) = (any)(num(v) | num(tail(s)) & 1))
#define ext(x)          ((any)(num(x) | 1))
#define mkExt(s)        (*(word*)&tail(s) |= 1)

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
#define caaaar(x)       (car(car(car(car(x)))))
#define caaadr(x)       (car(car(car(cdr(x)))))
#define caadar(x)       (car(car(cdr(car(x)))))
#define caaddr(x)       (car(car(cdr(cdr(x)))))
#define cadaar(x)       (car(cdr(car(car(x)))))
#define cadadr(x)       (car(cdr(car(cdr(x)))))
#define caddar(x)       (car(cdr(cdr(car(x)))))
#define cadddr(x)       (car(cdr(cdr(cdr(x)))))
#define cdaaar(x)       (cdr(car(car(car(x)))))
#define cdaadr(x)       (cdr(car(car(cdr(x)))))
#define cdadar(x)       (cdr(car(cdr(car(x)))))
#define cdaddr(x)       (cdr(car(cdr(cdr(x)))))
#define cddaar(x)       (cdr(cdr(car(car(x)))))
#define cddadr(x)       (cdr(cdr(car(cdr(x)))))
#define cdddar(x)       (cdr(cdr(cdr(car(x)))))
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
#define isNum(x)        (num(x)&(WORD/2))
#define isSym(x)        (num(x)&WORD)
#define isCell(x)       (!(num(x)&(2*WORD-2)))
#define isExt(s)        (num(tail(s))&1)
#define IsZero(n)       (!unDig(n) && !isNum(cdr(numCell(n))))

/* Evaluation */
#define EVAL(x)         (isNum(x)? x : isSym(x)? val(x) : evList(x))
#define evSubr(f,x)     (*(fun)unDig(f))(x)

/* Error checking */
#define NeedNum(ex,x)   if (!isNum(x)) numError(ex,x)
#define NeedCnt(ex,x)   if (!isNum(x) || isNum(cdr(numCell(x)))) cntError(ex,x)
#define NeedSym(ex,x)   if (!isSym(x)) symError(ex,x)
#define NeedExt(ex,x)   if (!isSym(x) || !isExt(x)) extError(ex,x)
#define NeedPair(ex,x)  if (!isCell(x)) pairError(ex,x)
#define NeedAtom(ex,x)  if (isCell(x)) atomError(ex,x)
#define NeedLst(ex,x)   if (!isCell(x) && !isNil(x)) lstError(ex,x)
#define NeedVar(ex,x)   if (isNum(x)) varError(ex,x)
#define CheckNil(ex,x)  if (isNil(x)) protError(ex,x)
#define CheckVar(ex,x)  if ((x)>=Nil && (x)<=T) protError(ex,x)

/* External symbol access */
#define Fetch(ex,x)     if (isExt(x)) db(ex,x,1)
#define Touch(ex,x)     if (isExt(x)) db(ex,x,2)

/* Globals */
extern int Repl, Chr, Slot, Spkr, Mic, Hear, Tell, Children, ExtN;
extern char **AV, *AV0, *Home;
extern child *Child;
extern heap *Heaps;
extern cell *Avail;
extern stkEnv Env;
extern catchFrame *CatchPtr;
extern struct termios OrgTermio, *Termio;
extern int InFDs, OutFDs;
extern inFile *InFile, **InFiles;
extern outFile *OutFile, **OutFiles;
extern int (*getBin)(void);
extern void (*putBin)(int);
extern any TheKey, TheCls, Thrown;
extern any Alarm, Sigio, Line, Zero, One;
extern any Intern[IHASH], Transient[IHASH], Extern[EHASH];
extern any ApplyArgs, ApplyBody, DbVal, DbTail;
extern any Nil, DB, Meth, Quote, T;
extern any Solo, PPid, Pid, At, At2, At3, This, Prompt, Dbg, Zap, Ext, Scl, Class;
extern any Run, Hup, Sig1, Sig2, Up, Err, Msg, Uni, Led, Tsm, Adr, Fork, Bye;
extern bool Break;
extern sig_atomic_t Signal[NSIG];

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
void binPrint(int,any);
any binRead(int);
int binSize(any);
adr blk64(any);
any boxChar(int,int*,any*);
any boxWord2(word2);
any brkLoad(any);
int bufSize(any);
void bufString(any,char*);
void bye(int) __attribute__ ((noreturn));
void byteSym(int,int*,any*);
void pairError(any,any) __attribute__ ((noreturn));
void charSym(int,int*,any*);
any circ(any);
void closeInFile(int);
void closeOnExec(any,int);
void closeOutFile(int);
void cntError(any,any) __attribute__ ((noreturn));
int compare(any,any);
any cons(any,any);
any consNum(word,any);
any consStr(any);
any consSym(any,any);
void newline(void);
void ctOpen(any,any,ctlFrame*);
void db(any,any,int);
int dbSize(any,any);
void digAdd(any,word);
void digDiv2(any);
void digMul(any,word);
void digMul2(any);
void digSub1(any);
any doubleToNum(double);
unsigned long ehash(any);
any endString(void);
bool eol(void);
bool equal(any,any);
void erOpen(any,any,errFrame*);
void err(any,any,char*,...) __attribute__ ((noreturn));
any evExpr(any,any);
long evCnt(any,any);
double evDouble(any,any);
any evList(any);
any evSym(any);
void execError(char*) __attribute__ ((noreturn));
void extError(any,any) __attribute__ ((noreturn));
any extOffs(int,any);
any findHash(any,any*);
int firstByte(any);
bool flush(outFile*);
void flushAll(void);
pid_t forkLisp(any);
any funq(any);
any get(any,any);
int getChar(void);
void getStdin(void);
void giveup(char*) __attribute__ ((noreturn));
bool hashed(any,any);
void heapAlloc(void);
any idx(any,any,int);
unsigned long ihash(any);
inFile *initInFile(int,char*);
outFile *initOutFile(int);
void initSymbols(void);
any intern(char*);
bool isBlank(any);
bool isLife(any);
void lstError(any,any) __attribute__ ((noreturn));
any load(any,int,any);
any loadAll(any);
any method(any);
any mkChar(int);
any mkDat(int,int,int);
any mkName(char*);
any mkStr(char*);
any mkTime(int,int,int);
any name(any);
any new64(adr,any);
any newId(any,int);
int nonblocking(int);
int numBytes(any);
void numError(any,any) __attribute__ ((noreturn));
double numToDouble(any);
any numToSym(any,int,int,int);
void outName(any);
void outNum(any);
void outString(char*);
void outWord(word);
void pack(any,int*,any*,cell*);
int pathSize(any);
void pathString(any,char*);
void pipeError(any,char*);
void popCtlFiles(void);
void popInFiles(void);
void popErrFiles(void);
void popOutFiles(void);
void pr(int,any);
void prin(any);
void prin1(any);
void print(any);
void print1(any);
void prn(long);
void protError(any,any) __attribute__ ((noreturn));
void pushCtlFiles(ctlFrame*);
void pushInFiles(inFrame*);
void pushErrFiles(errFrame*);
void pushOutFiles(outFrame*);
void put(any,any,any);
void putStdout(int);
void rdOpen(any,any,inFrame*);
any read1(int);
int rdBytes(int,byte*,int,bool);
int secondByte(any);
void setCooked(void);
void setRaw(void);
bool sharedLib(any);
void sighandler(any);
int slow(inFile*,bool);
void space(void);
bool subStr(any,any);
int symByte(any);
int symChar(any);
void symError(any,any) __attribute__ ((noreturn));
any symToNum(any,int,int,int);
word2 unBoxWord2(any);
void undefined(any,any);
void unintern(any,any*);
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
any doAdr(any);
any doAlarm(any);
any doAll(any);
any doAnd(any);
any doAny(any);
any doAppend(any);
any doApply(any);
any doArg(any);
any doArgs(any);
any doArgv(any);
any doArrow(any);
any doAsoq(any);
any doAs(any);
any doAssoc(any);
any doAt(any);
any doAtom(any);
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
any doBytes(any);
any doCaaaar(any);
any doCaaadr(any);
any doCaaar(any);
any doCaadar(any);
any doCaaddr(any);
any doCaadr(any);
any doCaar(any);
any doCadaar(any);
any doCadadr(any);
any doCadar(any);
any doCaddar(any);
any doCadddr(any);
any doCaddr(any);
any doCadr(any);
any doCall(any);
any doCar(any);
any doCase(any);
any doCasq(any);
any doCatch(any);
any doCdaaar(any);
any doCdaadr(any);
any doCdaar(any);
any doCdadar(any);
any doCdaddr(any);
any doCdadr(any);
any doCd(any);
any doCdar(any);
any doCddaar(any);
any doCddadr(any);
any doCddar(any);
any doCdddar(any);
any doCddddr(any);
any doCdddr(any);
any doCddr(any);
any doCdr(any);
any doChain(any);
any doChar(any);
any doChop(any);
any doCirc(any);
any doCircQ(any);
any doClip(any);
any doClose(any);
any doCmd(any);
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
any doDetach(any);
any doDiff(any);
any doDir(any);
any doDiv(any);
any doDm(any);
any doDo(any);
any doE(any);
any doEcho(any);
any doEnv(any);
any doEof(any);
any doEol(any);
any doEq(any);
any doEq0(any);
any doEq1(any);
any doEqT(any);
any doEqual(any);
any doErr(any);
any doEval(any);
any doExec(any);
any doExt(any);
any doExtern(any);
any doExtQ(any);
any doExtra(any);
any doExtract(any);
any doFifo(any);
any doFile(any);
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
any doFull(any);
any doFully(any);
any doFunQ(any);
any doGc(any);
any doGe(any);
any doGe0(any);
any doGet(any);
any doGetd(any);
any doGetl(any);
any doGlue(any);
any doGroup(any);
any doGt(any);
any doGt0(any);
any doHash(any);
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
any doInsert(any);
any doIntern(any);
any doIpid(any);
any doIsa(any);
any doJob(any);
any doJournal(any);
any doKey(any);
any doKids(any);
any doKill(any);
any doLast(any);
any doLe(any);
any doLe0(any);
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
any doOpid(any);
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
any doPlace(any);
any doPoll(any);
any doPool(any);
any doPop(any);
any doPopq(any);
any doPort(any);
any doPr(any);
any doPreQ(any);
any doPrin(any);
any doPrinl(any);
any doPrint(any);
any doPrintln(any);
any doPrintsp(any);
any doPrior(any);
any doProg(any);
any doProg1(any);
any doProg2(any);
any doProp(any);
any doPropCol(any);
any doProtect(any);
any doProve(any);
any doPush(any);
any doPush1(any);
any doPush1q(any);
any doPut(any);
any doPutl(any);
any doPwd(any);
any doQueue(any);
any doQuit(any);
any doQuote(any);
any doRand(any);
any doRange(any);
any doRank(any);
any doRassoc(any);
any doRaw(any);
any doRd(any);
any doRead(any);
any doRemove(any);
any doRem(any);
any doReplace(any);
any doRest(any);
any doReverse(any);
any doRewind(any);
any doRollback(any);
any doRot(any);
any doRun(any);
any doSect(any);
any doSeed(any);
any doSeek(any);
any doSemicol(any);
any doSend(any);
any doSeq(any);
any doSet(any);
any doSetCol(any);
any doSetq(any);
any doShift(any);
any doSigio(any);
any doSize(any);
any doSkip(any);
any doSort(any);
any doSpace(any);
any doSplit(any);
any doSpQ(any);
any doSqrt(any);
any doState(any);
any doStem(any);
any doStr(any);
any doStrip(any);
any doStrQ(any);
any doSub(any);
any doSubQ(any);
any doSum(any);
any doSuper(any);
any doSwap(any);
any doSym(any);
any doSymQ(any);
any doSync(any);
any doSys(any);
any doT(any);
any doTail(any);
any doTell(any);
any doText(any);
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
any doVersion(any);
any doWait(any);
any doWhen(any);
any doWhile(any);
any doWipe(any);
any doWith(any);
any doWr(any);
any doXchg(any);
any doXor(any);
any doYoke(any);
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
         return NULL;
   }
   return isNil(y) || !equal(x,y)? NULL : y;
}

static inline any memq(any x, any y) {
   any z = y;

   while (isCell(y)) {
      if (x == car(y))
         return y;
      if (z == (y = cdr(y)))
         return NULL;
   }
   return isNil(y) || x != y? NULL : y;
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
