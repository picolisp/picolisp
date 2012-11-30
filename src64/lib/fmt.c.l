# 30sep12abu
# (c) Software Lab. Alexander Burger

(de newSection (Sym)
   (setq *Section Sym) )

(de asmDataLength ()
   (+
      (or (cadar *AsmData) 0)
      (sum '((X) (if (num? X) 1 8))
         (cddar *AsmData)) ) )

# Directives
(de label (Lbl Flg)
   (if (== 'data *Section)
      (push '*AsmData
         (list Lbl (asmDataLength)) )
      (if (and *AsmCode (not (caar @)))
         (conc (car *AsmCode) (cons Lbl))
         (push '*AsmCode (list NIL Lbl)) )
      (idx '*Labels (def (name Lbl) *AsmPos) T) ) )

(asm word (X)
   (conc (cdar *AsmData)
      (cons (if (sym? X) X (cons X))) ) )

(asm byte (N)
   (conc (cdar *AsmData) (cons N)) )

(asm bytes (Lst)
   (conc (cdar *AsmData) (copy Lst)) )

(asm hx2 (Lst)
   (conc (cdar *AsmData)
      (mapcan
         '((S)
            (let (N (hex S)  Hi (& (>> 8 N) 255)  Lo (& N 255))
               (if *LittleEndian
                  (list Lo Hi)
                  (list Hi Lo) ) ) )
         Lst ) ) )

(de escCstr (Str)
   (make
      (for (L (chop Str)  L)
         (let C (pop 'L)
            (link
               (char
                  (ifn (= "\\" C)
                     C
                     (case (pop 'L)
                        ("t" "^I")
                        ("n" "^J")
                        ("r" "^M")
                        (T @) ) ) ) ) ) ) ) )

(asm ascii (Str)
   (conc (cdar *AsmData) (escCstr Str)) )

(asm asciz (Str)
   (conc (cdar *AsmData) (escCstr Str) (cons 0)) )

# vi:et:ts=3:sw=3
