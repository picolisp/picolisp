/* 20sep07abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

static char *HtOK[] = {
   "<b>",      "</b>",
   "<i>",      "</i>",
   "<u>",      "</u>",
   "<p>",      "</p>",
   "<pre>",    "</pre>",
   "<div ",    "</div>",
   "<font ",   "</font>",
   "<img ",    "</img>",
   "<br>", "<hr>", NULL
};

static bool findHtOK(char *s) {
   char **p, *q, *t;

   for (p = HtOK; *p; ++p)
      for (q = *p,  t = s;;) {
         if (*q != *t)
            break;
         if (*++q == '\0')
            return YES;
         if (*++t == '\0')
            break;
      }
   return NO;
}

// (ht:Prin 'sym ..) -> T
any Prin(any x) {
   any y;

   while (isCell(x = cdr(x))) {
      if (isNum(y = EVAL(car(x))) || isCell(y) || isExt(y))
         prin(y);
      else {
         int c;
         char *p, *q, nm[bufSize(y)];

         bufString(y, nm);
         for (p = nm; *p;) {
            if (findHtOK(p) && (q = strchr(p,'>')))
               do
                  Env.put(*p++);
               while (p <= q);
            else {
               switch (*(byte*)p) {
               case '<':
                  outString("&lt;");
                  break;
               case '>':
                  outString("&gt;");
                  break;
               case '&':
                  outString("&amp;");
                  break;
               case '"':
                  outString("&quot;");
                  break;
               case 0xFF:
                  Env.put(0xEF);
                  Env.put(0xBF);
                  Env.put(0xBF);
                  break;
               default:
                  Env.put(c = *p);
                  if ((c & 0x80) != 0) {
                     Env.put(*++p);
                     if ((c & 0x20) != 0)
                        Env.put(*++p);
                  }
               }
               ++p;
            }
         }
      }
   }
   return T;
}

static void putHex(int c) {
   int n;

   if ((n = c >> 4 & 0xF) > 9)
      n += 7;
   Env.put(n + '0');
   if ((n = c & 0xF) > 9)
      n += 7;
   Env.put(n + '0');
}

static int getHex(any *p) {
   int n, m;

   n = firstByte(car(*p)),  *p = cdr(*p);
   if ((n -= '0') > 9)
      n -= 7;
   m = firstByte(car(*p)),  *p = cdr(*p);
   if ((m -= '0') > 9)
      m -= 7;
   return n << 4 | m;
}

static void htEncode(char *p) {
	int c;

   while (c = *p++) {
      if (strchr(" \"#%&:;<=>?_", c))
         Env.put('%'), putHex(c);
      else {
         Env.put(c);
         if ((c & 0x80) != 0) {
            Env.put(*p++);
            if ((c & 0x20) != 0)
               Env.put(*p++);
         }
      }
   }
}

static void htFmt(any x) {
   any y;

   if (isNum(x))
      Env.put('+'),  prin(x);
   else if (isCell(x))
      do
         Env.put('_'),  htFmt(car(x));
      while (isCell(x = cdr(x)));
   else if (isNum(y = name(x))) {
      char nm[bufSize(x)];

      bufString(x, nm);
      if (isExt(x))
         Env.put('-'),  htEncode(nm);
      else if (hashed(x, hash(y), Intern))
         Env.put('$'),  htEncode(nm);
      else if (strchr("$+.", *nm)) {
         Env.put('%'), putHex(*nm);
         htEncode(nm+1);
      }
      else
         htEncode(nm);
   }
}

// (ht:Fmt 'any ..) -> sym
any Fmt(any x) {
   int n, i;
   cell c[length(x = cdr(x))];

   for (n = 0;  isCell(x);  ++n, x = cdr(x))
      Push(c[n], EVAL(car(x)));
   begString();
   for (i = 0; i < n;) {
      htFmt(data(c[i]));
      if (++i != n)
         Env.put('&');
   }
   x = endString();
   if (n)
      drop(c[0]);
   return x;
}

// (ht:Pack 'lst) -> sym
any Pack(any x) {
   int c;
   cell c1;

   x = EVAL(cadr(x));
   begString();
   Push(c1,x);
   while (isCell(x)) {
      if ((c = symChar(name(car(x)))) == '%')
         x = cdr(x),  Env.put(getHex(&x));
      else
         outName(car(x)), x = cdr(x);
   }
   return endString();
}

/*** Chunked Encoding ***/
#define CHUNK 4000
static int Cnt;
static void (*Get)(void);
static void (*Put)(int);
static char Chunk[CHUNK];

static int chrHex(void) {
   if (Chr >= '0' && Chr <= '9')
      return Chr - 48;
   else if (Chr >= 'A' && Chr <= 'F')
      return Chr - 55;
   else if (Chr >= 'a' && Chr <= 'f')
      return Chr - 87;
   else
      return -1;
}

static void chunkSize(void) {
   int n;

   if (!Chr)
      Get();
   if ((Cnt = chrHex()) >= 0) {
      while (Get(), (n = chrHex()) >= 0)
         Cnt = Cnt << 4 | n;
      while (Chr != '\n') {
         if (Chr < 0)
            return;
         Get();
      }
      Get();
      if (Cnt == 0) {
         Get();  // Skip '\r' of empty line
         Chr = 0;  // Discard '\n'
      }
   }
}

static void getChunked(void) {
   if (Cnt <= 0)
      Chr = -1;
   else {
      Get();
      if (--Cnt == 0) {
         Get(), Get();  // Skip '\n', '\r'
         chunkSize();
      }
   }
}

// (ht:In 'flg . prg) -> any
any In(any x) {
   x = cdr(x);
   if (isNil(EVAL(car(x))))
      return prog(cdr(x));
   Get = Env.get,  Env.get = getChunked;
   chunkSize();
   x = prog(cdr(x));
   Env.get = Get;
   Chr = 0;
   return x;
}

static void wrChunk(void) {
   int i;
   char buf[16];

   sprintf(buf, "%x\r\n", Cnt);
   i = 0;
   do
      Put(buf[i]);
   while (buf[++i]);
   for (i = 0; i < Cnt; ++i)
      Put(Chunk[i]);
   Put('\r'), Put('\n');
}

static void putChunked(int c) {
   Chunk[Cnt++] = c;
   if (Cnt == CHUNK)
      wrChunk(),  Cnt = 0;
}

// (ht:Out 'flg . prg) -> any
any Out(any x) {
   x = cdr(x);
   if (isNil(EVAL(car(x))))
      x = prog(cdr(x));
   else {
      Cnt = 0;
      Put = Env.put,  Env.put = putChunked;
      x = prog(cdr(x));
      if (Cnt)
         wrChunk();
      Env.put = Put;
      outString("0\r\n\r\n");
   }
   flush(OutFile);
   return x;
}
