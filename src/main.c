/* 29mar06abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

/* Globals */
bool SigInt, SigTerm;
int Chr, Spkr, Mic, Slot, Hear, Tell, PSize, *Pipe, Trace;
char **AV, *Home;
heap *Heaps;
cell *Avail;
stkEnv Env;
catchFrame *CatchPtr;
struct termios *Termio;
FILE *InFile, *OutFile;
any TheKey, TheCls;
any Line, Zero, One, Intern[HASH], Transient[HASH], Extern[HASH];
any ApplyArgs, ApplyBody, DbVal, DbTail;
any Nil, DB, Up, At, At2, At3, This, Meth, Quote, T;
any Dbg, Pid, Scl, Class, Key, Led, Tsm, Err, Msg, Uni, Adr, Fork, Bye;

static int TtyPid;
static bool Jam, Protect;
static struct termios RawTermio;
static jmp_buf ErrRst;
static void finish(int) __attribute__ ((noreturn));


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
   unwind(NULL);
   prog(val(Bye));
   finish(n);
}

void execError(char *s) {
   fprintf(stderr, "%s: can't exec\n", s);
   exit(127);
}

static void sigterm(void) {
   int i;

   if (Protect)
      return;
   for (i = 0; i < PSize; i += 2)
      if (Pipe[i] >= 0)
         return;
   bye(0);
}

static void doSigInt1(int n __attribute__((unused))) {
   if (TtyPid)
      kill(TtyPid, SIGINT);
   else
      sigterm();
}

static void doSigInt(int n __attribute__((unused))) {
   if (TtyPid)
      kill(TtyPid, SIGINT);
   else
      SigInt = YES;
}

static void doSigTerm(int n __attribute__((unused))) {
   SigTerm = YES;
   sigterm();
}

static void doSigChld(int n __attribute__((unused))) {
   pid_t pid;
   int stat;

   while ((pid = waitpid(0, &stat, WNOHANG)) > 0)
      if (WIFSIGNALED(stat))
         fprintf(stderr, "%d SIG-%d\n", (int)pid, WTERMSIG(stat));
}

static void doTermStop(int n __attribute__((unused))) {
   sigset_t mask;

   tcsetattr(STDIN_FILENO, TCSADRAIN, Termio);
   sigemptyset(&mask);
   sigaddset(&mask, SIGTSTP);
   sigprocmask(SIG_UNBLOCK, &mask, NULL);
   signal(SIGTSTP, SIG_DFL),  raise(SIGTSTP),  signal(SIGTSTP, doTermStop);
   tcsetattr(STDIN_FILENO, TCSADRAIN, &RawTermio);
}

void setRaw(void) {
   if (!Termio  &&  tcgetattr(STDIN_FILENO, &RawTermio) == 0) {
      *(Termio = malloc(sizeof(struct termios))) = RawTermio;
      RawTermio.c_iflag = 0;
      RawTermio.c_lflag = ISIG;
      RawTermio.c_cc[VMIN] = 1;
      RawTermio.c_cc[VTIME] = 0;
      tcsetattr(STDIN_FILENO, TCSADRAIN, &RawTermio);
      if (signal(SIGTSTP,SIG_IGN) == SIG_DFL)
         signal(SIGTSTP, doTermStop);
   }
}

void setCooked(void) {
   if (Termio)
      tcsetattr(STDIN_FILENO, TCSADRAIN, Termio);
   Termio = NULL;
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

void protect(bool flg) {
   if (!(Protect = flg) && SigTerm)
      raise(SIGTERM);
}

// (protect . prg) -> any
any doProtect(any x) {
   protect(YES);
   x = prog(cdr(x));
   protect(NO);
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

   h = (heap*)((long)alloc(NULL,
      sizeof(heap) + sizeof(cell)) + (sizeof(cell)-1) & ~(sizeof(cell)-1) );
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
   if (isNil(EVAL(car(x))))
      for (x = Avail;  x;  x = cdr(x))
         ++n;
   else {
      heap *h = Heaps;
      do
         n += CELLS;
      while (h = h->next);
   }
   return boxCnt(n);
}

// (env ['lst]) -> lst
any doEnv(any x) {
   any y;
   int i;
   bindFrame *p;
   cell c1;

   if (isCell(x = EVAL(cadr(x)))) {
      Push(c1, y = cons(cons(car(x), val(car(x))), Nil));
      while (isCell(x = cdr(x)))
         y = cdr(y) = cons(cons(car(x), val(car(x))), Nil);
   }
   else {
      Push(c1, Nil);
      for (p = Env.bind;  p;  p = p->link) {
         if (p->i == 0) {
            for (i = p->cnt;  --i >= 0;) {
               for (x = data(c1); ; x = cdr(x)) {
                  if (!isCell(x)) {
                     data(c1) = cons(p->bnd[i].sym, data(c1));
                     break;
                  }
                  if (car(x) == p->bnd[i].sym)
                     break;
               }
            }
         }
      }
   }
   return Pop(c1);
}

// (up sym ['val]) -> any
any doUp(any x) {
   any y;
   int i;
   bindFrame *p;

   x = cdr(x),  y = car(x);
   for (p = Env.bind;  p;  p = p->link)
      if (p->i <= 0)
         for (i = p->cnt;  --i >= 0;)
            if (p->bnd[i].sym == y) {
               if (isCell(x = cdr(x)))
                  return p->bnd[i].val = EVAL(car(x));
               return p->bnd[i].val;
            }
   return Nil;
}

// (stk any ..) -> T
any doStk(any x) {
   any p;
   FILE *oSave = OutFile;

   OutFile = stderr;
   print(cdr(x)), crlf();
   for (p = Env.stack; p; p = cdr(p)) {
      printf("%lX ", num(p)),  fflush_unlocked(stderr);
      print(car(p)), crlf();
   }
   crlf();
   OutFile = oSave;
   return T;
}

/*** Primitives ***/
/* Comparisons */
bool equal(any x, any y) {
   for (;;) {
      if (x == y)
         return YES;
      if (isNum(x)) {
         if (!isNum(y)  ||  unDig(x) != unDig(y))
            return NO;
         x = cdr(numCell(x)),  y = cdr(numCell(y));
      }
      else if (isSym(x)) {
         if (!isSym(y)  || !isNum(x = name(x))  ||  !isNum(y = name(y)))
            return NO;
      }
      else {
         any a, b;

         if (!isCell(y))
            return NO;
         while (car(x) == Quote) {
            if (car(y) != Quote)
               return NO;
            if (x == cdr(x))
               return y == cdr(y);
            if (y == cdr(y))
               return NO;
            if (!isCell(x = cdr(x)))
               return equal(x, cdr(y));
            if (!isCell(y = cdr(y)))
               return NO;
         }
         a = x, b = y;
         for (;;) {
            if (!equal(car(x), car(y)))
               return NO;
            if (!isCell(x = cdr(x)))
               return equal(x, cdr(y));
            if (!isCell(y = cdr(y)))
               return NO;
            if (x == a && y == b)
               return YES;
         }
      }
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
         return !isNum(name(y))? 1664525*(int32_t)x - 1664525*(int32_t)y : -1;
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

/*** Error handling ***/
void err(any ex, any x, char *fmt, ...) {
   va_list ap;
   char msg[240];
   outFrame f;

   Line = Nil;
   Env.brk = NO;
   f.pid = -1,  f.fp = stderr;
   pushOutFiles(&f);
   while (*AV  &&  strcmp(*AV,"-") != 0)
      ++AV;
   if (ex)
      outString("!? "), print(val(Up) = ex), crlf();
   if (x)
      print(x), outString(" -- ");
   va_start(ap,fmt);
   vsnprintf(msg, sizeof(msg), fmt, ap);
   va_end(ap);
   if (msg[0]) {
      outString(msg), crlf();
      val(Msg) = mkStr(msg);
      if (!isNil(val(Err)) && !Jam)
         Jam = YES,  prog(val(Err)),  Jam = NO;
      if (!isatty(STDIN_FILENO) || !isatty(STDOUT_FILENO))
         bye(1);
      load(NULL, '?', Nil);
   }
   popOutFiles();
   unwind(NULL);
   Env.stack = NULL;
   Env.meth = NULL;
   Env.next = 0;
   Env.make = NULL;
   Env.parser = NULL;
   Trace = 0;
   longjmp(ErrRst,1);
}

// (quit ['any ['any]])
any doQuit(any x) {
   cell c1;

   x = cdr(x),  Push(c1, evSym(x));
   x = isCell(x = cdr(x))?  EVAL(car(x)) : NULL;
   {
      char msg[bufSize(data(c1))];

      bufString(data(c1), msg);
      drop(c1);
      err(NULL, x, "%s", msg);
   }
}

void argError(any ex, any x) {err(ex, x, "Bad argument");}
void numError(any ex, any x) {err(ex, x, "Number expected");}
void cntError(any ex, any x) {err(ex, x, "Small number expected");}
void symError(any ex, any x) {err(ex, x, "Symbol expected");}
void extError(any ex, any x) {err(ex, x, "External symbol expected");}
void cellError(any ex, any x) {err(ex, x, "Cell expected");}
void atomError(any ex, any x) {err(ex, x, "Atom expected");}
void lstError(any ex, any x) {err(ex, x, "List expected");}
void varError(any ex, any x) {err(ex, x, "Variable expected");}
void protError(any ex, any x) {err(ex, x, "Protected symbol");}

void pipeError(any ex, char *s) {err(ex, NULL, "Pipe %s error", s);}

void unwind(catchFrame *p) {
   int i;
   catchFrame *q;
   cell c1;

   while (CatchPtr) {
      q = CatchPtr,  CatchPtr = CatchPtr->link;
      while (Env.bind != q->env.bind) {
         if (Env.bind->i == 0)
            for (i = Env.bind->cnt;  --i >= 0;)
               val(Env.bind->bnd[i].sym) = Env.bind->bnd[i].val;
         Env.bind = Env.bind->link;
      }
      while (Env.inFiles != q->env.inFiles)
         popInFiles();
      while (Env.outFiles != q->env.outFiles)
         popOutFiles();
      while (Env.ctlFiles != q->env.ctlFiles)
         popCtlFiles();
      Env = q->env;
      if (q == p)
         return;
      if (!isSym(q->tag)) {
         Push(c1, q->tag);
         EVAL(data(c1));
         drop(c1);
      }
   }
   while (Env.bind) {
      if (Env.bind->i == 0)
         for (i = Env.bind->cnt;  --i >= 0;)
            val(Env.bind->bnd[i].sym) = Env.bind->bnd[i].val;
      Env.bind = Env.bind->link;
   }
   while (Env.inFiles)
      popInFiles();
   while (Env.outFiles)
      popOutFiles();
   while (Env.ctlFiles)
      popCtlFiles();
}

/*** Evaluation ***/
/* Evaluate symbolic expression */
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
      while (--f.i > 0) {
         x = val(f.bnd[f.i].sym);
         val(f.bnd[f.i].sym) = f.bnd[f.i].val;
         f.bnd[f.i].val = x;
      }
      x = prog(cdr(expr));
   }
   else if (y != At) {
      f.bnd[f.cnt].sym = y,  f.bnd[f.cnt++].val = val(y),  val(y) = x;
      while (--f.i > 0) {
         x = val(f.bnd[f.i].sym);
         val(f.bnd[f.i].sym) = f.bnd[f.i].val;
         f.bnd[f.i].val = x;
      }
      x = prog(cdr(expr));
   }
   else {
      int n, cnt;
      cell *arg;
      cell c[n = cnt = length(x)];

      while (--n >= 0)
         Push(c[n], EVAL(car(x))),  x = cdr(x);
      while (--f.i > 0) {
         x = val(f.bnd[f.i].sym);
         val(f.bnd[f.i].sym) = f.bnd[f.i].val;
         f.bnd[f.i].val = x;
      }
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

void undefined(any x, any ex) {
   void *h;
   char *p, nm[bufSize(x)];

   bufString(x, nm);
   if (!(p = strchr(nm,':'))  ||  p == nm  ||  p[1] == '\0')
      err(ex, x, "Undefined");
   *p++ = '\0';
   {
      int n = Home? strlen(Home) : 0;
      char buf[n + strlen(nm) + 4 + 1];

      if (strchr(nm,'/'))
         strcpy(buf, nm);
      else {
         if (n)
            memcpy(buf, Home, n);
         strcpy(buf + n, "lib/"),  strcpy(buf + n + 4, nm);
      }
      if (!(h = dlopen(buf, RTLD_LAZY | RTLD_GLOBAL))  ||  !(h = dlsym(h,p)))
         err(ex, x, "%s", (char*)dlerror());
      val(x) = box(num(h));
   }
}

/* Evaluate a list */
any evList(any ex) {
   any foo;

   if (SigInt)
      SigInt = NO,  brkLoad(ex);
   if (!isSym(foo = car(ex))) {
      if (isNum(foo))
         return ex;
      if (isNum(foo = evList(foo)))
         return evSubr(foo,ex);
      if (isCell(foo))
         return evExpr(foo, cdr(ex));
   }
   for (;;) {
      if (isNil(val(foo)) || foo == val(foo))
         undefined(foo,ex);
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
   return Env.next? T : Nil;
}

// (next) -> any
any doNext(any ex __attribute__((unused))) {
   return Env.next? data(Env.arg[--Env.next]) : Nil;
}

// (arg ['cnt]) -> any
any doArg(any ex) {
   long n;

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

   if (!(i = Env.next))
      return Nil;
   Push(c1, x = cons(data(Env.arg[--i]), Nil));
   while (i)
      x = cdr(x) = cons(data(Env.arg[--i]), Nil);
   return Pop(c1);
}

any mkDat(int y, int m, int d) {
   int n;
   static char mon[13] = {31,31,28,31,30,31,30,31,31,30,31,30,31};

   if (m<1 || m>12 || d<1 || d>mon[m] && (m!=2 || d!=29 || y%4 || !(y%100) && y%400))
      return Nil;
   n = (12*y + m - 3) / 12;
   return boxCnt((4404*y+367*m-1094)/12 - 2*n + n/4 - n/100 + n/400 + d);
}

// (date '[T]) -> dat
// (date 'dat) -> (y m d)
// (date 'y 'm 'd) -> dat | NIL
// (date '(y m d)) -> dat | NIL
any doDate(any ex) {
   any x, z;
   int y, m, d, n;
   cell c1;
   time_t tim;
   struct tm *p;

   if (!isCell(x = cdr(ex))) {
      time(&tim);
      p = localtime(&tim);
      return mkDat(p->tm_year+1900,  p->tm_mon+1,  p->tm_mday);
   }
   if ((z = EVAL(car(x))) == T) {
      time(&tim);
      p = gmtime(&tim);
      return mkDat(p->tm_year+1900,  p->tm_mon+1,  p->tm_mday);
   }
   if (isNil(z))
      return Nil;
   if (isNum(z) && !isCell(x = cdr(x))) {
      n = xCnt(ex,z);
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
   if (!isCell(z))
      return mkDat(xCnt(ex,z), evCnt(ex,x), evCnt(ex,cdr(x)));
   return mkDat(xCnt(ex, car(z)),  xCnt(ex, cadr(z)),  xCnt(ex, caddr(z)));
}

// (time ['T]) -> tim
// (time 'tim) -> (h m s)
// (time 'h 'm ['s]) -> tim | NIL
// (time '(h m [s])) -> tim | NIL
any doTime(any ex) {
   any x, z;
   int h, m, s;
   cell c1;
   time_t tim;
   struct tm *p;

   if (!isCell(x = cdr(ex))) {
      time(&tim);
      p = localtime(&tim);
      return boxCnt(p->tm_hour * 3600 + p->tm_min * 60 + p->tm_sec);
   }
   if ((z = EVAL(car(x))) == T) {
      time(&tim);
      p = gmtime(&tim);
      return boxCnt(p->tm_hour * 3600 + p->tm_min * 60 + p->tm_sec);
   }
   if (isNil(z))
      return Nil;
   if (isNum(z) && !isCell(x = cdr(x))) {
      s = xCnt(ex,z);
      Push(c1, cons(boxCnt(s % 60), Nil));
      data(c1) = cons(boxCnt(s / 60 % 60), data(c1));
      data(c1) = cons(boxCnt(s / 3600), data(c1));
      return Pop(c1);
   }
   if (!isCell(z)) {
      h = xCnt(ex, z);
      m = evCnt(ex, x);
      s = isCell(cdr(x))? evCnt(ex, cdr(x)) : 0;
   }
   else {
      h = xCnt(ex, car(z));
      m = xCnt(ex, cadr(z));
      s = isCell(cddr(z))? xCnt(ex, caddr(z)) : 0;
   }
   if (h < 0 || h > 23  ||  m < 0 || m > 59  ||  s < 0 || s > 60)
      return Nil;
   return boxCnt(h * 3600 + m * 60 + s);
}

// (pwd) -> sym
any doPwd(any x) {
   char *p;

   if ((p = getcwd(NULL,0)) == NULL)
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
      if ((p = getcwd(NULL,0)) == NULL  ||  path[0] && chdir(path) < 0)
         return Nil;
      x = mkStr(p);
      free(p);
      return x;
   }
}

// (ctty 'sym|pid) -> flg
any doCtty(any ex) {
   any x;

   if (!isSym(x = EVAL(cadr(ex))))
      TtyPid = xCnt(ex,x);
   else {
      char tty[bufSize(x)];

      bufString(x, tty);
      if (!freopen(tty,"r",stdin) || !freopen(tty,"w",stdout) || !freopen(tty,"w",stderr))
         return Nil;
   }
   return T;
}

// (info 'any) -> (cnt|T dat . tim)
any doInfo(any x) {
   cell c1;
   struct tm *p;
   struct stat st;

   x = evSym(cdr(x));
   {
      char nm[bufSize(x)];

      bufString(x, nm);
      if (stat(nm, &st) < 0)
         return Nil;
      p = gmtime(&st.st_mtime);
      Push(c1, boxCnt(p->tm_hour * 3600 + p->tm_min * 60 + p->tm_sec));
      data(c1) = cons(mkDat(p->tm_year+1900,  p->tm_mon+1,  p->tm_mday), data(c1));
      data(c1) = cons(S_ISDIR(st.st_mode)? T : boxWord2((word2)st.st_size), data(c1));
      return Pop(c1);
   }
}

// (dir ['any]) -> lst
any doDir(any x) {
   any y;
   DIR *dp;
   struct dirent *p;
   cell c1;

   if (isNil(x = evSym(cdr(x))))
      dp = opendir(".");
   else {
      char nm[bufSize(x)];

      bufString(x, nm);
      dp = opendir(nm);
   }
   if (!dp)
      return Nil;
   do {
      if (!(p = readdir(dp))) {
         closedir(dp);
         return Nil;
      }
   } while (p->d_name[0] == '.');
   Push(c1, y = cons(mkStr(p->d_name), Nil));
   while (p = readdir(dp))
      if (p->d_name[0] != '.')
         y = cdr(y) = cons(mkStr(p->d_name), Nil);
   closedir(dp);
   return Pop(c1);
}

// (argv [sym ..] [. sym]) -> lst|sym
any doArgv(any ex) {
   any x, y;
   char **p;
   cell c1;

   if (!*(p = AV))
      return Nil;
   if (strcmp(*p,"-") == 0  &&  !*++p)
      return Nil;
   if (isNil(x = cdr(ex))) {
      Push(c1, x = cons(mkStr(*p++), Nil));
      while (*p)
         x = cdr(x) = cons(mkStr(*p++), Nil);
      return Pop(c1);
   }
   do {
      if (!isCell(x)) {
         NeedSym(ex,x);
         Push(c1, y = cons(mkStr(*p++), Nil));
         while (*p)
            y = cdr(y) = cons(mkStr(*p++), Nil);
         return val(x) = Pop(c1);
      }
      y = car(x);
      NeedSym(ex,y);
      val(y) = *p? mkStr(*p++) : Nil;
   } while (!isNil(x = cdr(x)));
   return val(y);
}

// (opt) -> sym
any doOpt(any ex __attribute__((unused))) {
   return *AV && strcmp(*AV,"-")? mkStr(*AV++) : Nil;
}

/*** Main ***/
int main(int ac, char *av[]) {
   int i;
   char *p;

   for (i = 1; i < ac; ++i)
      if (*av[i] != '-') {
         if (p = strrchr(av[i], '/')) {
            Home = malloc(p - av[i] + 2);
            memcpy(Home, av[i], p - av[i] + 1);
            Home[p - av[i] + 1] = '\0';
         }
         break;
      }
   AV = av+1;
   heapAlloc();
   initSymbols();
   Line = Nil;
   InFile = stdin,  Env.get = getStdin;
   OutFile = stdout,  Env.put = putStdout;
   ApplyArgs = cons(cons(consSym(Nil,Nil), Nil), Nil);
   ApplyBody = cons(Nil,Nil);
   signal(SIGINT, doSigInt1);
   signal(SIGTERM, doSigTerm);
   signal(SIGCHLD, doSigChld);
   signal(SIGPIPE, SIG_IGN);
   signal(SIGTTIN, SIG_IGN);
   signal(SIGTTOU, SIG_IGN);
   setjmp(ErrRst);
   while (*AV  &&  strcmp(*AV,"-") != 0)
      load(NULL, 0, mkStr(*AV++));
   signal(SIGINT, doSigInt);
   load(NULL, ':', Nil);
   bye(0);
}
