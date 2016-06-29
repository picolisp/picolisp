/* 16mar16abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

static void redefMsg(any x, any y) {
   outFile *oSave = OutFile;
   void (*putSave)(int) = Env.put;

   OutFile = OutFiles[STDERR_FILENO],  Env.put = putStdout;
   outString("# ");
   print(x);
   if (y)
      space(), print(y);
   outString(" redefined\n");
   Env.put = putSave,  OutFile = oSave;
}

static void putSrc(any s, any k) {
   if (!isNil(val(Dbg)) && !isExt(s) && InFile && InFile->name) {
      any x, y;
      cell c1;

      Push(c1, boxCnt(InFile->src));
      data(c1) = cons(data(c1), mkStr(InFile->name));
      x = get(s, Dbg);
      if (!k) {
         if (isNil(x))
            put(s, Dbg, cons(data(c1), Nil));
         else
            car(x) = data(c1);
      }
      else if (isNil(x))
         put(s, Dbg, cons(Nil, cons(data(c1), Nil)));
      else {
         for (y = cdr(x); isCell(y); y = cdr(y))
            if (caar(y) == k) {
               cdar(y) = data(c1);
               drop(c1);
               return;
            }
         cdr(x) = cons(cons(k, data(c1)), cdr(x));
      }
      drop(c1);
   }
}

static void redefine(any ex, any s, any x) {
   NeedSym(ex,s);
   CheckVar(ex,s);
   if (!isNil(val(s))  &&  s != val(s)  &&  !equal(x,val(s)))
      redefMsg(s, NULL);
   val(s) = x;
   putSrc(s, NULL);
}

// (quote . any) -> any
any doQuote(any x) {return cdr(x);}

// (as 'any1 . any2) -> any2 | NIL
any doAs(any x) {
   x = cdr(x);
   if (isNil(EVAL(car(x))))
      return Nil;
   return cdr(x);
}

// (lit 'any) -> any
any doLit(any x) {
   x = cadr(x);
   if (isNum(x = EVAL(x)) || isNil(x) || x == T || isCell(x) && isNum(car(x)))
      return x;
   return cons(Quote, x);
}

// (eval 'any ['cnt ['lst]]) -> any
any doEval(any x) {
   any y;
   cell c1;
   bindFrame *p;

   x = cdr(x),  Push(c1, EVAL(car(x))),  x = cdr(x);
   if (!isNum(y = EVAL(car(x))) || !(p = Env.bind))
      data(c1) = EVAL(data(c1));
   else {
      int cnt, n, i, j;
      struct {  // bindFrame
         struct bindFrame *link;
         int i, cnt;
         struct {any sym; any val;} bnd[length(x)];
      } f;

      x = cdr(x),  x = EVAL(car(x));
      j = cnt = (int)unBox(y);
      n = f.i = f.cnt = 0;
      do {
         ++n;
         if ((i = p->i) <= 0  &&  (p->i -= cnt, i == 0)) {
            for (i = 0;  i < p->cnt;  ++i) {
               y = val(p->bnd[i].sym);
               val(p->bnd[i].sym) = p->bnd[i].val;
               p->bnd[i].val = y;
            }
            if (p->cnt  &&  p->bnd[0].sym == At  &&  !--j)
               break;
         }
      } while (p = p->link);
      while (isCell(x)) {
         for (p = Env.bind, j = n; ; p = p->link) {
            if (p->i < 0)
               for (i = 0;  i < p->cnt;  ++i) {
                  if (p->bnd[i].sym == car(x)) {
                     f.bnd[f.cnt].val = val(f.bnd[f.cnt].sym = car(x));
                     val(car(x)) = p->bnd[i].val;
                     ++f.cnt;
                     goto next;
                  }
               }
            if (!--j)
               break;
         }
next:    x = cdr(x);
      }
      f.link = Env.bind,  Env.bind = (bindFrame*)&f;
      data(c1) = EVAL(data(c1));
      while (--f.cnt >= 0)
         val(f.bnd[f.cnt].sym) = f.bnd[f.cnt].val;
      Env.bind = f.link;
      do {
         for (p = Env.bind, i = n;  --i;  p = p->link);
         if (p->i < 0  &&  (p->i += cnt) == 0)
            for (i = p->cnt;  --i >= 0;) {
               y = val(p->bnd[i].sym);
               val(p->bnd[i].sym) = p->bnd[i].val;
               p->bnd[i].val = y;
            }
      } while (--n);
   }
   return Pop(c1);
}

// (run 'any ['cnt ['lst]]) -> any
any doRun(any x) {
   any y;
   cell c1;
   bindFrame *p;

   x = cdr(x),  data(c1) = EVAL(car(x)),  x = cdr(x);
   if (!isNum(data(c1))) {
      Save(c1);
      if (!isNum(y = EVAL(car(x))) || !(p = Env.bind))
         data(c1) = isSym(data(c1))? val(data(c1)) : run(data(c1));
      else {
         int cnt, n, i, j;
         struct {  // bindFrame
            struct bindFrame *link;
            int i, cnt;
            struct {any sym; any val;} bnd[length(x)];
         } f;

         x = cdr(x),  x = EVAL(car(x));
         j = cnt = (int)unBox(y);
         n = f.i = f.cnt = 0;
         do {
            ++n;
            if ((i = p->i) <= 0  &&  (p->i -= cnt, i == 0)) {
               for (i = 0;  i < p->cnt;  ++i) {
                  y = val(p->bnd[i].sym);
                  val(p->bnd[i].sym) = p->bnd[i].val;
                  p->bnd[i].val = y;
               }
               if (p->cnt  &&  p->bnd[0].sym == At  &&  !--j)
                  break;
            }
         } while (p = p->link);
         while (isCell(x)) {
            for (p = Env.bind, j = n; ; p = p->link) {
               if (p->i < 0)
                  for (i = 0;  i < p->cnt;  ++i) {
                     if (p->bnd[i].sym == car(x)) {
                        f.bnd[f.cnt].val = val(f.bnd[f.cnt].sym = car(x));
                        val(car(x)) = p->bnd[i].val;
                        ++f.cnt;
                        goto next;
                     }
                  }
               if (!--j)
                  break;
            }
next:       x = cdr(x);
         }
         f.link = Env.bind,  Env.bind = (bindFrame*)&f;
         data(c1) = isSym(data(c1))? val(data(c1)) : prog(data(c1));
         while (--f.cnt >= 0)
            val(f.bnd[f.cnt].sym) = f.bnd[f.cnt].val;
         Env.bind = f.link;
         do {
            for (p = Env.bind, i = n;  --i;  p = p->link);
            if (p->i < 0  &&  (p->i += cnt) == 0)
               for (i = p->cnt;  --i >= 0;) {
                  y = val(p->bnd[i].sym);
                  val(p->bnd[i].sym) = p->bnd[i].val;
                  p->bnd[i].val = y;
               }
         } while (--n);
      }
      drop(c1);
   }
   return data(c1);
}

// (def 'sym 'any) -> sym
// (def 'sym 'sym 'any) -> sym
any doDef(any ex) {
   any x, y;
   cell c1, c2, c3;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   NeedSym(ex,data(c1));
   x = cdr(x),  Push(c2, EVAL(car(x)));
   if (!isCell(cdr(x))) {
      CheckVar(ex,data(c1));
      Touch(ex,data(c1));
      if (!isNil(y = val(data(c1)))  &&  y != data(c1)  &&  !equal(data(c2), y))
         redefMsg(data(c1), NULL);
      val(data(c1)) = data(c2);
      putSrc(data(c1), NULL);
   }
   else {
      x = cdr(x),  Push(c3, EVAL(car(x)));
      if (isExt(data(c1)))
         db(ex, data(c1), !isNil(data(c2))? 2 : 1);
      if (!isNil(y = get(data(c1), data(c2)))  &&  !equal(data(c3), y))
         redefMsg(data(c1), data(c2));
      put(data(c1), data(c2), data(c3));
      putSrc(data(c1), data(c2));
   }
   return Pop(c1);
}

// (de sym . any) -> sym
any doDe(any ex) {
   redefine(ex, cadr(ex), cddr(ex));
   return cadr(ex);
}

// (dm sym . fun|cls2) -> sym
// (dm (sym . cls) . fun|cls2) -> sym
// (dm (sym sym2 [. cls]) . fun|cls2) -> sym
any doDm(any ex) {
   any x, y, msg, cls;

   x = cdr(ex);
   if (!isCell(car(x)))
      msg = car(x),  cls = val(Class);
   else {
      msg = caar(x);
      cls = !isCell(cdar(x))? cdar(x) :
         get(isNil(cddar(x))? val(Class) : cddar(x), cadar(x));
   }
   if (msg != T)
      redefine(ex, msg, val(Meth));
   if (isSym(cdr(x))) {
      y = val(cdr(x));
      for (;;) {
         if (!isCell(y) || !isCell(car(y)))
            err(ex, msg, "Bad message");
         if (caar(y) == msg) {
            x = car(y);
            break;
         }
         y = cdr(y);
      }
   }
   for (y = val(cls);  isCell(y) && isCell(car(y));  y = cdr(y))
      if (caar(y) == msg) {
         if (!equal(cdr(x), cdar(y)))
            redefMsg(msg, cls);
         cdar(y) = cdr(x);
         putSrc(cls, msg);
         return msg;
      }
   if (!isCell(car(x)))
      val(cls) = cons(x, val(cls));
   else
      val(cls) = cons(cons(msg, cdr(x)), val(cls));
   putSrc(cls, msg);
   return msg;
}

/* Evaluate method invocation */
static any evMethod(any o, any expr, any x) {
   any y = car(expr);
   any cls = TheCls, key = TheKey;
   struct {  // bindFrame
      struct bindFrame *link;
      int i, cnt;
      struct {any sym; any val;} bnd[length(y)+3];
   } f;

   f.link = Env.bind,  Env.bind = (bindFrame*)&f;
   f.i = sizeof(f.bnd) / (2*sizeof(any)) - 2;
   f.cnt = 1,  f.bnd[0].sym = At,  f.bnd[0].val = val(At);
   while (isCell(y)) {
      f.bnd[f.cnt].sym = car(y);
      f.bnd[f.cnt].val = EVAL(car(x));
      ++f.cnt, x = cdr(x), y = cdr(y);
   }
   if (isNil(y)) {
      do {
         x = val(f.bnd[--f.i].sym);
         val(f.bnd[f.i].sym) = f.bnd[f.i].val;
         f.bnd[f.i].val = x;
      } while (f.i);
      f.bnd[f.cnt].sym = This,  f.bnd[f.cnt++].val = val(This),  val(This) = o;
      y = cls,  cls = Env.cls;  Env.cls = y;
      y = key,  key = Env.key;  Env.key = y;
      x = prog(cdr(expr));
   }
   else if (y != At) {
      f.bnd[f.cnt].sym = y,  f.bnd[f.cnt++].val = val(y),  val(y) = x;
      do {
         x = val(f.bnd[--f.i].sym);
         val(f.bnd[f.i].sym) = f.bnd[f.i].val;
         f.bnd[f.i].val = x;
      } while (f.i);
      f.bnd[f.cnt].sym = This,  f.bnd[f.cnt++].val = val(This),  val(This) = o;
      y = cls,  cls = Env.cls;  Env.cls = y;
      y = key,  key = Env.key;  Env.key = y;
      x = prog(cdr(expr));
   }
   else {
      int n, cnt;
      cell *arg;
      cell c[n = cnt = length(x)];

      while (--n >= 0)
         Push(c[n], EVAL(car(x))),  x = cdr(x);
      do {
         x = val(f.bnd[--f.i].sym);
         val(f.bnd[f.i].sym) = f.bnd[f.i].val;
         f.bnd[f.i].val = x;
      } while (f.i);
      n = Env.next,  Env.next = cnt;
      arg = Env.arg,  Env.arg = c;
      f.bnd[f.cnt].sym = This,  f.bnd[f.cnt++].val = val(This),  val(This) = o;
      y = cls,  cls = Env.cls;  Env.cls = y;
      y = key,  key = Env.key;  Env.key = y;
      x = prog(cdr(expr));
      if (cnt)
         drop(c[cnt-1]);
      Env.arg = arg,  Env.next = n;
   }
   while (--f.cnt >= 0)
      val(f.bnd[f.cnt].sym) = f.bnd[f.cnt].val;
   Env.bind = f.link;
   Env.cls = cls,  Env.key = key;
   return x;
}

any method(any x) {
   any y, z;

   if (isCell(y = val(x))) {
      while (isCell(z = car(y))) {
         if (car(z) == TheKey)
            return cdr(z);
         if (!isCell(y = cdr(y)))
            return NULL;
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

// (new ['flg|num] ['typ ['any ..]]) -> obj
any doNew(any ex) {
   any x, y, *h;
   cell c1, c2;

   x = cdr(ex);
   if (isCell(y = EVAL(car(x))))
      Push(c1, consSym(y,Nil));
   else {
      if (isNil(y))
         data(c1) = consSym(Nil,Nil);
      else {
         y = newId(ex, isNum(y)? (int)unDig(y)/2 : 1);
         if (data(c1) = findHash(y, h = Extern + ehash(y)))
            tail(data(c1)) = y;
         else
            *h = cons(data(c1) = consSym(Nil,y), *h);
         mkExt(data(c1));
      }
      Save(c1);
      x = cdr(x),  val(data(c1)) = EVAL(car(x));
   }
   TheKey = T,  TheCls = NULL;
   if (y = method(data(c1)))
      evMethod(data(c1), y, cdr(x));
   else {
      Push(c2, Nil);
      while (isCell(x = cdr(x))) {
         data(c2) = EVAL(car(x)),  x = cdr(x);
         put(data(c1), data(c2), EVAL(car(x)));
      }
   }
   return Pop(c1);
}

// (type 'any) -> lst
any doType(any ex) {
   any x, y, z;

   x = cdr(ex),  x = EVAL(car(x));
   if (isSym(x)) {
      Fetch(ex,x);
      z = x = val(x);
      while (isCell(x)) {
         if (!isCell(car(x))) {
            y = x;
            while (isSym(car(x))) {
               if (!isCell(x = cdr(x)))
                  return isNil(x)? y : Nil;
               if (z == x)
                  return Nil;
            }
            return Nil;
         }
         if (z == (x = cdr(x)))
            return Nil;
      }
   }
   return Nil;
}

static bool isa(any cls, any x) {
   any z;

   z = x = val(x);
   while (isCell(x)) {
      if (!isCell(car(x))) {
         while (isSym(car(x))) {
            if (isExt(car(x)))
               return NO;
            if (cls == car(x) || isa(cls, car(x)))
               return YES;
            if (!isCell(x = cdr(x)) || z == x)
               return NO;
         }
         return NO;
      }
      if (z == (x = cdr(x)))
         return NO;
   }
   return NO;
}

// (isa 'cls|typ 'any) -> obj | NIL
any doIsa(any ex) {
   any x;
   cell c1;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   x = cdr(x),  x = EVAL(car(x));
   if (isSym(x)) {
      Fetch(ex,x);
      drop(c1);
      if (isSym(data(c1)))
         return isa(data(c1), x)? x : Nil;
      while (isCell(data(c1))) {
         if (!isa(car(data(c1)), x))
            return Nil;
         data(c1) = cdr(data(c1));
      }
      return x;
   }
   drop(c1);
   return Nil;
}

// (method 'msg 'obj) -> fun
any doMethod(any ex) {
   any x;
   cell c1;

   x = cdr(ex),  Push(c1,  EVAL(car(x)));
   NeedSym(ex,data(c1));
   x = cdr(x),  x = EVAL(car(x));
   NeedSym(ex,x);
   Fetch(ex,x);
   TheKey = Pop(c1);
   return method(x)? : Nil;
}

// (meth 'obj ['any ..]) -> any
any doMeth(any ex) {
   any x, y;
   cell c1;

   x = cdr(ex),  Push(c1, EVAL(car(x)));
   NeedSym(ex,data(c1));
   Fetch(ex,data(c1));
   for (TheKey = car(ex); ; TheKey = val(TheKey)) {
      if (!isSym(TheKey))
         err(ex, TheKey, "Bad message");
      if (isNum(val(TheKey))) {
         TheCls = NULL;
         if (y = method(data(c1))) {
            x = evMethod(data(c1), y, cdr(x));
            drop(c1);
            return x;
         }
         err(ex, TheKey, "Bad message");
      }
   }
}

// (send 'msg 'obj ['any ..]) -> any
any doSend(any ex) {
   any x, y;
   cell c1, c2;

   x = cdr(ex),  Push(c1,  EVAL(car(x)));
   NeedSym(ex,data(c1));
   x = cdr(x),  Push(c2,  EVAL(car(x)));
   NeedSym(ex,data(c2));
   Fetch(ex,data(c2));
   TheKey = data(c1),  TheCls = NULL;
   if (y = method(data(c2))) {
      x = evMethod(data(c2), y, cdr(x));
      drop(c1);
      return x;
   }
   err(ex, TheKey, "Bad message");
}

// (try 'msg 'obj ['any ..]) -> any
any doTry(any ex) {
   any x, y;
   cell c1, c2;

   x = cdr(ex),  Push(c1,  EVAL(car(x)));
   NeedSym(ex,data(c1));
   x = cdr(x),  Push(c2,  EVAL(car(x)));
   if (isSym(data(c2))) {
      if (isExt(data(c2))) {
         if (!isLife(data(c2)))
            return Nil;
         db(ex,data(c2),1);
      }
      TheKey = data(c1),  TheCls = NULL;
      if (y = method(data(c2))) {
         x = evMethod(data(c2), y, cdr(x));
         drop(c1);
         return x;
      }
   }
   drop(c1);
   return Nil;
}

// (super ['any ..]) -> any
any doSuper(any ex) {
   any x, y, cls, key;

   TheKey = Env.key;
   x = val(Env.cls? car(Env.cls) : val(This));
   while (isCell(car(x)))
      x = cdr(x);
   while (isCell(x)) {
      if (y = method(car(TheCls = x))) {
         cls = Env.cls,  Env.cls = TheCls;
         key = Env.key,  Env.key = TheKey;
         x = evExpr(y, cdr(ex));
         Env.key = key,  Env.cls = cls;
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
      if (x == Env.cls  ||  !(y = extra(car(x)))) {
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
   any x, y, cls, key;

   TheKey = Env.key;
   if ((y = extra(val(This)))  &&  num(y) != 1) {
      cls = Env.cls,  Env.cls = TheCls;
      key = Env.key,  Env.key = TheKey;
      x = evExpr(y, cdr(ex));
      Env.key = key,  Env.cls = cls;
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
   Bind(This,f),  val(This) = x;
   x = prog(cddr(ex));
   Unbind(f);
   return x;
}

// (bind 'sym|lst . prg) -> any
any doBind(any ex) {
   any x, y;

   x = cdr(ex);
   if (isNum(y = EVAL(car(x))))
      argError(ex, y);
   if (isNil(y))
      return prog(cdr(x));
   if (isSym(y)) {
      bindFrame f;

      Bind(y,f);
      x = prog(cdr(x));
      Unbind(f);
      return x;
   }
   {
      struct {  // bindFrame
         struct bindFrame *link;
         int i, cnt;
         struct {any sym; any val;} bnd[length(y)];
      } f;

      f.link = Env.bind,  Env.bind = (bindFrame*)&f;
      f.i = f.cnt = 0;
      do {
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
         ++f.cnt;
      } while (isCell(y = cdr(y)));
      x = prog(cdr(x));
      while (--f.cnt >= 0)
         val(f.bnd[f.cnt].sym) = f.bnd[f.cnt].val;
      Env.bind = f.link;
      return x;
   }
}

// (job 'lst . prg) -> any
any doJob(any ex) {
   any x = cdr(ex);
   any y = EVAL(car(x));
   cell c1;
   struct {  // bindFrame
      struct bindFrame *link;
      int i, cnt;
      struct {any sym; any val;} bnd[length(y)];
   } f;

   Push(c1,y);
   f.link = Env.bind,  Env.bind = (bindFrame*)&f;
   f.i = f.cnt = 0;
   while (isCell(y)) {
      f.bnd[f.cnt].sym = caar(y);
      f.bnd[f.cnt].val = val(caar(y));
      val(caar(y)) = cdar(y);
      ++f.cnt,  y = cdr(y);
   }
   x = prog(cdr(x));
   for (f.cnt = 0, y = Pop(c1);  isCell(y);  ++f.cnt, y = cdr(y)) {
      cdar(y) = val(caar(y));
      val(caar(y)) = f.bnd[f.cnt].val;
   }
   Env.bind = f.link;
   return x;
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
         int i, cnt;
         struct {any sym; any val;} bnd[(length(y)+1)/2];
      } f;

      f.link = Env.bind,  Env.bind = (bindFrame*)&f;
      f.i = f.cnt = 0;
      do {
         f.bnd[f.cnt].sym = car(y);
         f.bnd[f.cnt].val = val(car(y));
         ++f.cnt;
         val(car(y)) = EVAL(cadr(y));
      } while (isCell(y = cddr(y)));
      x = prog(cdr(x));
      while (--f.cnt >= 0)
         val(f.bnd[f.cnt].sym) = f.bnd[f.cnt].val;
      Env.bind = f.link;
   }
   return x;
}

// (let? sym 'any . prg) -> any
any doLetQ(any x) {
   any y, z;
   bindFrame f;

   x = cdr(x),  y = car(x),  x = cdr(x);
   if (isNil(z = EVAL(car(x))))
      return Nil;
   Bind(y,f),  val(y) = z;
   x = prog(cdr(x));
   Unbind(f);
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
         int i, cnt;
         struct {any sym; any val;} bnd[length(y)];
      } f;

      f.link = Env.bind,  Env.bind = (bindFrame*)&f;
      f.i = f.cnt = 0;
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
   any a;

   x = cdr(x);
   do {
      if (isNil(a = EVAL(car(x))))
         return Nil;
      val(At) = a;
   } while (isCell(x = cdr(x)));
   return a;
}

// (or 'any ..) -> any
any doOr(any x) {
   any a;

   x = cdr(x);
   do
      if (!isNil(a = EVAL(car(x))))
         return val(At) = a;
   while (isCell(x = cdr(x)));
   return Nil;
}

// (nand 'any ..) -> flg
any doNand(any x) {
   any a;

   x = cdr(x);
   do {
      if (isNil(a = EVAL(car(x))))
         return T;
      val(At) = a;
   } while (isCell(x = cdr(x)));
   return Nil;
}

// (nor 'any ..) -> flg
any doNor(any x) {
   any a;

   x = cdr(x);
   do
      if (!isNil(a = EVAL(car(x)))) {
         val(At) = a;
         return Nil;
      }
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
any doNot(any x) {
   any a;

   if (isNil(a = EVAL(cadr(x))))
      return T;
   val(At) = a;
   return Nil;
}

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

// (if 'any1 any2 . prg) -> any
any doIf(any x) {
   any a;

   x = cdr(x);
   if (isNil(a = EVAL(car(x))))
      return prog(cddr(x));
   val(At) = a;
   x = cdr(x);
   return EVAL(car(x));
}

// (if2 'any1 'any2 any3 any4 any5 . prg) -> any
any doIf2(any x) {
   any a;

   x = cdr(x);
   if (isNil(a = EVAL(car(x)))) {
      x = cdr(x);
      if (isNil(a = EVAL(car(x))))
         return prog(cddddr(x));
      val(At) = a;
      x = cdddr(x);
      return EVAL(car(x));
   }
   val(At) = a;
   x = cdr(x);
   if (isNil(a = EVAL(car(x)))) {
      x = cddr(x);
      return EVAL(car(x));
   }
   val(At) = a;
   x = cdr(x);
   return EVAL(car(x));
}

// (ifn 'any1 any2 . prg) -> any
any doIfn(any x) {
   any a;

   x = cdr(x);
   if (!isNil(a = EVAL(car(x)))) {
      val(At) = a;
      return prog(cddr(x));
   }
   x = cdr(x);
   return EVAL(car(x));
}

// (when 'any . prg) -> any
any doWhen(any x) {
   any a;

   x = cdr(x);
   if (isNil(a = EVAL(car(x))))
      return Nil;
   val(At) = a;
   return prog(cdr(x));
}

// (unless 'any . prg) -> any
any doUnless(any x) {
   any a;

   x = cdr(x);
   if (!isNil(a = EVAL(car(x)))) {
      val(At) = a;
      return Nil;
   }
   return prog(cdr(x));
}

// (cond ('any1 . prg1) ('any2 . prg2) ..) -> any
any doCond(any x) {
   any a;

   while (isCell(x = cdr(x))) {
      if (!isNil(a = EVAL(caar(x)))) {
         val(At) = a;
         return prog(cdar(x));
      }
   }
   return Nil;
}

// (nond ('any1 . prg1) ('any2 . prg2) ..) -> any
any doNond(any x) {
   any a;

   while (isCell(x = cdr(x))) {
      if (isNil(a = EVAL(caar(x))))
         return prog(cdar(x));
      val(At) = a;
   }
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

// (casq 'any (any1 . prg1) (any2 . prg2) ..) -> any
any doCasq(any x) {
   any y, z;

   x = cdr(x),  val(At) = EVAL(car(x));
   while (isCell(x = cdr(x))) {
      y = car(x),  z = car(y);
      if (z == T  ||  z == val(At))
         return prog(cdr(y));
      if (isCell(z)) {
         do
            if (car(z) == val(At))
               return prog(cdr(y));
         while (isCell(z = cdr(z)));
      }
   }
   return Nil;
}

// (state 'var (sym|lst exe [. prg]) ..) -> any
any doState(any ex) {
   any x, y, a;
   cell c1;

   x = cdr(ex);
   Push(c1, EVAL(car(x)));
   NeedVar(ex,data(c1));
   CheckVar(ex,data(c1));
   while (isCell(x = cdr(x))) {
      y = car(x);
      if (car(y) == T || memq(val(data(c1)), car(y))) {
         y = cdr(y);
         if (!isNil(a = EVAL(car(y)))) {
            val(At) = val(data(c1)) = a;
            drop(c1);
            return prog(cdr(y));
         }
      }
   }
   drop(c1);
   return Nil;
}

// (while 'any . prg) -> any
any doWhile(any x) {
   any cond, a;
   cell c1;

   cond = car(x = cdr(x)),  x = cdr(x);
   Push(c1, Nil);
   while (!isNil(a = EVAL(cond))) {
      val(At) = a;
      data(c1) = prog(x);
   }
   return Pop(c1);
}

// (until 'any . prg) -> any
any doUntil(any x) {
   any cond, a;
   cell c1;

   cond = car(x = cdr(x)),  x = cdr(x);
   Push(c1, Nil);
   while (isNil(a = EVAL(cond)))
      data(c1) = prog(x);
   val(At) = a;
   return Pop(c1);
}

// (loop ['any | (NIL 'any . prg) | (T 'any . prg) ..]) -> any
any doLoop(any ex) {
   any x, y, a;

   for (;;) {
      x = cdr(ex);
      do {
         if (isCell(y = car(x))) {
            if (isNil(car(y))) {
               y = cdr(y);
               if (isNil(a = EVAL(car(y))))
                  return prog(cdr(y));
               val(At) = a;
            }
            else if (car(y) == T) {
               y = cdr(y);
               if (!isNil(a = EVAL(car(y)))) {
                  val(At) = a;
                  return prog(cdr(y));
               }
            }
            else
               evList(y);
         }
      } while (isCell(x = cdr(x)));
   }
}

// (do 'flg|num ['any | (NIL 'any . prg) | (T 'any . prg) ..]) -> any
any doDo(any x) {
   any y, z, a;
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
               if (isNil(a = EVAL(car(z)))) {
                  drop(c1);
                  return prog(cdr(z));
               }
               val(At) = a;
               z = Nil;
            }
            else if (car(z) == T) {
               z = cdr(z);
               if (!isNil(a = EVAL(car(z)))) {
                  val(At) = a;
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

// (at '(cnt1 . cnt2|NIL) . prg) -> any
any doAt(any ex) {
   any x;

   x = cdr(ex),  x = EVAL(car(x));
   NeedPair(ex,x);
   if (isNil(cdr(x)))
      return Nil;
   NeedCnt(ex,car(x));
   NeedCnt(ex,cdr(x));
   if (num(setDig(car(x), unDig(car(x))+2)) < unDig(cdr(x)))
      return Nil;
   setDig(car(x), 0);
   return prog(cddr(ex));
}

// (for sym 'num ['any | (NIL 'any . prg) | (T 'any . prg) ..]) -> any
// (for sym|(sym2 . sym) 'lst ['any | (NIL 'any . prg) | (T 'any . prg) ..]) -> any
// (for (sym|(sym2 . sym) 'any1 'any2 [. prg]) ['any | (NIL 'any . prg) | (T 'any . prg) ..]) -> any
any doFor(any x) {
   any y, body, cond, a;
   cell c1;
   struct {  // bindFrame
      struct bindFrame *link;
      int i, cnt;
      struct {any sym; any val;} bnd[2];
   } f;

   f.link = Env.bind,  Env.bind = (bindFrame*)&f;
   f.i = 0;
   if (!isCell(y = car(x = cdr(x))) || !isCell(cdr(y))) {
      if (!isCell(y)) {
         f.cnt = 1;
         f.bnd[0].sym = y;
         f.bnd[0].val = val(y);
      }
      else {
         f.cnt = 2;
         f.bnd[0].sym = cdr(y);
         f.bnd[0].val = val(cdr(y));
         f.bnd[1].sym = car(y);
         f.bnd[1].val = val(car(y));
         val(f.bnd[1].sym) = Zero;
      }
      y = Nil;
      x = cdr(x),  Push(c1, EVAL(car(x)));
      if (isNum(data(c1)))
         val(f.bnd[0].sym) = Zero;
      body = x = cdr(x);
      for (;;) {
         if (isNum(data(c1))) {
            val(f.bnd[0].sym) = bigCopy(val(f.bnd[0].sym));
            digAdd(val(f.bnd[0].sym), 2);
            if (bigCompare(val(f.bnd[0].sym), data(c1)) > 0)
               break;
         }
         else {
            if (!isCell(data(c1)))
               break;
            val(f.bnd[0].sym) = car(data(c1));
            if (!isCell(data(c1) = cdr(data(c1))))
               data(c1) = Nil;
         }
         if (f.cnt == 2) {
            val(f.bnd[1].sym) = bigCopy(val(f.bnd[1].sym));
            digAdd(val(f.bnd[1].sym), 2);
         }
         do {
            if (!isNum(y = car(x))) {
               if (isSym(y))
                  y = val(y);
               else if (isNil(car(y))) {
                  y = cdr(y);
                  if (isNil(a = EVAL(car(y)))) {
                     y = prog(cdr(y));
                     goto for1;
                  }
                  val(At) = a;
                  y = Nil;
               }
               else if (car(y) == T) {
                  y = cdr(y);
                  if (!isNil(a = EVAL(car(y)))) {
                     val(At) = a;
                     y = prog(cdr(y));
                     goto for1;
                  }
                  y = Nil;
               }
               else
                  y = evList(y);
            }
         } while (isCell(x = cdr(x)));
         x = body;
      }
   for1:
      drop(c1);
      if (f.cnt == 2)
         val(f.bnd[1].sym) = f.bnd[1].val;
      val(f.bnd[0].sym) = f.bnd[0].val;
      Env.bind = f.link;
      return y;
   }
   if (!isCell(car(y))) {
      f.cnt = 1;
      f.bnd[0].sym = car(y);
      f.bnd[0].val = val(car(y));
   }
   else {
      f.cnt = 2;
      f.bnd[0].sym = cdar(y);
      f.bnd[0].val = val(cdar(y));
      f.bnd[1].sym = caar(y);
      f.bnd[1].val = val(caar(y));
      val(f.bnd[1].sym) = Zero;
   }
   y = cdr(y);
   val(f.bnd[0].sym) = EVAL(car(y));
   y = cdr(y),  cond = car(y),  y = cdr(y);
   Push(c1,Nil);
   body = x = cdr(x);
   for (;;) {
      if (f.cnt == 2) {
         val(f.bnd[1].sym) = bigCopy(val(f.bnd[1].sym));
         digAdd(val(f.bnd[1].sym), 2);
      }
      if (isNil(a = EVAL(cond)))
         break;
      val(At) = a;
      do {
         if (!isNum(data(c1) = car(x))) {
            if (isSym(data(c1)))
               data(c1) = val(data(c1));
            else if (isNil(car(data(c1)))) {
               data(c1) = cdr(data(c1));
               if (isNil(a = EVAL(car(data(c1))))) {
                  data(c1) = prog(cdr(data(c1)));
                  goto for2;
               }
               val(At) = a;
               data(c1) = Nil;
            }
            else if (car(data(c1)) == T) {
               data(c1) = cdr(data(c1));
               if (!isNil(a = EVAL(car(data(c1))))) {
                  val(At) = a;
                  data(c1) = prog(cdr(data(c1)));
                  goto for2;
               }
               data(c1) = Nil;
            }
            else
               data(c1) = evList(data(c1));
         }
      } while (isCell(x = cdr(x)));
      if (isCell(y))
         val(f.bnd[0].sym) = prog(y);
      x = body;
   }
for2:
   if (f.cnt == 2)
      val(f.bnd[1].sym) = f.bnd[1].val;
   val(f.bnd[0].sym) = f.bnd[0].val;
   Env.bind = f.link;
   return Pop(c1);
}

// (catch 'any . prg) -> any
any doCatch(any x) {
   any y;
   catchFrame f;

   x = cdr(x),  f.tag = EVAL(car(x)),  f.fin = Zero;
   f.link = CatchPtr,  CatchPtr = &f;
   f.env = Env;
   y = setjmp(f.rst)? Thrown : prog(cdr(x));
   CatchPtr = f.link;
   return y;
}

// (throw 'sym 'any)
any doThrow(any ex) {
   any x, tag;
   catchFrame *p;

   x = cdr(ex),  tag = EVAL(car(x));
   x = cdr(x),  Thrown = EVAL(car(x));
   for (p = CatchPtr;  p;  p = p->link)
      if (p->tag == T  ||  tag == p->tag) {
         unwind(p);
         longjmp(p->rst, 1);
      }
   err(ex, tag, "Tag not found");
}

// (finally exe . prg) -> any
any doFinally(any x) {
   catchFrame f;
   cell c1;

   x = cdr(x),  f.tag = NULL,  f.fin = car(x);
   f.link = CatchPtr,  CatchPtr = &f;
   f.env = Env;
   Push(c1, prog(cdr(x)));
   EVAL(f.fin);
   CatchPtr = f.link;
   return Pop(c1);
}

static outFrame Out;
static struct {  // bindFrame
   struct bindFrame *link;
   int i, cnt;
   struct {any sym; any val;} bnd[3];  // for 'Up', 'Run' and 'At'
} Brk;

any brkLoad(any x) {
   if (!Break && isatty(STDIN_FILENO) && isatty(STDOUT_FILENO)) {
      Break = YES;
      Brk.cnt = 3;
      Brk.bnd[0].sym = Up,  Brk.bnd[0].val = val(Up),  val(Up) = x;
      Brk.bnd[1].sym = Run,  Brk.bnd[1].val = val(Run),  val(Run) = Nil;
      Brk.bnd[2].sym = At,  Brk.bnd[2].val = val(At);
      Brk.link = Env.bind,  Env.bind = (bindFrame*)&Brk;
      Out.pid = 0,  Out.fd = STDOUT_FILENO,  pushOutFiles(&Out);
      print(x), newline();
      load(NULL, '!', Nil);
      popOutFiles();
      val(At) = Brk.bnd[2].val;
      val(Run) = Brk.bnd[1].val;
      x = val(Up),  val(Up) = Brk.bnd[0].val;
      Env.bind = Brk.link;
      Break = NO;
   }
   return x;
}

// (! . exe) -> any
any doBreak(any x) {
   x = cdr(x);
   if (!isNil(val(Dbg)))
      x = brkLoad(x);
   return EVAL(x);
}

// (e . prg) -> any
any doE(any ex) {
   any x;
   inFrame *in;
   cell c1, at, key;

   if (!Break)
      err(ex, NULL, "No Break");
   Push(c1,val(Dbg)),  val(Dbg) = Nil;
   Push(at, val(At)),  val(At) = Brk.bnd[2].val;
   Push(key, val(Run)),  val(Run) = Brk.bnd[1].val;
   in =  Env.inFrames,  popInFiles();
   popOutFiles();
   x = isCell(cdr(ex))? prog(cdr(ex)) : EVAL(val(Up));
   pushOutFiles(&Out);
   pushInFiles(in);
   val(Run) = data(key);
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

// ($ sym|lst lst . prg) -> any
any doTrace(any x) {
   any foo, body;
   outFile *oSave;
   void (*putSave)(int);
   cell c1;

   x = cdr(x);
   if (isNil(val(Dbg)))
      return prog(cddr(x));
   oSave = OutFile,  putSave = Env.put;
   OutFile = OutFiles[STDERR_FILENO],  Env.put = putStdout;
   foo = car(x);
   x = cdr(x),  body = cdr(x);
   traceIndent(++Env.trace, foo, " :");
   for (x = car(x);  isCell(x);  x = cdr(x))
      space(), print(val(car(x)));
   if (!isNil(x)) {
      if (x != At)
         space(), print(val(x));
      else {
         int i = Env.next;

         while (--i >= 0)
            space(), print(data(Env.arg[i]));
      }
   }
   newline();
   Env.put = putSave,  OutFile = oSave;
   Push(c1, prog(body));
   OutFile = OutFiles[STDERR_FILENO],  Env.put = putStdout;
   traceIndent(Env.trace--, foo, " = "),  print(data(c1));
   newline();
   Env.put = putSave,  OutFile = oSave;
   return Pop(c1);
}

// (exec 'any ..)
any doExec(any x) {
   any y;
   int i, ac = length(x = cdr(x));
   char *av[ac+1];

   if (ac) {
      av[0] = alloc(NULL, pathSize(y = evSym(x))),  pathString(y, av[0]);
      for (i = 1; isCell(x = cdr(x)); ++i)
         av[i] = alloc(NULL, bufSize(y = evSym(x))),  bufString(y, av[i]);
      av[ac] = NULL;
      flushAll();
      execvp(av[0], av);
      execError(av[0]);
   }
   return Nil;
}

// (call 'any ..) -> flg
any doCall(any ex) {
   pid_t pid;
   any x, y;
   int res, i, ac = length(x = cdr(ex));
   char *av[ac+1];

   if (ac == 0)
      return Nil;
   av[0] = alloc(NULL, pathSize(y = evSym(x))),  pathString(y, av[0]);
   for (i = 1; isCell(x = cdr(x)); ++i)
      av[i] = alloc(NULL, bufSize(y = evSym(x))),  bufString(y, av[i]);
   av[ac] = NULL;
   flushAll();
   if ((pid = fork()) == 0) {
      setpgid(0,0);
      execvp(av[0], av);
      execError(av[0]);
   }
   i = 0;  do
      free(av[i]);
   while (++i < ac);
   if (pid < 0)
      err(ex, NULL, "fork");
   setpgid(pid,0);
   if (Termio)
      tcsetpgrp(0,pid);
   for (;;) {
      while (waitpid(pid, &res, WUNTRACED) < 0) {
         if (errno != EINTR)
            err(ex, NULL, "wait pid");
         if (*Signal)
            sighandler(ex);
      }
      if (Termio)
         tcsetpgrp(0,getpgrp());
      if (!WIFSTOPPED(res)) {
         val(At2) = box(res+res);
         return res == 0? T : Nil;
      }
      load(NULL, '+', Nil);
      if (Termio)
         tcsetpgrp(0,pid);
      kill(pid, SIGCONT);
   }
}

// (tick (cnt1 . cnt2) . prg) -> any
any doTick(any ex) {
   any x;
   clock_t n1, n2, save1, save2;
   struct tms tim;
   static clock_t ticks1, ticks2;

   save1 = ticks1,  save2 = ticks2;
   times(&tim),  n1 = tim.tms_utime,  n2 = tim.tms_stime;
   x = prog(cddr(ex));
   times(&tim);
   n1 = (tim.tms_utime - n1) - (ticks1 - save1);
   n2 = (tim.tms_stime - n2) - (ticks2 - save2);
   setDig(caadr(ex), unDig(caadr(ex)) + 2*n1);
   setDig(cdadr(ex), unDig(cdadr(ex)) + 2*n2);
   ticks1 += n1,  ticks2 += n2;
   return x;
}

// (ipid) -> pid | NIL
any doIpid(any ex __attribute__((unused))) {
   if (Env.inFrames  &&  Env.inFrames->pid > 1)
      return boxCnt((long)Env.inFrames->pid);
   return Nil;
}

// (opid) -> pid | NIL
any doOpid(any ex __attribute__((unused))) {
   if (Env.outFrames  &&  Env.outFrames->pid > 1)
      return boxCnt((long)Env.outFrames->pid);
   return Nil;
}

// (kill 'pid ['cnt]) -> flg
any doKill(any ex) {
   pid_t pid;

   pid = (pid_t)evCnt(ex,cdr(ex));
   return kill(pid, isCell(cddr(ex))? (int)evCnt(ex,cddr(ex)) : SIGTERM)? Nil : T;
}

static void allocChildren(void) {
   int i;

   Child = alloc(Child, (Children + 8) * sizeof(child));
   for (i = 0; i < 8; ++i)
      Child[Children++].pid = 0;
}

pid_t forkLisp(any ex) {
   pid_t n;
   int i, hear[2], tell[2];
   static int mic[2];

   flushAll();
   if (!Spkr) {
      if (pipe(mic) < 0)
         pipeError(ex, "open");
      closeOnExec(ex, mic[0]), closeOnExec(ex, mic[1]);
      Spkr = mic[0];
   }
   if (pipe(hear) < 0  ||  pipe(tell) < 0)
      pipeError(ex, "open");
   closeOnExec(ex, hear[0]), closeOnExec(ex, hear[1]);
   closeOnExec(ex, tell[0]), closeOnExec(ex, tell[1]);
   for (i = 0; i < Children; ++i)
      if (!Child[i].pid)
         break;
   if ((n = fork()) < 0)
      err(ex, NULL, "fork");
   if (n == 0) {
      void *p;

      Slot = i;
      Spkr = 0;
      Mic = mic[1];
      close(hear[1]), close(tell[0]), close(mic[0]);
      if (Hear)
         close(Hear),  closeInFile(Hear),  closeOutFile(Hear);
      initInFile(Hear = hear[0], NULL);
      if (Tell)
         close(Tell);
      Tell = tell[1];
      for (i = 0; i < Children; ++i)
         if (Child[i].pid)
            close(Child[i].hear), close(Child[i].tell),  free(Child[i].buf);
      Children = 0,  free(Child),  Child = NULL;
      for (p = Env.inFrames; p; p = ((inFrame*)p)->link)
         ((inFrame*)p)->pid = 0;
      for (p = Env.outFrames; p; p = ((outFrame*)p)->link)
         ((outFrame*)p)->pid = 0;
      for (p = CatchPtr; p; p = ((catchFrame*)p)->link)
         ((catchFrame*)p)->fin = Zero;
      free(Termio),  Termio = NULL;
      if (Repl)
         ++Repl;
      val(PPid) = val(Pid);
      val(Pid) = boxCnt(getpid());
      run(val(Fork));
      val(Fork) = Nil;
      return 0;
   }
   if (i == Children)
      allocChildren();
   close(hear[0]), close(tell[1]);
   Child[i].pid = n;
   Child[i].hear = tell[0];
   nonblocking(Child[i].tell = hear[1]);
   Child[i].ofs = Child[i].cnt = 0;
   Child[i].buf = NULL;
   return n;
}

// (fork) -> pid | NIL
any doFork(any ex) {
   int n;

   return (n = forkLisp(ex))? boxCnt(n) : Nil;
}

// (detach) -> pid | NIL
any doDetach(any x) {
   if (!isNil(x = val(PPid))) {
      val(PPid) = Nil;
      close(Tell),  Tell = 0;
      close(Hear),  closeInFile(Hear),  closeOutFile(Hear),  Hear = 0;
      close(Mic),  Mic = 0;
      Slot = 0;
      setsid();
   }
   return x;
}

// (bye ['cnt])
any doBye(any ex) {
   any x = EVAL(cadr(ex));

   bye(isNil(x)? 0 : xCnt(ex,x));
}
