/* 18feb03abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

/* Globals */
bool SigInt, SigTerm;
int Chr, Mic[2], Slot, Hear, Tell, PSize, *Pipe, Trace;
char **AV, *Home;
heap *Heaps;
cell *Avail;
stkEnv Env;
catchFrame *CatchPtr;
struct termios *Termio;
FILE *InFile, *OutFile;
any TheKey, TheCls;
any Line, Zero, Intern[HASH], Transient[HASH], Extern[HASH];
any ApplyArgs, ApplyBody, DbVal, DbTail;
any Nil, DB, Up, At, At2, At3, This, Meth, Quote, T;
any Dbg, Pid, Scl, Class, Key, Led, Err, Msg, Bye;

static jmp_buf ErrRst;
static bool Jam, Protect;


/*** System ***/
void bye(int n) {
   if (Termio)
      tcsetattr(STDIN_FILENO, TCSADRAIN, Termio);
   exit(n);
}

void giveup(char *msg) {
   fprintf(stderr, "%d %s\n", getpid(), msg);
   bye(1);
}

void execError(char *s) {
   fprintf(stderr, "%s: can't exec\n", s);
   exit(127);
}

static void doSigInt(int n __attribute__((unused))) {SigInt = YES;}

static void doSigTerm(int n __attribute__((unused))) {
   int i;

   SigTerm = YES;
   if (Protect)
      return;
   for (i = 0; i < PSize; i += 2)
      if (Pipe[i] >= 0)
         return;
   signal(SIGTERM, SIG_DFL),  raise(SIGTERM);
}

void protect(bool flg) {
   if (flg)
      Protect = YES;
   else {
      Protect = NO;
      if (SigTerm)
         raise(SIGTERM);
   }
}

/* Allocate memory */
void *alloc(void *p, size_t siz) {
   void *q;

   if (!(q = realloc(p,siz)))
      giveup("No memory");
   return q;
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

// (env) -> lst
any doEnv(any x) {
   int i;
   bindFrame *p;
   cell c1;

   Push(c1,Nil);
   for (p = Env.bind;  p;  p = p->link) {
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
   return Pop(c1);
}

// (stk any ..) -> T
any doStk(any x) {
   any p;
   FILE *oSave = OutFile;

   OutFile = stdout;
   print(cdr(x)), crlf();
   for (p = Env.stack; p; p = cdr(p)) {
      printf("%lX ", num(p)),  fflush(stdout);
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
      if (!isNum(x = name(x)))
         return !isNum(name(y))? 0 : -1;
      if (!isNum(y = name(y)))
         return +1;
      n1 = unDig(x), n2 = unDig(y);
      for (;;) {
         if ((b1 = n1 & 0xFF) != (b2 = n2 & 0xFF))
            return b1 - b2;
         if ((n1 >>= 8) == 0) {
            if ((n2 >>= 8) != 0)
               return -1;
            if (!isNum(x = cdr(numCell(x))))
               return !isNum(y = cdr(numCell(y)))? 0 : -1;
            if (!isNum(y = cdr(numCell(y))))
               return +1;
            n1 = unDig(x), n2 = unDig(y);
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
         return isCell(cdr(y))? -1 : compare(x, cdr(y));
      if (!isCell(y = cdr(y)))
         return +1;
      if (x == a && y == b)
         return 0;
   }
}

/*** Error handling ***/
void err(any ex, any x, char *fmt, ...) {
   int i;
   va_list ap;
   char msg[64];

   Line = Nil;
   Env.get = getStdin;
   Env.put = putStdout;
   closeFiles(NULL,NULL,NULL);
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
         Jam = YES,  run(val(Err)),  Jam = NO;
      if (!isatty(STDIN_FILENO))
         bye(1);
      load(NULL, '?', Nil);
   }
   Env.stack = NULL;
   while (Env.bind) {
      i = Env.bind->cnt;
      while (--i >= 0)
         val(Env.bind->bnd[i].sym) = Env.bind->bnd[i].val;
      Env.bind = Env.bind->link;
   }
   Env.next = 0;
   Env.meth = NULL;
   Env.make = NULL;
   Env.parser = NULL;
   CatchPtr = NULL;
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

/*** Evaluation ***/
/* Evaluate symbolic expression */
any evExpr(any expr, any x) {
   any y;
   cell at;
   int i = length(car(expr));
   struct {  // bindFrame
      struct bindFrame *link;
      int cnt;
      struct {any sym; any val;} bnd[i];
   } f;

   Push(at,val(At));
   f.link = Env.bind,  Env.bind = (bindFrame*)&f;
   f.cnt = 0;
   for (y = car(expr);  isCell(y);  ++f.cnt, x = cdr(x), y = cdr(y)) {
      f.bnd[f.cnt].sym = car(y);
      f.bnd[f.cnt].val = EVAL(car(x));
   }
   if (isNil(y)) {
      while (--i >= 0) {
         x = val(f.bnd[i].sym);
         val(f.bnd[i].sym) = f.bnd[i].val;
         f.bnd[i].val = x;
      }
      x = prog(cdr(expr));
   }
   else if (y != At) {
      bindFrame g;

      Bind(y,g),  val(y) = x;
      while (--i >= 0) {
         x = val(f.bnd[i].sym);
         val(f.bnd[i].sym) = f.bnd[i].val;
         f.bnd[i].val = x;
      }
      x = prog(cdr(expr));
      Unbind(g);
   }
   else {
      int n, cnt;
      cell *arg;
      cell c[cnt = length(x)];

      n = cnt;
      while (--n >= 0)
         Push(c[n], EVAL(car(x))),  x = cdr(x);
      while (--i >= 0) {
         x = val(f.bnd[i].sym);
         val(f.bnd[i].sym) = f.bnd[i].val;
         f.bnd[i].val = x;
      }
      n = Env.next,  Env.next = cnt;
      arg = Env.arg,  Env.arg = c;
      x = prog(cdr(expr));
      Env.arg = arg,  Env.next = n;
   }
   while (--f.cnt >= 0)
      val(f.bnd[f.cnt].sym) = f.bnd[f.cnt].val;
   Env.bind = f.link;
   val(At) = Pop(at);
   return x;
}

static void undefined(any x, any ex) {
   void *h;
   char *p, nm[bufSize(x)];

   bufString(x, nm);
   if (!(p = strchr(nm,':'))  ||  p == nm  ||  p[1] == '\0')
      err(ex, x, "Undefined");
   *p++ = '\0';
   if (!(h = dlopen(nm, RTLD_LAZY | RTLD_GLOBAL))  ||  !(h = dlsym(h,p)))
      err(ex, x, "%s", (char*)dlerror());
   val(x) = box(num(h));
}

/* Evaluate a list */
any evList(any ex) {
   any x, y;

   if (SigInt)
      SigInt = NO,  brkLoad(ex);
   if (!isSym(x = car(ex))) {
      if (isNum(x))
         return ex;
      if (isNum(x = evList(x)))
         return evSubr(x,ex);
      if (isCell(x))
         return evExpr(x, cdr(ex));
   }
   for (y = val(x);  !isNum(y);  y = val(y)) {
      if (isCell(y))
         return evExpr(y, cdr(ex));
      if (y == val(y))
         undefined(y = x, ex);
   }
   return evSubr(y,ex);
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
   if (!nm)
      return Nil;
   return consStr(data(c2));
}

/* Evaluate count */
long evCnt(any ex, any x) {return xCnt(ex, EVAL(car(x)));}

long xCnt(any ex, any x) {
   NeedCnt(ex,x);
   return unBox(x);
}

long unBox(any x) {
   long n = unDig(x) / 2;
   return unDig(x) & 1? -n : n;
}

/* Construct count */
any boxCnt(long n) {return box(n>=0?  n*2 : -n*2+1);}

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

// (arg) -> any
any doArg(any ex __attribute__((unused))) {
   return data(Env.arg[Env.next]);
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

static any mkDat(int y, int m, int d) {
   int n;
   static char mon[13] = {31,31,28,31,30,31,30,31,31,30,31,30,31};

   if (m<1 || m>12 || d<1 || d>mon[m] && (m!=2 || d!=29 || y%4 || !(y%100) && y%400))
      return Nil;
   n = (12*y + m - 3) / 12;
   return boxCnt((4404*y+367*m-1094)/12 - 2*n + n/4 - n/100 + n/400 + d);
}

// (date) -> dat
// (date 'dat) -> (y m d)
// (date 'y 'm 'd) -> dat | NIL
// (date '(y m d)) -> dat | NIL
any doDate(any ex) {
   any x, z;
   int y, m, d, n;
   cell c1;
   time_t tim;
   struct tm *p;

   x = cdr(ex);
   if (isNum(z = EVAL(car(x))) && !isCell(x = cdr(x))) {
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
   if (isNil(z)) {
      time(&tim);
      p = localtime(&tim);
      return mkDat(p->tm_year+1900,  p->tm_mon+1,  p->tm_mday);
   }
   if (!isCell(z))
      return mkDat(xCnt(ex,z), evCnt(ex,x), evCnt(ex,cdr(x)));
   return mkDat(xCnt(ex, car(z)),  xCnt(ex, cadr(z)),  xCnt(ex, caddr(z)));
}

// (time) -> tim
// (time 'tim) -> (h m s)
// (time 'h 'm ['s]) -> tim | NIL
// (time '(h m [s])) -> tim | NIL
any doTime(any ex) {
   any x, z;
   int h, m, s;
   cell c1;
   time_t tim;
   struct tm *p;

   x = cdr(ex);
   if (isNum(z = EVAL(car(x))) && !isCell(x = cdr(x))) {
      s = xCnt(ex,z);
      Push(c1, cons(boxCnt(s % 60), Nil));
      data(c1) = cons(boxCnt(s / 60 % 60), data(c1));
      data(c1) = cons(boxCnt(s / 3600), data(c1));
      return Pop(c1);
   }
   if (isNil(z)) {
      time(&tim);
      p = localtime(&tim);
      return boxCnt(p->tm_hour * 3600 + p->tm_min * 60 + p->tm_sec);
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

// (cd 'sym) -> flg
any doCd(any ex) {
   any x;

   x = cdr(ex),  x = EVAL(car(x));
   NeedSym(ex,x);
   {
      char path[bufSize(x)];

      bufString(x, path);
      return chdir(path) < 0? Nil : T;
   }
}

// (ctty 'sym) -> flg
any doCtty(any ex) {
   any x;

   x = cdr(ex),  x = EVAL(car(x));
   NeedSym(ex,x);
   {
      char tty[bufSize(x)];

      bufString(x, tty);
      return freopen(tty, "r", stdin) && freopen(tty, "w", stdout)? T : Nil;
   }
}

// (info 'sym) -> (cnt dat . tim)
any doInfo(any ex) {
   any x;
   cell c1;
   struct tm *p;
   struct stat st;

   x = cdr(ex),  x = EVAL(car(x));
   NeedSym(ex,x);
   {
      char nm[bufSize(x)];

      bufString(x, nm);
      if (stat(nm, &st) < 0)
         return Nil;
      p = localtime(&st.st_mtime);
      Push(c1, boxCnt(p->tm_hour * 3600 + p->tm_min * 60 + p->tm_sec));
      data(c1) = cons(mkDat(p->tm_year+1900,  p->tm_mon+1,  p->tm_mday), data(c1));
      data(c1) = cons(boxWord2((word2)st.st_size), data(c1));
      return Pop(c1);
   }
}

// (argv) -> lst
any doArgv(any x) {
   char **p;
   cell c1;

   if (!*(p = AV))
      return Nil;
   if (strcmp(*p,"-") == 0)
      ++p;
   if (!*p)
      return Nil;
   Push(c1, x = cons(mkStr(*p++), Nil));
   while (*p)
      x = cdr(x) = cons(mkStr(*p++), Nil);
   return Pop(c1);
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
   ApplyArgs = cons(cons(cons(Quote, Nil), Nil), Nil);
   ApplyBody = cons(Nil,Nil);
   signal(SIGINT, doSigInt);
   signal(SIGTERM, doSigTerm);
   signal(SIGPIPE, SIG_IGN);
   signal(SIGTTIN, SIG_IGN);
   signal(SIGTTOU, SIG_IGN);
   setjmp(ErrRst);
   while (*AV  &&  strcmp(*AV,"-") != 0)
      load(NULL, 0, mkStr((byte*)*AV++));
   load(NULL, ':', Nil);
   doBye(Nil);
}
