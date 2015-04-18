/* 25feb15abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

#define MAX    MASK           // Max digit size    0xFFFF....
#define OVFL   ((1<<BITS-1))  // Carry/Overflow    0x8000....


static void divErr(any ex) {err(ex,NULL,"Div/0");}

/* Box double word */
any boxWord2(word2 t) {
   cell c1;

   Push(c1, hi(t)? consNum(num(t), box(hi(t))) : box(num(t)));
   digMul2(data(c1));
   return Pop(c1);
}

word2 unBoxWord2(any x) {
   word2 n = unDig(x);

   if (isNum(x = cdr(numCell(x))))
      n = n << BITS + unDig(x);
   return n / 2;
}

/* Bignum copy */
any bigCopy(any x) {
   any y;
   cell c1, c2;

   Push(c1, x);
   Push(c2, y = box(unDig(x)));
   while (isNum(x = cdr(numCell(x))))
      y = cdr(numCell(y)) = box(unDig(x));
   drop(c1);
   return data(c2);
}

/* Remove leading zero words */
void zapZero(any x) {
   any r = x;

   while (isNum(x = cdr(numCell(x))))
      if (unDig(x))
         r = x;
   cdr(numCell(r)) = x;
}

/* Multiply a (positive) bignum by 2 */
void digMul2(any x) {
   any y;
   word n, carry;

   n = unDig(x),  setDig(x, n + n),  carry = n & OVFL;
   while (isNum(x = cdr(numCell(y = x)))) {
      n = unDig(x);
      setDig(x, n + n + (carry? 1 : 0));
      carry = n & OVFL;
   }
   if (carry)
      cdr(numCell(y)) = box(1);
}

/* Shift right by one bit */
void digDiv2(any x) {
   any r, y;

   r = NULL;
   setDig(x, unDig(x) / 2);
   while (isNum(x = cdr(numCell(y = x)))) {
      if (unDig(x) & 1)
         setDig(y, unDig(y) | OVFL);
      setDig(x, unDig(x) / 2);
      r = y;
   }
   if (r  &&  unDig(y) == 0)
      cdr(numCell(r)) = x;
}

/* Add two (positive) bignums */
void bigAdd(any dst, any src) {
   any x;
   word n, carry;

   carry = (unDig(src) & ~1) > num(setDig(dst, (unDig(src) & ~1) + (unDig(dst) & ~1)));
   src = cdr(numCell(src));
   dst = cdr(numCell(x = dst));
   for (;;) {
      if (!isNum(src)) {
         while (isNum(dst)) {
            if (!carry)
               return;
            carry = 0 == num(setDig(dst, 1 + unDig(dst)));
            dst = cdr(numCell(x = dst));
         }
         break;
      }
      if (!isNum(dst)) {
         do {
            carry = unDig(src) > (n = carry + unDig(src));
            x = cdr(numCell(x)) = box(n);
         } while (isNum(src = cdr(numCell(src))));
         break;
      }
      if ((n = carry + unDig(src)) >= carry) {
         carry = unDig(dst) > (n += unDig(dst));
         setDig(dst,n);
      }
      src = cdr(numCell(src));
      dst = cdr(numCell(x = dst));
   }
   if (carry)
      cdr(numCell(x)) = box(1);
}

/* Add digit to a (positive) bignum */
void digAdd(any x, word n) {
   any y;
   word carry;

   carry = n > num(setDig(x, n + unDig(x)));
   while (carry) {
      if (isNum(x = cdr(numCell(y = x))))
         carry = 0 == num(setDig(x, 1 + unDig(x)));
      else {
         cdr(numCell(y)) = box(1);
         break;
      }
   }
}

/* Subtract two (positive) bignums */
void bigSub(any dst, any src) {
   any x, y;
   word n, borrow;

   borrow = MAX - (unDig(src) & ~1) < num(setDig(dst, (unDig(dst) & ~1) - (unDig(src) & ~1)));
   y = dst;
   for (;;) {
      src = cdr(numCell(src));
      dst = cdr(numCell(x = dst));
      if (!isNum(src)) {
         while (isNum(dst)) {
            if (!borrow)
               return;
            borrow = MAX == num(setDig(dst, unDig(dst) - 1));
            dst = cdr(numCell(x = dst));
         }
         break;
      }
      if (!isNum(dst)) {
         do {
            if (borrow)
               n = MAX - unDig(src);
            else
               borrow = 0 != (n = -unDig(src));
            x = cdr(numCell(x)) = box(n);
         } while (isNum(src = cdr(numCell(src))));
         break;
      }
      if ((n = unDig(dst) - borrow) > MAX - borrow)
         setDig(dst, MAX - unDig(src));
      else
         borrow = num(setDig(dst, n - unDig(src))) > MAX - unDig(src);
   }
   if (borrow) {
      dst = y;
      borrow = 0 != (n = -unDig(dst));
      setDig(dst, n | 1);  /* Negate */
      while (dst != x) {
         dst = cdr(numCell(dst));
         if (borrow)
            setDig(dst, MAX - unDig(dst));
         else
            borrow = 0 != num(setDig(dst, -unDig(dst)));
      }
   }
   if (unDig(x) == 0)
      zapZero(y);
}

/* Subtract 1 from a (positive) bignum */
void digSub1(any x) {
   any r, y;
   word borrow;

   r = NULL;
   borrow = MAX-1 == num(setDig(x, unDig(x) - 2));
   while (isNum(x = cdr(numCell(y = x)))) {
      if (!borrow)
         return;
      borrow = MAX == num(setDig(x, unDig(x) - 1));
      r = y;
   }
   if (r  &&  unDig(y) == 0)
      cdr(numCell(r)) = x;
}

/* Multiply two (positive) bignums */
static any bigMul(any x1, any x2) {
   any x, y, z;
   word n, carry;
   word2 t;
   cell c1;

   Push(c1, x = y = box(0));
   for (;;) {
      n = unDig(x2) / 2;
      if (isNum(x2 = cdr(numCell(x2)))  &&  unDig(x2) & 1)
         n |= OVFL;
      t = (word2)n * unDig(z = x1);  // x += n * x1
      carry = (lo(t) > num(setDig(y, unDig(y) + lo(t)))) + hi(t);
      while (isNum(z = cdr(numCell(z)))) {
         if (!isNum(cdr(numCell(y))))
            cdr(numCell(y)) = box(0);
         y = cdr(numCell(y));
         t = (word2)n * unDig(z);
         carry = carry > num(setDig(y, carry + unDig(y)));
         if (lo(t) > num(setDig(y, unDig(y) + lo(t))))
            ++carry;
         carry += hi(t);
      }
      if (carry)
         cdr(numCell(y)) = box(carry);
      if (!isNum(x2))
         break;
      if (!isNum(y = cdr(numCell(x))))
         y = cdr(numCell(x)) = box(0);
      x = y;
   } while (isNum(x2));
   zapZero(data(c1));
   return Pop(c1);
}

/* Multiply digit with a (positive) bignum */
void digMul(any x, word n) {
   word2 t;
   any y;

   t = (word2)n * unDig(x);
   for (;;) {
      setDig(x, num(t));
      t = hi(t);
      if (!isNum(x = cdr(numCell(y = x))))
         break;
      t += (word2)n * unDig(x);
   }
   if (t)
      cdr(numCell(y)) = box(num(t));
}

/* (Positive) Bignum comparison */
static int bigCmp(any x, any y) {
   int res;
   any x1, y1, x2, y2;

   x1 = y1 = Nil;
   for (;;) {
      if ((x2 = cdr(numCell(x))) == (y2 = cdr(numCell(y)))) {
         for (;;) {
            if (unDig(x) < unDig(y)) {
               res = -1;
               break;
            }
            if (unDig(x) > unDig(y)) {
               res = +1;
               break;
            }
            if (!isNum(x1))
               return 0;
            x2 = cdr(numCell(x1)),  cdr(numCell(x1)) = x,  x = x1,  x1 = x2;
            y2 = cdr(numCell(y1)),  cdr(numCell(y1)) = y,  y = y1,  y1 = y2;
         }
         break;
      }
      if (!isNum(x2)) {
         res = -1;
         break;
      }
      if (!isNum(y2)) {
         res = +1;
         break;
      }
      cdr(numCell(x)) = x1,  x1 = x,  x = x2;
      cdr(numCell(y)) = y1,  y1 = y,  y = y2;
   }
   while (isNum(x1)) {
      x2 = cdr(numCell(x1)),  cdr(numCell(x1)) = x,  x = x1,  x1 = x2;
      y2 = cdr(numCell(y1)),  cdr(numCell(y1)) = y,  y = y1,  y1 = y2;
   }
   return res;
}

/* Divide two (positive) bignums (Knuth Vol.2, p.257) */
static any bigDiv(any u, any v, bool rem) {
   int m, n, d, i;
   word q, v1, v2, u1, u2, u3, borrow;
   word2 t, r;
   any x, y, z;
   cell c1;

   digDiv2(u),  digDiv2(v);                                 // Normalize
   for (m = 0, z = u;  isNum(y = cdr(numCell(z)));  ++m, z = y);
   x = v,  y = NULL,  n = 1;
   while (isNum(cdr(numCell(x))))
      y = x,  x = cdr(numCell(x)),  ++n,  --m;
   if (m < 0) {
      if (rem)
         digMul2(u);
      return box(0);
   }
   cdr(numCell(z)) = box(0);
   for (d = 0;  (unDig(x) & OVFL) == 0;  ++d)
      digMul2(u),  digMul2(v);
   v1 = unDig(x);
   v2 = y? unDig(y) : 0;
   Push(c1, Nil);
   do {
      for (i = m, x = u;  --i >= 0;  x = cdr(numCell(x)));  // Index x -> u
      i = n;
      y = x;
      u1 = u2 = 0;
      do
         u3 = u2,  u2 = u1,  u1 = unDig(y),  y = cdr(numCell(y));
      while (--i >= 0);

      t = ((word2)u1 << BITS) + u2;                         // Calculate q
      q = u1 == v1? MAX : t / v1;
      r = t - (word2)q*v1;
      while (r <= MAX  &&  (word2)q*v2 > (r << BITS) + u3)
         --q,  r += v1;

      z = x;                                                // x -= q*v
      t = (word2)q * unDig(y = v);
      borrow = (MAX - lo(t) < num(setDig(z, unDig(z) - lo(t)))) + hi(t);
      while (isNum(y = cdr(numCell(y)))) {
         z = cdr(numCell(z));
         t = (word2)q * unDig(y);
         borrow = MAX - borrow < num(setDig(z, unDig(z) - borrow));
         if (MAX - lo(t) < num(setDig(z, unDig(z) - lo(t))))
            ++borrow;
         borrow += hi(t);
      }
      if (borrow) {
         z = cdr(numCell(z));
         if (MAX - borrow < num(setDig(z, unDig(z) - borrow))) {
            word n, carry;                                  // x += v

            --q;
            if (m || rem) {
               y = v;
               carry = unDig(y) > num(setDig(x, unDig(y) + unDig(x)));
               while (x = cdr(numCell(x)),  isNum(y = cdr(numCell(y)))) {
                  if ((n = carry + unDig(y)) >= carry) {
                     carry = unDig(x) > (n += unDig(x));
                     setDig(x,n);
                  }
               }
               setDig(x, carry + unDig(x));
            }
         }
      }
      data(c1) = consNum(q, data(c1));                      // Store result
   } while (--m >= 0);
   if (!rem)
      zapZero(data(c1)),  digMul2(data(c1));
   else {
      zapZero(u);
      if (!d)
         digMul2(u);
      else
         while (--d)
            digDiv2(u);
   }
   return Pop(c1);
}

/* Compare two numbers */
int bigCompare(any x, any y) {
   if (isNeg(x)) {
      if (!isNeg(y))
         return -1;
      return bigCmp(y,x);
   }
   if (isNeg(y))
      return +1;
   return bigCmp(x,y);
}

/* Make number from symbol */
any symToNum(any s, int scl, int sep, int ign) {
   unsigned c;
   bool sign, frac;
   cell c1, c2;

   if (!(c = symByte(s)))
      return NULL;
   while (c <= ' ')  /* Skip white space */
      if (!(c = symByte(NULL)))
         return NULL;
   sign = NO;
   if (c == '+'  ||  c == '-' && (sign = YES))
      if (!(c = symByte(NULL)))
         return NULL;
   if ((c -= '0') > 9)
      return NULL;
   frac = NO;
   Push(c1, s);
   Push(c2, box(c+c));
   while ((c = symChar(NULL))  &&  (!frac || scl)) {
      if ((int)c == sep) {
         if (frac) {
            drop(c1);
            return NULL;
         }
         frac = YES;
      }
      else if ((int)c != ign) {
         if ((c -= '0') > 9) {
            drop(c1);
            return NULL;
         }
         digMul(data(c2), 10);
         digAdd(data(c2), c+c);
         if (frac)
            --scl;
      }
   }
   if (c) {
      if ((c -= '0') > 9) {
         drop(c1);
         return NULL;
      }
      if (c >= 5)
         digAdd(data(c2), 2);
      while (c = symByte(NULL)) {
         if ((c -= '0') > 9) {
            drop(c1);
            return NULL;
         }
      }
   }
   if (frac)
      while (--scl >= 0)
         digMul(data(c2), 10);
   if (sign && !IsZero(data(c2)))
      neg(data(c2));
   drop(c1);
   return data(c2);
}

/* Buffer size calculation */
static inline int numlen(any x) {
   int n = 10;
   while (isNum(x = cdr(numCell(x))))
      n += 10;
   return (n + 8) / 9;
}

/* Make symbol from number */
any numToSym(any x, int scl, int sep, int ign) {
   int i;
   bool sign;
   cell c1;
   word n = numlen(x);
   word c, *p, *q, *ta, *ti, acc[n], inc[n];
   char *b, buf[10];

   sign = isNeg(x);
   *(ta = acc) = 0;
   *(ti = inc) = 1;
   n = 2;
   for (;;) {
      do {
         if (unDig(x) & n) {
            c = 0,  p = acc,  q = inc;
            do {
               if (ta < p)
                  *++ta = 0;
               if (c = (*p += *q + c) > 999999999)
                  *p -= 1000000000;
            } while (++p, ++q <= ti);
            if (c)
               *p = 1,  ++ta;
         }
         c = 0,  q = inc;
         do
            if (c = (*q += *q + c) > 999999999)
               *q -= 1000000000;
         while (++q <= ti);
         if (c)
            *q = 1,  ++ti;
      } while (n <<= 1);
      if (!isNum(x = cdr(numCell(x))))
         break;
      n = 1;
   }
   n = (ta - acc) * 9;
   n += sprintf(b = buf, "%ld", *ta--);
   if (sep < 0)
      return boxCnt(n + sign);
   i = -8,  Push(c1, x = box(0));
   if (sign)
      byteSym('-', &i, &x);
   if ((scl = n - scl - 1) < 0) {
      byteSym('0', &i, &x);
      charSym(sep, &i, &x);
      while (scl < -1)
         byteSym('0', &i, &x),  ++scl;
   }
   for (;;) {
      byteSym(*b++, &i, &x);
      if (!*b) {
         if (ta < acc)
            return consStr(Pop(c1));
         sprintf(b = buf, "%09ld", *ta--);
      }
      if (scl == 0)
         charSym(sep, &i, &x);
      else if (ign  &&  scl > 0  &&  scl % 3 == 0)
         charSym(ign, &i, &x);
      --scl;
   }
}

#define DMAX ((double)((word2)MASK+1))

/* Make number from double */
any doubleToNum(double d) {
   bool sign;
   any x;
   cell c1;

   if (isnan(d) || isinf(d) < 0)
      return Nil;
   if (isinf(d) > 0)
      return T;
   sign = NO;
   if (d < 0.0)
      sign = YES,  d = -d;
   d += 0.5;
   Push(c1, x = box((word)fmod(d,DMAX)));
   while (d > DMAX)
      x = cdr(numCell(x)) = box((word)fmod(d /= DMAX, DMAX));
   digMul2(data(c1));
   if (sign && !IsZero(data(c1)))
      neg(data(c1));
   return Pop(c1);
}

/* Make double from number */
double numToDouble(any x) {
   double d, m;
   bool sign;

   sign = isNeg(x);
   d = (double)(unDig(x) / 2),  m = DMAX/2.0;
   while (isNum(x = cdr(numCell(x))))
      d += m * (double)unDig(x),  m *= DMAX;
   return sign? -d : d;
}

// (format 'num ['cnt ['sym1 ['sym2]]]) -> sym
// (format 'sym|lst ['cnt ['sym1 ['sym2]]]) -> num
any doFormat(any ex) {
   int scl, sep, ign;
   any x, y;
   cell c1;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   x = cdr(x),  y = EVAL(car(x));
   scl = isNil(y)? 0 : xCnt(ex, y);
   sep = '.';
   ign = 0;
   if (isCell(x = cdr(x))) {
      y = EVAL(car(x));
      NeedSym(ex,y);
      sep = symChar(name(y));
      if (isCell(x = cdr(x))) {
         y = EVAL(car(x));
         NeedSym(ex,y);
         ign = symChar(name(y));
      }
   }
   if (isNum(data(c1)))
      data(c1) = numToSym(data(c1), scl, sep, ign);
   else {
      int i;
      any nm;
      cell c2;

      if (isSym(data(c1)))
         nm = name(data(c1));
      else {
         nm = NULL,  pack(data(c1), &i, &nm, &c2);
         nm = nm? data(c2) : Nil;
      }
      data(c1) = symToNum(nm, scl, sep, ign) ?: Nil;
   }
   return Pop(c1);
}

// (+ 'num ..) -> num
any doAdd(any ex) {
   any x;
   cell c1, c2;

   x = cdr(ex);
   if (isNil(data(c1) = EVAL(car(x))))
      return Nil;
   NeedNum(ex,data(c1));
   Push(c1, bigCopy(data(c1)));
   while (isCell(x = cdr(x))) {
      Push(c2, EVAL(car(x)));
      if (isNil(data(c2))) {
         drop(c1);
         return Nil;
      }
      NeedNum(ex,data(c2));
      if (isNeg(data(c1))) {
         if (isNeg(data(c2)))
            bigAdd(data(c1),data(c2));
         else
            bigSub(data(c1),data(c2));
         if (!IsZero(data(c1)))
            neg(data(c1));
      }
      else if (isNeg(data(c2)))
         bigSub(data(c1),data(c2));
      else
         bigAdd(data(c1),data(c2));
      drop(c2);
   }
   return Pop(c1);
}

// (- 'num ..) -> num
any doSub(any ex) {
   any x;
   cell c1, c2;

   x = cdr(ex);
   if (isNil(data(c1) = EVAL(car(x))))
      return Nil;
   NeedNum(ex,data(c1));
   if (!isCell(x = cdr(x)))
      return IsZero(data(c1))?
            data(c1) : consNum(unDig(data(c1)) ^ 1, cdr(numCell(data(c1))));
   Push(c1, bigCopy(data(c1)));
   do {
      Push(c2, EVAL(car(x)));
      if (isNil(data(c2))) {
         drop(c1);
         return Nil;
      }
      NeedNum(ex,data(c2));
      if (isNeg(data(c1))) {
         if (isNeg(data(c2)))
            bigSub(data(c1),data(c2));
         else
            bigAdd(data(c1),data(c2));
         if (!IsZero(data(c1)))
            neg(data(c1));
      }
      else if (isNeg(data(c2)))
         bigAdd(data(c1),data(c2));
      else
         bigSub(data(c1),data(c2));
      drop(c2);
   } while (isCell(x = cdr(x)));
   return Pop(c1);
}

// (inc 'num) -> num
// (inc 'var ['num]) -> num
any doInc(any ex) {
   any x;
   cell c1, c2;

   x = cdr(ex);
   if (isNil(data(c1) = EVAL(car(x))))
      return Nil;
   if (isNum(data(c1))) {
      Push(c1, bigCopy(data(c1)));
      if (!isNeg(data(c1)))
         digAdd(data(c1), 2);
      else {
         pos(data(c1)), digSub1(data(c1)), neg(data(c1));
         if (unDig(data(c1)) == 1  &&  !isNum(cdr(numCell(data(c1)))))
            setDig(data(c1), 0);
      }
      return Pop(c1);
   }
   CheckVar(ex,data(c1));
   if (isSym(data(c1)))
      Touch(ex,data(c1));
   if (!isCell(x = cdr(x))) {
      if (isNil(val(data(c1))))
         return Nil;
      NeedNum(ex,val(data(c1)));
      Save(c1);
      val(data(c1)) = bigCopy(val(data(c1)));
      if (!isNeg(val(data(c1))))
         digAdd(val(data(c1)), 2);
      else {
         pos(val(data(c1))), digSub1(val(data(c1))), neg(val(data(c1)));
         if (unDig(val(data(c1))) == 1  &&  !isNum(cdr(numCell(val(data(c1))))))
            setDig(val(data(c1)), 0);
      }
   }
   else {
      Save(c1);
      Push(c2, EVAL(car(x)));
      if (isNil(val(data(c1))) || isNil(data(c2))) {
         drop(c1);
         return Nil;
      }
      NeedNum(ex,val(data(c1)));
      val(data(c1)) = bigCopy(val(data(c1)));
      NeedNum(ex,data(c2));
      if (isNeg(val(data(c1)))) {
         if (isNeg(data(c2)))
            bigAdd(val(data(c1)),data(c2));
         else
            bigSub(val(data(c1)),data(c2));
         if (!IsZero(val(data(c1))))
            neg(val(data(c1)));
      }
      else if (isNeg(data(c2)))
         bigSub(val(data(c1)),data(c2));
      else
         bigAdd(val(data(c1)),data(c2));
   }
   return val(Pop(c1));
}

// (dec 'num) -> num
// (dec 'var ['num]) -> num
any doDec(any ex) {
   any x;
   cell c1, c2;

   x = cdr(ex);
   if (isNil(data(c1) = EVAL(car(x))))
      return Nil;
   if (isNum(data(c1))) {
      Push(c1, bigCopy(data(c1)));
      if (isNeg(data(c1)))
         digAdd(data(c1), 2);
      else if (IsZero(data(c1)))
         setDig(data(c1), 3);
      else
         digSub1(data(c1));
      return Pop(c1);
   }
   CheckVar(ex,data(c1));
   if (isSym(data(c1)))
      Touch(ex,data(c1));
   if (!isCell(x = cdr(x))) {
      if (isNil(val(data(c1))))
         return Nil;
      NeedNum(ex,val(data(c1)));
      Save(c1);
      val(data(c1)) = bigCopy(val(data(c1)));
      if (isNeg(val(data(c1))))
         digAdd(val(data(c1)), 2);
      else if (IsZero(val(data(c1))))
         setDig(val(data(c1)), 3);
      else
         digSub1(val(data(c1)));
   }
   else {
      Save(c1);
      Push(c2, EVAL(car(x)));
      if (isNil(val(data(c1))) || isNil(data(c2))) {
         drop(c1);
         return Nil;
      }
      NeedNum(ex,val(data(c1)));
      val(data(c1)) = bigCopy(val(data(c1)));
      NeedNum(ex,data(c2));
      if (isNeg(val(data(c1)))) {
         if (isNeg(data(c2)))
            bigSub(val(data(c1)),data(c2));
         else
            bigAdd(val(data(c1)),data(c2));
         if (!IsZero(val(data(c1))))
            neg(val(data(c1)));
      }
      else if (isNeg(data(c2)))
         bigAdd(val(data(c1)),data(c2));
      else
         bigSub(val(data(c1)),data(c2));
   }
   return val(Pop(c1));
}

// (* 'num ..) -> num
any doMul(any ex) {
   any x;
   bool sign;
   cell c1, c2;

   x = cdr(ex);
   if (isNil(data(c1) = EVAL(car(x))))
      return Nil;
   NeedNum(ex,data(c1));
   Push(c1, bigCopy(data(c1)));
   sign = isNeg(data(c1)),  pos(data(c1));
   while (isCell(x = cdr(x))) {
      Push(c2, EVAL(car(x)));
      if (isNil(data(c2))) {
         drop(c1);
         return Nil;
      }
      NeedNum(ex,data(c2));
      sign ^= isNeg(data(c2));
      data(c1) = bigMul(data(c1),data(c2));
      drop(c2);
   }
   if (sign && !IsZero(data(c1)))
      neg(data(c1));
   return Pop(c1);
}

// (*/ 'num1 ['num2 ..] 'num3) -> num
any doMulDiv(any ex) {
   any x;
   bool sign;
   cell c1, c2, c3;

   x = cdr(ex);
   if (isNil(data(c1) = EVAL(car(x))))
      return Nil;
   NeedNum(ex,data(c1));
   Push(c1, bigCopy(data(c1)));
   sign = isNeg(data(c1)),  pos(data(c1));
   Push(c2, Nil);
   for (;;) {
      x = cdr(x),  data(c2) = EVAL(car(x));
      if (isNil(data(c2))) {
         drop(c1);
         return Nil;
      }
      NeedNum(ex,data(c2));
      sign ^= isNeg(data(c2));
      if (!isCell(cdr(x)))
         break;
      data(c1) = bigMul(data(c1),data(c2));
   }
   if (IsZero(data(c2)))
      divErr(ex);
   Push(c3, bigCopy(data(c2)));
   digDiv2(data(c3));
   bigAdd(data(c1),data(c3));
   data(c2) = bigCopy(data(c2));
   data(c1) = bigDiv(data(c1),data(c2),NO);
   if (sign && !IsZero(data(c1)))
      neg(data(c1));
   return Pop(c1);
}

// (/ 'num ..) -> num
any doDiv(any ex) {
   any x;
   bool sign;
   cell c1, c2;

   x = cdr(ex);
   if (isNil(data(c1) = EVAL(car(x))))
      return Nil;
   NeedNum(ex,data(c1));
   Push(c1, bigCopy(data(c1)));
   sign = isNeg(data(c1)),  pos(data(c1));
   while (isCell(x = cdr(x))) {
      Push(c2, EVAL(car(x)));
      if (isNil(data(c2))) {
         drop(c1);
         return Nil;
      }
      NeedNum(ex,data(c2));
      sign ^= isNeg(data(c2));
      if (IsZero(data(c2)))
         divErr(ex);
      data(c2) = bigCopy(data(c2));
      data(c1) = bigDiv(data(c1),data(c2),NO);
      drop(c2);
   }
   if (sign && !IsZero(data(c1)))
      neg(data(c1));
   return Pop(c1);
}

// (% 'num ..) -> num
any doRem(any ex) {
   any x;
   bool sign;
   cell c1, c2;

   x = cdr(ex);
   if (isNil(data(c1) = EVAL(car(x))))
      return Nil;
   NeedNum(ex,data(c1));
   Push(c1, bigCopy(data(c1)));
   sign = isNeg(data(c1)),  pos(data(c1));
   while (isCell(x = cdr(x))) {
      Push(c2, EVAL(car(x)));
      if (isNil(data(c2))) {
         drop(c1);
         return Nil;
      }
      NeedNum(ex,data(c2));
      if (IsZero(data(c2)))
         divErr(ex);
      data(c2) = bigCopy(data(c2));
      bigDiv(data(c1),data(c2),YES);
      drop(c2);
   }
   if (sign && !IsZero(data(c1)))
      neg(data(c1));
   return Pop(c1);
}

// (>> 'cnt 'num) -> num
any doShift(any ex) {
   any x;
   long n;
   bool sign;
   cell c1;

   x = cdr(ex),  n = evCnt(ex,x);
   x = cdr(x);
   if (isNil(data(c1) = EVAL(car(x))))
      return Nil;
   NeedNum(ex,data(c1));
   Push(c1, bigCopy(data(c1)));
   sign = isNeg(data(c1));
   if (n > 0) {
      do
         digDiv2(data(c1));
      while (--n);
      pos(data(c1));
   }
   else if (n < 0) {
      pos(data(c1));
      do
         digMul2(data(c1));
      while (++n);
   }
   if (sign && !IsZero(data(c1)))
      neg(data(c1));
   return Pop(c1);
}

// (lt0 'any) -> num | NIL
any doLt0(any x) {
   x = cdr(x);
   return isNum(x = EVAL(car(x))) && isNeg(x)? x : Nil;
}

// (le0 'any) -> num | NIL
any doLe0(any x) {
   x = cdr(x);
   return isNum(x = EVAL(car(x))) && (isNeg(x) || IsZero(x))? x : Nil;
}

// (ge0 'any) -> num | NIL
any doGe0(any x) {
   x = cdr(x);
   return isNum(x = EVAL(car(x))) && !isNeg(x)? x : Nil;
}

// (gt0 'any) -> num | NIL
any doGt0(any x) {
   x = cdr(x);
   return isNum(x = EVAL(car(x))) && !isNeg(x) && !IsZero(x)? x : Nil;
}

// (abs 'num) -> num
any doAbs(any ex) {
   any x;

   x = cdr(ex);
   if (isNil(x = EVAL(car(x))))
      return Nil;
   NeedNum(ex,x);
   if (!isNeg(x))
      return x;
   return consNum(unDig(x) & ~1, cdr(numCell(x)));
}

// (bit? 'num ..) -> num | NIL
any doBitQ(any ex) {
   any x, y, z;
   cell c1;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   NeedNum(ex,data(c1));
   if (isNeg(data(c1)))
      data(c1) = consNum(unDig(data(c1)) & ~1, cdr(numCell(data(c1))));
   while (isCell(x = cdr(x))) {
      if (isNil(z = EVAL(car(x)))) {
         drop(c1);
         return Nil;
      }
      NeedNum(ex,z);
      y = data(c1);
      if ((unDig(y) & unDig(z) & ~1) != unDig(y)) {
         drop(c1);
         return Nil;
      }
      for (;;) {
         if (!isNum(y = cdr(numCell(y))))
            break;
         if (!isNum(z = cdr(numCell(z)))) {
            drop(c1);
            return Nil;
         }
         if ((unDig(y) & unDig(z)) != unDig(y)) {
            drop(c1);
            return Nil;
         }
      }
   }
   return Pop(c1);
}

// (& 'num ..) -> num
any doBitAnd(any ex) {
   any x, y, z;
   cell c1;

   x = cdr(ex);
   if (isNil(data(c1) = EVAL(car(x))))
      return Nil;
   NeedNum(ex,data(c1));
   Push(c1, bigCopy(data(c1)));
   pos(data(c1));
   while (isCell(x = cdr(x))) {
      if (isNil(z = EVAL(car(x)))) {
         drop(c1);
         return Nil;
      }
      NeedNum(ex,z);
      y = data(c1);
      setDig(y, unDig(y) & unDig(z) & ~1);
      for (;;) {
         if (!isNum(z = cdr(numCell(z)))) {
            cdr(numCell(y)) = Nil;
            break;
         }
         if (!isNum(y = cdr(numCell(y))))
            break;
         setDig(y, unDig(y) & unDig(z));
      }
   }
   zapZero(data(c1));
   return Pop(c1);
}

// (| 'num ..) -> num
any doBitOr(any ex) {
   any x, y;
   cell c1, c2;

   x = cdr(ex);
   if (isNil(data(c1) = EVAL(car(x))))
      return Nil;
   NeedNum(ex,data(c1));
   Push(c1, bigCopy(data(c1)));
   pos(data(c1));
   while (isCell(x = cdr(x))) {
      if (isNil(data(c2) = EVAL(car(x)))) {
         drop(c1);
         return Nil;
      }
      NeedNum(ex,data(c2));
      y = data(c1);
      Save(c2);
      setDig(y, unDig(y) | unDig(data(c2)) & ~1);
      for (;;) {
         if (!isNum(data(c2) = cdr(numCell(data(c2)))))
            break;
         if (!isNum(cdr(numCell(y))))
            cdr(numCell(y)) = box(0);
         y = cdr(numCell(y));
         setDig(y, unDig(y) | unDig(data(c2)));
      }
      drop(c2);
   }
   return Pop(c1);
}

// (x| 'num ..) -> num
any doBitXor(any ex) {
   any x, y;
   cell c1, c2;

   x = cdr(ex);
   if (isNil(data(c1) = EVAL(car(x))))
      return Nil;
   NeedNum(ex,data(c1));
   Push(c1, bigCopy(data(c1)));
   pos(data(c1));
   while (isCell(x = cdr(x))) {
      if (isNil(data(c2) = EVAL(car(x)))) {
         drop(c1);
         return Nil;
      }
      NeedNum(ex,data(c2));
      y = data(c1);
      Save(c2);
      setDig(y, unDig(y) ^ unDig(data(c2)) & ~1);
      for (;;) {
         if (!isNum(data(c2) = cdr(numCell(data(c2)))))
            break;
         if (!isNum(cdr(numCell(y))))
            cdr(numCell(y)) = box(0);
         y = cdr(numCell(y));
         setDig(y, unDig(y) ^ unDig(data(c2)));
      }
      drop(c2);
   }
   zapZero(data(c1));
   return Pop(c1);
}

// (sqrt 'num ['flg|num]) -> num
any doSqrt(any ex) {
   any x, y, z;
   cell c1, c2, c3, c4, c5;

   x = cdr(ex);
   if (isNil(x = EVAL(car(x))))
      return Nil;
   NeedNum(ex,x);
   if (isNeg(x))
      argError(ex, x);
   Push(c1, x);  // num
   y = cddr(ex);
   Push(c2, y = EVAL(car(y)));  // flg|num
   if (isNum(y))
      x = data(c1) = bigMul(x, y);
   Push(c3, y = box(unDig(x)));  // Number copy
   Push(c4, z = box(2));  // Mask
   while (isNum(x = cdr(numCell(x)))) {
      y = cdr(numCell(y)) = box(unDig(x));
      data(c4) = consNum(0, data(c4));
   }
   while (unDig(y) >= unDig(z))
      if (!setDig(z, unDig(z) << 2)) {
         z = cdr(numCell(z)) = box(2);
         break;
      }
   Push(c5, box(0));  // Result
   do {
      bigAdd(data(c5),data(c4));
      if (bigCmp(data(c5),data(c3)) > 0)
         bigSub(data(c5),data(c4));
      else
         bigSub(data(c3),data(c5)),  bigAdd(data(c5),data(c4));
      digDiv2(data(c5));
      digDiv2(data(c4)),  digDiv2(data(c4));
   } while (!IsZero(data(c4)));
   if (!isNil(data(c2)) && bigCmp(data(c3),data(c5)) > 0)
      digAdd(data(c5), 2);
   drop(c1);
   return data(c5);
}

/* Random numbers */
static uint64_t Seed;

static uint64_t initSeed(any x) {
   uint64_t n;

   for (n = 0; isCell(x); x = cdr(x))
      n += initSeed(car(x));
   if (!isNil(x)) {
      if (isSym(x))
         x = name(x);
      do
         n += unDig(x);
      while (isNum(x = cdr(numCell(x))));
   }
   return n;
}

// (seed 'any) -> cnt
any doSeed(any ex) {
   return box(hi(Seed = initSeed(EVAL(cadr(ex))) * 6364136223846793005LL));
}

// (hash 'any) -> cnt
any doHash(any ex) {
   word2 n = initSeed(EVAL(cadr(ex)));
   int i = 64;
   int j = 0;

   do {
      if (((int)n ^ j) & 1)
         j ^= 0x14002;  /* CRC Polynom x**16 + x**15 + x**2 + 1 */
      n >>= 1,  j >>= 1;
   } while (--i);
   return box(2 * (j + 1));
}

// (rand ['cnt1 'cnt2] | ['T]) -> cnt | flg
any doRand(any ex) {
   any x;
   long n, m;

   x = cdr(ex);
   Seed = Seed * 6364136223846793005LL + 1;
   if (isNil(x = EVAL(car(x))))
      return box(hi(Seed));
   if (x == T)
      return hi(Seed) & 1 ? T : Nil;
   n = xCnt(ex,x);
   if (m = evCnt(ex, cddr(ex)) + 1 - n)
      n += hi(Seed) % m;
   return boxCnt(n);
}
