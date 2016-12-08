/* 24oct16abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

// (car 'var) -> any
any doCar(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedVar(ex,x);
   return car(x);
}

// (cdr 'lst) -> any
any doCdr(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedLst(ex,x);
   return cdr(x);
}

any doCaar(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedVar(ex,x);
   return caar(x);
}

any doCadr(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedLst(ex,x);
   return cadr(x);
}

any doCdar(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedVar(ex,x);
   return cdar(x);
}

any doCddr(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedLst(ex,x);
   return cddr(x);
}

any doCaaar(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedVar(ex,x);
   return caaar(x);
}

any doCaadr(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedLst(ex,x);
   return caadr(x);
}

any doCadar(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedVar(ex,x);
   return cadar(x);
}

any doCaddr(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedLst(ex,x);
   return caddr(x);
}

any doCdaar(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedVar(ex,x);
   return cdaar(x);
}

any doCdadr(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedLst(ex,x);
   return cdadr(x);
}

any doCddar(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedVar(ex,x);
   return cddar(x);
}

any doCdddr(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedLst(ex,x);
   return cdddr(x);
}

any doCaaaar(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedVar(ex,x);
   return caaaar(x);
}

any doCaaadr(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedLst(ex,x);
   return caaadr(x);
}

any doCaadar(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedVar(ex,x);
   return caadar(x);
}

any doCaaddr(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedLst(ex,x);
   return caaddr(x);
}

any doCadaar(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedVar(ex,x);
   return cadaar(x);
}

any doCadadr(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedLst(ex,x);
   return cadadr(x);
}

any doCaddar(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedVar(ex,x);
   return caddar(x);
}

any doCadddr(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedLst(ex,x);
   return cadddr(x);
}

any doCdaaar(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedVar(ex,x);
   return cdaaar(x);
}

any doCdaadr(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedLst(ex,x);
   return cdaadr(x);
}

any doCdadar(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedVar(ex,x);
   return cdadar(x);
}

any doCdaddr(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedLst(ex,x);
   return cdaddr(x);
}

any doCddaar(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedVar(ex,x);
   return cddaar(x);
}

any doCddadr(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedLst(ex,x);
   return cddadr(x);
}

any doCdddar(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedVar(ex,x);
   return cdddar(x);
}

any doCddddr(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedLst(ex,x);
   return cddddr(x);
}

// (nth 'lst 'cnt ..) -> lst
any doNth(any ex) {
   any x;
   cell c1;

   x = cdr(ex),  Push(c1, EVAL(car(x))),  x = cdr(x);
   for (;;) {
      if (!isCell(data(c1)))
         return Pop(c1);
      data(c1) = nth((int)evCnt(ex,x), data(c1));
      if (!isCell(x = cdr(x)))
         return Pop(c1);
      data(c1) = car(data(c1));
   }
}

// (con 'lst 'any) -> any
any doCon(any ex) {
   any x;
   cell c1;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   NeedPair(ex,data(c1));
   x = cdr(x),  x = cdr(data(c1)) = EVAL(car(x));
   drop(c1);
   return x;
}

// (cons 'any ['any ..]) -> lst
any doCons(any x) {
   any y;
   cell c1;

   x = cdr(x);
   Push(c1, y = cons(EVAL(car(x)),Nil));
   while (isCell(cdr(x = cdr(x))))
      y = cdr(y) = cons(EVAL(car(x)),Nil);
   cdr(y) = EVAL(car(x));
   return Pop(c1);
}

// (conc 'lst ..) -> lst
any doConc(any x) {
   any y, z;
   cell c1;

   x = cdr(x),  Push(c1, y = EVAL(car(x)));
   while (isCell(x = cdr(x))) {
      z = EVAL(car(x));
      if (!isCell(y))
         y = data(c1) = z;
      else {
         while (isCell(cdr(y)))
            y = cdr(y);
         cdr(y) = z;
      }
   }
   return Pop(c1);
}

// (circ 'any ..) -> lst
any doCirc(any x) {
   any y;
   cell c1;

   x = cdr(x);
   Push(c1, y = cons(EVAL(car(x)),Nil));
   while (isCell(x = cdr(x)))
      y = cdr(y) = cons(EVAL(car(x)),Nil);
   cdr(y) = data(c1);
   return Pop(c1);
}

// (rot 'lst ['cnt]) -> lst
any doRot(any ex) {
   any x, y, z;
   int n;
   cell c1;

   x = cdr(ex),  Push(c1, y = EVAL(car(x)));
   if (isCell(y)) {
      n = 0;
      if (!isCell(x = cdr(x)) || (n = (int)evCnt(ex,x))) {
         x = car(y);
         while (--n  &&  isCell(y = cdr(y))  &&  y != data(c1))
            z = car(y),  car(y) = x,  x = z;
         car(data(c1)) = x;
      }
   }
   return Pop(c1);
}

// (list 'any ['any ..]) -> lst
any doList(any x) {
   any y;
   cell c1;

   x = cdr(x);
   Push(c1, y = cons(EVAL(car(x)),Nil));
   while (isCell(x = cdr(x)))
      y = cdr(y) = cons(EVAL(car(x)),Nil);
   return Pop(c1);
}

// (need 'cnt ['lst ['any]]) -> lst
// (need 'cnt ['num|sym]) -> lst
any doNeed(any ex) {
   int n;
   any x;
   cell c1, c2;

   n = (int)evCnt(ex, x = cdr(ex));
   x = cdr(x),  Push(c1, EVAL(car(x)));
   if (isCell(data(c1)) || isNil(data(c1)))
      Push(c2, EVAL(cadr(x)));
   else {
      Push(c2, data(c1));
      data(c1) = Nil;
   }
   x = data(c1);
   if (n > 0)
      for (n -= length(x); n > 0; --n)
         data(c1) = cons(data(c2), data(c1));
   else if (n) {
      if (!isCell(x))
         data(c1) = x = cons(data(c2),Nil);
      else
         while (isCell(cdr(x)))
            ++n,  x = cdr(x);
      while (++n < 0)
         x = cdr(x) = cons(data(c2),Nil);
   }
   return Pop(c1);
}

// (range 'num1 'num2 ['num3]) -> lst
any doRange(any ex) {
   any x;
   cell c1, c2, c3, c4;

   x = cdr(ex),  Push(c1, EVAL(car(x)));  // Start value
   NeedNum(ex,data(c1));
   x = cdr(x),  Push(c2, EVAL(car(x)));  // End value
   NeedNum(ex,data(c2));
   x = cdr(x),  Push(c3, One);  // Increment
   if (!isNil(x = EVAL(car(x)))) {
      NeedNum(ex, data(c3) = x);
      if (IsZero(x) || isNeg(x))
         argError(ex,x);
   }
   Push(c4, x = cons(data(c1), Nil));
   if (bigCompare(data(c2), data(c1)) >= 0) {
      for (;;) {
         data(c1) = bigCopy(data(c1));
         if (!isNeg(data(c1)))
            bigAdd(data(c1), data(c3));
         else {
            bigSub(data(c1), data(c3));
            if (!IsZero(data(c1)))
               neg(data(c1));
         }
         if (bigCompare(data(c2), data(c1)) < 0)
            break;
         x = cdr(x) = cons(data(c1), Nil);
      }
   }
   else {
      for (;;) {
         data(c1) = bigCopy(data(c1));
         if (!isNeg(data(c1)))
            bigSub(data(c1), data(c3));
         else {
            bigAdd(data(c1), data(c3));
            if (!IsZero(data(c1)))
               neg(data(c1));
         }
         if (bigCompare(data(c2), data(c1)) > 0)
            break;
         x = cdr(x) = cons(data(c1), Nil);
      }
   }
   drop(c1);
   return data(c4);
}

// (full 'any) -> bool
any doFull(any x) {
   x = cdr(x);
   for (x = EVAL(car(x)); isCell(x); x = cdr(x))
      if (isNil(car(x)))
         return Nil;
   return T;
}

// (make .. [(made 'lst ..)] .. [(link 'any ..)] ..) -> any
any doMake(any x) {
   any *make, *yoke;
   cell c1;

   Push(c1, Nil);
   make = Env.make;
   yoke = Env.yoke;
   Env.make = Env.yoke = &data(c1);
   while (isCell(x = cdr(x)))
      if (isCell(car(x)))
         evList(car(x));
   Env.yoke = yoke;
   Env.make = make;
   return Pop(c1);
}

static void makeError(any ex) {err(ex, NULL, "Not making");}

// (made ['lst1 ['lst2]]) -> lst
any doMade(any x) {
   if (!Env.make)
      makeError(x);
   if (isCell(x = cdr(x))) {
      *Env.yoke = EVAL(car(x));
      if (x = cdr(x), !isCell(x = EVAL(car(x)))) {
         any y;

         x = *Env.yoke;
         while (isCell(y = cdr(x)))
            x = y;
      }
      Env.make = &cdr(x);
   }
   return *Env.yoke;
}

// (chain 'lst ..) -> lst
any doChain(any x) {
   any y;

   if (!Env.make)
      makeError(x);
   x = cdr(x);
   do
      if (isCell(*Env.make = y = EVAL(car(x))))
         do
            Env.make = &cdr(*Env.make);
         while (isCell(*Env.make));
   while (isCell(x = cdr(x)));
   return y;
}

// (link 'any ..) -> any
any doLink(any x) {
   any y;

   if (!Env.make)
      makeError(x);
   x = cdr(x);
   do {
      y = EVAL(car(x));
      Env.make = &cdr(*Env.make = cons(y, Nil));
   } while (isCell(x = cdr(x)));
   return y;
}

// (yoke 'any ..) -> any
any doYoke(any x) {
   any y;

   if (!Env.make)
      makeError(x);
   x = cdr(x);
   do {
      y = EVAL(car(x));
      *Env.yoke = cons(y, *Env.yoke);
   } while (isCell(x = cdr(x)));
   while (isCell(*Env.make))
      Env.make = &cdr(*Env.make);
   return y;
}

// (copy 'any) -> any
any doCopy(any x) {
   any y, z;
   cell c1;

   x = cdr(x);
   if (!isCell(x = EVAL(car(x))))
      return x;
   Push(c1, y = cons(car(x), cdr(z = x)));
   while (isCell(x = cdr(y))) {
      if (x == z) {
         cdr(y) = data(c1);
         break;
      }
      y = cdr(y) = cons(car(x), cdr(x));
   }
   return Pop(c1);
}

// (mix 'lst cnt|'any ..) -> lst
any doMix(any x) {
   any y;
   cell c1, c2;

   x = cdr(x);
   if (!isCell(data(c1) = EVAL(car(x))) && !isNil(data(c1)))
      return data(c1);
   if (!isCell(x = cdr(x)))
      return Nil;
   Save(c1);
   Push(c2,
      y = cons(
         isNum(car(x))? car(nth((int)unBox(car(x)),data(c1))) : EVAL(car(x)),
         Nil ) );
   while (isCell(x = cdr(x)))
      y = cdr(y) = cons(
         isNum(car(x))? car(nth((int)unBox(car(x)),data(c1))) : EVAL(car(x)),
         Nil );
   drop(c1);
   return data(c2);
}

// (append 'lst ..) -> lst
any doAppend(any x) {
   any y, z;
   cell c1;

   while (isCell(cdr(x = cdr(x)))) {
      if (isCell(y = EVAL(car(x)))) {
         Push(c1, z = cons(car(y), cdr(y)));
         while (isCell(y = cdr(z)))
            z = cdr(z) = cons(car(y), cdr(y));
         while (isCell(cdr(x = cdr(x)))) {
            for (y = EVAL(car(x)); isCell(y); y = cdr(z))
               z = cdr(z) = cons(car(y), cdr(y));
            cdr(z) = y;
         }
         cdr(z) = EVAL(car(x));
         return Pop(c1);
      }
   }
   return EVAL(car(x));
}

// (delete 'any 'lst) -> lst
any doDelete(any x) {
   any y, z;
   cell c1, c2, c3;

   x = cdr(x),  Push(c1, y = EVAL(car(x)));
   x = cdr(x);
   if (!isCell(x = EVAL(car(x)))) {
      drop(c1);
      return x;
   }
   if (equal(y, car(x))) {
      drop(c1);
      return cdr(x);
   }
   Push(c2, x);
   Push(c3, z = cons(car(x), Nil));
   while (isCell(x = cdr(x))) {
      if (equal(y, car(x))) {
         cdr(z) = cdr(x);
         drop(c1);
         return data(c3);
      }
      z = cdr(z) = cons(car(x), Nil);
   }
   cdr(z) = x;
   drop(c1);
   return data(c3);
}

// (delq 'any 'lst) -> lst
any doDelq(any x) {
   any y, z;
   cell c1, c2, c3;

   x = cdr(x),  Push(c1, y = EVAL(car(x)));
   x = cdr(x);
   if (!isCell(x = EVAL(car(x)))) {
      drop(c1);
      return x;
   }
   if (y == car(x)) {
      drop(c1);
      return cdr(x);
   }
   Push(c2, x);
   Push(c3, z = cons(car(x), Nil));
   while (isCell(x = cdr(x))) {
      if (y == car(x)) {
         cdr(z) = cdr(x);
         drop(c1);
         return data(c3);
      }
      z = cdr(z) = cons(car(x), Nil);
   }
   cdr(z) = x;
   drop(c1);
   return data(c3);
}

// (replace 'lst 'any1 'any2 ..) -> lst
any doReplace(any x) {
   any y;
   int i, n = length(cdr(x = cdr(x))) + 1 & ~1;
   cell c1, c2, c[n];

   if (!isCell(data(c1) = EVAL(car(x))))
      return data(c1);
   Save(c1);
   for (i = 0; i < n; ++i)
      x = cdr(x),  Push(c[i], EVAL(car(x)));
   for (x = car(data(c1)), i = 0;  i < n;  i += 2)
      if (equal(x, data(c[i]))) {
         x = data(c[i+1]);
         break;
      }
   Push(c2, y = cons(x,Nil));
   while (isCell(data(c1) = cdr(data(c1)))) {
      for (x = car(data(c1)), i = 0;  i < n;  i += 2)
         if (equal(x, data(c[i]))) {
            x = data(c[i+1]);
            break;
         }
      y = cdr(y) = cons(x, Nil);
   }
   cdr(y) = data(c1);
   drop(c1);
   return data(c2);
}

// (insert 'cnt 'lst 'any) -> lst
any doInsert(any x) {
   long n;
   any y;
   cell c1, c2;

   n = evCnt(x, cdr(x)),  x = cddr(x);
   Push(c1, EVAL(car(x))),  x = cdr(x);
   if (!isCell(data(c1)) || --n <= 0) {
      x = cons(EVAL(car(x)), data(c1));
      drop(c1);
      return x;
   }
   Push(c2, y = cons(car(data(c1)), Nil));
   while (isCell(data(c1) = cdr(data(c1))) && --n)
      y = cdr(y) = cons(car(data(c1)), Nil);
   cdr(y) = cons(EVAL(car(x)), data(c1));
   drop(c1);
   return data(c2);
}

// (remove 'cnt 'lst) -> lst
any doRemove(any x) {
   long n;
   any y;
   cell c1, c2;

   n = evCnt(x, cdr(x)),  x = cddr(x);
   if (!isCell(data(c1) = EVAL(car(x))) || --n < 0)
      return data(c1);
   if (!n)
      return cdr(data(c1));
   Save(c1);
   Push(c2, y = cons(car(data(c1)), Nil));
   while (isCell(data(c1) = cdr(data(c1))) && --n)
      y = cdr(y) = cons(car(data(c1)), Nil);
   cdr(y) = cdr(data(c1));
   drop(c1);
   return data(c2);
}

// (place 'cnt 'lst 'any) -> lst
any doPlace(any x) {
   long n;
   any y;
   cell c1, c2;

   n = evCnt(x, cdr(x)),  x = cddr(x);
   data(c1) = EVAL(car(x)),  x = cdr(x);
   if (!isCell(data(c1)))
      return EVAL(car(x));
   Save(c1);
   if (--n <= 0) {
      x = cons(EVAL(car(x)), cdr(data(c1)));
      drop(c1);
      return x;
   }
   Push(c2, y = cons(car(data(c1)), Nil));
   while (isCell(data(c1) = cdr(data(c1))) && --n)
      y = cdr(y) = cons(car(data(c1)), Nil);
   cdr(y) = cons(EVAL(car(x)), cdr(data(c1)));
   drop(c1);
   return data(c2);
}

// (strip 'any) -> any
any doStrip(any x) {
   x = cdr(x),  x = EVAL(car(x));
   while (isCell(x)  &&  car(x) == Quote  && x != cdr(x))
      x = cdr(x);
   return x;
}

// (split 'lst 'any ..) -> lst
any doSplit(any x) {
   any y;
   int i, n = length(cdr(x = cdr(x)));
   cell c1, c[n], res, sub;

   if (!isCell(data(c1) = EVAL(car(x))))
      return data(c1);
   Save(c1);
   for (i = 0; i < n; ++i)
      x = cdr(x),  Push(c[i], EVAL(car(x)));
   Push(res, x = Nil);
   Push(sub, y = Nil);
   do {
      for (i = 0;  i < n;  ++i) {
         if (equal(car(data(c1)), data(c[i]))) {
            if (isNil(x))
               x = data(res) = cons(data(sub), Nil);
            else
               x = cdr(x) = cons(data(sub), Nil);
            y = data(sub) = Nil;
            goto spl1;
         }
      }
      if (isNil(y))
         y = data(sub) = cons(car(data(c1)), Nil);
      else
         y = cdr(y) = cons(car(data(c1)), Nil);
spl1: ;
   } while (isCell(data(c1) = cdr(data(c1))));
   y = cons(data(sub), Nil);
   drop(c1);
   if (isNil(x))
      return y;
   cdr(x) = y;
   return data(res);
}

// (reverse 'lst) -> lst
any doReverse(any x) {
   any y;
   cell c1;

   x = cdr(x),  Push(c1, x = EVAL(car(x)));
   for (y = Nil; isCell(x); x = cdr(x))
      y = cons(car(x), y);
   drop(c1);
   return y;
}

// (flip 'lst ['cnt])) -> lst
any doFlip(any ex) {
   any x, y, z;
   int n;
   cell c1;

   x = cdr(ex);
   if (!isCell(y = EVAL(car(x))) || !isCell(z = cdr(y)))
      return y;
   if (!isCell(x = cdr(x))) {
      cdr(y) = Nil;
      for (;;) {
         x = cdr(z),  cdr(z) = y;
         if (!isCell(x))
            return z;
         y = z,  z = x;
      }
   }
   Push(c1, y);
   n = (int)evCnt(ex,x) - 1;
   drop(c1);
   if (n <= 0)
      return y;
   cdr(y) = cdr(z),  cdr(z) = y;
   while (--n && isCell(x = cdr(y)))
      cdr(y) = cdr(x),  cdr(x) = z,  z = x;
   return z;
}

static any trim(any x) {
   any y;

   if (!isCell(x))
      return x;
   if (isNil(y = trim(cdr(x))) && isBlank(car(x)))
      return Nil;
   return cons(car(x),y);
}

// (trim 'lst) -> lst
any doTrim(any x) {
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   x = trim(data(c1));
   drop(c1);
   return x;
}

// (clip 'lst) -> lst
any doClip(any x) {
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   while (isCell(data(c1)) && isBlank(car(data(c1))))
      data(c1) = cdr(data(c1));
   x = trim(data(c1));
   drop(c1);
   return x;
}

// (head 'cnt|lst 'lst) -> lst
any doHead(any ex) {
   long n;
   any x, y;
   cell c1, c2;

   x = cdr(ex);
   if (isNil(data(c1) = EVAL(car(x))))
      return Nil;
   x = cdr(x);
   if (isCell(data(c1))) {
      Save(c1);
      if (isCell(x = EVAL(car(x)))) {
         for (y = data(c1);  equal(car(y), car(x));  x = cdr(x))
            if (!isCell(y = cdr(y)))
               return Pop(c1);
      }
      drop(c1);
      return Nil;
   }
   if ((n = xCnt(ex,data(c1))) == 0)
      return Nil;
   if (!isCell(x = EVAL(car(x))))
      return x;
   if (n < 0  &&  (n += length(x)) <= 0)
      return Nil;
   Push(c1,x);
   Push(c2, x = cons(car(data(c1)), Nil));
   while (--n  &&  isCell(data(c1) = cdr(data(c1))))
      x = cdr(x) = cons(car(data(c1)), Nil);
   drop(c1);
   return data(c2);
}

// (tail 'cnt|lst 'lst) -> lst
any doTail(any ex) {
   long n;
   any x, y;
   cell c1;

   x = cdr(ex);
   if (isNil(data(c1) = EVAL(car(x))))
      return Nil;
   x = cdr(x);
   if (isCell(data(c1))) {
      Save(c1);
      if (isCell(x = EVAL(car(x)))) {
         do
            if (equal(x,data(c1)))
               return Pop(c1);
         while (isCell(x = cdr(x)));
      }
      drop(c1);
      return Nil;
   }
   if ((n = xCnt(ex,data(c1))) == 0)
      return Nil;
   if (!isCell(x = EVAL(car(x))))
      return x;
   if (n < 0)
      return nth(1 - n, x);
   for (y = cdr(x);  --n;  y = cdr(y))
      if (!isCell(y))
         return x;
   while (isCell(y))
      x = cdr(x),  y = cdr(y);
   return x;
}

// (stem 'lst 'any ..) -> lst
any doStem(any x) {
   int i, n = length(cdr(x = cdr(x)));
   cell c1, c[n];

   Push(c1, EVAL(car(x)));
   for (i = 0; i < n; ++i)
      x = cdr(x),  Push(c[i], EVAL(car(x)));
   for (x = data(c1); isCell(x); x = cdr(x)) {
      for (i = 0;  i < n;  ++i)
         if (equal(car(x), data(c[i]))) {
            data(c1) = cdr(x);
            break;
         }
   }
   return Pop(c1);
}

// (fin 'any) -> num|sym
any doFin(any x) {
   x = cdr(x),  x = EVAL(car(x));
   while (isCell(x))
      x = cdr(x);
   return x;
}

// (last 'lst) -> any
any doLast(any x) {
   x = cdr(x),  x = EVAL(car(x));
   if (!isCell(x))
      return x;
   while (isCell(cdr(x)))
      x = cdr(x);
   return car(x);
}

// (== 'any ..) -> flg
any doEq(any x) {
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   while (isCell(x = cdr(x)))
      if (data(c1) != EVAL(car(x))) {
         drop(c1);
         return Nil;
      }
   drop(c1);
   return T;
}

// (n== 'any ..) -> flg
any doNEq(any x) {
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   while (isCell(x = cdr(x)))
      if (data(c1) != EVAL(car(x))) {
         drop(c1);
         return T;
      }
   drop(c1);
   return Nil;
}

// (= 'any ..) -> flg
any doEqual(any x) {
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   while (isCell(x = cdr(x)))
      if (!equal(data(c1), EVAL(car(x)))) {
         drop(c1);
         return Nil;
      }
   drop(c1);
   return T;
}

// (<> 'any ..) -> flg
any doNEqual(any x) {
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   while (isCell(x = cdr(x)))
      if (!equal(data(c1), EVAL(car(x)))) {
         drop(c1);
         return T;
      }
   drop(c1);
   return Nil;
}

// (=0 'any) -> 0 | NIL
any doEq0(any x) {
   x = cdr(x);
   return isNum(x = EVAL(car(x))) && IsZero(x)? x : Nil;
}

// (=1 'any) -> 1 | NIL
any doEq1(any x) {
   x = cdr(x);
   return isNum(x = EVAL(car(x))) && (unDig(x)==2 && !isNum(cdr(numCell(x))))? x : Nil;
}

// (=T 'any) -> flg
any doEqT(any x) {
   x = cdr(x);
   return T == EVAL(car(x))? T : Nil;
}

// (n0 'any) -> flg
any doNEq0(any x) {
   x = cdr(x);
   return isNum(x = EVAL(car(x))) && IsZero(x)? Nil : T;
}

// (nT 'any) -> flg
any doNEqT(any x) {
   x = cdr(x);
   return T == EVAL(car(x))? Nil : T;
}

// (< 'any ..) -> flg
any doLt(any x) {
   any y;
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   while (isCell(x = cdr(x))) {
      y = EVAL(car(x));
      if (compare(data(c1), y) >= 0) {
         drop(c1);
         return Nil;
      }
      data(c1) = y;
   }
   drop(c1);
   return T;
}

// (<= 'any ..) -> flg
any doLe(any x) {
   any y;
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   while (isCell(x = cdr(x))) {
      y = EVAL(car(x));
      if (compare(data(c1), y) > 0) {
         drop(c1);
         return Nil;
      }
      data(c1) = y;
   }
   drop(c1);
   return T;
}

// (> 'any ..) -> flg
any doGt(any x) {
   any y;
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   while (isCell(x = cdr(x))) {
      y = EVAL(car(x));
      if (compare(data(c1), y) <= 0) {
         drop(c1);
         return Nil;
      }
      data(c1) = y;
   }
   drop(c1);
   return T;
}

// (>= 'any ..) -> flg
any doGe(any x) {
   any y;
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   while (isCell(x = cdr(x))) {
      y = EVAL(car(x));
      if (compare(data(c1), y) < 0) {
         drop(c1);
         return Nil;
      }
      data(c1) = y;
   }
   drop(c1);
   return T;
}

// (max 'any ..) -> any
any doMax(any x) {
   any y;
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   while (isCell(x = cdr(x)))
      if (compare(y = EVAL(car(x)), data(c1)) > 0)
         data(c1) = y;
   return Pop(c1);
}

// (min 'any ..) -> any
any doMin(any x) {
   any y;
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   while (isCell(x = cdr(x)))
      if (compare(y = EVAL(car(x)), data(c1)) < 0)
         data(c1) = y;
   return Pop(c1);
}

// (atom 'any) -> flg
any doAtom(any x) {
   x = cdr(x);
   return !isCell(EVAL(car(x)))? T : Nil;
}

// (pair 'any) -> any
any doPair(any x) {
   x = cdr(x);
   return isCell(x = EVAL(car(x)))? x : Nil;
}

// (circ? 'any) -> any
any doCircQ(any x) {
   x = cdr(x);
   return isCell(x = EVAL(car(x))) && (x = circ(x))? x : Nil;
}

// (lst? 'any) -> flg
any doLstQ(any x) {
   x = cdr(x);
   return isCell(x = EVAL(car(x))) || isNil(x)? T : Nil;
}

// (num? 'any) -> num | NIL
any doNumQ(any x) {
   x = cdr(x);
   return isNum(x = EVAL(car(x)))? x : Nil;
}

// (sym? 'any) -> flg
any doSymQ(any x) {
   x = cdr(x);
   return isSym(EVAL(car(x)))? T : Nil;
}

// (flg? 'any) -> flg
any doFlgQ(any x) {
   x = cdr(x);
   return isNil(x = EVAL(car(x))) || x==T? T : Nil;
}

// (member 'any 'lst) -> any
any doMember(any x) {
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   x = cdr(x),  x = EVAL(car(x));
   return member(Pop(c1), x) ?: Nil;
}

// (memq 'any 'lst) -> any
any doMemq(any x) {
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   x = cdr(x),  x = EVAL(car(x));
   return memq(Pop(c1), x) ?: Nil;
}

// (mmeq 'lst 'lst) -> any
any doMmeq(any x) {
   any y, z;
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   x = cdr(x),  y = EVAL(car(x));
   for (x = Pop(c1);  isCell(x);  x = cdr(x))
      if (z = memq(car(x), y))
         return z;
   return Nil;
}

// (sect 'lst 'lst) -> lst
any doSect(any x) {
   cell c1, c2, c3;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   x = cdr(x),  Push(c2, EVAL(car(x)));
   Push(c3, x = Nil);
   while (isCell(data(c1))) {
      if (member(car(data(c1)), data(c2)))
         if (isNil(x))
            x = data(c3) = cons(car(data(c1)), Nil);
         else
            x = cdr(x) = cons(car(data(c1)), Nil);
      data(c1) = cdr(data(c1));
   }
   drop(c1);
   return data(c3);
}

// (diff 'lst 'lst) -> lst
any doDiff(any x) {
   cell c1, c2, c3;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   x = cdr(x),  Push(c2, EVAL(car(x)));
   Push(c3, x = Nil);
   while (isCell(data(c1))) {
      if (!member(car(data(c1)), data(c2)))
         if (isNil(x))
            x = data(c3) = cons(car(data(c1)), Nil);
         else
            x = cdr(x) = cons(car(data(c1)), Nil);
      data(c1) = cdr(data(c1));
   }
   drop(c1);
   return data(c3);
}

// (index 'any 'lst) -> cnt | NIL
any doIndex(any x) {
   int n;
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   x = cdr(x),  x = EVAL(car(x));
   return (n = indx(Pop(c1), x))? boxCnt(n) : Nil;
}

// (offset 'lst1 'lst2) -> cnt | NIL
any doOffset(any x) {
   int n;
   any y;
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   x = cdr(x),  y = EVAL(car(x));
   for (n = 1, x = Pop(c1);  isCell(y);  ++n, y = cdr(y))
      if (equal(x,y))
         return boxCnt(n);
   return Nil;
}

// (prior 'lst1 'lst2) -> lst | NIL
any doPrior(any x) {
   any y;
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   x = cdr(x),  y = EVAL(car(x));
   if ((x = Pop(c1)) != y)
      while (isCell(y)) {
         if (x == cdr(y))
            return y;
         y = cdr(y);
      }
   return Nil;
}

// (length 'any) -> cnt | T
any doLength(any x) {
   int n, c;
   any y;

   if (isNum(x = EVAL(cadr(x))))
      return numToSym(x, 0, -1, 0);
   if (isSym(x)) {
      for (n = 0, c = symChar(name(x));  c;  ++n, c = symChar(NULL));
      return boxCnt(n);
   }
   for (n = 0, y = x;;) {
      ++n;
      *(word*)&car(y) |= 1;
      if (!isCell(y = cdr(y))) {
         do
            *(word*)&car(x) &= ~1;
         while (isCell(x = cdr(x)));
         return boxCnt(n);
      }
      if (num(car(y)) & 1) {
         while (x != y)
            *(word*)&car(x) &= ~1,  x = cdr(x);
         do
            *(word*)&car(x) &= ~1;
         while (y != (x = cdr(x)));
         return T;
      }
   }
}

static int size(any x) {
   int n;
   any y;

   for (n = 0, y = x;;) {
      ++n;
      if (isCell(car(y)))
         n += size(car(y));
      *(word*)&car(y) |= 1;
      if (!isCell(y = cdr(y))) {
         do
            *(word*)&car(x) &= ~1;
         while (isCell(x = cdr(x)));
         return n;
      }
      if (num(car(y)) & 1) {
         while (x != y)
            *(word*)&car(x) &= ~1,  x = cdr(x);
         do
            *(word*)&car(x) &= ~1;
         while (y != (x = cdr(x)));
         return n;
      }
   }
}

// (size 'any) -> cnt
any doSize(any ex) {
   any x = cdr(ex);

   if (isNum(x = EVAL(car(x))))
      return boxCnt(numBytes(x));
   if (!isSym(x))
      return boxCnt(size(x));
   if (isExt(x))
      return boxCnt(dbSize(ex,x));
   return isNum(x = name(x))? boxCnt(numBytes(x)) : Zero;
}

// (bytes 'any) -> cnt
any doBytes(any x) {
   return boxCnt(binSize(EVAL(cadr(x))));
}

// (assoc 'any 'lst) -> lst
any doAssoc(any x) {
   any y;
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   x = cdr(x),  y = EVAL(car(x));
   for (x = Pop(c1);  isCell(y);  y = cdr(y))
      if (isCell(car(y)) && equal(x,caar(y)))
         return car(y);
   return Nil;
}

// (rassoc 'any 'lst) -> lst
any doRassoc(any x) {
   any y;
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   x = cdr(x),  y = EVAL(car(x));
   for (x = Pop(c1);  isCell(y);  y = cdr(y))
      if (isCell(car(y)) && equal(x,cdar(y)))
         return car(y);
   return Nil;
}

// (asoq 'any 'lst) -> lst
any doAsoq(any x) {
   any y;
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   x = cdr(x),  y = EVAL(car(x));
   for (x = Pop(c1);  isCell(y);  y = cdr(y))
      if (isCell(car(y)) && x == caar(y))
         return car(y);
   return Nil;
}

// (rank 'any 'lst ['flg]) -> lst
any doRank(any x) {
   any y, z;
   cell c1, c2;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   x = cdr(x),  Push(c2, y = EVAL(car(x)));
   z = Nil;
   x = cdr(x);
   if (isNil(EVAL(car(x))))
      for (x = Pop(c1);  isCell(y);  y = cdr(y)) {
         if (compare(caar(y), x) > 0)
            break;
         z = y;
      }
   else
      for (x = Pop(c1);  isCell(y);  y = cdr(y)) {
         if (compare(x, caar(y)) > 0)
            break;
         z = y;
      }
   return car(z);
}

/* Pattern matching */
bool match(any p, any d) {
   any x;

   for (;;) {
      if (!isCell(p)) {
         if (isSym(p)  &&  firstByte(p) == '@') {
            val(p) = d;
            return YES;
         }
         return equal(p,d);
      }
      if (isSym(x = car(p))  &&  firstByte(x) == '@') {
         if (!isCell(d)) {
            if (equal(d, cdr(p))) {
               val(x) = Nil;
               return YES;
            }
            return NO;
         }
         if (match(cdr(p), cdr(d))) {
            val(x) = cons(car(d), Nil);
            return YES;
         }
         if (match(cdr(p), d)) {
            val(x) = Nil;
            return YES;
         }
         if (match(p, cdr(d))) {
            val(x) = cons(car(d), val(x));
            return YES;
         }
      }
      if (!isCell(d) || !match(x, car(d)))
         return NO;
      p = cdr(p);
      d = cdr(d);
   }
}

// (match 'lst1 'lst2) -> flg
any doMatch(any x) {
   cell c1, c2;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   x = cdr(x),  Push(c2, EVAL(car(x)));
   x = match(data(c1), data(c2))? T : Nil;
   drop(c1);
   return x;
}

// Fill template structure
static any fill(any x, any s) {
   any y;
   cell c1;

   if (isNum(x))
      return NULL;
   if (isSym(x))
      return x != val(x) && (isNil(s)? x!=At && firstByte(x)=='@' : memq(x,s)!=NULL)? val(x) : NULL;
   if (car(x) == Up) {
      x = cdr(x);
      if (!isCell(y = EVAL(car(x))))
         return fill(cdr(x), s) ?: cdr(x);
      Push(c1, y);
      while (isCell(cdr(y)))
         y = cdr(y);
      cdr(y) = fill(cdr(x), s) ?: cdr(x);
      return Pop(c1);
   }
   if (y = fill(car(x), s)) {
      Push(c1,y);
      y = fill(cdr(x), s);
      return cons(Pop(c1), y ?: cdr(x));
   }
   if (y = fill(cdr(x), s))
      return cons(car(x), y);
   return NULL;
}

// (fill 'any ['sym|lst]) -> any
any doFill(any x) {
   cell c1, c2;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   x = cdr(x),  Push(c2, EVAL(car(x)));
   if (x = fill(data(c1), data(c2))) {
      drop(c1);
      return x;
   }
   return Pop(c1);
}

/* Declarative Programming */
cell *Penv, *Pnl;

static bool unify(any n1, any x1, any n2, any x2) {
   any x, env;

lookup1:
   if (isSym(x1)  &&  firstByte(x1) == '@')
      for (x = data(*Penv);  isCell(car(x));  x = cdr(x))
         if (equal(n1, caaar(x))  &&  x1 == cdaar(x)) {
            n1 = cadar(x);
            x1 = cddar(x);
            goto lookup1;
         }
lookup2:
   if (isSym(x2)  &&  firstByte(x2) == '@')
      for (x = data(*Penv);  isCell(car(x));  x = cdr(x))
         if (equal(n2, caaar(x))  &&  x2 == cdaar(x)) {
            n2 = cadar(x);
            x2 = cddar(x);
            goto lookup2;
         }
   if (equal(n1, n2)  &&  equal(x1, x2))
      return YES;
   if (isSym(x1)  &&  firstByte(x1) == '@') {
      if (x1 != At) {
         data(*Penv) = cons(cons(cons(n1,x1), Nil), data(*Penv));
         cdar(data(*Penv)) = cons(n2,x2);
      }
      return YES;
   }
   if (isSym(x2)  &&  firstByte(x2) == '@') {
      if (x2 != At) {
         data(*Penv) = cons(cons(cons(n2,x2), Nil), data(*Penv));
         cdar(data(*Penv)) = cons(n1,x1);
      }
      return YES;
   }
   if (!isCell(x1) || !isCell(x2))
      return equal(x1, x2);
   env = data(*Penv);
   if (unify(n1, car(x1), n2, car(x2))  &&  unify(n1, cdr(x1), n2, cdr(x2)))
      return YES;
   data(*Penv) = env;
   return NO;
}

static any lup(any n, any x) {
   any y;
   cell c1;

lup:
   if (isSym(x)  &&  firstByte(x) == '@')
      for (y = data(*Penv);  isCell(car(y));  y = cdr(y))
         if (equal(n, caaar(y))  &&  x == cdaar(y)) {
            n = cadar(y);
            x = cddar(y);
            goto lup;
         }
   if (!isCell(x))
      return x;
   Push(c1, lup(n, car(x)));
   x = lup(n, cdr(x));
   return cons(Pop(c1), x);
}

static any lookup(any n, any x) {
   return isSym(x = lup(n,x)) && firstByte(x)=='@'?  Nil : x;
}

static any uniFill(any x) {
   cell c1;

   if (isNum(x))
      return x;
   if (isSym(x))
      return lup(car(data(*Pnl)), x);
   Push(c1, uniFill(car(x)));
   x = uniFill(cdr(x));
   return cons(Pop(c1), x);
}

// (prove 'lst ['lst]) -> lst
any doProve(any x) {
   int i;
   cell *envSave, *nlSave, at, q, dbg, env, n, nl, alt, tp1, tp2, e;

   x = cdr(x);
   if (!isCell(data(q) = EVAL(car(x))))
      return Nil;
   Save(q);
   Push(at,val(At));
   envSave = Penv,  Penv = &env,  nlSave = Pnl,  Pnl = &nl;
   if (x = cdr(x), isNil(x = EVAL(car(x))))
      data(dbg) = NULL;
   else
      Push(dbg, x);
   Push(env, caar(data(q))),  car(data(q)) = cdar(data(q));
   Push(n, car(data(env))),  data(env) = cdr(data(env));
   Push(nl, car(data(env))),  data(env) = cdr(data(env));
   Push(alt, car(data(env))),  data(env) = cdr(data(env));
   Push(tp1, car(data(env))),  data(env) = cdr(data(env));
   Push(tp2, car(data(env))),  data(env) = cdr(data(env));
   Push(e,Nil);
   while (isCell(data(tp1)) || isCell(data(tp2))) {
      if (isCell(data(alt))) {
         data(e) = data(env);
         if (!unify(car(data(nl)), cdar(data(tp1)), data(n), caar(data(alt)))) {
            if (!isCell(data(alt) = cdr(data(alt)))) {
               data(env) = caar(data(q)),  car(data(q)) = cdar(data(q));
               data(n) = car(data(env)),  data(env) = cdr(data(env));
               data(nl) = car(data(env)),  data(env) = cdr(data(env));
               data(alt) = car(data(env)),  data(env) = cdr(data(env));
               data(tp1) = car(data(env)),  data(env) = cdr(data(env));
               data(tp2) = car(data(env)),  data(env) = cdr(data(env));
            }
         }
         else {
            if (data(dbg)  &&  memq(caar(data(tp1)), data(dbg))) {
               outWord(indx(car(data(alt)), get(caar(data(tp1)), T)));
               space();
               print(uniFill(car(data(tp1)))), newline();
            }
            if (isCell(cdr(data(alt))))
               car(data(q)) =
                  cons(
                     cons(data(n),
                        cons(data(nl),
                           cons(cdr(data(alt)),
                              cons(data(tp1), cons(data(tp2),data(e))) ) ) ),
                     car(data(q)) );
            data(nl) = cons(data(n), data(nl));
            data(n) = box(2 + unDig(data(n)));
            data(tp2) = cons(cdr(data(tp1)), data(tp2));
            data(tp1) = cdar(data(alt));
            data(alt) = Nil;
         }
      }
      else if (!isCell(x = data(tp1))) {
         data(tp1) = car(data(tp2)),  data(tp2) = cdr(data(tp2));
         data(nl) = cdr(data(nl));
      }
      else if (car(x) == T) {
         while (isCell(car(data(q)))  &&
                              unDig(caaar(data(q))) >= unDig(car(data(nl))) )
            car(data(q)) = cdar(data(q));
         data(tp1) = cdr(x);
      }
      else if (isNum(caar(x))) {
         data(e) = prog(cdar(x));
         for (i = unDig(caar(x)), x = data(nl);  (i -= 2) > 0;)
            x = cdr(x);
         data(nl) = cons(car(x), data(nl));
         data(tp2) = cons(cdr(data(tp1)), data(tp2));
         data(tp1) = data(e);
      }
      else if (caar(x) == Up) {
         if (!isNil(data(e) = prog(cddar(x)))  &&
                     unify(car(data(nl)), cadar(x), car(data(nl)), data(e)) )
            data(tp1) = cdr(x);
         else {
            data(env) = caar(data(q)),  car(data(q)) = cdar(data(q));
            data(n) = car(data(env)),  data(env) = cdr(data(env));
            data(nl) = car(data(env)),  data(env) = cdr(data(env));
            data(alt) = car(data(env)),  data(env) = cdr(data(env));
            data(tp1) = car(data(env)),  data(env) = cdr(data(env));
            data(tp2) = car(data(env)),  data(env) = cdr(data(env));
         }
      }
      else if (!isCell(data(alt) = get(caar(x), T))) {
         data(env) = caar(data(q)),  car(data(q)) = cdar(data(q));
         data(n) = car(data(env)),  data(env) = cdr(data(env));
         data(nl) = car(data(env)),  data(env) = cdr(data(env));
         data(alt) = car(data(env)),  data(env) = cdr(data(env));
         data(tp1) = car(data(env)),  data(env) = cdr(data(env));
         data(tp2) = car(data(env)),  data(env) = cdr(data(env));
      }
   }
   for (data(e) = Nil,  x = data(env);  isCell(cdr(x));  x = cdr(x))
      if (isNum(caaar(x)) && IsZero(caaar(x)))
         data(e) = cons(cons(cdaar(x), lookup(Zero, cdaar(x))), data(e));
   val(At) = data(at);
   drop(q);
   Penv = envSave,  Pnl = nlSave;
   return isCell(data(e))? data(e) : isCell(data(env))? T : Nil;
}

// (-> any [cnt]) -> any
any doArrow(any x) {
   int i;
   any y;

   if (!isNum(caddr(x)))
      return lookup(car(data(*Pnl)), cadr(x));
   for (i = unDig(caddr(x)), y = data(*Pnl);  (i -= 2) > 0;)
      y = cdr(y);
   return lookup(car(y), cadr(x));
}

// (unify 'any) -> lst
any doUnify(any x) {
   cell c1;

   Push(c1, EVAL(cadr(x)));
   if (unify(cadr(data(*Pnl)), data(c1), car(data(*Pnl)), data(c1))) {
      drop(c1);
      return data(*Penv);
   }
   drop(c1);
   return Nil;
}

/* List Merge Sort: Bill McDaniel, DDJ Jun99 */
static bool cmp(any ex, any foo, cell c[2]) {
   if (isNil(foo))
      return compare(car(data(c[0])), car(data(c[1]))) < 0;
   return !isNil(apply(ex, foo, YES, 2, c));
}

// (group 'lst) -> lst
any doGroup(any x) {
   any y, z;
   cell c1, c2;

   x = cdr(x);
   if (!isCell(x = EVAL(car(x))))
      return Nil;
   Push(c1, x);
   Push(c2, y = cons(cdar(x), Nil));
   data(c2) = cons(cons(caar(x), cons(y,y)), Nil);
   while (isCell(x = cdr(x))) {
      y = cons(cdar(x), Nil);
      for (z = data(c2);;) {
         if (equal(caar(z), caar(x))) {
            z = cdar(z),  car(z) = cdar(z) = y;
            break;
         }
         if (!isCell(cdr(z))) {
            cdr(z) = y;
            cdr(z) = cons(cons(caar(x), cons(y,y)), Nil);
            break;
         }
         z = cdr(z);
      }
   }
   x = data(c2);
   do
      cdar(x) = cddar(x);
   while (isCell(x = cdr(x)));
   drop(c1);
   return data(c2);
}

// (sort 'lst ['fun]) -> lst
any doSort(any ex) {
   int i;
   any x;
   cell p, foo, in[2], out[2], last[2];
   any *tail[2];

   x = cdr(ex);
   if (!isCell(data(out[0]) = EVAL(car(x))))
      return data(out[0]);
   Save(out[0]);
   x = cdr(x),  Push(foo, EVAL(car(x)));
   Push(out[1], Nil);
   Save(in[0]);
   Save(in[1]);
   Push(p, Nil);
   Push(last[1], Nil);
   do {
      data(in[0]) = data(out[0]);
      data(in[1]) = data(out[1]);

      i = isCell(data(in[1]))  &&  !cmp(ex, data(foo), in);
      if (isCell(data(p) = data(in[i])))
         data(in[i]) = cdr(data(in[i]));
      data(out[0]) = data(p);
      tail[0] = &cdr(data(p));
      data(last[1]) = data(out[0]);
      cdr(data(p)) = Nil;
      i = 0;
      data(out[1]) = Nil;
      tail[1] = &data(out[1]);
      while (isCell(data(in[0])) || isCell(data(in[1]))) {
         if (!isCell(data(in[1]))) {
            if (isCell(data(p) = data(in[0])))
               data(in[0]) = cdr(data(in[0]));
            data(last[0]) = data(p);
            if (cmp(ex, data(foo), last))
               i = 1 - i;
         }
         else if (!isCell(data(in[0]))) {
            data(last[0]) = data(p) = data(in[1]),  data(in[1]) = cdr(data(in[1]));
            if (cmp(ex, data(foo), last))
               i = 1 - i;
         }
         else if (data(last[0]) = data(in[0]),  cmp(ex, data(foo), last)) {
            data(last[0]) = data(in[1]);
            if (!cmp(ex, data(foo), last))
               data(p) = data(in[1]),  data(in[1]) = cdr(data(in[1]));
            else {
               if (cmp(ex, data(foo), in))
                  data(p) = data(in[0]),  data(in[0]) = cdr(data(in[0]));
               else
                  data(p) = data(in[1]),  data(in[1]) = cdr(data(in[1]));
               i = 1 - i;
            }
         }
         else {
            data(last[0]) = data(in[1]);
            if (cmp(ex, data(foo), last))
               data(p) = data(in[0]),  data(in[0]) = cdr(data(in[0]));
            else {
               if (cmp(ex, data(foo), in))
                  data(p) = data(in[0]),  data(in[0]) = cdr(data(in[0]));
               else
                  data(p) = data(in[1]),  data(in[1]) = cdr(data(in[1]));
            }
         }
         *tail[i] = data(p);
         tail[i] = &cdr(data(p));
         cdr(data(p)) = Nil;
         data(last[1]) = data(p);
      }
   } while (isCell(data(out[1])));
   return Pop(out[0]);
}
