/* 30sep04abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

// I/O Tokens
enum {NIX, BEG, DOT, END};
enum {NUMBER, INTERN, TRANSIENT, EXTERN};

static char Delim[] = " \t\n\r\"'()[]`~";
static int StrI, BinIx, BinCnt;
static cell StrCell, *StrP;
static bool Sync;
static byte *PipeBuf, *PipePtr;
static int (*getBin)(int);
static void (*putBin)(int);
static void (*PutSave)(int);
static int Transactions;
static byte TBuf[] = {INTERN+4, 'T'};

static void openErr(any ex, char *s) {err(ex, NULL, "%s open: %s", s, strerror(errno));}
static void lockErr(void) {err(NULL, NULL, "File lock: %s", strerror(errno));}
static void writeErr(char *s) {err(NULL, NULL, "%s write: %s", s, strerror(errno));}
static void dbErr(char *s) {err(NULL, NULL, "DB %s: %s", s, strerror(errno));}
static void eofErr(void) {err(NULL, NULL, "EOF Overrun");}
static void closeErr(char *s) {err(NULL, NULL, "%s close: %s", s, strerror(errno));}

int slow(int fd, byte *p, int cnt) {
   int n;

   while ((n = read(fd, p, cnt)) < 0)
      if (errno != EINTR)
         return 0;
   return n;
}

bool rdBytes(int fd, byte *p, int cnt) {
   int n;

   do
      while ((n = read(fd, p, cnt)) <= 0)
         if (!n || errno != EINTR)
            return NO;
   while (p += n,  cnt -= n);
   return YES;
}

bool wrBytes(int fd, byte *p, int cnt) {
   int n;

   do
      if ((n = write(fd, p, cnt)) >= 0)
         p += n, cnt -= n;
      else if (errno == EPIPE || errno == ECONNRESET)
         return NO;
      else if (errno != EINTR)
         writeErr("bytes");
   while (cnt);
   return YES;
}

/*** Low level I/O ***/
static int getBinary(int n) {
   static byte buf[256];

   if (BinIx == BinCnt) {
      if (!(BinCnt = slow(fileno(InFile), buf, n)))
         return -1;
      BinIx = 0;
   }
   return buf[BinIx++];
}

static any rdNum(int cnt) {
   int n, i;
   any x;
   cell c1;

   if ((n = getBin(cnt)) < 0)
      return NULL;
   i = 0,  Push(c1, x = box(n));
   if (--cnt == 62) {
      do {
         if ((n = getBin(1)) < 0)
            return NULL;
         byteSym(n, &i, &x);
      } while (--cnt);
      for (;;) {
         if ((cnt = getBin(1)) < 0)
            return NULL;
         if (cnt != 255)
            break;
         do {
            if ((n = getBin(cnt)) < 0)
               return NULL;
            byteSym(n, &i, &x);
         } while (--cnt);
      }
   }
   while (cnt) {
      if ((n = getBin(cnt--)) < 0)
         return NULL;
      byteSym(n, &i, &x);
   }
   return Pop(c1);
}

static any binRead(void) {
   int c;
   any x, y, *h;
   cell c1;

   if ((c = getBin(1)) < 0)
      return NULL;
   if ((c & ~3) == 0) {
      if (c == NIX)
         return Nil;
      if (c == BEG) {
         if ((x = binRead()) == NULL)
            return NULL;
         Push(c1, x = cons(x,Nil));
         while ((y = binRead()) != (any)END) {
            if (y == NULL) {
               drop(c1);
               return NULL;
            }
            if (y == (any)DOT) {
               if ((y = binRead()) == NULL) {
                  drop(c1);
                  return NULL;
               }
               cdr(x) = y == (any)END? data(c1) : y;
               break;
            }
            x = cdr(x) = cons(y,Nil);
         }
         return Pop(c1);
      }
      return (any)c;  // NIX, DOT or END
   }
   if ((y = rdNum(c / 4)) == NULL)
      return NULL;
   if ((c &= 3) == NUMBER)
      return y;
   if (c == TRANSIENT)
      return consStr(y);
   if (c == EXTERN) {
      if (x = findHash(y, h = Extern + hash(y)))
         return x;
      x = extSym(consSym(Nil,y));
      *h = cons(x,*h);
      return x;
   }
   if (x = findHash(y, h = Intern + hash(y)))
      return x;
   x = consSym(Nil,y);
   *h = cons(x,*h);
   return x;
}

static void prDig(int t, long n) {
   if ((n & 0xFFFFFF00) == 0)
      putBin(1*4+t), putBin(n);
   else if ((n & 0xFFFF0000) == 0)
      putBin(2*4+t), putBin(n), putBin(n>>8);
   else if ((n & 0xFF000000) == 0)
      putBin(3*4+t), putBin(n), putBin(n>>8), putBin(n>>16);
   else
      putBin(4*4+t), putBin(n), putBin(n>>8), putBin(n>>16), putBin(n>>24);
}

static int numByte(any s) {
   static int i;
   static any x;
   static word n;

   if (s)
      i = 0,  n = unDig(x = s);
   else if (n >>= 8,  (++i & sizeof(word)-1) == 0)
      n = unDig(x = cdr(numCell(x)));
   return n & 0xFF;
}

static void prNum(int t, any x) {
   int cnt, i;

   if (!isNum(cdr(numCell(x))))
      prDig(t, unDig(x));
   else if ((cnt = numBytes(x)) < 63) {
      putBin(cnt*4+t);
      putBin(numByte(x));
      while (--cnt)
         putBin(numByte(NULL));
   }
   else {
      putBin(63*4+t);
      putBin(numByte(x));
      for (i = 1; i < 63; ++i)
         putBin(numByte(NULL));
      cnt -= 63;
      while (cnt >= 255) {
         putBin(255);
         for (i = 0; i < 255; ++i)
            putBin(numByte(NULL));
         cnt -= 255;
      }
      putBin(cnt);
      while (--cnt >= 0)
         putBin(numByte(NULL));
   }
}

static void binPrint(any x) {
   any y;

   if (isNum(x))
      prNum(NUMBER, x);
   else if (isNil(x))
      putBin(NIX);
   else if (isSym(x)) {
      if (!isNum(y = name(x)))
         binPrint(y);
      else
         prNum(
            isExt(x)? EXTERN : hashed(x, hash(y), Intern)? INTERN : TRANSIENT,
            y );
   }
   else {
      y = x;
      putBin(BEG);
      while (binPrint(car(x)), !isNil(x = cdr(x))) {
         if (x == y) {
            putBin(DOT);
            break;
         }
         if (!isCell(x)) {
            putBin(DOT);
            binPrint(x);
            return;
         }
      }
      putBin(END);
   }
}

void pr(any x) {putBin = putStdout,  binPrint(x);}
void prn(long n) {putBin = putStdout,  prDig(0, n >= 0? n * 2 : -n * 2 + 1);}

/* Inter-Family communication */
static void putTell(int c) {
   *PipePtr++ = c;
   if (PipePtr == PipeBuf + PIPE_BUF - 1)  // END
      err(NULL, NULL, "Tell PIPE_BUF");
}

static void tellBeg(ptr *pb, ptr *pp, ptr buf) {
   *pb = PipeBuf,  *pp = PipePtr,  PipeBuf = PipePtr = buf;
   *PipePtr++ = BEG;
}

static void tell(any x) {putBin = putTell,  binPrint(x);}

static void tellEnd(ptr *pb, ptr *pp) {
   int i;
   int n = PipePtr - PipeBuf + 1;

   *PipePtr++ = END;
   if (Tell  &&  !wrBytes(Tell, PipeBuf, n))
      close(Tell),  Tell = 0;
   for (i = 0; i < PSize; i += 2)
      if (Pipe[i] >= 0)
         if (!wrBytes(Pipe[i+1], PipeBuf, n))
            close(Pipe[i]),  close(Pipe[i+1]),  Pipe[i] = -1;
   if (SigTerm)
      raise(SIGTERM);
   PipePtr = *pp,  PipeBuf = *pb;
}

static int getHear(int n) {
   static byte buf[256];

   if (BinIx == BinCnt) {
      if (!(BinCnt = slow(Hear, buf, n)))
         return -1;
      BinIx = 0;
   }
   return buf[BinIx++];
}

static any rdHear(void) {
   BinIx = BinCnt = 0,  getBin = getHear;
   return binRead();
}


/* Return next byte from symbol name */
int symByte(any s) {
   static any x;
   static word n;

   if (s) {
      if (!isNum(x = s))
         return 0;
      n = unDig(x);
   }
   else if ((n >>= 8) == 0) {
      if (!isNum(x = cdr(numCell(x))))
         return 0;
      n = unDig(x);
   }
   return n & 0xFF;
}

/* Return next char from symbol name */
int symChar(any s) {
   int c = symByte(s);

   if (c == 0xFF)
      return TOP;
   if (c & 0x80) {
      if ((c & 0x20) == 0)
         c &= 0x1F;
      else
         c = (c & 0xF) << 6 | symByte(NULL) & 0x3F;
      c = c << 6 | symByte(NULL) & 0x3F;
   }
   return c;
}

int numBytes(any x) {
   int cnt;
   word n;

   if (!isNum(x))
      return 0;
   for (cnt = 4;  isNum(cdr(numCell(x)));  cnt += 4)
      x = cdr(numCell(x));
   if (((n = unDig(x)) & 0xFF000000) == 0) {
      --cnt;
      if ((n & 0xFF0000) == 0) {
         --cnt;
         if ((n & 0xFF00) == 0)
            --cnt;
      }
   }
   return cnt;
}

/* Buffer size */
int bufSize(any x) {return numBytes(name(x)) + 1;}

int pathSize(any x) {
   int c = firstByte(x);

   if (c != '@'  &&  (c != '+' || secondByte(x) != '@'))
      return bufSize(x);
   if (!Home)
      return numBytes(name(x));
   return strlen(Home) + numBytes(name(x));
}

void bufString(any x, byte *p) {
   int c = symByte(name(x));

   while (*p++ = c)
      c = symByte(NULL);
}

void pathString(any x, byte *p) {
   int c;
   byte *h;

   if ((c = symByte(name(x))) == '+')
      *p++ = c,  c = symByte(NULL);
   if (c != '@')
      while (*p++ = c)
         c = symByte(NULL);
   else {
      if (h = Home)
         do
            *p++ = *h++;
         while (*h);
      while (*p++ = symByte(NULL));
   }
}

/* Add next byte to symbol name */
void byteSym(int c, int *i, any *p) {
   if ((*i += 8) < 32)
      setDig(*p, unDig(*p) | (c & 0xFF) << *i);
   else
      *i = 0,  *p = cdr(numCell(*p)) = box(c);
}

/* Box first char of symbol name */
any boxChar(int c, int *i, any *p) {
   *i = 0;
   if (c < 0x80)
      *p = box(c);
   else if (c < 0x800) {
      *p = box(0xC0 | c>>6 & 0x1F);
      byteSym(0x80 | c & 0x3F, i, p);
   }
   else if (c == TOP)
      *p = box(0xFF);
   else {
      *p = box(0xE0 | c>>12 & 0x0F);
      byteSym(0x80 | c>>6 & 0x3F, i, p);
      byteSym(0x80 | c & 0x3F, i, p);
   }
   return *p;
}

/* Add next char to symbol name */
void charSym(int c, int *i, any *p) {
   if (c < 0x80)
      byteSym(c, i, p);
   else if (c < 0x800) {
      byteSym(0xC0 | c>>6 & 0x1F, i, p);
      byteSym(0x80 | c & 0x3F, i, p);
   }
   else if (c == TOP)
      byteSym(0xFF, i, p);
   else {
      byteSym(0xE0 | c>>12 & 0x0F, i, p);
      byteSym(0x80 | c>>6 & 0x3F, i, p);
      byteSym(0x80 | c & 0x3F, i, p);
   }
}

static void rdOpen(any ex, any x, inFrame *f) {
   if (isNum(x)) {
      int n = (int)unBox(x);

      if (n < 0) {
         inFrame *g = Env.inFiles;

         for (;;) {
            if (!(g = g->link)) {
               f->fp = stdin;
               break;
            }
            if (!++n) {
               f->fp = g->fp;
               break;
            }
         }
         f->pid = -1;
      }
      else {
         if (!(f->fp = fdopen(dup(n), "r")))
            openErr(ex, "Read FD");
         f->pid = 0;
      }
   }
   else if (isNil(x))
      f->pid = -1,  f->fp = stdin;
   else if (isSym(x)) {
      byte nm[pathSize(x)];

      pathString(x,nm);
      if (!(f->fp = fopen(nm,"r")))
         openErr(ex, nm);
      f->pid = 0;
   }
   else {
      any y;
      int i, pfd[2], ac = length(x);
      byte *av[ac+1];

      if (pipe(pfd) < 0)
         pipeError(ex, "read open");
      av[0] = alloc(NULL, pathSize(y = xSym(car(x)))),  pathString(y, av[0]);
      for (i = 1; isCell(x = cdr(x)); ++i)
         av[i] = alloc(NULL, bufSize(y = xSym(car(x)))),  bufString(y, av[i]);
      av[ac] = NULL;
      if ((f->pid = fork()) == 0) {
         setpgid(0,0);
         close(pfd[0]);
         if (pfd[1] != STDOUT_FILENO)
            dup2(pfd[1], STDOUT_FILENO),  close(pfd[1]);
         execvp(av[0], (char**)av);
         execError(av[0]);
      }
      i = 0;  do
         free(av[i]);
      while (++i < ac);
      if (f->pid < 0)
         err(ex, NULL, "fork");
      setpgid(f->pid,0);
      close(pfd[1]);
      if (!(f->fp = fdopen(pfd[0], "r")))
         openErr(ex, "Read pipe");
   }
}

static void wrOpen(any ex, any x, outFrame *f) {
   if (isNum(x)) {
      int n = (int)unBox(x);

      if (n < 0) {
         outFrame *g = Env.outFiles;

         for (;;) {
            if (!(g = g->link)) {
               f->fp = stdout;
               break;
            }
            if (!++n) {
               f->fp = g->fp;
               break;
            }
         }
         f->pid = -1;
      }
      else {
         if (!(f->fp = fdopen(dup(n), "w")))
            openErr(ex, "Write FD");
         f->pid = 0;
      }
   }
   else if (isNil(x))
      f->pid = -1,  f->fp = stdout;
   else if (isSym(x)) {
      byte nm[pathSize(x)];

      pathString(x,nm);
      if (nm[0] == '+') {
         if (!(f->fp = fopen(nm+1, "a")))
            openErr(ex, nm);
      }
      else if (!(f->fp = fopen(nm, "w")))
         openErr(ex, nm);
      f->pid = 0;
   }
   else {
      any y;
      int i, pfd[2], ac = length(x);
      byte *av[ac+1];

      if (pipe(pfd) < 0)
         pipeError(ex, "write open");
      av[0] = alloc(NULL, pathSize(y = xSym(car(x)))),  pathString(y, av[0]);
      for (i = 1; isCell(x = cdr(x)); ++i)
         av[i] = alloc(NULL, bufSize(y = xSym(car(x)))),  bufString(y, av[i]);
      av[ac] = NULL;
      if ((f->pid = fork()) == 0) {
         setpgid(0,0);
         close(pfd[1]);
         if (pfd[0] != STDIN_FILENO)
            dup2(pfd[0], STDIN_FILENO),  close(pfd[0]);
         execvp(av[0], (char**)av);
         execError(av[0]);
      }
      i = 0;  do
         free(av[i]);
      while (++i < ac);
      if (f->pid < 0)
         err(ex, NULL, "fork");
      setpgid(f->pid,0);
      close(pfd[0]);
      if (!(f->fp = fdopen(pfd[1], "w")))
         openErr(ex, "Write pipe");
   }
}

static void ctOpen(any ex, any x, ctlFrame *f) {
   NeedSym(ex,x);
   {
      byte nm[pathSize(x)];
      struct flock fl;

      pathString(x,nm);
      if (nm[0] == '+') {
         if ((f->fd = open(nm+1, O_CREAT|O_RDWR, 0666)) < 0)
            openErr(ex, nm);
         fl.l_type = F_RDLCK;
      }
      else {
         if ((f->fd = open(nm, O_CREAT|O_RDWR, 0666)) < 0)
            openErr(ex, nm);
         fl.l_type = F_WRLCK;
      }
      fl.l_whence = SEEK_SET;
      fl.l_start = 0;
      fl.l_len = 0;
      while (fcntl(f->fd, F_SETLKW, &fl) < 0)
         if (errno != EINTR)
            close(f->fd),  lockErr();
   }
}

/*** Reading ***/
void getStdin(void) {
   if (InFile != stdin || !isCell(val(Led)))
      Chr = getc(InFile);
   else {
      static word dig;

      if (!isNum(Line))
         dig = isNum(Line = name(run(val(Led))))? unDig(Line) : '\n';
      else if ((dig >>= 8) == 0)
         dig = isNum(Line = cdr(numCell(Line)))? unDig(Line) : '\n';
      Chr = dig & 0xFF;
   }
}

static void getParse(void) {
   if ((Chr = Env.parser->dig & 0xFF) == 0xFF)
      Chr = -1;
   else if ((Env.parser->dig >>= 8) == 0) {
      Env.parser->dig =
         isNum(Env.parser->name = cdr(numCell(Env.parser->name))) ?
            unDig(Env.parser->name) : Env.parser->eof;
   }
}

static void pushInFiles(inFrame *f) {
   f->next = Chr,  Chr = 0;
   InFile = f->fp;
   f->link = Env.inFiles,  Env.inFiles = f;
}

static void pushOutFiles(outFrame *f) {
   OutFile = f->fp;
   f->link = Env.outFiles,  Env.outFiles = f;
}

static void pushCtlFiles(ctlFrame *f) {
   f->link = Env.ctlFiles,  Env.ctlFiles = f;
}

static void popInFiles(void) {
   if (Env.inFiles->pid >= 0) {
      fclose(InFile);
      if (Env.inFiles->pid > 0)
         while (waitpid(Env.inFiles->pid, NULL, 0) < 0)
            if (errno != EINTR)
               closeErr("Read pipe");
   }
   Chr = Env.inFiles->next;
   InFile = (Env.inFiles = Env.inFiles->link)?  Env.inFiles->fp : stdin;
}

static void popOutFiles(void) {
   if (Env.outFiles->pid >= 0) {
      fclose(OutFile);
      if (Env.outFiles->pid > 0)
         while (waitpid(Env.outFiles->pid, NULL, 0) < 0)
            if (errno != EINTR)
               closeErr("Write pipe");
   }
   OutFile = (Env.outFiles = Env.outFiles->link)? Env.outFiles->fp : stdout;
}

static void popCtlFiles(void) {
   close(Env.ctlFiles->fd);
   Env.ctlFiles = Env.ctlFiles->link;
}

void closeFiles(inFrame *in, outFrame *out, ctlFrame *ctl) {
   while (Env.inFiles != in)
      popInFiles();
   while (Env.outFiles != out)
      popOutFiles();
   while (Env.ctlFiles != ctl)
      popCtlFiles();
}

/* Skip White Space and Comments */
static int skip(void) {
   for (;;) {
      if (Chr < 0)
         return Chr;
      while (Chr <= ' ') {
         Env.get();
         if (Chr < 0)
            return Chr;
      }
      if (Chr != '#')
         return Chr;
      while (Env.get(), Chr != '\n')
         if (Chr < 0)
            return Chr;
      Env.get();
   }
}

/* Test for escaped characters */
static void testEsc(void) {
   for (;;) {
      if (Chr < 0)
         eofErr();
      if (Chr == '^') {
         Env.get();
         if (Chr == '?')
            Chr = 127;
         else
            Chr &= 0x1F;
         return;
      }
      if (Chr != '\\')
         return;
      if (Env.get(), Chr != '\n')
         return;
      do
         Env.get();
      while (Chr == ' '  ||  Chr == '\t');
   }
}

/* Read a List */
static any rdList(void) {
   any x;
   cell c1, c2;
   static any read0(bool);

   Env.get();
   if (skip() == ')') {
      Env.get();
      return Nil;
   }
   if (Chr == ']')
      return Nil;
   for (;;) {
      if (Chr != '~') {
         Push(c1, x = cons(read0(NO),Nil));
         break;
      }
      Env.get();
      Push(c1, read0(NO));
      if (isCell(x = data(c1) = EVAL(data(c1)))) {
         do
            x = cdr(x);
         while (isCell(cdr(x)));
         break;
      }
      drop(c1);
   }
   for (;;) {
      if (skip() == ')') {
         Env.get();
         break;
      }
      if (Chr == ']')
         break;
      if (Chr == '.') {
         Env.get();
         cdr(x) = skip()==')' || Chr==']'? data(c1) : read0(NO);
         if (skip() == ')')
            Env.get();
         else if (Chr != ']')
            err(NULL, x, "Bad dotted pair");
         break;
      }
      if (Chr != '~')
         x = cdr(x) = cons(read0(NO),Nil);
      else {
         Env.get();
         Push(c2, read0(NO));
         data(c2) = EVAL(data(c2));
         if (isCell(cdr(x) = Pop(c2)))
            do
               x = cdr(x);
            while (isCell(cdr(x)));
      }
   }
   return Pop(c1);
}

/* Try for anonymous symbol */
static any anonymous(any s) {
   unsigned c;
   unsigned long n;
   heap *h;

   if ((c = symByte(s)) != '$')
      return NULL;
   n = 0;
   while (c = symByte(NULL)) {
      if (c < '0' || c > '9')
         return NULL;
      n = n * 10 + c - '0';
   }
   n *= sizeof(cell);
   h = Heaps;
   do
      if ((any)n > h->cells  &&  (any)n < h->cells + CELLS)
         return symPtr(n);
   while (h = h->next);
   return NULL;
}

/* Read one Expression */
static any read0(bool top) {
   int i;
   any x, y, *h;
   cell c1;

   if (skip() < 0) {
      if (top)
         return Nil;
      eofErr();
   }
   if (Chr == '(') {
      x = rdList();
      if (top  &&  Chr == ']')
         Env.get();
      return x;
   }
   if (Chr == '[') {
      x = rdList();
      if (Chr != ']')
         err(NULL, x, "Super parentheses mismatch");
      Env.get();
      return x;
   }
   if (Chr == '\'') {
      Env.get();
      return cons(Quote, read0(NO));
   }
   if (Chr == ',') {
      Env.get();
      if (isCell(y = member(x = read0(NO), val(Uni))))
         return car(y);
      val(Uni) = cons(x, val(Uni));
      return x;
   }
   if (Chr == '`') {
      Env.get();
      Push(c1, read0(NO));
      x = EVAL(data(c1));
      drop(c1);
      return x;
   }
   if (Chr == '"') {
      Env.get();
      if (Chr == '"') {
         Env.get();
         return Nil;
      }
      testEsc();
      i = 0,  Push(c1, y = box(Chr));
      while (Env.get(), Chr != '"') {
         testEsc();
         byteSym(Chr, &i, &y);
      }
      y = Pop(c1),  Env.get();
      if (x = findHash(y, h = Transient + hash(y)))
         return x;
      x = consStr(y);
      if (Env.get == getStdin)
         *h = cons(x,*h);
      return x;
   }
   if (Chr == '{') {
      Env.get();
      if (Chr == '}') {
         Env.get();
         return consSym(Nil,Nil);
      }
      i = 0,  Push(c1, y = box(Chr));
      while (Env.get(), Chr != '}') {
         if (Chr < 0)
            eofErr();
         byteSym(Chr, &i, &y);
      }
      y = Pop(c1),  Env.get();
      if (x = findHash(y, h = Extern + hash(y)))
         return x;
      x = extSym(consSym(Nil,y));
      *h = cons(x,*h);
      return x;
   }
   if (strchr(Delim, Chr))
      err(NULL, NULL, "Bad input '%c' (%d)", isprint(Chr)? Chr:'?', Chr);
   i = 0,  Push(c1, y = box(Chr));
   while (Env.get(), !strchr(Delim, Chr))
      byteSym(Chr, &i, &y);
   y = Pop(c1);
   if (unDig(y) == ('L'<<16 | 'I'<<8 | 'N'))
      return Nil;
   if (x = findHash(y, h = Intern + hash(y)))
      return x;
   if (x = symToNum(y, (int)unDig(val(Scl)) / 2, '.', 0))
      return x;
   if (x = anonymous(y))
      return x;
   x = consSym(Nil,y);
   *h = cons(x,*h);
   return x;
}

/* Read one expression */
any read1(int end) {
   any x;

   if (!Chr)
      Env.get();
   if (Chr == end)
      return Nil;
   x = read0(YES);
   while (Chr  &&  strchr(" \t)]", Chr))
      Env.get();
   return x;
}

// (read) -> any
any doRead(any x) {
   x = read1(0);
   if (InFile == stdin  &&  Chr == '\n')
      Chr = 0;
   return x;
}

long waitFd(any ex, int fd, long ms) {
   any x;
   cell c1;
   int i, j, m, n;
   long t;
   bool flg;
   fd_set fdSet;
   char buf[1024];
   struct timeval *tp, tv;

   Save(c1);
   do {
      if (ms >= 0)
         t = ms,  tp = &tv;
      else
         t = LONG_MAX,  tp = NULL;
      FD_ZERO(&fdSet);
      m = 0;
      if (fd >= 0)
         FD_SET(m = fd, &fdSet);
      if (Hear) {
         if (Hear > m)
            m = Hear;
         FD_SET(Hear, &fdSet);
      }
      for (x = data(c1) = val(Key); isCell(x); x = cdr(x))
         if (isNeg(caar(x))) {
            if ((n = (int)unDig(cadar(x)) / 2) < t)
               tp = &tv,  t = n;
         }
         else {
            if ((n = (int)unDig(caar(x)) / 2) > m)
               m = n;
            FD_SET(n, &fdSet);
         }
      if (Mic[0]) {
         if (Mic[0] > m)
            m = Mic[0];
         FD_SET(Mic[0], &fdSet);
      }
      for (i = 0; i < PSize; i += 2) {
         if (Pipe[i] >= 0) {
            if (Pipe[i] > m)
               m = Pipe[i];
            FD_SET(Pipe[i], &fdSet);
         }
      }
      if (tp) {
         tv.tv_sec = t / 1000;
         tv.tv_usec = t % 1000 * 1000;
      }
      while (select(m+1, &fdSet, NULL, NULL, tp) < 0)
         if (errno != EINTR)
            err(ex, NULL, "Select error: %s", strerror(errno));
      if (tp) {
         t -= tv.tv_sec*1000 + tv.tv_usec/1000;
         if (ms > 0  &&  (ms -= t) < 0)
            ms = 0;
      }
      for (flg = NO, i = 0; i < PSize; i += 2) {
         if (Pipe[i] >= 0  &&  FD_ISSET(Pipe[i], &fdSet)) {
            if (!(n = slow(Pipe[i], buf, sizeof(buf))))
               close(Pipe[i]),  close(Pipe[i+1]),  Pipe[i] = -1;
            else {
               flg = YES;
               for (j = 0; j < PSize; j += 2)
                  if (Pipe[j] >= 0  &&  j != i)
                     if (!wrBytes(Pipe[j+1], buf, n))
                        close(Pipe[j]),  close(Pipe[j+1]),  Pipe[j] = -1;
            }
         }
      }
      if (!flg  &&  Mic[0]  &&  FD_ISSET(Mic[0], &fdSet)  &&
               rdBytes(Mic[0], (byte*)&m, sizeof(int))  &&  Pipe[m] >= 0  &&
                                    !wrBytes(Pipe[m+1], TBuf, sizeof(TBuf)) )
         close(Pipe[m]),  close(Pipe[m+1]),  Pipe[m] = -1;
      if (SigTerm)
         raise(SIGTERM);
      for (x = data(c1); isCell(x); x = cdr(x))
         if (isNeg(caar(x))) {
            if ((n = (int)(unDig(cadar(x)) / 2 - t)) > 0)
               setDig(cadar(x), 2*n);
            else {
               setDig(cadar(x), unDig(caar(x)));
               run(cddar(x));
            }
         }
      if (Hear  &&  FD_ISSET(Hear, &fdSet))
         if ((x = rdHear()) == NULL)
            close(Hear),  Hear = 0;
         else if (x == T)
            Sync = YES;
         else
            evList(x);
      for (x = data(c1); isCell(x); x = cdr(x))
         if (!isNeg(caar(x)) && (n=(int)unDig(caar(x))/2)!=fd && FD_ISSET(n,&fdSet)) {
            run(cdar(x));
            break;
         }
   } while (ms  &&  fd >= 0 && !FD_ISSET(fd, &fdSet));
   drop(c1);
   return ms;
}

// (wait ['cnt] . prg) -> any
any doWait(any ex) {
   any x, y;
   long ms;

   x = cdr(ex);
   ms = isNil(y = EVAL(car(x)))? -1 : xCnt(ex,y);
   x = cdr(x);
   while (isNil(y = prog(x)))
      if (!(ms = waitFd(ex, -1, ms)))
         return Nil;
   return y;
}

// (sync) -> flg
any doSync(any ex) {
   if (!Mic[1] || !Hear)
      return Nil;
   if (write(Mic[1], &Slot, sizeof(int)) != sizeof(int))
      writeErr("sync");
   Sync = NO;
   do
      waitFd(ex, Hear, -1);
   while (!Sync);
   return T;
}

// (hear 'num|sym) -> any
any doHear(any ex) {
   any x;

   x = cdr(ex),  x = EVAL(car(x));
   NeedAtom(ex,x);
   if (isNum(x))
      Hear = (int)xCnt(ex,x);
   else {
      int fd;
      byte nm[pathSize(x)];

      pathString(x, nm);
      if ((fd = open(nm, O_RDONLY)) <= 0)
         openErr(ex, nm);
      Hear = fd;
   }
   return x;
}

// (tell 'sym ['any ..]) -> any
any doTell(any x) {
   any y;
   ptr pbSave, ppSave;
   byte buf[PIPE_BUF];

   if (!Tell && !PSize)
      return Nil;
   tellBeg(&pbSave, &ppSave, buf);
   do
      x = cdr(x),  tell(y = EVAL(car(x)));
   while (isCell(cdr(x)));
   tellEnd(&pbSave, &ppSave);
   return y;
}

// (poll 'cnt) -> flg
any doPoll(any ex) {
   int fd;
   fd_set fdSet;
   struct timeval tv;

   FD_ZERO(&fdSet);
   FD_SET(fd = (int)evCnt(ex,cdr(ex)), &fdSet);
   tv.tv_sec = tv.tv_usec = 0;
   while (select(fd+1, &fdSet, NULL, NULL, &tv) < 0)
      if (errno != EINTR)
         err(ex, NULL, "Poll error: %s", strerror(errno));
   return FD_ISSET(fd, &fdSet)? T : Nil;
}

// (key ['cnt]) -> sym
any doKey(any ex) {
   any x;
   int c;
   byte buf[2];

   fflush(stdout);
   setRaw();
   x = cdr(ex);
   if (!waitFd(ex, STDIN_FILENO, isNil(x = EVAL(car(x)))? -1 : xCnt(ex,x)))
      return Nil;
   if (!rdBytes(STDIN_FILENO, buf, 1))
      return Nil;
   if ((c = buf[0]) == 0xFF)
      c = TOP;
   else if (c & 0x80) {
      if ((c & 0x20) == 0) {
         if (!rdBytes(STDIN_FILENO, buf, 1))
            return Nil;
         c = (c & 0x1F) << 6 | buf[0] & 0x3F;
      }
      else {
         if (!rdBytes(STDIN_FILENO, buf, 2))
            return Nil;
         c = ((c & 0xF) << 6 | buf[0] & 0x3F) << 6 | buf[1] & 0x3F;
      }
   }
   return mkChar(c);
}

/* Get full char from input channel */
static int getChar(void) {
   int c;

   if ((c = Chr) == 0xFF)
      return TOP;
   if (c & 0x80) {
      Env.get();
      if ((c & 0x20) == 0)
         c &= 0x1F;
      else
         c = (c & 0xF) << 6 | Chr & 0x3F,  Env.get();
      if (Chr < 0)
         eofErr();
      c = c << 6 | Chr & 0x3F;
   }
   return c;
}

// (peek) -> sym
any doPeek(any ex __attribute__((unused))) {
   if (!Chr)
      Env.get();
   return Chr<0? Nil : mkChar(Chr);
}

// (char) -> sym
// (char 'cnt) -> sym
// (char T) -> sym
// (char 'sym) -> cnt
any doChar(any ex) {
   any x = cdr(ex);
   if (!isCell(x)) {
      if (!Chr)
         Env.get();
      x = Chr<0? Nil : mkChar(getChar());
      Env.get();
      return x;
   }
   if (isNum(x = EVAL(car(x))))
      return IsZero(x)? Nil : mkChar(unDig(x) / 2);
   if (isSym(x))
      return x == T? mkChar(TOP) : boxCnt(symChar(name(x)));
   atomError(ex,x);
}

// (skip) -> sym
any doSkip(any ex __attribute__((unused))) {
   return skip()<0? Nil : mkChar(Chr);
}

// (from 'any ..) -> sym
any doFrom(any ex) {
   any x;
   int res, i, j, ac = length(x = cdr(ex)), p[ac];
   cell c[ac];
   byte *av[ac];

   if (ac == 0)
      return Nil;
   for (i = 0;;) {
      Push(c[i], evSym(x));
      av[i] = alloc(NULL, bufSize(data(c[i]))),  bufString(data(c[i]), av[i]);
      p[i] = 0;
      if (++i == ac)
         break;
      x = cdr(x);
   }
   res = -1;
   if (!Chr)
      Env.get();
   while (Chr >= 0) {
      for (i = 0; i < ac; ++i) {
         for (;;) {
            if (av[i][p[i]] == (byte)Chr) {
               if (av[i][++p[i]])
                  break;
               Env.get();
               res = i;
               goto done;
            }
            if (!p[i])
               break;
            for (j = 1; --p[i]; ++j)
               if (memcmp(av[i], av[i]+j, p[i]) == 0)
                  break;
         }
      }
      Env.get();
   }
done:
   i = 0;  do
      free(av[i]);
   while (++i < ac);
   drop(c[0]);
   return res < 0? Nil : data(c[res]);
}

// (till 'any ['flg]) -> lst|sym
any doTill(any ex) {
   any x;
   int i;
   cell c1;

   x = evSym(cdr(ex));
   {
      byte buf[bufSize(x)];

      bufString(x, buf);
      if (!Chr)
         Env.get();
      if (Chr < 0 || strchr(buf,Chr))
         return Nil;
      x = cddr(ex);
      if (isNil(EVAL(car(x)))) {
         Push(c1, x = cons(mkChar(getChar()), Nil));
         while (Env.get(), Chr > 0 && !strchr(buf,Chr))
            x = cdr(x) = cons(mkChar(getChar()), Nil);
         return Pop(c1);
      }
      Push(c1, boxChar(getChar(), &i, &x));
      while (Env.get(), Chr > 0 && !strchr(buf,Chr))
         charSym(getChar(), &i, &x);
      return consStr(Pop(c1));
   }
}

// (line 'flg ['cnt ..]) -> lst|sym
any doLine(any ex) {
   any x, y, z;
   bool pack;
   int i, n;
   cell c1;

   if (!Chr)
      Env.get();
   if (Chr < 0)
      return T;
   if (Chr == '\r')
      Env.get();
   if (Chr < 0  ||  Chr == '\n') {
      Chr = 0;
      return Nil;
   }
   x = cdr(ex);
   if (pack = !isNil(EVAL(car(x))))
      Push(c1, boxChar(getChar(), &i, &z));
   else
      Push(c1, cons(mkChar(getChar()), Nil));
   if (!isCell(x = cdr(x)))
      y = data(c1);
   else {
      if (!pack)
         z = data(c1);
      data(c1) = y = cons(data(c1), Nil);
      for (;;) {
         n = (int)evCnt(ex,x);
         while (--n) {
            if (Env.get(), Chr == '\r')
               Env.get();
            if (Chr < 0  ||  Chr == '\n') {
               Chr = 0;
               if (pack)
                  car(y) = consStr(car(y));
               return Pop(c1);
            }
            if (pack)
               charSym(getChar(), &i, &z);
            else
               z = cdr(z) = cons(mkChar(getChar()), Nil);
         }
         if (pack)
            car(y) = consStr(car(y));
         if (!isCell(x = cdr(x))) {
            pack = NO;
            break;
         }
         if (Env.get(), Chr == '\r')
            Env.get();
         if (Chr < 0  ||  Chr == '\n') {
            Chr = 0;
            return Pop(c1);
         }
         y = cdr(y) = cons(
            pack? boxChar(getChar(), &i, &z) : (z = cons(mkChar(getChar()), Nil)),
            Nil );
      }
   }
   for (;;) {
      if (Env.get(), Chr == '\r')
         Env.get();
      if (Chr < 0  ||  Chr == '\n') {
         Chr = 0;
         return pack? consStr(Pop(c1)) : Pop(c1);
      }
      if (pack)
         charSym(getChar(), &i, &z);
      else
         y = cdr(y) = cons(mkChar(getChar()), Nil);
   }
}

// (lines 'sym ..) -> cnt
any doLines(any ex) {
   any x, y;
   int c, cnt = 0;
   FILE *fp;

   for (x = cdr(ex); isCell(x); x = cdr(x)) {
      y = EVAL(car(x));
      NeedSym(ex,y);
      {
         byte nm[pathSize(y)];

         pathString(y, nm);
         if (!(fp = fopen(nm,"r")))
            openErr(ex, nm);
         while ((c = getc(fp)) >= 0)
            if (c == '\n')
               ++cnt;
         fclose(fp);
      }
   }
   return boxCnt(cnt);
}

static any parse(any x, bool skp) {
   int c;
   parseFrame *save, parser;
   void (*getSave)(void);
   cell c1;

   if (save = Env.parser)
      Push(c1, Env.parser->name);
   Env.parser = &parser;
   parser.dig = unDig(parser.name = name(x));
   parser.eof = 0xFF00 | ']';
   getSave = Env.get,  Env.get = getParse,  c = Chr,  Chr = 0;
   if (skp)
      getParse();
   x = rdList();
   Chr = c,  Env.get = getSave;
   if (Env.parser = save)
      drop(c1);
   return x;
}

static void putString(int c) {
   if (StrP)
      byteSym(c, &StrI, &StrP);
   else
      StrI = 0,  data(StrCell) = StrP = box(c);
}

void begString(void) {
   StrP = NULL;
   Push(StrCell,Nil);
   PutSave = Env.put,  Env.put = putString;
}

any endString(void) {
   Env.put = PutSave;
   drop(StrCell);
   return StrP? consStr(data(StrCell)) : Nil;
}

// (any 'sym) -> any
any doAny(any ex) {
   any x;

   x = cdr(ex),  x = EVAL(car(x));
   NeedSym(ex,x);
   if (!isNil(x)) {
      int c;
      parseFrame *save, parser;
      void (*getSave)(void);
      cell c1;

      if (save = Env.parser)
         Push(c1, Env.parser->name);
      Env.parser = &parser;
      parser.dig = unDig(parser.name = name(x));
      parser.eof = 0xFF00 | ' ';
      getSave = Env.get,  Env.get = getParse,  c = Chr,  Chr = 0;
      getParse();
      x = read0(YES);
      Chr = c,  Env.get = getSave;
      if (Env.parser = save)
         drop(c1);
   }
   return x;
}

// (sym 'any) -> sym
any doSym(any x) {
   cell c1;

   x = EVAL(cadr(x));
   begString();
   Push(c1,x);
   print(data(c1));
   return endString();
}

// (str 'sym) -> lst
// (str 'lst) -> sym
any doStr(any ex) {
   any x;
   cell c1;

   x = cdr(ex);
   if (isSym(x = EVAL(car(x))))
      return isNil(x)? Nil : parse(x,NO);
   NeedCell(ex,x);
   begString();
   Push(c1,x);
   print(car(x));
   while (isCell(x = cdr(x)))
      space(),  print(car(x));
   return endString();
}

any load(any ex, int pr, any x) {
   cell c1;
   inFrame f;

   if (isSym(x) && firstByte(x) == '-') {
      Push(c1, parse(x,YES));
      x = evList(data(c1));
      drop(c1);
      return x;
   }
   rdOpen(ex, x, &f);
   doHide(Nil);
   pushInFiles(&f);
   x = Nil;
   for (;;) {
      if (InFile != stdin)
         data(c1) = read1(0);
      else {
         if (pr && !Chr)
            Env.put(pr), space();
         data(c1) = read1('\n');
         SigInt = NO;
         if (Chr == '\n')
            Chr = 0;
      }
      if (isNil(data(c1)))
         break;
      Save(c1),  x = EVAL(data(c1)),  drop(c1);
      if (InFile == stdin && !Chr) {
         val(At3) = val(At2),  val(At2) = val(At),  val(At) = x;
         outString("-> "),  print(x),  crlf();
      }
   }
   popInFiles();
   doHide(Nil);
   return x;
}

// (load 'any ..) -> any
any doLoad(any ex) {
   any x, y;

   x = cdr(ex);
   do {
      y = EVAL(car(x));
      y = load(ex, '>', y);
   } while (isCell(x = cdr(x)));
   return y;
}

// (in 'any . prg) -> any
any doIn(any ex) {
   any x;
   inFrame f;

   x = cdr(ex),  x = EVAL(car(x));
   rdOpen(ex,x,&f);
   pushInFiles(&f);
   x = prog(cddr(ex));
   popInFiles();
   return x;
}

// (out 'any . prg) -> any
any doOut(any ex) {
   any x;
   outFrame f;

   x = cdr(ex),  x = EVAL(car(x));
   wrOpen(ex,x,&f);
   pushOutFiles(&f);
   x = prog(cddr(ex));
   popOutFiles();
   return x;
}

// (ctl 'sym . prg) -> any
any doCtl(any ex) {
   any x;
   ctlFrame f;

   x = cdr(ex),  x = EVAL(car(x));
   ctOpen(ex,x,&f);
   pushCtlFiles(&f);
   x = prog(cddr(ex));
   popCtlFiles();
   return x;
}

// (open 'sym) -> cnt | NIL
any doOpen(any ex) {
   any x;

   x = cdr(ex),  x = EVAL(car(x));
   NeedSym(ex,x);
   {
      int fd;
      byte nm[pathSize(x)];

      pathString(x, nm);
      if ((fd = open(nm, O_CREAT|O_RDWR, 0666)) >= 0)
         return boxCnt(fd);
   }
   return Nil;
}

// (close 'cnt) -> T
any doClose(any ex) {
   close((int)evCnt(ex, cdr(ex)));
   return T;
}

// (echo ['cnt ['cnt]] | ['sym ..]) -> sym
any doEcho(any ex) {
   any x, y;
   long cnt;

   x = cdr(ex),  y = EVAL(car(x));
   if (isNil(y) && !isCell(cdr(x))) {
      int n, dst = fileno(OutFile);
      byte buf[BUFSIZ];

      fflush(OutFile);
      if (Chr) {
         buf[0] = (byte)Chr;
         if (!wrBytes(dst,buf,1))
            return Nil;
      }
      Chr = 0;
      while ((n = fread(buf, 1, sizeof(buf), InFile)) > 0)
         if (!wrBytes(dst, buf, n))
            return Nil;
      return T;
   }
   if (isSym(y)) {
      int res, m, n, i, j, ac = length(x), p[ac], om, op;
      cell c[ac];
      byte *av[ac];

      for (i = 0;;) {
         Push(c[i], y);
         av[i] = alloc(NULL, bufSize(y)),  bufString(y, av[i]);
         p[i] = 0;
         if (++i == ac)
            break;
         y = evSym(x = cdr(x));
      }
      res = m = -1;
      if (!Chr)
         Env.get();
      while (Chr >= 0) {
         if ((om = m) >= 0)
            op = p[m];
         for (i = 0; i < ac; ++i) {
            for (;;) {
               if (av[i][p[i]] == (byte)Chr) {
                  if (av[i][++p[i]]) {
                     if (m < 0  ||  p[i] > p[m])
                        m = i;
                     break;
                  }
                  if (om >= 0)
                     for (j = 0, n = op-p[i]+1; j < n; ++j)
                        Env.put(av[om][j]);
                  Env.get();
                  res = i;
                  goto done;
               }
               if (!p[i])
                  break;
               for (j = 1; --p[i]; ++j)
                  if (memcmp(av[i], av[i]+j, p[i]) == 0)
                     break;
               if (m == i)
                  for (m = -1, j = 0; j < ac; ++j)
                     if (p[j] && (m < 0 || p[j] > p[m]))
                        m = j;
            }
         }
         if (m < 0) {
            if (om >= 0)
               for (i = 0; i < op; ++i)
                  Env.put(av[om][i]);
            Env.put(Chr);
         }
         else if (om >= 0)
            for (i = 0, n = op-p[m]+1; i < n; ++i)
               Env.put(av[om][i]);
         Env.get();
      }
   done:
      i = 0;  do
         free(av[i]);
      while (++i < ac);
      drop(c[0]);
      return res < 0? Nil : data(c[res]);
   }
   if (!Chr)
      Env.get();
   if (isCell(x = cdr(x))) {
      for (cnt = xCnt(ex,y); --cnt >= 0; Env.get())
         if (Chr < 0)
            return Nil;
      y = EVAL(car(x));
   }
   for (cnt = xCnt(ex,y); --cnt >= 0; Env.get()) {
      if (Chr < 0)
         return Nil;
      Env.put(Chr);
   }
   return T;
}

/*** Prining ***/
void putStdout(int c) {putc(c, OutFile);}

void crlf(void) {Env.put('\n');}
void space(void) {Env.put(' ');}

void outWord(word n) {
   if (n > 9)
      outWord(n / 10);
   Env.put('0' + n % 10);
}

void outString(byte *s) {
   while (*s)
      Env.put(*s++);
}

static void outSym(int c) {
   do
      Env.put(c);
   while (c = symByte(NULL));
}

static void outStr(int c) {
   do {
      if (c == '"'  ||  c == '^'  ||  c == '\\')
         Env.put('\\');
      else if (c == 127)
         Env.put('^'),  c = '?';
      else if (c < ' ')
         Env.put('^'),  c |= 0x40;
      Env.put(c);
   } while (c = symByte(NULL));
}

void outName(any s) {outSym(symByte(name(s)));}

/* Print one expression */
void print(any x) {
   if (isNum(x))
      outName(numToSym(x, 0, 0, 0));
   else if (isNil(x))
      outString("NIL");
   else if (isSym(x)) {
      int c;

      if (!(c = symByte(name(x))))
         Env.put('$'),  outWord(num(x)/sizeof(cell));
      else if (isExt(x))
         Env.put('{'),  outSym(c),  Env.put('}');
      else if (hashed(x, hash(name(x)), Intern))
         outSym(c);
      else
         Env.put('"'),  outStr(c),  Env.put('"');
   }
   else if (car(x) == Quote  &&  x != cdr(x))
      Env.put('\''),  print(cdr(x));
   else {
      cell c1;

      Push(c1,x);
      Env.put('(');
      while (print(car(x)), !isNil(x = cdr(x))) {
         if (x == data(c1)) {
            outString(" .");
            break;
         }
         if (!isCell(x)) {
            outString(" . ");
            print(x);
            break;
         }
         space();
         if (SigInt)
            SigInt = NO,  brkLoad(Up);
      }
      Env.put(')');
      drop(c1);
   }
}

void prin(any x) {
   if (!isNil(x)) {
      if (isNum(x))
         outName(numToSym(x, 0, 0, 0));
      else if (isSym(x)) {
         if (isExt(x))
            Env.put('{');
         outName(x);
         if (isExt(x))
            Env.put('}');
      }
      else if (car(x) == Quote)
         Env.put('\''),  prin(cdr(x));
      else {
         cell c1;

         Push(c1,x);
         while (prin(car(x)), !isNil(x = cdr(x))) {
            if (!isCell(x)) {
               prin(x);
               break;
            }
         }
         drop(c1);
      }
   }
}

// (prin 'any ..) -> any
any doPrin(any x) {
   any y = Nil;

   while (isCell(x = cdr(x)))
      prin(y = EVAL(car(x)));
   return y;
}

// (prinl 'any ..) -> any
any doPrinl(any x) {
   any y = Nil;

   while (isCell(x = cdr(x)))
      prin(y = EVAL(car(x)));
   crlf();
   return y;
}

// (space ['cnt]) -> T
any doSpace(any ex) {
   any x;
   int n;

   if (isNil(x = EVAL(cadr(ex))))
      Env.put(' ');
   else
      for (n = xCnt(ex,x); n > 0; --n)
         Env.put(' ');
   return T;
}

// (print 'any ..) -> any
any doPrint(any x) {
   any y;

   x = cdr(x),  print(y = EVAL(car(x)));
   while (isCell(x = cdr(x)))
      space(),  print(y = EVAL(car(x)));
   return y;
}

// (printsp 'any ..) -> any
any doPrintsp(any x) {
   any y;

   x = cdr(x);
   do
      print(y = EVAL(car(x))),  space();
   while (isCell(x = cdr(x)));
   return y;
}

// (println 'any ..) -> any
any doPrintln(any x) {
   any y;

   x = cdr(x),  print(y = EVAL(car(x)));
   while (isCell(x = cdr(x)))
      space(),  print(y = EVAL(car(x)));
   crlf();
   return y;
}

// (flush) -> flg
any doFlush(any ex __attribute__((unused))) {
   return fflush(OutFile)? Nil : T;
}

// (rewind) -> flg
any doRewind(any ex __attribute__((unused))) {
   return fseek(OutFile, 0L, SEEK_SET) || ftruncate(fileno(OutFile),0)? Nil : T;
}

// (rd) -> any
// (rd 'cnt) -> num | NIL
any doRd(any x) {
   long cnt;
   cell c1;

   x = cdr(x);
   if (!isNum(x = EVAL(car(x)))) {
      BinIx = BinCnt = 0,  getBin = getBinary;
      return binRead() ?: Nil;
   }
   if ((cnt = unBox(x)) < 0) {
      byte buf[cnt = -cnt];

      if (!rdBytes(fileno(InFile), buf, cnt))  // Little Endian
         return Nil;
      if (cnt % sizeof(word) == 0)
         Push(c1, Nil);
      else {
         word n = buf[--cnt];

         while (cnt % sizeof(word))
            n = n << 8 | buf[--cnt];
         Push(c1, box(n));
      }
      while ((cnt -= 4) >= 0)
         data(c1) = consNum(buf[cnt+3]<<24 | buf[cnt+2]<<16 | buf[cnt+1]<<8 | buf[cnt], data(c1));
   }
   else {
      int i;
      byte buf[cnt];

      if (!rdBytes(fileno(InFile), buf, cnt))
         return Nil;
      if (cnt % sizeof(word) == 0) {
         i = 0;
         Push(c1, Nil);
      }
      else {
         word n = buf[0];

         for (i = 1;  i < (int)(cnt % sizeof(word));  ++i)
            n = n << 8 | buf[i];
         Push(c1, box(n));
      }
      while (i < cnt) {
         data(c1) = consNum(buf[i]<<24 | buf[i+1]<<16 | buf[i+2]<<8 | buf[i+3], data(c1));
         i += 4;
      }
   }
   zapZero(data(c1));
   digMul2(data(c1));
   return Pop(c1);
}

// (pr 'any ..) -> any
any doPr(any x) {
   any y;

   x = cdr(x),  pr(y = EVAL(car(x)));
   while (isCell(x = cdr(x)))
      pr(y = EVAL(car(x)));
   return y;
}

// (wr 'num ..) -> num
any doWr(any x) {
   any y;

   x = cdr(x);
   do
      putc(unDig(y = EVAL(car(x))) / 2 & 255, OutFile);
   while (isCell(x = cdr(x)));
   return y;
}

/*** DB-I/O ***/
#define BLKSIZE 64   // DB block size

#define BLK 6
#define TAGMASK (BLKSIZE-1)
#define BLKMASK (~TAGMASK)

typedef long long adr;

static int BlkFile;
static adr BlkIndex, BlkLink, Marks;
static byte *Ptr, *Mark;
static byte Block[BLKSIZE];
static byte IniBlk[BLKSIZE];  // 01 00 00 00 00 00 NIL 0

static adr getAdr(byte *p) {
   return (adr)p[0] | (adr)p[1]<<8 | (adr)p[2]<<16 |
                           (adr)p[3]<<24 | (adr)p[4]<<32 | (adr)p[5]<<40;
}

static void setAdr(adr n, byte *p) {
   p[0] = (byte)n,  p[1] = (byte)(n >> 8),  p[2] = (byte)(n >> 16);
   p[3] = (byte)(n >> 24),  p[4] = (byte)(n >> 32),  p[5] = (byte)(n >> 40);
}

static any new64(adr n, any x) {
   int c;
   word2 w = 0;

   do {
      if ((c = n & 0x3F) > 11)
         c += 5;
      if (c > 42)
         c += 6;
      w = w << 8 | c + '0';
   } while (n >>= 6);
   if (w >> 32)
      return consNum((word)w, consNum((word)(w >> 32), x));
   return consNum((word)w, x);
}

static adr blk64(any x) {
   int c;
   word2 w;
   adr n = 0;

   if (isNum(x)) {
      w = unDig(x);
      if (isNum(x = cdr(numCell(x))))
         w |= (word2)unDig(x) << 32;
      do {
         c = w & 0xFF;
         if ((c -= '0') > 42)
            c -= 6;
         if (c > 11)
            c -= 5;
         n = n << 6 | c;
      } while (w >>= 8);
   }
   return n;
}

/* File Record Locking */
static void setLock(int cmd, int typ, off_t len) {
   struct flock fl;

   fl.l_type = typ;
   fl.l_whence = SEEK_SET;
   fl.l_start = 0;
   fl.l_len = len;
   if (fcntl(BlkFile, cmd, &fl) < 0)
      lockErr();
}

static void rdLock(void) {setLock(F_SETLKW, F_RDLCK, 1);}
static void wrLock(void) {setLock(F_SETLKW, F_WRLCK, 1);}
static void rwUnlock(int len) {setLock(F_SETLK, F_UNLCK, len);}

static pid_t tryLock(adr n) {
   struct flock fl;

   for (;;) {
      fl.l_type = F_WRLCK;
      fl.l_whence = SEEK_SET;
      fl.l_start = (off_t)n;
      fl.l_len = (off_t)(n != 0);  // Zero-id: Lock all
      if (fcntl(BlkFile, F_SETLK, &fl) >= 0)
         return 0;
      if (errno != EACCES  &&  errno != EAGAIN)
         lockErr();
      fl.l_type = F_WRLCK;  //??
      fl.l_whence = SEEK_SET;
      fl.l_start = (off_t)n;
      fl.l_len = (off_t)(n != 0);
      if (fcntl(BlkFile, F_GETLK, &fl) < 0)
         lockErr();
      if (fl.l_type != F_UNLCK)
         return fl.l_pid;
   }
}

static void blkPeek(adr pos, void *buf, size_t siz) {
   for (;;) {
      if (lseek(BlkFile, (off_t)pos, SEEK_SET) != (off_t)pos)
         dbErr("seek");
      if (read(BlkFile, buf, siz) == (ssize_t)siz)
         break;
      if (errno != EINTR)
         dbErr("read");
   }
}

static void blkPoke(adr pos, void *buf, size_t siz) {
   for (;;) {
      if (lseek(BlkFile, (off_t)pos, SEEK_SET) != (off_t)pos)
         dbErr("seek");
      if (write(BlkFile, buf, siz) == (ssize_t)siz)
         break;
      if (errno != EINTR)
         dbErr("write");
   }
}

static void rdBlock(adr n) {
   blkPeek(BlkIndex = n, Block, BLKSIZE);
   BlkLink = getAdr(Block) & BLKMASK;
   Ptr = Block + BLK;
}

static void wrBlock(void) {blkPoke(BlkIndex, Block, BLKSIZE);}

static adr newBlock(void) {
   adr n;
   byte buf[2*BLK];

   blkPeek(0, buf, 2*BLK);  // Get Free, Next
   if (n = getAdr(buf))
      blkPeek(n, buf, BLK);  // Get free link
   else
      n = getAdr(buf+BLK),  setAdr(n + BLKSIZE, buf+BLK);  // Increment next
   setAdr(0, IniBlk),  blkPoke(n, IniBlk, BLKSIZE);
   blkPoke(0, buf, 2*BLK);
   return n;
}

any newId(void) {
   adr n;

   wrLock();
   n = newBlock();
   rwUnlock(1);
   return new64(n/BLKSIZE, At2);  // dirty
}

bool isLife(any x) {
   adr n;
   byte buf[BLK];

   if (BlkFile && (n = blk64(name(x))*BLKSIZE)) {
      blkPeek(BLK, buf, BLK);  // Get Next
      if (n < getAdr(buf)) {
         blkPeek(n, buf, BLK);
         if ((getAdr(buf) & TAGMASK) == 1)
            return YES;
      }
   }
   return NO;
}

static void cleanUp(adr n) {
   adr p, fr;
   byte buf[BLK];

   blkPeek(0, buf, BLK),  fr = getAdr(buf);  // Get Free
   setAdr(n, buf),  blkPoke(0, buf, BLK);     // Set new
   do {
      p = n;
      blkPeek(p, buf, BLK),  n = getAdr(buf);  // Get block link
      n &= BLKMASK;        // Clear Tag
      setAdr(n, buf),  blkPoke(p, buf, BLK);
   } while (n);
   if (fr)
      setAdr(fr, buf),  blkPoke(p, buf, BLK);  // Append old free list
}

static int getBlock(int n __attribute__((unused))) {
   if (Ptr == Block+BLKSIZE) {
      if (!BlkLink)
         return 0;
      rdBlock(BlkLink);
   }
   return *Ptr++;
}

static void putBlock(int c) {
   if (Ptr == Block+BLKSIZE) {
      if (BlkLink)
         wrBlock(),  rdBlock(BlkLink);
      else {
         adr n = newBlock();
         int cnt = Block[0];  // Link must be 0

         setAdr(n | cnt, Block);
         wrBlock();
         BlkIndex = n;
         if (cnt < TAGMASK)
            ++cnt;
         setAdr(cnt, Block);
         Ptr = Block + BLK;
      }
   }
   *Ptr++ = (byte)c;
}

// (pool ['sym]) -> flg
any doPool(any ex) {
   any x;

   x = cdr(ex),  x = EVAL(car(x));
   NeedSym(ex,x);
   free(Mark), Mark = NULL, Marks = 0;
   if (BlkFile) {
      while (isNil(doRollback(Nil)));
      if (close(BlkFile) < 0)
         closeErr("DB");
      BlkFile = 0;
   }
   if (!isNil(x)) {
      byte nm[pathSize(x)];
      byte buf[2*BLK];

      pathString(x, nm);
      if ((BlkFile = open(nm, O_RDWR)) < 0) {
         if (errno != ENOENT  ||
                  (BlkFile = open(nm, O_CREAT|O_EXCL|O_RDWR, 0666)) < 0) {
            BlkFile = 0;
            return Nil;
         }
         setAdr(0, buf);              // Free
         setAdr(2*BLKSIZE, buf+BLK);  // Next
         blkPoke(0, buf, 2*BLK);
         setAdr(1, IniBlk),  blkPoke(BLKSIZE, IniBlk, BLKSIZE);
      }
   }
   return T;
}

// (seq 'sym1 ['sym2 ['num]]) -> sym | num | NIL
any doSeq(any ex) {
   adr n, n2, free, p, next;
   any x, y, z, *h;
   byte buf[BLK];

   x = cdr(ex),  y = EVAL(car(x));
   NeedExt(ex,y);
   if (n = blk64(name(y))*BLKSIZE) {
      if (x = cdr(x),  isExt(y = EVAL(car(x)))) {
         n2 = blk64(name(y))*BLKSIZE;
         x = cdr(x),  free = blk64(EVAL(car(x)));
         while ((n += BLKSIZE) < n2) {
            if (free) {
               setAdr(n, buf),  blkPoke(free, buf, BLK);
               setAdr(0, buf),  blkPoke(n, buf, BLK);  // Set new Free tail
            }
            else {
               blkPeek(0, buf, BLK); // Get Free
               blkPoke(n, buf, BLK); // Write Free|0
               setAdr(n, buf),  blkPoke(0, buf, BLK);  // Set new Free
            }
            free = n;
         }
         setAdr(1, IniBlk),  blkPoke(n, IniBlk, BLKSIZE);
         blkPeek(BLK, buf, BLK),  next = getAdr(buf);  // Get Next
         if (n >= next)
            setAdr(n+BLKSIZE, buf),  blkPoke(BLK, buf, BLK);  // Set new Next
         return new64(free,Nil);
      }
      blkPeek(BLK, buf, BLK),  next = getAdr(buf);  // Get Next
      while ((n += BLKSIZE) < next) {
         blkPeek(n, buf, BLK),  p = getAdr(buf);
         if ((p & TAGMASK) == 1) {
            z = new64(n/BLKSIZE, Nil);
            if (y = findHash(z, h = Extern + hash(z)))
               return y;
            y = extSym(consSym(Nil,z));
            *h = cons(y,*h);
            return y;
         }
      }
   }
   return Nil;
}

// (mark 'sym|0 [NIL | T | 0]) -> flg
any doMark(any ex) {
   any x, y;
   adr n, m;
   int b;
   byte *p, buf[BLK];

   x = cdr(ex);
   if (isNum(y = EVAL(car(x))))
      free(Mark), Mark = NULL, Marks = 0;
   else {
      NeedSym(ex,y);
      if (n = blk64(name(y))) {
         b = 1 << (n & 7);
         if ((n >>= 3) >= Marks) {
            m = Marks;
            blkPeek(BLK, buf, BLK),  Marks = getAdr(buf);  // Get Next
            Marks = (Marks/BLKSIZE + 7 >> 3);
            Mark = alloc(Mark,Marks);
            bzero(Mark+m, Marks-m);
            if (n >= Marks)
               err(ex, y, "Bad mark");
         }
         p = Mark + n;
         x = cdr(x);
         if (isNil(x = EVAL(car(x)))) {
            if (*p & b)  // Test mark
               return T;
         }
         else if (isNum(x))
            *p &= ~b;  // Clear mark
         else {
            *p |= b;  // Set mark
            return T;
         }
      }
   }
   return Nil;
}

// (lock ['sym]) -> cnt | NIL
any doLock(any ex) {
   any x;
   pid_t n;

   x = cdr(ex);
   if (isNil(x = EVAL(car(x))))
      n = tryLock(0);
   else {
      NeedExt(ex,x);
      n = tryLock(blk64(name(x))*BLKSIZE);
   }
   return n? boxCnt(n) : Nil;
}

int dbSize(any sym) {
   int n = 1;

   rdLock();
   rdBlock(blk64(name(sym))*BLKSIZE);
   while (BlkLink)
      ++n,  rdBlock(BlkLink);
   rwUnlock(1);
   return n;
}


void db(any ex, any s, int a) {
   any x, y, *p;

   if (!isNum(x = tail(s))) {
      if (a == 1)
         return;
      while (!isNum(x = cdr(x)));
   }
   p = &cdr(numCell(x));
   while (isNum(*p))
      p = &cdr(numCell(*p));
   if (!isSym(*p))
      p = &car(*p);
   if (*p != At3) {  // not deleted
      if (*p == At2) {  // dirty
         if (a == 3) {
            *p = At3;  // deleted
            val(s) = Nil;
            tail(s) = x;
         }
      }
      else if (isNil(*p) || a > 1) {
         if (a == 3) {
            *p = At3;  // deleted
            val(s) = Nil;
            tail(s) = x;
         }
         else if (*p == At)
            *p =  At2;  // loaded -> dirty
         else {  // NIL & 1 | 2
            cell c1;

            Push(c1,s);
            rdLock();
            rdBlock(blk64(x)*BLKSIZE);
            if ((Block[0] & TAGMASK) != 1)
               err(ex, s, "Bad ID");
            *p  =  a == 1? At : At2;  // loaded : dirty
            getBin = getBlock;
            val(s) = binRead();
            if (!isNil(y = binRead())) {
               x = tail(s) = cons(y,x);
               if ((y = binRead()) != T)
                  car(x) = cons(y,car(x));
               while (!isNil(y = binRead())) {
                  cdr(x) = cons(y,cdr(x));
                  if ((y = binRead()) != T)
                     cadr(x) = cons(y,cadr(x));
                  x = cdr(x);
               }
            }
            rwUnlock(1);
            drop(c1);
         }
      }
   }
}

// (begin) -> T
any doBegin(any x) {
   int i;
   any y, z;

   for (i = 0; i < HASH; ++i) {
      for (x = Extern[i];  isCell(x);  x = cdr(x)) {
         y = tail(car(x));
         while (isCell(y))
            y = cdr(y);
         y = numCell(y);
         while (isNum(cdr(y)))
            y = numCell(cdr(y));
         if (!isSym(z = cdr(y)))
            z = car(z);
         if (z == At2  ||  z == At3) {  // dirty or deleted
            cell c1, c2;

            Push(c1, cdr(y));
            Push(c2, car(x));
            cdr(y) = cons(z, cons(val(car(x)),Nil)),  y = cddr(y);
            for (z = tail(car(x));  isCell(z);  z = cdr(z)) {
               if (!isCell(car(z)))
                  cdr(y) = cons(car(z),Nil);
               else
                  cdr(y) = cons(cons(caar(z),cdar(z)), Nil);
               y = cdr(y);
            }
            cdr(y) = Pop(c1);
         }
      }
   }
   ++Transactions;
   return T;
}

// (commit ['flg]) -> flg
any doCommit(any x) {
   bool force, note;
   int i;
   any flg, y, z;
   ptr pbSave, ppSave;
   byte buf[PIPE_BUF];

   x = cdr(x),  flg = EVAL(car(x));
   wrLock();
   force = !isNil(flg) || !Transactions;
   protect(YES);
   if (note = Tell && !isNil(flg) && flg != T)
      tellBeg(&pbSave, &ppSave, buf),  tell(flg);
   for (i = 0; i < HASH; ++i) {
      for (x = Extern[i];  isCell(x);  x = cdr(x)) {
         y = tail(car(x));
         while (isCell(y))
            y = cdr(y);
         z = numCell(y);
         while (isNum(cdr(z)))
            z = numCell(cdr(z));
         if (!isSym(cdr(z))) {
            any t = car(y = cdr(z));
            y = cdr(y);
            while (!isSym(y = cdr(y))  &&  car(y) != At2  &&  car(y) != At3);
            if (isSym(y))
               cdr(z) = t;
            else
               cdr(z) = y,  car(y) = t;
         }
         else if (force) {
            if (cdr(z) == At3) {  // deleted
               cleanUp(blk64(y)*BLKSIZE);
               cdr(z) = Nil;
               if (note) {
                  if (PipePtr >= PipeBuf + PIPE_BUF - 9) {  // EXTERN <7> END
                     tellEnd(&pbSave, &ppSave);
                     tellBeg(&pbSave, &ppSave, buf),  tell(flg);
                  }
                  tell(car(x));
               }
            }
            else if (cdr(z) == At2) {  // dirty
               rdBlock(blk64(y)*BLKSIZE);
               Block[0] |= 1;  // Might be new
               putBin = putBlock;
               binPrint(val(y = car(x)));
               for (y = tail(y);  isCell(y);  y = cdr(y)) {
                  if (isSym(car(y)))
                     binPrint(car(y)), binPrint(T);
                  else
                     binPrint(cdar(y)), binPrint(caar(y));
               }
               putBin(NIX);
               setAdr(Block[0] & TAGMASK, Block);  // Clear Link
               wrBlock();
               if (BlkLink)
                  cleanUp(BlkLink);
               cdr(z) = At;  // loaded
               if (note) {
                  if (PipePtr >= PipeBuf + PIPE_BUF - 9) {  // EXTERN <7> END
                     tellEnd(&pbSave, &ppSave);
                     tellBeg(&pbSave, &ppSave, buf),  tell(flg);
                  }
                  tell(car(x));
               }
            }
         }
      }
   }
   if (note)
      tellEnd(&pbSave, &ppSave);
   protect(NO);
   if (Transactions) {
      rwUnlock(1);
      --Transactions;
      return Nil;
   }
   rwUnlock(0);  // Unlock all
   return T;
}

// (rollback) -> flg
any doRollback(any x) {
   int i;
   any y, z;

   for (i = 0; i < HASH; ++i) {
      for (x = Extern[i];  isCell(x);  x = cdr(x)) {
         y = tail(car(x));
         while (isCell(y))
            y = cdr(y);
         z = numCell(y);
         while (isNum(cdr(z)))
            z = numCell(cdr(z));
         if (!isSym(cdr(z))) {
            any *p = &tail(car(x));
            val(car(x)) = caddr(z);
            while (!isSym(cdddr(z)) && cadddr(z) != At2 && cadddr(z) != At3)
               *p = cdddr(z),  cdddr(z) = cddddr(z),  p = &cdr(*p);
            *p = y;
            cdr(z) = cdddr(z);
         }
         else if (!isNil(cdr(z))) {
            val(car(x)) = Nil;
            tail(car(x)) = y;
            cdr(z) = Nil;
         }
      }
   }
   if (Transactions) {
      --Transactions;
      return Nil;
   }
   rwUnlock(0);  // Unlock all
   return T;
}

// (dbck 'flg) -> any
any doDbck(any ex) {
   bool flg;
   int i;
   adr next, p, cnt;
   word2 blks, syms, offs;
   byte buf[2*BLK];
   cell c1;

   flg = !isNil(EVAL(cadr(ex)));
   blkPeek(0, buf, 2*BLK);  // Get Free, Next
   next = getAdr(buf+BLK);
   if ((p = lseek(BlkFile, 0, SEEK_END))  &&  p != next)  // Check size
      return mkStr("Size mismatch");
   cnt = BLKSIZE;
   blks = syms = offs = 0;
   BlkLink = getAdr(buf);  // Check free list
   protect(YES);
   while (BlkLink) {
      rdBlock(BlkLink);
      if ((cnt += BLKSIZE) > next)
         return mkStr("Circular free list");
      Block[0] |= TAGMASK,  wrBlock();  // Mark free list
   }
   for (p = BLKSIZE;  p != next;  p += BLKSIZE) {  // Check all chains
      if (rdBlock(p), (Block[0] & TAGMASK) == 0) {
         cnt += BLKSIZE;
         memcpy(Block, buf, BLK);  // Insert into free list
         wrBlock();
         setAdr(p, buf),  blkPoke(0, buf, BLK);
      }
      else if ((Block[0] & TAGMASK) == 1) {
         ++blks, ++syms;
         cnt += BLKSIZE;
         for (i = 2;  BlkLink != 0;  cnt += BLKSIZE) {
            ++blks;
            offs += labs((long)((BlkLink - BlkIndex) * 64 / next));
            rdBlock(BlkLink);
            if ((Block[0] & TAGMASK) != i)
               return mkStr("Bad chain");
            if (i < TAGMASK)
               ++i;
         }
      }
   }
   BlkLink = getAdr(buf);  // Unmark free list
   while (BlkLink) {
      rdBlock(BlkLink);
      if (Block[0] & TAGMASK)
         Block[0] &= BLKMASK,  wrBlock();
   }
   protect(NO);
   if (cnt != next)
      return  mkStr("Bad count");
   if (!flg)
      return Nil;
   Push(c1, boxWord2(offs));
   data(c1) = cons(boxWord2(syms), data(c1));
   data(c1) = cons(boxWord2(blks), data(c1));
   return Pop(c1);
}
