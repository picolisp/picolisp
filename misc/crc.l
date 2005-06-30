# 24may05abu
# (c) Software Lab. Alexander Burger

(gcc "crc" 'crc)

any crc(any ex) {
   any x = EVAL(cadr(ex));
   int c, crc, i;

   NeedLst(ex,x);
   for (crc = 0; isCell(x); x = cdr(x)) {
      c = (int)xCnt(ex,car(x));
      for (i = 0; i < 8; ++i) {
         if ((c ^ crc) & 1)
            crc ^= 0x14002;  /* Polynom x**16 + x**15 + x**2 + 1 */
         c >>= 1,  crc >>= 1;
      }
   }
   return boxCnt(crc);
}
/**/
