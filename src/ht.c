/* 19oct04abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

static byte *HtOK[] = {
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

static bool findHtOK(byte *s) {
   byte **p, *q, *t;

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
      if (isNum(y = EVAL(car(x))) || isExt(y))
         prin(y);
      else {
         byte *p, *q, nm[bufSize(y)];

         bufString(y, nm);
         for (p = nm; *p;) {
            if (findHtOK(p) && (q = strchr(p,'>')))
               do
                  Env.put(*p++);
               while (p <= q);
            else {
               switch (*p) {
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
               default:
                  Env.put(*p);
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

static void htEncode(byte *p) {
   while (*p) {
      if (strchr(" \"#%&=?_", *p))
         Env.put('%'), putHex(*p++);
      else
         Env.put(*p++);
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
      if (isExt(x))
         Env.put('.'),  outName(x);
      else {
         byte nm[bufSize(x)];

         bufString(x, nm);
         if (hashed(x, hash(y), Intern))
            Env.put('$'),  htEncode(nm);
         else if (strchr("$+.", *nm)) {
            Env.put('%'), putHex(*nm);
            htEncode(nm+1);
         }
         else
            htEncode(nm);
      }
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
