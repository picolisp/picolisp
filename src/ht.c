/* 28may03abu
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
         int len = bufSize(y);
         byte *p, *q, nm[len];

         bufString(y, nm);
         for (p = nm; p < nm + len;) {
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

static void htEncode(any x) {
   byte *p, nm[bufSize(x)];

   bufString(x, nm);
   for (p = nm; *p; ++p) {
      if (strchr(" \"%&()=?[]_{}", *p))
         Env.put('%'), putHex(*p);
      else
         Env.put(*p);
   }
}

static void htFmt(any x) {
   any y;

   if (isNum(x) || isExt(x))
      prin(x);
   else if (isCell(x)) {
      Env.put('(');
      for (;;) {
         htFmt(car(x));
         if (isCell(x = cdr(x)))
            Env.put('_');
         else
            break;
      }
      Env.put(')');
   }
   else if (isNum(y = name(x))) {
      if (findHash(y, Intern + hash(y)))
         Env.put('['),  htEncode(x),  Env.put(']');
      else
         htEncode(x);
   }
}

// (ht:Fmt 'any ..) -> sym
any Fmt(any x) {
   cell c1;

   begString();
   while (isCell(x = cdr(x))) {
      Push(c1, EVAL(car(x)));
      htFmt(data(c1));
      if (isCell(cdr(x)))
         Env.put('&');
      drop(c1);
   }
   return endString();
}

// (ht:Pack 'lst) -> sym
any Pack(any x) {
   int c;
   cell c1;

   begString();
   Push(c1, x = EVAL(cadr(x)));
   while (isCell(x)) {
      if ((c = symChar(name(car(x)))) == '%')
         x = cdr(x),  Env.put(getHex(&x));
      else
         outName(car(x)), x = cdr(x);
   }
   drop(c1);
   return endString();
}
