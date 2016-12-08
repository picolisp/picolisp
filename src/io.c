/* 26aug16abu
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

static char Delim[] = " \t\n\r\"'(),[]`~{}";
static int StrI;
static cell StrCell, *StrP;
static bool Sync;
static pid_t Talking;
static byte *PipeBuf, *PipePtr;
static void (*PutSave)(int);
static byte TBuf[] = {INTERN+4, 'T'};

static void openErr(any ex, char *s) {err(ex, NULL, "%s open: %s", s, strerror(errno));}
static void closeErr(void) {err(NULL, NULL, "Close error: %s", strerror(errno));}
static void eofErr(void) {err(NULL, NULL, "EOF Overrun");}
static void badInput(void) {err(NULL, NULL, "Bad input '%c'", Chr);}
static void badFd(any ex, any x) {err(ex, x, "Bad FD");}
static void lockErr(void) {err(NULL, NULL, "File lock: %s", strerror(errno));}
static void writeErr(char *s) {err(NULL, NULL, "%s write: %s", s, strerror(errno));}
static void selectErr(any ex) {err(ex, NULL, "Select error: %s", strerror(errno));}

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

int nonblocking(int fd) {
   int flg = fcntl(fd, F_GETFL, 0);

   fcntl(fd, F_SETFL, flg | O_NONBLOCK);
   return flg;
}

inFile *initInFile(int fd, char *nm) {
   inFile *p;

   if (fd >= InFDs) {
      int i = InFDs;

      InFiles = alloc(InFiles, (InFDs = fd + 1) * sizeof(inFile*));
      do
         InFiles[i] = NULL;
      while (++i < InFDs);
   }
   p = InFiles[fd] = alloc(InFiles[fd], sizeof(inFile));
   p->fd = fd;
   p->ix = p->cnt = p->next = 0;
   p->line = p->src = 1;
   p->name = nm;
   return p;
}

outFile *initOutFile(int fd) {
   outFile *p;

   if (fd >= OutFDs) {
      int i = OutFDs;

      OutFiles = alloc(OutFiles, (OutFDs = fd + 1) * sizeof(outFile*));
      do
         OutFiles[i] = NULL;
      while (++i < OutFDs);
   }
   p = OutFiles[fd] = alloc(OutFiles[fd], sizeof(outFile));
   p->tty = isatty(p->fd = fd);
   p->ix = 0;
   return p;
}

void closeInFile(int fd) {
   inFile *p;

   if (fd < InFDs && (p = InFiles[fd])) {
      if (p == InFile)
         InFile = NULL;
      free(p->name),  free(p),  InFiles[fd] = NULL;
   }
}

void closeOutFile(int fd) {
   outFile *p;

   if (fd < OutFDs && (p = OutFiles[fd])) {
      if (p == OutFile)
         OutFile = NULL;
      free(p),  OutFiles[fd] = NULL;
   }
}

int slow(inFile *p, bool nb) {
   int n, f;

   p->ix = p->cnt = 0;
   for (;;) {
      if (nb)
         f = nonblocking(p->fd);
      n = read(p->fd, p->buf, BUFSIZ);
      if (nb)
         fcntl(p->fd, F_SETFL, f);
      if (n > 0)
         return p->cnt = n;
      if (n == 0) {
         p->ix = p->cnt = -1;
         return 0;
      }
      if (errno == EAGAIN)
         return -1;
      if (errno != EINTR)
         return 0;
      if (*Signal)
         sighandler(NULL);
   }
}

int rdBytes(int fd, byte *p, int cnt, bool nb) {
   int n, f;

   for (;;) {
      if (nb)
         f = nonblocking(fd);
      n = read(fd, p, cnt);
      if (nb)
         fcntl(fd, F_SETFL, f);
      if (n > 0) {
         for (;;) {
            if ((cnt -= n) == 0)
               return 1;
            p += n;
            while ((n = read(fd, p, cnt)) <= 0) {
               if (!n || errno != EINTR)
                  return 0;
               if (*Signal)
                  sighandler(NULL);
            }
         }
      }
      if (n == 0)
         return 0;
      if (errno == EAGAIN)
         return -1;
      if (errno != EINTR)
         return 0;
      if (*Signal)
         sighandler(NULL);
   }
}

bool wrBytes(int fd, byte *p, int cnt) {
   int n;

   for (;;) {
      if ((n = write(fd, p, cnt)) >= 0) {
         if ((cnt -= n) == 0)
            return YES;
         p += n;
      }
      else {
         if (errno == EBADF || errno == EPIPE || errno == ECONNRESET)
            return NO;
         if (errno != EINTR) {
            if (fd == STDERR_FILENO)
               bye(2);
            writeErr("bytes");
         }
         if (*Signal)
            sighandler(NULL);
      }
   }
}

static void clsChild(int i) {
   if (Child[i].pid == Talking)
      Talking = 0;
   Child[i].pid = 0;
   close(Child[i].hear),  close(Child[i].tell);
   free(Child[i].buf);
}

static void wrChild(int i, byte *p, int cnt) {
   int n;

   if (Child[i].cnt == 0) {
      for (;;) {
         if ((n = write(Child[i].tell, p, cnt)) >= 0) {
            if ((cnt -= n) == 0)
               return;
            p += n;
         }
         else if (errno == EAGAIN)
            break;
         else if (errno == EPIPE || errno == ECONNRESET) {
            clsChild(i);
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

   if (p && (n = p->ix)) {
      p->ix = 0;
      return wrBytes(p->fd, p->buf, n);
   }
   return YES;
}

void flushAll(void) {
   int i;

   for (i = 0; i < OutFDs; ++i)
      flush(OutFiles[i]);
}

/*** Low level I/O ***/
static int stdinByte(void) {
   inFile *p;

   if ((p = InFiles[STDIN_FILENO]) && (p->ix != p->cnt || (p->ix >= 0 && slow(p,NO))))
      return p->buf[p->ix++];
   if (!isatty(STDIN_FILENO))
      return -1;
   bye(0);
}

static int getBinary(void) {
   if (!InFile || InFile->ix == InFile->cnt && (InFile->ix < 0 || !slow(InFile,NO)))
      return -1;
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
         do {
            if ((n = getBin()) < 0)
               return NULL;
            byteSym(n, &i, &x);
         } while (--cnt);
         if ((cnt = getBin()) < 0)
            return NULL;
      } while (cnt == 255);
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
      return (any)(long)c;  // DOT or END
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
      if (x = findHash(y, h = Extern + ehash(y)))
         return x;
      mkExt(x = consSym(Nil,y));
      *h = cons(x,*h);
      return x;
   }
   if (x = findHash(y, h = Intern + ihash(y)))
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
         prNum(hashed(x, Intern[ihash(y)])? INTERN : TRANSIENT, y);
      else
         prNum(EXTERN, extn? extOffs(-extn, y) : y);
   }
   else {
      putBin(BEG);
      if ((y = circ(x)) == NULL) {
         while (binPrint(extn, car(x)), !isNil(x = cdr(x))) {
            if (!isCell(x)) {
               putBin(DOT);
               binPrint(extn, x);
               return;
            }
         }
      }
      else if (y == x) {
         do
            binPrint(extn, car(x));
         while (y != (x = cdr(x)));
         putBin(DOT);
      }
      else {
         do
            binPrint(extn, car(x));
         while (y != (x = cdr(x)));
         putBin(DOT),  putBin(BEG);
         do
            binPrint(extn, car(x));
         while (y != (x = cdr(x)));
         putBin(DOT);
      }
      putBin(END);
   }
}

void pr(int extn, any x) {putBin = putStdout,  binPrint(extn, x);}

void prn(long n) {
   putBin = putStdout;
   prDig(NUMBER, n >= 0? n * 2 : -n * 2 + 1);
}

/* Family IPC */
static void putTell(int c) {
   *PipePtr++ = c;
   if (PipePtr == PipeBuf + PIPE_BUF - 1)  // END
      err(NULL, NULL, "Tell PIPE_BUF");
}

static void tellBeg(ptr *pb, ptr *pp, ptr buf) {
   *pb = PipeBuf,  *pp = PipePtr;
   PipePtr = (PipeBuf = buf) + 2*sizeof(int);
   *PipePtr++ = BEG;
}

static void prTell(any x) {putBin = putTell,  binPrint(0, x);}

static void tellEnd(ptr *pb, ptr *pp, int pid) {
   int i, n;

   *PipePtr++ = END;
   n = PipePtr - PipeBuf - 2*sizeof(int);
   *(int*)PipeBuf = pid;
   *((int*)PipeBuf + 1) = n;
   if (Tell && !wrBytes(Tell, PipeBuf, n + 2*sizeof(int)))
      close(Tell),  Tell = 0;
   for (i = 0; i < Children; ++i)
      if (Child[i].pid && (!pid || pid == Child[i].pid))
         wrChild(i, PipeBuf + 2*sizeof(int), n);
   PipePtr = *pp,  PipeBuf = *pb;
}

static void unsync(void) {
   int pn[2] = {0, 0};

   if (Tell && !wrBytes(Tell, (byte*)pn, 2*sizeof(int)))
      close(Tell),  Tell = 0;
   Sync = NO;
}

static any rdHear(void) {
   any x;
   inFile *iSave = InFile;

   InFile = InFiles[Hear];
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

// (path 'any) -> sym
any doPath(any x) {
   x = evSym(cdr(x));
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
   if (!Env.inFrames && !Env.outFrames)
      err(ex, NULL, "No current fd");
   if (!Env.inFrames)
      return OutFile->fd;
   if (!Env.outFrames)
      return InFile->fd;
   return labs((char*)Env.outFrames - p) > labs((char*)Env.inFrames - p)?
      InFile->fd : OutFile->fd;
}

void rdOpen(any ex, any x, inFrame *f) {
   if (isNil(x))
      f->pid = 0,  f->fd = STDIN_FILENO;
   else if (isNum(x)) {
      int n = (int)unBox(x);

      if (n < 0) {
         inFrame *g = Env.inFrames;

         for (;;) {
            if (!(g = g->link))
               badFd(ex,x);
            if (!++n) {
               n = g->fd;
               break;
            }
         }
      }
      f->pid = 0,  f->fd = n;
      if (n >= InFDs || !InFiles[n])
         badFd(ex,x);
   }
   else if (isSym(x)) {
      char nm[pathSize(x)];

      f->pid = 1;
      pathString(x,nm);
      if (nm[0] == '+') {
         while ((f->fd = open(nm+1, O_APPEND|O_CREAT|O_RDWR, 0666)) < 0) {
            if (errno != EINTR)
               openErr(ex, nm);
            if (*Signal)
               sighandler(ex);
         }
         initInFile(f->fd, strdup(nm+1));
      }
      else {
         while ((f->fd = open(nm, O_RDONLY)) < 0) {
            if (errno != EINTR)
               openErr(ex, nm);
            if (*Signal)
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
         execvp(av[0], av);
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
      f->pid = 0,  f->fd = STDOUT_FILENO;
   else if (isNum(x)) {
      int n = (int)unBox(x);

      if (n < 0) {
         outFrame *g = Env.outFrames;

         for (;;) {
            if (!(g = g->link))
               badFd(ex,x);
            if (!++n) {
               n = g->fd;
               break;
            }
         }
      }
      f->pid = 0,  f->fd = n;
      if (n >= OutFDs || !OutFiles[n])
         badFd(ex,x);
   }
   else if (isSym(x)) {
      char nm[pathSize(x)];

      f->pid = 1;
      pathString(x,nm);
      if (nm[0] == '+') {
         while ((f->fd = open(nm+1, O_APPEND|O_CREAT|O_WRONLY, 0666)) < 0) {
            if (errno != EINTR)
               openErr(ex, nm);
            if (*Signal)
               sighandler(ex);
         }
      }
      else {
         while ((f->fd = open(nm, O_CREAT|O_TRUNC|O_WRONLY, 0666)) < 0) {
            if (errno != EINTR)
               openErr(ex, nm);
            if (*Signal)
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
         execvp(av[0], av);
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

void erOpen(any ex, any x, errFrame *f) {
   int fd;

   NeedSym(ex,x);
   f->fd = dup(STDERR_FILENO);
   if (isNil(x))
      fd = dup(OutFile->fd);
   else {
      char nm[pathSize(x)];

      pathString(x,nm);
      if (nm[0] == '+') {
         while ((fd = open(nm+1, O_APPEND|O_CREAT|O_WRONLY, 0666)) < 0) {
            if (errno != EINTR)
               openErr(ex, nm);
            if (*Signal)
               sighandler(ex);
         }
      }
      else {
         while ((fd = open(nm, O_CREAT|O_TRUNC|O_WRONLY, 0666)) < 0) {
            if (errno != EINTR)
               openErr(ex, nm);
            if (*Signal)
               sighandler(ex);
         }
      }
      closeOnExec(ex, fd);
   }
   dup2(fd, STDERR_FILENO),  close(fd);
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
            if (*Signal)
               sighandler(ex);
         }
         lockFile(f->fd, F_SETLKW, F_RDLCK);
      }
      else {
         while ((f->fd = open(nm, O_CREAT|O_RDWR, 0666)) < 0) {
            if (errno != EINTR)
               openErr(ex, nm);
            if (*Signal)
               sighandler(ex);
         }
         lockFile(f->fd, F_SETLKW, F_WRLCK);
      }
      closeOnExec(ex, f->fd);
   }
}

/*** Reading ***/
void getStdin(void) {
   if (!InFile)
      Chr = -1;
   else if (InFile != InFiles[STDIN_FILENO]) {
      if (InFile->ix == InFile->cnt  && (InFile->ix < 0 || !slow(InFile,NO))) {
         Chr = -1;
         return;
      }
      if ((Chr = InFile->buf[InFile->ix++]) == '\n')
         ++InFile->line;
   }
   else if (!isCell(val(Led))) {
      waitFd(NULL, STDIN_FILENO, -1);
      Chr = stdinByte();
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
   Chr = (InFile = InFiles[f->fd])? InFile->next : -1;
   f->get = Env.get,  Env.get = getStdin;
   f->link = Env.inFrames,  Env.inFrames = f;
}

void pushOutFiles(outFrame *f) {
   OutFile = OutFiles[f->fd];
   f->put = Env.put,  Env.put = putStdout;
   f->link = Env.outFrames,  Env.outFrames = f;
}

void pushErrFiles(errFrame *f) {
   f->link = Env.errFrames,  Env.errFrames = f;
}

void pushCtlFiles(ctlFrame *f) {
   f->link = Env.ctlFrames,  Env.ctlFrames = f;
}

void popInFiles(void) {
   if (Env.inFrames->pid) {
      close(Env.inFrames->fd),  closeInFile(Env.inFrames->fd);
      if (Env.inFrames->pid > 1)
         while (waitpid(Env.inFrames->pid, NULL, 0) < 0) {
            if (errno != EINTR)
               closeErr();
            if (*Signal)
               sighandler(NULL);
         }
   }
   else if (InFile)
      InFile->next = Chr;
   Env.get = Env.inFrames->get;
   Chr =
      (InFile = InFiles[(Env.inFrames = Env.inFrames->link)? Env.inFrames->fd : STDIN_FILENO])?
         InFile->next : -1;
}

void popOutFiles(void) {
   flush(OutFile);
   if (Env.outFrames->pid) {
      close(Env.outFrames->fd),  closeOutFile(Env.outFrames->fd);
      if (Env.outFrames->pid > 1)
         while (waitpid(Env.outFrames->pid, NULL, 0) < 0) {
            if (errno != EINTR)
               closeErr();
            if (*Signal)
               sighandler(NULL);
         }
   }
   Env.put = Env.outFrames->put;
   OutFile = OutFiles[(Env.outFrames = Env.outFrames->link)? Env.outFrames->fd : STDOUT_FILENO];
}

void popErrFiles(void) {
   dup2(Env.errFrames->fd, STDERR_FILENO);
   close(Env.errFrames->fd);
   Env.errFrames = Env.errFrames->link;
}

void popCtlFiles(void) {
   if (Env.ctlFrames->fd >= 0)
      close(Env.ctlFrames->fd);
   else
      lockFile(currFd(NULL, (char*)Env.ctlFrames), F_SETLK, F_UNLCK);
   Env.ctlFrames = Env.ctlFrames->link;
}

/* Get full char from input channel */
int getChar(void) {
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
static int skipc(int c) {
   if (Chr < 0)
      return Chr;
   for (;;) {
      while (Chr <= ' ') {
         Env.get();
         if (Chr < 0)
            return Chr;
      }
      if (Chr != c)
         return Chr;
      Env.get();
      while (Chr != '\n') {
         if (Chr < 0)
            return Chr;
         Env.get();
      }
   }
}

static void comment(void) {
   Env.get();
   if (Chr != '{') {
      while (Chr != '\n') {
         if (Chr < 0)
            return;
         Env.get();
      }
   }
   else {
      for (;;) {  // #{block-comment}# from Kriangkrai Soatthiyanont
         Env.get();
         if (Chr < 0)
            return;
         if (Chr == '}' && (Env.get(), Chr == '#'))
            break;
      }
      Env.get();
   }
}

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
      comment();
   }
}

/* Test for escaped characters */
static bool testEsc(void) {
   for (;;) {
      if (Chr < 0)
         return NO;
      if (Chr == '^') {
         Env.get();
         if (Chr == '@')
            badInput();
         if (Chr == '?')
            Chr = 127;
         else
            Chr &= 0x1F;
         return YES;
      }
      if (Chr != '\\') {
         Chr = getChar();
         return YES;
      }
      if (Env.get(), Chr != '\n') {
         switch (Chr) {
         case 'n': Chr = '\n'; break;
         case 'r': Chr = '\r'; break;
         case 't': Chr = '\t'; break;
         default:
            if ('0' <= Chr && Chr <= '9') {
               int c = Chr - '0';

               while (Env.get(), Chr != '\\') {
                  if (Chr < '0' || '9' < Chr)
                     badInput();
                  c = c * 10 + Chr - '0';
               }
               Chr = c;
            }
         }
         return YES;
      }
      do
         Env.get();
      while (Chr == ' '  ||  Chr == '\t');
   }
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
      if ((any)n >= h->cells  &&  (any)n < h->cells + CELLS)
         return symPtr((any)n);
   while (h = h->next);
   return NULL;
}

/* Read an atom */
static any rdAtom(int c) {
   int i;
   any x, y, *h;
   cell c1;

   i = 0,  Push(c1, y = box(c));
   while (Chr > 0 && !strchr(Delim, Chr)) {
      if (Chr == '\\')
         Env.get();
      byteSym(Chr, &i, &y);
      Env.get();
   }
   y = Pop(c1);
   if (unDig(y) == ('L'<<16 | 'I'<<8 | 'N'))
      return Nil;
   if (x = symToNum(y, (int)unDig(val(Scl)) / 2, '.', 0))
      return x;
   if (x = anonymous(y))
      return x;
   if (x = findHash(y, h = Intern + ihash(y)))
      return x;
   x = consSym(Nil,y);
   *h = cons(x,*h);
   return x;
}

/* Read a list */
static any rdList(void) {
   any x;
   cell c1;

   Env.get();
   for (;;) {
      if (skip() == ')') {
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
      if (skip() == ')') {
         Env.get();
         break;
      }
      if (Chr == ']')
         break;
      if (Chr == '.') {
         Env.get();
         if (strchr(Delim, Chr)) {
            cdr(x) = skip()==')' || Chr==']'? data(c1) : read0(NO);
            if (skip() == ')')
               Env.get();
            else if (Chr != ']')
               err(NULL, x, "Bad dotted pair");
            break;
         }
         x = cdr(x) = cons(rdAtom('.'), Nil);
      }
      else if (Chr != '~')
         x = cdr(x) = cons(read0(NO), Nil);
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

/* Read one expression */
static any read0(bool top) {
   int i;
   any x, y, *h;
   cell c1;

   if (skip() < 0) {
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
      return cons(Quote, read0(top));
   }
   if (Chr == ',') {
      Env.get();
      x = read0(top);
      if (val(Uni) != T) {
         Push(c1, x);
         if (isCell(y = idx(Uni, data(c1), 1)))
            x = car(y);
         drop(c1);
      }
      return x;
   }
   if (Chr == '`') {
      Env.get();
      Push(c1, read0(top));
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
      i = 0,  Push(c1, y = boxChar(Chr, &i, &y));
      while (Env.get(), Chr != '"') {
         if (!testEsc())
            eofErr();
         charSym(Chr, &i, &y);
      }
      y = Pop(c1),  Env.get();
      if (x = findHash(y, h = Transient + ihash(y)))
         return x;
      x = consStr(y);
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
      if (x = findHash(y, h = Extern + ehash(y)))
         return x;
      mkExt(x = consSym(Nil,y));
      *h = cons(x,*h);
      return x;
   }
   if (Chr == ')' || Chr == ']' || Chr == '~')
      badInput();
   if (Chr == '\\')
      Env.get();
   i = Chr;
   Env.get();
   return rdAtom(i);
}

any read1(int end) {
   if (!Chr)
      Env.get();
   if (Chr == end)
      return Nil;
   return read0(YES);
}

/* Read one token */
any token(any x, int c) {
   int i;
   any y, *h;
   cell c1;

   if (!Chr)
      Env.get();
   if (skipc(c) < 0)
      return NULL;
   if (Chr == '"') {
      Env.get();
      if (Chr == '"') {
         Env.get();
         return Nil;
      }
      if (!testEsc())
         return Nil;
      Push(c1, y =  cons(mkChar(Chr), Nil));
      while (Env.get(), Chr != '"' && testEsc())
         y = cdr(y) = cons(mkChar(Chr), Nil);
      Env.get();
      return Pop(c1);
   }
   if (Chr >= '0' && Chr <= '9') {
      i = 0,  Push(c1, y = box(Chr));
      while (Env.get(), Chr >= '0' && Chr <= '9' || Chr == '.')
         byteSym(Chr, &i, &y);
      return symToNum(Pop(c1), (int)unDig(val(Scl)) / 2, '.', 0);
   }
   if (Chr != '+' && Chr != '-') {
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
         if (unDig(y) == ('L'<<16 | 'I'<<8 | 'N'))
            return Nil;
         if (x = findHash(y, h = Intern + ihash(y)))
            return x;
         x = consSym(Nil,y);
         *h = cons(x,*h);
         return x;
      }
   }
   c = getChar();
   Env.get();
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
   if (InFile == InFiles[STDIN_FILENO]  &&  Chr == '\n')
      Chr = 0;
   return x;
}

static inline bool inReady(inFile *p) {
   return p->ix < p->cnt;
}

static bool isSet(int fd, fd_set *fds) {
   inFile *p;

   if (fd >= InFDs || !(p = InFiles[fd]))
      return FD_ISSET(fd, fds);
   if (inReady(p))
      return YES;
   return FD_ISSET(fd, fds) && slow(p,YES) >= 0;
}

long waitFd(any ex, int fd, long ms) {
   any x, taskSave;
   cell c1, c2, c3;
   int i, j, m, n;
   long t;
   fd_set rdSet, wrSet;
   struct timeval *tp, tv;
#ifndef __linux__
   struct timeval tt;
#endif

   taskSave = Env.task;
   Push(c1, val(At));
   Save(c2);
   do {
      if (ms >= 0)
         t = ms,  tp = &tv;
      else
         t = LONG_MAX,  tp = NULL;
      FD_ZERO(&rdSet);
      FD_ZERO(&wrSet);
      m = 0;
      if (fd >= 0) {
         if (fd < InFDs  &&  InFiles[fd]  &&  inReady(InFiles[fd]))
            tp = &tv,  t = 0;
         else
            FD_SET(m = fd, &rdSet);
      }
      for (x = data(c2) = Env.task = val(Run); isCell(x); x = cdr(x)) {
         if (!memq(car(x), taskSave)) {
            if (isNeg(caar(x))) {
               if ((n = (int)unDig(cadar(x)) / 2) < t)
                  tp = &tv,  t = n;
            }
            else if ((n = (int)unDig(caar(x)) / 2) != fd) {
               if (n < InFDs  &&  InFiles[n]  &&  inReady(InFiles[n]))
                  tp = &tv,  t = 0;
               else {
                  FD_SET(n, &rdSet);
                  if (n > m)
                     m = n;
               }
            }
         }
      }
      if (Hear  &&  Hear != fd  &&  InFiles[Hear]) {
         if (inReady(InFiles[Hear]))
            tp = &tv,  t = 0;
         else {
            FD_SET(Hear, &rdSet);
            if (Hear > m)
               m = Hear;
         }
      }
      if (Spkr) {
         FD_SET(Spkr, &rdSet);
         if (Spkr > m)
            m = Spkr;
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
            selectErr(ex);
         }
         if (*Signal)
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
      if (Spkr) {
         ++Env.protect;
         for (i = 0; i < Children; ++i) {
            if (Child[i].pid) {
               if (FD_ISSET(Child[i].hear, &rdSet)) {
                  int pn[2];

                  if ((m = rdBytes(Child[i].hear, (byte*)pn, 2*sizeof(int), YES)) >= 0) {
                     byte buf[PIPE_BUF - sizeof(int)];

                     if (m == 0) {
                        clsChild(i);
                        continue;
                     }
                     if (pn[0] == 0 && pn[1] == 0) {
                        if (Child[i].pid == Talking)
                           Talking = 0;
                     }
                     else if (rdBytes(Child[i].hear, buf, pn[1], NO)) {
                        for (j = 0; j < Children; ++j)
                           if (j != i && Child[j].pid && (!pn[0] || pn[0] == Child[j].pid))
                              wrChild(j, buf, pn[1]);
                     }
                     else {
                        clsChild(i);
                        continue;
                     }
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
                  else
                     clsChild(i);
               }
            }
         }
         if (!Talking  &&  FD_ISSET(Spkr,&rdSet)  &&
                  rdBytes(Spkr, (byte*)&m, sizeof(int), YES) > 0  &&
                  Child[m].pid ) {
            Talking = Child[m].pid;
            wrChild(m, TBuf, sizeof(TBuf));
         }
         --Env.protect;
      }
      if (Hear && Hear != fd && isSet(Hear, &rdSet)) {
         if ((data(c3) = rdHear()) == NULL)
            close(Hear),  closeInFile(Hear),  closeOutFile(Hear),  Hear = 0;
         else if (data(c3) == T)
            Sync = YES;
         else {
            Save(c3);
            evList(data(c3));
            drop(c3);
         }
      }
      for (x = data(c2); isCell(x); x = cdr(x)) {
         if (!memq(car(x), taskSave)) {
            if (isNeg(caar(x))) {
               if ((n = (int)(unDig(cadar(x)) / 2 - t)) > 0)
                  setDig(cadar(x), (long)2*n);
               else {
                  setDig(cadar(x), unDig(caar(x)));
                  val(At) = caar(x);
                  prog(cddar(x));
               }
            }
            else if ((n = (int)unDig(caar(x)) / 2) != fd) {
               if (isSet(n, &rdSet)) {
                  val(At) = caar(x);
                  prog(cdar(x));
               }
            }
         }
      }
      if (*Signal)
         sighandler(ex);
   } while (ms  &&  fd >= 0 && !isSet(fd, &rdSet));
   Env.task = taskSave;
   val(At) = Pop(c1);
   return ms;
}

// (wait 'cnt|NIL . prg) -> any
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
   if (Sync)
      return T;
   p = (byte*)&Slot;
   cnt = sizeof(int);
   for (;;) {
      if ((n = write(Mic, p, cnt)) >= 0) {
         if ((cnt -= n) == 0)
            break;
         p += n;
      }
      else {
         if (errno != EINTR)
            writeErr("sync");
         if (*Signal)
            sighandler(ex);
      }
   }
   Sync = NO;
   do
      waitFd(ex, -1, -1);
   while (!Sync);
   return T;
}

// (hear 'cnt) -> cnt
any doHear(any ex) {
   any x;
   int fd;

   x = cdr(ex),  x = EVAL(car(x));
   if ((fd = (int)xCnt(ex,x)) < 0 || fd >= InFDs || !InFiles[fd])
      badFd(ex,x);
   if (Hear)
      close(Hear),  closeInFile(Hear),  closeOutFile(Hear);
   Hear = fd;
   return x;
}

// (tell ['cnt] 'sym ['any ..]) -> any
any doTell(any x) {
   any y;
   int pid;
   ptr pbSave, ppSave;
   byte buf[PIPE_BUF];

   if (!Tell && !Children)
      return Nil;
   if (!isCell(x = cdr(x))) {
      unsync();
      return Nil;
   }
   pid = 0;
   if (isNum(y = EVAL(car(x)))) {
      pid = (int)unDig(y)/2;
      x = cdr(x),  y = EVAL(car(x));
   }
   tellBeg(&pbSave, &ppSave, buf);
   while (prTell(y), isCell(x = cdr(x)))
      y = EVAL(car(x));
   tellEnd(&pbSave, &ppSave, pid);
   return y;
}

// (poll 'cnt) -> cnt | NIL
any doPoll(any ex) {
   any x;
   int fd;
   inFile *p;
   fd_set fdSet;
   struct timeval tv;

   x = cdr(ex),  x = EVAL(car(x));
   if ((fd = (int)xCnt(ex,x)) < 0  ||  fd >= InFDs)
      badFd(ex,x);
   if (!(p = InFiles[fd]))
      return Nil;
   do {
      if (inReady(p))
         return x;
      FD_ZERO(&fdSet);
      FD_SET(fd, &fdSet);
      tv.tv_sec = tv.tv_usec = 0;
      while (select(fd+1, &fdSet, NULL, NULL, &tv) < 0)
         if (errno != EINTR)
            selectErr(ex);
      if (!FD_ISSET(fd, &fdSet))
         return Nil;
   } while (slow(p,YES) < 0);
   return x;
}

// (key ['cnt]) -> sym
any doKey(any ex) {
   any x;
   int c, d;

   flushAll();
   setRaw();
   x = cdr(ex);
   if (!waitFd(ex, STDIN_FILENO, isNil(x = EVAL(car(x)))? -1 : xCnt(ex,x)))
      return Nil;
   if ((c = stdinByte()) == 0xFF)
      c = TOP;
   else if (c & 0x80) {
      d = stdinByte();
      if ((c & 0x20) == 0)
         c = (c & 0x1F) << 6 | d & 0x3F;
      else
         c = ((c & 0xF) << 6 | d & 0x3F) << 6 | stdinByte() & 0x3F;
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

// (skip ['any]) -> sym
any doSkip(any x) {
   x = evSym(cdr(x));
   return skipc(symChar(name(x)))<0? Nil : mkChar(Chr);
}

// (eol) -> flg
any doEol(any ex __attribute__((unused))) {
   return Chr=='\n' || Chr<=0? T : Nil;
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
any doFrom(any x) {
   int i, j, ac = length(x = cdr(x)), p[ac];
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
   if (!Chr)
      Env.get();
   while (Chr >= 0) {
      for (i = 0; i < ac; ++i) {
         for (;;) {
            if (av[i][p[i]] == (byte)Chr) {
               if (av[i][++p[i]])
                  break;
               Env.get();
               x = data(c[i]);
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
   x = Nil;
done:
   i = 0;  do
      free(av[i]);
   while (++i < ac);
   drop(c[0]);
   return x;
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
any doLines(any x) {
   any y;
   int c, cnt = 0;
   bool flg = NO;
   FILE *fp;

   for (x = cdr(x); isCell(x); x = cdr(x)) {
      y = evSym(x);
      {
         char nm[pathSize(y)];

         pathString(y, nm);
         if (fp = fopen(nm, "r")) {
            flg = YES;
            while ((c = getc_unlocked(fp)) >= 0)
               if (c == '\n')
                  ++cnt;
            fclose(fp);
         }
      }
   }
   return flg? boxCnt(cnt) : Nil;
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
         x = Nil;
      else {
         Push(c2, y = cons(x,Nil));
         while (x = token(s,0))
            y = cdr(y) = cons(x,Nil);
         x = Pop(c2);
      }
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
   x = EVAL(cadr(x));
   begString();
   print(x);
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
   if (isNum(x))
      argError(ex,x);
   if (isSym(x)) {
      if (!isCell(cddr(ex)))
         return parse(x, NO, NULL);
      Push(c1, x);
      Push(c2, evSym(cddr(ex)));
      x = parse(x, NO, data(c2));
      drop(c1);
      return x;
   }
   begString();
   while (print(car(x)), isCell(x = cdr(x)))
      space();
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
   pushInFiles(&f);
   doHide(Nil);
   x = Nil;
   for (;;) {
      if (InFile != InFiles[STDIN_FILENO])
         data(c1) = read1(0);
      else {
         if (pr && !Chr)
            prin(run(val(Prompt))), Env.put(pr), space(), flushAll();
         data(c1) = read1(isatty(STDIN_FILENO)? '\n' : 0);
         while (Chr > 0) {
            if (Chr == '\n') {
               Chr = 0;
               break;
            }
            if (Chr == '#')
               comment();
            else {
               if (Chr > ' ')
                  break;
               Env.get();
            }
         }
      }
      if (isNil(data(c1))) {
         popInFiles();
         doHide(Nil);
         return x;
      }
      Save(c1);
      if (InFile != InFiles[STDIN_FILENO] || Chr || !pr)
         x = EVAL(data(c1));
      else {
         flushAll();
         Push(c2, val(At));
         x = val(At) = EVAL(data(c1));
         val(At3) = val(At2),  val(At2) = data(c2);
         outString("-> "),  flushAll(),  print1(x),  newline();
      }
      drop(c1);
   }
}

// (load 'any ..) -> any
any doLoad(any ex) {
   any x, y;

   x = cdr(ex);
   do {
      if ((y = EVAL(car(x))) != T)
         y = load(ex, '>', y);
      else
         y = loadAll(ex);
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

// (err 'sym . prg) -> any
any doErr(any ex) {
   any x;
   errFrame f;

   x = cdr(ex),  x = EVAL(car(x));
   erOpen(ex,x,&f);
   pushErrFiles(&f);
   x = prog(cddr(ex));
   popErrFiles();
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

// (pipe exe) -> cnt
// (pipe exe . prg) -> any
any doPipe(any ex) {
   any x;
   union {
      inFrame in;
      outFrame out;
   } f;
   int pfd[2];

   if ((isCell(cddr(ex))? pipe(pfd) : socketpair(AF_UNIX, SOCK_STREAM, 0, pfd)) < 0  ||  pfd[1] < 2)
      err(ex, NULL, "Can't pipe");
   closeOnExec(ex, pfd[0]), closeOnExec(ex, pfd[1]);
   if ((f.in.pid = forkLisp(ex)) == 0) {
      close(pfd[0]);
      if (isCell(cddr(ex)))
         setpgid(0,0);
      else
         dup2(pfd[1], STDIN_FILENO);
      dup2(pfd[1], STDOUT_FILENO);
      close(pfd[1]);
      signal(SIGPIPE, SIG_DFL);
      f.out.pid = 0,  f.out.fd = STDOUT_FILENO;
      pushOutFiles(&f.out);
      OutFile->tty = NO;
      val(Led) = val(Run) = Nil;
      EVAL(cadr(ex));
      bye(0);
   }
   close(pfd[1]);
   initInFile(f.in.fd = pfd[0], NULL);
   if (!isCell(cddr(ex))) {
      initOutFile(pfd[0]);
      return boxCnt(pfd[0]);
   }
   setpgid(f.in.pid,0);
   pushInFiles(&f.in);
   x = prog(cddr(ex));
   popInFiles();
   return x;
}

// (open 'any ['flg]) -> cnt | NIL
any doOpen(any ex) {
   any x = evSym(cdr(ex));
   char nm[pathSize(x)];
   int fd;

   pathString(x, nm);
   x = caddr(ex),  x = EVAL(x);
   while ((fd = open(nm, isNil(x)? O_CREAT|O_RDWR : O_RDONLY, 0666)) < 0) {
      if (errno != EINTR)
         return Nil;
      if (*Signal)
         sighandler(ex);
   }
   closeOnExec(ex, fd);
   initInFile(fd, strdup(nm)), initOutFile(fd);
   return boxCnt(fd);
}

// (close 'cnt) -> cnt | NIL
any doClose(any ex) {
   any x;
   int fd;

   x = cdr(ex),  x = EVAL(car(x)),  fd = (int)xCnt(ex,x);
   while (close(fd)) {
      if (errno != EINTR)
         return Nil;
      if (*Signal)
         sighandler(ex);
   }
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
      int m, n, i, j, ac = length(x), p[ac], om, op;
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
      m = -1;
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
                     for (j = 0, n = op-p[i]; j <= n; ++j)
                        Env.put(av[om][j]);
                  Chr = 0;
                  x = data(c[i]);
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
            for (i = 0, n = op-p[m]; i <= n; ++i)
               Env.put(av[om][i]);
         Env.get();
      }
      x = Nil;
   done:
      i = 0;  do
         free(av[i]);
      while (++i < ac);
      drop(c[0]);
      return x;
   }
   if (isCell(x = cdr(x))) {
      for (cnt = xCnt(ex,y), y = EVAL(car(x)); --cnt >= 0; Env.get())
         if (Chr < 0)
            return Nil;
   }
   if ((cnt = xCnt(ex,y)) > 0) {
      for (;;) {
         if (Chr < 0)
            return Nil;
         Env.put(Chr);
         if (!--cnt)
            break;
         Env.get();
      }
   }
   Chr = 0;
   return T;
}

/*** Printing ***/
void putStdout(int c) {
   if (OutFile) {
      if (OutFile->ix == BUFSIZ) {
         OutFile->ix = 0;
         wrBytes(OutFile->fd, OutFile->buf, BUFSIZ);
      }
      if ((OutFile->buf[OutFile->ix++] = c) == '\n' && OutFile->tty) {
         int n = OutFile->ix;

         OutFile->ix = 0;
         wrBytes(OutFile->fd, OutFile->buf, n);
      }
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

void outName(any s) {
   int c;

   if (c = symByte(name(s)))
      outSym(c);
}

void outNum(any x) {
   if (isNum(cdr(numCell(x)))) {
      cell c1;

      Push(c1, numToSym(x, 0, 0, 0));
      outName(data(c1));
      drop(c1);
   }
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
   cell c1;

   Push(c1,x);
   print1(x);
   drop(c1);
}

void print1(any x) {
   if (*Signal)
      sighandler(NULL);
   if (isNum(x))
      outNum(x);
   else if (isNil(x))
      outString("NIL");
   else if (isSym(x)) {
      int c;
      any y;

      if (!(c = symByte(y = name(x))))
         Env.put('$'),  outWord(num(x)/sizeof(cell));
      else if (isExt(x))
         Env.put('{'),  outSym(c),  Env.put('}');
      else if (hashed(x, Intern[ihash(y)])) {
         if (unDig(y) == '.')
            Env.put('\\'),  Env.put('.');
         else {
            if (c == '#')
               Env.put('\\');
            do {
               if (c == '\\' || strchr(Delim, c))
                  Env.put('\\');
               Env.put(c);
            } while (c = symByte(NULL));
         }
      }
      else {
         bool tsm = isCell(val(Tsm)) && Env.put == putStdout && OutFile->tty;

         if (!tsm)
            Env.put('"');
         else {
            outName(car(val(Tsm)));
            c = symByte(y);
         }
         do {
            if (c == '\\'  ||  c == '^'  ||  !tsm && c == '"')
               Env.put('\\');
            else if (c == 127)
               Env.put('^'),  c = '?';
            else if (c < ' ')
               Env.put('^'),  c |= 0x40;
            Env.put(c);
         } while (c = symByte(NULL));
         if (!tsm)
            Env.put('"');
         else
            outName(cdr(val(Tsm)));
      }
   }
   else if (car(x) == Quote  &&  x != cdr(x))
      Env.put('\''),  print1(cdr(x));
   else {
      any y;

      Env.put('(');
      if ((y = circ(x)) == NULL) {
         while (print1(car(x)), !isNil(x = cdr(x))) {
            if (!isCell(x)) {
               outString(" . ");
               print1(x);
               break;
            }
            space();
         }
      }
      else if (y == x) {
         do
            print1(car(x)),  space();
         while (y != (x = cdr(x)));
         Env.put('.');
      }
      else {
         do
            print1(car(x)),  space();
         while (y != (x = cdr(x)));
         outString(". (");
         do
            print1(car(x)),  space();
         while (y != (x = cdr(x)));
         outString(".)");
      }
      Env.put(')');
   }
}

void prin(any x) {
   cell c1;

   Push(c1,x);
   prin1(x);
   drop(c1);
}

void prin1(any x) {
   if (*Signal)
      sighandler(NULL);
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
         while (prin1(car(x)), !isNil(x = cdr(x))) {
            if (!isCell(x)) {
               prin1(x);
               break;
            }
         }
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
      return Nil;
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
   long cnt;
   int n, i;
   cell c1;

   x = cdr(x),  x = EVAL(car(x));
   if (!isNum(x)) {
      Push(c1,x);
      getBin = getBinary;
      x = binRead(ExtN) ?: data(c1);
      drop(c1);
      return x;
   }
   if ((cnt = unBox(x)) < 0) {
      if ((n = getBinary()) < 0)
         return Nil;
      i = 0,  Push(c1, x = box(n));
      while (++cnt) {
         if ((n = getBinary()) < 0)
            return Nil;
         byteSym(n, &i, &x);
      }
      zapZero(data(c1));
      digMul2(data(c1));
   }
   else {
      if ((n = getBinary()) < 0)
         return Nil;
      i = 0,  Push(c1, x = box(n+n));
      while (--cnt) {
         if ((n = getBinary()) < 0)
            return Nil;
         digMul(data(c1), 256);
         setDig(data(c1), unDig(data(c1)) | n+n);
      }
      zapZero(data(c1));
   }
   return Pop(c1);
}

// (pr 'any ..) -> any
any doPr(any x) {
   any y;

   x = cdr(x);
   do
      pr(ExtN, y = EVAL(car(x)));
   while (isCell(x = cdr(x)));
   return y;
}

// (wr 'cnt ..) -> cnt
any doWr(any x) {
   any y;

   x = cdr(x);
   do
      putStdout(unDig(y = EVAL(car(x))) / 2);
   while (isCell(x = cdr(x)));
   return y;
}

/*** DB-I/O ***/
#define BLKSIZE 64  // DB block unit size
#define BLK 6
#define TAGMASK (BLKSIZE-1)
#define BLKMASK (~TAGMASK)
#define EXTERN64 65536

static int F, Files, *BlkShift, *BlkFile, *BlkSize, *Fluse, MaxBlkSize;
static FILE *Jnl, *Log;
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

static void dbfErr(any ex) {err(ex, NULL, "Bad DB file");}
static void dbErr(char *s) {err(NULL, NULL, "DB %s: %s", s, strerror(errno));}
static void jnlErr(any ex) {err(ex, NULL, "Bad Journal");}
static void fsyncErr(any ex, char *s) {err(ex, NULL, "%s fsync error: %s", s, strerror(errno));}
static void truncErr(any ex) {err(ex, NULL, "Log truncate error: %s", strerror(errno));}
static void ignLog(void) {fprintf(stderr, "Discarding incomplete transaction\n");}

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
   return hi(w)? consNum(num(w), consNum(hi(w), x)) : consNum(num(w), x);
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
   int f = F;
   adr n = blk64(x);

   if (offs != -EXTERN64) {
      if ((F += offs) < 0)
         err(NULL, NULL, "%d: Bad DB offset", F);
      x = new64(n, Nil);
   }
   else {  // Undocumented 64-bit DB export
      adr w = n & 0xFFFFF | (F & 0xFF) << 20;

      w |= ((n >>= 20) & 0xFFF) << 28;
      w |= (adr)(F >> 8) << 40 | (n >> 12) << 48;
      x = hi(w)? consNum(num(w), consNum(hi(w), Nil)) : consNum(num(w), Nil);
   }
   F = f;
   return x;
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
      while (fcntl(BlkFile[F], F_GETLK, &fl) < 0)
         if (errno != EINTR)
            lockErr();
      if (fl.l_type != F_UNLCK)
         return fl.l_pid;
   }
}

static void blkPeek(off_t pos, void *buf, int siz) {
   if (pread(BlkFile[F], buf, siz, pos) != (ssize_t)siz)
      dbErr("read");
}

static void blkPoke(off_t pos, void *buf, int siz) {
   if (pwrite(BlkFile[F], buf, siz, pos) != (ssize_t)siz)
      dbErr("write");
   if (Jnl) {
      byte a[BLK+2];

      putc_unlocked(siz == BlkSize[F]? BLKSIZE : siz, Jnl);
      a[0] = (byte)F,  a[1] = (byte)(F >> 8),  setAdr(pos >> BlkShift[F], a+2);
      if (fwrite(a, BLK+2, 1, Jnl) != 1 || fwrite(buf, siz, 1, Jnl) != 1)
         writeErr("Journal");
   }
}

static void rdBlock(adr n) {
   blkPeek((BlkIndex = n) << BlkShift[F], Block, BlkSize[F]);
   BlkLink = getAdr(Block) & BLKMASK;
   Ptr = Block + BLK;
}

static void logBlock(void) {
   byte a[BLK+2];

   a[0] = (byte)F,  a[1] = (byte)(F >> 8),  setAdr(BlkIndex, a+2);
   if (fwrite(a, BLK+2, 1, Log) != 1 || fwrite(Block, BlkSize[F], 1, Log) != 1)
      writeErr("Log");
}

static void wrBlock(void) {blkPoke(BlkIndex << BlkShift[F], Block, BlkSize[F]);}

static adr newBlock(void) {
   adr n;
   byte buf[2*BLK];

   blkPeek(0, buf, 2*BLK);  // Get Free, Next
   if ((n = getAdr(buf)) && Fluse[F]) {
      blkPeek(n << BlkShift[F], buf, BLK);  // Get free link
      --Fluse[F];
   }
   else if ((n = getAdr(buf+BLK)) != 281474976710592LL)
      setAdr(n + BLKSIZE, buf+BLK);  // Increment next
   else
      err(NULL, NULL, "DB Oversize");
   blkPoke(0, buf, 2*BLK);
   setAdr(0, IniBlk),  blkPoke(n << BlkShift[F], IniBlk, BlkSize[F]);
   return n;
}

any newId(any ex, int i) {
   adr n;

   if ((F = i-1) >= Files)
      dbfErr(ex);
   if (!Log)
      ++Env.protect;
   wrLock();
   if (Jnl)
      lockFile(fileno(Jnl), F_SETLKW, F_WRLCK);
   n = newBlock();
   if (Jnl)
      fflush(Jnl),  lockFile(fileno(Jnl), F_SETLK, F_UNLCK);
   rwUnlock(1);
   if (!Log)
      --Env.protect;
   return new64(n/BLKSIZE, At2);  // dirty
}

bool isLife(any x) {
   adr n;
   byte buf[2*BLK];

   if ((n = blk64(name(x))*BLKSIZE) > 0) {
      if (F < Files) {
         for (x = tail1(x); !isSym(x); x = cdr(cellPtr(x)));
         if (x == At || x == At2)
            return YES;
         if (x != At3) {
            blkPeek(0, buf, 2*BLK);  // Get Next
            if (n < getAdr(buf+BLK)) {
               blkPeek(n << BlkShift[F], buf, BLK);
               if ((buf[0] & TAGMASK) == 1)
                  return YES;
            }
         }
      }
      else if (isCell(val(Ext)))
         return YES;
   }
   return NO;
}

static void cleanUp(adr n) {
   adr p, fr;
   byte buf[BLK];

   blkPeek(0, buf, BLK),  fr = getAdr(buf);  // Get Free
   setAdr(n, buf),  blkPoke(0, buf, BLK);    // Set new
   for (;;) {
      p = n << BlkShift[F];
      blkPeek(p, buf, BLK);  // Get block link
      buf[0] &= BLKMASK;  // Clear Tag
      if ((n = getAdr(buf)) == 0)
         break;
      blkPoke(p, buf, BLK);
   }
   setAdr(fr, buf),  blkPoke(p, buf, BLK);  // Append old free list
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

   fprintf(stderr, "Last transaction not completed: Rollback\n");
   fseek(Log, 0L, SEEK_SET);
   for (F = 0; F < Files; ++F)
      dirty[F] = 0;
   for (;;) {
      if (fread(a, 2, 1, Log) == 0)
         jnlErr(ex);
      if (a[0] == 0xFF && a[1] == 0xFF)
         break;
      if ((F = a[0] | a[1]<<8) >= Files  ||
            fread(a, BLK, 1, Log) != 1  ||
            fread(buf, BlkSize[F], 1, Log) != 1 )
         jnlErr(ex);
      if (pwrite(BlkFile[F], buf, BlkSize[F], getAdr(a) << BlkShift[F]) != (ssize_t)BlkSize[F])
         dbErr("write");
      dirty[F] = 1;
   }
   for (F = 0; F < Files; ++F)
      if (dirty[F] && fsync(BlkFile[F]) < 0)
         fsyncErr(ex, "DB");
}

// (pool ['sym1 ['lst] ['sym2] ['sym3]]) -> T
any doPool(any ex) {
   any x;
   byte buf[2*BLK+1];
   cell c1, c2, c3, c4;

   x = cdr(ex),  Push(c1, evSym(x));  // db
   x = cdr(x),  Push(c2, EVAL(car(x)));  // lst
   NeedLst(ex,data(c2));
   x = cdr(x),  Push(c3, evSym(x));  // sym2
   Push(c4, evSym(cdr(x)));  // sym3
   val(Solo) = Zero;
   if (Files) {
      doRollback(Nil);
      for (F = 0; F < Files; ++F) {
         if (Marks)
            free(Mark[F]);
         if (close(BlkFile[F]) < 0)
            closeErr();
      }
      free(Mark), Mark = NULL, free(Marks), Marks = NULL;
      Files = 0;
      if (Jnl)
         fclose(Jnl),  Jnl = NULL;
      if (Log)
         fclose(Log),  Log = NULL;
   }
   if (!isNil(data(c1))) {
      x = data(c2);
      Files = length(x) ?: 1;
      BlkShift = alloc(BlkShift, Files * sizeof(int));
      BlkFile = alloc(BlkFile, Files * sizeof(int));
      BlkSize = alloc(BlkSize, Files * sizeof(int));
      Fluse = alloc(Fluse, Files * sizeof(int));
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
               Files = F;
               openErr(ex, nm);
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
         Fluse[F] = -1;
         x = cdr(x);
      }
      Block = alloc(Block, MaxBlkSize);
      IniBlk = alloc(IniBlk, MaxBlkSize);
      memset(IniBlk, 0, MaxBlkSize);
      if (!isNil(data(c3))) {
         char nm[pathSize(data(c3))];

         pathString(data(c3), nm);
         if (!(Jnl = fopen(nm, "a")))
            openErr(ex, nm);
         closeOnExec(ex, fileno(Jnl));
      }
      if (!isNil(data(c4))) {
         char nm[pathSize(data(c4))];

         pathString(data(c4), nm);
         if (!(Log = fopen(nm, "a+")))
            openErr(ex, nm);
         closeOnExec(ex, fileno(Log));
         if (transaction())
            restore(ex);
         fseek(Log, 0L, SEEK_SET);
         if (ftruncate(fileno(Log), 0))
            truncErr(ex);
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
               jnlErr(ex);
            if ((F = a[0] | a[1]<<8) >= Files)
               dbfErr(ex);
            if (siz == BLKSIZE)
               siz = BlkSize[F];
            if (fread(a, BLK, 1, fp) != 1 || fread(buf, siz, 1, fp) != 1)
               jnlErr(ex);
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
   if (y = findHash(x, h = Extern + ehash(x)))
      return y;
   mkExt(y = consSym(Nil,x));
   *h = cons(y,*h);
   return y;
}

// (id 'num ['num]) -> sym
// (id 'sym [NIL]) -> num
// (id 'sym T) -> (num . num)
any doId(any ex) {
   any x, y;
   adr n;
   cell c1;

   x = cdr(ex);
   if (isNum(y = EVAL(car(x)))) {
      x = cdr(x);
      if (isNil(x = EVAL(car(x)))) {
         F = 0;
         return mkId(unBoxWord2(y));
      }
      F = (int)unDig(y)/2 - 1;
      NeedNum(ex,x);
      return mkId(unBoxWord2(x));
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

// (seq 'cnt|sym1) -> sym | NIL
any doSeq(any ex) {
   any x;
   adr n, next;
   byte buf[2*BLK];

   x = cdr(ex);
   if (isNum(x = EVAL(car(x)))) {
      F = (int)unDig(x)/2 - 1;
      n = 0;
   }
   else {
      NeedExt(ex,x);
      n = blk64(name(x))*BLKSIZE;
   }
   if (F >= Files)
      dbfErr(ex);
   rdLock();
   blkPeek(0, buf, 2*BLK),  next = getAdr(buf+BLK);  // Get Next
   while ((n += BLKSIZE) < next) {
      blkPeek(n << BlkShift[F], buf, BLK);
      if ((buf[0] & TAGMASK) == 1) {
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
            *p = At2;  // loaded -> dirty
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

// (commit ['any] [exe1] [exe2]) -> flg
any doCommit(any ex) {
   bool note;
   int i, extn;
   adr n;
   cell c1;
   any x, y, z;
   ptr pbSave, ppSave;
   byte dirty[Files], buf[PIPE_BUF];

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   if (!Log)
      ++Env.protect;
   wrLock();
   if (Jnl)
      lockFile(fileno(Jnl), F_SETLKW, F_WRLCK);
   if (Log) {
      for (F = 0; F < Files; ++F)
         dirty[F] = 0,  Fluse[F] = 0;
      for (i = 0; i < EHASH; ++i) {  // Save objects
         for (x = Extern[i];  isCell(x);  x = cdr(x)) {
            for (y = tail1(car(x)); isCell(y); y = cdr(y));
            z = numCell(y);
            while (isNum(cdr(z)))
               z = numCell(cdr(z));
            if (cdr(z) == At2 || cdr(z) == At3) {  // dirty or deleted
               n = blk64(y);
               if (F < Files) {
                  rdBlock(n*BLKSIZE);
                  while (logBlock(), BlkLink)
                     rdBlock(BlkLink);
                  dirty[F] = 1;
                  if (cdr(z) != At3)
                     ++Fluse[F];
               }
            }
         }
      }
      for (F = 0; F < Files; ++F) {
         if (i = Fluse[F]) {
            rdBlock(0);                               // Save Block 0
            while (logBlock(),  BlkLink && --i >= 0)  // and free list
               rdBlock(BlkLink);
         }
      }
      putc_unlocked(0xFF, Log),  putc_unlocked(0xFF, Log);
      fflush(Log);
      if (fsync(fileno(Log)) < 0)
         fsyncErr(ex, "Transaction");
   }
   x = cddr(ex),  EVAL(car(x));
   if (data(c1) == T)
      note = NO,  extn = EXTERN64;  // Undocumented 64-bit DB export
   else {
      extn = 0;
      if (note = !isNil(data(c1)) && (Tell || Children))
         tellBeg(&pbSave, &ppSave, buf),  prTell(data(c1));
   }
   for (i = 0; i < EHASH; ++i) {
      for (x = Extern[i];  isCell(x);  x = cdr(x)) {
         for (y = tail1(car(x)); isCell(y); y = cdr(y));
         z = numCell(y);
         while (isNum(cdr(z)))
            z = numCell(cdr(z));
         if (cdr(z) == At2) {  // dirty
            n = blk64(y);
            if (F < Files) {
               rdBlock(n*BLKSIZE);
               Block[0] |= 1;  // Might be new
               putBin = putBlock;
               binPrint(extn, val(y = car(x)));
               for (y = tail1(y);  isCell(y);  y = cdr(y)) {
                  if (isCell(car(y))) {
                     if (!isNil(cdar(y)))
                        binPrint(extn, cdar(y)), binPrint(extn, caar(y));
                  }
                  else {
                     if (!isNil(car(y)))
                        binPrint(extn, car(y)), binPrint(extn, T);
                  }
               }
               putBlock(NIX);
               setAdr(Block[0] & TAGMASK, Block);  // Clear Link
               wrBlock();
               if (BlkLink)
                  cleanUp(BlkLink);
               cdr(z) = At;  // loaded
               if (note) {
                  if (PipePtr >= PipeBuf + PIPE_BUF - 12) {  // EXTERN <2+1+7> END
                     tellEnd(&pbSave, &ppSave, 0);
                     tellBeg(&pbSave, &ppSave, buf),  prTell(data(c1));
                  }
                  prTell(car(x));
               }
            }
         }
         else if (cdr(z) == At3) {  // deleted
            n = blk64(y);
            if (F < Files) {
               cleanUp(n*BLKSIZE);
               if (note) {
                  if (PipePtr >= PipeBuf + PIPE_BUF - 12) {  // EXTERN <2+1+7> END
                     tellEnd(&pbSave, &ppSave, 0);
                     tellBeg(&pbSave, &ppSave, buf),  prTell(data(c1));
                  }
                  prTell(car(x));
               }
            }
            cdr(z) = Nil;
         }
      }
   }
   if (note)
      tellEnd(&pbSave, &ppSave, 0);
   x = cdddr(ex),  EVAL(car(x));
   if (Jnl)
      fflush(Jnl),  lockFile(fileno(Jnl), F_SETLK, F_UNLCK);
   if (isCell(x = val(Zap))) {
      outFile f, *oSave;
      char nm[pathSize(y = cdr(x))];

      pathString(y, nm);
      if ((f.fd = open(nm, O_APPEND|O_CREAT|O_WRONLY, 0666)) < 0)
         openErr(ex, nm);
      f.ix = 0;
      f.tty = NO;
      putBin = putStdout;
      oSave = OutFile,  OutFile = &f;
      for (y = car(x); isCell(y); y = cdr(y))
         binPrint(0, car(y));
      flush(&f);
      close(f.fd);
      car(x) = Nil;
      OutFile = oSave;
   }
   if (Log) {
      for (F = 0; F < Files; ++F)
         if (dirty[F] && fsync(BlkFile[F]) < 0)
            fsyncErr(ex, "DB");
      fseek(Log, 0L, SEEK_SET);
      if (ftruncate(fileno(Log), 0))
         truncErr(ex);
   }
   rwUnlock(0);  // Unlock all
   unsync();
   if (!Log)
      --Env.protect;
   for (F = 0; F < Files; ++F)
      Fluse[F] = -1;
   drop(c1);
   return T;
}

// (rollback) -> flg
any doRollback(any x) {
   int i;
   any y, z;

   if (!Files && !isCell(val(Ext)))
      return Nil;
   for (i = 0; i < EHASH; ++i) {
      for (x = Extern[i];  isCell(x);  x = cdr(x)) {
         val(y = car(x)) = Nil;
         for (z = tail1(y); isCell(z); z = cdr(z));
         tail(y) = ext(z);
         z = numCell(z);
         while (isNum(cdr(z)))
            z = numCell(cdr(z));
         cdr(z) = Nil;
      }
   }
   if (isCell(x = val(Zap)))
      car(x) = Nil;
   if (Files)
      rwUnlock(0);  // Unlock all
   unsync();
   return T;
}

// (mark 'sym|0 ['NIL | 'T | '0]) -> flg
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
   NeedExt(ex,y);
   n = blk64(name(y));
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
   FILE *jnl = Jnl;
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
   ++Env.protect;
   wrLock();
   if (Jnl)
      lockFile(fileno(Jnl), F_SETLKW, F_WRLCK);
   blkPeek(0, buf, 2*BLK);  // Get Free, Next
   BlkLink = getAdr(buf);
   next = getAdr(buf+BLK);
   Jnl = NULL;
   while (BlkLink) {  // Check free list
      rdBlock(BlkLink);
      if ((cnt += BLKSIZE) > next) {
         x = mkStr("Circular free list");
         goto done;
      }
      Block[0] |= TAGMASK,  wrBlock();  // Mark free list
   }
   Jnl = jnl;
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
         for (i = 2;  BlkLink;  cnt += BLKSIZE) {
            ++blks;
            rdBlock(BlkLink);
            if ((Block[0] & TAGMASK) != i) {
               x = mkStr("Bad chain");
               goto done;
            }
            if (i < TAGMASK)
               ++i;
         }
      }
   }
   BlkLink = getAdr(buf);  // Unmark free list
   Jnl = NULL;
   while (BlkLink) {
      rdBlock(BlkLink);
      if (Block[0] & TAGMASK)
         Block[0] &= BLKMASK,  wrBlock();
   }
   if (cnt != next)
      x = mkStr("Bad count");
   else if (!flg)
      x = Nil;
   else {
      Push(c1, boxWord2(syms));
      data(c1) = cons(boxWord2(blks), data(c1));
      x = Pop(c1);
   }
done:
   if (Jnl = jnl)
      fflush(Jnl),  lockFile(fileno(Jnl), F_SETLK, F_UNLCK);
   rwUnlock(1);
   --Env.protect;
   return x;
}
