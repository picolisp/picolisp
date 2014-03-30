/* 25mar14abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

any apply(any ex, any foo, bool cf, int n, cell *p) {
   while (!isNum(foo)) {
      if (isCell(foo)) {
         int i;
         any x = car(foo);
         struct {  // bindFrame
            struct bindFrame *link;
            int i, cnt;
            struct {any sym; any val;} bnd[length(x)+2];
         } f;

         f.link = Env.bind,  Env.bind = (bindFrame*)&f;
         f.i = 0;
         f.cnt = 1,  f.bnd[0].sym = At,  f.bnd[0].val = val(At);
         while (isCell(x)) {
            f.bnd[f.cnt].val = val(f.bnd[f.cnt].sym = car(x));
            val(f.bnd[f.cnt].sym) = --n<0? Nil : cf? car(data(p[f.cnt-1])) : data(p[f.cnt-1]);
            ++f.cnt, x = cdr(x);
         }
         if (isNil(x))
            x = prog(cdr(foo));
         else if (x != At) {
            f.bnd[f.cnt].sym = x,  f.bnd[f.cnt].val = val(x),  val(x) = Nil;
            while (--n >= 0)
               val(x) = cons(consSym(cf? car(data(p[n+f.cnt-1])) : data(p[n+f.cnt-1]), Nil), val(x));
            ++f.cnt;
            x = prog(cdr(foo));
         }
         else {
            int cnt = n;
            int next = Env.next;
            cell *arg = Env.arg;
            cell c[Env.next = n];

            Env.arg = c;
            for (i = f.cnt-1;  --n >= 0;  ++i)
               Push(c[n], cf? car(data(p[i])) : data(p[i]));
            x = prog(cdr(foo));
            if (cnt)
               drop(c[cnt-1]);
            Env.arg = arg,  Env.next = next;
         }
         while (--f.cnt >= 0)
            val(f.bnd[f.cnt].sym) = f.bnd[f.cnt].val;
         Env.bind = f.link;
         return x;
      }
      if (val(foo) == val(Meth)) {
         any expr, o, x;

         o = cf? car(data(p[0])) : data(p[0]);
         NeedSym(ex,o);
         Fetch(ex,o);
         TheCls = NULL,  TheKey = foo;
         if (expr = method(o)) {
            int i;
            any cls = Env.cls, key = Env.key;
            struct {  // bindFrame
               struct bindFrame *link;
               int i, cnt;
               struct {any sym; any val;} bnd[length(x = car(expr))+3];
            } f;

            Env.cls = TheCls,  Env.key = TheKey;
            f.link = Env.bind,  Env.bind = (bindFrame*)&f;
            f.i = 0;
            f.cnt = 1,  f.bnd[0].sym = At,  f.bnd[0].val = val(At);
            --n, ++p;
            while (isCell(x)) {
               f.bnd[f.cnt].val = val(f.bnd[f.cnt].sym = car(x));
               val(f.bnd[f.cnt].sym) = --n<0? Nil : cf? car(data(p[f.cnt-1])) : data(p[f.cnt-1]);
               ++f.cnt, x = cdr(x);
            }
            if (isNil(x)) {
               f.bnd[f.cnt].sym = This;
               f.bnd[f.cnt++].val = val(This);
               val(This) = o;
               x = prog(cdr(expr));
            }
            else if (x != At) {
               f.bnd[f.cnt].sym = x,  f.bnd[f.cnt].val = val(x),  val(x) = Nil;
               while (--n >= 0)
                  val(x) = cons(consSym(cf? car(data(p[n+f.cnt-1])) : data(p[n+f.cnt-1]), Nil), val(x));
               ++f.cnt;
               f.bnd[f.cnt].sym = This;
               f.bnd[f.cnt++].val = val(This);
               val(This) = o;
               x = prog(cdr(expr));
            }
            else {
               int cnt = n;
               int next = Env.next;
               cell *arg = Env.arg;
               cell c[Env.next = n];

               Env.arg = c;
               for (i = f.cnt-1;  --n >= 0;  ++i)
                  Push(c[n], cf? car(data(p[i])) : data(p[i]));
               f.bnd[f.cnt].sym = This;
               f.bnd[f.cnt++].val = val(This);
               val(This) = o;
               x = prog(cdr(expr));
               if (cnt)
                  drop(c[cnt-1]);
               Env.arg = arg,  Env.next = next;
            }
            while (--f.cnt >= 0)
               val(f.bnd[f.cnt].sym) = f.bnd[f.cnt].val;
            Env.bind = f.link;
            Env.cls = cls,  Env.key = key;
            return x;
         }
         err(ex, o, "Bad object");
      }
      if (isNil(val(foo)) || foo == val(foo))
         undefined(foo,ex);
      foo = val(foo);
   }
   if (--n < 0)
      cdr(ApplyBody) = Nil;
   else {
      any x = ApplyArgs;
      val(caar(x)) = cf? car(data(p[n])) : data(p[n]);
      while (--n >= 0) {
         if (!isCell(cdr(x)))
            cdr(x) = cons(cons(consSym(Nil,Nil), car(x)), Nil);
         x = cdr(x);
         val(caar(x)) = cf? car(data(p[n])) : data(p[n]);
      }
      cdr(ApplyBody) = car(x);
   }
   return evSubr(foo, ApplyBody);
}

// (apply 'fun 'lst ['any ..]) -> any
any doApply(any ex) {
   any x, y;
   int i, n;
   cell foo;

   x = cdr(ex),  Push(foo, EVAL(car(x)));
   x = cdr(x),  y = EVAL(car(x));
   {
      cell c[(n = length(cdr(x))) + length(y)];

      while (isCell(y))
         Push(c[n], car(y)),  y = cdr(y),  ++n;
      for (i = 0; isCell(x = cdr(x)); ++i)
         Push(c[i], EVAL(car(x)));
      x = apply(ex, data(foo), NO, n, c);
   }
   drop(foo);
   return x;
}

// (pass 'fun ['any ..]) -> any
any doPass(any ex) {
   any x;
   int n, i;
   cell foo, c[length(cdr(x = cdr(ex))) + (Env.next>0? Env.next : 0)];

   Push(foo, EVAL(car(x)));
   for (n = 0; isCell(x = cdr(x)); ++n)
      Push(c[n], EVAL(car(x)));
   for (i = Env.next;  --i >= 0;  ++n)
      Push(c[n], data(Env.arg[i]));
   x = apply(ex, data(foo), NO, n, c);
   drop(foo);
   return x;
}

// (maps 'fun 'sym ['lst ..]) -> any
any doMaps(any ex) {
   any x;
   int i, n;
   cell foo, c[length(cdr(x = cdr(ex)))];

   Push(foo, EVAL(car(x)));
   x = cdr(x),  Push(c[0], EVAL(car(x)));
   NeedSym(ex, data(c[0]));
   for (n = 1; isCell(x = cdr(x)); ++n)
      Push(c[n], EVAL(car(x)));
   Fetch(ex, data(c[0]));
   data(c[0]) = tail1(data(c[0]));
   while (isCell(data(c[0]))) {
      x = apply(ex, data(foo), YES, n, c);
      for (i = 0; i < n; ++i)
         data(c[i]) = cdr(data(c[i]));
   }
   drop(foo);
   return x;
}

// (map 'fun 'lst ..) -> lst
any doMap(any ex) {
   any x = cdr(ex);
   cell foo;

   Push(foo, EVAL(car(x)));
   if (isCell(x = cdr(x))) {
      int i, n = 0;
      cell c[length(x)];

      do
         Push(c[n], EVAL(car(x))), ++n;
      while (isCell(x = cdr(x)));
      while (isCell(data(c[0]))) {
         x = apply(ex, data(foo), NO, n, c);
         for (i = 0; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
      }
   }
   drop(foo);
   return x;
}

// (mapc 'fun 'lst ..) -> any
any doMapc(any ex) {
   any x = cdr(ex);
   cell foo;

   Push(foo, EVAL(car(x)));
   if (isCell(x = cdr(x))) {
      int i, n = 0;
      cell c[length(x)];

      do
         Push(c[n], EVAL(car(x))), ++n;
      while (isCell(x = cdr(x)));
      while (isCell(data(c[0]))) {
         x = apply(ex, data(foo), YES, n, c);
         for (i = 0; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
      }
   }
   drop(foo);
   return x;
}

// (maplist 'fun 'lst ..) -> lst
any doMaplist(any ex) {
   any x = cdr(ex);
   cell res, foo;

   Push(res, Nil);
   Push(foo, EVAL(car(x)));
   if (isCell(x = cdr(x))) {
      int i, n = 0;
      cell c[length(x)];

      do
         Push(c[n], EVAL(car(x))), ++n;
      while (isCell(x = cdr(x)));
      if (!isCell(data(c[0])))
         return Pop(res);
      data(res) = x = cons(apply(ex, data(foo), NO, n, c), Nil);
      while (isCell(data(c[0]) = cdr(data(c[0])))) {
         for (i = 1; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
         x = cdr(x) = cons(apply(ex, data(foo), NO, n, c), Nil);
      }
   }
   return Pop(res);
}

// (mapcar 'fun 'lst ..) -> lst
any doMapcar(any ex) {
   any x = cdr(ex);
   cell res, foo;

   Push(res, Nil);
   Push(foo, EVAL(car(x)));
   if (isCell(x = cdr(x))) {
      int i, n = 0;
      cell c[length(x)];

      do
         Push(c[n], EVAL(car(x))), ++n;
      while (isCell(x = cdr(x)));
      if (!isCell(data(c[0])))
         return Pop(res);
      data(res) = x = cons(apply(ex, data(foo), YES, n, c), Nil);
      while (isCell(data(c[0]) = cdr(data(c[0])))) {
         for (i = 1; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
         x = cdr(x) = cons(apply(ex, data(foo), YES, n, c), Nil);
      }
   }
   return Pop(res);
}

// (mapcon 'fun 'lst ..) -> lst
any doMapcon(any ex) {
   any x = cdr(ex);
   cell res, foo;

   Push(res, Nil);
   Push(foo, EVAL(car(x)));
   if (isCell(x = cdr(x))) {
      int i, n = 0;
      cell c[length(x)];

      do
         Push(c[n], EVAL(car(x))), ++n;
      while (isCell(x = cdr(x)));
      if (!isCell(data(c[0])))
         return Pop(res);
      while (!isCell(x = apply(ex, data(foo), NO, n, c))) {
         if (!isCell(data(c[0]) = cdr(data(c[0]))))
            return Pop(res);
         for (i = 1; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
      }
      data(res) = x;
      while (isCell(data(c[0]) = cdr(data(c[0])))) {
         for (i = 1; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
         while (isCell(cdr(x)))
            x = cdr(x);
         cdr(x) = apply(ex, data(foo), NO, n, c);
      }
   }
   return Pop(res);
}

// (mapcan 'fun 'lst ..) -> lst
any doMapcan(any ex) {
   any x = cdr(ex);
   cell res, foo;

   Push(res, Nil);
   Push(foo, EVAL(car(x)));
   if (isCell(x = cdr(x))) {
      int i, n = 0;
      cell c[length(x)];

      do
         Push(c[n], EVAL(car(x))), ++n;
      while (isCell(x = cdr(x)));
      if (!isCell(data(c[0])))
         return Pop(res);
      while (!isCell(x = apply(ex, data(foo), YES, n, c))) {
         if (!isCell(data(c[0]) = cdr(data(c[0]))))
            return Pop(res);
         for (i = 1; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
      }
      data(res) = x;
      while (isCell(data(c[0]) = cdr(data(c[0])))) {
         for (i = 1; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
         while (isCell(cdr(x)))
            x = cdr(x);
         cdr(x) = apply(ex, data(foo), YES, n, c);
      }
   }
   return Pop(res);
}

// (filter 'fun 'lst ..) -> lst
any doFilter(any ex) {
   any x = cdr(ex);
   cell res, foo;

   Push(res, Nil);
   Push(foo, EVAL(car(x)));
   if (isCell(x = cdr(x))) {
      int i, n = 0;
      cell c[length(x)];

      do
         Push(c[n], EVAL(car(x))), ++n;
      while (isCell(x = cdr(x)));
      if (!isCell(data(c[0])))
         return Pop(res);
      while (isNil(apply(ex, data(foo), YES, n, c))) {
         if (!isCell(data(c[0]) = cdr(data(c[0]))))
            return Pop(res);
         for (i = 1; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
      }
      data(res) = x = cons(car(data(c[0])), Nil);
      while (isCell(data(c[0]) = cdr(data(c[0])))) {
         for (i = 1; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
         if (!isNil(apply(ex, data(foo), YES, n, c)))
            x = cdr(x) = cons(car(data(c[0])), Nil);
      }
   }
   return Pop(res);
}

// (extract 'fun 'lst ..) -> lst
any doExtract(any ex) {
   any x = cdr(ex);
   any y;
   cell res, foo;

   Push(res, Nil);
   Push(foo, EVAL(car(x)));
   if (isCell(x = cdr(x))) {
      int i, n = 0;
      cell c[length(x)];

      do
         Push(c[n], EVAL(car(x))), ++n;
      while (isCell(x = cdr(x)));
      if (!isCell(data(c[0])))
         return Pop(res);
      while (isNil(y = apply(ex, data(foo), YES, n, c))) {
         if (!isCell(data(c[0]) = cdr(data(c[0]))))
            return Pop(res);
         for (i = 1; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
      }
      data(res) = x = cons(y, Nil);
      while (isCell(data(c[0]) = cdr(data(c[0])))) {
         for (i = 1; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
         if (!isNil(y = apply(ex, data(foo), YES, n, c)))
            x = cdr(x) = cons(y, Nil);
      }
   }
   return Pop(res);
}

// (seek 'fun 'lst ..) -> lst
any doSeek(any ex) {
   any x = cdr(ex);
   cell foo;

   Push(foo, EVAL(car(x)));
   if (isCell(x = cdr(x))) {
      int i, n = 0;
      cell c[length(x)];

      do
         Push(c[n], EVAL(car(x))), ++n;
      while (isCell(x = cdr(x)));
      while (isCell(data(c[0]))) {
         if (!isNil(x = apply(ex, data(foo), NO, n, c))) {
            drop(foo);
            val(At2) = x;
            return data(c[0]);
         }
         for (i = 0; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
      }
   }
   drop(foo);
   return Nil;
}

// (find 'fun 'lst ..) -> any
any doFind(any ex) {
   any x = cdr(ex);
   cell foo;

   Push(foo, EVAL(car(x)));
   if (isCell(x = cdr(x))) {
      int i, n = 0;
      cell c[length(x)];

      do
         Push(c[n], EVAL(car(x))), ++n;
      while (isCell(x = cdr(x)));
      while (isCell(data(c[0]))) {
         if (!isNil(x = apply(ex, data(foo), YES, n, c))) {
            drop(foo);
            val(At2) = x;
            return car(data(c[0]));
         }
         for (i = 0; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
      }
   }
   drop(foo);
   return Nil;
}

// (pick 'fun 'lst ..) -> any
any doPick(any ex) {
   any x = cdr(ex);
   cell foo;

   Push(foo, EVAL(car(x)));
   if (isCell(x = cdr(x))) {
      int i, n = 0;
      cell c[length(x)];

      do
         Push(c[n], EVAL(car(x))), ++n;
      while (isCell(x = cdr(x)));
      while (isCell(data(c[0]))) {
         if (!isNil(x = apply(ex, data(foo), YES, n, c))) {
            drop(foo);
            return x;
         }
         for (i = 0; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
      }
   }
   drop(foo);
   return Nil;
}

// (fully 'fun 'lst ..) -> flg
any doFully(any ex) {
   any x = cdr(ex);
   cell foo;

   Push(foo, EVAL(car(x)));
   if (isCell(x = cdr(x))) {
      int i, n = 0;
      cell c[length(x)];

      do
         Push(c[n], EVAL(car(x))), ++n;
      while (isCell(x = cdr(x)));
      while (isCell(data(c[0]))) {
         if (isNil(apply(ex, data(foo), YES, n, c))) {
            drop(foo);
            return Nil;
         }
         for (i = 0; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
      }
   }
   drop(foo);
   return T;
}

// (cnt 'fun 'lst ..) -> cnt
any doCnt(any ex) {
   any x = cdr(ex);
   int res;
   cell foo;

   res = 0;
   Push(foo, EVAL(car(x)));
   if (isCell(x = cdr(x))) {
      int i, n = 0;
      cell c[length(x)];

      do
         Push(c[n], EVAL(car(x))), ++n;
      while (isCell(x = cdr(x)));
      while (isCell(data(c[0]))) {
         if (!isNil(apply(ex, data(foo), YES, n, c)))
            res += 2;
         for (i = 0; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
      }
   }
   drop(foo);
   return box(res);
}

// (sum 'fun 'lst ..) -> num
any doSum(any ex) {
   any x = cdr(ex);
   cell res, foo, c1;

   Push(res, box(0));
   Push(foo, EVAL(car(x)));
   if (isCell(x = cdr(x))) {
      int i, n = 0;
      cell c[length(x)];

      do
         Push(c[n], EVAL(car(x))), ++n;
      while (isCell(x = cdr(x)));
      while (isCell(data(c[0]))) {
         if (isNum(data(c1) = apply(ex, data(foo), YES, n, c))) {
            Save(c1);
            if (isNeg(data(res))) {
               if (isNeg(data(c1)))
                  bigAdd(data(res),data(c1));
               else
                  bigSub(data(res),data(c1));
               if (!IsZero(data(res)))
                  neg(data(res));
            }
            else if (isNeg(data(c1)))
               bigSub(data(res),data(c1));
            else
               bigAdd(data(res),data(c1));
            drop(c1);
         }
         for (i = 0; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
      }
   }
   return Pop(res);
}

// (maxi 'fun 'lst ..) -> any
any doMaxi(any ex) {
   any x = cdr(ex);
   cell res, val, foo;

   Push(res, Nil);
   Push(val, Nil);
   Push(foo, EVAL(car(x)));
   if (isCell(x = cdr(x))) {
      int i, n = 0;
      cell c[length(x)];

      do
         Push(c[n], EVAL(car(x))), ++n;
      while (isCell(x = cdr(x)));
      while (isCell(data(c[0]))) {
         if (compare(x = apply(ex, data(foo), YES, n, c), data(val)) > 0)
            data(res) = car(data(c[0])),  data(val) = x;
         for (i = 0; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
      }
   }
   val(At2) = data(val);
   return Pop(res);
}

// (mini 'fun 'lst ..) -> any
any doMini(any ex) {
   any x = cdr(ex);
   cell res, val, foo;

   Push(res, Nil);
   Push(val, T);
   Push(foo, EVAL(car(x)));
   if (isCell(x = cdr(x))) {
      int i, n = 0;
      cell c[length(x)];

      do
         Push(c[n], EVAL(car(x))), ++n;
      while (isCell(x = cdr(x)));
      while (isCell(data(c[0]))) {
         if (compare(x = apply(ex, data(foo), YES, n, c), data(val)) < 0)
            data(res) = car(data(c[0])),  data(val) = x;
         for (i = 0; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
      }
   }
   val(At2) = data(val);
   return Pop(res);
}

static void fish(any ex, any foo, any x, cell *r) {
   if (!isNil(apply(ex, foo, NO, 1, (cell*)&x)))
      data(*r) = cons(x, data(*r));
   else if (isCell(x)) {
      if (!isNil(cdr(x)))
         fish(ex, foo, cdr(x), r);
      fish(ex, foo, car(x), r);
   }
}

// (fish 'fun 'any) -> lst
any doFish(any ex) {
   any x = cdr(ex);
   cell res, foo, c1;

   Push(res, Nil);
   Push(foo, EVAL(car(x)));
   x = cdr(x),  Push(c1, EVAL(car(x)));
   fish(ex, data(foo), data(c1), &res);
   return Pop(res);
}

// (by 'fun1 'fun2 'lst ..) -> lst
any doBy(any ex) {
   any x = cdr(ex);
   cell res, foo1, foo2;

   Push(res, Nil);
   Push(foo1, EVAL(car(x))),  x = cdr(x),  Push(foo2, EVAL(car(x)));
   if (isCell(x = cdr(x))) {
      int i, n = 0;
      cell c[length(x)];

      do
         Push(c[n], EVAL(car(x))), ++n;
      while (isCell(x = cdr(x)));
      if (!isCell(data(c[0])))
         return Pop(res);
      data(res) = x = cons(cons(apply(ex, data(foo1), YES, n, c), car(data(c[0]))), Nil);
      while (isCell(data(c[0]) = cdr(data(c[0])))) {
         for (i = 1; i < n; ++i)
            data(c[i]) = cdr(data(c[i]));
         x = cdr(x) = cons(cons(apply(ex, data(foo1), YES, n, c), car(data(c[0]))), Nil);
      }
      data(res) = apply(ex, data(foo2), NO, 1, &res);
      for (x = data(res); isCell(x); x = cdr(x))
         car(x) = cdar(x);
   }
   return Pop(res);
}
