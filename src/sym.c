/* 06jun03abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

/* ELF hash algorithm */
unsigned long hash(any x) {
   unsigned long g, h;
   word n;

   for (h = 0; isNum(x); x = cdr(numCell(x)))
      for (n = unDig(x); n; n >>= 8)
         g = (h = (h<<4) + (n&0xFF)) & 0xF0000000,  h = (h ^ g>>24) & ~g;
   return h % HASH;
}

bool hashed(any s, long h, any *tab) {
   any x;

   for (x = tab[h];  isCell(x);  x = cdr(x))
      if (s == car(x))
         return YES;
   return NO;
}

any findHash(any s, any *p) {
   any x, y, *q, h;

   if (isCell(h = *p)) {
      x = s,  y = name(car(h));
      while (unDig(x) == unDig(y)) {
         x = cdr(numCell(x));
         y = cdr(numCell(y));
         if (!isNum(x) && !isNum(y))
            return car(h);
      }
      while (isCell(h = *(q = &cdr(h)))) {
         x = s,  y = name(car(h));
         while (unDig(x) == unDig(y)) {
            x = cdr(numCell(x));
            y = cdr(numCell(y));
            if (!isNum(x) && !isNum(y)) {
               *q = cdr(h),  cdr(h) = *p,  *p = h;
               return car(h);
            }
         }
      }
   }
   return NULL;
}

/* Get symbol name */
any name(any s) {
   s = tail(s);
   while (isCell(s))
      s = cdr(s);
   return s;
}

/* Find or create single-char symbol */
any mkChar(int c) {
   any x;

   if (c == TOP)
      c = 0xFF;
   else if (c >= 0x80) {
      if (c < 0x800)
         c = 0xC0 | c>>6 & 0x1F  |  (0x80 | c & 0x3F) << 8;
      else
         c = 0xE0 | c>>12 & 0x0F  |  (0x80 | c>>6 & 0x3F) << 8  |  (0x80 | c & 0x3F) << 16;
      return consStr(box(c));
   }
   for (x = Transient[c];  isCell(x);  x = cdr(x))
      if (num(c) == unDig(name(car(x))))
         return car(x);
   x = consStr(box(c));
   Transient[c] = cons(x, Transient[c]);
   return x;
}

/* Make name */
any mkName(byte *s) {
   int i;
   any nm;
   cell c1;

   i = 0,  Push(c1, nm = box(*s++));
   while (*s)
      byteSym(*s++, &i, &nm);
   return Pop(c1);
}

/* Make string */
any mkStr(char *s) {return s && *s? consStr(mkName((byte*)s)) : Nil;}

/* Get first byte of symbol name */
int firstByte(any s) {
   return !isNum(s = name(s))? 0 : unDig(s) & 0xFF;
}

bool isBlank(any x) {
   int c;

   if (!isSym(x))
      return NO;
   for (c = symChar(name(x)); c; c = symChar(NULL))
      if (c > ' ')
         return NO;
   return YES;
}

// (sp? 'any) -> flg
any doSpQ(any x) {
   x = cdr(x);
   return isBlank(EVAL(car(x)))? T : Nil;
}

// (pat? 'any) -> flg
any doPatQ(any x) {
   x = cdr(x);
   return isSym(x = EVAL(car(x))) && firstByte(x) == '@'? T : Nil;
}

// (fun? 'any) -> any
any doFunQ(any x) {
   any y;

   x = cdr(x);
   if (isSym(x = EVAL(car(x))))
      return Nil;
   if (isNum(x))
      return (unDig(x)&3) || isNum(cdr(numCell(x)))? Nil : Zero;
   if (!isCell(cdr(x)))
      return Nil;
   if (isNil(x = car(x)))
      return T;
   for (y = x; isCell(y); y = cdr(y))
      if (isNum(car(y)) || isCell(car(y)))
         return Nil;
   return isSym(y)? x : Nil;
}

// (intern 'sym) -> sym
any doIntern(any ex) {
   any x, y, *h;

   x = cdr(ex),  x = EVAL(car(x));
   NeedSym(ex,x);
   if (!isNum(y = name(x)))
      return Nil;
   if (y = findHash(y, h = Intern + hash(y)))
      return y;
   *h = cons(x,*h);
   return x;
}

// (extern 'sym) -> sym|NIL
any doExtern(any ex) {
   int c, i;
   any x, y, *h, nm;
   cell c1, c2;

   x = cdr(ex),  x = EVAL(car(x));
   NeedSym(ex,x);
   if (!isNum(x = name(x)))
      return Nil;
   if (!(y = findHash(x, h = Extern + hash(x)))) {
      Push(c1, x);
      if ((c = symChar(x)) == '{')
         c = symChar(NULL);
      Push(c2, boxChar(c, &i, &nm));
      while ((c = symChar(NULL)) && c != '}')
         charSym(c, &i, &nm);
      if (!(y = findHash(data(c2), h = Extern + hash(data(c2))))) {
         y = extSym(consSym(Nil,data(c2)));
         *h = cons(y,*h);
      }
      drop(c1);
   }
   return isLife(y)? y : Nil;
}

// (==== ['sym ..]) -> NIL
any doHide(any ex) {
   any x, y, z, *h;
   int i;

   for (i = 0; i < HASH; ++i)
      Transient[i] = Nil;
   for (x = cdr(ex); isCell(x); x = cdr(x)) {
      y = EVAL(car(x));
      NeedSym(ex,y);
      if (isNum(z = name(y)) && !findHash(z, h = Transient + hash(z)))
         *h = cons(y, *h);
   }
   return Nil;
}

// (str? 'any) -> flg
any doStrQ(any x) {
   x = cdr(x);
   return isSym(x = EVAL(car(x))) && !isExt(x) && !hashed(x,hash(name(x)),Intern)? T : Nil;
}

// (ext? 'any) -> flg
any doExtQ(any x) {
   x = cdr(x);
   return isExt(x = EVAL(car(x))) && isLife(x) ? T : Nil;
}

// (touch 'sym) -> sym
any doTouch(any ex) {
   any x = cdr(ex);
   x = EVAL(car(x));
   NeedSym(ex,x);
   Touch(ex,x);
   return x;
}

// (zap 'sym) -> sym
any doZap(any ex) {
   any x, y, *h;

   x = cdr(ex),  x = EVAL(car(x));
   NeedSym(ex,x);
   if (isExt(x))
      db(ex,x,3);
   else {
      CheckVar(ex,x);
      for (h = Intern + hash(name(x)); isCell(y = *h); h = &y->cdr)
         if (x == car(y)) {
            *h = cdr(y);
            break;
         }
   }
   return x;
}

// (chop 'any) -> lst
any doChop(any x) {
   int c;
   cell c1, c2;

   if (isCell(x = EVAL(cadr(x))))
      return x;
   if (!(c = symChar(name(x = xSym(x)))))
      return Nil;
   Push(c1, x);
   Push(c2, x = cons(mkChar(c), Nil));
   while (c = symChar(NULL))
      x = cdr(x) = cons(mkChar(c), Nil);
   drop(c1);
   return data(c2);
}

void pack(any x, int *i, any *nm, cell *p) {
   int c;

   if (isCell(x))
      do
         pack(car(x), i, nm, p);
      while (isCell(x = cdr(x)));
   if (!isNil(x)) {
      if (isNum(x))
         x = numToSym(x, 0, 0, 0);
      if (c = symChar(name(x))) {
         if (*nm) {
            if (isExt(x))
               charSym('{', i, nm);
            charSym(c, i, nm);
         }
         else if (!isExt(x))
            Push(*p, boxChar(c, i, nm));
         else {
            Push(*p, boxChar('{', i, nm));
            charSym(c, i, nm);
         }
         while (c = symChar(NULL))
            charSym(c, i, nm);
         if (isExt(x))
            charSym('}', i, nm);
      }
   }
}

// (pack 'any ..) -> sym
any doPack(any x) {
   int i;
   any nm;
   cell c1, c2;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   nm = NULL,  pack(data(c1), &i, &nm, &c2);
   while (isCell(x = cdr(x)))
      pack(data(c1) = EVAL(car(x)), &i, &nm, &c2);
   drop(c1);
   return nm? consStr(data(c2)) : Nil;
}

static bool subStr(word n1, any y, word n2, any x) {
   for (;;) {
      if ((n1 & 0xFF) != (n2 & 0xFF))
         return NO;
      if ((n1 >>= 8) == 0) {
         if (!isNum(y = cdr(numCell(y))))
            return YES;
         n1 = unDig(y);
      }
      if ((n2 >>= 8) == 0) {
         if (!isNum(x = cdr(numCell(x))))
            return NO;
         n2 = unDig(x);
      }
   }
}

// (pre? 'sym1 'sym2) -> flg
any doPreQ(any ex) {
   any x, y;
   cell c1;

   x = cdr(ex);
   if (isNil(y = EVAL(car(x))))
      return T;
   NeedSym(ex,y);
   if (!isNum(y = name(y)))
      return T;
   Push(c1, y);
   x = cdr(x),  x = EVAL(car(x));
   NeedSym(ex,x);
   drop(c1);
   if (!isNum(x = name(x)))
      return Nil;
   return subStr(unDig(y), y, unDig(x), x)? T : Nil;
}

// (sub? 'sym1 'sym2) -> flg
any doSubQ(any ex) {
   any x, y;
   word n;
   cell c1;

   x = cdr(ex);
   if (isNil(y = EVAL(car(x))))
      return T;
   NeedSym(ex,y);
   if (!isNum(y = name(y)))
      return T;
   Push(c1, y);
   x = cdr(x),  x = EVAL(car(x));
   NeedSym(ex,x);
   drop(c1);
   if (!isNum(x = name(x)))
      return Nil;
   n = unDig(x);
   for (;;) {
      if (subStr(unDig(y), y, n, x))
         return T;
      if ((n >>= 8) == 0) {
         if (!isNum(x = cdr(numCell(x))))
            return Nil;
         n = unDig(x);
      }
   }
}

// (upp? 'any) -> flg
any doUppQ(any x) {
   x = cdr(x);
   return isSym(x = EVAL(car(x))) && isUppc(symChar(name(x)))? T : Nil;
}

// (low? 'any) -> flg
any doLowQ(any x) {
   x = cdr(x);
   return isSym(x = EVAL(car(x))) && isLowc(symChar(name(x)))? T : Nil;
}

// (uppc 'any) -> any
any doUppc(any x) {
   int c, i;
   any nm;
   cell c1, c2;

   x = cdr(x);
   if (!isSym(x = EVAL(car(x))) || !(c = symChar(name(x))))
      return x;
   Push(c1, x);
   if (isLowc(c))
      c &= ~0x20;
   Push(c2, boxChar(c, &i, &nm));
   while (c = symChar(NULL)) {
      if (isLowc(c))
         c &= ~0x20;
      charSym(c, &i, &nm);
   }
   drop(c1);
   return consStr(data(c2));
}

// (lowc 'any) -> any
any doLowc(any x) {
   int c, i;
   any nm;
   cell c1, c2;

   x = cdr(x);
   if (!isSym(x = EVAL(car(x))) || !(c = symChar(name(x))))
      return x;
   Push(c1, x);
   if (isUppc(c))
      c |= 0x20;
   Push(c2, boxChar(c, &i, &nm));
   while (c = symChar(NULL)) {
      if (isUppc(c))
         c |= 0x20;
      charSym(c, &i, &nm);
   }
   drop(c1);
   return consStr(data(c2));
}

// (val 'var) -> any
any doVal(any ex) {
   any x;

   x = cdr(ex),  x = EVAL(car(x));
   NeedVar(ex,x);
   Fetch(ex,x);
   return val(x);
}

// (set 'var 'any ..) -> any
any doSet(any ex) {
   any x;
   cell c1, c2;

   x = cdr(ex);
   do {
      Push(c1, EVAL(car(x))),  x = cdr(x);
      NeedVar(ex,data(c1));
      CheckVar(ex,data(c1));
      Push(c2, EVAL(car(x))),  x = cdr(x);
      Touch(ex,data(c1));
      val(data(c1)) = data(c2);
      drop(c1);
   } while (isCell(x));
   return val(data(c1));
}

// (setq sym 'any ..) -> any
any doSetq(any ex) {
   any x, y;

   x = cdr(ex);
   do {
      y = car(x),  x = cdr(x);
      NeedSym(ex,y);
      val(y) = EVAL(car(x));
   } while (isCell(x = cdr(x)));
   return val(y);
}

// (xchg 'var 'var ..) -> any
any doXchg(any ex) {
   any x, y;
   cell c1, c2;

   x = cdr(ex);
   do {
      Push(c1, EVAL(car(x))),  x = cdr(x);
      NeedVar(ex,data(c1));
      CheckVar(ex,data(c1));
      Push(c2, EVAL(car(x))),  x = cdr(x);
      NeedVar(ex,data(c2));
      CheckVar(ex,data(c2));
      Touch(ex,data(c1));
      Touch(ex,data(c2));
      y = val(data(c1)),  val(data(c1)) = val(data(c2)),  val(data(c2)) = y;
      drop(c1);
   } while (isCell(x));
   return y;
}

// (on sym ..) -> T
any doOn(any ex) {
   any x = cdr(ex);
   do {
      NeedSym(ex,car(x));
      val(car(x)) = T;
   } while (isCell(x = cdr(x)));
   return T;
}

// (off sym ..) -> NIL
any doOff(any ex) {
   any x = cdr(ex);
   do {
      NeedSym(ex,car(x));
      val(car(x)) = Nil;
   } while (isCell(x = cdr(x)));
   return Nil;
}

// (zero sym ..) -> 0
any doZero(any ex) {
   any x = cdr(ex);
   do {
      NeedSym(ex,car(x));
      val(car(x)) = Zero;
   } while (isCell(x = cdr(x)));
   return Zero;
}

// (default sym 'any ..) -> any
any doDefault(any ex) {
   any x, y;

   x = cdr(ex);
   do {
      y = car(x),  x = cdr(x);
      NeedSym(ex,y);
      if (isNil(val(y)))
         val(y) = EVAL(car(x));
   } while (isCell(x = cdr(x)));
   return val(y);
}

// (push 'var 'any ..) -> any
any doPush(any ex) {
   any x;
   cell c1, c2;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   NeedVar(ex,data(c1));
   CheckVar(ex,data(c1));
   x = cdr(x),  Push(c2, EVAL(car(x)));
   Touch(ex,data(c1));
   val(data(c1)) = cons(data(c2), val(data(c1)));
   while (isCell(x = cdr(x))) {
      data(c2) = EVAL(car(x));
      Touch(ex,data(c1));
      val(data(c1)) = cons(data(c2), val(data(c1)));
   }
   drop(c1);
   return data(c2);
}

// (pop 'var) -> any
any doPop(any ex) {
   any x, y;

   x = cdr(ex),  x = EVAL(car(x));
   NeedVar(ex,x);
   CheckVar(ex,x);
   Touch(ex,x);
   if (!isCell(y = val(x)))
      return y;
   val(x) = cdr(y);
   return car(y);
}

// (cut 'cnt 'var) -> lst
any doCut(any ex) {
   long n;
   any x, y;
   cell c1, c2;

   if ((n = evCnt(ex, x = cdr(ex))) <= 0)
      return Nil;
   x = cdr(x),  Push(c1, EVAL(car(x)));
   NeedVar(ex,data(c1));
   CheckVar(ex,data(c1));
   if (isCell(val(data(c1)))) {
      Touch(ex,data(c1));
      Push(c2, y = cons(car(val(data(c1))), Nil));
      while (isCell(val(data(c1)) = cdr(val(data(c1)))) && --n)
         y = cdr(y) = cons(car(val(data(c1))), Nil);
      drop(c1);
      return data(c2);
   }
   return val(Pop(c1));
}

// (queue 'var 'any) -> any
any doQueue(any ex) {
   any x, y;
   cell c1;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   NeedVar(ex,data(c1));
   CheckVar(ex,data(c1));
   x = cdr(x),  x = EVAL(car(x));
   Touch(ex,data(c1));
   if (!isCell(y = val(data(c1))))
      val(data(c1)) = cons(x,Nil);
   else {
      while (isCell(cdr(y)))
         y = cdr(y);
      cdr(y) = cons(x,Nil);
   }
   drop(c1);
   return x;
}

static void idx(any x, cell *p) {
   if (isCell(cddr(x)))
      idx(cddr(x), p);
   data(*p) = cons(car(x), data(*p));
   if (isCell(cadr(x)))
      idx(cadr(x), p);
}

// (idx 'var 'any 'flg) -> flg
// (idx 'var 'any) -> flg
// (idx 'var) -> lst
any doIdx(any ex) {
   any x, y, z, *p;
   int flg, n;
   cell c1, c2;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   NeedVar(ex,data(c1));
   CheckVar(ex,data(c1));
   if (!isCell(x = cdr(x))) {
      Push(c2, Nil);
      idx(val(data(c1)), &c2);
      drop(c1);
      return data(c2);
   }
   Push(c2, EVAL(car(x)));
   flg = !isCell(cdr(x))? 0 : isNil(EVAL(cadr(x)))? -1 : +1;
   if (!isCell(x = val(data(c1)))) {
      if (flg > 0) {
         Touch(ex,data(c1));
         val(data(c1)) = cons(data(c2),Nil);
      }
      drop(c1);
      return Nil;
   }
   p = (any*)cellPtr(data(c1));
   for (;;) {
      if ((n = compare(data(c2), car(x))) == 0) {
         if (flg < 0) {
            Touch(ex,data(c1));
            if (!isCell(cadr(x)))
               *p = cddr(x);
            else if (!isCell(y = cddr(x)))
               *p = cadr(x);
            else if (!isCell(z = cadr(y)))
               car(x) = car(y),  cddr(x) = cddr(y);
            else {
               while (isCell(cadr(z)))
                  z = cadr(y = z);
               car(x) = car(z),  cadr(y) = cddr(z);
            }
         }
         drop(c1);
         return T;
      }
      if (!isCell(cdr(x))) {
         if (flg > 0) {
            Touch(ex,data(c1));
            cdr(x) = n < 0?
               cons(cons(data(c2),Nil), Nil) : cons(Nil, cons(data(c2),Nil));
         }
         drop(c1);
         return Nil;
      }
      if (n < 0) {
         if (!isCell(cadr(x))) {
            if (flg > 0) {
               Touch(ex,data(c1));
               cadr(x) = cons(data(c2),Nil);
            }
            drop(c1);
            return Nil;
         }
         x = *(p = &cadr(x));
      }
      else {
         if (!isCell(cddr(x))) {
            if (flg > 0) {
               Touch(ex,data(c1));
               cddr(x) = cons(data(c2),Nil);
            }
            drop(c1);
            return Nil;
         }
         x = *(p = &cddr(x));
      }
   }
}

any put(any x, any key, any val) {
   any y, z;

   if (isCell(y = tail(x))) {
      if (isCell(car(y))) {
         if (key == cdar(y)) {
            if (isNil(val))
               tail(x) = cdr(y);
            else if (val == T)
               car(y) = key;
            else
               caar(y) = val;
            return val;
         }
      }
      else if (key == car(y)) {
         if (isNil(val))
            tail(x) = cdr(y);
         else if (val != T)
            car(y) = cons(val,key);
         return val;
      }
      while (isCell(z = cdr(y))) {
         if (isCell(car(z))) {
            if (key == cdar(z)) {
               if (isNil(val))
                  cdr(y) = cdr(z);
               else {
                  if (val == T)
                     car(z) = key;
                  else
                     caar(z) = val;
                  cdr(y) = cdr(z),  cdr(z) = tail(x),  tail(x) = z;
               }
               return val;
            }
         }
         else if (key == car(z)) {
            if (isNil(val))
               cdr(y) = cdr(z);
            else {
               if (val != T)
                  car(z) = cons(val,key);
               cdr(y) = cdr(z),  cdr(z) = tail(x),  tail(x) = z;
            }
            return val;
         }
         y = z;
      }
   }
   if (!isNil(val))
      tail(x) = cons(val==T? key : cons(val,key), tail(x));
   return val;
}

any get(any x, any key) {
   any y, z;

   if (!isCell(y = tail(x)))
      return Nil;
   if (!isCell(car(y))) {
      if (key == car(y))
         return T;
   }
   else if (key == cdar(y))
      return caar(y);
   while (isCell(z = cdr(y))) {
      if (!isCell(car(z))) {
         if (key == car(z)) {
            cdr(y) = cdr(z),  cdr(z) = tail(x),  tail(x) = z;
            return T;
         }
      }
      else if (key == cdar(z)) {
         cdr(y) = cdr(z),  cdr(z) = tail(x),  tail(x) = z;
         return caar(z);
      }
      y = z;
   }
   return Nil;
}

any prop(any x, any key) {
   any y, z;

   if (!isCell(y = tail(x)))
      return Nil;
   if (!isCell(car(y))) {
      if (key == car(y))
         return key;
   }
   else if (key == cdar(y))
      return car(y);
   while (isCell(z = cdr(y))) {
      if (!isCell(car(z))) {
         if (key == car(z)) {
            cdr(y) = cdr(z),  cdr(z) = tail(x),  tail(x) = z;
            return key;
         }
      }
      else if (key == cdar(z)) {
         cdr(y) = cdr(z),  cdr(z) = tail(x),  tail(x) = z;
         return car(z);
      }
      y = z;
   }
   return Nil;
}

// (put 'sym1|lst ['sym2|cnt ..] 'sym 'any) -> any
any doPut(any ex) {
   any x;
   cell c1, c2, c3;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   x = cdr(x),  Push(c2, EVAL(car(x)));
   while (isCell(cdr(x = cdr(x)))) {
      if (isCell(data(c1))) {
         NeedNum(ex,data(c2));
         data(c1) = car(nth(unDig(data(c2))/2, data(c1)));
      }
      else {
         NeedSym(ex,data(c1));
         Fetch(ex,data(c1));
         data(c1) = get(data(c1), data(c2));
      }
      data(c2) = EVAL(car(x));
   }
   NeedSym(ex,data(c1));
   CheckNil(ex,data(c1));
   Push(c3, EVAL(car(x)));
   Touch(ex,data(c1));
   x = put(data(c1), data(c2), data(c3));
   drop(c1);
   return x;
}

// (get 'sym1|lst ['sym2|cnt ..]) -> any
any doGet(any ex) {
   any x, y;
   cell c1;

   x = cdr(ex),  data(c1) = EVAL(car(x));
   if (!isCell(x = cdr(x)))
      return data(c1);
   Save(c1);
   do {
      y = EVAL(car(x));
      if (isCell(data(c1))) {
         NeedNum(ex,y);
         data(c1) = car(nth(unDig(y)/2, data(c1)));
      }
      else {
         NeedSym(ex,data(c1));
         Fetch(ex,data(c1));
         data(c1) = get(data(c1), y);
      }
   } while (isCell(x = cdr(x)));
   return Pop(c1);
}

// (prop 'sym1|lst ['sym2|cnt ..] 'sym) -> lst|sym
any doProp(any ex) {
   any x, y;
   cell c1;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   x = cdr(x),  y = EVAL(car(x));
   while (isCell(x = cdr(x))) {
      if (isCell(data(c1))) {
         NeedNum(ex,y);
         data(c1) = car(nth(unDig(y)/2, data(c1)));
      }
      else {
         NeedSym(ex,data(c1));
         Fetch(ex,data(c1));
         data(c1) = get(data(c1), y);
      }
      y = EVAL(car(x));
   }
   NeedSym(ex,data(c1));
   Fetch(ex,data(c1));
   return prop(Pop(c1), y);
}

// (=: sym [sym1|cnt .. sym2] 'any) -> any
any doSetCol(any ex) {
   any x, y, z;
   cell c1;

   x = cdr(ex);
   y = val(This);
   if (z = car(x),  isCell(cdr(x = cdr(x)))) {
      y = get(y,z);
      while (z = car(x),  isCell(cdr(x = cdr(x)))) {
         if (isCell(y)) {
            NeedNum(ex,z);
            y = car(nth(unDig(z)/2, y));
         }
         else {
            NeedSym(ex,y);
            Fetch(ex,y);
            y = get(y,z);
         }
      }
   }
   NeedSym(ex,y);
   CheckNil(ex,y);
   Push(c1, EVAL(car(x)));
   Touch(ex,y);
   x = put(y, z, data(c1));
   drop(c1);
   return x;
}

// (: sym [sym1|cnt .. sym2]) -> any
any doCol(any ex) {
   any x, y;

   x = cdr(ex),  y = get(val(This), car(x));
   while (isCell(x = cdr(x))) {
      if (isCell(y)) {
         NeedNum(ex,car(x));
         y = car(nth(unDig(car(x))/2, y));
      }
      else {
         NeedSym(ex,y);
         Fetch(ex,y);
         y = get(y,car(x));
      }
   }
   return y;
}

// (:: sym [sym1|cnt .. sym2]) -> lst|sym
any doPropCol(any ex) {
   any x, y;

   x = cdr(ex),  y = prop(val(This), car(x));
   while (isCell(x = cdr(x))) {
      if (isCell(y))
         y = car(y);
      if (isCell(y)) {
         NeedNum(ex,car(x));
         y = car(nth(unDig(car(x))/2, y));
      }
      else {
         NeedSym(ex,y);
         Fetch(ex,y);
         y = prop(y,car(x));
      }
   }
   return y;
}

// (putl 'sym1|lst1 ['sym2|cnt ..] 'lst) -> lst
any doPutl(any ex) {
   any x, y;
   cell c1, c2;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   x = cdr(x),  Push(c2, EVAL(car(x)));
   while (isCell(x = cdr(x))) {
      if (isCell(data(c1))) {
         NeedNum(ex,data(c2));
         data(c1) = car(nth(unDig(data(c2))/2, data(c1)));
      }
      else {
         NeedSym(ex,data(c1));
         Fetch(ex,data(c1));
         data(c1) = get(data(c1), data(c2));
      }
      data(c2) = EVAL(car(x));
   }
   NeedSym(ex,data(c1));
   NeedLst(ex,data(c2));
   CheckNil(ex,data(c1));
   Touch(ex,data(c1));
   x = cellPtr(data(c1));
   while (isCell(cdr(x)))
      cdr(x) = cddr(x);
   for (y = data(c2);  isCell(y);  y = cdr(y))
      cdr(x) = cons(car(y),cdr(x)),  x = cdr(x);
   drop(c1);
   return data(c2);
}

// (getl 'sym1|lst1 ['sym2|cnt ..]) -> lst
any doGetl(any ex) {
   any x, y;
   cell c1, c2;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   while (isCell(x = cdr(x))) {
      y = EVAL(car(x));
      if (isCell(data(c1))) {
         NeedNum(ex,y);
         data(c1) = car(nth(unDig(y)/2, data(c1)));
      }
      else {
         NeedSym(ex,data(c1));
         Fetch(ex,data(c1));
         data(c1) = get(data(c1), y);
      }
   }
   NeedSym(ex,data(c1));
   Fetch(ex,data(c1));
   if (!isCell(x = tail(data(c1))))
      data(c2) = Nil;
   else {
      Push(c2, y = cons(car(x),Nil));
      while (isCell(x = cdr(x)))
         y = cdr(y) = cons(car(x),Nil);
   }
   drop(c1);
   return data(c2);
}

static void wipe(any ex, any x) {
   any y, z;

   y = tail(x);
   while (isCell(y))
      y = cdr(y);
   z = numCell(y);
   while (isNum(cdr(z)))
      z = numCell(cdr(z));
   if (!isNil(cdr(z)) && cdr(z) != At)
      err(ex, x, "Modified");
   val(x) = Nil;
   tail(x) = y;
   cdr(z) = Nil;
}

// (wipe 'sym|lst) -> sym
any doWipe(any ex) {
   any x, y;

   x = cdr(ex);
   if (!isNil(x = EVAL(car(x))))
      if (isSym(x))
         wipe(ex,x);
      else if (isCell(x)) {
         y = x; do {
            NeedSym(ex,car(y));
            wipe(ex,car(y));
         } while (isCell(y = cdr(y)));
      }
   return x;
}

static any meta(any x, any y) {
   any z;

   while (isCell(x)) {
      if (isSym(car(x)))
         if (!isNil(z = get(car(x),y)) || !isNil(z = meta(val(car(x)), y)))
            return z;
      x = cdr(x);
   }
   return Nil;
}

// (meta 'obj|typ 'sym ['sym2|cnt ..]) -> any
any doMeta(any ex) {
   any x, y;
   cell c1;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   x = cdr(x),  y = EVAL(car(x));
   if (isSym(data(c1))) {
      Fetch(ex,data(c1));
      data(c1) = val(data(c1));
   }
   data(c1) = meta(data(c1), y);
   while (isCell(x = cdr(x))) {
      y = EVAL(car(x));
      if (isCell(data(c1))) {
         NeedNum(ex,y);
         data(c1) = car(nth(unDig(y)/2, data(c1)));
      }
      else {
         NeedSym(ex,data(c1));
         Fetch(ex,data(c1));
         data(c1) = get(data(c1), y);
      }
   }
   return Pop(c1);
}
