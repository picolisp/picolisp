/* 30dec08abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

#ifdef __CYGWIN__
#include <sys/file.h>
#define fcntl(fd,cmd,fl) 0
#endif

static any read0(bool);

// I/O Tokens
enum {NIX, BEG, DOT, END};
enum {NUMBER, INTERN, TRANSIENT, EXTERN};

static char Delim[] = " \t\n\r\"'()[]`~";
static int StrI;
static cell StrCell, *StrP;
static bool Sync;
static byte *PipeBuf, *PipePtr;
static void (*PutSave)(int);
static int Transactions;
static byte TBuf[] = {INTERN+4, 'T'};

static void openErr(any ex, char *s) {err(ex, NULL, "%s open: %s", s, strerror(errno));}
static void closeErr(char *s) {err(NULL, NULL, "%s close: %s", s, strerror(errno));}
static void eofErr(void) {err(NULL, NULL, "EOF Overrun");}
static void utfErr(void) {err(NULL, NULL, "Bad UTF-8");}
static void badFd(any ex, any x) {err(ex, x, "Bad FD");}
static void lockErr(void) {err(NULL, NULL, "File lock: %s", strerror(errno));}
static void writeErr(char *s) {err(NULL, NULL, "%s write: %s", s, strerror(errno));}
static void dbErr(char *s) {err(NULL, NULL, "DB %s: %s", s, strerror(errno));}
static void dbfErr(any ex) {err(ex, NULL, "Bad DB file");}

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

void closeOnExec(any ex, int fd) {
   if (fcntl(fd, F_SETFD, FD_CLOEXEC) < 0)
      err(ex, NULL, "SETFD %s", strerror(errno));
}

void blocking(bool flg, any ex, int fd) {
   int n;

   if ((n = fcntl(fd, F_GETFL, 0)) < 0)
      err(ex, NULL, "GETFL %s", strerror(errno));
   if (flg)
      n &= ~O_NONBLOCK;
   else
      n |= O_NONBLOCK;
   if (fcntl(fd, F_SETFL, n) < 0)
      err(ex, NULL, "SETFL %s", strerror(errno));
}

static inline bool inReady(int fd) {
   int i;
   inFile *p;

   return (i=fd-3) >= 0  &&  i < InFDs  &&  (p=InFiles[i])  &&  p->ix < p->cnt;
}

void initInFile(int fd, char *nm) {
   int n;
   inFile *p;

   if ((n = fd - 3) >= InFDs) {
      int i = InFDs;

      InFiles = alloc(InFiles, (InFDs = n + 1) * sizeof(inFile*));
      do
         InFiles[i] = NULL;
      while (++i < InFDs);
   }
   p = InFiles[n] = alloc(InFiles[n], sizeof(inFile));
   p->fd = fd;
   p->ix = p->cnt = p->next = 0;
   p->line = p->src = 1;
   p->name = nm;
}

void initOutFile(int fd) {
   int n;
   outFile *p;

   if ((n = fd - 3) >= OutFDs) {
      int i = OutFDs;

      OutFiles = alloc(OutFiles, (OutFDs = n + 1) * sizeof(outFile*));
      do
         OutFiles[i] = NULL;
      while (++i < OutFDs);
   }
   p = OutFiles[n] = alloc(OutFiles[n], sizeof(outFile));
   p->fd = fd;
   p->ix = 0;
}

void closeInFile(int fd) {
   int i;
   inFile *p;

   if ((i = fd-3) < InFDs && (p = InFiles[i]))
      free(p->name),  free(p),  InFiles[i] = NULL;
}

void closeOutFile(int fd) {
   int i;

   if ((i = fd-3) < OutFDs)
      free(OutFiles[i]),  OutFiles[i] = NULL;
}

int slow(int fd, byte *p, int cnt) {
   int n;

   while ((n = read(fd, p, cnt)) < 0) {
      if (errno != EINTR)
         return 0;
      if (Signal)
         sighandler(T);
   }
   return n;
}

bool rdBytes(int fd, byte *p, int cnt) {
   int n;

   do {
      while ((n = read(fd, p, cnt)) <= 0) {
         if (!n || errno != EINTR)
            return NO;
         if (Signal)
            sighandler(T);
      }
   } while (p += n,  cnt -= n);
   return YES;
}

bool wrBytes(int fd, byte *p, int cnt) {
   int n;

   do {
      if ((n = write(fd, p, cnt)) >= 0)
         p += n, cnt -= n;
      else if (errno == EBADF || errno == EPIPE || errno == ECONNRESET)
         return NO;
      else if (errno != EINTR)
         writeErr("bytes");
      if (Signal)
         sighandler(T);
   } while (cnt);
   return YES;
}

static void wrChild(int i, byte *p, int cnt) {
   int n;

   if (Child[i].cnt == 0) {
      for (;;) {
         if ((n = write(Child[i].tell, p, cnt)) >= 0) {
            p += n;
            if ((cnt -= n) == 0)
               return;
         }
         else if (errno == EAGAIN)
            break;
         else if (errno == EPIPE || errno == ECONNRESET) {
            Child[i].pid = 0;
            close(Child[i].hear),  close(Child[i].tell);
            free(Child[i].buf);
            return;
         }
         else if (errno != EINTR)
            writeErr("child");
      }
   }
   n = Child[i].cnt;
   Child[i].buf = alloc(Child[i].buf, n + sizeof(int) + cnt);
   *(int*)(Child[i].buf + n) = cnt;
   memcpy(Child[i].buf + n + sizeof(int), p, cnt);
   Child[i].cnt += sizeof(int) + cnt;
}

bool flush(outFile *p) {
   int n;

   if (!p)
      return !fflush(StdOut);
   if (n = p->ix) {
      p->ix = 0;
      return wrBytes(p->fd, p->buf, n);
   }
   return YES;
}

void flushAll(void) {
   int i;

   fflush(stdout);
   fflush(stderr);
   for (i = 0; i < OutFDs; ++i)
      if (OutFiles[i])
         flush(OutFiles[i]);
}

/*** Low level I/O ***/
static int getBinary(void) {
   if (InFile->ix == InFile->cnt) {
      InFile->ix = InFile->cnt = 0;
      if (!(InFile->cnt = slow(InFile->fd, InFile->buf, BUFSIZ)))
         return -1;
   }
   return InFile->buf[InFile->ix++];
}

static any rdNum(int cnt) {
   int n, i;
   any x;
   cell c1;

   if ((n = getBin()) < 0)
      return NULL;
   i = 0,  Push(c1, x = box(n));
   if (--cnt == 62) {
      do {
         if ((n = getBin()) < 0)
            return NULL;
         byteSym(n, &i, &x);
      } while (--cnt);
      for (;;) {
         if ((cnt = getBin()) < 0)
            return NULL;
         if (cnt != 255)
            break;
         do {
            if ((n = getBin()) < 0)
               return NULL;
            byteSym(n, &i, &x);
         } while (--cnt);
      }
   }
   while (--cnt >= 0) {
      if ((n = getBin()) < 0)
         return NULL;
      byteSym(n, &i, &x);
   }
   return Pop(c1);
}

any binRead(int extn) {
   int c;
   any x, y, *h;
   cell c1;

   if ((c = getBin()) < 0)
      return NULL;
   if ((c & ~3) == 0) {
      if (c == NIX)
         return Nil;
      if (c == BEG) {
         if ((x = binRead(extn)) == NULL)
            return NULL;
         Push(c1, x = cons(x,Nil));
         while ((y = binRead(extn)) != (any)END) {
            if (y == NULL) {
               drop(c1);
               return NULL;
            }
            if (y == (any)DOT) {
               if ((y = binRead(extn)) == NULL) {
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
      return (any)(long)c;  // NIX, DOT or END
   }
   if ((y = rdNum(c / 4)) == NULL)
      return NULL;
   if ((c &= 3) == NUMBER)
      return y;
   if (c == TRANSIENT)
      return consStr(y);
   if (c == EXTERN) {
      if (extn)
         y = extOffs(extn, y);
      if (x = findHash(y, h = Extern + hash(y)))
         return x;
      mkExt(x = consSym(Nil,y));
      *h = cons(x,*h);
      return x;
   }
   if (x = findHash(y, h = Intern + hash(y)))
      return x;
   x = consSym(Nil,y);
   *h = cons(x,*h);
   return x;
}

static void prDig(int t, word n) {
   int i = 1;
   word m = MASK;

   while (n & (m <<= 8))
      ++i;
   putBin(i*4+t);
   while (putBin(n), --i)
      n >>= 8;
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

void binPrint(int extn, any x) {
   any y;

   if (isNum(x))
      prNum(NUMBER, x);
   else if (isNil(x))
      putBin(NIX);
   else if (isSym(x)) {
      if (!isNum(y = name(x)))
         binPrint(extn, y);
      else if (!isExt(x))
         prNum(hashed(x, hash(y), Intern)? INTERN : TRANSIENT, y);
      else {
         if (extn)
            y = extOffs(-extn, y);
         prNum(EXTERN, y);
      }
   }
   else {
      y = x;
      putBin(BEG);
      while (binPrint(extn, car(x)), !isNil(x = cdr(x))) {
         if (x == y) {
            putBin(DOT);
            break;
         }
         if (!isCell(x)) {
            putBin(DOT);
            binPrint(extn, x);
            return;
         }
      }
      putBin(END);
   }
}

void pr(int extn, any x) {putBin = putStdout,  binPrint(extn, x);}
void prn(long n) {putBin = putStdout,  prDig(0, n >= 0? n * 2 : -n * 2 + 1);}

/* Family IPC */
static void putTell(int c) {
   *PipePtr++ = c;
   if (PipePtr == PipeBuf + PIPE_BUF - 1)  // END
      err(NULL, NULL, "Tell PIPE_BUF");
}

static void tellBeg(ptr *pb, ptr *pp, ptr buf) {
   *pb = PipeBuf,  *pp = PipePtr;
   PipePtr = (PipeBuf = buf) + sizeof(int);
   *PipePtr++ = BEG;
}

static void prTell(any x) {putBin = putTell,  binPrint(0, x);}

static void tellEnd(ptr *pb, ptr *pp) {
   int i, n;

   *PipePtr++ = END;
   *(int*)PipeBuf = n = PipePtr - PipeBuf - sizeof(int);
   if (Tell && !wrBytes(Tell, PipeBuf, n+sizeof(int)))
      close(Tell),  Tell = 0;
   for (i = 0; i < Children; ++i)
      if (Child[i].pid)
         wrChild(i, PipeBuf+sizeof(int), n);
   PipePtr = *pp,  PipeBuf = *pb;
}

static any rdHear(void) {
   any x;
   inFile *iSave = InFile;

   InFile = InFiles[Hear-3];
   getBin = getBinary;
   x = binRead(0);
   InFile = iSave;
   return x;
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
      if (!isNum(cdr(numCell(x))))
         return 0;
      n = unDig(x = cdr(numCell(x)));
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
   word n, m = MASK;

   for (cnt = 1;  isNum(cdr(numCell(x)));  cnt += WORD)
      x = cdr(numCell(x));
   for (n = unDig(x); n & (m <<= 8); ++cnt);
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
   if ((*i += 8) < BITS)
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
      return OutFile? OutFile->fd : STDOUT_FILENO;
   if (!Env.outFiles)
      return InFile? InFile->fd : STDIN_FILENO;
   return labs((char*)Env.outFiles - p) > labs((char*)Env.inFiles - p)?
      (InFile? InFile->fd : STDIN_FILENO) : (OutFile? OutFile->fd : STDOUT_FILENO);
}

void rdOpen(any ex, any x, inFrame *f) {
   if (isNil(x))
      f->pid = -1,  f->fd = STDIN_FILENO;
   else if (isNum(x)) {
      int n = (int)unBox(x);

      if (n < 0) {
         inFrame *g = Env.inFiles;

         for (;;) {
            if (!(g = g->link))
               break;
            if (!++n) {
               n = g->fd;
               break;
            }
         }
      }
      if ((f->fd = n) <= 2) {
         f->pid = -1;
         if (n < 0)
            badFd(ex,x);
      }
      else {
         f->pid = 0;
         if ((n -= 3) >= InFDs || !InFiles[n])
            badFd(ex,x);
      }
   }
   else if (isSym(x)) {
      char nm[pathSize(x)];

      f->pid = 1;
      pathString(x,nm);
      if (nm[0] == '+') {
         while ((f->fd = open(nm+1, O_APPEND|O_CREAT|O_RDWR, 0666)) < 0) {
            if (errno != EINTR)
               openErr(ex, nm);
            if (Signal)
               sighandler(ex);
         }
         initInFile(f->fd, strdup(nm+1));
      }
      else {
         while ((f->fd = open(nm, O_RDONLY)) < 0) {
            if (errno != EINTR)
               openErr(ex, nm);
            if (Signal)
               sighandler(ex);
         }
         initInFile(f->fd, strdup(nm));
      }
      closeOnExec(ex, f->fd);
   }
   else {
      any y;
      int i, pfd[2], ac = length(x);
      char *av[ac+1];

      if (pipe(pfd) < 0)
         pipeError(ex, "read open");
      closeOnExec(ex, pfd[0]), closeOnExec(ex, pfd[1]);
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
      initInFile(f->fd = pfd[0], NULL);
   }
}

void wrOpen(any ex, any x, outFrame *f) {
   if (isNil(x))
      f->pid = -1,  f->fd = STDOUT_FILENO;
   else if (isNum(x)) {
      int n = (int)unBox(x);

      if (n < 0) {
         outFrame *g = Env.outFiles;

         for (;;) {
            if (!(g = g->link))
               break;
            if (!++n) {
               n = g->fd;
               break;
            }
         }
      }
      if ((f->fd = n) <= 2) {
         f->pid = -1;
         if (n < 0)
            badFd(ex,x);
      }
      else {
         f->pid = 0;
         if ((n -= 3) >= OutFDs || !OutFiles[n])
            badFd(ex,x);
      }
   }
   else if (isSym(x)) {
      char nm[pathSize(x)];

      f->pid = 1;
      pathString(x,nm);
      if (nm[0] == '+') {
         while ((f->fd = open(nm+1, O_APPEND|O_CREAT|O_WRONLY, 0666)) < 0) {
            if (errno != EINTR)
               openErr(ex, nm);
            if (Signal)
               sighandler(ex);
         }
      }
      else {
         while ((f->fd = open(nm, O_CREAT|O_TRUNC|O_WRONLY, 0666)) < 0) {
            if (errno != EINTR)
               openErr(ex, nm);
            if (Signal)
               sighandler(ex);
         }
      }
      closeOnExec(ex, f->fd);
      initOutFile(f->fd);
   }
   else {
      any y;
      int i, pfd[2], ac = length(x);
      char *av[ac+1];

      if (pipe(pfd) < 0)
         pipeError(ex, "write open");
      closeOnExec(ex, pfd[0]), closeOnExec(ex, pfd[1]);
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
      initOutFile(f->fd = pfd[1]);
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
         while ((f->fd = open(nm+1, O_CREAT|O_RDWR, 0666)) < 0) {
            if (errno != EINTR)
               openErr(ex, nm);
            if (Signal)
               sighandler(ex);
         }
         lockFile(f->fd, F_SETLKW, F_RDLCK);
      }
      else {
         while ((f->fd = open(nm, O_CREAT|O_RDWR, 0666)) < 0) {
            if (errno != EINTR)
               openErr(ex, nm);
            if (Signal)
               sighandler(ex);
         }
         lockFile(f->fd, F_SETLKW, F_WRLCK);
      }
      closeOnExec(ex, f->fd);
   }
}

/*** Reading ***/
void getStdin(void) {
   if (InFile) {
      if (InFile->ix == InFile->cnt) {
         InFile->ix = InFile->cnt = 0;
         if (!(InFile->cnt = slow(InFile->fd, InFile->buf, BUFSIZ))) {
            Chr = -1;
            return;
         }
      }
      if ((Chr = InFile->buf[InFile->ix++]) == '\n')
         ++InFile->line;
   }
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
   if (InFile)
      InFile->next = Chr;
   else
      Next0 = Chr;
   if (f->pid < 0)
      InFile = NULL,  Chr = Next0;
   else if (InFile = InFiles[f->fd - 3])
      Chr = InFile->next;
   else
      Chr = Next0;
   f->get = Env.get,  Env.get = getStdin;
   f->link = Env.inFiles,  Env.inFiles = f;
}

void pushOutFiles(outFrame *f) {
   if (f->pid < 0)
      OutFile = NULL,  StdOut = f->fd == 2? stderr : stdout;
   else
      OutFile = OutFiles[f->fd - 3];
   f->put = Env.put,  Env.put = putStdout;
   f->link = Env.outFiles,  Env.outFiles = f;
}

void pushCtlFiles(ctlFrame *f) {
   f->link = Env.ctlFiles,  Env.ctlFiles = f;
}

void popInFiles(void) {
   if (Env.inFiles->pid > 0) {
      close(Env.inFiles->fd),  closeInFile(Env.inFiles->fd);
      if (Env.inFiles->pid > 1)
         while (waitpid(Env.inFiles->pid, NULL, 0) < 0) {
            if (errno != EINTR)
               closeErr("Read pipe");
            if (Signal)
               sighandler(T);
         }
   }
   Env.get = Env.inFiles->get;
   if (!(Env.inFiles = Env.inFiles->link) || Env.inFiles->pid < 0)
      InFile = NULL,  Chr = Next0;
   else if (InFile = InFiles[Env.inFiles->fd - 3])
      Chr = InFile->next;
   else
      Chr = Next0;
}

void popOutFiles(void) {
   flush(OutFile);
   if (Env.outFiles->pid > 0) {
      close(Env.outFiles->fd),  closeOutFile(Env.outFiles->fd);
      if (Env.outFiles->pid > 1)
         while (waitpid(Env.outFiles->pid, NULL, 0) < 0) {
            if (errno != EINTR)
               closeErr("Write pipe");
            if (Signal)
               sighandler(T);
         }
   }
   Env.put = Env.outFiles->put;
   if (!(Env.outFiles = Env.outFiles->link))
      OutFile = NULL,  StdOut = stdout;
   else if (Env.outFiles->pid >= 0)
      OutFile = OutFiles[Env.outFiles->fd - 3];
   else
      OutFile = NULL,  StdOut = Env.outFiles->fd == 2? stderr : stdout;
}

void popCtlFiles(void) {
   if (Env.ctlFiles->fd >= 0)
      close(Env.ctlFiles->fd);
   else
      lockFile(currFd(NULL, (char*)Env.ctlFiles), F_SETLK, F_UNLCK);
   Env.ctlFiles = Env.ctlFiles->link;
}

/* Get full char from input channel */
int getChar(void) {
   int c;

   if ((c = Chr) == 0xFF)
      return TOP;
   if (c & 0x80) {
      if ((c & 0x40) == 0)
         utfErr();
      Env.get();
      if ((c & 0x20) == 0)
         c &= 0x1F;
      else {
         if (c & 0x10 || (Chr & 0xC0) != 0x80)
            utfErr();
         c = (c & 0xF) << 6 | Chr & 0x3F,  Env.get();
      }
      if (Chr < 0)
         eofErr();
      if ((Chr & 0xC0) != 0x80)
         utfErr();
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
   cell c1;

   Env.get();
   for (;;) {
      if (skip('#') == ')') {
         Env.get();
         return Nil;
      }
      if (Chr == ']')
         return Nil;
      if (Chr != '~') {
         Push(c1, x = cons(read0(NO),Nil));
         break;
      }
      Env.get();
      Push(c1, read0(NO));
      if (isCell(x = data(c1) = EVAL(data(c1)))) {
         while (isCell(cdr(x)))
            x = cdr(x);
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
         cdr(x) = read0(NO);
         cdr(x) = EVAL(cdr(x));
         while (isCell(cdr(x)))
            x = cdr(x);
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
         return symPtr((any)n);
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
   if (top && InFile)
      InFile->src = InFile->line;
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
      Push(c1, x = read0(NO));
      if (isCell(y = idx(Uni, data(c1), 1)))
         x = car(y);
      drop(c1);
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
      mkExt(x = consSym(Nil,y));
      *h = cons(x,*h);
      return x;
   }
   if (strchr(Delim, Chr))
      err(NULL, NULL, "Bad input '%c' (%d)", isprint(Chr)? Chr:'?', Chr);
   if (Chr == '\\')
      Env.get();
   i = 0,  Push(c1, y = box(Chr));
   for (;;) {
      Env.get();
      if (Chr <= 0 || strchr(Delim, Chr))
         break;
      if (Chr == '\\')
         Env.get();
      byteSym(Chr, &i, &y);
   }
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
   while (Chr > 0  &&  strchr(" \t)]", Chr))
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
      return NULL;
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
   any x;

   if (!isCell(x = cdr(ex)))
      x = read1(0);
   else {
      cell c1;

      Push(c1, EVAL(car(x)));
      NeedSym(ex, data(c1));
      x = cdr(x),  x = EVAL(car(x));
      NeedSym(ex,x);
      x = token(data(c1), symChar(name(x))) ?: Nil;
      drop(c1);
   }
   if (!InFile  &&  Chr == '\n')
      Chr = 0;
   return x;
}

long waitFd(any ex, int fd, long ms) {
   any x;
   cell c1, c2;
   int i, j, m, n;
   long t;
   bool flg;
   fd_set rdSet, wrSet;
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
      FD_ZERO(&rdSet);
      FD_ZERO(&wrSet);
      m = 0;
      if (fd >= 0) {
         if (inReady(fd))
            tp = &tv,  t = 0;
         else
            FD_SET(m = fd, &rdSet);
      }
      if (Hear) {
         if (inReady(Hear))
            tp = &tv,  t = 0;
         else {
            FD_SET(Hear, &rdSet);
            if (Hear > m)
               m = Hear;
         }
      }
      for (x = data(c1) = val(Run); isCell(x); x = cdr(x)) {
         if (isNeg(caar(x))) {
            if ((n = (int)unDig(cadar(x)) / 2) < t)
               tp = &tv,  t = n;
         }
         else if (inReady(n = (int)unDig(caar(x)) / 2))
            tp = &tv,  t = 0;
         else {
            FD_SET(n, &rdSet);
            if (n > m)
               m = n;
         }
      }
      if (Spkr) {
         FD_SET(Spkr, &rdSet);
         if (Spkr > m)
            m = Spkr;
      }
      for (i = 0; i < Children; ++i) {
         if (Child[i].pid) {
            FD_SET(Child[i].hear, &rdSet);
            if (Child[i].hear > m)
               m = Child[i].hear;
            if (Child[i].cnt) {
               FD_SET(Child[i].tell, &wrSet);
               if (Child[i].tell > m)
                  m = Child[i].tell;
            }
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
      while (select(m+1, &rdSet, &wrSet, NULL, tp) < 0) {
         if (errno != EINTR) {
            val(Run) = Nil;
            err(ex, NULL, "Select error: %s", strerror(errno));
         }
         if (Signal)
            sighandler(ex);
      }
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
      for (flg = NO, i = 0; i < Children; ++i) {
         if (Child[i].pid) {
            if (FD_ISSET(Child[i].hear, &rdSet)) {
               static byte *buf;

               if (!buf)
                  buf = alloc(NULL, PIPE_BUF - sizeof(int));
               if (rdBytes(Child[i].hear, (byte*)&n, sizeof(int)) && rdBytes(Child[i].hear, buf, n)) {
                  flg = YES;
                  for (j = 0; j < Children; ++j)
                     if (j != i  &&  Child[j].pid)
                        wrChild(j, buf, n);
               }
               else {
                  Child[i].pid = 0;
                  close(Child[i].hear),  close(Child[i].tell);
                  free(Child[i].buf);
                  continue;
               }
            }
            if (FD_ISSET(Child[i].tell, &wrSet)) {
               n = *(int*)(Child[i].buf + Child[i].ofs);
               if (wrBytes(Child[i].tell, Child[i].buf + Child[i].ofs + sizeof(int), n)) {
                  Child[i].ofs += sizeof(int) + n;
                  if (2 * Child[i].ofs >= Child[i].cnt) {
                     if (Child[i].cnt -= Child[i].ofs) {
                        memcpy(Child[i].buf, Child[i].buf + Child[i].ofs, Child[i].cnt);
                        Child[i].buf = alloc(Child[i].buf, Child[i].cnt);
                     }
                     Child[i].ofs = 0;
                  }
               }
               else {
                  Child[i].pid = 0;
                  close(Child[i].hear),  close(Child[i].tell);
                  free(Child[i].buf);
               }
            }
         }
      }
      if (!flg && Spkr && FD_ISSET(Spkr,&rdSet) && rdBytes(Spkr,(byte*)&m,sizeof(int)) && Child[m].pid)
         wrChild(m, TBuf, sizeof(TBuf));
      for (x = data(c1); isCell(x); x = cdr(x))
         if (isNeg(caar(x))) {
            if ((n = (int)(unDig(cadar(x)) / 2 - t)) > 0)
               setDig(cadar(x), (long)2*n);
            else {
               setDig(cadar(x), unDig(caar(x)));
               Push(c2,val(At)),  val(At) = caar(x);
               prog(cddar(x));
               val(At) = Pop(c2);
            }
         }
      if (Hear  &&  (inReady(Hear) || FD_ISSET(Hear, &rdSet))) {
         if ((data(c2) = rdHear()) == NULL)
            close(Hear),  closeInFile(Hear),  Hear = 0;
         else if (data(c2) == T)
            Sync = YES;
         else {
            Save(c2);
            evList(data(c2));
            drop(c2);
         }
         FD_SET(Hear, &rdSet);
      }
      for (x = data(c1); isCell(x); x = cdr(x))
         if (!isNeg(caar(x)) &&  (inReady(n = (int)unDig(caar(x))/2) || FD_ISSET(n, &rdSet))) {
            Push(c2,val(At)),  val(At) = caar(x);
            prog(cdar(x));
            val(At) = Pop(c2);
            FD_SET(n, &rdSet);
         }
      if (Signal)
         sighandler(ex);
   } while (ms  &&  fd >= 0 && !inReady(fd) && !FD_ISSET(fd, &rdSet));
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
   byte *p;
   int n, cnt;

   if (!Mic || !Hear)
      return Nil;
   p = (byte*)&Slot;
   cnt = sizeof(int);
   do {
      if ((n = write(Mic, p, cnt)) < 0) {
         if (errno != EINTR)
            writeErr("sync");
         if (Signal)
            sighandler(ex);
      }
      p += n;
   } while (cnt -= n);
   Sync = NO;
   do
      waitFd(ex, Hear, -1);
   while (!Sync);
   return T;
}

// (hear 'num|sym) -> any
any doHear(any ex) {
   any x;
   int i, fd;

   x = cdr(ex),  x = EVAL(car(x));
   NeedAtom(ex,x);
   if (Hear)
      close(Hear),  closeInFile(Hear),  Hear = 0;
   if (isNum(x)) {
      i = (fd = (int)xCnt(ex,x)) - 3;
      if (i < 0 || i >= InFDs || !InFiles[i])
         badFd(ex,x);
      Hear = fd;
   }
   else {
      char nm[pathSize(x)];

      pathString(x, nm);
      while ((fd = open(nm, O_RDONLY)) < 0) {
         if (errno != EINTR)
            openErr(ex, nm);
         if (Signal)
            sighandler(ex);
      }
      closeOnExec(ex, fd);
      initInFile(Hear = fd, strdup(nm));
   }
   return x;
}

// (tell 'sym ['any ..]) -> any
any doTell(any x) {
   any y;
   ptr pbSave, ppSave;
   byte buf[PIPE_BUF];

   if (!Tell && !Children)
      return Nil;
   tellBeg(&pbSave, &ppSave, buf);
   do
      x = cdr(x),  prTell(y = EVAL(car(x)));
   while (isCell(cdr(x)));
   tellEnd(&pbSave, &ppSave);
   return y;
}

// (poll 'cnt) -> cnt | NIL
any doPoll(any ex) {
   any x;
   int fd;
   fd_set fdSet;
   struct timeval tv;

   x = cdr(ex),  x = EVAL(car(x));
   if (inReady(fd = (int)xCnt(ex,x)))
      return x;
   FD_ZERO(&fdSet);
   FD_SET(fd, &fdSet);
   tv.tv_sec = tv.tv_usec = 0;
   while (select(fd+1, &fdSet, NULL, NULL, &tv) < 0)
      if (errno != EINTR)
         err(ex, NULL, "Poll error: %s", strerror(errno));
   return FD_ISSET(fd, &fdSet)? x : Nil;
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

// (eol) -> flg
any doEol(any ex __attribute__((unused))) {
   return InFile && Chr=='\n' || Chr<=0? T : Nil;
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

bool eol(void) {
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

static any parse(any x, bool skp, any s) {
   int c;
   parseFrame *save, parser;
   void (*getSave)(void);
   cell c1;

   save = Env.parser;
   Env.parser = &parser;
   parser.dig = unDig(parser.name = name(x));
   parser.eof = s? 0xFF : 0xFF5D0A;
   getSave = Env.get,  Env.get = getParse,  c = Chr,  Chr = 0;
   Push(c1, Env.parser->name);
   if (skp)
      getParse();
   if (!s)
      x = rdList();
   else {
      any y;
      cell c2;

      if (!(x = token(s,0)))
         return Nil;
      Push(c2, y = cons(x,Nil));
      while (x = token(s,0))
         y = cdr(y) = cons(x,Nil);
      x = Pop(c2);
   }
   drop(c1);
   Chr = c,  Env.get = getSave,  Env.parser = save;
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

      save = Env.parser;
      Env.parser = &parser;
      parser.dig = unDig(parser.name = name(x));
      parser.eof = 0xFF20;
      getSave = Env.get,  Env.get = getParse,  c = Chr,  Chr = 0;
      Push(c1, Env.parser->name);
      getParse();
      x = read0(YES);
      drop(c1);
      Chr = c,  Env.get = getSave,  Env.parser = save;
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

// (str 'sym ['sym1]) -> lst
// (str 'lst) -> sym
any doStr(any ex) {
   any x;
   cell c1, c2;

   x = cdr(ex);
   if (isNil(x = EVAL(car(x))))
      return Nil;
   if (isSym(x)) {
      if (!isCell(cddr(ex)))
         return parse(x, NO, NULL);
      Push(c1, x);
      Push(c2, evSym(cddr(ex)));
      x = parse(x, NO, data(c2));
      drop(c1);
      return x;
   }
   NeedCell(ex,x);
   begString();
   Push(c1,x);
   print(car(x));
   while (isCell(x = cdr(x)))
      space(),  print(car(x));
   return endString();
}

any load(any ex, int pr, any x) {
   cell c1, c2;
   inFrame f;

   if (isSym(x) && firstByte(x) == '-') {
      Push(c1, parse(x, YES, NULL));
      x = evList(data(c1));
      drop(c1);
      return x;
   }
   rdOpen(ex, x, &f);
   doHide(Nil);
   pushInFiles(&f);
   x = Nil;
   for (;;) {
      if (InFile)
         data(c1) = read1(0);
      else {
         if (pr && !Chr)
            Env.put(pr), space(), flush(OutFile);
         data(c1) = read1('\n');
         if (Chr == '\n')
            Chr = 0;
      }
      if (isNil(data(c1)))
         break;
      Save(c1);
      if (InFile || Chr || !pr)
         x = EVAL(data(c1));
      else {
         Push(c2, val(At));
         x = val(At) = EVAL(data(c1));
         val(At3) = val(At2),  val(At2) = data(c2);
         outString("-> "),  flush(OutFile),  print(x),  newline();
      }
      drop(c1);
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
         y = loadAll(ex,y);
   } while (isCell(x = cdr(x)));
   return y;
}

// (in 'any . prg) -> any
any doIn(any ex) {
   any x;
   inFrame f;

   x = cdr(ex),  x = EVAL(car(x));
   rdOpen(ex, x, &f);
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
   wrOpen(ex, x, &f);
   pushOutFiles(&f);
   x = prog(cddr(ex));
   popOutFiles();
   return x;
}

// (pipe exe) -> cnt
// (pipe exe . prg) -> any
any doPipe(any ex) {
   any x;
   union {
      inFrame in;
      outFrame out;
   } f;
   int pfd[2];

   if (pipe(pfd) < 0)
      err(ex, NULL, "Can't pipe");
   closeOnExec(ex, pfd[0]), closeOnExec(ex, pfd[1]);
   if ((f.in.pid = forkLisp(ex)) == 0) {
      if (isCell(cddr(ex)))
         setpgid(0,0);
      close(pfd[0]);
      if (pfd[1] != STDOUT_FILENO)
         dup2(pfd[1], STDOUT_FILENO),  close(pfd[1]);
      wrOpen(ex, Nil, &f.out);
      pushOutFiles(&f.out);
      EVAL(cadr(ex));
      bye(0);
   }
   close(pfd[1]);
   if (f.in.pid < 0)
      err(ex, NULL, "fork");
   if (!isCell(cddr(ex))) {
      initInFile(pfd[0], NULL);
      return boxCnt(pfd[0]);
   }
   initInFile(f.in.fd = pfd[0], NULL);
   setpgid(f.in.pid,0);
   pushInFiles(&f.in);
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
      while ((fd = open(nm, O_CREAT|O_RDWR, 0666)) < 0) {
         if (errno != EINTR)
            return Nil;
         if (Signal)
            sighandler(ex);
      }
      closeOnExec(ex, fd);
      initInFile(fd, strdup(nm)), initOutFile(fd);
      return boxCnt(fd);
   }
}

// (close 'cnt) -> cnt | NIL
any doClose(any ex) {
   any x;
   int fd;

   x = cdr(ex),  x = EVAL(car(x));
   if (close(fd = (int)xCnt(ex,x)))
      return Nil;
   closeInFile(fd),  closeOutFile(fd);
   return x;
}

// (echo ['cnt ['cnt]] | ['sym ..]) -> sym
any doEcho(any ex) {
   any x, y;
   long cnt;

   x = cdr(ex),  y = EVAL(car(x));
   if (!Chr)
      Env.get();
   if (isNil(y) && !isCell(cdr(x))) {
      while (Chr >= 0)
         Env.put(Chr),  Env.get();
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
   if (isCell(x = cdr(x))) {
      for (cnt = xCnt(ex,y), y = EVAL(car(x)); --cnt >= 0; Env.get())
         if (Chr < 0)
            return Nil;
   }
   for (cnt = xCnt(ex,y); --cnt >= 0; Env.get()) {
      if (Chr < 0)
         return Nil;
      Env.put(Chr);
   }
   return T;
}

/*** Prining ***/
void putStdout(int c) {
   if (!OutFile)
      putc_unlocked(c, StdOut);
   else {
      if (OutFile->ix == BUFSIZ) {
         OutFile->ix = 0;
         wrBytes(OutFile->fd, OutFile->buf, BUFSIZ);
      }
      OutFile->buf[OutFile->ix++] = c;
   }
}

void newline(void) {Env.put('\n');}
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

void outName(any s) {outSym(symByte(name(s)));}

void outNum(any x) {
   if (isNum(cdr(numCell(x))))
      outName(numToSym(x, 0, 0, 0));
   else {
      char *p, buf[BITS/2];

      sprintf(p = buf, "%ld", unBox(x));
      do
         Env.put(*p++);
      while (*p);
   }
}

/* Print one expression */
void print(any x) {
   if (Signal)
      sighandler(T);
   if (isNum(x))
      outNum(x);
   else if (isNil(x))
      outString("NIL");
   else if (isSym(x)) {
      int c;

      if (!(c = symByte(name(x))))
         Env.put('$'),  outWord(num(x)/sizeof(cell));
      else if (isExt(x))
         Env.put('{'),  outSym(c),  Env.put('}');
      else if (hashed(x, hash(name(x)), Intern)) {
         do {
            if (strchr(Delim, c))
               Env.put('\\');
            Env.put(c);
         } while (c = symByte(NULL));
      }
      else {
         Env.put('"');
         do {
            if (c == '"'  ||  c == '^'  ||  c == '\\')
               Env.put('\\');
            else if (c == 127)
               Env.put('^'),  c = '?';
            else if (c < ' ')
               Env.put('^'),  c |= 0x40;
            Env.put(c);
         } while (c = symByte(NULL));
         Env.put('"');
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
      }
      Env.put(')');
      drop(c1);
   }
}

void prin(any x) {
   if (Signal)
      sighandler(T);
   if (!isNil(x)) {
      if (isNum(x))
         outNum(x);
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
   newline();
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
   newline();
   return y;
}

// (flush) -> flg
any doFlush(any ex __attribute__((unused))) {
   return flush(OutFile)? T : Nil;
}

// (rewind) -> flg
any doRewind(any ex __attribute__((unused))) {
   if (!OutFile)
      return fseek(StdOut, 0L, SEEK_SET) || ftruncate(fileno(StdOut), 0)? Nil : T;
   OutFile->ix = 0;
   return lseek(OutFile->fd, 0L, SEEK_SET) || ftruncate(OutFile->fd, 0)? Nil : T;
}

// (ext 'cnt . prg) -> any
any doExt(any ex) {
   int extn;
   any x;

   x = cdr(ex);
   extn = ExtN,  ExtN = (int)evCnt(ex,x);
   x = prog(cddr(ex));
   ExtN = extn;
   return x;
}

// (rd ['sym]) -> any
// (rd 'cnt) -> num | NIL
any doRd(any x) {
   int i, j;
   long cnt;
   word n;
   cell c1;

   x = cdr(x),  x = EVAL(car(x));
   if (!InFile)
      return Nil;
   if (!isNum(x)) {
      getBin = getBinary;
      return binRead(ExtN) ?: x;
   }
   if ((cnt = unBox(x)) < 0) {
      byte buf[cnt = -cnt];

      if (!rdBytes(InFile->fd, buf, cnt))  // Little Endian
         return Nil;
      if (cnt % sizeof(word) == 0)
         Push(c1, Nil);
      else {
         n = buf[--cnt];

         while (cnt % sizeof(word))
            n = n << 8 | buf[--cnt];
         Push(c1, box(n));
      }
      while ((cnt -= WORD) >= 0) {
         n = buf[cnt + WORD-1];
         i = WORD-2;
         do
            n = n << 8 | buf[cnt + i];
         while (--i >= 0);
         data(c1) = consNum(n, data(c1));
      }
   }
   else {
      byte buf[cnt];

      if (!rdBytes(InFile->fd, buf, cnt))
         return Nil;
      if (cnt % sizeof(word) == 0) {
         i = 0;
         Push(c1, Nil);
      }
      else {
         n = buf[0];

         for (i = 1;  i < (int)(cnt % sizeof(word));  ++i)
            n = n << 8 | buf[i];
         Push(c1, box(n));
      }
      while (i < cnt) {
         n = buf[i++];
         j = 1;
         do
            n = n << 8 | buf[i++];
         while (++j < WORD);
         data(c1) = consNum(n, data(c1));
      }
   }
   zapZero(data(c1));
   digMul2(data(c1));
   return Pop(c1);
}

// (pr 'any ..) -> any
any doPr(any x) {
   any y;

   x = cdr(x),  pr(ExtN, y = EVAL(car(x)));
   while (isCell(x = cdr(x)))
      pr(ExtN, y = EVAL(car(x)));
   return y;
}

// (wr 'num ..) -> num
any doWr(any x) {
   any y;

   x = cdr(x);
   do
      putStdout(unDig(y = EVAL(car(x))) / 2);
   while (isCell(x = cdr(x)));
   return y;
}

static void putChar(int c) {putchar_unlocked(c);}

// (rpc 'sym ['any ..]) -> flg
any doRpc(any x) {
   any y;

   x = cdr(x),  y = EVAL(car(x));
   putBin = putChar,  putBin(BEG),  binPrint(ExtN, y);
   while (isCell(x = cdr(x)))
      y = EVAL(car(x)),  putBin = putChar,  binPrint(ExtN, y);
   putBin(END);
   return fflush(stdout)? Nil : T;
}

/*** DB-I/O ***/
#define BLKSIZE 64  // DB block unit size
#define BLK 6
#define TAGMASK (BLKSIZE-1)
#define BLKMASK (~TAGMASK)

static int F, Files, *BlkShift, *BlkFile, *BlkSize, MaxBlkSize;
static FILE *Journal, *Log;
static adr BlkIndex, BlkLink;
static adr *Marks;
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
static void fsyncErr(any ex, char *s) {err(ex, NULL, "%s fsync error: %s", s, strerror(errno));}
static void ignLog(void) {fprintf(stderr, "Discarding incomplete transaction.\n");}

any new64(adr n, any x) {
   int c, i;
   adr w = 0;

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

adr blk64(any x) {
   int c;
   adr n, w;

   F = 0;
   n = 0;
   if (isNum(x)) {
      w = unDig(x);
      if (isNum(x = cdr(numCell(x))))
         w |= (adr)unDig(x) << BITS;
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

any extOffs(int offs, any x) {
   adr n = blk64(x);

   if ((F += offs) < 0)
      err(NULL, NULL, "%d: Bad DB offset", F);
   return new64(n, Nil);
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
      a[0] = (byte)F,  a[1] = (byte)(F >> 8),  fwrite(a, 2, 1, Journal);
      setAdr(pos >> BlkShift[F], a),  fwrite(a, BLK, 1, Journal);
      fwrite(buf, siz, 1, Journal);
   }
}

static void rdBlock(adr n) {
   blkPeek((BlkIndex = n) << BlkShift[F], Block, BlkSize[F]);
   BlkLink = getAdr(Block) & BLKMASK;
   Ptr = Block + BLK;
}

static void logBlock(void) {
   byte a[BLK];

   a[0] = (byte)F,  a[1] = (byte)(F >> 8),  fwrite(a, 2, 1, Log);
   setAdr(BlkIndex, a),  fwrite(a, BLK, 1, Log);
   fwrite(Block, BlkSize[F], 1, Log);
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

any newId(any ex, int i) {
   adr n;

   if ((F = i-1) >= Files)
      dbfErr(ex);
   wrLock();
   if (Journal)
      lockFile(fileno(Journal), F_SETLKW, F_WRLCK);
   if (!Log)
      ++Env.protect;
   n = newBlock();
   if (Journal)
      fflush(Journal),  lockFile(fileno(Journal), F_SETLK, F_UNLCK);
   if (!Log)
      --Env.protect;
   rwUnlock(1);
   return new64(n/BLKSIZE, At2);  // dirty
}

bool isLife(any x) {
   int i;
   adr n;
   byte buf[2*BLK];

   if (n = blk64(name(x))*BLKSIZE) {
      if (F < Files) {
         for (x = tail1(x); !isSym(x); x = cdr(cellPtr(x)));
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
      else {
         F -= Files-1;
         for (x = val(Ext); isCell(x); x = cdr(x)) {
            if ((i = unBox(caar(x))) >= F)
               return YES;
            F -= i;
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

static int getBlock(void) {
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

// Test for existing transaction
static bool transaction(void) {
   byte a[BLK];

   fseek(Log, 0L, SEEK_SET);
   if (fread(a, 2, 1, Log) == 0) {
      if (!feof(Log))
         ignLog();
      return NO;
   }
   for (;;) {
      if (a[0] == 0xFF && a[1] == 0xFF)
         return YES;
      if ((F = a[0] | a[1]<<8) >= Files  ||
            fread(a, BLK, 1, Log) != 1  ||
            fseek(Log, BlkSize[F], SEEK_CUR) != 0  ||
            fread(a, 2, 1, Log) != 1 ) {
         ignLog();
         return NO;
      }
   }
}

static void restore(any ex) {
   byte dirty[Files], a[BLK], buf[MaxBlkSize];

   fseek(Log, 0L, SEEK_SET);
   for (F = 0; F < Files; ++F)
      dirty[F] = 0;
   for (;;) {
      if (fread(a, 2, 1, Log) == 0)
         jnlErr();
      if (a[0] == 0xFF && a[1] == 0xFF)
         break;
      if ((F = a[0] | a[1]<<8) >= Files  ||
            fread(a, BLK, 1, Log) != 1  ||
            fread(buf, BlkSize[F], 1, Log) != 1 )
         jnlErr();
      while (pwrite(BlkFile[F], buf, BlkSize[F], getAdr(a) << BlkShift[F]) != (ssize_t)BlkSize[F])
         if (errno != EINTR)
            dbErr("write");
      dirty[F] = 1;
   }
   for (F = 0; F < Files; ++F)
      if (dirty[F] && fsync(BlkFile[F]) < 0)
         fsyncErr(ex, "DB");
}

// (pool ['sym1 ['lst] ['sym2] ['sym3]]) -> flg
any doPool(any ex) {
   any x;
   byte buf[2*BLK+1];
   cell c1, c2, c3, c4;

   x = cdr(ex),  Push(c1, EVAL(car(x)));  // db
   NeedSym(ex,data(c1));
   x = cdr(x),  Push(c2, EVAL(car(x)));  // lst
   NeedLst(ex,data(c2));
   Push(c3, evSym(cdr(x)));  // sym2
   Push(c4, evSym(cddr(x)));  // sym3
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
   if (Log)
      fclose(Log),  Log = NULL;
   if (!isNil(data(c1))) {
      x = data(c2);
      Files = length(x) ?: 1;
      BlkShift = alloc(BlkShift, Files * sizeof(int));
      BlkFile = alloc(BlkFile, Files * sizeof(int));
      BlkSize = alloc(BlkSize, Files * sizeof(int));
      Locks = alloc(Locks, Files),  memset(Locks, 0, Files);
      MaxBlkSize = 0;
      for (F = 0; F < Files; ++F) {
         char nm[pathSize(data(c1)) + 8];

         pathString(data(c1), nm);
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
               drop(c1);
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
         closeOnExec(ex, BlkFile[F]);
         if (BlkSize[F] > MaxBlkSize)
            MaxBlkSize = BlkSize[F];
         x = cdr(x);
      }
      Block = alloc(Block, MaxBlkSize);
      IniBlk = alloc(IniBlk, MaxBlkSize);
      memset(IniBlk, 0, MaxBlkSize);
      if (!isNil(data(c3))) {
         char nm[pathSize(data(c3))];

         pathString(data(c3), nm);
         if (!(Journal = fopen(nm, "a")))
            openErr(ex, nm);
         closeOnExec(ex, fileno(Journal));
      }
      if (!isNil(data(c4))) {
         char nm[pathSize(data(c4))];

         pathString(data(c4), nm);
         if (!(Log = fopen(nm, "a+")))
            openErr(ex, nm);
         if (transaction()) {
            fprintf(stderr, "Last transaction not completed: Rollback\n");
            restore(ex);
         }
         fseek(Log, 0L, SEEK_SET);
         closeOnExec(ex, fileno(Log));
         ftruncate(fileno(Log), 0);
      }
   }
   drop(c1);
   return T;
}

// (journal 'any ..) -> T
any doJournal(any ex) {
   any x, y;
   int siz;
   FILE *fp;
   byte a[BLK], buf[MaxBlkSize];

   for (x = cdr(ex); isCell(x); x = cdr(x)) {
      y = evSym(x);
      {
         char nm[pathSize(y)];

         pathString(y, nm);
         if (!(fp = fopen(nm, "r")))
            openErr(ex, nm);
         while ((siz = getc_unlocked(fp)) >= 0) {
            if (fread(a, 2, 1, fp) != 1)
               jnlErr();
            if ((F = a[0] | a[1]<<8) >= Files)
               dbfErr(ex);
            if (siz == BLKSIZE)
               siz = BlkSize[F];
            if (fread(a, BLK, 1, fp) != 1 || fread(buf, siz, 1, fp) != 1)
               jnlErr();
            blkPoke(getAdr(a) << BlkShift[F], buf, siz);
         }
         fclose(fp);
      }
   }
   return T;
}

static any mkId(adr n) {
   any x, y, *h;

   x = new64(n, Nil);
   if (y = findHash(x, h = Extern + hash(x)))
      return y;
   mkExt(y = consSym(Nil,x));
   *h = cons(y,*h);
   return y;
}

// (id 'num 'num) -> sym
// (id 'sym [NIL]) -> num
// (id 'sym T) -> (num . num)
any doId(any ex) {
   any x, y;
   adr n;
   cell c1;

   x = cdr(ex);
   if (isNum(y = EVAL(car(x)))) {
      F = unBox(y) - 1;
      x = cdr(x),  y = EVAL(car(x));
      NeedNum(ex,y);
      return mkId(unBoxWord2(y));
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
         dbfErr(ex);
      n = 0;
   }
   else {
      NeedExt(ex,y);
      n = blk64(name(y))*BLKSIZE;
      if (F >= Files)
         dbfErr(ex);
      if (n == 0)
         return Nil;
   }
   if (x = cdr(x),  isExt(y = EVAL(car(x)))) {
      n2 = blk64(name(y))*BLKSIZE;
      x = cdr(x),  free = blk64(EVAL(car(x)));
      wrLock();
      if (Journal)
         lockFile(fileno(Journal), F_SETLKW, F_WRLCK);
      if (!Log)
         ++Env.protect;
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
      if (Journal)
         fflush(Journal),  lockFile(fileno(Journal), F_SETLK, F_UNLCK);
      if (!Log)
         --Env.protect;
      rwUnlock(1);
      return new64(free,Nil);
   }
   rdLock();
   blkPeek(0, buf, 2*BLK),  next = getAdr(buf+BLK);  // Get Next
   while ((n += BLKSIZE) < next) {
      blkPeek(n << BlkShift[F], buf, BLK),  p = getAdr(buf);
      if ((p & TAGMASK) == 1) {
         rwUnlock(1);
         return mkId(n/BLKSIZE);
      }
   }
   rwUnlock(1);
   return Nil;
}

// (lieu 'any) -> sym | NIL
any doLieu(any x) {
   any y;

   x = cdr(x);
   if (!isSym(x = EVAL(car(x))) || !isExt(x))
      return Nil;
   for (y = tail1(x); !isSym(y); y = cdr(cellPtr(y)));
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
         dbfErr(ex);
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
   for (x = tail1(x);  isCell(x);  x = cdr(x)) {
      if (isSym(car(x)))
         n += binSize(car(x)) + 2;
      else
         n += binSize(cdar(x)) + binSize(caar(x));
   }
   return n;
}


void db(any ex, any s, int a) {
   any x, y, *p;

   if (!isNum(x = tail1(s))) {
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
            tail(s) = ext(x);
         }
      }
      else if (isNil(*p) || a > 1) {
         if (a == 3) {
            *p = At3;  // deleted
            val(s) = Nil;
            tail(s) = ext(x);
         }
         else if (*p == At)
            *p =  At2;  // loaded -> dirty
         else {  // NIL & 1 | 2
            adr n;
            cell c[1];

            Push(c[0],s);
            n = blk64(x);
            if (F < Files) {
               rdLock();
               rdBlock(n*BLKSIZE);
               if ((Block[0] & TAGMASK) != 1)
                  err(ex, s, "Bad ID");
               *p  =  a == 1? At : At2;  // loaded : dirty
               getBin = getBlock;
               val(s) = binRead(0);
               if (!isNil(y = binRead(0))) {
                  tail(s) = ext(x = cons(y,x));
                  if ((y = binRead(0)) != T)
                     car(x) = cons(y,car(x));
                  while (!isNil(y = binRead(0))) {
                     cdr(x) = cons(y,cdr(x));
                     if ((y = binRead(0)) != T)
                        cadr(x) = cons(y,cadr(x));
                     x = cdr(x);
                  }
               }
               rwUnlock(1);
            }
            else {
               if (!isCell(y = val(Ext)) || F < unBox(caar(y)))
                  dbfErr(ex);
               while (isCell(cdr(y)) && F >= unBox(caadr(y)))
                  y = cdr(y);
               y = apply(ex, cdar(y), NO, 1, c);  // ((Obj) ..)
               *p = At;  // loaded
               val(s) = car(y);
               if (!isCell(y = cdr(y)))
                  tail(s) = ext(x);
               else {
                  tail(s) = ext(y);
                  while (isCell(cdr(y)))
                     y = cdr(y);
                  cdr(y) = x;
               }
            }
            drop(c[0]);
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
         for (y = tail1(car(x)); isCell(y); y = cdr(y));
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
            for (z = tail1(car(x));  isCell(z);  z = cdr(z)) {
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
   if (isCell(val(Zap)))
      val(Zap) = cons(Nil, val(Zap));
   ++Transactions;
   return T;
}

// (commit ['any] [exe1] [exe2]) -> flg
any doCommit(any ex) {
   bool force, note;
   int i;
   adr n;
   any flg, x, y, z;
   ptr pbSave, ppSave;
   byte dirty[Files], buf[PIPE_BUF];

   x = cdr(ex),  flg = EVAL(car(x));
   if (force = !Transactions || !isNil(flg)) {
      wrLock();
      if (Journal)
         lockFile(fileno(Journal), F_SETLKW, F_WRLCK);
      if (!Log)
         ++Env.protect;
      else {
         for (F = 0; F < Files; ++F)
            dirty[F] = 0;
         for (i = 0; i < HASH; ++i) {  // Save objects
            for (x = Extern[i];  isCell(x);  x = cdr(x)) {
               for (y = tail1(car(x)); isCell(y); y = cdr(y));
               z = numCell(y);
               while (isNum(cdr(z)))
                  z = numCell(cdr(z));
               if (cdr(z) == At2 || cdr(z) == At3) {  // dirty or deleted
                  n = blk64(y);
                  if (F < Files) {
                     rdBlock(n*BLKSIZE),  logBlock();
                     while (BlkLink)
                        rdBlock(BlkLink),  logBlock();
                     dirty[F] = 1;
                  }
               }
            }
         }
         for (F = 0; F < Files; ++F) {
            if (dirty[F]) {
               rdBlock(0),  logBlock();   // Save Block 0
               while (BlkLink)            // Save free list
                  rdBlock(BlkLink),  logBlock();
            }
         }
         putc_unlocked(0xFF, Log),  putc_unlocked(0xFF, Log);
         fflush(Log);
         if (fsync(fileno(Log)) < 0)
            fsyncErr(ex, "Transaction");
      }
      x = cddr(ex),  EVAL(car(x));
      if (note = Tell && !isNil(flg) && flg != T)
         tellBeg(&pbSave, &ppSave, buf),  prTell(flg);
   }
   for (i = 0; i < HASH; ++i) {
      for (x = Extern[i];  isCell(x);  x = cdr(x)) {
         for (y = tail1(car(x)); isCell(y); y = cdr(y));
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
               n = blk64(y);
               if (F < Files) {
                  cleanUp(n*BLKSIZE);
                  if (note) {
                     if (PipePtr >= PipeBuf + PIPE_BUF - 12) {  // EXTERN <2+1+7> END
                        tellEnd(&pbSave, &ppSave);
                        tellBeg(&pbSave, &ppSave, buf),  prTell(flg);
                     }
                     prTell(car(x));
                  }
               }
               cdr(z) = Nil;
            }
            else if (cdr(z) == At2) {  // dirty
               n = blk64(y);
               if (F < Files) {
                  rdBlock(n*BLKSIZE);
                  Block[0] |= 1;  // Might be new
                  putBin = putBlock;
                  binPrint(0, val(y = car(x)));
                  for (y = tail1(y);  isCell(y);  y = cdr(y)) {
                     if (isSym(car(y)))
                        binPrint(0, car(y)), binPrint(0, T);
                     else
                        binPrint(0, cdar(y)), binPrint(0, caar(y));
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
   }
   if (force) {
      if (note)
         tellEnd(&pbSave, &ppSave);
      x = cdddr(ex),  EVAL(car(x));
      if (Journal)
         fflush(Journal),  lockFile(fileno(Journal), F_SETLK, F_UNLCK);
      if (isCell(x = val(Zap))) {
         for (z = cdr(x); isCell(z); z = cdr(z));
         {
            outFile f, *oSave;
            char nm[pathSize(z)];

            pathString(z, nm);
            if ((f.fd = open(nm, O_APPEND|O_CREAT|O_WRONLY, 0666)) >= 0) {
               f.ix = 0;
               putBin = putStdout;
               oSave = OutFile,  OutFile = &f;
               for (;;) {
                  for (y = car(x); isCell(y); y = cdr(y))
                     binPrint(0, car(y));
                  if (!isCell(cdr(x)))
                     break;
                  x = cdr(x);
               }
               OutFile = oSave;
               wrBytes(f.fd, f.buf, f.ix);
               close(f.fd);
            }
         }
         car(x) = Nil;
      }
      if (!Log)
         --Env.protect;
      else {
         for (F = 0; F < Files; ++F)
            if (dirty[F] && fsync(BlkFile[F]) < 0)
               fsyncErr(ex, "DB");
         fseek(Log, 0L, SEEK_SET);
         ftruncate(fileno(Log), 0);
      }
      rwUnlock(0);  // Unlock all
      Transactions = 0;
      return T;
   }
   rwUnlock(1);
   if (isCell(x = val(Zap))) {
      if (isCell(y = car(x))) {
         for (z = y; isCell(cdr(z)); z = cdr(z));
         cdr(z) = cadr(x);
         cadr(x) = y;
      }
      val(Zap) = cdr(x);
   }
   --Transactions;
   return Nil;
}

// (rollback) -> flg
any doRollback(any x) {
   int i;
   any y, z;

   for (i = 0; i < HASH; ++i) {
      for (x = Extern[i];  isCell(x);  x = cdr(x)) {
         for (y = tail1(car(x)); isCell(y); y = cdr(y));
         z = numCell(y);
         while (isNum(cdr(z)))
            z = numCell(cdr(z));
         if (!isSym(cdr(z))) {
            any *p = &tail(car(x));
            val(car(x)) = caddr(z);
            while (!isSym(cdddr(z)) && cadddr(z) != At2 && cadddr(z) != At3)
               *p = cdddr(z),  cdddr(z) = cddddr(z),  p = &cdr(*p);
            *p = y;
            mkExt(car(x));
            cdr(z) = cdddr(z);
         }
         else if (!isNil(cdr(z))) {
            val(car(x)) = Nil;
            tail(car(x)) = ext(y);
            cdr(z) = Nil;
         }
      }
   }
   if (Transactions) {
      if (isCell(val(Zap)))
         val(Zap) = cdr(val(Zap));
      --Transactions;
      return Nil;
   }
   else if (isCell(x = val(Zap)))
      car(x) = Nil;
   rwUnlock(0);  // Unlock all
   return T;
}

// (mark 'sym|0 [NIL | T | 0]) -> flg
any doMark(any ex) {
   any x, y;
   adr n, m;
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
   if (F >= Files)
      dbfErr(ex);
   if (!Marks) {
      Marks = alloc(Marks, Files * sizeof(adr));
      memset(Marks, 0, Files * sizeof(adr));
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
      dbfErr(x);
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
any doDbck(any ex) {
   any x, y;
   bool flg;
   int i;
   adr next, p, cnt;
   word2 blks, syms;
   byte buf[2*BLK];
   cell c1;

   F = 0;
   x = cdr(ex);
   if (isNum(y = EVAL(car(x)))) {
      if ((F = (int)unDig(y)/2 - 1) >= Files)
         dbfErr(ex);
      x = cdr(x),  y = EVAL(car(x));
   }
   flg = !isNil(y);
   cnt = BLKSIZE;
   blks = syms = 0;
   wrLock();
   if (Journal)
      lockFile(fileno(Journal), F_SETLKW, F_WRLCK);
   ++Env.protect;
   blkPeek(0, buf, 2*BLK);  // Get Free, Next
   BlkLink = getAdr(buf);
   next = getAdr(buf+BLK);
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
      fflush(Journal),  lockFile(fileno(Journal), F_SETLK, F_UNLCK);
   --Env.protect;
   rwUnlock(1);
   if (cnt != next)
      return mkStr("Bad count");
   if (!flg)
      return Nil;
   Push(c1, boxWord2(syms));
   data(c1) = cons(boxWord2(blks), data(c1));
   return Pop(c1);
}
