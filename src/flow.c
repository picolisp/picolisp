/* 28may03abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

static void redefMsg(void) {outString(" redefined\n");}

static void redefine(any ex, any s, any x) {
   NeedSym(ex,s);
   CheckVar(ex,s);
   if (!isNil(val(s))  &&  s != val(s)  &&  !equal(x,val(s)))
      print(s), redefMsg();
   val(s) = x;
}

// (quote . any) -> any
any doQuote(any x) {return cdr(x);}

// (eval 'any) -> any
any doEval(any x) {
   cell c1;

   x = cdr(x),  Push(c1, EVAL(car(x)));
   x = EVAL(data(c1));
   drop(c1);
   return x;
}

// (run 'any) -> any
any doRun(any ex) {
   cell c1;

   Push(c1, EVAL(cadr(ex)));
   data(c1) = isNum(data(c1))?
      data(c1) : (isSym(data(c1))?
         val(data(c1)) : run(data(c1)) );
   return Pop(c1);
}

// (def 'sym 'any) -> sym
// (def 'sym 'sym 'any) -> sym
any doDef(any ex) {
   any x, y;
   cell c1, c2, c3;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   NeedSym(ex,data(c1));
   CheckVar(ex,data(c1));
   x = cdr(x),  Push(c2, EVAL(car(x)));
   if (!isCell(cdr(x))) {
      if (!equal(data(c2), y = val(data(c1)))) {
         if (!isNil(y)  &&  data(c1) != y)
            print(data(c1)), redefMsg();
         Touch(ex,data(c1));
         val(data(c1)) = data(c2);
      }
   }
   else {
      x = cdr(x),  Push(c3, EVAL(car(x)));
      if (!equal(data(c3), y = get(data(c1), data(c2)))) {
         if (!isNil(y))
            print(data(c1)), space(), print(data(c2)), redefMsg();
         Touch(ex,data(c1));
         put(data(c1), data(c2), data(c3));
      }
   }
   return Pop(c1);
}

// (de sym . any) -> sym
any doDe(any ex) {
   redefine(ex, cadr(ex), cddr(ex));
   return cadr(ex);
}

// (dm sym . foo) -> sym | (dm (sym . cls) . foo) -> sym
any doDm(any ex) {
   any x, y, msg, cls;

   x = cdr(ex);
   if (isCell(car(x)))
      msg = caar(x),  cls = cdar(x);
   else
      msg = car(x),  cls = val(Class);
   if (msg != T)
      redefine(ex, msg, val(Meth));
   for (y = val(cls);  isCell(y) && isCell(car(y));  y = cdr(y))
      if (caar(y) == msg) {
         if (!equal(cdr(x), cdar(y)))
            print(msg), space(), print(cls), redefMsg();
         cdar(y) = cdr(x);
         return msg;
      }
   if (!isCell(car(x)))
      val(cls) = cons(x, val(cls));
   else
      val(cls) = cons(cons(caar(x), cdr(x)), val(cls));
   return msg;
}

/* Evaluate method invocation */
static any evMethod(any o, any expr, any x) {
   any y;
   cell at;
   int i = length(car(expr));
   methFrame m;
   struct {  // bindFrame
      struct bindFrame *link;
      int cnt;
      struct {any sym; any val;} bnd[i+1];
   } f;

   Push(at,val(At));
   m.link = Env.meth;
   m.key = TheKey;
   m.cls = TheCls;
   f.link = Env.bind,  Env.bind = (bindFrame*)&f;
   f.cnt = 0;
   for (y = car(expr);  isCell(y);  ++f.cnt, x = cdr(x), y = cdr(y)) {
      f.bnd[f.cnt].sym = car(y);
      f.bnd[f.cnt].val = EVAL(car(x));
   }
   if (isNil(y)) {
      while (--i >= 0) {
         x = val(f.bnd[i].sym);
         val(f.bnd[i].sym) = f.bnd[i].val;
         f.bnd[i].val = x;
      }
      f.bnd[f.cnt].sym = This;
      f.bnd[f.cnt++].val = val(This);
      val(This) = o;
      Env.meth = &m;
      x = prog(cdr(expr));
   }
   else if (y != At) {
      bindFrame g;

      Bind(y,g),  val(y) = x;
      while (--i >= 0) {
         x = val(f.bnd[i].sym);
         val(f.bnd[i].sym) = f.bnd[i].val;
         f.bnd[i].val = x;
      }
      f.bnd[f.cnt].sym = This;
      f.bnd[f.cnt++].val = val(This);
      val(This) = o;
      Env.meth = &m;
      x = prog(cdr(expr));
      Unbind(g);
   }
   else {
      int n, cnt;
      cell *arg;
      cell c[cnt = length(x)];

      n = cnt;
      while (--n >= 0)
         Push(c[n], EVAL(car(x))),  x = cdr(x);
      while (--i >= 0) {
         x = val(f.bnd[i].sym);
         val(f.bnd[i].sym) = f.bnd[i].val;
         f.bnd[i].val = x;
      }
      n = Env.next,  Env.next = cnt;
      arg = Env.arg,  Env.arg = c;
      f.bnd[f.cnt].sym = This;
      f.bnd[f.cnt++].val = val(This);
      val(This) = o;
      Env.meth = &m;
      x = prog(cdr(expr));
      Env.arg = arg,  Env.next = n;
   }
   while (--f.cnt >= 0)
      val(f.bnd[f.cnt].sym) = f.bnd[f.cnt].val;
   Env.bind = f.link;
   Env.meth = Env.meth->link;
   val(At) = Pop(at);
   return x;
}

any method(any x) {
   any y, z;

   if (isCell(y = val(x))) {
      if (isCell(car(y))) {
         if (caar(y) == TheKey)
            return cdar(y);
         for (;;) {
            z = y;
            if (!isCell(y = cdr(y)))
               return NULL;
            if (!isCell(car(y)))
               break;
            if (caar(y) == TheKey) {
               cdr(z) = cdr(y),  cdr(y) = val(x),  val(x) = y;
               return cdar(y);
            }
         }
      }
      do
         if (x = method(car(TheCls = y)))
            return x;
      while (isCell(y = cdr(y)));
   }
   return NULL;
}

// (box 'any) -> sym
any doBox(any x) {
   x = cdr(x);
   return consSym(EVAL(car(x)), Nil);
}

// (new ['flg] ['typ ['any ..]]) -> sym
any doNew(any ex) {
   any x, y, *p;
   cell c1, c2;

   x = cdr(ex);
   Push(c1, consSym(Nil,Nil));
   if (isCell(y = EVAL(car(x))))
      val(data(c1)) = y;
   else {
      if (!isNil(y)) {
         data(c1) = extSym(data(c1));
         p = Extern + hash(tail(data(c1)) = newId());
         *p = cons(data(c1),*p);
      }
      x = cdr(x),  y = EVAL(car(x));
      NeedLst(ex,y);
      val(data(c1)) = y;
   }
   TheKey = T,  TheCls = Nil;
   if (y = method(data(c1)))
      evMethod(data(c1), y, cdr(x));
   else {
      Save(c2);
      while (isCell(x = cdr(x))) {
         data(c2) = EVAL(car(x)),  x = cdr(x);
         put(data(c1), data(c2), EVAL(car(x)));
      }
   }
   return Pop(c1);
}

// (type 'any) -> lst
any doType(any ex) {
   any x, y;

   x = cdr(ex),  x = EVAL(car(x));
   if (isSym(x)) {
      Fetch(ex,x);
      for (x = val(x); isCell(x); x = cdr(x))
         if (!isCell(car(x))) {
            y = x;
            while (isSym(car(x)))
               if (!isCell(x = cdr(x)))
                  return isNil(x)? y : Nil;
            return Nil;
         }
   }
   return Nil;
}

static bool isa(any ex, any cls, any x) {
   Fetch(ex,x);
   for (x = val(x); isCell(x); x = cdr(x))
      if (!isCell(car(x))) {
         while (isSym(car(x))) {
            if (cls == car(x) || isa(ex, cls, car(x)))
               return YES;
            if (!isCell(x = cdr(x)))
               return NO;
         }
         return NO;
      }
   return NO;
}

// (isa 'cls|typ 'any) -> flg
any doIsa(any ex) {
   any x;
   cell c1;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   x = cdr(x),  x = EVAL(car(x));
   drop(c1);
   if (isSym(x)) {
      if (isSym(data(c1)))
         return isa(ex, data(c1), x)? T : Nil;
      while (isCell(data(c1))) {
         if (!isa(ex, car(data(c1)), x))
            return Nil;
         data(c1) = cdr(data(c1));
      }
      return T;
   }
   return Nil;
}

// (method 'msg 'obj) -> foo
any doMethod(any ex) {
   any x, y;

   x = cdr(ex),  y = EVAL(car(x));
   x = cdr(x),  x = EVAL(car(x));
   Fetch(ex,x);
   TheKey = y;
   return method(x)? : Nil;
}

// (meth 'obj ..) -> any
any doMeth(any ex) {
   any x, y;
   cell c1;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   NeedSym(ex,data(c1));
   Fetch(ex,data(c1));
   TheKey = car(ex),  TheCls = Nil;
   if (!(y = method(data(c1))))
      err(ex, TheKey, "Bad message");
   x = evMethod(data(c1), y, cdr(x));
   drop(c1);
   return x;
}

// (send 'msg 'obj ['any ..]) -> any
any doSend(any ex) {
   any x, y;
   cell c1;

   x = cdr(ex),  y = EVAL(car(x));
   NeedSym(ex,y);
   x = cdr(x),  Push(c1,  EVAL(car(x)));
   NeedSym(ex,data(c1));
   Fetch(ex,data(c1));
   TheKey = y,  TheCls = Nil;
   if (y = method(data(c1))) {
      x = evMethod(data(c1), y, cdr(x));
      drop(c1);
      return x;
   }
   err(ex, TheKey, "Bad message");
}

// (super ['any ..]) -> any
any doSuper(any ex) {
   any x, y;
   methFrame m;

   m.key = TheKey = Env.meth->key;
   x = val(isNil(Env.meth->cls)? val(This) : car(Env.meth->cls));
   while (isCell(car(x)))
      x = cdr(x);
   while (isCell(x)) {
      if (y = method(car(TheCls = x))) {
         m.cls = TheCls;
         m.link = Env.meth,  Env.meth = &m;
         x = evExpr(y, cdr(ex));
         Env.meth = Env.meth->link;
         return x;
      }
      x = cdr(x);
   }
   err(ex, TheKey, "Bad super");
}

static any extra(any x) {
   any y;

   for (x = val(x); isCell(car(x)); x = cdr(x));
   while (isCell(x)) {
      if (x == Env.meth->cls  ||  !(y = extra(car(x)))) {
         while (isCell(x = cdr(x)))
            if (y = method(car(TheCls = x)))
               return y;
         return NULL;
      }
      if (y  &&  num(y) != 1)
         return y;
      x = cdr(x);
   }
   return (any)1;
}

// (extra ['any ..]) -> any
any doExtra(any ex) {
   any x, y;
   methFrame m;

   m.key = TheKey = Env.meth->key;
   if ((y = extra(val(This)))  &&  num(y) != 1) {
      m.cls = TheCls;
      m.link = Env.meth,  Env.meth = &m;
      x = evExpr(y, cdr(ex));
      Env.meth = Env.meth->link;
      return x;
   }
   err(ex, TheKey, "Bad extra");
}

// (with 'sym . prg) -> any
any doWith(any ex) {
   any x;
   bindFrame f;

   x = cdr(ex);
   if (isNil(x = EVAL(car(x))))
      return Nil;
   NeedSym(ex,x);
   Fetch(ex,x);
   Bind(This,f),  val(This) = x;
   x = prog(cddr(ex));
   Unbind(f);
   return x;
}

// (bind 'sym|lst 'prg) -> any
any doBind(any ex) {
   any x, y;
   cell c1;

   x = cdr(ex);
   if (isNum(y = EVAL(car(x))))
      argError(ex, y);
   if (isSym(y)) {
      bindFrame f;

      Bind(y,f);
      x = cdr(x),  Push(c1, EVAL(car(x)));
      x = prog(data(c1));
      Unbind(f);
   }
   else {
      struct {  // bindFrame
         struct bindFrame *link;
         int cnt;
         struct {any sym; any val;} bnd[length(y)];
      } f;

      f.link = Env.bind,  Env.bind = (bindFrame*)&f;
      f.cnt = 0;
      while (isCell(y)) {
         if (isNum(car(y)))
            argError(ex, car(y));
         if (isSym(car(y))) {
            f.bnd[f.cnt].sym = car(y);
            f.bnd[f.cnt].val = val(car(y));
         }
         else {
            f.bnd[f.cnt].sym = caar(y);
            f.bnd[f.cnt].val = val(caar(y));
            val(caar(y)) = cdar(y);
         }
         ++f.cnt,  y = cdr(y);
      }
      x = cdr(x),  Push(c1, EVAL(car(x)));
      x = prog(data(c1));
      while (--f.cnt >= 0)
         val(f.bnd[f.cnt].sym) = f.bnd[f.cnt].val;
      Env.bind = f.link;
   }
   drop(c1);
   return x;
}

// (job lst . prg) -> any
any doJob(any ex) {
   any x = cdr(ex);
   any y = car(x);
   any z;
   struct {  // bindFrame
      struct bindFrame *link;
      int cnt;
      struct {any sym; any val;} bnd[length(y)];
   } f;

   f.link = Env.bind,  Env.bind = (bindFrame*)&f;
   f.cnt = 0;
   while (isCell(y)) {
      f.bnd[f.cnt].sym = caar(y);
      f.bnd[f.cnt].val = val(caar(y));
      val(caar(y)) = cdar(y);
      ++f.cnt,  y = cdr(y);
   }
   z = prog(cdr(x));
   for (f.cnt = 0, y = car(x);  isCell(y);  ++f.cnt, y = cdr(y)) {
      cdar(y) = val(caar(y));
      val(caar(y)) = f.bnd[f.cnt].val;
   }
   Env.bind = f.link;
   return z;
}

// (let sym 'any . prg) -> any
// (let (sym 'any ..) . prg) -> any
any doLet(any x) {
   any y;

   x = cdr(x);
   if (isSym(y = car(x))) {
      bindFrame f;

      x = cdr(x),  Bind(y,f),  val(y) = EVAL(car(x));
      x = prog(cdr(x));
      Unbind(f);
   }
   else {
      struct {  // bindFrame
         struct bindFrame *link;
         int cnt;
         struct {any sym; any val;} bnd[(length(y)+1)/2];
      } f;

      f.link = Env.bind,  Env.bind = (bindFrame*)&f;
      f.cnt = 0;
      do {
         f.bnd[f.cnt].sym = car(y);
         f.bnd[f.cnt].val = val(car(y));
         val(car(y)) = EVAL(cadr(y));
         ++f.cnt;
      } while (isCell(y = cddr(y)));
      x = prog(cdr(x));
      while (--f.cnt >= 0)
         val(f.bnd[f.cnt].sym) = f.bnd[f.cnt].val;
      Env.bind = f.link;
   }
   return x;
}

// (use sym . prg) -> any
// (use (sym ..) . prg) -> any
any doUse(any x) {
   any y;

   x = cdr(x);
   if (isSym(y = car(x))) {
      bindFrame f;

      Bind(y,f);
      x = prog(cdr(x));
      Unbind(f);
   }
   else {
      struct {  // bindFrame
         struct bindFrame *link;
         int cnt;
         struct {any sym; any val;} bnd[length(y)];
      } f;

      f.link = Env.bind,  Env.bind = (bindFrame*)&f;
      f.cnt = 0;
      do {
         f.bnd[f.cnt].sym = car(y);
         f.bnd[f.cnt].val = val(car(y));
         ++f.cnt;
      } while (isCell(y = cdr(y)));
      x = prog(cdr(x));
      while (--f.cnt >= 0)
         val(f.bnd[f.cnt].sym) = f.bnd[f.cnt].val;
      Env.bind = f.link;
   }
   return x;
}

// (and 'any ..) -> any
any doAnd(any x) {
   x = cdr(x);
   do
      if (isNil(val(At) = EVAL(car(x))))
         return Nil;
   while (isCell(x = cdr(x)));
   return val(At);
}

// (or 'any ..) -> any
any doOr(any x) {
   x = cdr(x);
   do
      if (!isNil(val(At) = EVAL(car(x))))
         return val(At);
   while (isCell(x = cdr(x)));
   return Nil;
}

// (nand 'any ..) -> flg
any doNand(any x) {
   x = cdr(x);
   do
      if (isNil(val(At) = EVAL(car(x))))
         return T;
   while (isCell(x = cdr(x)));
   return Nil;
}

// (nor 'any ..) -> flg
any doNor(any x) {
   x = cdr(x);
   do
      if (!isNil(val(At) = EVAL(car(x))))
         return Nil;
   while (isCell(x = cdr(x)));
   return T;
}

// (xor 'any 'any) -> flg
any doXor(any x) {
   bool f;

   x = cdr(x),  f = isNil(EVAL(car(x))),  x = cdr(x);
   return  f ^ isNil(EVAL(car(x)))?  T : Nil;
}

// (bool 'any) -> flg
any doBool(any x) {return isNil(EVAL(cadr(x)))? Nil : T;}

// (not 'any) -> flg
any doNot(any x) {return isNil(EVAL(cadr(x)))? T : Nil;}

// (nil . prg) -> NIL
any doNil(any x) {
   while (isCell(x = cdr(x)))
      if (isCell(car(x)))
         evList(car(x));
   return Nil;
}

// (t . prg) -> T
any doT(any x) {
   while (isCell(x = cdr(x)))
      if (isCell(car(x)))
         evList(car(x));
   return T;
}

// (prog . prg) -> any
any doProg(any x) {return prog(cdr(x));}

// (prog1 'any1 . prg) -> any1
any doProg1(any x) {
   cell c1;

   x = cdr(x),  Push(c1, val(At) = EVAL(car(x)));
   while (isCell(x = cdr(x)))
      if (isCell(car(x)))
         evList(car(x));
   return Pop(c1);
}

// (prog2 'any1 'any2 . prg) -> any2
any doProg2(any x) {
   cell c1;

   x = cdr(x),  EVAL(car(x));
   x = cdr(x),  Push(c1, val(At) = EVAL(car(x)));
   while (isCell(x = cdr(x)))
      if (isCell(car(x)))
         evList(car(x));
   return Pop(c1);
}

// (if 'any1 'any2 . prg) -> any
any doIf(any x) {
   x = cdr(x);
   if (isNil(val(At) = EVAL(car(x))))
      return prog(cddr(x));
   x = cdr(x);
   return EVAL(car(x));
}

// (ifn 'any1 'any2 . prg) -> any
any doIfn(any x) {
   x = cdr(x);
   if (!isNil(val(At) = EVAL(car(x))))
      return prog(cddr(x));
   x = cdr(x);
   return EVAL(car(x));
}

// (when 'any . prg) -> any
any doWhen(any x) {
   x = cdr(x);
   if (isNil(val(At) = EVAL(car(x))))
      return Nil;
   return prog(cdr(x));
}

// (unless 'any . prg) -> any
any doUnless(any x) {
   x = cdr(x);
   if (!isNil(val(At) = EVAL(car(x))))
      return Nil;
   return prog(cdr(x));
}

// (cond (('any1 . prg1) ('any2 . prg2) ..)) -> any
any doCond(any x) {
   while (isCell(x = cdr(x)))
      if (!isNil(val(At) = EVAL(caar(x))))
         return prog(cdar(x));
   return Nil;
}

// (case 'any (any1 . prg1) (any2 . prg2) ..) -> any
any doCase(any x) {
   any y, z;

   x = cdr(x),  val(At) = EVAL(car(x));
   while (isCell(x = cdr(x))) {
      y = car(x),  z = car(y);
      if (z == T  ||  equal(val(At), z))
         return prog(cdr(y));
      if (isCell(z)) {
         do
            if (equal(val(At), car(z)))
               return prog(cdr(y));
         while (isCell(z = cdr(z)));
      }
   }
   return Nil;
}

// (while 'any . prg) -> any
any doWhile (any x) {
   any cond;
   cell c1;

   cond = car(x = cdr(x)),  x = cdr(x);
   Push(c1, Nil);
   while (!isNil(val(At) = EVAL(cond)))
      data(c1) = prog(x);
   return Pop(c1);
}

// (whilst 'any . prg) -> any
any doWhilst (any x) {
   any cond;
   cell c1;

   cond = car(x = cdr(x)),  x = cdr(x);
   Push(c1, Nil);
   while (isCell(val(At) = EVAL(cond)) || isNil(val(At)))
      data(c1) = prog(x);
   return Pop(c1);
}

// (until 'any . prg) -> any
any doUntil (any x) {
   any cond;
   cell c1;

   cond = car(x = cdr(x)),  x = cdr(x);
   Push(c1, Nil);
   while (isNil(val(At) = EVAL(cond)))
      data(c1) = prog(x);
   return Pop(c1);
}

// (loop ['any | (NIL 'any . prg) | (T 'any . prg) ..]) -> any
any doLoop(any ex) {
   any x, y;

   for (;;) {
      x = cdr(ex);
      do {
         if (isCell(y = car(x))) {
            if (isNil(car(y))) {
               y = cdr(y);
               if (isNil(val(At) = EVAL(car(y))))
                  return prog(cdr(y));
            }
            else if (car(y) == T) {
               y = cdr(y);
               if (!isNil(val(At) = EVAL(car(y))))
                  return prog(cdr(y));
            }
            else
               evList(y);
         }
      } while (isCell(x = cdr(x)));
   }
}

// (do 'flg|num ['any | (NIL 'any . prg) | (T 'any . prg) ..]) -> any
any doDo(any x) {
   any y, z;
   cell c1;

   x = cdr(x);
   if (isNil(data(c1) = EVAL(car(x))))
      return Nil;
   Save(c1);
   if (isNum(data(c1))) {
      if (isNeg(data(c1))) {
         drop(c1);
         return Nil;
      }
      data(c1) = bigCopy(data(c1));
   }
   x = cdr(x),  z = Nil;
   for (;;) {
      if (isNum(data(c1))) {
         if (IsZero(data(c1))) {
            drop(c1);
            return z;
         }
         digSub1(data(c1));
      }
      y = x;
      do {
         if (!isNum(z = car(y))) {
            if (isSym(z))
               z = val(z);
            else if (isNil(car(z))) {
               z = cdr(z);
               if (isNil(val(At) = EVAL(car(z)))) {
                  drop(c1);
                  return prog(cdr(z));
               }
               z = Nil;
            }
            else if (car(z) == T) {
               z = cdr(z);
               if (!isNil(val(At) = EVAL(car(z)))) {
                  drop(c1);
                  return prog(cdr(z));
               }
               z = Nil;
            }
            else
               z = evList(z);
         }
      } while (isCell(y = cdr(y)));
   }
}

// (at '(num1 . num2) . prg) -> any
any doAt(any ex) {
   any x;

   x = cdr(ex),  x = EVAL(car(x));
   NeedCell(ex,x);
   NeedCnt(ex,(car(x)));
   NeedCnt(ex,(cdr(x)));
   if (setDig(car(x), unDig(car(x))+2) < unDig(cdr(x)))
      return Nil;
   setDig(car(x), 0);
   return prog(cddr(ex));
}

// (for (sym 'any1 'any2 [. prg1]) . prg2) -> any
any doFor(any ex) {
   any x, y, body, cond;
   bindFrame f;

   body = cdr(x = cdr(ex));
   x = car(x);
   NeedCell(ex,x);
   NeedSym(ex,car(x));
   Bind(car(x),f),  x = cdr(x);
   val(f.bnd[0].sym) = EVAL(car(x));
   x = cdr(x),  cond = car(x),  x = cdr(x);
   y = Nil;
   for (;;) {
      if (isNil(val(At) = EVAL(cond))) {
         Unbind(f);
         return y;
      }
      y = prog(body);
      if (isCell(x))
         val(f.bnd[0].sym) = prog(x);
   }
}

// (catch 'sym . prg) -> any
any doCatch(any ex) {
   any x, y;
   catchFrame f;

   x = cdr(ex),  f.tag = EVAL(car(x));
   f.link = CatchPtr,  CatchPtr = &f;
   f.env = Env;
   if (!(y = (any)setjmp(f.rst)))
      y = prog(cdr(x));
   CatchPtr = f.link;
   return y;
}

// (throw 'sym 'any)
any doThrow(any ex) {
   int i;
   any x, tag;

   x = cdr(ex),  tag = EVAL(car(x));
   x = cdr(x),  x = EVAL(car(x));
   while (CatchPtr) {
      if (CatchPtr->tag == T  ||  tag == CatchPtr->tag) {
         while (Env.bind != CatchPtr->env.bind) {
            i = Env.bind->cnt;
            while (--i >= 0)
               val(Env.bind->bnd[i].sym) = Env.bind->bnd[i].val;
            Env.bind = Env.bind->link;
         }
         closeFiles(CatchPtr->env.inFiles, CatchPtr->env.outFiles, CatchPtr->env.ctlFiles);
         Env = CatchPtr->env;
         longjmp(CatchPtr->rst, (int)x);
      }
      CatchPtr = CatchPtr->link;
   }
   err(ex, tag, "Tag not found");
}

static cell BrkAt;
static bindFrame BrkKey;

void brkLoad(any x) {
   cell c1;
   FILE *oSave;

   if (!isNil(val(Dbg))) {
      Push(c1, val(Up)),  val(Up) = x;
      Push(BrkAt, val(At));
      Bind(Key,BrkKey),  val(Key) = Nil;
      oSave = OutFile,  OutFile = stdout;
      print(x), crlf();
      load(NULL, '!', Nil);
      OutFile = oSave;
      Unbind(BrkKey);
      val(At) = data(BrkAt);
      val(Up) = Pop(c1);
   }
}

// (! . prg) -> any
any doBreak(any ex) {
   brkLoad(cdr(ex));
   return EVAL(cdr(ex));
}

// (e . prg) -> any
any doE(any ex) {
   any x;
   cell c1, at, key;

   if (!data(BrkAt))
      err(ex, NULL, "No Break");
   Push(c1,val(Dbg)),  val(Dbg) = Nil;
   Push(at, val(At)),  val(At) = data(BrkAt);
   Push(key, val(Key)),  val(Key) = BrkKey.bnd[0].val;
   if (Env.inFiles && Env.inFiles->link)
      Chr = Env.inFiles->next,  InFile = Env.inFiles->link->fp;
   x = isCell(cdr(ex))? run(cdr(ex)) : EVAL(val(Up));
   if (Env.inFiles && Env.inFiles->link)
      Env.inFiles->next = Chr,  Chr = 0;
   InFile = stdin;
   val(Key) = data(key);
   val(At) = data(at);
   val(Dbg) = Pop(c1);
   return x;
}

static void traceIndent(int i, any x, char *s) {
   if (i > 64)
      i = 64;
   while (--i >= 0)
      Env.put(' ');
   if (isSym(x))
      print(x);
   else
      print(car(x)), space(), print(cdr(x)), space(), print(val(This));
   outString(s);
}

static void traceSym(any x) {
   if (x != At)
      space(), print(val(x));
   else {
      int i = Env.next;

      while (--i >= 0)
         space(), print(data(Env.arg[i]));
   }
}

// ($ sym|lst lst . prg) -> any
any doTrace(any x) {
   any foo, body;
   FILE *oSave;
   cell c1;

   if (isNil(val(Dbg)))
      return prog(cdddr(x));
   oSave = OutFile,  OutFile = stdout;
   x = cdr(x),  foo = car(x);
   x = cdr(x),  body = cdr(x);
   traceIndent(++Trace, foo, " :");
   for (x = car(x);  isCell(x);  x = cdr(x))
      traceSym(car(x));
   if (!isNil(x) && isSym(x))
      traceSym(x);
   crlf();
   OutFile = oSave;
   Push(c1, prog(body));
   OutFile = stdout;
   traceIndent(Trace--, foo, " = "),  print(data(c1)),  crlf();
   OutFile = oSave;
   return Pop(c1);
}

// (sys 'any ['any]) -> sym
any doSys(any x) {
   any y;

   y = evSym(x = cdr(x));
   {
      byte nm[bufSize(y)];

      bufString(y,nm);
      if (!isCell(x = cdr(x)))
         return mkStr(getenv(nm));
      y = evSym(x);
      {
         byte val[bufSize(y)];

         bufString(y,val);
         return setenv(nm,val,1)? Nil : y;
      }
   }
}

// (call 'any ..) -> flg
any doCall(any ex) {
   pid_t pid;
   any x, y;
   int res, i, ac = length(x = cdr(ex));
   byte *av[ac+1];

   if (ac == 0)
      return Nil;
   i = 0;  do {
      y = evSym(x),  x = cdr(x);
      av[i] = alloc(NULL, bufSize(y)),  bufString(y, av[i]);
   } while (++i < ac);
   av[ac] = NULL;
   if ((pid = fork()) == 0) {
      setpgid(0,0);
      execvp(av[0], (char**)av);
      execError(av[0]);
   }
   i = 0;  do
      free(av[i]);
   while (++i < ac);
   if (pid < 0)
      err(ex, NULL, "fork");
   setpgid(pid,0);
   tcsetpgrp(0,pid);
   for (;;) {
      while (waitpid(pid, &res, WUNTRACED) < 0)
         if (errno != EINTR)
            err(ex, NULL, "wait pid");
      tcsetpgrp(0,getpgrp());
      if (!WIFSTOPPED(res))
         return res == 0? T : Nil;
      load(NULL, '+', Nil);
      tcsetpgrp(0,pid);
      kill(pid, SIGCONT);
   }
}

// (tick cnt . prg) -> any
any doTick(any ex) {
   any x;
   clock_t n, save;
   struct tms tim;
   static clock_t ticks;

   save = ticks;
   times(&tim),  n = tim.tms_utime;
   x = prog(cddr(ex));
   times(&tim),  n = (tim.tms_utime - n) - (ticks - save);
   setDig(cadr(ex), unDig(cadr(ex)) + 2*n);
   ticks += n;
   return x;
}

// (kill 'pid 'cnt) -> flg
any doKill(any ex) {
   pid_t pid;

   pid = (pid_t)evCnt(ex,cdr(ex));
   return kill(pid, (int)evCnt(ex,cddr(ex)))? Nil : T;
}

static int allocPipe(void) {
   int i;

   for (i = 0; i < PSize; i += 2)
      if (Pipe[i] < 0)
         return i;
   Pipe = realloc(Pipe, (PSize + 16) * sizeof(int));
   for (i = 0; i < 16; i += 2)
      Pipe[PSize] = -1,  PSize += 2;
   return PSize - 16;
}

static void doSigChld(int n __attribute__((unused))) {
   pid_t pid;
   int stat;

   while ((pid = waitpid(0, &stat, WNOHANG)) > 0)
      if (WIFSIGNALED(stat))
         fprintf(stderr, "%d SIG-%d\n", pid, WTERMSIG(stat));
}

// (fork) -> pid | NIL
any doFork(any ex) {
   int n, i, hear[2], tell[2];

   fflush(NULL);
   if (!Mic[0]) {
      signal(SIGCHLD, doSigChld);
      if (pipe(Mic) < 0)
         pipeError(ex, "open");
   }
   if (pipe(hear) < 0  ||  pipe(tell) < 0)
      pipeError(ex, "open");
   i = allocPipe();
   if ((n = fork()) < 0)
      err(ex, NULL, "fork");
   if (n == 0) {
      /* Child Process */
      free(Termio),  Termio = NULL;
      if (close(hear[1]) < 0  ||  close(tell[0]) < 0  ||  close(Mic[0]) < 0)
         pipeError(ex, "close");
      PSize = 0,  free(Pipe);
      Mic[0] = 0;
      Slot = i;
      Hear = hear[0];
      Tell = tell[1];
      val(Pid) = boxCnt(getpid());
      return Nil;
   }
   if (close(hear[0]) < 0  ||  close(tell[1]) < 0)
      pipeError(ex, "close");
   Pipe[i] = tell[0];
   Pipe[i+1] = hear[1];
   return boxCnt(n);
}

// (bye 'cnt|NIL)
any doBye(any ex) {
   any x = EVAL(cadr(ex));

   run(val(Bye));
   bye(isNil(x)? 0 : xCnt(ex,x));
}
