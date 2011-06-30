# 25may11abu
# (c) Software Lab. Alexander Burger

(if (== 64 64) (load "@lib/native.l") (from "/**/"))

(gcc "util" NIL
   (crc (Len Lst) "crc" 'I Len (cons NIL (cons Len) Lst)) )

int crc(int len, char *p) {
   int res, c, i;

   for (res = 0; --len >=0;) {
      c = *p++;
      for (i = 0; i < 8; ++i) {
         if ((c ^ res) & 1)
            res ^= 0x14002;  /* Polynom x**16 + x**15 + x**2 + 1 */
         c >>= 1,  res >>= 1;
      }
   }
   return res;
}

/**/


(ifn (== 64 64) (load "@lib/gcc.l") (from "/**/"))

(gcc "crc" NIL 'crc)

any crc(any ex) {
   any x;
   int len, res, c, i;

   len = evCnt(ex, x = cdr(ex));
   x = cdr(x),  x = EVAL(car(x));
   for (res = 0; --len >=0; x = cdr(x)) {
      c = (int)xCnt(ex,car(x));
      for (i = 0; i < 8; ++i) {
         if ((c ^ res) & 1)
            res ^= 0x14002;  /* Polynom x**16 + x**15 + x**2 + 1 */
         c >>= 1,  res >>= 1;
      }
   }
   return boxCnt(res);
}

/**/

# vi:et:ts=3:sw=3
