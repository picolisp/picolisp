/* 28feb03abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

#define MAX       num(-1)           /* Maximal digit size */

#define lo(t)     num((t) & 0xFFFFFFFF)
#define hi(t)     num((t) >> 32)

static void divErr(any ex) {err(ex,NULL,"Div/0");}

/* Box double word */
any boxWord2(word2 t) {
   cell c1;

   Push(c1, box(lo(t)));
   if (hi(t))
      data(c1) = cons(box(hi(t)), data(c1));
   digMul2(data(c1));
   return Pop(c1);
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

   n = unDig(x),  carry = n > setDig(x, n + n);
   while (isNum(x = cdr(numCell(y = x)))) {
      if ((n = carry + unDig(x)) >= carry)
         carry = unDig(x) > (n += unDig(x));
      setDig(x,n);
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
         setDig(y, unDig(y) | 0x80000000);
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

   carry = (unDig(src) & ~1) > setDig(dst, (unDig(src) & ~1) + (unDig(dst) & ~1));
   src = cdr(numCell(src));
   dst = cdr(numCell(x = dst));
   for (;;) {
      if (!isNum(src)) {
         while (isNum(dst)) {
            if (!carry)
               return;
            carry = 0 == setDig(dst, 1 + unDig(dst));
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
      if ((n = carry + unDig(src)) >= carry)
         carry = unDig(dst) > (n += unDig(dst));
      setDig(dst,n);
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

   carry = n > setDig(x, n + unDig(x));
   while (carry) {
      if (isNum(x = cdr(numCell(y = x))))
         carry = 0 == setDig(x, 1 + unDig(x));
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

   borrow = MAX - (unDig(src) & ~1) < setDig(dst, (unDig(dst) & ~1) - (unDig(src) & ~1));
   y = dst;
   for (;;) {
      src = cdr(numCell(src));
      dst = cdr(numCell(x = dst));
      if (!isNum(src)) {
         while (isNum(dst)) {
            if (!borrow)
               return;
            borrow = MAX == setDig(dst, unDig(dst) - 1);
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
         borrow = setDig(dst, n - unDig(src)) > MAX - unDig(src);
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
            borrow = 0 != (setDig(dst, -unDig(dst)));
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
   borrow = MAX == setDig(x, unDig(x) - 2);
   while (isNum(x = cdr(numCell(y = x)))) {
      if (!borrow)
         return;
      borrow = MAX == setDig(x, unDig(x) - 1);
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
         n |= 0x80000000;
      t = (word2)n * unDig(z = x1);  // x += n * x1
      carry = (lo(t) > setDig(y, unDig(y) + lo(t))) + hi(t);
      while (isNum(z = cdr(numCell(z)))) {
         if (!isNum(cdr(numCell(y))))
            cdr(numCell(y)) = box(0);
         y = cdr(numCell(y));
         t = (word2)n * unDig(z);
         carry = carry > setDig(y, carry + unDig(y));
         if (lo(t) > setDig(y, unDig(y) + lo(t)))
            ++carry;
         carry += hi(t);
      }
      if (carry) {
         /***
         if (isNum(cdr(numCell(y))))
            digAdd(y,carry);
         else
         ***/
         cdr(numCell(y)) = box(carry);
      }
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
static void digMul(any x, word n) {
   word2 t;
   any y;

   t = (word2)n * unDig(x);
   setDig(x, lo(t));
   t = hi(t);
   while (isNum(x = cdr(numCell(y = x)))) {
      t += (word2)n * unDig(x);
      setDig(x, lo(t));
      t = hi(t);
   }
   if (t)
      cdr(numCell(y)) = box(lo(t));
}

/* (Positive) Bignum comparison */
static int bigCmp(any x, any y) {
   int res;
   any x1, y1, x2, y2;

   if (x == y)
      return 0;
   x1 = y1 = Nil;
   while (isNum(x2 = cdr(numCell(x)))  &&  isNum(y2 = cdr(numCell(y)))) {
      cdr(numCell(x)) = x1,  x1 = x,  x = x2;
      cdr(numCell(y)) = y1,  y1 = y,  y = y2;
   }
   if (isNum(cdr(numCell(x))))
      res = +1;
   else if (isNum(cdr(numCell(y))))
      res = -1;
   else for (;;) {
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
   word2 t, t2;
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
   for (d = 0;  (unDig(x) & 0x80000000) == 0;  ++d)
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

      t = ((word2)u1 << 32) + u2;                           // Calculate q
      if (u1 == v1)
         q = MAX;
      else
         q = t / v1;

      t2 = t - (word2)q*v1;
      while ((word2)q*v2 > (t2 << 32) + u3) {
         --q;
         if ((t2 += v1) > MAX)
            break;
      }

      z = x;                                                // x -= q*v
      t = (word2)q * unDig(y = v);
      borrow = (MAX - lo(t) < setDig(z, unDig(z) - lo(t))) + hi(t);
      while (isNum(y = cdr(numCell(y)))) {
         z = cdr(numCell(z));
         t = (word2)q * unDig(y);
         borrow = MAX - borrow < setDig(z, unDig(z) - borrow);
         if (MAX - lo(t) < setDig(z, unDig(z) - lo(t)))
            ++borrow;
         borrow += hi(t);
      }
      if (borrow) {
         z = cdr(numCell(z));
         if (MAX - borrow < setDig(z, unDig(z) - borrow)) {
            word n, carry;                                  // x += v

            --q;
            if (m || rem) {
               y = v;
               carry = unDig(y) > setDig(x, unDig(y) + unDig(x));
               while (x = cdr(numCell(x)),  isNum(y = cdr(numCell(y)))) {
                  if ((n = carry + unDig(y)) >= carry)
                     carry = unDig(x) > (n += unDig(x));
                  setDig(x,n);
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
   if (IsZero(x) && IsZero(y))
      return 0;
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
   while ((c = symByte(NULL))  &&  (!frac || scl)) {
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
         digAdd(data(c2), 1+1);
      while (c = symByte(NULL)) {
         if ((c -= '0') > 9) {
            drop(c1);
            return NULL;
         }
         if (c > 9) {
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
   return n;
}

/* Make symbol from number */
any numToSym(any x, int scl, int sep, int ign) {
   bool sign;
   cell c1;
   word n = numlen(x);
   byte c, *p, *q, *ta, *ti, acc[n], inc[n];

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
               if (c = (*p += *q + c) > 9)
                  *p -= 10;
            } while (++p, ++q <= ti);
            if (c)
               *p = 1,  ++ta;
         }
         c = 0,  q = inc;
         do
            if (c = (*q += *q + c) > 9)
               *q -= 10;
         while (++q <= ti);
         if (c)
            *q = 1,  ++ti;
      } while (n <<= 1);
      if (!isNum(x = cdr(numCell(x))))
         break;
      n = 1;
   }
   if (sep < 0)
      return boxCnt(ta - acc + (sign? 2 : 1));
   if (sep == 0) {
      int i = 0;

      Push(c1, x = box(*ta + '0'));
      while (--ta >= acc)
         byteSym(*ta + '0', &i, &x);
   }
   else {
      Push(c1, box(*(p = acc) + '0'));
      while (++p <= ta) {
         if (--scl == 0)
            consByteSym(sep, data(c1));
         else if (ign  &&  scl < 0  &&  -scl % 3 == 0)
            consByteSym(ign, data(c1));
         consByteSym(*p + '0', data(c1));
      }
      if (--scl >= 0) {
         if (scl > 0)
            do
               consByteSym('0', data(c1));
            while (--scl);
         consByteSym(sep, data(c1));
         consByteSym('0', data(c1));
      }
   }
   if (sign)
      consByteSym('-', data(c1));
   return consStr(Pop(c1));
}

#define DMAX 4294967296.0

/* Make number from double */
any doubleToNum(double d) {
   bool sign;
   any x;
   cell c1;

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
// (format 'sym ['cnt ['sym1 ['sym2]]]) -> num
any doFormat(any ex) {
   int scl, sep, ign;
   any x, y;
   cell c1;

   x = cdr(ex),  Push(c1, EVAL(car(x))),  x = cdr(x);
   NeedAtom(ex,data(c1));
   scl = sep = ign = 0;
   if (isCell(x)) {
      scl = (int)evCnt(ex,x);
      sep = '.';
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
   }
   data(c1) = isNum(data(c1))?
      numToSym(data(c1), scl, sep, ign) :
      symToNum(name(data(c1)), scl, sep, ign) ?: Nil;
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

// (inc 'var ['num]) -> num
any doInc(any ex) {
   any x;
   cell c1, c2;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   NeedVar(ex,data(c1));
   CheckVar(ex,data(c1));
   if (!isCell(x = cdr(x))) {
      Touch(ex,data(c1));
      if (isNil(val(data(c1)))) {
         drop(c1);
         return Nil;
      }
      NeedNum(ex,val(data(c1)));
      val(data(c1)) = bigCopy(val(data(c1)));
      if (!isNeg(val(data(c1))))
         digAdd(val(data(c1)), 2);
      else {
         digSub1(val(data(c1)));
         if (unDig(val(data(c1))) == 1  &&  !isNum(cdr(numCell(val(data(c1))))))
            setDig(val(data(c1)), 0);
      }
   }
   else {
      Push(c2, EVAL(car(x)));
      Touch(ex,data(c1));
      if (isNil(val(data(c1))) || isNil(val(data(c2)))) {
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
      drop(c2);
   }
   return val(Pop(c1));
}

// (dec 'var ['num]) -> num
any doDec(any ex) {
   any x;
   cell c1, c2;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   NeedVar(ex,data(c1));
   CheckVar(ex,data(c1));
   if (!isCell(x = cdr(x))) {
      Touch(ex,data(c1));
      if (isNil(val(data(c1)))) {
         drop(c1);
         return Nil;
      }
      NeedNum(ex,val(data(c1)));
      val(data(c1)) = bigCopy(val(data(c1)));
      if (isNeg(val(data(c1))))
         digAdd(val(data(c1)), 2);
      else if (IsZero(val(data(c1))))
         setDig(val(data(c1)), 3);
      else
         digSub1(val(data(c1)));
   }
   else {
      Push(c2, EVAL(car(x)));
      Touch(ex,data(c1));
      if (isNil(val(data(c1))) || isNil(val(data(c2)))) {
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
      drop(c2);
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

// (*/ 'num 'num 'num ['flg]) -> num
any doMulDiv(any ex) {
   any x;
   bool sign;
   cell c1, c2;

   x = cdr(ex);
   if (isNil(data(c1) = EVAL(car(x))))
      return Nil;
   NeedNum(ex,data(c1));
   Push(c1, bigCopy(data(c1)));
   sign = isNeg(data(c1)),  pos(data(c1));
   x = cdr(x),  Push(c2, EVAL(car(x)));
   if (isNil(data(c2))) {
      drop(c1);
      return Nil;
   }
   NeedNum(ex,data(c2));
   sign ^= isNeg(data(c2));
   data(c1) = bigMul(data(c1),data(c2));
   x = cdr(x),  data(c2) = EVAL(car(x));
   if (isNil(data(c2))) {
      drop(c1);
      return Nil;
   }
   NeedNum(ex,data(c2));
   sign ^= isNeg(data(c2));
   if (IsZero(data(c2)))
      divErr(ex);
   data(c2) = bigCopy(data(c2));
   x = cdr(x);
   if (!isNil(EVAL(car(x)))) {
      cell c3;

      Push(c3, bigCopy(data(c2)));
      digDiv2(data(c3));
      bigAdd(data(c1),data(c3));
   }
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

// (bit? 'num ..) -> flg
any doBitQ(any ex) {
   any x, y, z;
   cell c1;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   NeedNum(ex,data(c1));
   while (isCell(x = cdr(x))) {
      if (isNil(z = EVAL(car(x)))) {
         drop(c1);
         return Nil;
      }
      NeedNum(ex,z);
      y = data(c1);
      for (;;) {
         if ((unDig(y) & unDig(z)) != unDig(y)) {
            drop(c1);
            return Nil;
         }
         if (!isNum(y = cdr(numCell(y))))
            break;
         if (!isNum(z = cdr(numCell(z)))) {
            drop(c1);
            return Nil;
         }
      }
   }
   drop(c1);
   return T;
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
   while (isCell(x = cdr(x))) {
      if (isNil(z = EVAL(car(x)))) {
         drop(c1);
         return Nil;
      }
      NeedNum(ex,z);
      y = data(c1);
      for (;;) {
         setDig(y, unDig(y) & unDig(z));
         if (!isNum(z = cdr(numCell(z)))) {
            cdr(numCell(y)) = Nil;
            break;
         }
         if (!isNum(y = cdr(numCell(y))))
            break;
      }
   }
   zapZero(data(c1));
   return Pop(c1);
}

// (| 'num ..) -> num
any doBitOr(any ex) {
   any x, y, z;
   cell c1;

   x = cdr(ex);
   if (isNil(data(c1) = EVAL(car(x))))
      return Nil;
   NeedNum(ex,data(c1));
   Push(c1, bigCopy(data(c1)));
   while (isCell(x = cdr(x))) {
      if (isNil(z = EVAL(car(x)))) {
         drop(c1);
         return Nil;
      }
      NeedNum(ex,z);
      y = data(c1);
      for (;;) {
         setDig(y, unDig(y) | unDig(z));
         if (!isNum(z = cdr(numCell(z))))
            break;
         if (!isNum(cdr(numCell(y))))
            cdr(numCell(y)) = box(0);
         y = cdr(numCell(y));
      }
   }
   return Pop(c1);
}

// Needs to be optimized!
// (sqrt 'num) -> num
any doSqrt(any ex) {
   any x;
   cell c1, c2, c3;

   x = cdr(ex);
   if (isNil(x = EVAL(car(x))))
      return Nil;
   NeedNum(ex,x);
   if (isNeg(x))
      err(ex, x, "Bad argument");
   Push(c1, bigCopy(x));
   Push(c2, box(2));
   for (x = data(c1);  isNum(cdr(numCell(x)));  x = cdr(numCell(x)))
      data(c2) = consNum(0, data(c2));
   while (bigCmp(data(c2),data(c1)) <= 0)
      digMul2(data(c2)),  digMul2(data(c2));
   Push(c3, box(0));
   do {
      bigAdd(data(c3),data(c2));
      if (bigCmp(data(c3),data(c1)) > 0)
         bigSub(data(c3),data(c2));
      else
         bigSub(data(c1),data(c3)),  bigAdd(data(c3),data(c2));
      digDiv2(data(c3));
      digDiv2(data(c2)),  digDiv2(data(c2));
   } while (!IsZero(data(c2)));
   drop(c1);
   return data(c3);
}

static word2 Seed;

static word2 initSeed(any x) {
   word2 n;

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
   return boxCnt(
         hi(Seed = initSeed(EVAL(cadr(ex))) * 6364136223846793005LL + 1) );
}

// (rand ['cnt1 'cnt2] | ['T]) -> cnt | flg
any doRand(any ex) {
   any x;
   long n;

   x = cdr(ex);
   Seed = Seed * 6364136223846793005LL + 1;
   if (isNil(x = EVAL(car(x))))
      return boxCnt(hi(Seed));
   if (x == T)
      return hi(Seed) & 1 ? T : Nil;
   n = xCnt(ex,x);
   return boxCnt(n + hi(Seed) % (evCnt(ex, cddr(ex)) + 1 - n));
}
