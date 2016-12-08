# 24nov16abu
# (c) Software Lab. Alexander Burger

### Concurrent DB Garbage Collector ###
# *DbgcDly *DbgcPid

(default *DbgcDly 64)

(if (fork)
   (setq *DbgcPid @)

   (wait 60000)
   (undef 'upd)
   (de upd Lst
      (wipe Lst)
      (let *DbgcDly (>> 1 *DbgcDly)
         (for S Lst
            (when (ext? S)
               (mark S T)
               (markData (val S))
               (maps markData S) )
            (wipe S) ) ) )

   (de markExt (S)
      (unless (mark S T)
         (wait *DbgcDly)
         (markData (val S))
         (maps markData S)
         (wipe S) ) )

   (de markData (X)
      (while (pair X)
         (markData (++ X)) )
      (and (ext? X) (markExt X)) )

   (loop
      (let MS (+ (/ (usec) 1000) 86400000)
         (markExt *DB)
         (while (> MS (/ (usec) 1000))
            (wait 60000) ) )
      (let Cnt 0
         (for (F . @) (or *Dbs (2))
            (for (S (seq F)  S  (seq S))
               (wait *DbgcDly)
               (unless (mark S)
                  (sync)
                  (if (mark S)
                     (tell)
                     (and (isa '+Entity S) (zap> S))
                     (zap S)
                     (commit)
                     (inc 'Cnt) ) ) ) )
         (when *Blob
            (use (@S @R F S)
               (let Pat (conc (chop *Blob) '(@S "." @R))
                  (in (list 'find *Blob "-type" "f")
                     (while (setq F (line))
                        (wait *DbgcDly)
                        (when (match Pat F)
                           (unless
                              (and
                                 (setq S (extern (pack (replace @S '/))))
                                 (get S (intern (pack @R))) )
                              (inc 'Cnt)
                              (call "rm" (pack F)) )
                           (wipe S) ) ) ) ) ) )
         (msg Cnt " conDbgc") )
      (mark 0) ) )

# vi:et:ts=3:sw=3
