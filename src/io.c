/* 20dec06abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

#ifdef __CYGWIN__
#include <sys/file.h>
#define fcntl(fd,cmd,fl) 0
#define fileno_unlocked(f) fileno(f)
#endif

static any read0(bool);

// I/O Tokens
enum {NIX, BEG, DOT, END};
enum {NUMBER, INTERN, TRANSIENT, EXTERN};

static char Delim[] = " \t\n\r\"'()[]`~";
static int StrI, BinIx, BinCnt;
static cell StrCell, *StrP;
static bool Sync;
static byte *PipeBuf, *PipePtr;
static void (*PutSave)(int);
static int Transactions;
static byte TBuf[] = {INTERN+4, 'T'};

static void openErr(any ex, char *s) {err(ex, NULL, "%s open: %s", s, strerror(errno));}
static void lockErr(void) {err(NULL, NULL, "File lock: %s", strerror(errno));}
static void writeErr(char *s) {err(NULL, NULL, "%s write: %s", s, strerror(errno));}
static void dbErr(char *s) {err(NULL, NULL, "DB %s: %s", s, strerror(errno));}
static void dbfErr(void) {err(NULL, NULL, "Bad DB file");}
static void eofErr(void) {err(NULL, NULL, "EOF Overrun");}
static void closeErr(char *s) {err(NULL, NULL, "%s close: %s", s, strerror(errno));}

static void lockFile(int fd, int cmd, int typ) {
   struct flock fl;

   fl.l_type = typ;
   fl.l_whence = SEEK_SET;
   fl.l_start = 0;
   fl.l_len = 0;
   while (fcntl(fd, cmd, &fl) < 0  &&  typ != F_UNLCK)
      if (errno != EINTR)
         lockErr();
}

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
      if (!(BinCnt = slow(fileno_unlocked(InFile), buf, n)))
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

any binRead(void) {
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

void binPrint(any x) {
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

static void prTell(any x) {putBin = putTell,  binPrint(x);}

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
int bufSize(any x) {return isNum(x = name(x))? numBytes(x)+1 : 1;}

int pathSize(any x) {
   int c = firstByte(x);

   if (c != '@'  &&  (c != '+' || secondByte(x) != '@'))
      return bufSize(x);
   if (!Home)
      return numBytes(name(x));
   return strlen(Home) + numBytes(name(x));
}

void bufString(any x, char *p) {
   int c = symByte(name(x));

   while (*p++ = c)
      c = symByte(NULL);
}

void pathString(any x, char *p) {
   int c;
   char *h;

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

// (path 'sym) -> sym
any doPath(any ex) {
   any x;

   x = cdr(ex),  x = EVAL(car(x));
   NeedSym(ex,x);
   {
      char nm[pathSize(x)];

      pathString(x,nm);
      return mkStr(nm);
   }
}

/* Add next byte to symbol name */
void byteSym(int c, int *i, any *p) {
   if ((*i += 8) < 32)
      setDig(*p, unDig(*p) | (c & 0xFF) << *i);
   else
      *i = 0,  *p = cdr(numCell(*p)) = box(c & 0xFF);
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

static int currFd(any ex, char *p) {
   if (!Env.inFiles && !Env.outFiles)
      err(ex, NULL, "No current fd");
   if (!Env.inFiles)
      return fileno_unlocked(OutFile);
   if (!Env.outFiles)
      return fileno_unlocked(InFile);
   return labs((char*)Env.outFiles - p) > labs((char*)Env.inFiles - p)?
         fileno_unlocked(InFile) : fileno_unlocked(OutFile);
}

void rdOpen(any ex, any x, inFrame *f) {
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
      char nm[pathSize(x)];

      pathString(x,nm);
      if (nm[0] == '+') {
         if (!(f->fp = fopen(nm+1, "a+")))
            openErr(ex, nm);
         fseek(f->fp, 0L, SEEK_SET);
      }
      else if (!(f->fp = fopen(nm, "r")))
         openErr(ex, nm);
      f->pid = 0;
   }
   else {
      any y;
      int i, pfd[2], ac = length(x);
      char *av[ac+1];

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

void wrOpen(any ex, any x, outFrame *f) {
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
      char nm[pathSize(x)];

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
      char *av[ac+1];

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

void ctOpen(any ex, any x, ctlFrame *f) {
   NeedSym(ex,x);
   if (isNil(x)) {
      f->fd = -1;
      lockFile(currFd(ex, (char*)f), F_SETLKW, F_RDLCK);
   }
   else if (x == T) {
      f->fd = -1;
      lockFile(currFd(ex, (char*)f), F_SETLKW, F_WRLCK);
   }
   else {
      char nm[pathSize(x)];

      pathString(x,nm);
      if (nm[0] == '+') {
         if ((f->fd = open(nm+1, O_CREAT|O_RDWR, 0666)) < 0)
            openErr(ex, nm);
         lockFile(f->fd, F_SETLKW, F_RDLCK);
      }
      else {
         if ((f->fd = open(nm, O_CREAT|O_RDWR, 0666)) < 0)
            openErr(ex, nm);
         lockFile(f->fd, F_SETLKW, F_WRLCK);
      }
   }
}

/*** Reading ***/
void getStdin(void) {
   if (InFile != stdin)
      Chr = getc_unlocked(InFile);
   else if (!isCell(val(Led))) {
      byte buf[1];

      waitFd(NULL, STDIN_FILENO, -1);
      Chr = rdBytes(STDIN_FILENO, buf, 1)? buf[0] : -1;
   }
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

void pushInFiles(inFrame *f) {
   f->next = Chr,  Chr = 0;
   InFile = f->fp;
   f->get = Env.get,  Env.get = getStdin;
   f->link = Env.inFiles,  Env.inFiles = f;
}

void pushOutFiles(outFrame *f) {
   OutFile = f->fp;
   f->put = Env.put,  Env.put = putStdout;
   f->link = Env.outFiles,  Env.outFiles = f;
}

void pushCtlFiles(ctlFrame *f) {
   f->link = Env.ctlFiles,  Env.ctlFiles = f;
}

void popInFiles(void) {
   if (Env.inFiles->pid >= 0) {
      fclose(InFile);
      if (Env.inFiles->pid > 0)
         while (waitpid(Env.inFiles->pid, NULL, 0) < 0)
            if (errno != EINTR)
               closeErr("Read pipe");
   }
   Chr = Env.inFiles->next;
   Env.get = Env.inFiles->get;
   InFile = (Env.inFiles = Env.inFiles->link)?  Env.inFiles->fp : stdin;
}

void popOutFiles(void) {
   if (Env.outFiles->pid >= 0) {
      fclose(OutFile);
      if (Env.outFiles->pid > 0)
         while (waitpid(Env.outFiles->pid, NULL, 0) < 0)
            if (errno != EINTR)
               closeErr("Write pipe");
   }
   Env.put = Env.outFiles->put;
   OutFile = (Env.outFiles = Env.outFiles->link)? Env.outFiles->fp : stdout;
}

void popCtlFiles(void) {
   if (Env.ctlFiles->fd >= 0)
      close(Env.ctlFiles->fd);
   else
      lockFile(currFd(NULL, (char*)Env.ctlFiles), F_SETLK, F_UNLCK);
   Env.ctlFiles = Env.ctlFiles->link;
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

/* Skip White Space and Comments */
static int skip(int c) {
   for (;;) {
      if (Chr < 0)
         return Chr;
      while (Chr <= ' ') {
         Env.get();
         if (Chr < 0)
            return Chr;
      }
      if (Chr != c)
         return Chr;
      while (Env.get(), Chr != '\n')
         if (Chr < 0)
            return Chr;
      Env.get();
   }
}

/* Test for escaped characters */
static bool testEsc(void) {
   for (;;) {
      if (Chr < 0)
         return NO;
      if (Chr == '^') {
         Env.get();
         if (Chr == '?')
            Chr = 127;
         else
            Chr &= 0x1F;
         return YES;
      }
      if (Chr != '\\')
         return YES;
      if (Env.get(), Chr != '\n')
         return YES;
      do
         Env.get();
      while (Chr == ' '  ||  Chr == '\t');
   }
}

/* Read a list */
static any rdList(void) {
   any x;
   cell c1, c2;

   Env.get();
   if (skip('#') == ')') {
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
      if (skip('#') == ')') {
         Env.get();
         break;
      }
      if (Chr == ']')
         break;
      if (Chr == '.') {
         Env.get();
         cdr(x) = skip('#')==')' || Chr==']'? data(c1) : read0(NO);
         if (skip('#') == ')')
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

/* Read one expression */
static any read0(bool top) {
   int i;
   any x, y, *h;
   cell c1;

   if (skip('#') < 0) {
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
      if ((y = member(x = read0(NO), val(Uni))) && isCell(y))
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
      if (!testEsc())
         eofErr();
      i = 0,  Push(c1, y = box(Chr));
      while (Env.get(), Chr != '"') {
         if (!testEsc())
            eofErr();
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
   if (x = symToNum(y, (int)unDig(val(Scl)) / 2, '.', 0))
      return x;
   if (x = findHash(y, h = Intern + hash(y)))
      return x;
   if (x = anonymous(y))
      return x;
   x = consSym(Nil,y);
   *h = cons(x,*h);
   return x;
}

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

/* Read one token */
any token(any x, int c) {
   int i;
   any y, *h;
   cell c1;

   if (!Chr)
      Env.get();
   if (skip(c) < 0)
      return Nil;
   if (Chr == '"') {
      Env.get();
      if (Chr == '"') {
         Env.get();
         return Nil;
      }
      testEsc();
      i = 0,  Push(c1, y = box(Chr));
      while (Env.get(), Chr != '"' && testEsc())
         byteSym(Chr, &i, &y);
      Env.get();
      return consStr(y = Pop(c1));
   }
   if (Chr >= '0' && Chr <= '9') {
      i = 0,  Push(c1, y = box(Chr));
      while (Env.get(), Chr >= '0' && Chr <= '9' || Chr == '.')
         byteSym(Chr, &i, &y);
      return symToNum(Pop(c1), (int)unDig(val(Scl)) / 2, '.', 0);
   }
   {
      char nm[bufSize(x)];

      bufString(x, nm);
      if (Chr >= 'A' && Chr <= 'Z' || Chr == '\\' || Chr >= 'a' && Chr <= 'z' || strchr(nm,Chr)) {
         if (Chr == '\\')
            Env.get();
         i = 0,  Push(c1, y = box(Chr));
         while (Env.get(),
               Chr >= '0' && Chr <= '9' || Chr >= 'A' && Chr <= 'Z' ||
               Chr == '\\' || Chr >= 'a' && Chr <= 'z' || strchr(nm,Chr) ) {
            if (Chr == '\\')
               Env.get();
            byteSym(Chr, &i, &y);
         }
         y = Pop(c1);
         if (x = findHash(y, h = Intern + hash(y)))
            return x;
         x = consSym(Nil,y);
         *h = cons(x,*h);
         return x;
      }
   }
   y = box(c = getChar());
   Env.get();
   if (x = findHash(y, Intern + hash(y)))
      return x;
   return mkChar(c);
}

// (read ['sym1 ['sym2]]) -> any
any doRead(any ex) {
   any x, y;

   if (!isCell(x = cdr(ex)))
      x = read1(0);
   else {
      y = EVAL(car(x));
      NeedSym(ex,y);
      x = cdr(x),  x = EVAL(car(x));
      NeedSym(ex,x);
      x = token(y, symChar(name(x)));
   }
   if (InFile == stdin  &&  Chr == '\n')
      Chr = 0;
   return x;
}

long waitFd(any ex, int fd, long ms) {
   any x;
   cell c1, at;
   int i, j, m, n;
   long t;
   bool flg;
   fd_set fdSet;
   byte buf[1024];
   struct timeval *tp, tv;
#ifndef __linux__
   struct timeval tt;
#endif

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
      for (x = data(c1) = val(Run); isCell(x); x = cdr(x))
         if (isNeg(caar(x))) {
            if ((n = (int)unDig(cadar(x)) / 2) < t)
               tp = &tv,  t = n;
         }
         else {
            if ((n = (int)unDig(caar(x)) / 2) > m)
               m = n;
            FD_SET(n, &fdSet);
         }
      if (Spkr) {
         if (Spkr > m)
            m = Spkr;
         FD_SET(Spkr, &fdSet);
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
#ifndef __linux__
         gettimeofday(&tt,NULL);
         t = tt.tv_sec*1000 + tt.tv_usec/1000;
#endif
      }
      while (select(m+1, &fdSet, NULL, NULL, tp) < 0)
         if (errno != EINTR)
            err(ex, NULL, "Select error: %s", strerror(errno));
      if (tp) {
#ifdef __linux__
         t -= tv.tv_sec*1000 + tv.tv_usec/1000;
#else
         gettimeofday(&tt,NULL);
         t = tt.tv_sec*1000 + tt.tv_usec/1000 - t;
#endif
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
      if (!flg  &&  Spkr  &&  FD_ISSET(Spkr, &fdSet)  &&
               rdBytes(Spkr, (byte*)&m, sizeof(int))  &&  Pipe[m] >= 0  &&
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
               Push(at,val(At)),  val(At) = caar(x);
               prog(cddar(x));
               val(At) = Pop(at);
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
            Push(at,val(At)),  val(At) = caar(x);
            prog(cdar(x));
            val(At) = Pop(at);
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
         return prog(x);
   return y;
}

// (sync) -> flg
any doSync(any ex) {
   if (!Mic || !Hear)
      return Nil;
   if (write(Mic, &Slot, sizeof(int)) != sizeof(int))
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
      char nm[pathSize(x)];

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
      x = cdr(x),  prTell(y = EVAL(car(x)));
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

   fflush_unlocked(stdout);
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

// (skip ['sym]) -> sym
any doSkip(any ex) {
   any x;

   x = cdr(ex),  x = EVAL(car(x));
   NeedSym(ex,x);
   return skip(symChar(name(x)))<0? Nil : mkChar(Chr);
}

// (eof ['flg]) -> flg
any doEof(any x) {
   x = cdr(x);
   if (!isNil(EVAL(car(x)))) {
      Chr = -1;
      return T;
   }
   if (!Chr)
      Env.get();
   return Chr < 0? T : Nil;
}

// (from 'any ..) -> sym
any doFrom(any ex) {
   any x;
   int res, i, j, ac = length(x = cdr(ex)), p[ac];
   cell c[ac];
   char *av[ac];

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
      char buf[bufSize(x)];

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

static inline bool eol(void) {
   if (Chr < 0)
      return YES;
   if (Chr == '\n') {
      Chr = 0;
      return YES;
   }
   if (Chr == '\r') {
      Env.get();
      if (Chr == '\n')
         Chr = 0;
      return YES;
   }
   return NO;
}

// (line 'flg ['cnt ..]) -> lst|sym
any doLine(any ex) {
   any x, y, z;
   bool pack;
   int i, n;
   cell c1;

   if (!Chr)
      Env.get();
   if (eol())
      return Nil;
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
            if (Env.get(), eol()) {
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
         if (Env.get(), eol())
            return Pop(c1);
         y = cdr(y) = cons(
            pack? boxChar(getChar(), &i, &z) : (z = cons(mkChar(getChar()), Nil)),
            Nil );
      }
   }
   for (;;) {
      if (Env.get(), eol())
         return pack? consStr(Pop(c1)) : Pop(c1);
      if (pack)
         charSym(getChar(), &i, &z);
      else
         y = cdr(y) = cons(mkChar(getChar()), Nil);
   }
}

// (lines 'any ..) -> cnt
any doLines(any ex) {
   any x, y;
   int c, cnt = 0;
   FILE *fp;

   for (x = cdr(ex); isCell(x); x = cdr(x)) {
      y = evSym(x);
      {
         char nm[pathSize(y)];

         pathString(y, nm);
         if (!(fp = fopen(nm, "r")))
            openErr(ex, nm);
         while ((c = getc_unlocked(fp)) >= 0)
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
      StrI = 0,  data(StrCell) = StrP = box(c & 0xFF);
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
            Env.put(pr), space(), fflush_unlocked(OutFile);
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
         outString("-> "),  fflush_unlocked(OutFile),  print(x),  crlf();
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
      if ((y = EVAL(car(x))) != T)
         y = load(ex, '>', y);
      else
         while (*AV  &&  strcmp(*AV,"-") != 0)
            y = load(ex, '>', mkStr(*AV++));
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

// (pipe exe) -> cnt
// (pipe exe . prg) -> any
any doPipe(any ex) {
   any x;
   inFrame f;
   int pfd[2];

   if (pipe(pfd) < 0)
      err(ex, NULL, "Can't pipe");
   if ((f.pid = forkLisp(ex)) == 0) {
      if (isCell(cddr(ex)))
         setpgid(0,0);
      close(pfd[0]);
      if (pfd[1] != STDOUT_FILENO)
         dup2(pfd[1], STDOUT_FILENO),  close(pfd[1]);
      EVAL(cadr(ex));
      bye(0);
   }
   close(pfd[1]);
   if (!isCell(cddr(ex)))
      return boxCnt(pfd[0]);
   if (!(f.fp = fdopen(pfd[0], "r")))
      openErr(ex, "Read pipe");
   setpgid(f.pid,0);
   pushInFiles(&f);
   x = prog(cddr(ex));
   popInFiles();
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
      char nm[pathSize(x)];

      pathString(x, nm);
      if ((fd = open(nm, O_CREAT|O_RDWR, 0666)) >= 0)
         return boxCnt(fd);
   }
   return Nil;
}

// (close 'cnt) -> flg
any doClose(any ex) {
   return close((int)evCnt(ex, cdr(ex)))? Nil : T;
}

// (echo ['cnt ['cnt]] | ['sym ..]) -> sym
any doEcho(any ex) {
   any x, y;
   long cnt;

   x = cdr(ex),  y = EVAL(car(x));
   if (isNil(y) && !isCell(cdr(x))) {
      if (Env.get != getStdin || Env.put != putStdout) {
         if (!Chr)
            Env.get();
         while (Chr >= 0)
            Env.put(Chr),  Env.get();
      }
      else {
         int n, dst = fileno_unlocked(OutFile);
         byte buf[BUFSIZ];

         fflush_unlocked(OutFile);
         if (Chr) {
            buf[0] = (byte)Chr;
            if (!wrBytes(dst,buf,1))
               return Nil;
            Chr = 0;
         }
         while ((n = fread_unlocked(buf, 1, sizeof(buf), InFile)) > 0)
            if (!wrBytes(dst, buf, n))
               return Nil;
      }
      return T;
   }
   if (isSym(y)) {
      int res, m, n, i, j, ac = length(x), p[ac], om, op;
      cell c[ac];
      char *av[ac];

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
void putStdout(int c) {putc_unlocked(c & 0xFF, OutFile);}

void crlf(void) {Env.put('\n');}
void space(void) {Env.put(' ');}

void outWord(word n) {
   if (n > 9)
      outWord(n / 10);
   Env.put('0' + n % 10);
}

void outString(char *s) {
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
      else if (isNil(val(Tsm)) || Env.put != putStdout || !isatty(fileno_unlocked(OutFile)))
         Env.put('"'),  outStr(c),  Env.put('"');
      else {
         outName(car(val(Tsm)));
         outStr(symByte(name(x)));
         outName(cdr(val(Tsm)));
      }
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

// (space ['cnt]) -> cnt
any doSpace(any ex) {
   any x;
   int n;

   if (isNil(x = EVAL(cadr(ex)))) {
      Env.put(' ');
      return One;
   }
   for (n = xCnt(ex,x); n > 0; --n)
      Env.put(' ');
   return x;
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
   return fflush_unlocked(OutFile)? Nil : T;
}

// (rewind) -> flg
any doRewind(any ex __attribute__((unused))) {
   return fseek(OutFile, 0L, SEEK_SET) || ftruncate(fileno_unlocked(OutFile), 0)? Nil : T;
}

// (rd ['sym]) -> any
// (rd 'cnt) -> num | NIL
any doRd(any x) {
   long cnt;
   cell c1;

   x = cdr(x);
   if (!isNum(x = EVAL(car(x)))) {
      BinIx = BinCnt = 0,  getBin = getBinary;
      return binRead() ?: x;
   }
   if ((cnt = unBox(x)) < 0) {
      byte buf[cnt = -cnt];

      if (!rdBytes(fileno_unlocked(InFile), buf, cnt))  // Little Endian
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

      if (!rdBytes(fileno_unlocked(InFile), buf, cnt))
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
      putc_unlocked(unDig(y = EVAL(car(x))) / 2 & 0xFF, OutFile);
   while (isCell(x = cdr(x)));
   return y;
}

static void putChar(int c) {putchar_unlocked(c & 0xFF);}

// (rpc 'sym ['any ..]) -> flg
any doRpc(any x) {
   any y;

   x = cdr(x),  y = EVAL(car(x));
   putBin = putChar,  putBin(BEG),  binPrint(y);
   while (isCell(x = cdr(x)))
      y = EVAL(car(x)),  putBin = putChar,  binPrint(y);
   putBin(END);
   return fflush_unlocked(stdout)? Nil : T;
}

/*** DB-I/O ***/
#define BLKSIZE 64  // DB block unit size
#define BLK 6
#define TAGMASK (BLKSIZE-1)
#define BLKMASK (~TAGMASK)

typedef long long adr;

static int F, Files, *BlkShift, *BlkFile, *BlkSize, MaxBlkSize;
static FILE *Journal;
static adr BlkIndex, BlkLink;
static word2 *Marks;
static byte *Locks, *Ptr, **Mark;
static byte *Block, *IniBlk;  // 01 00 00 00 00 00 NIL 0

static adr getAdr(byte *p) {
   return (adr)p[0] | (adr)p[1]<<8 | (adr)p[2]<<16 |
                           (adr)p[3]<<24 | (adr)p[4]<<32 | (adr)p[5]<<40;
}

static void setAdr(adr n, byte *p) {
   p[0] = (byte)n,  p[1] = (byte)(n >> 8),  p[2] = (byte)(n >> 16);
   p[3] = (byte)(n >> 24),  p[4] = (byte)(n >> 32),  p[5] = (byte)(n >> 40);
}

static void jnlErr(void) {err(NULL, NULL, "Bad Journal");}

static any new64(word2 n, any x) {
   int c, i;
   word2 w = 0;

   do {
      if ((c = n & 0x3F) > 11)
         c += 5;
      if (c > 42)
         c += 6;
      w = w << 8 | c + '0';
   } while (n >>= 6);
   if (i = F) {
      ++i;
      w = w << 8 | '-';
      do {
         if ((c = i & 0x3F) > 11)
            c += 5;
         if (c > 42)
            c += 6;
         w = w << 8 | c + '0';
      } while (i >>= 6);
   }
   return hi(w)? consNum(num(w), consNum(hi(w), x)) :  consNum(num(w), x);
}

static word2 blk64(any x) {
   int c;
   word2 w;
   word2 n = 0;

   F = 0;
   if (isNum(x)) {
      w = unDig(x);
      if (isNum(x = cdr(numCell(x))))
         w |= (word2)unDig(x) << 32;
      do {
         if ((c = w & 0xFF) == '-')
            F = n-1,  n = 0;
         else {
            if ((c -= '0') > 42)
               c -= 6;
            if (c > 11)
               c -= 5;
            n = n << 6 | c;
         }
      } while (w >>= 8);
   }
   return n;
}

/* DB Record Locking */
static void dbLock(int cmd, int typ, int f, off_t len) {
   struct flock fl;

   fl.l_type = typ;
   fl.l_whence = SEEK_SET;
   fl.l_start = 0;
   fl.l_len = len;
   while (fcntl(BlkFile[f], cmd, &fl) < 0  &&  typ != F_UNLCK)
      if (errno != EINTR)
         lockErr();
}

static inline void rdLock(void) {
   if (val(Solo) != T)
      dbLock(F_SETLKW, F_RDLCK, 0, 1);
}

static inline void wrLock(void) {
   if (val(Solo) != T)
      dbLock(F_SETLKW, F_WRLCK, 0, 1);
}

static inline void rwUnlock(off_t len) {
   if (val(Solo) != T) {
      if (len == 0) {
         int f;

         for (f = 1; f < Files; ++f)
            if (Locks[f])
               dbLock(F_SETLK, F_UNLCK, f, 0),  Locks[f] = 0;
         val(Solo) = Zero;
      }
      dbLock(F_SETLK, F_UNLCK, 0, len);
   }
}

static pid_t tryLock(off_t n, off_t len) {
   struct flock fl;

   for (;;) {
      fl.l_type = F_WRLCK;
      fl.l_whence = SEEK_SET;
      fl.l_start = n;
      fl.l_len = len;
      if (fcntl(BlkFile[F], F_SETLK, &fl) >= 0) {
         Locks[F] = 1;
         if (!n)
            val(Solo) = T;
         else if (val(Solo) != T)
            val(Solo) = Nil;
         return 0;
      }
      if (errno != EINTR  &&  errno != EACCES  &&  errno != EAGAIN)
         lockErr();
      fl.l_type = F_WRLCK;  //??
      fl.l_whence = SEEK_SET;
      fl.l_start = n;
      fl.l_len = len;
      while (fcntl(BlkFile[F], F_GETLK, &fl) < 0)
         if (errno != EINTR)
            lockErr();
      if (fl.l_type != F_UNLCK)
         return fl.l_pid;
   }
}

static void blkPeek(off_t pos, void *buf, int siz) {
   while (pread(BlkFile[F], buf, siz, pos) != (ssize_t)siz)
      if (errno != EINTR)
         dbErr("read");
}

static void blkPoke(off_t pos, void *buf, int siz) {
   while (pwrite(BlkFile[F], buf, siz, pos) != (ssize_t)siz)
      if (errno != EINTR)
         dbErr("write");
   if (Journal) {
      byte a[BLK];

      putc_unlocked(siz == BlkSize[F]? BLKSIZE : siz, Journal);
      a[0] = (byte)F,  a[1] = (byte)(F >> 8),  fwrite_unlocked(a, 2, 1, Journal);
      setAdr(pos >> BlkShift[F], a),  fwrite_unlocked(a, BLK, 1, Journal);
      fwrite_unlocked(buf, siz, 1, Journal);
   }
}

static void rdBlock(adr n) {
   blkPeek((BlkIndex = n) << BlkShift[F], Block, BlkSize[F]);
   BlkLink = getAdr(Block) & BLKMASK;
   Ptr = Block + BLK;
}

static void wrBlock(void) {blkPoke(BlkIndex << BlkShift[F], Block, BlkSize[F]);}

static adr newBlock(void) {
   adr n;
   byte buf[2*BLK];

   blkPeek(0, buf, 2*BLK);  // Get Free, Next
   setAdr(0, IniBlk);
   if (n = getAdr(buf)) {
      blkPeek(n << BlkShift[F], buf, BLK);  // Get free link
      blkPoke(0, buf, 2*BLK);
      blkPoke(n << BlkShift[F], IniBlk, BlkSize[F]);
   }
   else if ((n = getAdr(buf+BLK)) < 281474976710592LL) {
      setAdr(n + BLKSIZE, buf+BLK);  // Increment next
      blkPoke(n << BlkShift[F], IniBlk, BlkSize[F]);
      blkPoke(0, buf, 2*BLK);
   }
   else
      err(NULL, NULL, "DB Oversize");
   return n;
}

any newId(int i) {
   adr n;

   if ((F = i-1) >= Files)
      dbfErr();
   wrLock();
   if (Journal)
      lockFile(fileno_unlocked(Journal), F_SETLKW, F_WRLCK);
   n = newBlock();
   if (Journal)
      fflush_unlocked(Journal),  lockFile(fileno_unlocked(Journal), F_SETLK, F_UNLCK);
   rwUnlock(1);
   return new64(n/BLKSIZE, At2);  // dirty
}

bool isLife(any x) {
   adr n;
   byte buf[2*BLK];

   if ((n = blk64(name(x))*BLKSIZE)  &&  F < Files) {
      for (x = tail(x); !isSym(x); x = cdr(cellPtr(x)));
      if (x == At || x == At2)
         return YES;
      if (x != At3) {
         blkPeek(0, buf, 2*BLK);  // Get Next
         if (n < getAdr(buf+BLK)) {
            blkPeek(n << BlkShift[F], buf, BLK);
            if ((getAdr(buf) & TAGMASK) == 1)
               return YES;
         }
      }
   }
   return NO;
}

static void cleanUp(adr n) {
   adr p, fr;
   byte buf[BLK];

   blkPeek(0, buf, BLK),  fr = getAdr(buf);  // Get Free
   setAdr(n, buf),  blkPoke(0, buf, BLK);    // Set new
   do {
      p = n;
      blkPeek(p << BlkShift[F], buf, BLK),  n = getAdr(buf);  // Get block link
      n &= BLKMASK;  // Clear Tag
      setAdr(n, buf),  blkPoke(p << BlkShift[F], buf, BLK);
   } while (n);
   if (fr)
      setAdr(fr, buf),  blkPoke(p << BlkShift[F], buf, BLK);  // Append old free list
}

static int getBlock(int n __attribute__((unused))) {
   if (Ptr == Block+BlkSize[F]) {
      if (!BlkLink)
         return 0;
      rdBlock(BlkLink);
   }
   return *Ptr++;
}

static void putBlock(int c) {
   if (Ptr == Block+BlkSize[F]) {
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

// (pool ['sym1 ['lst] ['sym2]]) -> flg
any doPool(any ex) {
   any x, db;
   byte buf[2*BLK+1];

   val(Solo) = Zero;
   if (Files) {
      while (isNil(doRollback(Nil)));
      for (F = 0; F < Files; ++F) {
         if (Marks)
            free(Mark[F]);
         if (close(BlkFile[F]) < 0)
            closeErr("DB");
      }
      free(Mark), Mark = NULL, free(Marks), Marks = NULL;
      Files = 0;
   }
   if (Journal)
      fclose(Journal),  Journal = NULL;
   x = cdr(ex),  db = EVAL(car(x));
   NeedSym(ex,db);
   if (!isNil(db)) {
      x = cddr(ex),  x = EVAL(car(x));
      NeedLst(ex,x);
      Files = length(x) ?: 1;
      BlkShift = alloc(BlkShift, Files * sizeof(int));
      BlkFile = alloc(BlkFile, Files * sizeof(int));
      BlkSize = alloc(BlkSize, Files * sizeof(int));
      Locks = alloc(Locks, Files),  memset(Locks, 0, Files);
      MaxBlkSize = 0;
      for (F = 0; F < Files; ++F) {
         char nm[pathSize(db) + 8];

         pathString(db, nm);
         if (isCell(x))
            sprintf(nm + strlen(nm), "%d", F+1);
         BlkShift[F] = isNum(car(x))? (int)unDig(car(x))/2 : 2;
         if ((BlkFile[F] = open(nm, O_RDWR)) >= 0) {
            blkPeek(0, buf, 2*BLK+1);  // Get block shift
            BlkSize[F] = BLKSIZE << (BlkShift[F] = (int)buf[2*BLK]);
         }
         else {
            if (errno != ENOENT  ||
                     (BlkFile[F] = open(nm, O_CREAT|O_EXCL|O_RDWR, 0666)) < 0) {
               Files = 0;
               return Nil;
            }
            BlkSize[F] = BLKSIZE << BlkShift[F];
            setAdr(0, buf);  // Free
            if (F)
               setAdr(BLKSIZE, buf+BLK);  // Next
            else {
               byte blk[BlkSize[0]];

               setAdr(2*BLKSIZE, buf+BLK);  // Next
               memset(blk, 0, BlkSize[0]);
               setAdr(1, blk),  blkPoke(BlkSize[0], blk, BlkSize[0]);
            }
            buf[2*BLK] = (byte)BlkShift[F];
            blkPoke(0, buf, 2*BLK+1);
         }
         if (BlkSize[F] > MaxBlkSize)
            MaxBlkSize = BlkSize[F];
         x = cdr(x);
      }
      Block = alloc(Block, MaxBlkSize);
      IniBlk = alloc(IniBlk, MaxBlkSize);
      memset(IniBlk, 0, MaxBlkSize);
      x = cdddr(ex),  x = EVAL(car(x));
      NeedSym(ex,x);
      if (!isNil(x)) {
         char nm[pathSize(x)];

         pathString(x, nm);
         if (!(Journal = fopen(nm, "a")))
            openErr(ex, nm);
      }
   }
   return T;
}

// (journal) -> T
any doJournal(any ex __attribute__((unused))) {
   int siz;
   byte a[BLK], buf[MaxBlkSize];

   while ((siz = getc_unlocked(InFile)) >= 0) {
      if (fread_unlocked(a, 2, 1, InFile) != 1)
         jnlErr();
      if ((F = a[0] | a[1]<<8) >= Files)
         dbfErr();
      if (siz == BLKSIZE)
         siz = BlkSize[F];
      if (fread_unlocked(a, BLK, 1, InFile) != 1 || fread_unlocked(buf, siz, 1, InFile) != 1)
         jnlErr();
      blkPoke(getAdr(a) << BlkShift[F], buf, siz);
   }
   return T;
}

static any mkId(word2 n) {
   any x, y, *h;

   x = new64(n, Nil);
   if (y = findHash(x, h = Extern + hash(x)))
      return y;
   y = extSym(consSym(Nil,x));
   *h = cons(y,*h);
   return y;
}

// (id 'num 'num) -> sym
// (id 'sym [NIL]) -> num
// (id 'sym T) -> (num . num)
any doId(any ex) {
   any x, y;
   word2 n;
   cell c1;

   x = cdr(ex);
   if (isNum(y = EVAL(car(x)))) {
      F = unBox(y) - 1;
      x = cdr(x),  y = EVAL(car(x));
      NeedNum(ex,y);
      n = (word2)unDig(y);
      if (isNum(y = cdr(numCell(y))))
         n = n << 32 + unDig(y);
      return mkId(n / 2);
   }
   NeedExt(ex,y);
   n = blk64(name(y));
   x = cdr(x);
   if (isNil(EVAL(car(x))))
      return boxWord2(n);
   Push(c1, boxWord2(n));
   data(c1) = cons(box((F + 1) * 2), data(c1));
   return Pop(c1);
}

// (seq 'cnt|sym1 ['sym2 ['num]]) -> sym | num | NIL
any doSeq(any ex) {
   adr n, n2, free, p, next;
   any x, y;
   byte buf[2*BLK];

   x = cdr(ex);
   if (isNum(y = EVAL(car(x)))) {
      if ((F = (int)unDig(y)/2 - 1) >= Files)
         dbfErr();
      n = 0;
   }
   else {
      NeedExt(ex,y);
      if ((n = blk64(name(y))*BLKSIZE) == 0)
         return Nil;
   }
   if (x = cdr(x),  isExt(y = EVAL(car(x)))) {
      n2 = blk64(name(y))*BLKSIZE;
      x = cdr(x),  free = blk64(EVAL(car(x)));
      while ((n += BLKSIZE) < n2) {
         if (free) {
            setAdr(n, buf),  blkPoke(free << BlkShift[F], buf, BLK);
            setAdr(0, buf),  blkPoke(n << BlkShift[F], buf, BLK);  // Set new Free tail
         }
         else {
            blkPeek(0, buf, BLK); // Get Free
            blkPoke(n << BlkShift[F], buf, BLK); // Write Free|0
            setAdr(n, buf),  blkPoke(0, buf, BLK);  // Set new Free
         }
         free = n;
      }
      setAdr(1, IniBlk),  blkPoke(n << BlkShift[F], IniBlk, BlkSize[F]);
      blkPeek(0, buf, 2*BLK),  next = getAdr(buf+BLK);  // Get Next
      if (n >= next)
         setAdr(n+BLKSIZE, buf+BLK),  blkPoke(0, buf, 2*BLK);  // Set new Next
      return new64(free,Nil);
   }
   blkPeek(0, buf, 2*BLK),  next = getAdr(buf+BLK);  // Get Next
   while ((n += BLKSIZE) < next) {
      blkPeek(n << BlkShift[F], buf, BLK),  p = getAdr(buf);
      if ((p & TAGMASK) == 1)
         return mkId(n/BLKSIZE);
   }
   return Nil;
}

// (lieu 'any) -> sym | NIL
any doLieu(any x) {
   any y;

   x = cdr(x);
   if (!isExt(x = EVAL(car(x))))
      return Nil;
   for (y = tail(x); !isSym(y); y = cdr(cellPtr(y)));
   return y == At || y == At2? x : Nil;
}

// (lock ['sym]) -> cnt | NIL
any doLock(any ex) {
   any x;
   pid_t n;
   off_t blk;

   x = cdr(ex);
   if (isNil(x = EVAL(car(x))))
      F = 0,  n = tryLock(0,0);
   else {
      NeedExt(ex,x);
      blk = blk64(name(x));
      if (F >= Files)
         dbfErr();
      n = tryLock(blk * BlkSize[F], 1);
   }
   return n? boxCnt(n) : Nil;
}

static int binSize(any x) {
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

int dbSize(any ex, any x) {
   int n;

   db(ex,x,1);
   n = BLK + 1 + binSize(val(x));
   for (x = tail(x);  isCell(x);  x = cdr(x)) {
      if (isSym(car(x)))
         n += binSize(car(x)) + 2;
      else
         n += binSize(cdar(x)) + binSize(caar(x));
   }
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
         for (y = tail(car(x)); isCell(y); y = cdr(y));
         y = numCell(y);
         while (isNum(cdr(y)))
            y = numCell(cdr(y));
         if (!isSym(z = cdr(y)))
            z = car(z);
         if (z == At2  ||  z == At3) {  // dirty or deleted
            cell c1, c2;

            Push(c1, cdr(y));
            Push(c2, car(x));
            cdr(y) = cons(z, cons(val(car(x)), Nil)),  y = cddr(y);
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

// (commit ['any] [exe1] [exe2]) -> flg
any doCommit(any ex) {
   bool force, note;
   int i;
   any flg, x, y, z;
   ptr pbSave, ppSave;
   byte buf[PIPE_BUF];

   x = cdr(ex),  flg = EVAL(car(x));
   force = !Transactions || !isNil(flg);
   wrLock();
   if (Journal)
      lockFile(fileno_unlocked(Journal), F_SETLKW, F_WRLCK);
   protect(YES);
   x = cddr(ex),  EVAL(car(x));
   if (note = Tell && !isNil(flg) && flg != T)
      tellBeg(&pbSave, &ppSave, buf),  prTell(flg);
   for (i = 0; i < HASH; ++i) {
      for (x = Extern[i];  isCell(x);  x = cdr(x)) {
         for (y = tail(car(x)); isCell(y); y = cdr(y));
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
                  if (PipePtr >= PipeBuf + PIPE_BUF - 12) {  // EXTERN <2+1+7> END
                     tellEnd(&pbSave, &ppSave);
                     tellBeg(&pbSave, &ppSave, buf),  prTell(flg);
                  }
                  prTell(car(x));
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
                  if (PipePtr >= PipeBuf + PIPE_BUF - 12) {  // EXTERN <2+1+7> END
                     tellEnd(&pbSave, &ppSave);
                     tellBeg(&pbSave, &ppSave, buf),  prTell(flg);
                  }
                  prTell(car(x));
               }
            }
         }
      }
   }
   if (note)
      tellEnd(&pbSave, &ppSave);
   if (Journal)
      fflush_unlocked(Journal),  lockFile(fileno_unlocked(Journal), F_SETLK, F_UNLCK);
   x = cdddr(ex),  EVAL(car(x));
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
         for (y = tail(car(x)); isCell(y); y = cdr(y));
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

// (mark 'sym|0 [NIL | T | 0]) -> flg
any doMark(any ex) {
   any x, y;
   word2 n, m;
   int b;
   byte *p;

   x = cdr(ex);
   if (isNum(y = EVAL(car(x)))) {
      if (Marks) {
         for (F = 0; F < Files; ++F)
            free(Mark[F]);
         free(Mark), Mark = NULL, free(Marks), Marks = NULL;
      }
      return Nil;
   }
   NeedSym(ex,y);
   if (!(n = blk64(name(y))))
      return Nil;
   if (!Marks) {
      Marks = alloc(Marks, Files * sizeof(word2));
      memset(Marks, 0, Files * sizeof(word2));
      Mark = alloc(Mark, Files * sizeof(byte*));
      memset(Mark, 0, Files * sizeof(byte*));
   }
   b = 1 << (n & 7);
   if ((n >>= 3) >= Marks[F]) {
      m = Marks[F],  Marks[F] = n + 1;
      Mark[F] = alloc(Mark[F], Marks[F]);
      memset(Mark[F] + m, 0, Marks[F] - m);
   }
   p = Mark[F] + n;
   x = cdr(x);
   y = *p & b? T : Nil;  // Old value
   if (!isNil(x = EVAL(car(x)))) {
      if (isNum(x))
         *p &= ~b;  // Clear mark
      else
         *p |= b;  // Set mark
   }
   return y;
}

// (free 'cnt) -> (sym . lst)
any doFree(any x) {
   byte buf[2*BLK];
   cell c1;

   if ((F = (int)evCnt(x, cdr(x)) - 1) >= Files)
      dbfErr();
   rdLock();
   blkPeek(0, buf, 2*BLK);  // Get Free, Next
   Push(c1, x = cons(mkId(getAdr(buf+BLK)/BLKSIZE), Nil));  // Next
   BlkLink = getAdr(buf);  // Free
   while (BlkLink) {
      x = cdr(x) = cons(mkId(BlkLink/BLKSIZE), Nil);
      rdBlock(BlkLink);
   }
   rwUnlock(1);
   return Pop(c1);
}

// (dbck ['cnt] 'flg) -> any
any doDbck(any x) {
   any y;
   bool flg;
   int i;
   adr next, p, cnt;
   word2 blks, syms;
   byte buf[2*BLK];
   cell c1;

   F = 0;
   x = cdr(x);
   if (isNum(y = EVAL(car(x)))) {
      if ((F = (int)unDig(y)/2 - 1) >= Files)
         dbfErr();
      x = cdr(x),  y = EVAL(car(x));
   }
   flg = !isNil(y);
   cnt = BLKSIZE;
   blks = syms = 0;
   blkPeek(0, buf, 2*BLK);  // Get Free, Next
   BlkLink = getAdr(buf);
   next = getAdr(buf+BLK);
   if (Journal)
      lockFile(fileno_unlocked(Journal), F_SETLKW, F_WRLCK);
   protect(YES);
   while (BlkLink) {  // Check free list
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
   if (Journal)
      fflush_unlocked(Journal),  lockFile(fileno_unlocked(Journal), F_SETLK, F_UNLCK);
   protect(NO);
   if (cnt != next)
      return mkStr("Bad count");
   if (!flg)
      return Nil;
   Push(c1, boxWord2(syms));
   data(c1) = cons(boxWord2(blks), data(c1));
   return Pop(c1);
}
