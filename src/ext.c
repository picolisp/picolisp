/* 12jul04abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

/*** Soundex Algorithm ***/
static int SnxTab[] = {
   '0', '1', '2', '3', '4', '5', '6', '7',  // 48
   '8', '9',   0,   0,   0,   0,   0,   0,
     0,   0, 'F', 'S', 'T',   0, 'F', 'S',  // 64
     0,   0, 'S', 'S', 'L', 'N', 'N',   0,
   'F', 'S', 'R', 'S', 'T',   0, 'F', 'F',
   'S',   0, 'S',   0,   0,   0,   0,   0,
     0,   0, 'F', 'S', 'T',   0, 'F', 'S',  // 96
     0,   0, 'S', 'S', 'L', 'N', 'N',   0,
   'F', 'S', 'R', 'S', 'T',   0, 'F', 'F',
   'S',   0, 'S',   0,   0,   0,   0,   0,
     0,   0,   0,   0,   0,   0,   0,   0,  // 128
     0,   0,   0,   0,   0,   0,   0,   0,
     0,   0,   0,   0,   0,   0,   0,   0,
     0,   0,   0,   0,   0,   0,   0,   0,
     0,   0,   0,   0,   0,   0,   0,   0,  // 160
     0,   0,   0,   0,   0,   0,   0,   0,
     0,   0,   0,   0,   0,   0,   0,   0,
     0,   0,   0,   0,   0,   0,   0,   0,
     0,   0,   0,   0,   0,   0,   0, 'S',  // 192
     0,   0,   0,   0,   0,   0,   0,   0,
   'T', 'N',   0,   0,   0,   0,   0, 'S',
     0,   0,   0,   0,   0,   0,   0, 'S',
     0,   0,   0,   0,   0,   0,   0, 'S',  // 224
     0,   0,   0,   0,   0,   0,   0,   0,
     0, 'N'
   // ...
};

#define SNXBASE   48
#define SNXSIZE   ((int)(sizeof(SnxTab) / sizeof(int)))


// (ext:Snx 'any ['cnt]) -> sym
any Snx(any ex) {
   int n, c, i, last;
   any x, nm;
   cell c1, c2;

   x = cdr(ex);
   if (!isSym(x = EVAL(car(x))) || !(c = symChar(name(x))))
      return Nil;
   while (c < SNXBASE)
      if (!(c = symChar(NULL)))
         return Nil;
   Push(c1, x);
   n = isCell(x = cddr(ex))? evCnt(ex,x) : 24;
   if (c >= 'a' && c <= 'z' || c == 128 || c >= (byte)224 && c < (byte)255)
      c &= ~0x20;
   Push(c2, boxChar(last = c, &i, &nm));
   while (c = symChar(NULL))
      if (c > ' ') {
         if ((c -= SNXBASE) < 0 || c >= SNXSIZE || !(c = SnxTab[c]))
            last = 0;
         else if (c != last) {
            if (!--n)
               break;
            charSym(last = c, &i, &nm);
         }
      }
   drop(c1);
   return consStr(data(c2));
}


/*** Math ***/
// (ext:Sin 'angle 'scale) -> num
any Sin(any ex) {
   any x;
   double a, n;

   a = evDouble(ex, x = cdr(ex));
   n = evDouble(ex, cdr(x));
   return doubleToNum(n * sin(a / n));
}

// (ext:Cos 'angle 'scale) -> num
any Cos(any ex) {
   any x;
   double a, n;

   a = evDouble(ex, x = cdr(ex));
   n = evDouble(ex, cdr(x));
   return doubleToNum(n * cos(a / n));
}

// (ext:Tan 'angle 'scale) -> num
any Tan(any ex) {
   any x;
   double a, n;

   a = evDouble(ex, x = cdr(ex));
   n = evDouble(ex, cdr(x));
   return doubleToNum(n * tan(a / n));
}

// (ext:Atan 'x 'y 'scale) -> num
any Atan(any ex) {
   double x, y, n;

   x = evDouble(ex, cdr(ex));
   y = evDouble(ex, cddr(ex));
   n = evDouble(ex, cdddr(ex));
   return doubleToNum(n * atan2(x / n, y / n));
}

// (ext:Dist 'h 'v ['h1 'h2 ['h2 'v2]]) -> num
any Dist(any ex) {
   any x;
   double h, v, h1, v1, h2, v2, a, ca, sa;

   h = evDouble(ex, x = cdr(ex));
   v = evDouble(ex, x = cdr(x));
   if (!isCell(x = cdr(x)))
      return doubleToNum(sqrt(h*h + v*v));
   h1 = evDouble(ex, x);
   v1 = evDouble(ex, x = cdr(x));
   if (!isCell(x = cdr(x))) {
      h -= h1,  v -= v1;
      return doubleToNum(sqrt(h*h + v*v));
   }
   h2 = evDouble(ex, x);
   v2 = evDouble(ex, cdr(x));
   h -= h2,  h1 -= h2;
   v -= v2,  v1 -= v2;
   a = atan2(h1,v1),  ca = cos(a),  sa = sin(a);
   a = h * ca - v * sa,  v = v * ca + h * sa,  h = a;
   v1 = v1 * ca + h1 * sa;
   if (v >= 0.0  &&  v <= v1)
      return doubleToNum(fabs(h));
   if (v > 0.0)
      v -= v1;
   return doubleToNum(sqrt(h*h + v*v));
}

/*** U-Law Encoding ***/
#define BIAS   132
#define CLIP   (32767-BIAS)

// (ext:Ulaw 'cnt) -> cnt  # SEEEMMMM
any Ulaw(any ex) {
   int val, sign, tmp, exp;

   val = (int)evCnt(ex,cdr(ex));
   sign = 0;
   if (val < 0)
      val = -val,  sign = 0x80;
   if (val > CLIP)
      val = CLIP;
   tmp = (val += BIAS) << 1;
   for (exp = 7;  exp > 0  &&  !(tmp & 0x8000);  --exp, tmp <<= 1);
   return boxCnt(~(sign  |  exp<<4  |  val >> exp+3 & 0x000F) & 0xFF);
}
