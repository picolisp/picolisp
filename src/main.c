/* 11feb16abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"
#include "vers.h"

#ifdef __CYGWIN__
#define O_ASYNC FASYNC
#endif

#if defined (__SVR4) || defined (_AIX) || defined (__hpux) || defined (__sgi)
#define O_ASYNC 0
#define GETCWDLEN 1024
#else
#define GETCWDLEN 0
#endif

/* Globals */
int Repl, Chr, Slot, Spkr, Mic, Hear, Tell, Children, ExtN;
char **AV, *AV0, *Home;
child *Child;
heap *Heaps;
cell *Avail;
stkEnv Env;
catchFrame *CatchPtr;
struct termios OrgTermio, *Termio;
int InFDs, OutFDs;
inFile *InFile, **InFiles;
outFile *OutFile, **OutFiles;
int (*getBin)(void);
void (*putBin)(int);
any TheKey, TheCls, Thrown;
any Alarm, Sigio, Line, Zero, One;
any Intern[IHASH], Transient[IHASH], Extern[EHASH];
any ApplyArgs, ApplyBody, DbVal, DbTail;
any Nil, DB, Meth, Quote, T;
any Solo, PPid, Pid, At, At2, At3, This, Prompt, Dbg, Zap, Ext, Scl, Class;
any Run, Hup, Sig1, Sig2, Up, Err, Msg, Uni, Led, Tsm, Adr, Fork, Bye;
bool Break;
sig_atomic_t Signal[NSIG];

static int TtyPid;
static word2 USec;
static struct timeval Tv;
static bool Tio, Jam;
static jmp_buf ErrRst;
static void finish(int) __attribute__ ((noreturn));
static struct rlimit ULim = {RLIM_INFINITY, RLIM_INFINITY};


/*** System ***/
static void finish(int n) {
   setCooked();
   exit(n);
}

void giveup(char *msg) {
   fprintf(stderr, "%d %s\n", (int)getpid(), msg);
   finish(1);
}

void bye(int n) {
   static bool flg;

   if (!flg) {
      flg = YES;
      unwind(NULL);
      prog(val(Bye));
   }
   flushAll();
   finish(n);
}

void execError(char *s) {
   fprintf(stderr, "%s: Can't exec\n", s);
   exit(127);
}

/* Install interrupting signal */
static void iSignal(int n, void (*foo)(int)) {
   struct sigaction act;

   act.sa_handler = foo;
   sigemptyset(&act.sa_mask);
   act.sa_flags = 0;
   sigaction(n, &act, NULL);
}

/* Signal handler */
void sighandler(any ex) {
   int i;
   bool flg;

   if (!Env.protect) {
      Env.protect = 1;
      do {
         if (Signal[SIGIO]) {
            --Signal[0], --Signal[SIGIO];
            run(Sigio);
         }
         else if (Signal[SIGUSR1]) {
            --Signal[0], --Signal[SIGUSR1];
            run(val(Sig1));
         }
         else if (Signal[SIGUSR2]) {
            --Signal[0], --Signal[SIGUSR2];
            run(val(Sig2));
         }
         else if (Signal[SIGALRM]) {
            --Signal[0], --Signal[SIGALRM];
            run(Alarm);
         }
         else if (Signal[SIGINT]) {
            --Signal[0], --Signal[SIGINT];
            if (Repl < 2)
               brkLoad(ex ?: Nil);
         }
         else if (Signal[SIGHUP]) {
            --Signal[0], --Signal[SIGHUP];
            run(val(Hup));
         }
         else if (Signal[SIGTERM]) {
            for (flg = NO, i = 0; i < Children; ++i)
               if (Child[i].pid  &&  kill(Child[i].pid, SIGTERM) == 0)
                  flg = YES;
            if (flg)
               break;
            Signal[0] = 0,  bye(0);
         }
      } while (*Signal);
      Env.protect = 0;
   }
}

static void sig(int n) {
   if (TtyPid)
      kill(TtyPid, n);
   else
      ++Signal[n], ++Signal[0];
}

static void sigTerm(int n) {
   if (TtyPid)
      kill(TtyPid, n);
   else
      ++Signal[SIGTERM], ++Signal[0];
}

static void sigChld(int n __attribute__((unused))) {
   int e, stat;
   pid_t pid;

   e = errno;
   while ((pid = waitpid(0, &stat, WNOHANG)) > 0)
      if (WIFSIGNALED(stat))
         fprintf(stderr, "%d SIG-%d\n", (int)pid, WTERMSIG(stat));
   errno = e;
}

static void tcSet(struct termios *p) {
   if (Termio)
      while (tcsetattr(STDIN_FILENO, TCSADRAIN, p)  &&  errno == EINTR);
}

static void sigTermStop(int n __attribute__((unused))) {
   sigset_t mask;

   tcSet(&OrgTermio);
   sigemptyset(&mask);
   sigaddset(&mask, SIGTSTP);
   sigprocmask(SIG_UNBLOCK, &mask, NULL);
   signal(SIGTSTP, SIG_DFL),  raise(SIGTSTP),  signal(SIGTSTP, sigTermStop);
   tcSet(Termio);
}

void setRaw(void) {
   if (Tio && !Termio) {
      *(Termio = malloc(sizeof(struct termios))) = OrgTermio;
      Termio->c_iflag = 0;
      Termio->c_oflag = OPOST+ONLCR;
      Termio->c_lflag = ISIG;
      Termio->c_cc[VMIN] = 1;
      Termio->c_cc[VTIME] = 0;
      tcSet(Termio);
      if (signal(SIGTSTP,SIG_IGN) == SIG_DFL)
         signal(SIGTSTP, sigTermStop);
   }
}

void setCooked(void) {
   tcSet(&OrgTermio);
   free(Termio),  Termio = NULL;
}

// (raw ['flg]) -> flg
any doRaw(any x) {
   if (!isCell(x = cdr(x)))
      return Termio? T : Nil;
   if (isNil(EVAL(car(x)))) {
      setCooked();
      return Nil;
   }
   setRaw();
   return T;
}

// (alarm 'cnt . prg) -> cnt
any doAlarm(any x) {
   int n = alarm((int)evCnt(x,cdr(x)));
   Alarm = cddr(x);
   return boxCnt(n);
}

// (sigio 'cnt . prg) -> cnt
any doSigio(any ex) {
   any x = EVAL(cadr(ex));
   int fd = (int)xCnt(ex,x);

   Sigio = cddr(ex);
   fcntl(fd, F_SETOWN, unBox(val(Pid)));
   fcntl(fd, F_SETFL, fcntl(fd, F_GETFL, 0) | O_NONBLOCK|O_ASYNC);
   return x;
}

// (kids) -> lst
any doKids(any ex __attribute__((unused))) {
   int i;
   any x;

   for (i = 0, x = Nil; i < Children; ++i)
      if (Child[i].pid)
         x = cons(box(Child[i].pid * 2), x);
   return x;
}

// (protect . prg) -> any
any doProtect(any x) {
   ++Env.protect;
   x = prog(cdr(x));
   --Env.protect;
   return x;
}

/* Allocate memory */
void *alloc(void *p, size_t siz) {
   if (!(p = realloc(p,siz)))
      giveup("No memory");
   return p;
}

/* Allocate cell heap */
void heapAlloc(void) {
   heap *h;
   cell *p;

   h = (heap*)alloc(NULL, sizeof(heap));
   h->next = Heaps,  Heaps = h;
   p = h->cells + CELLS-1;
   do
      Free(p);
   while (--p >= h->cells);
}

// (heap 'flg) -> cnt
any doHeap(any x) {
   long n = 0;

   x = cdr(x);
   if (isNil(EVAL(car(x)))) {
      heap *h = Heaps;
      do
         ++n;
      while (h = h->next);
      return boxCnt(n);
   }
   for (x = Avail;  x;  x = car(x))
      ++n;
   return boxCnt(n / CELLS);
}

// (adr 'var) -> num
// (adr 'num) -> var
any doAdr(any x) {
   x = cdr(x);
   if (isNum(x = EVAL(car(x))))
      return (any)(unDig(x) * WORD);
   return box(num(x) / WORD);
}

// (env ['lst] | ['sym 'val] ..) -> lst
any doEnv(any x) {
   int i;
   bindFrame *p;
   cell c1, c2;

   Push(c1, Nil);
   if (!isCell(x = cdr(x))) {
      for (p = Env.bind;  p;  p = p->link) {
         if (p->i == 0) {
            for (i = p->cnt;  --i >= 0;) {
               for (x = data(c1); ; x = cdr(x)) {
                  if (!isCell(x)) {
                     data(c1) = cons(cons(p->bnd[i].sym, val(p->bnd[i].sym)), data(c1));
                     break;
                  }
                  if (caar(x) == p->bnd[i].sym)
                     break;
               }
            }
         }
      }
   }
   else {
      do {
         Push(c2, EVAL(car(x)));
         if (isCell(data(c2))) {
            do
               data(c1) = cons(
                  isCell(car(data(c2)))?
                     cons(caar(data(c2)), cdar(data(c2))) :
                     cons(car(data(c2)), val(car(data(c2)))),
                  data(c1) );
            while (isCell(data(c2) = cdr(data(c2))));
         }
         else if (!isNil(data(c2))) {
            x = cdr(x);
            data(c1) = cons(cons(data(c2), EVAL(car(x))), data(c1));
         }
         drop(c2);
      }
      while (isCell(x = cdr(x)));
   }
   return Pop(c1);
}

// (up [cnt] sym ['val]) -> any
any doUp(any x) {
   any y, *val;
   int cnt, i;
   bindFrame *p;

   x = cdr(x);
   if (!isNum(y = car(x)))
      cnt = 1;
   else
      cnt = (int)unBox(y),  x = cdr(x),  y = car(x);
   for (p = Env.bind, val = &val(y);  p;  p = p->link) {
      if (p->i <= 0) {
         for (i = 0;  i < p->cnt;  ++i)
            if (p->bnd[i].sym == y) {
               if (!--cnt) {
                  if (isCell(x = cdr(x)))
                     return p->bnd[i].val = EVAL(car(x));
                  return p->bnd[i].val;
               }
               val = &p->bnd[i].val;
            }
      }
   }
   if (isCell(x = cdr(x)))
      return *val = EVAL(car(x));
   return *val;
}

// (sys 'any ['any]) -> sym
any doSys(any x) {
   any y;

   y = evSym(x = cdr(x));
   {
      char nm[bufSize(y)];

      bufString(y,nm);
      if (!isCell(x = cdr(x)))
         return mkStr(getenv(nm));
      y = evSym(x);
      {
#if defined (__sgi)
         char *val = malloc(sizeof(nm) + bufSize(y));

         sprintf(val, "%s=", nm); 
         bufString(y, val + sizeof(nm));
         return putenv(val)? Nil : y;
#else
         char val[bufSize(y)];

         bufString(y,val);
         return setenv(nm,val,1)? Nil : y;
#endif
      }
   }
}

/*** Primitives ***/
any circ(any x) {
   any y = x;

   if (!isCell(x))
      return NULL;
   for (;;) {
      *(word*)&car(y) |= 1;
      if (!isCell(y = cdr(y))) {
         do
            *(word*)&car(x) &= ~1;
         while (isCell(x = cdr(x)));
         return NULL;
      }
      if (num(car(y)) & 1) {
         while (x != y)
            *(word*)&car(x) &= ~1,  x = cdr(x);
         do
            *(word*)&car(x) &= ~1;
         while (y != (x = cdr(x)));
         return y;
      }
   }
}

/* Comparisons */
bool equal(any x, any y) {
   any a, b;
   bool res;

   for (;;) {
      if (x == y)
         return YES;
      if (isNum(x)) {
         if (!isNum(y)  ||  unDig(x) != unDig(y))
            return NO;
         x = cdr(numCell(x)),  y = cdr(numCell(y));
         continue;
      }
      if (isSym(x)) {
         if (!isSym(y)  || !isNum(x = name(x))  ||  !isNum(y = name(y)))
            return NO;
         continue;
      }
      if (!isCell(y))
         return NO;
      a = x, b = y;
      res = NO;
      for (;;) {
         if (!equal(car(x), (any)(num(car(y)) & ~1)))
            break;
         if (!isCell(cdr(x))) {
            res = equal(cdr(x), cdr(y));
            break;
         }
         if (!isCell(cdr(y)))
            break;
         *(word*)&car(x) |= 1,  x = cdr(x),  y = cdr(y);
         if (num(car(x)) & 1) {
            for (;;) {
               if (a == x) {
                  if (b == y) {
                     for (;;) {
                        a = cdr(a);
                        if ((b = cdr(b)) == y) {
                           res = a == x;
                           break;
                        }
                        if (a == x) {
                           res = YES;
                           break;
                        }
                     }
                  }
                  break;
               }
               if (b == y) {
                  res = NO;
                  break;
               }
               *(word*)&car(a) &= ~1,  a = cdr(a),  b = cdr(b);
            }
            do
               *(word*)&car(a) &= ~1,  a = cdr(a);
            while (a != x);
            return res;
         }
      }
      while (a != x)
         *(word*)&car(a) &= ~1,  a = cdr(a);
      return res;
   }
}

int compare(any x, any y) {
   any a, b;

   if (x == y)
      return 0;
   if (isNil(x))
      return -1;
   if (x == T)
      return +1;
   if (isNum(x)) {
      if (!isNum(y))
         return isNil(y)? +1 : -1;
      return bigCompare(x,y);
   }
   if (isSym(x)) {
      int b1, b2;
      word n1, n2;

      if (isNum(y) || isNil(y))
         return +1;
      if (isCell(y) || y == T)
         return -1;
      if (!isNum(a = name(x)))
         return !isNum(name(y))? (long)x - (long)y : -1;
      if (!isNum(b = name(y)))
         return +1;
      n1 = unDig(a), n2 = unDig(b);
      for (;;) {
         if ((b1 = n1 & 0xFF) != (b2 = n2 & 0xFF))
            return b1 - b2;
         if ((n1 >>= 8) == 0) {
            if ((n2 >>= 8) != 0)
               return -1;
            if (!isNum(a = cdr(numCell(a))))
               return !isNum(b = cdr(numCell(b)))? 0 : -1;
            if (!isNum(b = cdr(numCell(b))))
               return +1;
            n1 = unDig(a), n2 = unDig(b);
         }
         else if ((n2 >>= 8) == 0)
            return +1;
      }
   }
   if (!isCell(y))
      return y == T? -1 : +1;
   a = x, b = y;
   for (;;) {
      int n;

      if (n = compare(car(x),car(y)))
         return n;
      if (!isCell(x = cdr(x)))
         return compare(x, cdr(y));
      if (!isCell(y = cdr(y)))
         return y == T? -1 : +1;
      if (x == a && y == b)
         return 0;
   }
}

int binSize(any x) {
   if (isNum(x)) {
      int n = numBytes(x);

      if (n < 63)
         return n + 1;
      return n + 2 + (n - 63) / 255;
   }
   else if (isNil(x))
      return 1;
   else if (isSym(x))
      return binSize(name(x));
   else {
      any y = x;
      int n = 2;

      while (n += binSize(car(x)), !isNil(x = cdr(x))) {
         if (x == y)
            return n + 1;
         if (!isCell(x))
            return n + binSize(x);
      }
      return n;
   }
}

/*** Error handling ***/
void err(any ex, any x, char *fmt, ...) {
   va_list ap;
   char msg[240];
   outFrame f;
   cell c1;

   va_start(ap,fmt);
   vsnprintf(msg, sizeof(msg), fmt, ap);
   va_end(ap);
   val(Up) = ex ?: Nil;
   if (x)
      Push(c1, x);
   if (msg[0]) {
      any y;
      catchFrame *p;

      val(Msg) = mkStr(msg);
      for (p = CatchPtr;  p;  p = p->link)
         if (y = p->tag)
            while (isCell(y)) {
               if (subStr(car(y), val(Msg))) {
                  Thrown = isNil(car(y))? val(Msg) : car(y);
                  unwind(p);
                  longjmp(p->rst, 1);
               }
               y = cdr(y);
            }
   }
   Chr = ExtN = 0;
   Break = NO;
   Alarm = Line = Nil;
   f.pid = 0,  f.fd = STDERR_FILENO,  pushOutFiles(&f);
   if (InFile && InFile->name) {
      Env.put('[');
      outString(InFile->name), Env.put(':'), outWord(InFile->src);
      Env.put(']'), space();
   }
   if (ex)
      outString("!? "), print(ex), newline();
   if (x)
      print(x), outString(" -- ");
   if (msg[0]) {
      outString(msg), newline();
      if (!isNil(val(Err)) && !Jam)
         Jam = YES,  prog(val(Err)),  Jam = NO;
      if (!isatty(STDIN_FILENO) || !isatty(STDOUT_FILENO))
         bye(1);
      load(NULL, '?', Nil);
   }
   unwind(NULL);
   Env.stack = NULL;
   Env.protect = Env.trace = 0;
   Env.next = -1;
   Env.task = Nil;
   Env.make = Env.yoke = NULL;
   Env.parser = NULL;
   Env.put = putStdout;
   Env.get = getStdin;
   longjmp(ErrRst, +1);
}

// (quit ['any ['any]])
any doQuit(any x) {
   any y;

   x = cdr(x),  y = evSym(x);
   {
      char msg[bufSize(y)];

      bufString(y, msg);
      x = isCell(x = cdr(x))?  EVAL(car(x)) : NULL;
      err(NULL, x, "%s", msg);
   }
}

void argError(any ex, any x) {err(ex, x, "Bad argument");}
void numError(any ex, any x) {err(ex, x, "Number expected");}
void cntError(any ex, any x) {err(ex, x, "Small number expected");}
void symError(any ex, any x) {err(ex, x, "Symbol expected");}
void extError(any ex, any x) {err(ex, x, "External symbol expected");}
void pairError(any ex, any x) {err(ex, x, "Cons pair expected");}
void atomError(any ex, any x) {err(ex, x, "Atom expected");}
void lstError(any ex, any x) {err(ex, x, "List expected");}
void varError(any ex, any x) {err(ex, x, "Variable expected");}
void protError(any ex, any x) {err(ex, x, "Protected symbol");}

void pipeError(any ex, char *s) {err(ex, NULL, "Pipe %s error", s);}

void unwind(catchFrame *catch) {
   any x;
   int i, j, n;
   bindFrame *p;
   catchFrame *q;

   while (q = CatchPtr) {
      while (p = Env.bind) {
         if ((i = p->i) < 0) {
            j = i, n = 0;
            while (++n, ++j && (p = p->link))
               if (p->i >= 0 || p->i < i)
                  --j;
            do {
               for (p = Env.bind, j = n;  --j;  p = p->link);
               if (p->i < 0  &&  ((p->i -= i) > 0? (p->i = 0) : p->i) == 0)
                  for (j = p->cnt;  --j >= 0;) {
                     x = val(p->bnd[j].sym);
                     val(p->bnd[j].sym) = p->bnd[j].val;
                     p->bnd[j].val = x;
                  }
            } while (--n);
         }
         if (Env.bind == q->env.bind)
            break;
         if (Env.bind->i == 0)
            for (i = Env.bind->cnt;  --i >= 0;)
               val(Env.bind->bnd[i].sym) = Env.bind->bnd[i].val;
         Env.bind = Env.bind->link;
      }
      while (Env.inFrames != q->env.inFrames)
         popInFiles();
      while (Env.outFrames != q->env.outFrames)
         popOutFiles();
      while (Env.errFrames != q->env.errFrames)
         popErrFiles();
      while (Env.ctlFrames != q->env.ctlFrames)
         popCtlFiles();
      Env = q->env;
      EVAL(q->fin);
      CatchPtr = q->link;
      if (q == catch)
         return;
   }
   while (Env.bind) {
      if (Env.bind->i == 0)
         for (i = Env.bind->cnt;  --i >= 0;)
            val(Env.bind->bnd[i].sym) = Env.bind->bnd[i].val;
      Env.bind = Env.bind->link;
   }
   while (Env.inFrames)
      popInFiles();
   while (Env.outFrames)
      popOutFiles();
   while (Env.errFrames)
      popErrFiles();
   while (Env.ctlFrames)
      popCtlFiles();
}

/*** Evaluation ***/
any evExpr(any expr, any x) {
   any y = car(expr);
   struct {  // bindFrame
      struct bindFrame *link;
      int i, cnt;
      struct {any sym; any val;} bnd[length(y)+2];
   } f;

   f.link = Env.bind,  Env.bind = (bindFrame*)&f;
   f.i = sizeof(f.bnd) / (2*sizeof(any)) - 1;
   f.cnt = 1,  f.bnd[0].sym = At,  f.bnd[0].val = val(At);
   while (isCell(y)) {
      f.bnd[f.cnt].sym = car(y);
      f.bnd[f.cnt].val = EVAL(car(x));
      ++f.cnt, x = cdr(x), y = cdr(y);
   }
   if (isNil(y)) {
      do {
         x = val(f.bnd[--f.i].sym);
         val(f.bnd[f.i].sym) = f.bnd[f.i].val;
         f.bnd[f.i].val = x;
      } while (f.i);
      x = prog(cdr(expr));
   }
   else if (y != At) {
      f.bnd[f.cnt].sym = y,  f.bnd[f.cnt++].val = val(y),  val(y) = x;
      do {
         x = val(f.bnd[--f.i].sym);
         val(f.bnd[f.i].sym) = f.bnd[f.i].val;
         f.bnd[f.i].val = x;
      } while (f.i);
      x = prog(cdr(expr));
   }
   else {
      int n, cnt;
      cell *arg;
      cell c[n = cnt = length(x)];

      while (--n >= 0)
         Push(c[n], EVAL(car(x))),  x = cdr(x);
      do {
         x = val(f.bnd[--f.i].sym);
         val(f.bnd[f.i].sym) = f.bnd[f.i].val;
         f.bnd[f.i].val = x;
      } while (f.i);
      n = Env.next,  Env.next = cnt;
      arg = Env.arg,  Env.arg = c;
      x = prog(cdr(expr));
      if (cnt)
         drop(c[cnt-1]);
      Env.arg = arg,  Env.next = n;
   }
   while (--f.cnt >= 0)
      val(f.bnd[f.cnt].sym) = f.bnd[f.cnt].val;
   Env.bind = f.link;
   return x;
}

any funq(any x) {
   any y;

   if (isSym(x))
      return Nil;
   if (isNum(x))
      return (unDig(x)&3) || isNum(cdr(numCell(x)))? Nil : x;
   if (circ(y = cdr(x)))
      return Nil;
   while (isCell(y)) {
      if (isCell(car(y))) {
         if (isNum(caar(y))) {
            if (isCell(cdr(y)))
               return Nil;
         }
         else if (isNil(caar(y)) || caar(y) == T)
            return Nil;
      }
      else if (!isNil(cdr(y)))
         return Nil;
      y = cdr(y);
   }
   if (!isNil(y))
      return Nil;
   if (isNil(x = car(x)))
      return T;
   if (circ(y = x))
      return Nil;
   while (isCell(y)) {
      if (isNum(car(y)) || isCell(car(y)) || isNil(car(y)) || car(y) == T)
         return Nil;
      y = cdr(y);
   }
   return isNum(y) || y==T? Nil : x;
}

bool sharedLib(any x) {
   void *h;
   char *p, nm[bufSize(x)];

   bufString(x, nm);
   if (!(p = strchr(nm,':'))  ||  p == nm  ||  p[1] == '\0')
      return NO;
   *p++ = '\0';
   {
      int n = Home? strlen(Home) : 0;
#ifndef __CYGWIN__
      char buf[n + strlen(nm) + 4 + 1];
#else
      char buf[n + strlen(nm) + 4 + 4 + 1];
#endif

      if (strchr(nm,'/'))
         strcpy(buf, nm);
      else {
         if (n)
            memcpy(buf, Home, n);
         strcpy(buf + n, "lib/"),  strcpy(buf + n + 4, nm);
#ifdef __CYGWIN__
         strcpy(buf + n + 4 + strlen(nm), ".dll");
#endif
      }
      if (!(h = dlopen(buf, RTLD_LAZY | RTLD_GLOBAL))  ||  !(h = dlsym(h,p)))
         return NO;
      val(x) = box(num(h));
   }
   return YES;
}

void undefined(any x, any ex) {
   if (!sharedLib(x))
      err(ex, x, "Undefined");
}

static any evList2(any foo, any ex) {
   cell c1;

   Push(c1, foo);
   if (isCell(foo)) {
      foo = evExpr(foo, cdr(ex));
      drop(c1);
      return foo;
   }
   for (;;) {
      if (isNil(val(foo)))
         undefined(foo,ex);
      if (*Signal)
         sighandler(ex);
      if (isNum(foo = val(foo))) {
         foo = evSubr(foo,ex);
         drop(c1);
         return foo;
      }
      if (isCell(foo)) {
         foo = evExpr(foo, cdr(ex));
         drop(c1);
         return foo;
      }
   }
}

/* Evaluate a list */
any evList(any ex) {
   any foo;

   if (!isSym(foo = car(ex))) {
      if (isNum(foo))
         return ex;
      if (*Signal)
         sighandler(ex);
      if (isNum(foo = evList(foo)))
         return evSubr(foo,ex);
      return evList2(foo,ex);
   }
   for (;;) {
      if (isNil(val(foo)))
         undefined(foo,ex);
      if (*Signal)
         sighandler(ex);
      if (isNum(foo = val(foo)))
         return evSubr(foo,ex);
      if (isCell(foo))
         return evExpr(foo, cdr(ex));
   }
}

/* Evaluate any to sym */
any evSym(any x) {return xSym(EVAL(car(x)));}

any xSym(any x) {
   int i;
   any nm;
   cell c1, c2;

   if (isSym(x))
      return x;
   Push(c1,x);
   nm = NULL,  pack(x, &i, &nm, &c2);
   drop(c1);
   return nm? consStr(data(c2)) : Nil;
}

/* Evaluate count */
long evCnt(any ex, any x) {return xCnt(ex, EVAL(car(x)));}

long xCnt(any ex, any x) {
   NeedCnt(ex,x);
   return unBox(x);
}

/* Evaluate double */
double evDouble(any ex, any x) {
   x = EVAL(car(x));
   NeedNum(ex,x);
   return numToDouble(x);
}

// (args) -> flg
any doArgs(any ex __attribute__((unused))) {
   return Env.next > 0? T : Nil;
}

// (next) -> any
any doNext(any ex __attribute__((unused))) {
   if (Env.next > 0)
      return data(Env.arg[--Env.next]);
   if (Env.next == 0)
      Env.next = -1;
   return Nil;
}

// (arg ['cnt]) -> any
any doArg(any ex) {
   long n;

   if (Env.next < 0)
      return Nil;
   if (!isCell(cdr(ex)))
      return data(Env.arg[Env.next]);
   if ((n = evCnt(ex,cdr(ex))) > 0  &&  n <= Env.next)
      return data(Env.arg[Env.next - n]);
   return Nil;
}

// (rest) -> lst
any doRest(any x) {
   int i;
   cell c1;

   if ((i = Env.next) <= 0)
      return Nil;
   Push(c1, x = cons(data(Env.arg[--i]), Nil));
   while (i)
      x = cdr(x) = cons(data(Env.arg[--i]), Nil);
   return Pop(c1);
}

static struct tm *TM;

any mkDat(int y, int m, int d) {
   int n;
   static char mon[13] = {31,31,28,31,30,31,30,31,31,30,31,30,31};

   if (y<0 || m<1 || m>12 || d<1 || d>mon[m] && (m!=2 || d!=29 || y%4 || !(y%100) && y%400))
      return Nil;
   n = (12*y + m - 3) / 12;
   return boxCnt((4404*y+367*m-1094)/12 - 2*n + n/4 - n/100 + n/400 + d);
}

// (date ['T]) -> dat
// (date 'dat) -> (y m d)
// (date 'y 'm 'd) -> dat | NIL
// (date '(y m d)) -> dat | NIL
any doDate(any ex) {
   any x, z;
   int y, m, d, n;
   cell c1;

   if (!isCell(x = cdr(ex))) {
      gettimeofday(&Tv,NULL);
      TM = localtime(&Tv.tv_sec);
      return mkDat(TM->tm_year+1900,  TM->tm_mon+1,  TM->tm_mday);
   }
   if ((z = EVAL(car(x))) == T) {
      gettimeofday(&Tv,NULL);
      TM = gmtime(&Tv.tv_sec);
      return mkDat(TM->tm_year+1900,  TM->tm_mon+1,  TM->tm_mday);
   }
   if (isNil(z))
      return Nil;
   if (isCell(z))
      return mkDat(xCnt(ex, car(z)),  xCnt(ex, cadr(z)),  xCnt(ex, caddr(z)));
   if (!isCell(x = cdr(x))) {
      if ((n = xCnt(ex,z)) < 0)
         return Nil;
      y = (100*n - 20) / 3652425;
      n += (y - y/4);
      y = (100*n - 20) / 36525;
      n -= 36525*y / 100;
      m = (10*n - 5) / 306;
      d = (10*n - 306*m + 5) / 10;
      if (m < 10)
         m += 3;
      else
         ++y,  m -= 9;
      Push(c1, cons(boxCnt(d), Nil));
      data(c1) = cons(boxCnt(m), data(c1));
      data(c1) = cons(boxCnt(y), data(c1));
      return Pop(c1);
   }
   y = xCnt(ex,z);
   m = evCnt(ex,x);
   return mkDat(y, m, evCnt(ex,cdr(x)));
}

any mkTime(int h, int m, int s) {
   if (h < 0  ||  m < 0 || m > 59  ||  s < 0 || s > 60)
      return Nil;
   return boxCnt(h * 3600 + m * 60 + s);
}

// (time ['T]) -> tim
// (time 'tim) -> (h m s)
// (time 'h 'm ['s]) -> tim | NIL
// (time '(h m [s])) -> tim | NIL
any doTime(any ex) {
   any x, z;
   int h, m, s;
   cell c1;
   struct tm *p;

   if (!isCell(x = cdr(ex))) {
      gettimeofday(&Tv,NULL);
      p = localtime(&Tv.tv_sec);
      return boxCnt(p->tm_hour * 3600 + p->tm_min * 60 + p->tm_sec);
   }
   if ((z = EVAL(car(x))) == T)
      return TM? boxCnt(TM->tm_hour * 3600 + TM->tm_min * 60 + TM->tm_sec) : Nil;
   if (isNil(z))
      return Nil;
   if (isCell(z))
      return mkTime(xCnt(ex, car(z)), xCnt(ex, cadr(z)), isCell(cddr(z))? xCnt(ex, caddr(z)) : 0);
   if (!isCell(x = cdr(x))) {
      if ((s = xCnt(ex,z)) < 0)
         return Nil;
      Push(c1, cons(boxCnt(s % 60), Nil));
      data(c1) = cons(boxCnt(s / 60 % 60), data(c1));
      data(c1) = cons(boxCnt(s / 3600), data(c1));
      return Pop(c1);
   }
   h = xCnt(ex, z);
   m = evCnt(ex, x);
   return mkTime(h, m, isCell(cdr(x))? evCnt(ex, cdr(x)) : 0);
}

// (usec ['flg]) -> num
any doUsec(any ex) {
   if (!isNil(EVAL(cadr(ex))))
      return boxCnt(Tv.tv_usec);
   gettimeofday(&Tv,NULL);
   return boxWord2((word2)Tv.tv_sec*1000000 + Tv.tv_usec - USec);
}

// (pwd) -> sym
any doPwd(any x) {
   char *p;

   if ((p = getcwd(NULL, GETCWDLEN)) == NULL)
      return Nil;
   x = mkStr(p);
   free(p);
   return x;
}

// (cd 'any) -> sym
any doCd(any x) {
   x = evSym(cdr(x));
   {
      char *p, path[pathSize(x)];

      pathString(x, path);
      if ((p = getcwd(NULL, GETCWDLEN)) == NULL)
         return Nil;
      x = path[0] && chdir(path) < 0? Nil : mkStr(p);
      free(p);
      return x;
   }
}

// (ctty 'sym|pid) -> flg
any doCtty(any ex) {
   any x;

   if (isNum(x = EVAL(cadr(ex))))
      TtyPid = unDig(x) / 2;
   else {
      if (!isSym(x))
         argError(ex,x);
      {
         char tty[bufSize(x)];

         bufString(x, tty);
         if (!freopen(tty,"r",stdin) || !freopen(tty,"w",stdout) || !freopen(tty,"w",stderr))
            return Nil;
         InFiles[STDIN_FILENO]->ix = InFiles[STDIN_FILENO]->cnt = InFiles[STDIN_FILENO]->next = 0;
         Tio = tcgetattr(STDIN_FILENO, &OrgTermio) == 0;
         OutFiles[STDOUT_FILENO]->tty = YES;
         OutFiles[STDOUT_FILENO]->ix = 0;
      }
   }
   return T;
}

// (info 'any ['flg]) -> (cnt|flg dat . tim)
any doInfo(any x) {
   any y;
   cell c1;
   struct tm *p;
   struct stat st;

   y = evSym(x = cdr(x));
   {
      char nm[pathSize(y)];

      pathString(y, nm);
      x = cdr(x);
      if ((isNil(EVAL(car(x)))? stat(nm, &st) : lstat(nm, &st)) < 0)
         return Nil;
      p = gmtime(&st.st_mtime);
      Push(c1, boxCnt(p->tm_hour * 3600 + p->tm_min * 60 + p->tm_sec));
      data(c1) = cons(mkDat(p->tm_year+1900,  p->tm_mon+1,  p->tm_mday), data(c1));
      data(c1) = cons(
         (st.st_mode & S_IFMT) == S_IFDIR? T :
         (st.st_mode & S_IFMT) != S_IFREG? Nil :
         boxWord2((word2)st.st_size), data(c1) );
      return Pop(c1);
   }
}

// (file) -> (sym1 sym2 . num) | NIL
any doFile(any ex __attribute__((unused))) {
   char *s, *p;
   cell c1;

   if (!InFile || !InFile->name)
      return Nil;
   Push(c1, boxCnt(InFile->src));
   s = strdup(InFile->name);
   if (p = strrchr(s, '/')) {
      data(c1) = cons(mkStr(p+1), data(c1));
      *(p+1) = '\0';
      data(c1) = cons(mkStr(s), data(c1));
   }
   else {
      data(c1) = cons(mkStr(s), data(c1));
      data(c1) = cons(mkStr("./"), data(c1));
   }
   free(s);
   return Pop(c1);
}

// (dir ['any] ['flg]) -> lst
any doDir(any x) {
   any y;
   DIR *dp;
   struct dirent *p;
   cell c1;

   if (isNil(y = evSym(x = cdr(x))))
      dp = opendir(".");
   else {
      char nm[pathSize(y)];

      pathString(y, nm);
      dp = opendir(nm);
   }
   if (!dp)
      return Nil;
   x = cdr(x),  x = EVAL(car(x));
   do {
      if (!(p = readdir(dp))) {
         closedir(dp);
         return Nil;
      }
   } while (isNil(x) && p->d_name[0] == '.');
   Push(c1, y = cons(mkStr(p->d_name), Nil));
   while (p = readdir(dp))
      if (!isNil(x) || p->d_name[0] != '.')
         y = cdr(y) = cons(mkStr(p->d_name), Nil);
   closedir(dp);
   return Pop(c1);
}

// (cmd ['any]) -> sym
any doCmd(any x) {
   if (isNil(x = evSym(cdr(x))))
      return mkStr(AV0);
   bufString(x, AV0);
   return x;
}

// (argv [var ..] [. sym]) -> lst|sym
any doArgv(any ex) {
   any x, y;
   char **p;
   cell c1;

   if (*(p = AV) && strcmp(*p,"-") == 0)
      ++p;
   if (isNil(x = cdr(ex))) {
      if (!*p)
         return Nil;
      Push(c1, x = cons(mkStr(*p++), Nil));
      while (*p)
         x = cdr(x) = cons(mkStr(*p++), Nil);
      return Pop(c1);
   }
   do {
      if (!isCell(x)) {
         NeedSym(ex,x);
         CheckVar(ex,x);
         if (!*p)
            return val(x) = Nil;
         Push(c1, y = cons(mkStr(*p++), Nil));
         while (*p)
            y = cdr(y) = cons(mkStr(*p++), Nil);
         return val(x) = Pop(c1);
      }
      y = car(x);
      NeedVar(ex,y);
      CheckVar(ex,y);
      val(y) = *p? mkStr(*p++) : Nil;
   } while (!isNil(x = cdr(x)));
   return val(y);
}

// (opt) -> sym
any doOpt(any ex __attribute__((unused))) {
   return *AV && strcmp(*AV,"-")? mkStr(*AV++) : Nil;
}

// (version ['flg]) -> lst
any doVersion(any x) {
   int i;
   cell c1;

   x = cdr(x);
   if (isNil(EVAL(car(x)))) {
      for (i = 0; i < 3; ++i) {
         outWord((word)Version[i]);
         Env.put(i == 2? ' ' : '.');
      }
      Env.put('C');
      newline();
   }
   Push(c1, Nil);
   i = 3;
   do
      data(c1) = cons(box(Version[--i] * 2), data(c1));
   while (i);
   return Pop(c1);
}

any loadAll(any ex) {
   any x = Nil;

   while (*AV  &&  strcmp(*AV,"-") != 0)
      x = load(ex, 0, mkStr(*AV++));
   return x;
}

/*** Main ***/
static void init(int ac, char *av[]) {
   char *p;
   sigset_t sigs;

   AV0 = *av++;
   AV = av;
   heapAlloc();
   initSymbols();
   if (ac >= 2 && strcmp(av[ac-2], "+") == 0)
      val(Dbg) = T,  av[ac-2] = NULL;
   if (av[0] && *av[0] != '-' && (p = strrchr(av[0], '/')) && !(p == av[0]+1 && *av[0] == '.')) {
      Home = malloc(p - av[0] + 2);
      memcpy(Home, av[0], p - av[0] + 1);
      Home[p - av[0] + 1] = '\0';
   }
   Env.get = getStdin;
   InFile = initInFile(STDIN_FILENO, NULL);
   Env.put = putStdout;
   initOutFile(STDERR_FILENO);
   OutFile = initOutFile(STDOUT_FILENO);
   Env.task = Alarm = Sigio = Line = Nil;
   setrlimit(RLIMIT_STACK, &ULim);
   Tio = tcgetattr(STDIN_FILENO, &OrgTermio) == 0;
   ApplyArgs = cons(cons(consSym(Nil,Nil), Nil), Nil);
   ApplyBody = cons(Nil,Nil);
   sigfillset(&sigs);
   sigprocmask(SIG_UNBLOCK, &sigs, NULL);
   iSignal(SIGHUP, sig);
   iSignal(SIGINT, sigTerm);
   iSignal(SIGUSR1, sig);
   iSignal(SIGUSR2, sig);
   iSignal(SIGALRM, sig);
   iSignal(SIGTERM, sig);
   iSignal(SIGIO, sig);
   signal(SIGCHLD, sigChld);
   signal(SIGPIPE, SIG_IGN);
   signal(SIGTTIN, SIG_IGN);
   signal(SIGTTOU, SIG_IGN);
   gettimeofday(&Tv,NULL);
   USec = (word2)Tv.tv_sec*1000000 + Tv.tv_usec;
}

int MAIN(int ac, char *av[]) {
   init(ac,av);
   if (!setjmp(ErrRst)) {
      loadAll(NULL);
      ++Repl;
      iSignal(SIGINT, sig);
   }
   for (;;)
      load(NULL, ':', Nil);
}
